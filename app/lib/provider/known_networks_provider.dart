import 'package:collection/collection.dart';
import 'package:localsend_app/model/network_identity.dart';
import 'package:localsend_app/model/persistence/known_network.dart';
import 'package:localsend_app/provider/persistence_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// The LANs the user has named ("公司", "家里", ...), used to group friends.
final knownNetworksProvider = ReduxProvider<KnownNetworksService, List<KnownNetwork>>((ref) {
  return KnownNetworksService(ref.read(persistenceProvider));
});

class KnownNetworksService extends ReduxNotifier<List<KnownNetwork>> {
  final PersistenceService _persistence;

  KnownNetworksService(this._persistence);

  @override
  List<KnownNetwork> init() => _persistence.getKnownNetworks();
}

extension KnownNetworksExt on Iterable<KnownNetwork> {
  /// The stored network that [identity] most likely refers to, or null when
  /// none is a good enough match and the user should be asked to name it.
  ///
  /// Matching is fuzzy rather than an exact key lookup because which signals
  /// are available changes over time (docked vs. not, VPN on/off, a permission
  /// granted later). An exact match would create a duplicate group every time
  /// the available signal changed.
  KnownNetwork? findMatch(NetworkIdentity identity) {
    KnownNetwork? best;
    int bestScore = 0;
    for (final network in this) {
      final score = network.matchScore(identity);
      if (score > bestScore) {
        best = network;
        bestScore = score;
      }
    }
    return bestScore >= knownNetworkMatchThreshold ? best : null;
  }

  KnownNetwork? findById(String? id) {
    if (id == null) {
      return null;
    }
    return firstWhereOrNull((e) => e.id == id);
  }
}

class AddKnownNetworkAction extends AsyncReduxAction<KnownNetworksService, List<KnownNetwork>> {
  final KnownNetwork network;

  AddKnownNetworkAction(this.network);

  @override
  Future<List<KnownNetwork>> reduce() async {
    final updated = List<KnownNetwork>.unmodifiable([...state, network]);
    await notifier._persistence.setKnownNetworks(updated);
    return updated;
  }
}

class UpdateKnownNetworkAction extends AsyncReduxAction<KnownNetworksService, List<KnownNetwork>> {
  final KnownNetwork network;

  UpdateKnownNetworkAction(this.network);

  @override
  Future<List<KnownNetwork>> reduce() async {
    final index = state.indexWhere((e) => e.id == network.id);
    if (index == -1) {
      await Future.microtask(() {});
      return state;
    }
    final updated = List<KnownNetwork>.unmodifiable(
      <KnownNetwork>[...state]..replaceRange(index, index + 1, [network]),
    );
    await notifier._persistence.setKnownNetworks(updated);
    return updated;
  }
}

class RemoveKnownNetworkAction extends AsyncReduxAction<KnownNetworksService, List<KnownNetwork>> {
  final String id;

  RemoveKnownNetworkAction({required this.id});

  @override
  Future<List<KnownNetwork>> reduce() async {
    final updated = List<KnownNetwork>.unmodifiable(state.where((e) => e.id != id));
    if (updated.length == state.length) {
      return state;
    }
    await notifier._persistence.setKnownNetworks(updated);
    return updated;
  }
}

/// Folds the signals of [identity] into the matching network so the next
/// observation matches exactly. This is what lets a group survive access point
/// roaming or a signal becoming available later.
class MergeIdentityAction extends AsyncReduxAction<KnownNetworksService, List<KnownNetwork>> {
  final NetworkIdentity identity;

  MergeIdentityAction(this.identity);

  @override
  Future<List<KnownNetwork>> reduce() async {
    final match = state.findMatch(identity);
    if (match == null) {
      await Future.microtask(() {});
      return state;
    }
    final merged = match.mergeIdentity(identity);
    final index = state.indexWhere((e) => e.id == match.id);
    final updated = List<KnownNetwork>.unmodifiable(
      <KnownNetwork>[...state]..replaceRange(index, index + 1, [merged]),
    );
    await notifier._persistence.setKnownNetworks(updated);
    return updated;
  }
}
