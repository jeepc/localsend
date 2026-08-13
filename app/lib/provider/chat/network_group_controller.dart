import 'package:localsend_app/model/persistence/known_network.dart';
import 'package:localsend_app/provider/known_networks_provider.dart';
import 'package:localsend_app/provider/network_identity_provider.dart';
import 'package:localsend_app/widget/dialogs/network_name_dialog.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

/// Resolves the group the current LAN belongs to, asking the user to name it
/// the first time we see that network.
///
/// Returns the group id, or null when the network cannot be identified or the
/// user dismissed the naming dialog. Only call this from a user-initiated flow:
/// it can show a dialog.
class EnsureCurrentNetworkGroupAction extends AsyncGlobalActionWithResult<String?> {
  /// When false, an unknown network yields null instead of prompting.
  final bool promptIfUnknown;

  EnsureCurrentNetworkGroupAction({this.promptIfUnknown = true});

  @override
  Future<String?> reduce() async {
    await ref.redux(networkIdentityProvider).dispatchAsync(RefreshNetworkIdentityAction());
    final identity = ref.read(networkIdentityProvider);
    if (identity.isUnknown) {
      return null;
    }

    final match = ref.read(knownNetworksProvider).findMatch(identity);
    if (match != null) {
      // Absorb the current signals so the next observation matches exactly,
      // even if the signal that produced this key disappears.
      await ref.redux(knownNetworksProvider).dispatchAsync(MergeIdentityAction(identity));
      return match.id;
    }

    if (!promptIfUnknown) {
      return null;
    }

    // ignore: use_build_context_synchronously
    final label = await NetworkNameDialog.open(Routerino.context, detectedName: identity.ssid);
    if (label == null) {
      return null;
    }

    final network = KnownNetwork.fromIdentity(label: label, identity: identity);
    await ref.redux(knownNetworksProvider).dispatchAsync(AddKnownNetworkAction(network));
    return network.id;
  }
}
