// Code generated by protoc-gen-go. DO NOT EDIT.
// versions:
// 	protoc-gen-go v1.36.4
// 	protoc        (unknown)
// source: earbug/v5/store.proto

package earbugv5

import (
	protoreflect "google.golang.org/protobuf/reflect/protoreflect"
	protoimpl "google.golang.org/protobuf/runtime/protoimpl"
	durationpb "google.golang.org/protobuf/types/known/durationpb"
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
	state             protoimpl.MessageState `protogen:"opaque.v1"`
	xxx_hidden_Tracks map[string]*Track      `protobuf:"bytes,4,rep,name=tracks" protobuf_key:"bytes,1,opt,name=key" protobuf_val:"bytes,2,opt,name=value"`
	xxx_hidden_Users  map[int64]*UserData    `protobuf:"bytes,8,rep,name=users" protobuf_key:"varint,1,opt,name=key" protobuf_val:"bytes,2,opt,name=value"`
	unknownFields     protoimpl.UnknownFields
	sizeCache         protoimpl.SizeCache
}

func (x *Store) Reset() {
	*x = Store{}
	mi := &file_earbug_v5_store_proto_msgTypes[0]
	ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
	ms.StoreMessageInfo(mi)
}

func (x *Store) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*Store) ProtoMessage() {}

func (x *Store) ProtoReflect() protoreflect.Message {
	mi := &file_earbug_v5_store_proto_msgTypes[0]
	if x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

func (x *Store) GetTracks() map[string]*Track {
	if x != nil {
		return x.xxx_hidden_Tracks
	}
	return nil
}

func (x *Store) GetUsers() map[int64]*UserData {
	if x != nil {
		return x.xxx_hidden_Users
	}
	return nil
}

func (x *Store) SetTracks(v map[string]*Track) {
	x.xxx_hidden_Tracks = v
}

func (x *Store) SetUsers(v map[int64]*UserData) {
	x.xxx_hidden_Users = v
}

type Store_builder struct {
	_ [0]func() // Prevents comparability and use of unkeyed literals for the builder.

	// track id : track
	Tracks map[string]*Track
	Users  map[int64]*UserData
}

func (b0 Store_builder) Build() *Store {
	m0 := &Store{}
	b, x := &b0, m0
	_, _ = b, x
	x.xxx_hidden_Tracks = b.Tracks
	x.xxx_hidden_Users = b.Users
	return m0
}

type UserData struct {
	state                  protoimpl.MessageState `protogen:"opaque.v1"`
	xxx_hidden_Token       []byte                 `protobuf:"bytes,1,opt,name=token"`
	xxx_hidden_Playbacks   map[string]*Playback   `protobuf:"bytes,2,rep,name=playbacks" protobuf_key:"bytes,1,opt,name=key" protobuf_val:"bytes,2,opt,name=value"`
	XXX_raceDetectHookData protoimpl.RaceDetectHookData
	XXX_presence           [1]uint32
	unknownFields          protoimpl.UnknownFields
	sizeCache              protoimpl.SizeCache
}

func (x *UserData) Reset() {
	*x = UserData{}
	mi := &file_earbug_v5_store_proto_msgTypes[1]
	ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
	ms.StoreMessageInfo(mi)
}

func (x *UserData) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*UserData) ProtoMessage() {}

func (x *UserData) ProtoReflect() protoreflect.Message {
	mi := &file_earbug_v5_store_proto_msgTypes[1]
	if x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

func (x *UserData) GetToken() []byte {
	if x != nil {
		return x.xxx_hidden_Token
	}
	return nil
}

func (x *UserData) GetPlaybacks() map[string]*Playback {
	if x != nil {
		return x.xxx_hidden_Playbacks
	}
	return nil
}

func (x *UserData) SetToken(v []byte) {
	if v == nil {
		v = []byte{}
	}
	x.xxx_hidden_Token = v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 0, 2)
}

func (x *UserData) SetPlaybacks(v map[string]*Playback) {
	x.xxx_hidden_Playbacks = v
}

func (x *UserData) HasToken() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 0)
}

func (x *UserData) ClearToken() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 0)
	x.xxx_hidden_Token = nil
}

type UserData_builder struct {
	_ [0]func() // Prevents comparability and use of unkeyed literals for the builder.

	Token []byte
	// rfc3339 timestamp : playback
	Playbacks map[string]*Playback
}

func (b0 UserData_builder) Build() *UserData {
	m0 := &UserData{}
	b, x := &b0, m0
	_, _ = b, x
	if b.Token != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 0, 2)
		x.xxx_hidden_Token = b.Token
	}
	x.xxx_hidden_Playbacks = b.Playbacks
	return m0
}

type Playback struct {
	state                  protoimpl.MessageState `protogen:"opaque.v1"`
	xxx_hidden_TrackId     *string                `protobuf:"bytes,1,opt,name=track_id,json=trackId"`
	xxx_hidden_TrackUri    *string                `protobuf:"bytes,2,opt,name=track_uri,json=trackUri"`
	xxx_hidden_ContextType *string                `protobuf:"bytes,3,opt,name=context_type,json=contextType"`
	xxx_hidden_ContextUri  *string                `protobuf:"bytes,4,opt,name=context_uri,json=contextUri"`
	XXX_raceDetectHookData protoimpl.RaceDetectHookData
	XXX_presence           [1]uint32
	unknownFields          protoimpl.UnknownFields
	sizeCache              protoimpl.SizeCache
}

func (x *Playback) Reset() {
	*x = Playback{}
	mi := &file_earbug_v5_store_proto_msgTypes[2]
	ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
	ms.StoreMessageInfo(mi)
}

func (x *Playback) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*Playback) ProtoMessage() {}

func (x *Playback) ProtoReflect() protoreflect.Message {
	mi := &file_earbug_v5_store_proto_msgTypes[2]
	if x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

func (x *Playback) GetTrackId() string {
	if x != nil {
		if x.xxx_hidden_TrackId != nil {
			return *x.xxx_hidden_TrackId
		}
		return ""
	}
	return ""
}

func (x *Playback) GetTrackUri() string {
	if x != nil {
		if x.xxx_hidden_TrackUri != nil {
			return *x.xxx_hidden_TrackUri
		}
		return ""
	}
	return ""
}

func (x *Playback) GetContextType() string {
	if x != nil {
		if x.xxx_hidden_ContextType != nil {
			return *x.xxx_hidden_ContextType
		}
		return ""
	}
	return ""
}

func (x *Playback) GetContextUri() string {
	if x != nil {
		if x.xxx_hidden_ContextUri != nil {
			return *x.xxx_hidden_ContextUri
		}
		return ""
	}
	return ""
}

func (x *Playback) SetTrackId(v string) {
	x.xxx_hidden_TrackId = &v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 0, 4)
}

func (x *Playback) SetTrackUri(v string) {
	x.xxx_hidden_TrackUri = &v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 1, 4)
}

func (x *Playback) SetContextType(v string) {
	x.xxx_hidden_ContextType = &v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 2, 4)
}

func (x *Playback) SetContextUri(v string) {
	x.xxx_hidden_ContextUri = &v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 3, 4)
}

func (x *Playback) HasTrackId() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 0)
}

func (x *Playback) HasTrackUri() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 1)
}

func (x *Playback) HasContextType() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 2)
}

func (x *Playback) HasContextUri() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 3)
}

func (x *Playback) ClearTrackId() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 0)
	x.xxx_hidden_TrackId = nil
}

func (x *Playback) ClearTrackUri() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 1)
	x.xxx_hidden_TrackUri = nil
}

func (x *Playback) ClearContextType() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 2)
	x.xxx_hidden_ContextType = nil
}

func (x *Playback) ClearContextUri() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 3)
	x.xxx_hidden_ContextUri = nil
}

type Playback_builder struct {
	_ [0]func() // Prevents comparability and use of unkeyed literals for the builder.

	TrackId     *string
	TrackUri    *string
	ContextType *string
	ContextUri  *string
}

func (b0 Playback_builder) Build() *Playback {
	m0 := &Playback{}
	b, x := &b0, m0
	_, _ = b, x
	if b.TrackId != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 0, 4)
		x.xxx_hidden_TrackId = b.TrackId
	}
	if b.TrackUri != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 1, 4)
		x.xxx_hidden_TrackUri = b.TrackUri
	}
	if b.ContextType != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 2, 4)
		x.xxx_hidden_ContextType = b.ContextType
	}
	if b.ContextUri != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 3, 4)
		x.xxx_hidden_ContextUri = b.ContextUri
	}
	return m0
}

type Track struct {
	state                  protoimpl.MessageState `protogen:"opaque.v1"`
	xxx_hidden_Id          *string                `protobuf:"bytes,1,opt,name=id"`
	xxx_hidden_Uri         *string                `protobuf:"bytes,2,opt,name=uri"`
	xxx_hidden_Type        *string                `protobuf:"bytes,3,opt,name=type"`
	xxx_hidden_Name        *string                `protobuf:"bytes,4,opt,name=name"`
	xxx_hidden_Duration    *durationpb.Duration   `protobuf:"bytes,5,opt,name=duration"`
	xxx_hidden_Artists     *[]*Artist             `protobuf:"bytes,6,rep,name=artists"`
	xxx_hidden_Features    *AudioFeatures         `protobuf:"bytes,7,opt,name=features"`
	XXX_raceDetectHookData protoimpl.RaceDetectHookData
	XXX_presence           [1]uint32
	unknownFields          protoimpl.UnknownFields
	sizeCache              protoimpl.SizeCache
}

func (x *Track) Reset() {
	*x = Track{}
	mi := &file_earbug_v5_store_proto_msgTypes[3]
	ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
	ms.StoreMessageInfo(mi)
}

func (x *Track) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*Track) ProtoMessage() {}

func (x *Track) ProtoReflect() protoreflect.Message {
	mi := &file_earbug_v5_store_proto_msgTypes[3]
	if x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

func (x *Track) GetId() string {
	if x != nil {
		if x.xxx_hidden_Id != nil {
			return *x.xxx_hidden_Id
		}
		return ""
	}
	return ""
}

func (x *Track) GetUri() string {
	if x != nil {
		if x.xxx_hidden_Uri != nil {
			return *x.xxx_hidden_Uri
		}
		return ""
	}
	return ""
}

func (x *Track) GetType() string {
	if x != nil {
		if x.xxx_hidden_Type != nil {
			return *x.xxx_hidden_Type
		}
		return ""
	}
	return ""
}

func (x *Track) GetName() string {
	if x != nil {
		if x.xxx_hidden_Name != nil {
			return *x.xxx_hidden_Name
		}
		return ""
	}
	return ""
}

func (x *Track) GetDuration() *durationpb.Duration {
	if x != nil {
		return x.xxx_hidden_Duration
	}
	return nil
}

func (x *Track) GetArtists() []*Artist {
	if x != nil {
		if x.xxx_hidden_Artists != nil {
			return *x.xxx_hidden_Artists
		}
	}
	return nil
}

func (x *Track) GetFeatures() *AudioFeatures {
	if x != nil {
		return x.xxx_hidden_Features
	}
	return nil
}

func (x *Track) SetId(v string) {
	x.xxx_hidden_Id = &v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 0, 7)
}

func (x *Track) SetUri(v string) {
	x.xxx_hidden_Uri = &v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 1, 7)
}

func (x *Track) SetType(v string) {
	x.xxx_hidden_Type = &v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 2, 7)
}

func (x *Track) SetName(v string) {
	x.xxx_hidden_Name = &v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 3, 7)
}

func (x *Track) SetDuration(v *durationpb.Duration) {
	x.xxx_hidden_Duration = v
}

func (x *Track) SetArtists(v []*Artist) {
	x.xxx_hidden_Artists = &v
}

func (x *Track) SetFeatures(v *AudioFeatures) {
	x.xxx_hidden_Features = v
}

func (x *Track) HasId() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 0)
}

func (x *Track) HasUri() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 1)
}

func (x *Track) HasType() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 2)
}

func (x *Track) HasName() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 3)
}

func (x *Track) HasDuration() bool {
	if x == nil {
		return false
	}
	return x.xxx_hidden_Duration != nil
}

func (x *Track) HasFeatures() bool {
	if x == nil {
		return false
	}
	return x.xxx_hidden_Features != nil
}

func (x *Track) ClearId() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 0)
	x.xxx_hidden_Id = nil
}

func (x *Track) ClearUri() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 1)
	x.xxx_hidden_Uri = nil
}

func (x *Track) ClearType() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 2)
	x.xxx_hidden_Type = nil
}

func (x *Track) ClearName() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 3)
	x.xxx_hidden_Name = nil
}

func (x *Track) ClearDuration() {
	x.xxx_hidden_Duration = nil
}

func (x *Track) ClearFeatures() {
	x.xxx_hidden_Features = nil
}

type Track_builder struct {
	_ [0]func() // Prevents comparability and use of unkeyed literals for the builder.

	Id       *string
	Uri      *string
	Type     *string
	Name     *string
	Duration *durationpb.Duration
	Artists  []*Artist
	// audio features backfill
	Features *AudioFeatures
}

func (b0 Track_builder) Build() *Track {
	m0 := &Track{}
	b, x := &b0, m0
	_, _ = b, x
	if b.Id != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 0, 7)
		x.xxx_hidden_Id = b.Id
	}
	if b.Uri != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 1, 7)
		x.xxx_hidden_Uri = b.Uri
	}
	if b.Type != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 2, 7)
		x.xxx_hidden_Type = b.Type
	}
	if b.Name != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 3, 7)
		x.xxx_hidden_Name = b.Name
	}
	x.xxx_hidden_Duration = b.Duration
	x.xxx_hidden_Artists = &b.Artists
	x.xxx_hidden_Features = b.Features
	return m0
}

// https://developer.spotify.com/documentation/web-api/reference/get-several-audio-features
type AudioFeatures struct {
	state                       protoimpl.MessageState `protogen:"opaque.v1"`
	xxx_hidden_Acousticness     float32                `protobuf:"fixed32,1,opt,name=acousticness"`
	xxx_hidden_Danceability     float32                `protobuf:"fixed32,2,opt,name=danceability"`
	xxx_hidden_Energy           float32                `protobuf:"fixed32,3,opt,name=energy"`
	xxx_hidden_Instrumentalness float32                `protobuf:"fixed32,4,opt,name=instrumentalness"`
	xxx_hidden_Key              int32                  `protobuf:"varint,5,opt,name=key"`
	xxx_hidden_Liveness         float32                `protobuf:"fixed32,6,opt,name=liveness"`
	xxx_hidden_Loudness         float32                `protobuf:"fixed32,7,opt,name=loudness"`
	xxx_hidden_Mode             int32                  `protobuf:"varint,8,opt,name=mode"`
	xxx_hidden_Speechiness      float32                `protobuf:"fixed32,9,opt,name=speechiness"`
	xxx_hidden_Tempo            float32                `protobuf:"fixed32,10,opt,name=tempo"`
	xxx_hidden_TimeSignature    int32                  `protobuf:"varint,11,opt,name=time_signature,json=timeSignature"`
	xxx_hidden_Valence          float32                `protobuf:"fixed32,12,opt,name=valence"`
	XXX_raceDetectHookData      protoimpl.RaceDetectHookData
	XXX_presence                [1]uint32
	unknownFields               protoimpl.UnknownFields
	sizeCache                   protoimpl.SizeCache
}

func (x *AudioFeatures) Reset() {
	*x = AudioFeatures{}
	mi := &file_earbug_v5_store_proto_msgTypes[4]
	ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
	ms.StoreMessageInfo(mi)
}

func (x *AudioFeatures) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*AudioFeatures) ProtoMessage() {}

func (x *AudioFeatures) ProtoReflect() protoreflect.Message {
	mi := &file_earbug_v5_store_proto_msgTypes[4]
	if x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

func (x *AudioFeatures) GetAcousticness() float32 {
	if x != nil {
		return x.xxx_hidden_Acousticness
	}
	return 0
}

func (x *AudioFeatures) GetDanceability() float32 {
	if x != nil {
		return x.xxx_hidden_Danceability
	}
	return 0
}

func (x *AudioFeatures) GetEnergy() float32 {
	if x != nil {
		return x.xxx_hidden_Energy
	}
	return 0
}

func (x *AudioFeatures) GetInstrumentalness() float32 {
	if x != nil {
		return x.xxx_hidden_Instrumentalness
	}
	return 0
}

func (x *AudioFeatures) GetKey() int32 {
	if x != nil {
		return x.xxx_hidden_Key
	}
	return 0
}

func (x *AudioFeatures) GetLiveness() float32 {
	if x != nil {
		return x.xxx_hidden_Liveness
	}
	return 0
}

func (x *AudioFeatures) GetLoudness() float32 {
	if x != nil {
		return x.xxx_hidden_Loudness
	}
	return 0
}

func (x *AudioFeatures) GetMode() int32 {
	if x != nil {
		return x.xxx_hidden_Mode
	}
	return 0
}

func (x *AudioFeatures) GetSpeechiness() float32 {
	if x != nil {
		return x.xxx_hidden_Speechiness
	}
	return 0
}

func (x *AudioFeatures) GetTempo() float32 {
	if x != nil {
		return x.xxx_hidden_Tempo
	}
	return 0
}

func (x *AudioFeatures) GetTimeSignature() int32 {
	if x != nil {
		return x.xxx_hidden_TimeSignature
	}
	return 0
}

func (x *AudioFeatures) GetValence() float32 {
	if x != nil {
		return x.xxx_hidden_Valence
	}
	return 0
}

func (x *AudioFeatures) SetAcousticness(v float32) {
	x.xxx_hidden_Acousticness = v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 0, 12)
}

func (x *AudioFeatures) SetDanceability(v float32) {
	x.xxx_hidden_Danceability = v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 1, 12)
}

func (x *AudioFeatures) SetEnergy(v float32) {
	x.xxx_hidden_Energy = v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 2, 12)
}

func (x *AudioFeatures) SetInstrumentalness(v float32) {
	x.xxx_hidden_Instrumentalness = v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 3, 12)
}

func (x *AudioFeatures) SetKey(v int32) {
	x.xxx_hidden_Key = v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 4, 12)
}

func (x *AudioFeatures) SetLiveness(v float32) {
	x.xxx_hidden_Liveness = v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 5, 12)
}

func (x *AudioFeatures) SetLoudness(v float32) {
	x.xxx_hidden_Loudness = v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 6, 12)
}

func (x *AudioFeatures) SetMode(v int32) {
	x.xxx_hidden_Mode = v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 7, 12)
}

func (x *AudioFeatures) SetSpeechiness(v float32) {
	x.xxx_hidden_Speechiness = v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 8, 12)
}

func (x *AudioFeatures) SetTempo(v float32) {
	x.xxx_hidden_Tempo = v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 9, 12)
}

func (x *AudioFeatures) SetTimeSignature(v int32) {
	x.xxx_hidden_TimeSignature = v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 10, 12)
}

func (x *AudioFeatures) SetValence(v float32) {
	x.xxx_hidden_Valence = v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 11, 12)
}

func (x *AudioFeatures) HasAcousticness() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 0)
}

func (x *AudioFeatures) HasDanceability() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 1)
}

func (x *AudioFeatures) HasEnergy() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 2)
}

func (x *AudioFeatures) HasInstrumentalness() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 3)
}

func (x *AudioFeatures) HasKey() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 4)
}

func (x *AudioFeatures) HasLiveness() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 5)
}

func (x *AudioFeatures) HasLoudness() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 6)
}

func (x *AudioFeatures) HasMode() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 7)
}

func (x *AudioFeatures) HasSpeechiness() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 8)
}

func (x *AudioFeatures) HasTempo() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 9)
}

func (x *AudioFeatures) HasTimeSignature() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 10)
}

func (x *AudioFeatures) HasValence() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 11)
}

func (x *AudioFeatures) ClearAcousticness() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 0)
	x.xxx_hidden_Acousticness = 0
}

func (x *AudioFeatures) ClearDanceability() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 1)
	x.xxx_hidden_Danceability = 0
}

func (x *AudioFeatures) ClearEnergy() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 2)
	x.xxx_hidden_Energy = 0
}

func (x *AudioFeatures) ClearInstrumentalness() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 3)
	x.xxx_hidden_Instrumentalness = 0
}

func (x *AudioFeatures) ClearKey() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 4)
	x.xxx_hidden_Key = 0
}

func (x *AudioFeatures) ClearLiveness() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 5)
	x.xxx_hidden_Liveness = 0
}

func (x *AudioFeatures) ClearLoudness() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 6)
	x.xxx_hidden_Loudness = 0
}

func (x *AudioFeatures) ClearMode() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 7)
	x.xxx_hidden_Mode = 0
}

func (x *AudioFeatures) ClearSpeechiness() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 8)
	x.xxx_hidden_Speechiness = 0
}

func (x *AudioFeatures) ClearTempo() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 9)
	x.xxx_hidden_Tempo = 0
}

func (x *AudioFeatures) ClearTimeSignature() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 10)
	x.xxx_hidden_TimeSignature = 0
}

func (x *AudioFeatures) ClearValence() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 11)
	x.xxx_hidden_Valence = 0
}

type AudioFeatures_builder struct {
	_ [0]func() // Prevents comparability and use of unkeyed literals for the builder.

	Acousticness     *float32
	Danceability     *float32
	Energy           *float32
	Instrumentalness *float32
	Key              *int32
	Liveness         *float32
	Loudness         *float32
	Mode             *int32
	Speechiness      *float32
	Tempo            *float32
	TimeSignature    *int32
	Valence          *float32
}

func (b0 AudioFeatures_builder) Build() *AudioFeatures {
	m0 := &AudioFeatures{}
	b, x := &b0, m0
	_, _ = b, x
	if b.Acousticness != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 0, 12)
		x.xxx_hidden_Acousticness = *b.Acousticness
	}
	if b.Danceability != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 1, 12)
		x.xxx_hidden_Danceability = *b.Danceability
	}
	if b.Energy != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 2, 12)
		x.xxx_hidden_Energy = *b.Energy
	}
	if b.Instrumentalness != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 3, 12)
		x.xxx_hidden_Instrumentalness = *b.Instrumentalness
	}
	if b.Key != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 4, 12)
		x.xxx_hidden_Key = *b.Key
	}
	if b.Liveness != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 5, 12)
		x.xxx_hidden_Liveness = *b.Liveness
	}
	if b.Loudness != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 6, 12)
		x.xxx_hidden_Loudness = *b.Loudness
	}
	if b.Mode != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 7, 12)
		x.xxx_hidden_Mode = *b.Mode
	}
	if b.Speechiness != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 8, 12)
		x.xxx_hidden_Speechiness = *b.Speechiness
	}
	if b.Tempo != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 9, 12)
		x.xxx_hidden_Tempo = *b.Tempo
	}
	if b.TimeSignature != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 10, 12)
		x.xxx_hidden_TimeSignature = *b.TimeSignature
	}
	if b.Valence != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 11, 12)
		x.xxx_hidden_Valence = *b.Valence
	}
	return m0
}

type Artist struct {
	state                  protoimpl.MessageState `protogen:"opaque.v1"`
	xxx_hidden_Id          *string                `protobuf:"bytes,1,opt,name=id"`
	xxx_hidden_Uri         *string                `protobuf:"bytes,2,opt,name=uri"`
	xxx_hidden_Name        *string                `protobuf:"bytes,3,opt,name=name"`
	XXX_raceDetectHookData protoimpl.RaceDetectHookData
	XXX_presence           [1]uint32
	unknownFields          protoimpl.UnknownFields
	sizeCache              protoimpl.SizeCache
}

func (x *Artist) Reset() {
	*x = Artist{}
	mi := &file_earbug_v5_store_proto_msgTypes[5]
	ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
	ms.StoreMessageInfo(mi)
}

func (x *Artist) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*Artist) ProtoMessage() {}

func (x *Artist) ProtoReflect() protoreflect.Message {
	mi := &file_earbug_v5_store_proto_msgTypes[5]
	if x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

func (x *Artist) GetId() string {
	if x != nil {
		if x.xxx_hidden_Id != nil {
			return *x.xxx_hidden_Id
		}
		return ""
	}
	return ""
}

func (x *Artist) GetUri() string {
	if x != nil {
		if x.xxx_hidden_Uri != nil {
			return *x.xxx_hidden_Uri
		}
		return ""
	}
	return ""
}

func (x *Artist) GetName() string {
	if x != nil {
		if x.xxx_hidden_Name != nil {
			return *x.xxx_hidden_Name
		}
		return ""
	}
	return ""
}

func (x *Artist) SetId(v string) {
	x.xxx_hidden_Id = &v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 0, 3)
}

func (x *Artist) SetUri(v string) {
	x.xxx_hidden_Uri = &v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 1, 3)
}

func (x *Artist) SetName(v string) {
	x.xxx_hidden_Name = &v
	protoimpl.X.SetPresent(&(x.XXX_presence[0]), 2, 3)
}

func (x *Artist) HasId() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 0)
}

func (x *Artist) HasUri() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 1)
}

func (x *Artist) HasName() bool {
	if x == nil {
		return false
	}
	return protoimpl.X.Present(&(x.XXX_presence[0]), 2)
}

func (x *Artist) ClearId() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 0)
	x.xxx_hidden_Id = nil
}

func (x *Artist) ClearUri() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 1)
	x.xxx_hidden_Uri = nil
}

func (x *Artist) ClearName() {
	protoimpl.X.ClearPresent(&(x.XXX_presence[0]), 2)
	x.xxx_hidden_Name = nil
}

type Artist_builder struct {
	_ [0]func() // Prevents comparability and use of unkeyed literals for the builder.

	Id   *string
	Uri  *string
	Name *string
}

func (b0 Artist_builder) Build() *Artist {
	m0 := &Artist{}
	b, x := &b0, m0
	_, _ = b, x
	if b.Id != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 0, 3)
		x.xxx_hidden_Id = b.Id
	}
	if b.Uri != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 1, 3)
		x.xxx_hidden_Uri = b.Uri
	}
	if b.Name != nil {
		protoimpl.X.SetPresentNonAtomic(&(x.XXX_presence[0]), 2, 3)
		x.xxx_hidden_Name = b.Name
	}
	return m0
}

var File_earbug_v5_store_proto protoreflect.FileDescriptor

var file_earbug_v5_store_proto_rawDesc = string([]byte{
	0x0a, 0x15, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x2f, 0x76, 0x35, 0x2f, 0x73, 0x74, 0x6f, 0x72,
	0x65, 0x2e, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x12, 0x09, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x2e,
	0x76, 0x35, 0x1a, 0x1e, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2f, 0x70, 0x72, 0x6f, 0x74, 0x6f,
	0x62, 0x75, 0x66, 0x2f, 0x64, 0x75, 0x72, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x2e, 0x70, 0x72, 0x6f,
	0x74, 0x6f, 0x22, 0xb0, 0x02, 0x0a, 0x05, 0x53, 0x74, 0x6f, 0x72, 0x65, 0x12, 0x34, 0x0a, 0x06,
	0x74, 0x72, 0x61, 0x63, 0x6b, 0x73, 0x18, 0x04, 0x20, 0x03, 0x28, 0x0b, 0x32, 0x1c, 0x2e, 0x65,
	0x61, 0x72, 0x62, 0x75, 0x67, 0x2e, 0x76, 0x35, 0x2e, 0x53, 0x74, 0x6f, 0x72, 0x65, 0x2e, 0x54,
	0x72, 0x61, 0x63, 0x6b, 0x73, 0x45, 0x6e, 0x74, 0x72, 0x79, 0x52, 0x06, 0x74, 0x72, 0x61, 0x63,
	0x6b, 0x73, 0x12, 0x31, 0x0a, 0x05, 0x75, 0x73, 0x65, 0x72, 0x73, 0x18, 0x08, 0x20, 0x03, 0x28,
	0x0b, 0x32, 0x1b, 0x2e, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x2e, 0x76, 0x35, 0x2e, 0x53, 0x74,
	0x6f, 0x72, 0x65, 0x2e, 0x55, 0x73, 0x65, 0x72, 0x73, 0x45, 0x6e, 0x74, 0x72, 0x79, 0x52, 0x05,
	0x75, 0x73, 0x65, 0x72, 0x73, 0x1a, 0x4b, 0x0a, 0x0b, 0x54, 0x72, 0x61, 0x63, 0x6b, 0x73, 0x45,
	0x6e, 0x74, 0x72, 0x79, 0x12, 0x10, 0x0a, 0x03, 0x6b, 0x65, 0x79, 0x18, 0x01, 0x20, 0x01, 0x28,
	0x09, 0x52, 0x03, 0x6b, 0x65, 0x79, 0x12, 0x26, 0x0a, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x18,
	0x02, 0x20, 0x01, 0x28, 0x0b, 0x32, 0x10, 0x2e, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x2e, 0x76,
	0x35, 0x2e, 0x54, 0x72, 0x61, 0x63, 0x6b, 0x52, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x3a, 0x02,
	0x38, 0x01, 0x1a, 0x4d, 0x0a, 0x0a, 0x55, 0x73, 0x65, 0x72, 0x73, 0x45, 0x6e, 0x74, 0x72, 0x79,
	0x12, 0x10, 0x0a, 0x03, 0x6b, 0x65, 0x79, 0x18, 0x01, 0x20, 0x01, 0x28, 0x03, 0x52, 0x03, 0x6b,
	0x65, 0x79, 0x12, 0x29, 0x0a, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x18, 0x02, 0x20, 0x01, 0x28,
	0x0b, 0x32, 0x13, 0x2e, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x2e, 0x76, 0x35, 0x2e, 0x55, 0x73,
	0x65, 0x72, 0x44, 0x61, 0x74, 0x61, 0x52, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x3a, 0x02, 0x38,
	0x01, 0x4a, 0x04, 0x08, 0x01, 0x10, 0x02, 0x4a, 0x04, 0x08, 0x02, 0x10, 0x03, 0x4a, 0x04, 0x08,
	0x03, 0x10, 0x04, 0x4a, 0x04, 0x08, 0x05, 0x10, 0x06, 0x4a, 0x04, 0x08, 0x06, 0x10, 0x07, 0x4a,
	0x04, 0x08, 0x07, 0x10, 0x08, 0x22, 0xb5, 0x01, 0x0a, 0x08, 0x55, 0x73, 0x65, 0x72, 0x44, 0x61,
	0x74, 0x61, 0x12, 0x14, 0x0a, 0x05, 0x74, 0x6f, 0x6b, 0x65, 0x6e, 0x18, 0x01, 0x20, 0x01, 0x28,
	0x0c, 0x52, 0x05, 0x74, 0x6f, 0x6b, 0x65, 0x6e, 0x12, 0x40, 0x0a, 0x09, 0x70, 0x6c, 0x61, 0x79,
	0x62, 0x61, 0x63, 0x6b, 0x73, 0x18, 0x02, 0x20, 0x03, 0x28, 0x0b, 0x32, 0x22, 0x2e, 0x65, 0x61,
	0x72, 0x62, 0x75, 0x67, 0x2e, 0x76, 0x35, 0x2e, 0x55, 0x73, 0x65, 0x72, 0x44, 0x61, 0x74, 0x61,
	0x2e, 0x50, 0x6c, 0x61, 0x79, 0x62, 0x61, 0x63, 0x6b, 0x73, 0x45, 0x6e, 0x74, 0x72, 0x79, 0x52,
	0x09, 0x70, 0x6c, 0x61, 0x79, 0x62, 0x61, 0x63, 0x6b, 0x73, 0x1a, 0x51, 0x0a, 0x0e, 0x50, 0x6c,
	0x61, 0x79, 0x62, 0x61, 0x63, 0x6b, 0x73, 0x45, 0x6e, 0x74, 0x72, 0x79, 0x12, 0x10, 0x0a, 0x03,
	0x6b, 0x65, 0x79, 0x18, 0x01, 0x20, 0x01, 0x28, 0x09, 0x52, 0x03, 0x6b, 0x65, 0x79, 0x12, 0x29,
	0x0a, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x18, 0x02, 0x20, 0x01, 0x28, 0x0b, 0x32, 0x13, 0x2e,
	0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x2e, 0x76, 0x35, 0x2e, 0x50, 0x6c, 0x61, 0x79, 0x62, 0x61,
	0x63, 0x6b, 0x52, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x3a, 0x02, 0x38, 0x01, 0x22, 0x86, 0x01,
	0x0a, 0x08, 0x50, 0x6c, 0x61, 0x79, 0x62, 0x61, 0x63, 0x6b, 0x12, 0x19, 0x0a, 0x08, 0x74, 0x72,
	0x61, 0x63, 0x6b, 0x5f, 0x69, 0x64, 0x18, 0x01, 0x20, 0x01, 0x28, 0x09, 0x52, 0x07, 0x74, 0x72,
	0x61, 0x63, 0x6b, 0x49, 0x64, 0x12, 0x1b, 0x0a, 0x09, 0x74, 0x72, 0x61, 0x63, 0x6b, 0x5f, 0x75,
	0x72, 0x69, 0x18, 0x02, 0x20, 0x01, 0x28, 0x09, 0x52, 0x08, 0x74, 0x72, 0x61, 0x63, 0x6b, 0x55,
	0x72, 0x69, 0x12, 0x21, 0x0a, 0x0c, 0x63, 0x6f, 0x6e, 0x74, 0x65, 0x78, 0x74, 0x5f, 0x74, 0x79,
	0x70, 0x65, 0x18, 0x03, 0x20, 0x01, 0x28, 0x09, 0x52, 0x0b, 0x63, 0x6f, 0x6e, 0x74, 0x65, 0x78,
	0x74, 0x54, 0x79, 0x70, 0x65, 0x12, 0x1f, 0x0a, 0x0b, 0x63, 0x6f, 0x6e, 0x74, 0x65, 0x78, 0x74,
	0x5f, 0x75, 0x72, 0x69, 0x18, 0x04, 0x20, 0x01, 0x28, 0x09, 0x52, 0x0a, 0x63, 0x6f, 0x6e, 0x74,
	0x65, 0x78, 0x74, 0x55, 0x72, 0x69, 0x22, 0xeb, 0x01, 0x0a, 0x05, 0x54, 0x72, 0x61, 0x63, 0x6b,
	0x12, 0x0e, 0x0a, 0x02, 0x69, 0x64, 0x18, 0x01, 0x20, 0x01, 0x28, 0x09, 0x52, 0x02, 0x69, 0x64,
	0x12, 0x10, 0x0a, 0x03, 0x75, 0x72, 0x69, 0x18, 0x02, 0x20, 0x01, 0x28, 0x09, 0x52, 0x03, 0x75,
	0x72, 0x69, 0x12, 0x12, 0x0a, 0x04, 0x74, 0x79, 0x70, 0x65, 0x18, 0x03, 0x20, 0x01, 0x28, 0x09,
	0x52, 0x04, 0x74, 0x79, 0x70, 0x65, 0x12, 0x12, 0x0a, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x18, 0x04,
	0x20, 0x01, 0x28, 0x09, 0x52, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x12, 0x35, 0x0a, 0x08, 0x64, 0x75,
	0x72, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x18, 0x05, 0x20, 0x01, 0x28, 0x0b, 0x32, 0x19, 0x2e, 0x67,
	0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2e, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x62, 0x75, 0x66, 0x2e, 0x44,
	0x75, 0x72, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x52, 0x08, 0x64, 0x75, 0x72, 0x61, 0x74, 0x69, 0x6f,
	0x6e, 0x12, 0x2b, 0x0a, 0x07, 0x61, 0x72, 0x74, 0x69, 0x73, 0x74, 0x73, 0x18, 0x06, 0x20, 0x03,
	0x28, 0x0b, 0x32, 0x11, 0x2e, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x2e, 0x76, 0x35, 0x2e, 0x41,
	0x72, 0x74, 0x69, 0x73, 0x74, 0x52, 0x07, 0x61, 0x72, 0x74, 0x69, 0x73, 0x74, 0x73, 0x12, 0x34,
	0x0a, 0x08, 0x66, 0x65, 0x61, 0x74, 0x75, 0x72, 0x65, 0x73, 0x18, 0x07, 0x20, 0x01, 0x28, 0x0b,
	0x32, 0x18, 0x2e, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x2e, 0x76, 0x35, 0x2e, 0x41, 0x75, 0x64,
	0x69, 0x6f, 0x46, 0x65, 0x61, 0x74, 0x75, 0x72, 0x65, 0x73, 0x52, 0x08, 0x66, 0x65, 0x61, 0x74,
	0x75, 0x72, 0x65, 0x73, 0x22, 0xf2, 0x02, 0x0a, 0x0d, 0x41, 0x75, 0x64, 0x69, 0x6f, 0x46, 0x65,
	0x61, 0x74, 0x75, 0x72, 0x65, 0x73, 0x12, 0x22, 0x0a, 0x0c, 0x61, 0x63, 0x6f, 0x75, 0x73, 0x74,
	0x69, 0x63, 0x6e, 0x65, 0x73, 0x73, 0x18, 0x01, 0x20, 0x01, 0x28, 0x02, 0x52, 0x0c, 0x61, 0x63,
	0x6f, 0x75, 0x73, 0x74, 0x69, 0x63, 0x6e, 0x65, 0x73, 0x73, 0x12, 0x22, 0x0a, 0x0c, 0x64, 0x61,
	0x6e, 0x63, 0x65, 0x61, 0x62, 0x69, 0x6c, 0x69, 0x74, 0x79, 0x18, 0x02, 0x20, 0x01, 0x28, 0x02,
	0x52, 0x0c, 0x64, 0x61, 0x6e, 0x63, 0x65, 0x61, 0x62, 0x69, 0x6c, 0x69, 0x74, 0x79, 0x12, 0x16,
	0x0a, 0x06, 0x65, 0x6e, 0x65, 0x72, 0x67, 0x79, 0x18, 0x03, 0x20, 0x01, 0x28, 0x02, 0x52, 0x06,
	0x65, 0x6e, 0x65, 0x72, 0x67, 0x79, 0x12, 0x2a, 0x0a, 0x10, 0x69, 0x6e, 0x73, 0x74, 0x72, 0x75,
	0x6d, 0x65, 0x6e, 0x74, 0x61, 0x6c, 0x6e, 0x65, 0x73, 0x73, 0x18, 0x04, 0x20, 0x01, 0x28, 0x02,
	0x52, 0x10, 0x69, 0x6e, 0x73, 0x74, 0x72, 0x75, 0x6d, 0x65, 0x6e, 0x74, 0x61, 0x6c, 0x6e, 0x65,
	0x73, 0x73, 0x12, 0x10, 0x0a, 0x03, 0x6b, 0x65, 0x79, 0x18, 0x05, 0x20, 0x01, 0x28, 0x05, 0x52,
	0x03, 0x6b, 0x65, 0x79, 0x12, 0x1a, 0x0a, 0x08, 0x6c, 0x69, 0x76, 0x65, 0x6e, 0x65, 0x73, 0x73,
	0x18, 0x06, 0x20, 0x01, 0x28, 0x02, 0x52, 0x08, 0x6c, 0x69, 0x76, 0x65, 0x6e, 0x65, 0x73, 0x73,
	0x12, 0x1a, 0x0a, 0x08, 0x6c, 0x6f, 0x75, 0x64, 0x6e, 0x65, 0x73, 0x73, 0x18, 0x07, 0x20, 0x01,
	0x28, 0x02, 0x52, 0x08, 0x6c, 0x6f, 0x75, 0x64, 0x6e, 0x65, 0x73, 0x73, 0x12, 0x12, 0x0a, 0x04,
	0x6d, 0x6f, 0x64, 0x65, 0x18, 0x08, 0x20, 0x01, 0x28, 0x05, 0x52, 0x04, 0x6d, 0x6f, 0x64, 0x65,
	0x12, 0x20, 0x0a, 0x0b, 0x73, 0x70, 0x65, 0x65, 0x63, 0x68, 0x69, 0x6e, 0x65, 0x73, 0x73, 0x18,
	0x09, 0x20, 0x01, 0x28, 0x02, 0x52, 0x0b, 0x73, 0x70, 0x65, 0x65, 0x63, 0x68, 0x69, 0x6e, 0x65,
	0x73, 0x73, 0x12, 0x14, 0x0a, 0x05, 0x74, 0x65, 0x6d, 0x70, 0x6f, 0x18, 0x0a, 0x20, 0x01, 0x28,
	0x02, 0x52, 0x05, 0x74, 0x65, 0x6d, 0x70, 0x6f, 0x12, 0x25, 0x0a, 0x0e, 0x74, 0x69, 0x6d, 0x65,
	0x5f, 0x73, 0x69, 0x67, 0x6e, 0x61, 0x74, 0x75, 0x72, 0x65, 0x18, 0x0b, 0x20, 0x01, 0x28, 0x05,
	0x52, 0x0d, 0x74, 0x69, 0x6d, 0x65, 0x53, 0x69, 0x67, 0x6e, 0x61, 0x74, 0x75, 0x72, 0x65, 0x12,
	0x18, 0x0a, 0x07, 0x76, 0x61, 0x6c, 0x65, 0x6e, 0x63, 0x65, 0x18, 0x0c, 0x20, 0x01, 0x28, 0x02,
	0x52, 0x07, 0x76, 0x61, 0x6c, 0x65, 0x6e, 0x63, 0x65, 0x22, 0x3e, 0x0a, 0x06, 0x41, 0x72, 0x74,
	0x69, 0x73, 0x74, 0x12, 0x0e, 0x0a, 0x02, 0x69, 0x64, 0x18, 0x01, 0x20, 0x01, 0x28, 0x09, 0x52,
	0x02, 0x69, 0x64, 0x12, 0x10, 0x0a, 0x03, 0x75, 0x72, 0x69, 0x18, 0x02, 0x20, 0x01, 0x28, 0x09,
	0x52, 0x03, 0x75, 0x72, 0x69, 0x12, 0x12, 0x0a, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x18, 0x03, 0x20,
	0x01, 0x28, 0x09, 0x52, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x42, 0x8b, 0x01, 0x0a, 0x0d, 0x63, 0x6f,
	0x6d, 0x2e, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x2e, 0x76, 0x35, 0x42, 0x0a, 0x53, 0x74, 0x6f,
	0x72, 0x65, 0x50, 0x72, 0x6f, 0x74, 0x6f, 0x50, 0x01, 0x5a, 0x29, 0x67, 0x6f, 0x2e, 0x73, 0x65,
	0x61, 0x6e, 0x6b, 0x68, 0x6c, 0x69, 0x61, 0x6f, 0x2e, 0x63, 0x6f, 0x6d, 0x2f, 0x6d, 0x6f, 0x6e,
	0x6f, 0x2f, 0x65, 0x61, 0x72, 0x62, 0x75, 0x67, 0x2f, 0x76, 0x35, 0x3b, 0x65, 0x61, 0x72, 0x62,
	0x75, 0x67, 0x76, 0x35, 0xa2, 0x02, 0x03, 0x45, 0x58, 0x58, 0xaa, 0x02, 0x09, 0x45, 0x61, 0x72,
	0x62, 0x75, 0x67, 0x2e, 0x56, 0x35, 0xca, 0x02, 0x09, 0x45, 0x61, 0x72, 0x62, 0x75, 0x67, 0x5c,
	0x56, 0x35, 0xe2, 0x02, 0x15, 0x45, 0x61, 0x72, 0x62, 0x75, 0x67, 0x5c, 0x56, 0x35, 0x5c, 0x47,
	0x50, 0x42, 0x4d, 0x65, 0x74, 0x61, 0x64, 0x61, 0x74, 0x61, 0xea, 0x02, 0x0a, 0x45, 0x61, 0x72,
	0x62, 0x75, 0x67, 0x3a, 0x3a, 0x56, 0x35, 0x62, 0x08, 0x65, 0x64, 0x69, 0x74, 0x69, 0x6f, 0x6e,
	0x73, 0x70, 0xe8, 0x07,
})

var file_earbug_v5_store_proto_msgTypes = make([]protoimpl.MessageInfo, 9)
var file_earbug_v5_store_proto_goTypes = []any{
	(*Store)(nil),               // 0: earbug.v5.Store
	(*UserData)(nil),            // 1: earbug.v5.UserData
	(*Playback)(nil),            // 2: earbug.v5.Playback
	(*Track)(nil),               // 3: earbug.v5.Track
	(*AudioFeatures)(nil),       // 4: earbug.v5.AudioFeatures
	(*Artist)(nil),              // 5: earbug.v5.Artist
	nil,                         // 6: earbug.v5.Store.TracksEntry
	nil,                         // 7: earbug.v5.Store.UsersEntry
	nil,                         // 8: earbug.v5.UserData.PlaybacksEntry
	(*durationpb.Duration)(nil), // 9: google.protobuf.Duration
}
var file_earbug_v5_store_proto_depIdxs = []int32{
	6, // 0: earbug.v5.Store.tracks:type_name -> earbug.v5.Store.TracksEntry
	7, // 1: earbug.v5.Store.users:type_name -> earbug.v5.Store.UsersEntry
	8, // 2: earbug.v5.UserData.playbacks:type_name -> earbug.v5.UserData.PlaybacksEntry
	9, // 3: earbug.v5.Track.duration:type_name -> google.protobuf.Duration
	5, // 4: earbug.v5.Track.artists:type_name -> earbug.v5.Artist
	4, // 5: earbug.v5.Track.features:type_name -> earbug.v5.AudioFeatures
	3, // 6: earbug.v5.Store.TracksEntry.value:type_name -> earbug.v5.Track
	1, // 7: earbug.v5.Store.UsersEntry.value:type_name -> earbug.v5.UserData
	2, // 8: earbug.v5.UserData.PlaybacksEntry.value:type_name -> earbug.v5.Playback
	9, // [9:9] is the sub-list for method output_type
	9, // [9:9] is the sub-list for method input_type
	9, // [9:9] is the sub-list for extension type_name
	9, // [9:9] is the sub-list for extension extendee
	0, // [0:9] is the sub-list for field type_name
}

func init() { file_earbug_v5_store_proto_init() }
func file_earbug_v5_store_proto_init() {
	if File_earbug_v5_store_proto != nil {
		return
	}
	type x struct{}
	out := protoimpl.TypeBuilder{
		File: protoimpl.DescBuilder{
			GoPackagePath: reflect.TypeOf(x{}).PkgPath(),
			RawDescriptor: unsafe.Slice(unsafe.StringData(file_earbug_v5_store_proto_rawDesc), len(file_earbug_v5_store_proto_rawDesc)),
			NumEnums:      0,
			NumMessages:   9,
			NumExtensions: 0,
			NumServices:   0,
		},
		GoTypes:           file_earbug_v5_store_proto_goTypes,
		DependencyIndexes: file_earbug_v5_store_proto_depIdxs,
		MessageInfos:      file_earbug_v5_store_proto_msgTypes,
	}.Build()
	File_earbug_v5_store_proto = out.File
	file_earbug_v5_store_proto_goTypes = nil
	file_earbug_v5_store_proto_depIdxs = nil
}
