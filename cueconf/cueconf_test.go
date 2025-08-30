package cueconf

import (
	"encoding/json/v2"
	"os"
	"path/filepath"
	"reflect"
	"testing"
)

type TestConfig struct {
	S string
	B bool
	I int
	M map[string]string
	L []string
	E struct {
		S string
		B bool
	}
}

var testSchema = `
S: string
B: bool
I: int
M: [string]: string
L: [...string]
E: S: string
E: B: bool
`

func TestForBytes(t *testing.T) {
	wantCoof := TestConfig{
		S: "a string",
		B: true,
		I: 666,
		M: map[string]string{"hello": "world"},
		L: []string{"foo", "bar"},
		E: struct {
			S string
			B bool
		}{"zzz", false},
	}
	wantConfJSON, err := json.Marshal(wantCoof)
	if err != nil {
		t.Fatal("marshal config as json:", err)
	}
	gotConf, err := ForBytes[TestConfig](testSchema, wantConfJSON)
	if err != nil {
		t.Error("ForBytes:", err)
	}
	if !reflect.DeepEqual(gotConf, wantCoof) {
		t.Errorf("config not equal:\ngot: %+v\nwnt: %+v", gotConf, wantCoof)
	}
}

func TestForFile(t *testing.T) {
	wantCoof := TestConfig{
		S: "a string",
		B: true,
		I: 666,
		M: map[string]string{"hello": "world"},
		L: []string{"foo", "bar"},
		E: struct {
			S string
			B bool
		}{"zzz", false},
	}
	wantConfJSON, err := json.Marshal(wantCoof)
	if err != nil {
		t.Fatal("marshal config as json:", err)
	}

	tmpDir := t.TempDir()
	tmpFile := filepath.Join(tmpDir, "config.json")
	err = os.WriteFile(tmpFile, wantConfJSON, 0o644)
	if err != nil {
		t.Fatal("write config to file:", err)
	}

	gotConf, err := ForFile[TestConfig](testSchema, tmpFile, false)
	if err != nil {
		t.Error("ForFile:", err)
	}
	if !reflect.DeepEqual(gotConf, wantCoof) {
		t.Errorf("config not equal:\ngot: %+v\nwnt: %+v", gotConf, wantCoof)
	}
}
