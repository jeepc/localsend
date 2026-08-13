import 'package:dart_mappable/dart_mappable.dart';
import 'package:localsend_isolates/model/device.dart';

part 'nearby_devices_state.mapper.dart';

@MappableClass()
class NearbyDevicesState with NearbyDevicesStateMappable {
  final bool runningFavoriteScan;
  final Set<String> runningIps; // list of local ips

  /// Whether a full discovery scan has run since the last clear.
  ///
  /// The send tab's open-once scan keys off this instead of off [devices] being
  /// empty: the chat presence heartbeat also fills [devices], but only with
  /// friends, so a non-empty map is no longer proof that the network was swept.
  final bool initialScanDone;
  final Map<String, Device> devices; // fingerprint -> device

  /// When each device was last confirmed, keyed by fingerprint.
  ///
  /// [devices] only ever grows, so it cannot answer "is this device still
  /// there?". This does: the discovery re-emits a device on every
  /// confirmation, so an entry that stops moving means the device stopped
  /// answering. Kept in RAM only, so plain [DateTime.now] is the clock.
  final Map<String, DateTime> lastSeen;

  /// Devices that are discovered via signaling server.
  /// The key is the fingerprint of the device.
  /// We do not trust the fingerprint, so we allow multiple devices with the same fingerprint.
  final Map<String, Set<Device>> signalingDevices;

  const NearbyDevicesState({
    required this.runningFavoriteScan,
    required this.runningIps,
    required this.initialScanDone,
    required this.devices,
    required this.lastSeen,
    required this.signalingDevices,
  });

  Map<String, Device> get allDevices {
    final Map<String, Device> allDevices = {};
    allDevices.addAll(devices);
    for (final devices in signalingDevices.values) {
      for (final device in devices) {
        final currentDevice = allDevices[device.fingerprint];
        if (currentDevice != null && currentDevice.alias == device.alias) {
          allDevices[device.fingerprint] = currentDevice.merge(device);
        } else {
          allDevices[device.fingerprint] = device;
        }
      }
    }
    return allDevices;
  }
}

extension on Device {
  Device merge(Device other) {
    return Device(
      signalingId: signalingId ?? other.signalingId,
      ip: ip ?? other.ip,
      version: version,
      port: port,
      https: https,
      fingerprint: fingerprint,
      alias: alias,
      deviceModel: deviceModel,
      deviceType: deviceType,
      download: download,
      channels: [
        ...channels,
        for (final channel in other.channels)
          if (!channels.contains(channel)) channel,
      ],
    );
  }
}
