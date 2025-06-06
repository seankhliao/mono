// Code generated by protoc-gen-go. DO NOT EDIT.
// versions:
// 	protoc-gen-go v1.36.6
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

const file_auth_v1_store_proto_rawDesc = "" +
	"\n" +
	"\x13auth/v1/store.proto\x12\aauth.v1\x1a\x1fgoogle/protobuf/timestamp.proto\"\x90\x02\n" +
	"\x05Store\x128\n" +
	"\bsessions\x18\x01 \x03(\v2\x1c.auth.v1.Store.SessionsEntryR\bsessions\x12/\n" +
	"\x05users\x18\x02 \x03(\v2\x19.auth.v1.Store.UsersEntryR\x05users\x1aO\n" +
	"\rSessionsEntry\x12\x10\n" +
	"\x03key\x18\x01 \x01(\tR\x03key\x12(\n" +
	"\x05value\x18\x02 \x01(\v2\x12.auth.v1.TokenInfoR\x05value:\x028\x01\x1aK\n" +
	"\n" +
	"UsersEntry\x12\x10\n" +
	"\x03key\x18\x01 \x01(\x03R\x03key\x12'\n" +
	"\x05value\x18\x02 \x01(\v2\x11.auth.v1.UserInfoR\x05value:\x028\x01\"\xb9\x01\n" +
	"\tTokenInfo\x12\x1d\n" +
	"\n" +
	"session_id\x18\x01 \x01(\tR\tsessionId\x124\n" +
	"\acreated\x18\x02 \x01(\v2\x1a.google.protobuf.TimestampR\acreated\x12\x17\n" +
	"\auser_id\x18\x03 \x01(\x03R\x06userId\x12!\n" +
	"\fsession_data\x18\x04 \x01(\fR\vsessionData\x12\x1b\n" +
	"\tcred_name\x18\x05 \x01(\tR\bcredName\"p\n" +
	"\bUserInfo\x12\x17\n" +
	"\auser_id\x18\x01 \x01(\x03R\x06userId\x12\x1a\n" +
	"\busername\x18\x02 \x01(\tR\busername\x12)\n" +
	"\x05creds\x18\x04 \x03(\v2\x13.auth.v1.CredentialR\x05credsJ\x04\b\x03\x10\x04\"4\n" +
	"\n" +
	"Credential\x12\x12\n" +
	"\x04name\x18\x01 \x01(\tR\x04name\x12\x12\n" +
	"\x04cred\x18\x02 \x01(\fR\x04credB}\n" +
	"\vcom.auth.v1B\n" +
	"StoreProtoP\x01Z%go.seankhliao.com/mono/auth/v1;authv1\xa2\x02\x03AXX\xaa\x02\aAuth.V1\xca\x02\aAuth\\V1\xe2\x02\x13Auth\\V1\\GPBMetadata\xea\x02\bAuth::V1b\beditionsp\xe8\a"

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
