// structflag automatically converts struct fields into flag registrations
//
// Using reflect, structflag walks over the fields of a struct,
// registering each exported field as a flag.
// It recognizes the struct tag `flag` of the format: `name,flag help`.
// If name is `-`, the field is skipped.
// Flag names are joined by dots, if no struct tag is present,
// the lowercased name of the field is used.
package structflag

import (
	"encoding"
	"flag"
	"fmt"
	"reflect"
	"strconv"
	"strings"
	"time"
)

func RegisterFlags(fset *flag.FlagSet, c any, prefix string) error {
	cv := reflect.ValueOf(c).Elem()
	ct := cv.Type()
	if cv.Kind() != reflect.Struct {
		return fmt.Errorf("config: non struct passed to RegisterFlags, got %s", cv.Kind())
	}
	for i := range ct.NumField() {
		f := ct.Field(i)

		// can't set these
		if !f.IsExported() {
			continue
		}

		// get the flag name, prefix + field_name|tag_value
		tagVal := f.Tag.Get("flag")
		name, desc, _ := strings.Cut(tagVal, ",")
		if name == "" {
			name = strings.ToLower(f.Name)
		} else if name == "-" {
			continue
		}
		if prefix != "" {
			name = prefix + "." + name
		}

		// used to refer to this field
		fidx := f.Index

		// textmarshalers first
		if f.Type.Implements(reflect.TypeFor[encoding.TextUnmarshaler]()) {
			fset.Func(name, desc, func(s string) error {
				return cv.FieldByIndex(fidx).Addr().Interface().(encoding.TextUnmarshaler).UnmarshalText([]byte(s))
			})
			continue
		}

		// special case time types
		if reflect.TypeFor[time.Time]().AssignableTo(f.Type) {
			fset.Func(name, desc, func(s string) error {
				t, err := time.Parse(time.RFC3339, s)
				if err != nil {
					return err
				}
				cv.FieldByIndex(fidx).Set(reflect.ValueOf(t))
				return nil
			})
			continue
		}
		if reflect.TypeFor[time.Duration]().AssignableTo(f.Type) {
			fset.Func(name, desc, func(s string) error {
				t, err := time.ParseDuration(s)
				if err != nil {
					return err
				}
				cv.FieldByIndex(fidx).Set(reflect.ValueOf(t))
				return nil
			})
			continue
		}

		// nested structs
		if f.Type.Kind() == reflect.Struct {
			err := RegisterFlags(fset, cv.FieldByIndex(fidx).Addr().Interface(), name)
			if err != nil {
				return err
			}
			continue
		}

		// booleans need their own fset func
		if f.Type.Kind() == reflect.Bool {
			fset.BoolFunc(name, desc, func(s string) error {
				b, err := strconv.ParseBool(s)
				if err != nil {
					return err
				}
				cv.FieldByIndex(fidx).SetBool(b)
				return nil
			})
			continue
		}

		// everything else
		k := f.Type.Kind()
		val := reflect.New(f.Type)
		// if it's a slice, grab the element kind
		if k == reflect.Slice {
			k = f.Type.Elem().Kind()
			val = reflect.New(f.Type.Elem())
		}
		val = val.Elem()
		fset.Func(name, desc, func(s string) error {
			switch k {
			case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
				n, err := strconv.ParseInt(s, 10, 64)
				if err != nil {
					return err
				}
				val.SetInt(n)
			case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
				n, err := strconv.ParseUint(s, 10, 64)
				if err != nil {
					return err
				}
				val.SetUint(n)
			case reflect.Float32, reflect.Float64:
				n, err := strconv.ParseFloat(s, 64)
				if err != nil {
					return err
				}
				val.SetFloat(n)
			case reflect.String:
				val.SetString(s)
			default:
				return fmt.Errorf("unhandled type: %v", f.Type.Name())
			}
			if f.Type.Kind() == reflect.Slice {
				// append to slices
				cv.FieldByIndex(fidx).Set(reflect.Append(cv.FieldByIndex(fidx), val))
			} else {
				cv.FieldByIndex(fidx).Set(val)
			}
			return nil
		})

	}
	return nil
}
