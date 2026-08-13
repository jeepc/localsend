// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'pending_friend_request.dart';

class PendingFriendRequestMapper extends ClassMapperBase<PendingFriendRequest> {
  PendingFriendRequestMapper._();

  static PendingFriendRequestMapper? _instance;
  static PendingFriendRequestMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PendingFriendRequestMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'PendingFriendRequest';

  static String _$requestId(PendingFriendRequest v) => v.requestId;
  static const Field<PendingFriendRequest, String> _f$requestId = Field(
    'requestId',
    _$requestId,
  );
  static String _$fingerprint(PendingFriendRequest v) => v.fingerprint;
  static const Field<PendingFriendRequest, String> _f$fingerprint = Field(
    'fingerprint',
    _$fingerprint,
  );
  static String _$alias(PendingFriendRequest v) => v.alias;
  static const Field<PendingFriendRequest, String> _f$alias = Field(
    'alias',
    _$alias,
  );
  static String? _$ip(PendingFriendRequest v) => v.ip;
  static const Field<PendingFriendRequest, String> _f$ip = Field('ip', _$ip);
  static int _$port(PendingFriendRequest v) => v.port;
  static const Field<PendingFriendRequest, int> _f$port = Field('port', _$port);
  static String? _$networkId(PendingFriendRequest v) => v.networkId;
  static const Field<PendingFriendRequest, String> _f$networkId = Field(
    'networkId',
    _$networkId,
  );
  static DateTime _$createdAt(PendingFriendRequest v) => v.createdAt;
  static const Field<PendingFriendRequest, DateTime> _f$createdAt = Field(
    'createdAt',
    _$createdAt,
  );

  @override
  final MappableFields<PendingFriendRequest> fields = const {
    #requestId: _f$requestId,
    #fingerprint: _f$fingerprint,
    #alias: _f$alias,
    #ip: _f$ip,
    #port: _f$port,
    #networkId: _f$networkId,
    #createdAt: _f$createdAt,
  };

  static PendingFriendRequest _instantiate(DecodingData data) {
    return PendingFriendRequest(
      requestId: data.dec(_f$requestId),
      fingerprint: data.dec(_f$fingerprint),
      alias: data.dec(_f$alias),
      ip: data.dec(_f$ip),
      port: data.dec(_f$port),
      networkId: data.dec(_f$networkId),
      createdAt: data.dec(_f$createdAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PendingFriendRequest fromJson(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PendingFriendRequest>(map);
  }

  static PendingFriendRequest deserialize(String json) {
    return ensureInitialized().decodeJson<PendingFriendRequest>(json);
  }
}

mixin PendingFriendRequestMappable {
  String serialize() {
    return PendingFriendRequestMapper.ensureInitialized()
        .encodeJson<PendingFriendRequest>(this as PendingFriendRequest);
  }

  Map<String, dynamic> toJson() {
    return PendingFriendRequestMapper.ensureInitialized()
        .encodeMap<PendingFriendRequest>(this as PendingFriendRequest);
  }

  PendingFriendRequestCopyWith<
    PendingFriendRequest,
    PendingFriendRequest,
    PendingFriendRequest
  >
  get copyWith =>
      _PendingFriendRequestCopyWithImpl<
        PendingFriendRequest,
        PendingFriendRequest
      >(this as PendingFriendRequest, $identity, $identity);
  @override
  String toString() {
    return PendingFriendRequestMapper.ensureInitialized().stringifyValue(
      this as PendingFriendRequest,
    );
  }

  @override
  bool operator ==(Object other) {
    return PendingFriendRequestMapper.ensureInitialized().equalsValue(
      this as PendingFriendRequest,
      other,
    );
  }

  @override
  int get hashCode {
    return PendingFriendRequestMapper.ensureInitialized().hashValue(
      this as PendingFriendRequest,
    );
  }
}

extension PendingFriendRequestValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PendingFriendRequest, $Out> {
  PendingFriendRequestCopyWith<$R, PendingFriendRequest, $Out>
  get $asPendingFriendRequest => $base.as(
    (v, t, t2) => _PendingFriendRequestCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class PendingFriendRequestCopyWith<
  $R,
  $In extends PendingFriendRequest,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? requestId,
    String? fingerprint,
    String? alias,
    String? ip,
    int? port,
    String? networkId,
    DateTime? createdAt,
  });
  PendingFriendRequestCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _PendingFriendRequestCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PendingFriendRequest, $Out>
    implements PendingFriendRequestCopyWith<$R, PendingFriendRequest, $Out> {
  _PendingFriendRequestCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PendingFriendRequest> $mapper =
      PendingFriendRequestMapper.ensureInitialized();
  @override
  $R call({
    String? requestId,
    String? fingerprint,
    String? alias,
    Object? ip = $none,
    int? port,
    Object? networkId = $none,
    DateTime? createdAt,
  }) => $apply(
    FieldCopyWithData({
      if (requestId != null) #requestId: requestId,
      if (fingerprint != null) #fingerprint: fingerprint,
      if (alias != null) #alias: alias,
      if (ip != $none) #ip: ip,
      if (port != null) #port: port,
      if (networkId != $none) #networkId: networkId,
      if (createdAt != null) #createdAt: createdAt,
    }),
  );
  @override
  PendingFriendRequest $make(CopyWithData data) => PendingFriendRequest(
    requestId: data.get(#requestId, or: $value.requestId),
    fingerprint: data.get(#fingerprint, or: $value.fingerprint),
    alias: data.get(#alias, or: $value.alias),
    ip: data.get(#ip, or: $value.ip),
    port: data.get(#port, or: $value.port),
    networkId: data.get(#networkId, or: $value.networkId),
    createdAt: data.get(#createdAt, or: $value.createdAt),
  );

  @override
  PendingFriendRequestCopyWith<$R2, PendingFriendRequest, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _PendingFriendRequestCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

