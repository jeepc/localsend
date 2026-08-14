// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'chat_message.dart';

class ChatMessageTypeMapper extends EnumMapper<ChatMessageType> {
  ChatMessageTypeMapper._();

  static ChatMessageTypeMapper? _instance;
  static ChatMessageTypeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChatMessageTypeMapper._());
    }
    return _instance!;
  }

  static ChatMessageType fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ChatMessageType decode(dynamic value) {
    switch (value) {
      case r'text':
        return ChatMessageType.text;
      case r'file':
        return ChatMessageType.file;
      case r'image':
        return ChatMessageType.image;
      default:
        return ChatMessageType.values[0];
    }
  }

  @override
  dynamic encode(ChatMessageType self) {
    switch (self) {
      case ChatMessageType.text:
        return r'text';
      case ChatMessageType.file:
        return r'file';
      case ChatMessageType.image:
        return r'image';
    }
  }
}

extension ChatMessageTypeMapperExtension on ChatMessageType {
  String toValue() {
    ChatMessageTypeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ChatMessageType>(this) as String;
  }
}

class ChatMessageStatusMapper extends EnumMapper<ChatMessageStatus> {
  ChatMessageStatusMapper._();

  static ChatMessageStatusMapper? _instance;
  static ChatMessageStatusMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChatMessageStatusMapper._());
    }
    return _instance!;
  }

  static ChatMessageStatus fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ChatMessageStatus decode(dynamic value) {
    switch (value) {
      case r'sending':
        return ChatMessageStatus.sending;
      case r'sent':
        return ChatMessageStatus.sent;
      case r'failed':
        return ChatMessageStatus.failed;
      case r'received':
        return ChatMessageStatus.received;
      default:
        return ChatMessageStatus.values[1];
    }
  }

  @override
  dynamic encode(ChatMessageStatus self) {
    switch (self) {
      case ChatMessageStatus.sending:
        return r'sending';
      case ChatMessageStatus.sent:
        return r'sent';
      case ChatMessageStatus.failed:
        return r'failed';
      case ChatMessageStatus.received:
        return r'received';
    }
  }
}

extension ChatMessageStatusMapperExtension on ChatMessageStatus {
  String toValue() {
    ChatMessageStatusMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ChatMessageStatus>(this) as String;
  }
}

class ChatMessageMapper extends ClassMapperBase<ChatMessage> {
  ChatMessageMapper._();

  static ChatMessageMapper? _instance;
  static ChatMessageMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChatMessageMapper._());
      ChatMessageTypeMapper.ensureInitialized();
      ChatMessageStatusMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ChatMessage';

  static String _$id(ChatMessage v) => v.id;
  static const Field<ChatMessage, String> _f$id = Field('id', _$id);
  static String _$peerFingerprint(ChatMessage v) => v.peerFingerprint;
  static const Field<ChatMessage, String> _f$peerFingerprint = Field(
    'peerFingerprint',
    _$peerFingerprint,
  );
  static bool _$outgoing(ChatMessage v) => v.outgoing;
  static const Field<ChatMessage, bool> _f$outgoing = Field(
    'outgoing',
    _$outgoing,
  );
  static ChatMessageType _$type(ChatMessage v) => v.type;
  static const Field<ChatMessage, ChatMessageType> _f$type = Field(
    'type',
    _$type,
  );
  static String? _$text(ChatMessage v) => v.text;
  static const Field<ChatMessage, String> _f$text = Field('text', _$text);
  static String? _$fileName(ChatMessage v) => v.fileName;
  static const Field<ChatMessage, String> _f$fileName = Field(
    'fileName',
    _$fileName,
  );
  static int? _$fileSize(ChatMessage v) => v.fileSize;
  static const Field<ChatMessage, int> _f$fileSize = Field(
    'fileSize',
    _$fileSize,
  );
  static List<String> _$filePaths(ChatMessage v) => v.filePaths;
  static const Field<ChatMessage, List<String>> _f$filePaths = Field(
    'filePaths',
    _$filePaths,
    opt: true,
    def: const [],
  );
  static int _$fileCount(ChatMessage v) => v.fileCount;
  static const Field<ChatMessage, int> _f$fileCount = Field(
    'fileCount',
    _$fileCount,
    opt: true,
    def: 1,
  );
  static DateTime _$timestamp(ChatMessage v) => v.timestamp;
  static const Field<ChatMessage, DateTime> _f$timestamp = Field(
    'timestamp',
    _$timestamp,
  );
  static ChatMessageStatus _$status(ChatMessage v) => v.status;
  static const Field<ChatMessage, ChatMessageStatus> _f$status = Field(
    'status',
    _$status,
  );

  @override
  final MappableFields<ChatMessage> fields = const {
    #id: _f$id,
    #peerFingerprint: _f$peerFingerprint,
    #outgoing: _f$outgoing,
    #type: _f$type,
    #text: _f$text,
    #fileName: _f$fileName,
    #fileSize: _f$fileSize,
    #filePaths: _f$filePaths,
    #fileCount: _f$fileCount,
    #timestamp: _f$timestamp,
    #status: _f$status,
  };

  static ChatMessage _instantiate(DecodingData data) {
    return ChatMessage(
      id: data.dec(_f$id),
      peerFingerprint: data.dec(_f$peerFingerprint),
      outgoing: data.dec(_f$outgoing),
      type: data.dec(_f$type),
      text: data.dec(_f$text),
      fileName: data.dec(_f$fileName),
      fileSize: data.dec(_f$fileSize),
      filePaths: data.dec(_f$filePaths),
      fileCount: data.dec(_f$fileCount),
      timestamp: data.dec(_f$timestamp),
      status: data.dec(_f$status),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ChatMessage fromJson(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ChatMessage>(map);
  }

  static ChatMessage deserialize(String json) {
    return ensureInitialized().decodeJson<ChatMessage>(json);
  }
}

mixin ChatMessageMappable {
  String serialize() {
    return ChatMessageMapper.ensureInitialized().encodeJson<ChatMessage>(
      this as ChatMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return ChatMessageMapper.ensureInitialized().encodeMap<ChatMessage>(
      this as ChatMessage,
    );
  }

  ChatMessageCopyWith<ChatMessage, ChatMessage, ChatMessage> get copyWith =>
      _ChatMessageCopyWithImpl<ChatMessage, ChatMessage>(
        this as ChatMessage,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ChatMessageMapper.ensureInitialized().stringifyValue(
      this as ChatMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    return ChatMessageMapper.ensureInitialized().equalsValue(
      this as ChatMessage,
      other,
    );
  }

  @override
  int get hashCode {
    return ChatMessageMapper.ensureInitialized().hashValue(this as ChatMessage);
  }
}

extension ChatMessageValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ChatMessage, $Out> {
  ChatMessageCopyWith<$R, ChatMessage, $Out> get $asChatMessage =>
      $base.as((v, t, t2) => _ChatMessageCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ChatMessageCopyWith<$R, $In extends ChatMessage, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get filePaths;
  $R call({
    String? id,
    String? peerFingerprint,
    bool? outgoing,
    ChatMessageType? type,
    String? text,
    String? fileName,
    int? fileSize,
    List<String>? filePaths,
    int? fileCount,
    DateTime? timestamp,
    ChatMessageStatus? status,
  });
  ChatMessageCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ChatMessageCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ChatMessage, $Out>
    implements ChatMessageCopyWith<$R, ChatMessage, $Out> {
  _ChatMessageCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ChatMessage> $mapper =
      ChatMessageMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get filePaths =>
      ListCopyWith(
        $value.filePaths,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(filePaths: v),
      );
  @override
  $R call({
    String? id,
    String? peerFingerprint,
    bool? outgoing,
    ChatMessageType? type,
    Object? text = $none,
    Object? fileName = $none,
    Object? fileSize = $none,
    List<String>? filePaths,
    int? fileCount,
    DateTime? timestamp,
    ChatMessageStatus? status,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (peerFingerprint != null) #peerFingerprint: peerFingerprint,
      if (outgoing != null) #outgoing: outgoing,
      if (type != null) #type: type,
      if (text != $none) #text: text,
      if (fileName != $none) #fileName: fileName,
      if (fileSize != $none) #fileSize: fileSize,
      if (filePaths != null) #filePaths: filePaths,
      if (fileCount != null) #fileCount: fileCount,
      if (timestamp != null) #timestamp: timestamp,
      if (status != null) #status: status,
    }),
  );
  @override
  ChatMessage $make(CopyWithData data) => ChatMessage(
    id: data.get(#id, or: $value.id),
    peerFingerprint: data.get(#peerFingerprint, or: $value.peerFingerprint),
    outgoing: data.get(#outgoing, or: $value.outgoing),
    type: data.get(#type, or: $value.type),
    text: data.get(#text, or: $value.text),
    fileName: data.get(#fileName, or: $value.fileName),
    fileSize: data.get(#fileSize, or: $value.fileSize),
    filePaths: data.get(#filePaths, or: $value.filePaths),
    fileCount: data.get(#fileCount, or: $value.fileCount),
    timestamp: data.get(#timestamp, or: $value.timestamp),
    status: data.get(#status, or: $value.status),
  );

  @override
  ChatMessageCopyWith<$R2, ChatMessage, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ChatMessageCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

