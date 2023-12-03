package main

import "time"

var bucketSession = []byte(`session`)

type SessionInfo struct {
	UserID    int64
	Email     string
	StartTime time.Time
	UserAgent string
}
