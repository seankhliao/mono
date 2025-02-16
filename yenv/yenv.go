// yenv populates a struct from the given environment variables,
// matching the struct tag "env" key.
package yenv

import (
	"encoding"
	"fmt"
	"reflect"
	"strconv"
	"strings"
	"time"
)

// Map is a convenience function to turn key=value environment variables
// (typically from [os.Environ]) to a map for easy access.
// Last value wins.
func Map(environ []string) map[string]string {
	envs := make(map[string]string, len(environ))
	for _, env := range environ {
		if k, v, ok := strings.Cut(env, "="); ok {
			envs[k] = v
		}
	}
	return envs
}

type fieldError struct {
	field string
	key   string
	err   error
}

func (f fieldError) Error() string {
	return fmt.Sprintf("yenv.FromEnv field=%s key=%s err=%s", f.field, f.key, f.err)
}

func (f fieldError) Unwrap() error {
	return f.err
}

// FromEnv populates a struct using the given environment variables.
// Besides the basic types, [encoding.TextUnmarshaler] is also supported.
// "prefix" is a prefix to all environment variable keys;
// prefix and struct nesting are joined with "_".
// "t" should be a pointer to a struct.
func FromEnv(envs map[string]string, prefix string, t any) error {
	confType := reflect.TypeOf(t).Elem()
	confStruct := reflect.ValueOf(t).Elem()
	for fi := range confType.NumField() {
		structField := confType.Field(fi)
		if !structField.IsExported() {
			continue
		}

		envKey := structField.Tag.Get("env")
		if prefix != "" {
			envKey = prefix + "_" + envKey
		}

		fieldErr := fieldError{
			field: structField.Name,
			key:   envKey,
		}

		field := confStruct.Field(fi)
		fieldPtr := field.Addr().Interface()

		envVal, hasValue := envs[envKey]
		if u, ok := fieldPtr.(encoding.TextUnmarshaler); ok {
			err := u.UnmarshalText([]byte(envVal))
			if err != nil {
				fieldErr.err = err
				return fieldErr
			}
			continue
		}

		if structField.Type.Kind() == reflect.Struct {
			err := FromEnv(envs, envKey, fieldPtr)
			if err != nil {
				if fErr, ok := err.(fieldError); ok {
					fErr.field = structField.Name + "." + fErr.field
					return fErr
				}
				fieldErr.err = err
				return fieldErr
			}
			continue
		}

		if !hasValue {
			continue
		}

		switch structField.Type {
		case reflect.TypeFor[time.Duration]():
			v, err := time.ParseDuration(envVal)
			if err != nil {
				fieldErr.err = err
				return fieldErr
			}
			field.Set(reflect.ValueOf(v))
		default:

			switch structField.Type.Kind() {
			case reflect.Bool:
				v, err := strconv.ParseBool(envVal)
				if err != nil {
					fieldErr.err = err
					return fieldErr
				}
				field.SetBool(v)
			case reflect.Float32, reflect.Float64:
				v, err := strconv.ParseFloat(envVal, 64)
				if err != nil {
					fieldErr.err = err
					return fieldErr
				}
				field.SetFloat(v)
			case reflect.Int, reflect.Int16, reflect.Int32, reflect.Int64, reflect.Int8:
				v, err := strconv.ParseInt(envVal, 10, 64)
				if err != nil {
					fieldErr.err = err
					return fieldErr
				}
				field.SetInt(v)
			case reflect.String:
				field.SetString(envVal)
			case reflect.Uint, reflect.Uint16, reflect.Uint32, reflect.Uint64, reflect.Uint8:
				v, err := strconv.ParseUint(envVal, 10, 64)
				if err != nil {
					fieldErr.err = err
					return fieldErr
				}
				field.SetUint(v)
			}
		}
	}
	return nil
}

// Print outputs the environment variables that reflect the current values
// os the struct fields with "env" struct tags.
// No masking is done on the output (may output secrets),
// [encoding.TextMarshaler] is supported.
func Print(prefix string, t any) []string {
	var out []string

	confType := reflect.TypeOf(t)
	confStruct := reflect.ValueOf(t)
	if confType.Kind() == reflect.Pointer {
		confType = confType.Elem()
		confStruct = confStruct.Elem()
	}
	for fi := range confType.NumField() {
		structField := confType.Field(fi)
		if !structField.IsExported() {
			continue
		}

		envKey := structField.Tag.Get("env")
		if envKey == "" {
			continue
		}
		if prefix != "" {
			envKey = prefix + "_" + envKey
		}

		field := confStruct.Field(fi).Interface()

		switch u := field.(type) {
		case time.Duration:
			out = append(out, fmt.Sprintf("%s=%s", envKey, u.String()))
			continue
		case encoding.TextMarshaler:
			b, _ := u.MarshalText()
			out = append(out, fmt.Sprintf("%s=%s", envKey, string(b)))
			continue
		}

		if structField.Type.Kind() == reflect.Struct {
			out = append(out, Print(envKey, field)...)
			continue
		}

		out = append(out, fmt.Sprintf("%s=%v", envKey, field))
	}

	return out
}
