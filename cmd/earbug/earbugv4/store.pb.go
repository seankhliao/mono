// Code generated by protoc-gen-go. DO NOT EDIT.
// versions:
// 	protoc-gen-go v1.31.0
// 	protoc        (unknown)
// source: cmd/earbug/earbugv4/store.proto

package earbugv4

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

	// Deprecated: Marked as deprecated in cmd/earbug/earbugv4/store.proto.
	Token []byte `protobuf:"bytes,2,opt,name=token,proto3" json:"token,omitempty"`
	// rfc3339 timestamp : playback
	Playbacks map[string]*Playback `protobuf:"bytes,3,rep,name=playbacks,proto3" json:"playbacks,omitempty" protobuf_key:"bytes,1,opt,name=key,proto3" protobuf_val:"bytes,2,opt,name=value,proto3"`
	// track id : track
	Tracks map[string]*Track `protobuf:"bytes,4,rep,name=tracks,proto3" json:"tracks,omitempty" protobuf_key:"bytes,1,opt,name=key,proto3" protobuf_val:"bytes,2,opt,name=value,proto3"`
	// cached auth credentials
	Auth *Auth `protobuf:"bytes,7,opt,name=auth,proto3" json:"auth,omitempty"`
}

func (x *Store) Reset() {
	*x = Store{}
	if protoimpl.UnsafeEnabled {
		mi := &file_cmd_earbug_earbugv4_store_proto_msgTypes[0]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *Store) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*Store) ProtoMessage() {}

func (x *Store) ProtoReflect() protoreflect.Message {
	mi := &file_cmd_earbug_earbugv4_store_proto_msgTypes[0]
	if protoimpl.UnsafeEnabled && x != nil {
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
	return file_cmd_earbug_earbugv4_store_proto_rawDescGZIP(), []int{0}
}

// Deprecated: Marked as deprecated in cmd/earbug/earbugv4/store.proto.
func (x *Store) GetToken() []byte {
	if x != nil {
		return x.Token
	}
	return nil
}

func (x *Store) GetPlaybacks() map[string]*Playback {
	if x != nil {
		return x.Playbacks
	}
	return nil
}

func (x *Store) GetTracks() map[string]*Track {
	if x != nil {
		return x.Tracks
	}
	return nil
}

func (x *Store) GetAuth() *Auth {
	if x != nil {
		return x.Auth
	}
	return nil
}

type Auth struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	Token        []byte `protobuf:"bytes,1,opt,name=token,proto3" json:"token,omitempty"`
	ClientId     string `protobuf:"bytes,2,opt,name=client_id,json=clientId,proto3" json:"client_id,omitempty"`
	ClientSecret string `protobuf:"bytes,3,opt,name=client_secret,json=clientSecret,proto3" json:"client_secret,omitempty"`
}

func (x *Auth) Reset() {
	*x = Auth{}
	if protoimpl.UnsafeEnabled {
		mi := &file_cmd_earbug_earbugv4_store_proto_msgTypes[1]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *Auth) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*Auth) ProtoMessage() {}

func (x *Auth) ProtoReflect() protoreflect.Message {
	mi := &file_cmd_earbug_earbugv4_store_proto_msgTypes[1]
	if protoimpl.UnsafeEnabled && x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use Auth.ProtoReflect.Descriptor instead.
func (*Auth) Descriptor() ([]byte, []int) {
	return file_cmd_earbug_earbugv4_store_proto_rawDescGZIP(), []int{1}
}

func (x *Auth) GetToken() []byte {
	if x != nil {
		return x.Token
	}
	return nil
}

func (x *Auth) GetClientId() string {
	if x != nil {
		return x.ClientId
	}
	return ""
}

func (x *Auth) GetClientSecret() string {
	if x != nil {
		return x.ClientSecret
	}
	return ""
}

type Playback struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	TrackId     string `protobuf:"bytes,1,opt,name=track_id,json=trackId,proto3" json:"track_id,omitempty"`
	TrackUri    string `protobuf:"bytes,2,opt,name=track_uri,json=trackUri,proto3" json:"track_uri,omitempty"`
	ContextType string `protobuf:"bytes,3,opt,name=context_type,json=contextType,proto3" json:"context_type,omitempty"`
	ContextUri  string `protobuf:"bytes,4,opt,name=context_uri,json=contextUri,proto3" json:"context_uri,omitempty"`
}

func (x *Playback) Reset() {
	*x = Playback{}
	if protoimpl.UnsafeEnabled {
		mi := &file_cmd_earbug_earbugv4_store_proto_msgTypes[2]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *Playback) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*Playback) ProtoMessage() {}

func (x *Playback) ProtoReflect() protoreflect.Message {
	mi := &file_cmd_earbug_earbugv4_store_proto_msgTypes[2]
	if protoimpl.UnsafeEnabled && x != nil {
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
	return file_cmd_earbug_earbugv4_store_proto_rawDescGZIP(), []int{2}
}

func (x *Playback) GetTrackId() string {
	if x != nil {
		return x.TrackId
	}
	return ""
}

func (x *Playback) GetTrackUri() string {
	if x != nil {
		return x.TrackUri
	}
	return ""
}

func (x *Playback) GetContextType() string {
	if x != nil {
		return x.ContextType
	}
	return ""
}

func (x *Playback) GetContextUri() string {
	if x != nil {
		return x.ContextUri
	}
	return ""
}

type Track struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	Id       string               `protobuf:"bytes,1,opt,name=id,proto3" json:"id,omitempty"`
	Uri      string               `protobuf:"bytes,2,opt,name=uri,proto3" json:"uri,omitempty"`
	Type     string               `protobuf:"bytes,3,opt,name=type,proto3" json:"type,omitempty"`
	Name     string               `protobuf:"bytes,4,opt,name=name,proto3" json:"name,omitempty"`
	Duration *durationpb.Duration `protobuf:"bytes,5,opt,name=duration,proto3" json:"duration,omitempty"`
	Artists  []*Artist            `protobuf:"bytes,6,rep,name=artists,proto3" json:"artists,omitempty"`
}

func (x *Track) Reset() {
	*x = Track{}
	if protoimpl.UnsafeEnabled {
		mi := &file_cmd_earbug_earbugv4_store_proto_msgTypes[3]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *Track) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*Track) ProtoMessage() {}

func (x *Track) ProtoReflect() protoreflect.Message {
	mi := &file_cmd_earbug_earbugv4_store_proto_msgTypes[3]
	if protoimpl.UnsafeEnabled && x != nil {
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
	return file_cmd_earbug_earbugv4_store_proto_rawDescGZIP(), []int{3}
}

func (x *Track) GetId() string {
	if x != nil {
		return x.Id
	}
	return ""
}

func (x *Track) GetUri() string {
	if x != nil {
		return x.Uri
	}
	return ""
}

func (x *Track) GetType() string {
	if x != nil {
		return x.Type
	}
	return ""
}

func (x *Track) GetName() string {
	if x != nil {
		return x.Name
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

	Id   string `protobuf:"bytes,1,opt,name=id,proto3" json:"id,omitempty"`
	Uri  string `protobuf:"bytes,2,opt,name=uri,proto3" json:"uri,omitempty"`
	Name string `protobuf:"bytes,3,opt,name=name,proto3" json:"name,omitempty"`
}

func (x *Artist) Reset() {
	*x = Artist{}
	if protoimpl.UnsafeEnabled {
		mi := &file_cmd_earbug_earbugv4_store_proto_msgTypes[4]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *Artist) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*Artist) ProtoMessage() {}

func (x *Artist) ProtoReflect() protoreflect.Message {
	mi := &file_cmd_earbug_earbugv4_store_proto_msgTypes[4]
	if protoimpl.UnsafeEnabled && x != nil {
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
	return file_cmd_earbug_earbugv4_store_proto_rawDescGZIP(), []int{4}
}

func (x *Artist) GetId() string {
	if x != nil {
		return x.Id
	}
	return ""
}

func (x *Artist) GetUri() string {
	if x != nil {
		return x.Uri
	}
	return ""
}

func (x *Artist) GetName() string {
	if x != nil {
		return x.Name
	}
	return ""
}

var File_cmd_earbug_earbugv4_store_proto protoreflect.FileDescriptor

var file_cmd_earbug_earbugv4_store_proto_rawDesc = []byte{
	0x0a, 0x1f, 0x63, 0x6d, 0x64, 0x2f, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x2f, 0x65, 0x61, 0x72,
	0x62, 0x75, 0x67, 0x76, 0x34, 0x2f, 0x73, 0x74, 0x6f, 0x72, 0x65, 0x2e, 0x70, 0x72, 0x6f, 0x74,
	0x6f, 0x12, 0x14, 0x73, 0x65, 0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69, 0x61, 0x6f, 0x2e, 0x65, 0x61,
	0x72, 0x62, 0x75, 0x67, 0x2e, 0x76, 0x34, 0x1a, 0x1e, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2f,
	0x70, 0x72, 0x6f, 0x74, 0x6f, 0x62, 0x75, 0x66, 0x2f, 0x64, 0x75, 0x72, 0x61, 0x74, 0x69, 0x6f,
	0x6e, 0x2e, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x22, 0xa4, 0x03, 0x0a, 0x05, 0x53, 0x74, 0x6f, 0x72,
	0x65, 0x12, 0x18, 0x0a, 0x05, 0x74, 0x6f, 0x6b, 0x65, 0x6e, 0x18, 0x02, 0x20, 0x01, 0x28, 0x0c,
	0x42, 0x02, 0x18, 0x01, 0x52, 0x05, 0x74, 0x6f, 0x6b, 0x65, 0x6e, 0x12, 0x48, 0x0a, 0x09, 0x70,
	0x6c, 0x61, 0x79, 0x62, 0x61, 0x63, 0x6b, 0x73, 0x18, 0x03, 0x20, 0x03, 0x28, 0x0b, 0x32, 0x2a,
	0x2e, 0x73, 0x65, 0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69, 0x61, 0x6f, 0x2e, 0x65, 0x61, 0x72, 0x62,
	0x75, 0x67, 0x2e, 0x76, 0x34, 0x2e, 0x53, 0x74, 0x6f, 0x72, 0x65, 0x2e, 0x50, 0x6c, 0x61, 0x79,
	0x62, 0x61, 0x63, 0x6b, 0x73, 0x45, 0x6e, 0x74, 0x72, 0x79, 0x52, 0x09, 0x70, 0x6c, 0x61, 0x79,
	0x62, 0x61, 0x63, 0x6b, 0x73, 0x12, 0x3f, 0x0a, 0x06, 0x74, 0x72, 0x61, 0x63, 0x6b, 0x73, 0x18,
	0x04, 0x20, 0x03, 0x28, 0x0b, 0x32, 0x27, 0x2e, 0x73, 0x65, 0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69,
	0x61, 0x6f, 0x2e, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x2e, 0x76, 0x34, 0x2e, 0x53, 0x74, 0x6f,
	0x72, 0x65, 0x2e, 0x54, 0x72, 0x61, 0x63, 0x6b, 0x73, 0x45, 0x6e, 0x74, 0x72, 0x79, 0x52, 0x06,
	0x74, 0x72, 0x61, 0x63, 0x6b, 0x73, 0x12, 0x2e, 0x0a, 0x04, 0x61, 0x75, 0x74, 0x68, 0x18, 0x07,
	0x20, 0x01, 0x28, 0x0b, 0x32, 0x1a, 0x2e, 0x73, 0x65, 0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69, 0x61,
	0x6f, 0x2e, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x2e, 0x76, 0x34, 0x2e, 0x41, 0x75, 0x74, 0x68,
	0x52, 0x04, 0x61, 0x75, 0x74, 0x68, 0x1a, 0x5c, 0x0a, 0x0e, 0x50, 0x6c, 0x61, 0x79, 0x62, 0x61,
	0x63, 0x6b, 0x73, 0x45, 0x6e, 0x74, 0x72, 0x79, 0x12, 0x10, 0x0a, 0x03, 0x6b, 0x65, 0x79, 0x18,
	0x01, 0x20, 0x01, 0x28, 0x09, 0x52, 0x03, 0x6b, 0x65, 0x79, 0x12, 0x34, 0x0a, 0x05, 0x76, 0x61,
	0x6c, 0x75, 0x65, 0x18, 0x02, 0x20, 0x01, 0x28, 0x0b, 0x32, 0x1e, 0x2e, 0x73, 0x65, 0x61, 0x6e,
	0x6b, 0x68, 0x6c, 0x69, 0x61, 0x6f, 0x2e, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x2e, 0x76, 0x34,
	0x2e, 0x50, 0x6c, 0x61, 0x79, 0x62, 0x61, 0x63, 0x6b, 0x52, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65,
	0x3a, 0x02, 0x38, 0x01, 0x1a, 0x56, 0x0a, 0x0b, 0x54, 0x72, 0x61, 0x63, 0x6b, 0x73, 0x45, 0x6e,
	0x74, 0x72, 0x79, 0x12, 0x10, 0x0a, 0x03, 0x6b, 0x65, 0x79, 0x18, 0x01, 0x20, 0x01, 0x28, 0x09,
	0x52, 0x03, 0x6b, 0x65, 0x79, 0x12, 0x31, 0x0a, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x18, 0x02,
	0x20, 0x01, 0x28, 0x0b, 0x32, 0x1b, 0x2e, 0x73, 0x65, 0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69, 0x61,
	0x6f, 0x2e, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x2e, 0x76, 0x34, 0x2e, 0x54, 0x72, 0x61, 0x63,
	0x6b, 0x52, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x3a, 0x02, 0x38, 0x01, 0x4a, 0x04, 0x08, 0x01,
	0x10, 0x02, 0x4a, 0x04, 0x08, 0x05, 0x10, 0x06, 0x4a, 0x04, 0x08, 0x06, 0x10, 0x07, 0x22, 0x5e,
	0x0a, 0x04, 0x41, 0x75, 0x74, 0x68, 0x12, 0x14, 0x0a, 0x05, 0x74, 0x6f, 0x6b, 0x65, 0x6e, 0x18,
	0x01, 0x20, 0x01, 0x28, 0x0c, 0x52, 0x05, 0x74, 0x6f, 0x6b, 0x65, 0x6e, 0x12, 0x1b, 0x0a, 0x09,
	0x63, 0x6c, 0x69, 0x65, 0x6e, 0x74, 0x5f, 0x69, 0x64, 0x18, 0x02, 0x20, 0x01, 0x28, 0x09, 0x52,
	0x08, 0x63, 0x6c, 0x69, 0x65, 0x6e, 0x74, 0x49, 0x64, 0x12, 0x23, 0x0a, 0x0d, 0x63, 0x6c, 0x69,
	0x65, 0x6e, 0x74, 0x5f, 0x73, 0x65, 0x63, 0x72, 0x65, 0x74, 0x18, 0x03, 0x20, 0x01, 0x28, 0x09,
	0x52, 0x0c, 0x63, 0x6c, 0x69, 0x65, 0x6e, 0x74, 0x53, 0x65, 0x63, 0x72, 0x65, 0x74, 0x22, 0x86,
	0x01, 0x0a, 0x08, 0x50, 0x6c, 0x61, 0x79, 0x62, 0x61, 0x63, 0x6b, 0x12, 0x19, 0x0a, 0x08, 0x74,
	0x72, 0x61, 0x63, 0x6b, 0x5f, 0x69, 0x64, 0x18, 0x01, 0x20, 0x01, 0x28, 0x09, 0x52, 0x07, 0x74,
	0x72, 0x61, 0x63, 0x6b, 0x49, 0x64, 0x12, 0x1b, 0x0a, 0x09, 0x74, 0x72, 0x61, 0x63, 0x6b, 0x5f,
	0x75, 0x72, 0x69, 0x18, 0x02, 0x20, 0x01, 0x28, 0x09, 0x52, 0x08, 0x74, 0x72, 0x61, 0x63, 0x6b,
	0x55, 0x72, 0x69, 0x12, 0x21, 0x0a, 0x0c, 0x63, 0x6f, 0x6e, 0x74, 0x65, 0x78, 0x74, 0x5f, 0x74,
	0x79, 0x70, 0x65, 0x18, 0x03, 0x20, 0x01, 0x28, 0x09, 0x52, 0x0b, 0x63, 0x6f, 0x6e, 0x74, 0x65,
	0x78, 0x74, 0x54, 0x79, 0x70, 0x65, 0x12, 0x1f, 0x0a, 0x0b, 0x63, 0x6f, 0x6e, 0x74, 0x65, 0x78,
	0x74, 0x5f, 0x75, 0x72, 0x69, 0x18, 0x04, 0x20, 0x01, 0x28, 0x09, 0x52, 0x0a, 0x63, 0x6f, 0x6e,
	0x74, 0x65, 0x78, 0x74, 0x55, 0x72, 0x69, 0x22, 0xc0, 0x01, 0x0a, 0x05, 0x54, 0x72, 0x61, 0x63,
	0x6b, 0x12, 0x0e, 0x0a, 0x02, 0x69, 0x64, 0x18, 0x01, 0x20, 0x01, 0x28, 0x09, 0x52, 0x02, 0x69,
	0x64, 0x12, 0x10, 0x0a, 0x03, 0x75, 0x72, 0x69, 0x18, 0x02, 0x20, 0x01, 0x28, 0x09, 0x52, 0x03,
	0x75, 0x72, 0x69, 0x12, 0x12, 0x0a, 0x04, 0x74, 0x79, 0x70, 0x65, 0x18, 0x03, 0x20, 0x01, 0x28,
	0x09, 0x52, 0x04, 0x74, 0x79, 0x70, 0x65, 0x12, 0x12, 0x0a, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x18,
	0x04, 0x20, 0x01, 0x28, 0x09, 0x52, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x12, 0x35, 0x0a, 0x08, 0x64,
	0x75, 0x72, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x18, 0x05, 0x20, 0x01, 0x28, 0x0b, 0x32, 0x19, 0x2e,
	0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2e, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x62, 0x75, 0x66, 0x2e,
	0x44, 0x75, 0x72, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x52, 0x08, 0x64, 0x75, 0x72, 0x61, 0x74, 0x69,
	0x6f, 0x6e, 0x12, 0x36, 0x0a, 0x07, 0x61, 0x72, 0x74, 0x69, 0x73, 0x74, 0x73, 0x18, 0x06, 0x20,
	0x03, 0x28, 0x0b, 0x32, 0x1c, 0x2e, 0x73, 0x65, 0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69, 0x61, 0x6f,
	0x2e, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x2e, 0x76, 0x34, 0x2e, 0x41, 0x72, 0x74, 0x69, 0x73,
	0x74, 0x52, 0x07, 0x61, 0x72, 0x74, 0x69, 0x73, 0x74, 0x73, 0x22, 0x3e, 0x0a, 0x06, 0x41, 0x72,
	0x74, 0x69, 0x73, 0x74, 0x12, 0x0e, 0x0a, 0x02, 0x69, 0x64, 0x18, 0x01, 0x20, 0x01, 0x28, 0x09,
	0x52, 0x02, 0x69, 0x64, 0x12, 0x10, 0x0a, 0x03, 0x75, 0x72, 0x69, 0x18, 0x02, 0x20, 0x01, 0x28,
	0x09, 0x52, 0x03, 0x75, 0x72, 0x69, 0x12, 0x12, 0x0a, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x18, 0x03,
	0x20, 0x01, 0x28, 0x09, 0x52, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x42, 0xcd, 0x01, 0x0a, 0x18, 0x63,
	0x6f, 0x6d, 0x2e, 0x73, 0x65, 0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69, 0x61, 0x6f, 0x2e, 0x65, 0x61,
	0x72, 0x62, 0x75, 0x67, 0x2e, 0x76, 0x34, 0x42, 0x0a, 0x53, 0x74, 0x6f, 0x72, 0x65, 0x50, 0x72,
	0x6f, 0x74, 0x6f, 0x50, 0x01, 0x5a, 0x33, 0x67, 0x6f, 0x2e, 0x73, 0x65, 0x61, 0x6e, 0x6b, 0x68,
	0x6c, 0x69, 0x61, 0x6f, 0x2e, 0x63, 0x6f, 0x6d, 0x2f, 0x6d, 0x6f, 0x6e, 0x6f, 0x2f, 0x63, 0x6d,
	0x64, 0x2f, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x2f, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x76,
	0x34, 0x3b, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x76, 0x34, 0xa2, 0x02, 0x03, 0x53, 0x45, 0x58,
	0xaa, 0x02, 0x14, 0x53, 0x65, 0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69, 0x61, 0x6f, 0x2e, 0x45, 0x61,
	0x72, 0x62, 0x75, 0x67, 0x2e, 0x56, 0x34, 0xca, 0x02, 0x14, 0x53, 0x65, 0x61, 0x6e, 0x6b, 0x68,
	0x6c, 0x69, 0x61, 0x6f, 0x5c, 0x45, 0x61, 0x72, 0x62, 0x75, 0x67, 0x5c, 0x56, 0x34, 0xe2, 0x02,
	0x20, 0x53, 0x65, 0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69, 0x61, 0x6f, 0x5c, 0x45, 0x61, 0x72, 0x62,
	0x75, 0x67, 0x5c, 0x56, 0x34, 0x5c, 0x47, 0x50, 0x42, 0x4d, 0x65, 0x74, 0x61, 0x64, 0x61, 0x74,
	0x61, 0xea, 0x02, 0x16, 0x53, 0x65, 0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69, 0x61, 0x6f, 0x3a, 0x3a,
	0x45, 0x61, 0x72, 0x62, 0x75, 0x67, 0x3a, 0x3a, 0x56, 0x34, 0x62, 0x06, 0x70, 0x72, 0x6f, 0x74,
	0x6f, 0x33,
}

var (
	file_cmd_earbug_earbugv4_store_proto_rawDescOnce sync.Once
	file_cmd_earbug_earbugv4_store_proto_rawDescData = file_cmd_earbug_earbugv4_store_proto_rawDesc
)

func file_cmd_earbug_earbugv4_store_proto_rawDescGZIP() []byte {
	file_cmd_earbug_earbugv4_store_proto_rawDescOnce.Do(func() {
		file_cmd_earbug_earbugv4_store_proto_rawDescData = protoimpl.X.CompressGZIP(file_cmd_earbug_earbugv4_store_proto_rawDescData)
	})
	return file_cmd_earbug_earbugv4_store_proto_rawDescData
}

var file_cmd_earbug_earbugv4_store_proto_msgTypes = make([]protoimpl.MessageInfo, 7)
var file_cmd_earbug_earbugv4_store_proto_goTypes = []interface{}{
	(*Store)(nil),               // 0: seankhliao.earbug.v4.Store
	(*Auth)(nil),                // 1: seankhliao.earbug.v4.Auth
	(*Playback)(nil),            // 2: seankhliao.earbug.v4.Playback
	(*Track)(nil),               // 3: seankhliao.earbug.v4.Track
	(*Artist)(nil),              // 4: seankhliao.earbug.v4.Artist
	nil,                         // 5: seankhliao.earbug.v4.Store.PlaybacksEntry
	nil,                         // 6: seankhliao.earbug.v4.Store.TracksEntry
	(*durationpb.Duration)(nil), // 7: google.protobuf.Duration
}
var file_cmd_earbug_earbugv4_store_proto_depIdxs = []int32{
	5, // 0: seankhliao.earbug.v4.Store.playbacks:type_name -> seankhliao.earbug.v4.Store.PlaybacksEntry
	6, // 1: seankhliao.earbug.v4.Store.tracks:type_name -> seankhliao.earbug.v4.Store.TracksEntry
	1, // 2: seankhliao.earbug.v4.Store.auth:type_name -> seankhliao.earbug.v4.Auth
	7, // 3: seankhliao.earbug.v4.Track.duration:type_name -> google.protobuf.Duration
	4, // 4: seankhliao.earbug.v4.Track.artists:type_name -> seankhliao.earbug.v4.Artist
	2, // 5: seankhliao.earbug.v4.Store.PlaybacksEntry.value:type_name -> seankhliao.earbug.v4.Playback
	3, // 6: seankhliao.earbug.v4.Store.TracksEntry.value:type_name -> seankhliao.earbug.v4.Track
	7, // [7:7] is the sub-list for method output_type
	7, // [7:7] is the sub-list for method input_type
	7, // [7:7] is the sub-list for extension type_name
	7, // [7:7] is the sub-list for extension extendee
	0, // [0:7] is the sub-list for field type_name
}

func init() { file_cmd_earbug_earbugv4_store_proto_init() }
func file_cmd_earbug_earbugv4_store_proto_init() {
	if File_cmd_earbug_earbugv4_store_proto != nil {
		return
	}
	if !protoimpl.UnsafeEnabled {
		file_cmd_earbug_earbugv4_store_proto_msgTypes[0].Exporter = func(v interface{}, i int) interface{} {
			switch v := v.(*Store); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
		file_cmd_earbug_earbugv4_store_proto_msgTypes[1].Exporter = func(v interface{}, i int) interface{} {
			switch v := v.(*Auth); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
		file_cmd_earbug_earbugv4_store_proto_msgTypes[2].Exporter = func(v interface{}, i int) interface{} {
			switch v := v.(*Playback); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
		file_cmd_earbug_earbugv4_store_proto_msgTypes[3].Exporter = func(v interface{}, i int) interface{} {
			switch v := v.(*Track); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
		file_cmd_earbug_earbugv4_store_proto_msgTypes[4].Exporter = func(v interface{}, i int) interface{} {
			switch v := v.(*Artist); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
	}
	type x struct{}
	out := protoimpl.TypeBuilder{
		File: protoimpl.DescBuilder{
			GoPackagePath: reflect.TypeOf(x{}).PkgPath(),
			RawDescriptor: file_cmd_earbug_earbugv4_store_proto_rawDesc,
			NumEnums:      0,
			NumMessages:   7,
			NumExtensions: 0,
			NumServices:   0,
		},
		GoTypes:           file_cmd_earbug_earbugv4_store_proto_goTypes,
		DependencyIndexes: file_cmd_earbug_earbugv4_store_proto_depIdxs,
		MessageInfos:      file_cmd_earbug_earbugv4_store_proto_msgTypes,
	}.Build()
	File_cmd_earbug_earbugv4_store_proto = out.File
	file_cmd_earbug_earbugv4_store_proto_rawDesc = nil
	file_cmd_earbug_earbugv4_store_proto_goTypes = nil
	file_cmd_earbug_earbugv4_store_proto_depIdxs = nil
}
