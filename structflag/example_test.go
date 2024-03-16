package structflag_test

import (
	"flag"
	"fmt"
	"time"

	"go.seankhliao.com/mono/structflag"
)

func ExampleRegisterFlags() {
	fset := flag.NewFlagSet("cmd", flag.ContinueOnError)

	type Config struct {
		Sub struct {
			S0 string
			S1 string `flag:"string_1,help me"`
		}
		B1  bool
		B3  bool `flag:"bool_3"`
		S2  string
		I1  int
		I16 int16
		I64 int64
		F32 float32
		F64 float64
		T1  time.Time
		D1  time.Duration
		A1  []string
		A2  []int
	}

	var conf Config
	err := structflag.RegisterFlags(fset, &conf, "f")
	if err != nil {
		panic(err)
	}

	err = fset.Parse([]string{
		"-f.sub.s0=aaa", "-f.sub.string_1", "bbb",
		"-f.b1", "-f.bool_3",
		"-f.s2=ccc",
		"-f.i1=123", "-f.i16=456", "-f.i64=-789",
		"-f.t1=2024-02-10T22:23:45Z", "-f.d1=5h4m3s",
		"-f.a1=ddd", "-f.a1=eee",
		"-f.a2=111", "-f.a2=222", "-f.a2=333",
	})
	if err != nil {
		panic(err)
	}

	fmt.Printf("%#v\n", conf)

	// Output: structflag_test.Config{Sub:struct { S0 string; S1 string "flag:\"string_1,help me\"" }{S0:"aaa", S1:"bbb"}, B1:true, b2:false, B3:true, S2:"ccc", s3:"", I1:123, I16:456, I64:-789, F32:0, F64:0, T1:time.Date(2024, time.February, 10, 22, 23, 45, 0, time.UTC), D1:18243000000000, A1:[]string{"ddd", "eee"}, A2:[]int{111, 222, 333}}
}
