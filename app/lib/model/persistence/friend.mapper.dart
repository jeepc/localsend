// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'friend.dart';

class FriendMapper extends ClassMapperBase<Friend> {
  FriendMapper._();

  static FriendMapper? _instance;
  static FriendMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FriendMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Friend';

  static String _$id(Friend v) => v.id;
  static const Field<Friend, String> _f$id = Field('id', _$id);
  static String _$fingerprint(Friend v) => v.fingerprint;
  static const Field<Friend, String> _f$fingerprint = Field(
    'fingerprint',
    _$fingerprint,
  );
  static String _$alias(Friend v) => v.alias;
  static const Field<Friend, String> _f$alias = Field('alias', _$alias);
  static String? _$customAlias(Friend v) => v.customAlias;
  static const Field<Friend, String> _f$customAlias = Field(
    'customAlias',
    _$customAlias,
  );
  static String? _$lastIp(Friend v) => v.lastIp;
  static const Field<Friend, String> _f$lastIp = Field('lastIp', _$lastIp);
  static int _$lastPort(Friend v) => v.lastPort;
  static const Field<Friend, int> _f$lastPort = Field('lastPort', _$lastPort);
  static String? _$networkId(Friend v) => v.networkId;
  static const Field<Friend, String> _f$networkId = Field(
    'networkId',
    _$networkId,
  );
  static DateTime _$addedAt(Friend v) => v.addedAt;
  static const Field<Friend, DateTime> _f$addedAt = Field('addedAt', _$addedAt);

  @override
  final MappableFields<Friend> fields = const {
    #id: _f$id,
    #fingerprint: _f$fingerprint,
    #alias: _f$alias,
    #customAlias: _f$customAlias,
    #lastIp: _f$lastIp,
    #lastPort: _f$lastPort,
    #networkId: _f$networkId,
    #addedAt: _f$addedAt,
  };

  static Friend _instantiate(DecodingData data) {
    return Friend(
      id: data.dec(_f$id),
      fingerprint: data.dec(_f$fingerprint),
      alias: data.dec(_f$alias),
      customAlias: data.dec(_f$customAlias),
      lastIp: data.dec(_f$lastIp),
      lastPort: data.dec(_f$lastPort),
      networkId: data.dec(_f$networkId),
      addedAt: data.dec(_f$addedAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Friend fromJson(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Friend>(map);
  }

  static Friend deserialize(String json) {
    return ensureInitialized().decodeJson<Friend>(json);
  }
}

mixin FriendMappable {
  String serialize() {
    return FriendMapper.ensureInitialized().encodeJson<Friend>(this as Friend);
  }

  Map<String, dynamic> toJson() {
    return FriendMapper.ensureInitialized().encodeMap<Friend>(this as Friend);
  }

  FriendCopyWith<Friend, Friend, Friend> get copyWith =>
      _FriendCopyWithImpl<Friend, Friend>(this as Friend, $identity, $identity);
  @override
  String toString() {
    return FriendMapper.ensureInitialized().stringifyValue(this as Friend);
  }

  @override
  bool operator ==(Object other) {
    return FriendMapper.ensureInitialized().equalsValue(this as Friend, other);
  }

  @override
  int get hashCode {
    return FriendMapper.ensureInitialized().hashValue(this as Friend);
  }
}

extension FriendValueCopy<$R, $Out> on ObjectCopyWith<$R, Friend, $Out> {
  FriendCopyWith<$R, Friend, $Out> get $asFriend =>
      $base.as((v, t, t2) => _FriendCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class FriendCopyWith<$R, $In extends Friend, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? fingerprint,
    String? alias,
    String? customAlias,
    String? lastIp,
    int? lastPort,
    String? networkId,
    DateTime? addedAt,
  });
  FriendCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _FriendCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Friend, $Out>
    implements FriendCopyWith<$R, Friend, $Out> {
  _FriendCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Friend> $mapper = FriendMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    String? fingerprint,
    String? alias,
    Object? customAlias = $none,
    Object? lastIp = $none,
    int? lastPort,
    Object? networkId = $none,
    DateTime? addedAt,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (fingerprint != null) #fingerprint: fingerprint,
      if (alias != null) #alias: alias,
      if (customAlias != $none) #customAlias: customAlias,
      if (lastIp != $none) #lastIp: lastIp,
      if (lastPort != null) #lastPort: lastPort,
      if (networkId != $none) #networkId: networkId,
      if (addedAt != null) #addedAt: addedAt,
    }),
  );
  @override
  Friend $make(CopyWithData data) => Friend(
    id: data.get(#id, or: $value.id),
    fingerprint: data.get(#fingerprint, or: $value.fingerprint),
    alias: data.get(#alias, or: $value.alias),
    customAlias: data.get(#customAlias, or: $value.customAlias),
    lastIp: data.get(#lastIp, or: $value.lastIp),
    lastPort: data.get(#lastPort, or: $value.lastPort),
    networkId: data.get(#networkId, or: $value.networkId),
    addedAt: data.get(#addedAt, or: $value.addedAt),
  );

  @override
  FriendCopyWith<$R2, Friend, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _FriendCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

