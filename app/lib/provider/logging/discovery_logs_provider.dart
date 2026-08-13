import 'package:localsend_app/model/log_entry.dart';
import 'package:logging/logging.dart';
import 'package:refena_flutter/refena_flutter.dart';

final _logger = Logger('Discovery');

/// Contains the discovery logs for debugging purposes.
final discoveryLoggerProvider = NotifierProvider<DiscoveryLogger, List<LogEntry>>((ref) {
  return DiscoveryLogger();
});

class DiscoveryLogger extends Notifier<List<LogEntry>> {
  static const _maxEntries = 200;

  DiscoveryLogger();

  @override
  List<LogEntry> init() {
    return [];
  }

  void addLog(String log) {
    _logger.info(log);
    final entries = [
      ...state,
      LogEntry(timestamp: DateTime.now(), log: log),
    ];
    // Drop from the front: taking the first entries would pin the log to the
    // oldest 200 lines and silently discard everything after, which is the
    // opposite of what the troubleshoot page needs.
    state = entries.length <= _maxEntries ? entries : entries.sublist(entries.length - _maxEntries);
  }

  void clear() {
    state = [];
  }
}
