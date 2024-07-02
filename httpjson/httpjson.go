package httpjson

import (
	"encoding/json"
	"fmt"
	"net/http"
)

// Ok marshals the given data as JSON and writes it to the given ResponseWriter.
func OK(rw http.ResponseWriter, data any) error {
	b, err := json.Marshal(data)
	if err != nil {
		return fmt.Errorf("httpjson marshal data as json: %w", err)
	}

	rw.Header().Set("content-type", "application/json")
	_, err = rw.Write(b)
	return err
}

// https://datatracker.ietf.org/doc/html/rfc7807#section-3
type problemDetail struct {
	Type     string `json:"type,omitempty"`
	Title    string `json:"title,omitempty"`
	Status   int    `json:"status,omitempty"`
	Detail   string `json:"detail,omitempty"`
	Instance string `json:"instance,omitempty"`
}

// Err wraps the given error and message in an RFC 7807 Problem Details JSON Object,
// and writes it to the given ResponseWriter.
func Err(rw http.ResponseWriter, code int, msg string, err error) error {
	prob := problemDetail{
		Title:  msg,
		Detail: err.Error(),
		Status: code,
	}
	b, err := json.Marshal(prob)
	if err != nil {
		return fmt.Errorf("httpjson marshal problem json: %w", err)
	}

	rw.Header().Set("content-type", "application/problem+json")
	rw.WriteHeader(code)
	_, err = rw.Write(b)
	return err
}
