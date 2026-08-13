import 'dart:async';

import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/pages/home_page_controller.dart';
import 'package:localsend_app/provider/animation_provider.dart';
import 'package:localsend_app/provider/chat/chat_controller.dart';
import 'package:localsend_app/provider/chat/friends_provider.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:logging/logging.dart';
import 'package:refena_flutter/refena_flutter.dart';

final _logger = Logger('Presence');

/// How long a friend counts as online after the last confirmation.
///
/// Three heartbeat rounds fit into this window, so one lost announcement or one
/// round where the peer was busy does not make the dot flicker.
const presenceTimeout = Duration(seconds: 30);

/// How often the chat tab re-confirms its friends while it is open.
///
/// Every round announces (the discovery offers no probe-only call), which asks
/// the whole LAN to register with us. Raise this if that turns out to be too
/// chatty on a large network — and raise [presenceTimeout] with it, the two are
/// meant to stay a factor of three apart.
const presenceHeartbeatInterval = Duration(seconds: 10);

/// Whether a friend can be reached right now.
enum PresenceStatus {
  online,
  offline,

  /// Not established yet: the chat tab was just opened and the first heartbeat
  /// round has not come back. Claiming "offline" here would grey out everyone
  /// for a moment every time the tab is entered.
  unknown,
}

/// Whether [fingerprint] is reachable, as of [now].
///
/// Pure on purpose: this is the whole presence rule and it is unit tested.
PresenceStatus presenceStatusOf({
  required String fingerprint,
  required Map<String, DateTime> lastSeen,
  required Set<String> signalingFingerprints,
  required DateTime now,
  required bool firstRoundDone,
}) {
  // Signaling devices are not discovered over the LAN, so they never get a
  // [lastSeen] stamp. The signaling server tells us when they go away instead.
  if (_containsIgnoreCase(signalingFingerprints, fingerprint)) {
    return PresenceStatus.online;
  }

  final seen = _lookupIgnoreCase(lastSeen, fingerprint);
  if (seen != null && now.difference(seen) < presenceTimeout) {
    return PresenceStatus.online;
  }

  if (!firstRoundDone) {
    return PresenceStatus.unknown;
  }

  return PresenceStatus.offline;
}

/// Certificate fingerprints are uppercase hex, but a peer reports its own
/// fingerprint in the payload when encryption is off, where nothing enforces
/// the case. [ChatRefExt.resolveChatTarget] and the friend request handling
/// already ignore case, so presence has to agree.
DateTime? _lookupIgnoreCase(Map<String, DateTime> lastSeen, String fingerprint) {
  final direct = lastSeen[fingerprint];
  if (direct != null) {
    return direct;
  }
  final upper = fingerprint.toUpperCase();
  for (final entry in lastSeen.entries) {
    if (entry.key.toUpperCase() == upper) {
      return entry.value;
    }
  }
  return null;
}

bool _containsIgnoreCase(Set<String> fingerprints, String fingerprint) {
  if (fingerprints.contains(fingerprint)) {
    return true;
  }
  final upper = fingerprint.toUpperCase();
  return fingerprints.any((e) => e.toUpperCase() == upper);
}

class PresenceState {
  /// When the presence was last evaluated.
  ///
  /// A friend going away produces no event, so the status has to be recomputed
  /// on a clock. Every heartbeat moves this forward, which re-runs the view
  /// provider and lets [presenceTimeout] expire.
  final DateTime tickAt;

  /// End of the last completed round, or null while none has finished since
  /// the chat tab was opened.
  final DateTime? lastRoundAt;

  /// Whether a round is in flight; also drives the refresh button's spinner.
  final bool probing;

  const PresenceState({
    required this.tickAt,
    required this.lastRoundAt,
    required this.probing,
  });

  PresenceState copyWith({
    DateTime? tickAt,
    DateTime? lastRoundAt,
    bool? probing,
  }) {
    return PresenceState(
      tickAt: tickAt ?? this.tickAt,
      lastRoundAt: lastRoundAt ?? this.lastRoundAt,
      probing: probing ?? this.probing,
    );
  }
}

/// Keeps the chat tab's online dots honest while the tab is open.
///
/// Discovery on its own only ever adds devices, so without this a friend that
/// closed the app would stay green until the user goes to the send tab and
/// scans by hand.
final presenceProvider = ReduxProvider<PresenceService, PresenceState>((ref) {
  return PresenceService();
});

class PresenceService extends ReduxNotifier<PresenceState> {
  Timer? _timer;

  @override
  PresenceState init() => PresenceState(
    tickAt: DateTime.now(),
    lastRoundAt: null,
    probing: false,
  );

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(presenceHeartbeatInterval, (_) {
      // ignore: discarded_futures
      global.dispatchAsync(PresenceHeartbeatAction());
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Starts the heartbeat and runs one round right away.
///
/// Idempotent: the chat tab dispatches this on mount and again whenever the app
/// returns to the foreground.
class StartPresenceWatchAction extends ReduxAction<PresenceService, PresenceState> with GlobalActions {
  @override
  PresenceState reduce() {
    notifier._startTimer();

    final now = DateTime.now();
    final lastRound = state.lastRoundAt;

    // Coming back after a long absence, what we knew is worthless. Forgetting
    // the round makes the UI say "checking" instead of declaring everyone gone.
    final stillFresh = lastRound != null && now.difference(lastRound) < presenceTimeout;

    // Built directly instead of via copyWith, which cannot clear a nullable.
    return PresenceState(
      tickAt: now,
      lastRoundAt: stillFresh ? lastRound : null,
      probing: state.probing,
    );
  }

  @override
  void after() {
    // ignore: discarded_futures
    global.dispatchAsync(PresenceHeartbeatAction());
  }
}

/// Stops the heartbeat when the chat tab goes away or the app is backgrounded.
class StopPresenceWatchAction extends ReduxAction<PresenceService, PresenceState> {
  @override
  PresenceState reduce() {
    notifier._stopTimer();
    return state;
  }
}

/// The manual refresh button: runs a round now and restarts the interval, so
/// the next automatic round is a full interval away.
class PresenceRefreshAction extends ReduxAction<PresenceService, PresenceState> with GlobalActions {
  @override
  PresenceState reduce() {
    notifier._startTimer();
    return state.copyWith(tickAt: DateTime.now());
  }

  @override
  void after() {
    // ignore: discarded_futures
    global.dispatchAsync(PresenceHeartbeatAction());
  }
}

/// One round: announce, probe the friends' known addresses, and let the
/// confirmations refresh [NearbyDevicesState.lastSeen] through the discovery
/// listener.
class PresenceHeartbeatAction extends AsyncGlobalAction {
  @override
  Future<void> reduce() async {
    if (ref.read(presenceProvider).probing) {
      // An announcement burst alone takes a few seconds; overlapping rounds
      // would only pile requests on the peers.
      return;
    }

    // The chat tab is destroyed when the user leaves it, so the timer is
    // normally gone already. These two keep a stray round from going out if
    // that ever stops being true, or while the window is minimised / in tray.
    if (ref.read(sleepProvider) || ref.read(homePageControllerProvider).currentTab != HomeTab.chat) {
      return;
    }

    final friends = ref.read(friendsProvider);
    if (friends.isEmpty) {
      // Nothing to be online. Still count it as a round so the UI leaves the
      // "checking" state.
      ref.redux(presenceProvider).dispatch(_FinishRoundAction());
      return;
    }

    // Prefers the discovered address over the stored one, so a friend whose
    // lease changed is probed where they actually are.
    final channels = <(String, int)>{};
    for (final friend in friends) {
      final target = ref.resolveChatTarget(friend.fingerprint);
      final ip = target?.ip;
      if (ip != null) {
        channels.add((ip, target!.port));
      }
    }

    final settings = ref.read(settingsProvider);

    ref.redux(presenceProvider).dispatch(_StartRoundAction());
    try {
      await ref
          .redux(nearbyDevicesProvider)
          .dispatchAsync(
            StartPresenceProbe(
              channels: channels.toList(),
              port: settings.port,
              https: settings.https,
            ),
          );
    } catch (e) {
      // The discovery isolate throws until it is up, which a round fired right
      // after start-up can hit. A round that never reached the network proves
      // nothing, so it must not complete: friends stay "checking" instead of
      // being declared offline on the strength of a failure of ours.
      _logger.warning('Presence heartbeat failed', e);
      ref.redux(presenceProvider).dispatch(_AbortRoundAction());
      return;
    }

    ref.redux(presenceProvider).dispatch(_FinishRoundAction());
  }
}

class _StartRoundAction extends ReduxAction<PresenceService, PresenceState> {
  @override
  PresenceState reduce() => state.copyWith(tickAt: DateTime.now(), probing: true);
}

/// Releases the round without recording it, so [PresenceState.lastRoundAt]
/// keeps meaning "we actually asked the network".
class _AbortRoundAction extends ReduxAction<PresenceService, PresenceState> {
  @override
  PresenceState reduce() => state.copyWith(tickAt: DateTime.now(), probing: false);
}

class _FinishRoundAction extends ReduxAction<PresenceService, PresenceState> {
  @override
  PresenceState reduce() {
    final now = DateTime.now();
    return state.copyWith(tickAt: now, lastRoundAt: now, probing: false);
  }
}
