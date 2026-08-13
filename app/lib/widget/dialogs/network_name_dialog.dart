import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:routerino/routerino.dart';

/// Asks the user to label the LAN they are currently on, so friends met here
/// land in a group they recognise ("公司", "家里", ...).
///
/// Pops the label, or null when the user cancels.
class NetworkNameDialog extends StatefulWidget {
  /// What we detected about the network, shown as a hint so the user can tell
  /// two networks apart when the label alone is ambiguous.
  final String? detectedName;

  const NetworkNameDialog({this.detectedName, super.key});

  static Future<String?> open(BuildContext context, {String? detectedName}) {
    return showDialog<String>(
      context: context,
      builder: (_) => NetworkNameDialog(detectedName: detectedName),
    );
  }

  @override
  State<NetworkNameDialog> createState() => _NetworkNameDialogState();
}

class _NetworkNameDialogState extends State<NetworkNameDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.detectedName ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    context.pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.dialogs.networkName.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.dialogs.networkName.description),
          const SizedBox(height: 15),
          TextFormField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: t.dialogs.networkName.hint),
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: t.dialogs.networkName.suggestions.map((suggestion) {
              return ActionChip(
                label: Text(suggestion),
                onPressed: () {
                  _controller.text = suggestion;
                  _controller.selection = TextSelection.collapsed(offset: suggestion.length);
                },
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text(t.general.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: _submit,
          child: Text(t.general.confirm),
        ),
      ],
    );
  }
}
