package yenv

import (
	"encoding"
	"slices"
	"testing"
	"time"
)

var environ = []string{
	"TEST_P1=foobar",
	"TEST_P2=-1",
	"TEST_P3=-2",
	"TEST_P4=-3",
	"TEST_P5=-4",
	"TEST_P6=-5",
	"TEST_P7=true",
	"TEST_P8=6.7",
	"TEST_P9=8.9",
	"TEST_P10=10",
	"TEST_P11=11",
	"TEST_P12=12",
	"TEST_P13=13",
	"TEST_P14=14",
	"TEST_P15=frob",
	"TEST_P16_C1=helloworld",
	"TEST_P16_C2=42",
	"TEST_P16_C3=true",
	"TEST_P16_C4=frob2",
	"TEST_P16_C5=5h4m3s",
}

var want = testStruct{
	"foobar",
	-1,
	-2,
	-3,
	-4,
	-5,
	true,
	6.7,
	8.9,
	10,
	11,
	12,
	13,
	14,
	unmarshaler{"unmarshaler called"},
	childStruct{
		"helloworld",
		42,
		true,
		unmarshaler{"unmarshaler called"},
		5*time.Hour + 4*time.Minute + 3*time.Second,
	},
}

func TestFromEnv(t *testing.T) {
	got := new(testStruct)
	err := FromEnv(Map(environ), "TEST", got)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if *got != want {
		t.Errorf("got != want:\ngot: %+v\nwnt: %+v", *got, want)
	}
}

func TestPrint(t *testing.T) {
	got := Print("TEST", want)
	want := slices.Clone(environ)
	want[14] = "TEST_P15=marshaler called"
	want[18] = "TEST_P16_C4=marshaler called"
	if !slices.Equal(got, want) {
		t.Errorf("got != want:\ngot: %v\nwnt: %v", got, want)
	}
}

type childStruct struct {
	C1 string        `env:"C1"`
	C2 int           `env:"C2"`
	C3 bool          `env:"C3"`
	C4 unmarshaler   `env:"C4"`
	C5 time.Duration `env:"C5"`
}
type testStruct struct {
	P1  string      `env:"P1"`
	P2  int         `env:"P2"`
	P3  int8        `env:"P3"`
	P4  int16       `env:"P4"`
	P5  int32       `env:"P5"`
	P6  int64       `env:"P6"`
	P7  bool        `env:"P7"`
	P8  float32     `env:"P8"`
	P9  float64     `env:"P9"`
	P10 uint        `env:"P10"`
	P11 uint8       `env:"P11"`
	P12 uint16      `env:"P12"`
	P13 uint32      `env:"P13"`
	P14 uint64      `env:"P14"`
	P15 unmarshaler `env:"P15"`
	P16 childStruct `env:"P16"`
}

var (
	_ encoding.TextUnmarshaler = &unmarshaler{}
	_ encoding.TextMarshaler   = unmarshaler{}
)

type unmarshaler struct {
	f string
}

func (u *unmarshaler) UnmarshalText(b []byte) error {
	u.f = "unmarshaler called"
	return nil
}

func (u unmarshaler) MarshalText() ([]byte, error) {
	return []byte("marshaler called"), nil
}
