# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: LostSeriesProtocol.proto

from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from google.protobuf import reflection as _reflection
from google.protobuf import descriptor_pb2
# @@protoc_insertion_point(imports)




DESCRIPTOR = _descriptor.FileDescriptor(
  name='LostSeriesProtocol.proto',
  package='LS',
  serialized_pb='\n\x18LostSeriesProtocol.proto\x12\x02LS\"\x1b\n\x06Header\x12\x11\n\tmessageID\x18\x01 \x02(\x03\"\xb5\x03\n\x07Message\x12)\n\rseriesRequest\x18\xe8\x07 \x01(\x0b\x32\x11.LS.SeriesRequest\x12+\n\x0e\x61rtworkRequest\x18\xe9\x07 \x01(\x0b\x32\x12.LS.ArtworkRequest\x12;\n\x16setSubscriptionRequest\x18\xea\x07 \x01(\x0b\x32\x1a.LS.SetSubscriptionRequest\x12;\n\x16getSubscriptionRequest\x18\xeb\x07 \x01(\x0b\x32\x1a.LS.GetSubscriptionRequest\x12+\n\x0eseriesResponse\x18\xd0\x0f \x01(\x0b\x32\x12.LS.SeriesResponse\x12-\n\x0f\x61rtworkResponse\x18\xd1\x0f \x01(\x0b\x32\x13.LS.ArtworkResponse\x12=\n\x17setSubscriptionResponse\x18\xd2\x0f \x01(\x0b\x32\x1b.LS.SetSubscriptionResponse\x12=\n\x17getSubscriptionResponse\x18\xd3\x0f \x01(\x0b\x32\x1b.LS.GetSubscriptionResponse\"+\n\x12SubscriptionRecord\x12\x15\n\roriginalTitle\x18\x01 \x02(\t\"\x0f\n\rSeriesRequest\"\x92\x01\n\x0eSeriesResponse\x12(\n\x05shows\x18\x01 \x03(\x0b\x32\x19.LS.SeriesResponse.TVShow\x1aV\n\x06TVShow\x12\r\n\x05title\x18\x01 \x02(\t\x12\x15\n\roriginalTitle\x18\x02 \x02(\t\x12\x14\n\x0cseasonNumber\x18\x03 \x02(\x05\x12\x10\n\x08snapshot\x18\x04 \x02(\t\"9\n\x0e\x41rtworkRequest\x12\x10\n\x08snapshot\x18\x01 \x02(\t\x12\x15\n\roriginalTitle\x18\x02 \x02(\t\":\n\x0f\x41rtworkResponse\x12\x10\n\x08snapshot\x18\x01 \x02(\t\x12\x15\n\roriginalTitle\x18\x02 \x02(\t\"V\n\x16SetSubscriptionRequest\x12\r\n\x05token\x18\x01 \x02(\t\x12-\n\rsubscriptions\x18\x02 \x03(\x0b\x32\x16.LS.SubscriptionRecord\")\n\x17SetSubscriptionResponse\x12\x0e\n\x06result\x18\x01 \x02(\x08\"\'\n\x16GetSubscriptionRequest\x12\r\n\x05token\x18\x01 \x02(\t\"W\n\x17GetSubscriptionResponse\x12\r\n\x05token\x18\x01 \x02(\t\x12-\n\rsubscriptions\x18\x02 \x03(\x0b\x32\x16.LS.SubscriptionRecord')




_HEADER = _descriptor.Descriptor(
  name='Header',
  full_name='LS.Header',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='messageID', full_name='LS.Header.messageID', index=0,
      number=1, type=3, cpp_type=2, label=2,
      has_default_value=False, default_value=0,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  options=None,
  is_extendable=False,
  extension_ranges=[],
  serialized_start=32,
  serialized_end=59,
)


_MESSAGE = _descriptor.Descriptor(
  name='Message',
  full_name='LS.Message',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='seriesRequest', full_name='LS.Message.seriesRequest', index=0,
      number=1000, type=11, cpp_type=10, label=1,
      has_default_value=False, default_value=None,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='artworkRequest', full_name='LS.Message.artworkRequest', index=1,
      number=1001, type=11, cpp_type=10, label=1,
      has_default_value=False, default_value=None,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='setSubscriptionRequest', full_name='LS.Message.setSubscriptionRequest', index=2,
      number=1002, type=11, cpp_type=10, label=1,
      has_default_value=False, default_value=None,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='getSubscriptionRequest', full_name='LS.Message.getSubscriptionRequest', index=3,
      number=1003, type=11, cpp_type=10, label=1,
      has_default_value=False, default_value=None,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='seriesResponse', full_name='LS.Message.seriesResponse', index=4,
      number=2000, type=11, cpp_type=10, label=1,
      has_default_value=False, default_value=None,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='artworkResponse', full_name='LS.Message.artworkResponse', index=5,
      number=2001, type=11, cpp_type=10, label=1,
      has_default_value=False, default_value=None,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='setSubscriptionResponse', full_name='LS.Message.setSubscriptionResponse', index=6,
      number=2002, type=11, cpp_type=10, label=1,
      has_default_value=False, default_value=None,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='getSubscriptionResponse', full_name='LS.Message.getSubscriptionResponse', index=7,
      number=2003, type=11, cpp_type=10, label=1,
      has_default_value=False, default_value=None,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  options=None,
  is_extendable=False,
  extension_ranges=[],
  serialized_start=62,
  serialized_end=499,
)


_SUBSCRIPTIONRECORD = _descriptor.Descriptor(
  name='SubscriptionRecord',
  full_name='LS.SubscriptionRecord',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='originalTitle', full_name='LS.SubscriptionRecord.originalTitle', index=0,
      number=1, type=9, cpp_type=9, label=2,
      has_default_value=False, default_value=unicode("", "utf-8"),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  options=None,
  is_extendable=False,
  extension_ranges=[],
  serialized_start=501,
  serialized_end=544,
)


_SERIESREQUEST = _descriptor.Descriptor(
  name='SeriesRequest',
  full_name='LS.SeriesRequest',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  options=None,
  is_extendable=False,
  extension_ranges=[],
  serialized_start=546,
  serialized_end=561,
)


_SERIESRESPONSE_TVSHOW = _descriptor.Descriptor(
  name='TVShow',
  full_name='LS.SeriesResponse.TVShow',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='title', full_name='LS.SeriesResponse.TVShow.title', index=0,
      number=1, type=9, cpp_type=9, label=2,
      has_default_value=False, default_value=unicode("", "utf-8"),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='originalTitle', full_name='LS.SeriesResponse.TVShow.originalTitle', index=1,
      number=2, type=9, cpp_type=9, label=2,
      has_default_value=False, default_value=unicode("", "utf-8"),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='seasonNumber', full_name='LS.SeriesResponse.TVShow.seasonNumber', index=2,
      number=3, type=5, cpp_type=1, label=2,
      has_default_value=False, default_value=0,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='snapshot', full_name='LS.SeriesResponse.TVShow.snapshot', index=3,
      number=4, type=9, cpp_type=9, label=2,
      has_default_value=False, default_value=unicode("", "utf-8"),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  options=None,
  is_extendable=False,
  extension_ranges=[],
  serialized_start=624,
  serialized_end=710,
)

_SERIESRESPONSE = _descriptor.Descriptor(
  name='SeriesResponse',
  full_name='LS.SeriesResponse',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='shows', full_name='LS.SeriesResponse.shows', index=0,
      number=1, type=11, cpp_type=10, label=3,
      has_default_value=False, default_value=[],
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
  ],
  extensions=[
  ],
  nested_types=[_SERIESRESPONSE_TVSHOW, ],
  enum_types=[
  ],
  options=None,
  is_extendable=False,
  extension_ranges=[],
  serialized_start=564,
  serialized_end=710,
)


_ARTWORKREQUEST = _descriptor.Descriptor(
  name='ArtworkRequest',
  full_name='LS.ArtworkRequest',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='snapshot', full_name='LS.ArtworkRequest.snapshot', index=0,
      number=1, type=9, cpp_type=9, label=2,
      has_default_value=False, default_value=unicode("", "utf-8"),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='originalTitle', full_name='LS.ArtworkRequest.originalTitle', index=1,
      number=2, type=9, cpp_type=9, label=2,
      has_default_value=False, default_value=unicode("", "utf-8"),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  options=None,
  is_extendable=False,
  extension_ranges=[],
  serialized_start=712,
  serialized_end=769,
)


_ARTWORKRESPONSE = _descriptor.Descriptor(
  name='ArtworkResponse',
  full_name='LS.ArtworkResponse',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='snapshot', full_name='LS.ArtworkResponse.snapshot', index=0,
      number=1, type=9, cpp_type=9, label=2,
      has_default_value=False, default_value=unicode("", "utf-8"),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='originalTitle', full_name='LS.ArtworkResponse.originalTitle', index=1,
      number=2, type=9, cpp_type=9, label=2,
      has_default_value=False, default_value=unicode("", "utf-8"),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  options=None,
  is_extendable=False,
  extension_ranges=[],
  serialized_start=771,
  serialized_end=829,
)


_SETSUBSCRIPTIONREQUEST = _descriptor.Descriptor(
  name='SetSubscriptionRequest',
  full_name='LS.SetSubscriptionRequest',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='token', full_name='LS.SetSubscriptionRequest.token', index=0,
      number=1, type=9, cpp_type=9, label=2,
      has_default_value=False, default_value=unicode("", "utf-8"),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='subscriptions', full_name='LS.SetSubscriptionRequest.subscriptions', index=1,
      number=2, type=11, cpp_type=10, label=3,
      has_default_value=False, default_value=[],
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  options=None,
  is_extendable=False,
  extension_ranges=[],
  serialized_start=831,
  serialized_end=917,
)


_SETSUBSCRIPTIONRESPONSE = _descriptor.Descriptor(
  name='SetSubscriptionResponse',
  full_name='LS.SetSubscriptionResponse',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='result', full_name='LS.SetSubscriptionResponse.result', index=0,
      number=1, type=8, cpp_type=7, label=2,
      has_default_value=False, default_value=False,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  options=None,
  is_extendable=False,
  extension_ranges=[],
  serialized_start=919,
  serialized_end=960,
)


_GETSUBSCRIPTIONREQUEST = _descriptor.Descriptor(
  name='GetSubscriptionRequest',
  full_name='LS.GetSubscriptionRequest',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='token', full_name='LS.GetSubscriptionRequest.token', index=0,
      number=1, type=9, cpp_type=9, label=2,
      has_default_value=False, default_value=unicode("", "utf-8"),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  options=None,
  is_extendable=False,
  extension_ranges=[],
  serialized_start=962,
  serialized_end=1001,
)


_GETSUBSCRIPTIONRESPONSE = _descriptor.Descriptor(
  name='GetSubscriptionResponse',
  full_name='LS.GetSubscriptionResponse',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='token', full_name='LS.GetSubscriptionResponse.token', index=0,
      number=1, type=9, cpp_type=9, label=2,
      has_default_value=False, default_value=unicode("", "utf-8"),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='subscriptions', full_name='LS.GetSubscriptionResponse.subscriptions', index=1,
      number=2, type=11, cpp_type=10, label=3,
      has_default_value=False, default_value=[],
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  options=None,
  is_extendable=False,
  extension_ranges=[],
  serialized_start=1003,
  serialized_end=1090,
)

_MESSAGE.fields_by_name['seriesRequest'].message_type = _SERIESREQUEST
_MESSAGE.fields_by_name['artworkRequest'].message_type = _ARTWORKREQUEST
_MESSAGE.fields_by_name['setSubscriptionRequest'].message_type = _SETSUBSCRIPTIONREQUEST
_MESSAGE.fields_by_name['getSubscriptionRequest'].message_type = _GETSUBSCRIPTIONREQUEST
_MESSAGE.fields_by_name['seriesResponse'].message_type = _SERIESRESPONSE
_MESSAGE.fields_by_name['artworkResponse'].message_type = _ARTWORKRESPONSE
_MESSAGE.fields_by_name['setSubscriptionResponse'].message_type = _SETSUBSCRIPTIONRESPONSE
_MESSAGE.fields_by_name['getSubscriptionResponse'].message_type = _GETSUBSCRIPTIONRESPONSE
_SERIESRESPONSE_TVSHOW.containing_type = _SERIESRESPONSE;
_SERIESRESPONSE.fields_by_name['shows'].message_type = _SERIESRESPONSE_TVSHOW
_SETSUBSCRIPTIONREQUEST.fields_by_name['subscriptions'].message_type = _SUBSCRIPTIONRECORD
_GETSUBSCRIPTIONRESPONSE.fields_by_name['subscriptions'].message_type = _SUBSCRIPTIONRECORD
DESCRIPTOR.message_types_by_name['Header'] = _HEADER
DESCRIPTOR.message_types_by_name['Message'] = _MESSAGE
DESCRIPTOR.message_types_by_name['SubscriptionRecord'] = _SUBSCRIPTIONRECORD
DESCRIPTOR.message_types_by_name['SeriesRequest'] = _SERIESREQUEST
DESCRIPTOR.message_types_by_name['SeriesResponse'] = _SERIESRESPONSE
DESCRIPTOR.message_types_by_name['ArtworkRequest'] = _ARTWORKREQUEST
DESCRIPTOR.message_types_by_name['ArtworkResponse'] = _ARTWORKRESPONSE
DESCRIPTOR.message_types_by_name['SetSubscriptionRequest'] = _SETSUBSCRIPTIONREQUEST
DESCRIPTOR.message_types_by_name['SetSubscriptionResponse'] = _SETSUBSCRIPTIONRESPONSE
DESCRIPTOR.message_types_by_name['GetSubscriptionRequest'] = _GETSUBSCRIPTIONREQUEST
DESCRIPTOR.message_types_by_name['GetSubscriptionResponse'] = _GETSUBSCRIPTIONRESPONSE

class Header(_message.Message):
  __metaclass__ = _reflection.GeneratedProtocolMessageType
  DESCRIPTOR = _HEADER

  # @@protoc_insertion_point(class_scope:LS.Header)

class Message(_message.Message):
  __metaclass__ = _reflection.GeneratedProtocolMessageType
  DESCRIPTOR = _MESSAGE

  # @@protoc_insertion_point(class_scope:LS.Message)

class SubscriptionRecord(_message.Message):
  __metaclass__ = _reflection.GeneratedProtocolMessageType
  DESCRIPTOR = _SUBSCRIPTIONRECORD

  # @@protoc_insertion_point(class_scope:LS.SubscriptionRecord)

class SeriesRequest(_message.Message):
  __metaclass__ = _reflection.GeneratedProtocolMessageType
  DESCRIPTOR = _SERIESREQUEST

  # @@protoc_insertion_point(class_scope:LS.SeriesRequest)

class SeriesResponse(_message.Message):
  __metaclass__ = _reflection.GeneratedProtocolMessageType

  class TVShow(_message.Message):
    __metaclass__ = _reflection.GeneratedProtocolMessageType
    DESCRIPTOR = _SERIESRESPONSE_TVSHOW

    # @@protoc_insertion_point(class_scope:LS.SeriesResponse.TVShow)
  DESCRIPTOR = _SERIESRESPONSE

  # @@protoc_insertion_point(class_scope:LS.SeriesResponse)

class ArtworkRequest(_message.Message):
  __metaclass__ = _reflection.GeneratedProtocolMessageType
  DESCRIPTOR = _ARTWORKREQUEST

  # @@protoc_insertion_point(class_scope:LS.ArtworkRequest)

class ArtworkResponse(_message.Message):
  __metaclass__ = _reflection.GeneratedProtocolMessageType
  DESCRIPTOR = _ARTWORKRESPONSE

  # @@protoc_insertion_point(class_scope:LS.ArtworkResponse)

class SetSubscriptionRequest(_message.Message):
  __metaclass__ = _reflection.GeneratedProtocolMessageType
  DESCRIPTOR = _SETSUBSCRIPTIONREQUEST

  # @@protoc_insertion_point(class_scope:LS.SetSubscriptionRequest)

class SetSubscriptionResponse(_message.Message):
  __metaclass__ = _reflection.GeneratedProtocolMessageType
  DESCRIPTOR = _SETSUBSCRIPTIONRESPONSE

  # @@protoc_insertion_point(class_scope:LS.SetSubscriptionResponse)

class GetSubscriptionRequest(_message.Message):
  __metaclass__ = _reflection.GeneratedProtocolMessageType
  DESCRIPTOR = _GETSUBSCRIPTIONREQUEST

  # @@protoc_insertion_point(class_scope:LS.GetSubscriptionRequest)

class GetSubscriptionResponse(_message.Message):
  __metaclass__ = _reflection.GeneratedProtocolMessageType
  DESCRIPTOR = _GETSUBSCRIPTIONRESPONSE

  # @@protoc_insertion_point(class_scope:LS.GetSubscriptionResponse)


# @@protoc_insertion_point(module_scope)
