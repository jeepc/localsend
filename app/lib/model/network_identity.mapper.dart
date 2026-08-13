// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'network_identity.dart';

class NetworkSignalSourceMapper extends EnumMapper<NetworkSignalSource> {
  NetworkSignalSourceMapper._();

  static NetworkSignalSourceMapper? _instance;
  static NetworkSignalSourceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = NetworkSignalSourceMapper._());
    }
    return _instance!;
  }

  static NetworkSignalSource fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  NetworkSignalSource decode(dynamic value) {
    switch (value) {
      case r'ssid':
        return NetworkSignalSource.ssid;
      case r'gateway':
        return NetworkSignalSource.gateway;
      case r'subnet':
        return NetworkSignalSource.subnet;
      case r'interfaceOnly':
        return NetworkSignalSource.interfaceOnly;
      case r'unknown':
        return NetworkSignalSource.unknown;
      default:
        return NetworkSignalSource.values[4];
    }
  }

  @override
  dynamic encode(NetworkSignalSource self) {
    switch (self) {
      case NetworkSignalSource.ssid:
        return r'ssid';
      case NetworkSignalSource.gateway:
        return r'gateway';
      case NetworkSignalSource.subnet:
        return r'subnet';
      case NetworkSignalSource.interfaceOnly:
        return r'interfaceOnly';
      case NetworkSignalSource.unknown:
        return r'unknown';
    }
  }
}

extension NetworkSignalSourceMapperExtension on NetworkSignalSource {
  String toValue() {
    NetworkSignalSourceMapper.ensureInitialized();
    return MapperContainer.globals.toValue<NetworkSignalSource>(this) as String;
  }
}

class NetworkIdentityMapper extends ClassMapperBase<NetworkIdentity> {
  NetworkIdentityMapper._();

  static NetworkIdentityMapper? _instance;
  static NetworkIdentityMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = NetworkIdentityMapper._());
      NetworkSignalSourceMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'NetworkIdentity';

  static String _$key(NetworkIdentity v) => v.key;
  static const Field<NetworkIdentity, String> _f$key = Field('key', _$key);
  static NetworkSignalSource _$source(NetworkIdentity v) => v.source;
  static const Field<NetworkIdentity, NetworkSignalSource> _f$source = Field(
    'source',
    _$source,
  );
  static String? _$ssid(NetworkIdentity v) => v.ssid;
  static const Field<NetworkIdentity, String> _f$ssid = Field('ssid', _$ssid);
  static String? _$bssid(NetworkIdentity v) => v.bssid;
  static const Field<NetworkIdentity, String> _f$bssid = Field(
    'bssid',
    _$bssid,
  );
  static String? _$gatewayIp(NetworkIdentity v) => v.gatewayIp;
  static const Field<NetworkIdentity, String> _f$gatewayIp = Field(
    'gatewayIp',
    _$gatewayIp,
  );
  static String? _$subnetCidr(NetworkIdentity v) => v.subnetCidr;
  static const Field<NetworkIdentity, String> _f$subnetCidr = Field(
    'subnetCidr',
    _$subnetCidr,
  );
  static String? _$localIp(NetworkIdentity v) => v.localIp;
  static const Field<NetworkIdentity, String> _f$localIp = Field(
    'localIp',
    _$localIp,
  );
  static String? _$interfaceName(NetworkIdentity v) => v.interfaceName;
  static const Field<NetworkIdentity, String> _f$interfaceName = Field(
    'interfaceName',
    _$interfaceName,
  );
  static bool _$vpnActive(NetworkIdentity v) => v.vpnActive;
  static const Field<NetworkIdentity, bool> _f$vpnActive = Field(
    'vpnActive',
    _$vpnActive,
  );
  static DateTime _$observedAt(NetworkIdentity v) => v.observedAt;
  static const Field<NetworkIdentity, DateTime> _f$observedAt = Field(
    'observedAt',
    _$observedAt,
  );

  @override
  final MappableFields<NetworkIdentity> fields = const {
    #key: _f$key,
    #source: _f$source,
    #ssid: _f$ssid,
    #bssid: _f$bssid,
    #gatewayIp: _f$gatewayIp,
    #subnetCidr: _f$subnetCidr,
    #localIp: _f$localIp,
    #interfaceName: _f$interfaceName,
    #vpnActive: _f$vpnActive,
    #observedAt: _f$observedAt,
  };

  static NetworkIdentity _instantiate(DecodingData data) {
    return NetworkIdentity(
      key: data.dec(_f$key),
      source: data.dec(_f$source),
      ssid: data.dec(_f$ssid),
      bssid: data.dec(_f$bssid),
      gatewayIp: data.dec(_f$gatewayIp),
      subnetCidr: data.dec(_f$subnetCidr),
      localIp: data.dec(_f$localIp),
      interfaceName: data.dec(_f$interfaceName),
      vpnActive: data.dec(_f$vpnActive),
      observedAt: data.dec(_f$observedAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static NetworkIdentity fromJson(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<NetworkIdentity>(map);
  }

  static NetworkIdentity deserialize(String json) {
    return ensureInitialized().decodeJson<NetworkIdentity>(json);
  }
}

mixin NetworkIdentityMappable {
  String serialize() {
    return NetworkIdentityMapper.ensureInitialized()
        .encodeJson<NetworkIdentity>(this as NetworkIdentity);
  }

  Map<String, dynamic> toJson() {
    return NetworkIdentityMapper.ensureInitialized().encodeMap<NetworkIdentity>(
      this as NetworkIdentity,
    );
  }

  NetworkIdentityCopyWith<NetworkIdentity, NetworkIdentity, NetworkIdentity>
  get copyWith =>
      _NetworkIdentityCopyWithImpl<NetworkIdentity, NetworkIdentity>(
        this as NetworkIdentity,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return NetworkIdentityMapper.ensureInitialized().stringifyValue(
      this as NetworkIdentity,
    );
  }

  @override
  bool operator ==(Object other) {
    return NetworkIdentityMapper.ensureInitialized().equalsValue(
      this as NetworkIdentity,
      other,
    );
  }

  @override
  int get hashCode {
    return NetworkIdentityMapper.ensureInitialized().hashValue(
      this as NetworkIdentity,
    );
  }
}

extension NetworkIdentityValueCopy<$R, $Out>
    on ObjectCopyWith<$R, NetworkIdentity, $Out> {
  NetworkIdentityCopyWith<$R, NetworkIdentity, $Out> get $asNetworkIdentity =>
      $base.as((v, t, t2) => _NetworkIdentityCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class NetworkIdentityCopyWith<$R, $In extends NetworkIdentity, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? key,
    NetworkSignalSource? source,
    String? ssid,
    String? bssid,
    String? gatewayIp,
    String? subnetCidr,
    String? localIp,
    String? interfaceName,
    bool? vpnActive,
    DateTime? observedAt,
  });
  NetworkIdentityCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _NetworkIdentityCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, NetworkIdentity, $Out>
    implements NetworkIdentityCopyWith<$R, NetworkIdentity, $Out> {
  _NetworkIdentityCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<NetworkIdentity> $mapper =
      NetworkIdentityMapper.ensureInitialized();
  @override
  $R call({
    String? key,
    NetworkSignalSource? source,
    Object? ssid = $none,
    Object? bssid = $none,
    Object? gatewayIp = $none,
    Object? subnetCidr = $none,
    Object? localIp = $none,
    Object? interfaceName = $none,
    bool? vpnActive,
    DateTime? observedAt,
  }) => $apply(
    FieldCopyWithData({
      if (key != null) #key: key,
      if (source != null) #source: source,
      if (ssid != $none) #ssid: ssid,
      if (bssid != $none) #bssid: bssid,
      if (gatewayIp != $none) #gatewayIp: gatewayIp,
      if (subnetCidr != $none) #subnetCidr: subnetCidr,
      if (localIp != $none) #localIp: localIp,
      if (interfaceName != $none) #interfaceName: interfaceName,
      if (vpnActive != null) #vpnActive: vpnActive,
      if (observedAt != null) #observedAt: observedAt,
    }),
  );
  @override
  NetworkIdentity $make(CopyWithData data) => NetworkIdentity(
    key: data.get(#key, or: $value.key),
    source: data.get(#source, or: $value.source),
    ssid: data.get(#ssid, or: $value.ssid),
    bssid: data.get(#bssid, or: $value.bssid),
    gatewayIp: data.get(#gatewayIp, or: $value.gatewayIp),
    subnetCidr: data.get(#subnetCidr, or: $value.subnetCidr),
    localIp: data.get(#localIp, or: $value.localIp),
    interfaceName: data.get(#interfaceName, or: $value.interfaceName),
    vpnActive: data.get(#vpnActive, or: $value.vpnActive),
    observedAt: data.get(#observedAt, or: $value.observedAt),
  );

  @override
  NetworkIdentityCopyWith<$R2, NetworkIdentity, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _NetworkIdentityCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

