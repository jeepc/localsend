// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'known_network.dart';

class KnownNetworkMapper extends ClassMapperBase<KnownNetwork> {
  KnownNetworkMapper._();

  static KnownNetworkMapper? _instance;
  static KnownNetworkMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = KnownNetworkMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'KnownNetwork';

  static String _$id(KnownNetwork v) => v.id;
  static const Field<KnownNetwork, String> _f$id = Field('id', _$id);
  static String _$label(KnownNetwork v) => v.label;
  static const Field<KnownNetwork, String> _f$label = Field('label', _$label);
  static List<String> _$keys(KnownNetwork v) => v.keys;
  static const Field<KnownNetwork, List<String>> _f$keys = Field(
    'keys',
    _$keys,
  );
  static List<String> _$bssids(KnownNetwork v) => v.bssids;
  static const Field<KnownNetwork, List<String>> _f$bssids = Field(
    'bssids',
    _$bssids,
  );
  static String? _$ssid(KnownNetwork v) => v.ssid;
  static const Field<KnownNetwork, String> _f$ssid = Field('ssid', _$ssid);
  static String? _$gatewayIp(KnownNetwork v) => v.gatewayIp;
  static const Field<KnownNetwork, String> _f$gatewayIp = Field(
    'gatewayIp',
    _$gatewayIp,
  );
  static String? _$subnetCidr(KnownNetwork v) => v.subnetCidr;
  static const Field<KnownNetwork, String> _f$subnetCidr = Field(
    'subnetCidr',
    _$subnetCidr,
  );
  static DateTime _$lastSeen(KnownNetwork v) => v.lastSeen;
  static const Field<KnownNetwork, DateTime> _f$lastSeen = Field(
    'lastSeen',
    _$lastSeen,
  );

  @override
  final MappableFields<KnownNetwork> fields = const {
    #id: _f$id,
    #label: _f$label,
    #keys: _f$keys,
    #bssids: _f$bssids,
    #ssid: _f$ssid,
    #gatewayIp: _f$gatewayIp,
    #subnetCidr: _f$subnetCidr,
    #lastSeen: _f$lastSeen,
  };

  static KnownNetwork _instantiate(DecodingData data) {
    return KnownNetwork(
      id: data.dec(_f$id),
      label: data.dec(_f$label),
      keys: data.dec(_f$keys),
      bssids: data.dec(_f$bssids),
      ssid: data.dec(_f$ssid),
      gatewayIp: data.dec(_f$gatewayIp),
      subnetCidr: data.dec(_f$subnetCidr),
      lastSeen: data.dec(_f$lastSeen),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static KnownNetwork fromJson(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<KnownNetwork>(map);
  }

  static KnownNetwork deserialize(String json) {
    return ensureInitialized().decodeJson<KnownNetwork>(json);
  }
}

mixin KnownNetworkMappable {
  String serialize() {
    return KnownNetworkMapper.ensureInitialized().encodeJson<KnownNetwork>(
      this as KnownNetwork,
    );
  }

  Map<String, dynamic> toJson() {
    return KnownNetworkMapper.ensureInitialized().encodeMap<KnownNetwork>(
      this as KnownNetwork,
    );
  }

  KnownNetworkCopyWith<KnownNetwork, KnownNetwork, KnownNetwork> get copyWith =>
      _KnownNetworkCopyWithImpl<KnownNetwork, KnownNetwork>(
        this as KnownNetwork,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return KnownNetworkMapper.ensureInitialized().stringifyValue(
      this as KnownNetwork,
    );
  }

  @override
  bool operator ==(Object other) {
    return KnownNetworkMapper.ensureInitialized().equalsValue(
      this as KnownNetwork,
      other,
    );
  }

  @override
  int get hashCode {
    return KnownNetworkMapper.ensureInitialized().hashValue(
      this as KnownNetwork,
    );
  }
}

extension KnownNetworkValueCopy<$R, $Out>
    on ObjectCopyWith<$R, KnownNetwork, $Out> {
  KnownNetworkCopyWith<$R, KnownNetwork, $Out> get $asKnownNetwork =>
      $base.as((v, t, t2) => _KnownNetworkCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class KnownNetworkCopyWith<$R, $In extends KnownNetwork, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get keys;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get bssids;
  $R call({
    String? id,
    String? label,
    List<String>? keys,
    List<String>? bssids,
    String? ssid,
    String? gatewayIp,
    String? subnetCidr,
    DateTime? lastSeen,
  });
  KnownNetworkCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _KnownNetworkCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, KnownNetwork, $Out>
    implements KnownNetworkCopyWith<$R, KnownNetwork, $Out> {
  _KnownNetworkCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<KnownNetwork> $mapper =
      KnownNetworkMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get keys =>
      ListCopyWith(
        $value.keys,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(keys: v),
      );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get bssids =>
      ListCopyWith(
        $value.bssids,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(bssids: v),
      );
  @override
  $R call({
    String? id,
    String? label,
    List<String>? keys,
    List<String>? bssids,
    Object? ssid = $none,
    Object? gatewayIp = $none,
    Object? subnetCidr = $none,
    DateTime? lastSeen,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (label != null) #label: label,
      if (keys != null) #keys: keys,
      if (bssids != null) #bssids: bssids,
      if (ssid != $none) #ssid: ssid,
      if (gatewayIp != $none) #gatewayIp: gatewayIp,
      if (subnetCidr != $none) #subnetCidr: subnetCidr,
      if (lastSeen != null) #lastSeen: lastSeen,
    }),
  );
  @override
  KnownNetwork $make(CopyWithData data) => KnownNetwork(
    id: data.get(#id, or: $value.id),
    label: data.get(#label, or: $value.label),
    keys: data.get(#keys, or: $value.keys),
    bssids: data.get(#bssids, or: $value.bssids),
    ssid: data.get(#ssid, or: $value.ssid),
    gatewayIp: data.get(#gatewayIp, or: $value.gatewayIp),
    subnetCidr: data.get(#subnetCidr, or: $value.subnetCidr),
    lastSeen: data.get(#lastSeen, or: $value.lastSeen),
  );

  @override
  KnownNetworkCopyWith<$R2, KnownNetwork, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _KnownNetworkCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

