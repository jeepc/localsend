import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:localsend_app/model/network_identity.dart';
import 'package:localsend_app/provider/local_ip_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/util/network_identity_helper.dart';
import 'package:localsend_isolates/util/network_interfaces.dart';
import 'package:logging/logging.dart';
import 'package:network_info_plus/network_info_plus.dart' as plugin;
import 'package:refena_flutter/refena_flutter.dart';

final _logger = Logger('NetworkIdentity');

/// Identifies the LAN this device is currently attached to, so friends can be
/// grouped by where the friendship lives (office, home, ...).
///
/// Recomputed only on connectivity changes / explicit refreshes, never on a
/// widget rebuild: every observation is several platform channel round trips.
final networkIdentityProvider = ReduxProvider<NetworkIdentityService, NetworkIdentity>((ref) {
  return NetworkIdentityService(
    ref.notifier(settingsProvider),
    ref.notifier(localIpProvider),
  );
});

class NetworkIdentityService extends ReduxNotifier<NetworkIdentity> {
  final SettingsService _settingsService;
  final LocalIpService _localIpService;

  NetworkIdentityService(this._settingsService, this._localIpService);

  @override
  NetworkIdentity init() => NetworkIdentity.unknown;
}

/// Re-observes the current network.
///
/// Dispatch this after [FetchLocalIpAction], on window focus and on
/// connectivity changes. On Windows there are no connectivity events (see
/// [InitLocalIpAction]), so a caller-driven refresh is the only signal.
class RefreshNetworkIdentityAction extends AsyncReduxAction<NetworkIdentityService, NetworkIdentity> {
  @override
  Future<NetworkIdentity> reduce() async {
    if (kIsWeb) {
      return state;
    }

    final vpnActive = await _isVpnActive();
    if (vpnActive && !state.isUnknown) {
      // With a VPN up the default route points at the tunnel, so a fresh
      // observation would describe the VPN and not the LAN. Freeze the last
      // known identity instead, otherwise every VPN toggle invents a network.
      _logger.info('VPN is active, keeping the previous network identity (${state.key}).');
      return state;
    }

    final info = plugin.NetworkInfo();

    // Each call gets its own try/catch: since network_info_plus 6.0.0 failures
    // surface as PlatformException instead of null, and getWifiSubmask in
    // particular throws when the IP is unavailable. One shared try would let a
    // single failing signal discard all the others.
    String? ssid;
    try {
      ssid = await info.getWifiName();
    } catch (e) {
      _logger.fine('Failed to get the SSID', e);
    }

    String? bssid;
    if (!checkPlatform([TargetPlatform.linux])) {
      // On Linux the plugin returns the local Wi-Fi card's permanent hardware
      // address rather than the access point's BSSID. That value is identical
      // on every network, so trusting it would merge all LANs into one group.
      try {
        bssid = await info.getWifiBSSID();
      } catch (e) {
        _logger.fine('Failed to get the BSSID', e);
      }
    }

    String? gatewayIp;
    try {
      gatewayIp = await info.getWifiGatewayIP();
    } catch (e) {
      _logger.fine('Failed to get the gateway IP', e);
    }

    final localIp = notifier._localIpService.state.localIps.firstOrNull;
    final interfaceName = await _interfaceNameOf(
      localIp,
      whitelist: notifier._settingsService.state.networkWhitelist,
      blacklist: notifier._settingsService.state.networkBlacklist,
    );

    final identity = buildNetworkIdentity(
      ssid: ssid,
      bssid: bssid,
      gatewayIp: gatewayIp,
      localIp: localIp,
      interfaceName: interfaceName,
      vpnActive: vpnActive,
      observedAt: DateTime.now().toUtc(),
    );

    if (identity.key != state.key) {
      _logger.info('Network identity: ${identity.key} (${identity.source.name})');
    }

    return identity;
  }
}

Future<bool> _isVpnActive() async {
  try {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.vpn);
  } catch (e) {
    _logger.fine('Failed to read the connectivity state', e);
    return false;
  }
}

/// Name of the interface holding [localIp].
///
/// Goes through [getNetworkInterfaces] so the user's whitelist/blacklist keeps
/// Docker, WSL, Hyper-V and VMware adapters out. Their addresses are stable per
/// machine, so an unfiltered virtual adapter happily masquerades as a LAN.
Future<String?> _interfaceNameOf(
  String? localIp, {
  required List<String>? whitelist,
  required List<String>? blacklist,
}) async {
  if (localIp == null) {
    return null;
  }
  try {
    final interfaces = await getNetworkInterfaces(whitelist: whitelist, blacklist: blacklist);
    for (final interface in interfaces) {
      if (interface.addresses.any((a) => a.address == localIp)) {
        return interface.name;
      }
    }
  } catch (e) {
    _logger.fine('Failed to enumerate network interfaces', e);
  }
  return null;
}

/// Global wrapper around [RefreshNetworkIdentityAction], so providers that
/// cannot hold a reference to [NetworkIdentityService] (it depends on them) can
/// still ask for a refresh.
class RefreshNetworkIdentityGlobalAction extends AsyncGlobalAction {
  @override
  Future<void> reduce() async {
    await ref.redux(networkIdentityProvider).dispatchAsync(RefreshNetworkIdentityAction());
  }
}
