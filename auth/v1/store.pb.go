// Code generated by protoc-gen-go. DO NOT EDIT.
// versions:
// 	protoc-gen-go v1.36.4
// 	protoc        (unknown)
// source: auth/v1/store.proto

package authv1

import (
	protoreflect "google.golang.org/protobuf/reflect/protoreflect"
	protoimpl "google.golang.org/protobuf/runtime/protoimpl"
	timestamppb "google.golang.org/protobuf/types/known/timestamppb"
	reflect "reflect"
	unsafe "unsafe"
)

const (
	// Verify that this generated code is sufficiently up-to-date.
	_ = protoimpl.EnforceVersion(20 - protoimpl.MinVersion)
	// Verify that runtime/protoimpl is sufficiently up-to-date.
	_ = protoimpl.EnforceVersion(protoimpl.MaxVersion - 20)
)

type Store struct {
	state               protoimpl.MessageState `protogen:"opaque.v1"`
	xxx_hidden_Sessions map[string]*TokenInfo  `protobuf:"bytes,1,rep,name=sessions" protobuf_key:"bytes,1,opt,name=key" protobuf_val:"bytes,2,opt,name=value"`
	xxx_hidden_Users    map[int64]*UserInfo    `protobuf:"bytes,2,rep,name=users" protobuf_key:"varint,1,opt,name=key" protobuf_val:"bytes,2,opt,name=value"`
	unknownFields       protoimpl.UnknownFields
	sizeCache           protoimpl.SizeCache
}

func (x *Store) Reset() {
	*x = Store{}
	mi := &file_auth_v1_store_proto_msgTypes[0]
	ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
	ms.StoreMessageInfo(mi)
}

func (x *Store) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*Store) ProtoMessage() {}

func (x *Store) ProtoReflect() protoreflect.Message {
	mi := &file_auth_v1_store_proto_msgTypes[0]
	if x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

func (x *Store) GetSessions() map[string]*TokenInfo {
	if x != nil {
		return x.xxx_hidden_Sessions
	}
	return nil
}

func (x *Store) GetUsers() map[int64]*UserInfo {
	if x != nil {
		return x.xxx_hidden_Users
	}
	return nil
}

func (x *Store) SetSessions(v map[string]*TokenInfo) {
	x.xxx_hidden_Sessions = v
}

func (x *Store) SetUsers(v map[int64]*UserInfo) {
	x.xxx_hidden_Users = v
}

type Store_builder struct {
	_ [0]func() // Prevents comparability and use of unkeyed literals for the builder.

	Sessions map[string]*TokenInfo
	Users    map[int64]*UserInfo
}

func (b0 Store_builder) Build() *Store {
	m0 := &Store{}
	b, x := &b0, m0
	_, _ = b, x
	x.xxx_hidden_Sessions = b.Sessions
	x.xxx_hidden_Users = b.Users
	return m0
}

type TokenInfo struct {
	state                  protoimpl.MessageState `protogen:"opaque.v1"`
	xxx_hidden_SessionId   *string                `protobuf:"bytes,1,opt,name=session_id,json=sessionId"`
	xxx_hidden_Created     *timestamppb.Timestamp `protobuf:"bytes,2,opt,name=created"`
	xxx_hidden_UserId      int64                  `protobuf:"varint,3,opt,name=user_id,json=userId"`
	xxx_hidden_SessionData []byte                 `protobuf:"bytes,4,opt,name=session_data,json=sessionData"`
	xxx_hidden_CredName    *string                `protobuf:"bytes,5,opt,name=cred_name,json=credName"`
	XXX_raceDetectHookData protoimpl.RaceDetectHookData
	XXX_presence           [1]uint32
	unknownFields          protoimpl.UnknownFields
	sizeCache              protoimpl.SizeCache
}

func (x *TokenInfo) Reset() {
	*x = TokenInfo{}
	mi := &file_auth_v1_store_proto_msgTypes[1]
	ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
	ms.StoreMessageInfo(mi)
}

func (x *TokenInfo) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*TokenInfo) ProtoMessage() {}

func (x *TokenInfo) ProtoReflect() protoreflect.Message {
	mi := &file_auth_v1_store_proto_msgTypes[1]
	if x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

func (x *TokenInfo) GetSessionId() string {
	if x != nil {
		if x.xxx_hidden_SessionId != nil {
			return *x.xxx_hidden_SessionId
		}
		return ""
	}
	return ""
}

func (x *TokenInfo) GetCreated() *timestamppb.Timestamp {
	if x != nil {
		return x.xxx_hidden_Created
	}
	return nil
}

func (x *TokenInfo) GetUserId() int64 {
	if x != nil {
		return x.xxx_hidden_UserId
	}
	return 0
}

func (x *TokenInfo) GetSessionData() []byte {
	if x != nil {
		return x.xxx_hidden_SessionData
	}
	return nil
}

func (x *TokenInfo) GetCredName() string {
	if x != nil {
		if x.xxx_hidden_CredName != nil {
			return *x.xxx_hidden_CredName
		}
		return ""
	}
	return ""
}

func (x *TokenInfo) SetSessionId(v string) {
	x.xxx_hidden_SessionId = &v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 0, 5)
}

func (x *TokenInfo) SetCreated(v *timestamppb.Timestamp) {
	x.xxx_hidden_Created = v
}

func (x *TokenInfo) SetUserId(v int64) {
	x.xxx_hidden_UserId = v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 2, 5)
}

func (x *TokenInfo) SetSessionData(v []byte) {
	if v == nil {
		v = []byte{}
	}
	x.xxx_hidden_SessionData = v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 3, 5)
}

func (x *TokenInfo) SetCredName(v string) {
	x.xxx_hidden_CredName = &v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 4, 5)
}

func (x *TokenInfo) HasSessionId() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 0)
}

func (x *TokenInfo) HasCreated() bool {
	if x == nil {
		return false
	}
	return x.xxx_hidden_Created != nil
}

func (x *TokenInfo) HasUserId() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 2)
}

func (x *TokenInfo) HasSessionData() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 3)
}

func (x *TokenInfo) HasCredName() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 4)
}

func (x *TokenInfo) ClearSessionId() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 0)
	x.xxx_hidden_SessionId = nil
}

func (x *TokenInfo) ClearCreated() {
	x.xxx_hidden_Created = nil
}

func (x *TokenInfo) ClearUserId() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 2)
	x.xxx_hidden_UserId = 0
}

func (x *TokenInfo) ClearSessionData() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 3)
	x.xxx_hidden_SessionData = nil
}

func (x *TokenInfo) ClearCredName() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 4)
	x.xxx_hidden_CredName = nil
}

type TokenInfo_builder struct {
	_ [0]func() // Prevents comparability and use of unkeyed literals for the builder.

	SessionId   *string
	Created     *timestamppb.Timestamp
	UserId      *int64
	SessionData []byte
	CredName    *string
}

func (b0 TokenInfo_builder) Build() *TokenInfo {
	m0 := &TokenInfo{}
	b, x := &b0, m0
	_, _ = b, x
	if b.SessionId != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 0, 5)
		x.xxx_hidden_SessionId = b.SessionId
	}
	x.xxx_hidden_Created = b.Created
	if b.UserId != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 2, 5)
		x.xxx_hidden_UserId = *b.UserId
	}
	if b.SessionData != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 3, 5)
		x.xxx_hidden_SessionData = b.SessionData
	}
	if b.CredName != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 4, 5)
		x.xxx_hidden_CredName = b.CredName
	}
	return m0
}

type UserInfo struct {
	state                  protoimpl.MessageState `protogen:"opaque.v1"`
	xxx_hidden_UserId      int64                  `protobuf:"varint,1,opt,name=user_id,json=userId"`
	xxx_hidden_Username    *string                `protobuf:"bytes,2,opt,name=username"`
	xxx_hidden_Creds       *[]*Credential         `protobuf:"bytes,4,rep,name=creds"`
	XXX_raceDetectHookData protoimpl.RaceDetectHookData
	XXX_presence           [1]uint32
	unknownFields          protoimpl.UnknownFields
	sizeCache              protoimpl.SizeCache
}

func (x *UserInfo) Reset() {
	*x = UserInfo{}
	mi := &file_auth_v1_store_proto_msgTypes[2]
	ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
	ms.StoreMessageInfo(mi)
}

func (x *UserInfo) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*UserInfo) ProtoMessage() {}

func (x *UserInfo) ProtoReflect() protoreflect.Message {
	mi := &file_auth_v1_store_proto_msgTypes[2]
	if x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

func (x *UserInfo) GetUserId() int64 {
	if x != nil {
		return x.xxx_hidden_UserId
	}
	return 0
}

func (x *UserInfo) GetUsername() string {
	if x != nil {
		if x.xxx_hidden_Username != nil {
			return *x.xxx_hidden_Username
		}
		return ""
	}
	return ""
}

func (x *UserInfo) GetCreds() []*Credential {
	if x != nil {
		if x.xxx_hidden_Creds != nil {
			return *x.xxx_hidden_Creds
		}
	}
	return nil
}

func (x *UserInfo) SetUserId(v int64) {
	x.xxx_hidden_UserId = v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 0, 3)
}

func (x *UserInfo) SetUsername(v string) {
	x.xxx_hidden_Username = &v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 1, 3)
}

func (x *UserInfo) SetCreds(v []*Credential) {
	x.xxx_hidden_Creds = &v
}

func (x *UserInfo) HasUserId() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 0)
}

func (x *UserInfo) HasUsername() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 1)
}

func (x *UserInfo) ClearUserId() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 0)
	x.xxx_hidden_UserId = 0
}

func (x *UserInfo) ClearUsername() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 1)
	x.xxx_hidden_Username = nil
}

type UserInfo_builder struct {
	_ [0]func() // Prevents comparability and use of unkeyed literals for the builder.

	UserId   *int64
	Username *string
	Creds    []*Credential
}

func (b0 UserInfo_builder) Build() *UserInfo {
	m0 := &UserInfo{}
	b, x := &b0, m0
	_, _ = b, x
	if b.UserId != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 0, 3)
		x.xxx_hidden_UserId = *b.UserId
	}
	if b.Username != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 1, 3)
		x.xxx_hidden_Username = b.Username
	}
	x.xxx_hidden_Creds = &b.Creds
	return m0
}

type Credential struct {
	state                  protoimpl.MessageState `protogen:"opaque.v1"`
	xxx_hidden_Name        *string                `protobuf:"bytes,1,opt,name=name"`
	xxx_hidden_Cred        []byte                 `protobuf:"bytes,2,opt,name=cred"`
	XXX_raceDetectHookData protoimpl.RaceDetectHookData
	XXX_presence           [1]uint32
	unknownFields          protoimpl.UnknownFields
	sizeCache              protoimpl.SizeCache
}

func (x *Credential) Reset() {
	*x = Credential{}
	mi := &file_auth_v1_store_proto_msgTypes[3]
	ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
	ms.StoreMessageInfo(mi)
}

func (x *Credential) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*Credential) ProtoMessage() {}

func (x *Credential) ProtoReflect() protoreflect.Message {
	mi := &file_auth_v1_store_proto_msgTypes[3]
	if x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

func (x *Credential) GetName() string {
	if x != nil {
		if x.xxx_hidden_Name != nil {
			return *x.xxx_hidden_Name
		}
		return ""
	}
	return ""
}

func (x *Credential) GetCred() []byte {
	if x != nil {
		return x.xxx_hidden_Cred
	}
	return nil
}

func (x *Credential) SetName(v string) {
	x.xxx_hidden_Name = &v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 0, 2)
}

func (x *Credential) SetCred(v []byte) {
	if v == nil {
		v = []byte{}
	}
	x.xxx_hidden_Cred = v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 1, 2)
}

func (x *Credential) HasName() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 0)
}

func (x *Credential) HasCred() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 1)
}

func (x *Credential) ClearName() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 0)
	x.xxx_hidden_Name = nil
}

func (x *Credential) ClearCred() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 1)
	x.xxx_hidden_Cred = nil
}

type Credential_builder struct {
	_ [0]func() // Prevents comparability and use of unkeyed literals for the builder.

	Name *string
	Cred []byte
}

func (b0 Credential_builder) Build() *Credential {
	m0 := &Credential{}
	b, x := &b0, m0
	_, _ = b, x
	if b.Name != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 0, 2)
		x.xxx_hidden_Name = b.Name
	}
	if b.Cred != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 1, 2)
		x.xxx_hidden_Cred = b.Cred
	}
	return m0
}

var File_auth_v1_store_proto protoreflect.FileDescriptor

var file_auth_v1_store_proto_rawDesc = string([]byte{
	0x0a, 0x13, 0x61, 0x75, 0x74, 0x68, 0x2f, 0x76, 0x31, 0x2f, 0x73, 0x74, 0x6f, 0x72, 0x65, 0x2e,
	0x70, 0x72, 0x6f, 0x74, 0x6f, 0x12, 0x07, 0x61, 0x75, 0x74, 0x68, 0x2e, 0x76, 0x31, 0x1a, 0x1f,
	0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2f, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x62, 0x75, 0x66, 0x2f,
	0x74, 0x69, 0x6d, 0x65, 0x73, 0x74, 0x61, 0x6d, 0x70, 0x2e, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x22,
	0x90, 0x02, 0x0a, 0x05, 0x53, 0x74, 0x6f, 0x72, 0x65, 0x12, 0x38, 0x0a, 0x08, 0x73, 0x65, 0x73,
	0x73, 0x69, 0x6f, 0x6e, 0x73, 0x18, 0x01, 0x20, 0x03, 0x28, 0x0b, 0x32, 0x1c, 0x2e, 0x61, 0x75,
	0x74, 0x68, 0x2e, 0x76, 0x31, 0x2e, 0x53, 0x74, 0x6f, 0x72, 0x65, 0x2e, 0x53, 0x65, 0x73, 0x73,
	0x69, 0x6f, 0x6e, 0x73, 0x45, 0x6e, 0x74, 0x72, 0x79, 0x52, 0x08, 0x73, 0x65, 0x73, 0x73, 0x69,
	0x6f, 0x6e, 0x73, 0x12, 0x2f, 0x0a, 0x05, 0x75, 0x73, 0x65, 0x72, 0x73, 0x18, 0x02, 0x20, 0x03,
	0x28, 0x0b, 0x32, 0x19, 0x2e, 0x61, 0x75, 0x74, 0x68, 0x2e, 0x76, 0x31, 0x2e, 0x53, 0x74, 0x6f,
	0x72, 0x65, 0x2e, 0x55, 0x73, 0x65, 0x72, 0x73, 0x45, 0x6e, 0x74, 0x72, 0x79, 0x52, 0x05, 0x75,
	0x73, 0x65, 0x72, 0x73, 0x1a, 0x4f, 0x0a, 0x0d, 0x53, 0x65, 0x73, 0x73, 0x69, 0x6f, 0x6e, 0x73,
	0x45, 0x6e, 0x74, 0x72, 0x79, 0x12, 0x10, 0x0a, 0x03, 0x6b, 0x65, 0x79, 0x18, 0x01, 0x20, 0x01,
	0x28, 0x09, 0x52, 0x03, 0x6b, 0x65, 0x79, 0x12, 0x28, 0x0a, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65,
	0x18, 0x02, 0x20, 0x01, 0x28, 0x0b, 0x32, 0x12, 0x2e, 0x61, 0x75, 0x74, 0x68, 0x2e, 0x76, 0x31,
	0x2e, 0x54, 0x6f, 0x6b, 0x65, 0x6e, 0x49, 0x6e, 0x66, 0x6f, 0x52, 0x05, 0x76, 0x61, 0x6c, 0x75,
	0x65, 0x3a, 0x02, 0x38, 0x01, 0x1a, 0x4b, 0x0a, 0x0a, 0x55, 0x73, 0x65, 0x72, 0x73, 0x45, 0x6e,
	0x74, 0x72, 0x79, 0x12, 0x10, 0x0a, 0x03, 0x6b, 0x65, 0x79, 0x18, 0x01, 0x20, 0x01, 0x28, 0x03,
	0x52, 0x03, 0x6b, 0x65, 0x79, 0x12, 0x27, 0x0a, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x18, 0x02,
	0x20, 0x01, 0x28, 0x0b, 0x32, 0x11, 0x2e, 0x61, 0x75, 0x74, 0x68, 0x2e, 0x76, 0x31, 0x2e, 0x55,
	0x73, 0x65, 0x72, 0x49, 0x6e, 0x66, 0x6f, 0x52, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x3a, 0x02,
	0x38, 0x01, 0x22, 0xb9, 0x01, 0x0a, 0x09, 0x54, 0x6f, 0x6b, 0x65, 0x6e, 0x49, 0x6e, 0x66, 0x6f,
	0x12, 0x1d, 0x0a, 0x0a, 0x73, 0x65, 0x73, 0x73, 0x69, 0x6f, 0x6e, 0x5f, 0x69, 0x64, 0x18, 0x01,
	0x20, 0x01, 0x28, 0x09, 0x52, 0x09, 0x73, 0x65, 0x73, 0x73, 0x69, 0x6f, 0x6e, 0x49, 0x64, 0x12,
	0x34, 0x0a, 0x07, 0x63, 0x72, 0x65, 0x61, 0x74, 0x65, 0x64, 0x18, 0x02, 0x20, 0x01, 0x28, 0x0b,
	0x32, 0x1a, 0x2e, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2e, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x62,
	0x75, 0x66, 0x2e, 0x54, 0x69, 0x6d, 0x65, 0x73, 0x74, 0x61, 0x6d, 0x70, 0x52, 0x07, 0x63, 0x72,
	0x65, 0x61, 0x74, 0x65, 0x64, 0x12, 0x17, 0x0a, 0x07, 0x75, 0x73, 0x65, 0x72, 0x5f, 0x69, 0x64,
	0x18, 0x03, 0x20, 0x01, 0x28, 0x03, 0x52, 0x06, 0x75, 0x73, 0x65, 0x72, 0x49, 0x64, 0x12, 0x21,
	0x0a, 0x0c, 0x73, 0x65, 0x73, 0x73, 0x69, 0x6f, 0x6e, 0x5f, 0x64, 0x61, 0x74, 0x61, 0x18, 0x04,
	0x20, 0x01, 0x28, 0x0c, 0x52, 0x0b, 0x73, 0x65, 0x73, 0x73, 0x69, 0x6f, 0x6e, 0x44, 0x61, 0x74,
	0x61, 0x12, 0x1b, 0x0a, 0x09, 0x63, 0x72, 0x65, 0x64, 0x5f, 0x6e, 0x61, 0x6d, 0x65, 0x18, 0x05,
	0x20, 0x01, 0x28, 0x09, 0x52, 0x08, 0x63, 0x72, 0x65, 0x64, 0x4e, 0x61, 0x6d, 0x65, 0x22, 0x70,
	0x0a, 0x08, 0x55, 0x73, 0x65, 0x72, 0x49, 0x6e, 0x66, 0x6f, 0x12, 0x17, 0x0a, 0x07, 0x75, 0x73,
	0x65, 0x72, 0x5f, 0x69, 0x64, 0x18, 0x01, 0x20, 0x01, 0x28, 0x03, 0x52, 0x06, 0x75, 0x73, 0x65,
	0x72, 0x49, 0x64, 0x12, 0x1a, 0x0a, 0x08, 0x75, 0x73, 0x65, 0x72, 0x6e, 0x61, 0x6d, 0x65, 0x18,
	0x02, 0x20, 0x01, 0x28, 0x09, 0x52, 0x08, 0x75, 0x73, 0x65, 0x72, 0x6e, 0x61, 0x6d, 0x65, 0x12,
	0x29, 0x0a, 0x05, 0x63, 0x72, 0x65, 0x64, 0x73, 0x18, 0x04, 0x20, 0x03, 0x28, 0x0b, 0x32, 0x13,
	0x2e, 0x61, 0x75, 0x74, 0x68, 0x2e, 0x76, 0x31, 0x2e, 0x43, 0x72, 0x65, 0x64, 0x65, 0x6e, 0x74,
	0x69, 0x61, 0x6c, 0x52, 0x05, 0x63, 0x72, 0x65, 0x64, 0x73, 0x4a, 0x04, 0x08, 0x03, 0x10, 0x04,
	0x22, 0x34, 0x0a, 0x0a, 0x43, 0x72, 0x65, 0x64, 0x65, 0x6e, 0x74, 0x69, 0x61, 0x6c, 0x12, 0x12,
	0x0a, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x18, 0x01, 0x20, 0x01, 0x28, 0x09, 0x52, 0x04, 0x6e, 0x61,
	0x6d, 0x65, 0x12, 0x12, 0x0a, 0x04, 0x63, 0x72, 0x65, 0x64, 0x18, 0x02, 0x20, 0x01, 0x28, 0x0c,
	0x52, 0x04, 0x63, 0x72, 0x65, 0x64, 0x42, 0x7d, 0x0a, 0x0b, 0x63, 0x6f, 0x6d, 0x2e, 0x61, 0x75,
	0x74, 0x68, 0x2e, 0x76, 0x31, 0x42, 0x0a, 0x53, 0x74, 0x6f, 0x72, 0x65, 0x50, 0x72, 0x6f, 0x74,
	0x6f, 0x50, 0x01, 0x5a, 0x25, 0x67, 0x6f, 0x2e, 0x73, 0x65, 0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69,
	0x61, 0x6f, 0x2e, 0x63, 0x6f, 0x6d, 0x2f, 0x6d, 0x6f, 0x6e, 0x6f, 0x2f, 0x61, 0x75, 0x74, 0x68,
	0x2f, 0x76, 0x31, 0x3b, 0x61, 0x75, 0x74, 0x68, 0x76, 0x31, 0xa2, 0x02, 0x03, 0x41, 0x58, 0x58,
	0xaa, 0x02, 0x07, 0x41, 0x75, 0x74, 0x68, 0x2e, 0x56, 0x31, 0xca, 0x02, 0x07, 0x41, 0x75, 0x74,
	0x68, 0x5c, 0x56, 0x31, 0xe2, 0x02, 0x13, 0x41, 0x75, 0x74, 0x68, 0x5c, 0x56, 0x31, 0x5c, 0x47,
	0x50, 0x42, 0x4d, 0x65, 0x74, 0x61, 0x64, 0x61, 0x74, 0x61, 0xea, 0x02, 0x08, 0x41, 0x75, 0x74,
	0x68, 0x3a, 0x3a, 0x56, 0x31, 0x62, 0x08, 0x65, 0x64, 0x69, 0x74, 0x69, 0x6f, 0x6e, 0x73, 0x70,
	0xe8, 0x07,
})

var file_auth_v1_store_proto_msgTypes = make([]protoimpl.MessageInfo, 6)
var file_auth_v1_store_proto_goTypes = []any{
	(*Store)(nil),                 // 0: auth.v1.Store
	(*TokenInfo)(nil),             // 1: auth.v1.TokenInfo
	(*UserInfo)(nil),              // 2: auth.v1.UserInfo
	(*Credential)(nil),            // 3: auth.v1.Credential
	nil,                           // 4: auth.v1.Store.SessionsEntry
	nil,                           // 5: auth.v1.Store.UsersEntry
	(*timestamppb.Timestamp)(nil), // 6: google.protobuf.Timestamp
}
var file_auth_v1_store_proto_depIdxs = []int32{
	4, // 0: auth.v1.Store.sessions:type_name -> auth.v1.Store.SessionsEntry
	5, // 1: auth.v1.Store.users:type_name -> auth.v1.Store.UsersEntry
	6, // 2: auth.v1.TokenInfo.created:type_name -> google.protobuf.Timestamp
	3, // 3: auth.v1.UserInfo.creds:type_name -> auth.v1.Credential
	1, // 4: auth.v1.Store.SessionsEntry.value:type_name -> auth.v1.TokenInfo
	2, // 5: auth.v1.Store.UsersEntry.value:type_name -> auth.v1.UserInfo
	6, // [6:6] is the sub-list for method output_type
	6, // [6:6] is the sub-list for method input_type
	6, // [6:6] is the sub-list for extension type_name
	6, // [6:6] is the sub-list for extension extendee
	0, // [0:6] is the sub-list for field type_name
}

func init() { file_auth_v1_store_proto_init() }
func file_auth_v1_store_proto_init() {
	if File_auth_v1_store_proto != nil {
		return
	}
	type x struct{}
	out := protoimpl.TypeBuilder{
		File: protoimpl.DescBuilder{
			GoPackagePath: reflect.TypeOf(x{}).PkgPath(),
			RawDescriptor: unsafe.Slice(unsafe.StringData(file_auth_v1_store_proto_rawDesc), len(file_auth_v1_store_proto_rawDesc)),
			NumEnums:      0,
			NumMessages:   6,
			NumExtensions: 0,
			NumServices:   0,
		},
		GoTypes:           file_auth_v1_store_proto_goTypes,
		DependencyIndexes: file_auth_v1_store_proto_depIdxs,
		MessageInfos:      file_auth_v1_store_proto_msgTypes,
	}.Build()
	File_auth_v1_store_proto = out.File
	file_auth_v1_store_proto_goTypes = nil
	file_auth_v1_store_proto_depIdxs = nil
}
