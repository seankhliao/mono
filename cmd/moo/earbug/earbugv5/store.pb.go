// Code generated by protoc-gen-go. DO NOT EDIT.
// versions:
// 	protoc-gen-go v1.35.1
// 	protoc        (unknown)
// source: cmd/moo/earbug/earbugv5/store.proto

package earbugv5

import (
	protoreflect "google.golang.org/protobuf/reflect/protoreflect"
	protoimpl "google.golang.org/protobuf/runtime/protoimpl"
	durationpb "google.golang.org/protobuf/types/known/durationpb"
	reflect "reflect"
	sync "sync"
)

const (
	// Verify that this generated code is sufficiently up-to-date.
	_ = protoimpl.EnforceVersion(20 - protoimpl.MinVersion)
	// Verify that runtime/protoimpl is sufficiently up-to-date.
	_ = protoimpl.EnforceVersion(protoimpl.MaxVersion - 20)
)

type Store struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	// track id : track
	Tracks map[string]*Track   `protobuf:"bytes,4,rep,name=tracks" json:"tracks,omitempty" protobuf_key:"bytes,1,opt,name=key" protobuf_val:"bytes,2,opt,name=value"`
	Users  map[int64]*UserData `protobuf:"bytes,8,rep,name=users" json:"users,omitempty" protobuf_key:"varint,1,opt,name=key" protobuf_val:"bytes,2,opt,name=value"`
}

func (x *Store) Reset() {
	*x = Store{}
	mi := &file_cmd_moo_earbug_earbugv5_store_proto_msgTypes[0]
	ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
	ms.StoreMessageInfo(mi)
}

func (x *Store) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*Store) ProtoMessage() {}

func (x *Store) ProtoReflect() protoreflect.Message {
	mi := &file_cmd_moo_earbug_earbugv5_store_proto_msgTypes[0]
	if x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use Store.ProtoReflect.Descriptor instead.
func (*Store) Descriptor() ([]byte, []int) {
	return file_cmd_moo_earbug_earbugv5_store_proto_rawDescGZIP(), []int{0}
}

func (x *Store) GetTracks() map[string]*Track {
	if x != nil {
		return x.Tracks
	}
	return nil
}

func (x *Store) GetUsers() map[int64]*UserData {
	if x != nil {
		return x.Users
	}
	return nil
}

type UserData struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	Token []byte `protobuf:"bytes,1,opt,name=token" json:"token,omitempty"`
	// rfc3339 timestamp : playback
	Playbacks map[string]*Playback `protobuf:"bytes,2,rep,name=playbacks" json:"playbacks,omitempty" protobuf_key:"bytes,1,opt,name=key" protobuf_val:"bytes,2,opt,name=value"`
}

func (x *UserData) Reset() {
	*x = UserData{}
	mi := &file_cmd_moo_earbug_earbugv5_store_proto_msgTypes[1]
	ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
	ms.StoreMessageInfo(mi)
}

func (x *UserData) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*UserData) ProtoMessage() {}

func (x *UserData) ProtoReflect() protoreflect.Message {
	mi := &file_cmd_moo_earbug_earbugv5_store_proto_msgTypes[1]
	if x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use UserData.ProtoReflect.Descriptor instead.
func (*UserData) Descriptor() ([]byte, []int) {
	return file_cmd_moo_earbug_earbugv5_store_proto_rawDescGZIP(), []int{1}
}

func (x *UserData) GetToken() []byte {
	if x != nil {
		return x.Token
	}
	return nil
}

func (x *UserData) GetPlaybacks() map[string]*Playback {
	if x != nil {
		return x.Playbacks
	}
	return nil
}

type Playback struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	TrackId     *string `protobuf:"bytes,1,opt,name=track_id,json=trackId" json:"track_id,omitempty"`
	TrackUri    *string `protobuf:"bytes,2,opt,name=track_uri,json=trackUri" json:"track_uri,omitempty"`
	ContextType *string `protobuf:"bytes,3,opt,name=context_type,json=contextType" json:"context_type,omitempty"`
	ContextUri  *string `protobuf:"bytes,4,opt,name=context_uri,json=contextUri" json:"context_uri,omitempty"`
}

func (x *Playback) Reset() {
	*x = Playback{}
	mi := &file_cmd_moo_earbug_earbugv5_store_proto_msgTypes[2]
	ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
	ms.StoreMessageInfo(mi)
}

func (x *Playback) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*Playback) ProtoMessage() {}

func (x *Playback) ProtoReflect() protoreflect.Message {
	mi := &file_cmd_moo_earbug_earbugv5_store_proto_msgTypes[2]
	if x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use Playback.ProtoReflect.Descriptor instead.
func (*Playback) Descriptor() ([]byte, []int) {
	return file_cmd_moo_earbug_earbugv5_store_proto_rawDescGZIP(), []int{2}
}

func (x *Playback) GetTrackId() string {
	if x != nil && x.TrackId != nil {
		return *x.TrackId
	}
	return ""
}

func (x *Playback) GetTrackUri() string {
	if x != nil && x.TrackUri != nil {
		return *x.TrackUri
	}
	return ""
}

func (x *Playback) GetContextType() string {
	if x != nil && x.ContextType != nil {
		return *x.ContextType
	}
	return ""
}

func (x *Playback) GetContextUri() string {
	if x != nil && x.ContextUri != nil {
		return *x.ContextUri
	}
	return ""
}

type Track struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	Id       *string              `protobuf:"bytes,1,opt,name=id" json:"id,omitempty"`
	Uri      *string              `protobuf:"bytes,2,opt,name=uri" json:"uri,omitempty"`
	Type     *string              `protobuf:"bytes,3,opt,name=type" json:"type,omitempty"`
	Name     *string              `protobuf:"bytes,4,opt,name=name" json:"name,omitempty"`
	Duration *durationpb.Duration `protobuf:"bytes,5,opt,name=duration" json:"duration,omitempty"`
	Artists  []*Artist            `protobuf:"bytes,6,rep,name=artists" json:"artists,omitempty"`
}

func (x *Track) Reset() {
	*x = Track{}
	mi := &file_cmd_moo_earbug_earbugv5_store_proto_msgTypes[3]
	ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
	ms.StoreMessageInfo(mi)
}

func (x *Track) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*Track) ProtoMessage() {}

func (x *Track) ProtoReflect() protoreflect.Message {
	mi := &file_cmd_moo_earbug_earbugv5_store_proto_msgTypes[3]
	if x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use Track.ProtoReflect.Descriptor instead.
func (*Track) Descriptor() ([]byte, []int) {
	return file_cmd_moo_earbug_earbugv5_store_proto_rawDescGZIP(), []int{3}
}

func (x *Track) GetId() string {
	if x != nil && x.Id != nil {
		return *x.Id
	}
	return ""
}

func (x *Track) GetUri() string {
	if x != nil && x.Uri != nil {
		return *x.Uri
	}
	return ""
}

func (x *Track) GetType() string {
	if x != nil && x.Type != nil {
		return *x.Type
	}
	return ""
}

func (x *Track) GetName() string {
	if x != nil && x.Name != nil {
		return *x.Name
	}
	return ""
}

func (x *Track) GetDuration() *durationpb.Duration {
	if x != nil {
		return x.Duration
	}
	return nil
}

func (x *Track) GetArtists() []*Artist {
	if x != nil {
		return x.Artists
	}
	return nil
}

type Artist struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	Id   *string `protobuf:"bytes,1,opt,name=id" json:"id,omitempty"`
	Uri  *string `protobuf:"bytes,2,opt,name=uri" json:"uri,omitempty"`
	Name *string `protobuf:"bytes,3,opt,name=name" json:"name,omitempty"`
}

func (x *Artist) Reset() {
	*x = Artist{}
	mi := &file_cmd_moo_earbug_earbugv5_store_proto_msgTypes[4]
	ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
	ms.StoreMessageInfo(mi)
}

func (x *Artist) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*Artist) ProtoMessage() {}

func (x *Artist) ProtoReflect() protoreflect.Message {
	mi := &file_cmd_moo_earbug_earbugv5_store_proto_msgTypes[4]
	if x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use Artist.ProtoReflect.Descriptor instead.
func (*Artist) Descriptor() ([]byte, []int) {
	return file_cmd_moo_earbug_earbugv5_store_proto_rawDescGZIP(), []int{4}
}

func (x *Artist) GetId() string {
	if x != nil && x.Id != nil {
		return *x.Id
	}
	return ""
}

func (x *Artist) GetUri() string {
	if x != nil && x.Uri != nil {
		return *x.Uri
	}
	return ""
}

func (x *Artist) GetName() string {
	if x != nil && x.Name != nil {
		return *x.Name
	}
	return ""
}

var File_cmd_moo_earbug_earbugv5_store_proto protoreflect.FileDescriptor

var file_cmd_moo_earbug_earbugv5_store_proto_rawDesc = []byte{
	0x0a, 0x23, 0x63, 0x6d, 0x64, 0x2f, 0x6d, 0x6f, 0x6f, 0x2f, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67,
	0x2f, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x76, 0x35, 0x2f, 0x73, 0x74, 0x6f, 0x72, 0x65, 0x2e,
	0x70, 0x72, 0x6f, 0x74, 0x6f, 0x12, 0x18, 0x73, 0x65, 0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69, 0x61,
	0x6f, 0x2e, 0x6d, 0x6f, 0x6e, 0x6f, 0x2e, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x76, 0x35, 0x1a,
	0x1e, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2f, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x62, 0x75, 0x66,
	0x2f, 0x64, 0x75, 0x72, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x2e, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x22,
	0xec, 0x02, 0x0a, 0x05, 0x53, 0x74, 0x6f, 0x72, 0x65, 0x12, 0x43, 0x0a, 0x06, 0x74, 0x72, 0x61,
	0x63, 0x6b, 0x73, 0x18, 0x04, 0x20, 0x03, 0x28, 0x0b, 0x32, 0x2b, 0x2e, 0x73, 0x65, 0x61, 0x6e,
	0x6b, 0x68, 0x6c, 0x69, 0x61, 0x6f, 0x2e, 0x6d, 0x6f, 0x6e, 0x6f, 0x2e, 0x65, 0x61, 0x72, 0x62,
	0x75, 0x67, 0x76, 0x35, 0x2e, 0x53, 0x74, 0x6f, 0x72, 0x65, 0x2e, 0x54, 0x72, 0x61, 0x63, 0x6b,
	0x73, 0x45, 0x6e, 0x74, 0x72, 0x79, 0x52, 0x06, 0x74, 0x72, 0x61, 0x63, 0x6b, 0x73, 0x12, 0x40,
	0x0a, 0x05, 0x75, 0x73, 0x65, 0x72, 0x73, 0x18, 0x08, 0x20, 0x03, 0x28, 0x0b, 0x32, 0x2a, 0x2e,
	0x73, 0x65, 0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69, 0x61, 0x6f, 0x2e, 0x6d, 0x6f, 0x6e, 0x6f, 0x2e,
	0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x76, 0x35, 0x2e, 0x53, 0x74, 0x6f, 0x72, 0x65, 0x2e, 0x55,
	0x73, 0x65, 0x72, 0x73, 0x45, 0x6e, 0x74, 0x72, 0x79, 0x52, 0x05, 0x75, 0x73, 0x65, 0x72, 0x73,
	0x1a, 0x5a, 0x0a, 0x0b, 0x54, 0x72, 0x61, 0x63, 0x6b, 0x73, 0x45, 0x6e, 0x74, 0x72, 0x79, 0x12,
	0x10, 0x0a, 0x03, 0x6b, 0x65, 0x79, 0x18, 0x01, 0x20, 0x01, 0x28, 0x09, 0x52, 0x03, 0x6b, 0x65,
	0x79, 0x12, 0x35, 0x0a, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x18, 0x02, 0x20, 0x01, 0x28, 0x0b,
	0x32, 0x1f, 0x2e, 0x73, 0x65, 0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69, 0x61, 0x6f, 0x2e, 0x6d, 0x6f,
	0x6e, 0x6f, 0x2e, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x76, 0x35, 0x2e, 0x54, 0x72, 0x61, 0x63,
	0x6b, 0x52, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x3a, 0x02, 0x38, 0x01, 0x1a, 0x5c, 0x0a, 0x0a,
	0x55, 0x73, 0x65, 0x72, 0x73, 0x45, 0x6e, 0x74, 0x72, 0x79, 0x12, 0x10, 0x0a, 0x03, 0x6b, 0x65,
	0x79, 0x18, 0x01, 0x20, 0x01, 0x28, 0x03, 0x52, 0x03, 0x6b, 0x65, 0x79, 0x12, 0x38, 0x0a, 0x05,
	0x76, 0x61, 0x6c, 0x75, 0x65, 0x18, 0x02, 0x20, 0x01, 0x28, 0x0b, 0x32, 0x22, 0x2e, 0x73, 0x65,
	0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69, 0x61, 0x6f, 0x2e, 0x6d, 0x6f, 0x6e, 0x6f, 0x2e, 0x65, 0x61,
	0x72, 0x62, 0x75, 0x67, 0x76, 0x35, 0x2e, 0x55, 0x73, 0x65, 0x72, 0x44, 0x61, 0x74, 0x61, 0x52,
	0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x3a, 0x02, 0x38, 0x01, 0x4a, 0x04, 0x08, 0x01, 0x10, 0x02,
	0x4a, 0x04, 0x08, 0x02, 0x10, 0x03, 0x4a, 0x04, 0x08, 0x03, 0x10, 0x04, 0x4a, 0x04, 0x08, 0x05,
	0x10, 0x06, 0x4a, 0x04, 0x08, 0x06, 0x10, 0x07, 0x4a, 0x04, 0x08, 0x07, 0x10, 0x08, 0x22, 0xd3,
	0x01, 0x0a, 0x08, 0x55, 0x73, 0x65, 0x72, 0x44, 0x61, 0x74, 0x61, 0x12, 0x14, 0x0a, 0x05, 0x74,
	0x6f, 0x6b, 0x65, 0x6e, 0x18, 0x01, 0x20, 0x01, 0x28, 0x0c, 0x52, 0x05, 0x74, 0x6f, 0x6b, 0x65,
	0x6e, 0x12, 0x4f, 0x0a, 0x09, 0x70, 0x6c, 0x61, 0x79, 0x62, 0x61, 0x63, 0x6b, 0x73, 0x18, 0x02,
	0x20, 0x03, 0x28, 0x0b, 0x32, 0x31, 0x2e, 0x73, 0x65, 0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69, 0x61,
	0x6f, 0x2e, 0x6d, 0x6f, 0x6e, 0x6f, 0x2e, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x76, 0x35, 0x2e,
	0x55, 0x73, 0x65, 0x72, 0x44, 0x61, 0x74, 0x61, 0x2e, 0x50, 0x6c, 0x61, 0x79, 0x62, 0x61, 0x63,
	0x6b, 0x73, 0x45, 0x6e, 0x74, 0x72, 0x79, 0x52, 0x09, 0x70, 0x6c, 0x61, 0x79, 0x62, 0x61, 0x63,
	0x6b, 0x73, 0x1a, 0x60, 0x0a, 0x0e, 0x50, 0x6c, 0x61, 0x79, 0x62, 0x61, 0x63, 0x6b, 0x73, 0x45,
	0x6e, 0x74, 0x72, 0x79, 0x12, 0x10, 0x0a, 0x03, 0x6b, 0x65, 0x79, 0x18, 0x01, 0x20, 0x01, 0x28,
	0x09, 0x52, 0x03, 0x6b, 0x65, 0x79, 0x12, 0x38, 0x0a, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x18,
	0x02, 0x20, 0x01, 0x28, 0x0b, 0x32, 0x22, 0x2e, 0x73, 0x65, 0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69,
	0x61, 0x6f, 0x2e, 0x6d, 0x6f, 0x6e, 0x6f, 0x2e, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x76, 0x35,
	0x2e, 0x50, 0x6c, 0x61, 0x79, 0x62, 0x61, 0x63, 0x6b, 0x52, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65,
	0x3a, 0x02, 0x38, 0x01, 0x22, 0x86, 0x01, 0x0a, 0x08, 0x50, 0x6c, 0x61, 0x79, 0x62, 0x61, 0x63,
	0x6b, 0x12, 0x19, 0x0a, 0x08, 0x74, 0x72, 0x61, 0x63, 0x6b, 0x5f, 0x69, 0x64, 0x18, 0x01, 0x20,
	0x01, 0x28, 0x09, 0x52, 0x07, 0x74, 0x72, 0x61, 0x63, 0x6b, 0x49, 0x64, 0x12, 0x1b, 0x0a, 0x09,
	0x74, 0x72, 0x61, 0x63, 0x6b, 0x5f, 0x75, 0x72, 0x69, 0x18, 0x02, 0x20, 0x01, 0x28, 0x09, 0x52,
	0x08, 0x74, 0x72, 0x61, 0x63, 0x6b, 0x55, 0x72, 0x69, 0x12, 0x21, 0x0a, 0x0c, 0x63, 0x6f, 0x6e,
	0x74, 0x65, 0x78, 0x74, 0x5f, 0x74, 0x79, 0x70, 0x65, 0x18, 0x03, 0x20, 0x01, 0x28, 0x09, 0x52,
	0x0b, 0x63, 0x6f, 0x6e, 0x74, 0x65, 0x78, 0x74, 0x54, 0x79, 0x70, 0x65, 0x12, 0x1f, 0x0a, 0x0b,
	0x63, 0x6f, 0x6e, 0x74, 0x65, 0x78, 0x74, 0x5f, 0x75, 0x72, 0x69, 0x18, 0x04, 0x20, 0x01, 0x28,
	0x09, 0x52, 0x0a, 0x63, 0x6f, 0x6e, 0x74, 0x65, 0x78, 0x74, 0x55, 0x72, 0x69, 0x22, 0xc4, 0x01,
	0x0a, 0x05, 0x54, 0x72, 0x61, 0x63, 0x6b, 0x12, 0x0e, 0x0a, 0x02, 0x69, 0x64, 0x18, 0x01, 0x20,
	0x01, 0x28, 0x09, 0x52, 0x02, 0x69, 0x64, 0x12, 0x10, 0x0a, 0x03, 0x75, 0x72, 0x69, 0x18, 0x02,
	0x20, 0x01, 0x28, 0x09, 0x52, 0x03, 0x75, 0x72, 0x69, 0x12, 0x12, 0x0a, 0x04, 0x74, 0x79, 0x70,
	0x65, 0x18, 0x03, 0x20, 0x01, 0x28, 0x09, 0x52, 0x04, 0x74, 0x79, 0x70, 0x65, 0x12, 0x12, 0x0a,
	0x04, 0x6e, 0x61, 0x6d, 0x65, 0x18, 0x04, 0x20, 0x01, 0x28, 0x09, 0x52, 0x04, 0x6e, 0x61, 0x6d,
	0x65, 0x12, 0x35, 0x0a, 0x08, 0x64, 0x75, 0x72, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x18, 0x05, 0x20,
	0x01, 0x28, 0x0b, 0x32, 0x19, 0x2e, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2e, 0x70, 0x72, 0x6f,
	0x74, 0x6f, 0x62, 0x75, 0x66, 0x2e, 0x44, 0x75, 0x72, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x52, 0x08,
	0x64, 0x75, 0x72, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x12, 0x3a, 0x0a, 0x07, 0x61, 0x72, 0x74, 0x69,
	0x73, 0x74, 0x73, 0x18, 0x06, 0x20, 0x03, 0x28, 0x0b, 0x32, 0x20, 0x2e, 0x73, 0x65, 0x61, 0x6e,
	0x6b, 0x68, 0x6c, 0x69, 0x61, 0x6f, 0x2e, 0x6d, 0x6f, 0x6e, 0x6f, 0x2e, 0x65, 0x61, 0x72, 0x62,
	0x75, 0x67, 0x76, 0x35, 0x2e, 0x41, 0x72, 0x74, 0x69, 0x73, 0x74, 0x52, 0x07, 0x61, 0x72, 0x74,
	0x69, 0x73, 0x74, 0x73, 0x22, 0x3e, 0x0a, 0x06, 0x41, 0x72, 0x74, 0x69, 0x73, 0x74, 0x12, 0x0e,
	0x0a, 0x02, 0x69, 0x64, 0x18, 0x01, 0x20, 0x01, 0x28, 0x09, 0x52, 0x02, 0x69, 0x64, 0x12, 0x10,
	0x0a, 0x03, 0x75, 0x72, 0x69, 0x18, 0x02, 0x20, 0x01, 0x28, 0x09, 0x52, 0x03, 0x75, 0x72, 0x69,
	0x12, 0x12, 0x0a, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x18, 0x03, 0x20, 0x01, 0x28, 0x09, 0x52, 0x04,
	0x6e, 0x61, 0x6d, 0x65, 0x42, 0xdc, 0x01, 0x0a, 0x1c, 0x63, 0x6f, 0x6d, 0x2e, 0x73, 0x65, 0x61,
	0x6e, 0x6b, 0x68, 0x6c, 0x69, 0x61, 0x6f, 0x2e, 0x6d, 0x6f, 0x6e, 0x6f, 0x2e, 0x65, 0x61, 0x72,
	0x62, 0x75, 0x67, 0x76, 0x35, 0x42, 0x0a, 0x53, 0x74, 0x6f, 0x72, 0x65, 0x50, 0x72, 0x6f, 0x74,
	0x6f, 0x50, 0x01, 0x5a, 0x2e, 0x67, 0x6f, 0x2e, 0x73, 0x65, 0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69,
	0x61, 0x6f, 0x2e, 0x63, 0x6f, 0x6d, 0x2f, 0x6d, 0x6f, 0x6e, 0x6f, 0x2f, 0x63, 0x6d, 0x64, 0x2f,
	0x6d, 0x6f, 0x6f, 0x2f, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x2f, 0x65, 0x61, 0x72, 0x62, 0x75,
	0x67, 0x76, 0x35, 0xa2, 0x02, 0x03, 0x53, 0x4d, 0x45, 0xaa, 0x02, 0x18, 0x53, 0x65, 0x61, 0x6e,
	0x6b, 0x68, 0x6c, 0x69, 0x61, 0x6f, 0x2e, 0x4d, 0x6f, 0x6e, 0x6f, 0x2e, 0x45, 0x61, 0x72, 0x62,
	0x75, 0x67, 0x76, 0x35, 0xca, 0x02, 0x18, 0x53, 0x65, 0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69, 0x61,
	0x6f, 0x5c, 0x4d, 0x6f, 0x6e, 0x6f, 0x5c, 0x45, 0x61, 0x72, 0x62, 0x75, 0x67, 0x76, 0x35, 0xe2,
	0x02, 0x24, 0x53, 0x65, 0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69, 0x61, 0x6f, 0x5c, 0x4d, 0x6f, 0x6e,
	0x6f, 0x5c, 0x45, 0x61, 0x72, 0x62, 0x75, 0x67, 0x76, 0x35, 0x5c, 0x47, 0x50, 0x42, 0x4d, 0x65,
	0x74, 0x61, 0x64, 0x61, 0x74, 0x61, 0xea, 0x02, 0x1a, 0x53, 0x65, 0x61, 0x6e, 0x6b, 0x68, 0x6c,
	0x69, 0x61, 0x6f, 0x3a, 0x3a, 0x4d, 0x6f, 0x6e, 0x6f, 0x3a, 0x3a, 0x45, 0x61, 0x72, 0x62, 0x75,
	0x67, 0x76, 0x35, 0x62, 0x08, 0x65, 0x64, 0x69, 0x74, 0x69, 0x6f, 0x6e, 0x73, 0x70, 0xe8, 0x07,
}

var (
	file_cmd_moo_earbug_earbugv5_store_proto_rawDescOnce sync.Once
	file_cmd_moo_earbug_earbugv5_store_proto_rawDescData = file_cmd_moo_earbug_earbugv5_store_proto_rawDesc
)

func file_cmd_moo_earbug_earbugv5_store_proto_rawDescGZIP() []byte {
	file_cmd_moo_earbug_earbugv5_store_proto_rawDescOnce.Do(func() {
		file_cmd_moo_earbug_earbugv5_store_proto_rawDescData = protoimpl.X.CompressGZIP(file_cmd_moo_earbug_earbugv5_store_proto_rawDescData)
	})
	return file_cmd_moo_earbug_earbugv5_store_proto_rawDescData
}

var file_cmd_moo_earbug_earbugv5_store_proto_msgTypes = make([]protoimpl.MessageInfo, 8)
var file_cmd_moo_earbug_earbugv5_store_proto_goTypes = []any{
	(*Store)(nil),               // 0: seankhliao.mono.earbugv5.Store
	(*UserData)(nil),            // 1: seankhliao.mono.earbugv5.UserData
	(*Playback)(nil),            // 2: seankhliao.mono.earbugv5.Playback
	(*Track)(nil),               // 3: seankhliao.mono.earbugv5.Track
	(*Artist)(nil),              // 4: seankhliao.mono.earbugv5.Artist
	nil,                         // 5: seankhliao.mono.earbugv5.Store.TracksEntry
	nil,                         // 6: seankhliao.mono.earbugv5.Store.UsersEntry
	nil,                         // 7: seankhliao.mono.earbugv5.UserData.PlaybacksEntry
	(*durationpb.Duration)(nil), // 8: google.protobuf.Duration
}
var file_cmd_moo_earbug_earbugv5_store_proto_depIdxs = []int32{
	5, // 0: seankhliao.mono.earbugv5.Store.tracks:type_name -> seankhliao.mono.earbugv5.Store.TracksEntry
	6, // 1: seankhliao.mono.earbugv5.Store.users:type_name -> seankhliao.mono.earbugv5.Store.UsersEntry
	7, // 2: seankhliao.mono.earbugv5.UserData.playbacks:type_name -> seankhliao.mono.earbugv5.UserData.PlaybacksEntry
	8, // 3: seankhliao.mono.earbugv5.Track.duration:type_name -> google.protobuf.Duration
	4, // 4: seankhliao.mono.earbugv5.Track.artists:type_name -> seankhliao.mono.earbugv5.Artist
	3, // 5: seankhliao.mono.earbugv5.Store.TracksEntry.value:type_name -> seankhliao.mono.earbugv5.Track
	1, // 6: seankhliao.mono.earbugv5.Store.UsersEntry.value:type_name -> seankhliao.mono.earbugv5.UserData
	2, // 7: seankhliao.mono.earbugv5.UserData.PlaybacksEntry.value:type_name -> seankhliao.mono.earbugv5.Playback
	8, // [8:8] is the sub-list for method output_type
	8, // [8:8] is the sub-list for method input_type
	8, // [8:8] is the sub-list for extension type_name
	8, // [8:8] is the sub-list for extension extendee
	0, // [0:8] is the sub-list for field type_name
}

func init() { file_cmd_moo_earbug_earbugv5_store_proto_init() }
func file_cmd_moo_earbug_earbugv5_store_proto_init() {
	if File_cmd_moo_earbug_earbugv5_store_proto != nil {
		return
	}
	type x struct{}
	out := protoimpl.TypeBuilder{
		File: protoimpl.DescBuilder{
			GoPackagePath: reflect.TypeOf(x{}).PkgPath(),
			RawDescriptor: file_cmd_moo_earbug_earbugv5_store_proto_rawDesc,
			NumEnums:      0,
			NumMessages:   8,
			NumExtensions: 0,
			NumServices:   0,
		},
		GoTypes:           file_cmd_moo_earbug_earbugv5_store_proto_goTypes,
		DependencyIndexes: file_cmd_moo_earbug_earbugv5_store_proto_depIdxs,
		MessageInfos:      file_cmd_moo_earbug_earbugv5_store_proto_msgTypes,
	}.Build()
	File_cmd_moo_earbug_earbugv5_store_proto = out.File
	file_cmd_moo_earbug_earbugv5_store_proto_rawDesc = nil
	file_cmd_moo_earbug_earbugv5_store_proto_goTypes = nil
	file_cmd_moo_earbug_earbugv5_store_proto_depIdxs = nil
}
