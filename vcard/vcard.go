// vcard is for [RFC 6350] vCards
//
// [RFC 6350]: https://datatracker.ietf.org/doc/html/rfc6350
package vcard

import (
	"net/url"
	"strings"
	"time"
)

const (
	MimeType = "text/vcard"
)

// Begin is the starting frame of the vCard
//
// https://datatracker.ietf.org/doc/html/rfc6350#section-6.1.1
type Begin struct{}

func (Begin) String() string { return "BEGIN:VCARD\r\n" }

// End is the ending frame of the vCard
//
// https://datatracker.ietf.org/doc/html/rfc6350#section-6.1.2
type End struct{}

func (End) String() string { return "END:VCARD\r\n" }

// https://datatracker.ietf.org/doc/html/rfc6350#section-6.7.9
type Version struct{}

func (Version) String() string { return "VERSION:4.0\r\n" }

// Source represents a URL from which more up to date info can be retrieved
//
// https://datatracker.ietf.org/doc/html/rfc6350#section-6.1.3
type Source url.URL

func (s Source) String() string {
	u := url.URL(s)
	return "SOURCE;VALUE=uri:" + u.String() + "\r\n"
}

type Revision time.Time

func (r Revision) String() string {
	return "REV:" + time.Time(r).Format("20060102T150405Z") + "\r\n"
}

// Kind is the kind of entity the card represents,
// e.g. "individual", "group", "org", "location"
//
// https://datatracker.ietf.org/doc/html/rfc6350#section-6.1.4
type Kind string

func (k Kind) String() string { return "KIND:" + escape(string(k)) + "\r\n" }

// FormattedName is the full, formatted name of the entity.
//
// https://datatracker.ietf.org/doc/html/rfc6350#section-6.2.1
type FormattedName string

func (f FormattedName) String() string { return "FN:" + escape(string(f)) + "\r\n" }

// Name is the individual name components
//
// https://datatracker.ietf.org/doc/html/rfc6350#section-6.2.2
type Name struct {
	Family     string
	Given      string
	Additional []string
	Prefix     []string
	Suffix     []string
}

func (n Name) String() string {
	return "N:" + escape(n.Family) +
		";" + escape(n.Given) +
		";" + escapeJoin(n.Additional) +
		";" + escapeJoin(n.Prefix) +
		";" + escapeJoin(n.Suffix) +
		"\r\n"
}

// Nickname
//
// https://datatracker.ietf.org/doc/html/rfc6350#section-6.2.3
type Nickname []string

func (n Nickname) String() string {
	return "NICKNAME:" + escapeJoin(n) + "\r\n"
}

// https://datatracker.ietf.org/doc/html/rfc6350#section-6.2.7
type Gender struct {
	Sex      string
	Identity string
}

func (g Gender) String() string {
	l := "GENDER:" + g.Sex
	if g.Identity != "" {
		l += ";" + escape(g.Identity)
	}
	return l + "\r\n"
}

// https://datatracker.ietf.org/doc/html/rfc6350#section-6.3.1
type Address struct {
	Type string // type of address

	POBox      string // recommended not to be set
	Extended   string // apartment or suite, recommended not to be set
	Street     string
	Locality   string // city
	Region     string // state or province
	PostalCode string
	Country    string // full country name
}

func (a Address) String() string {
	return "ADR" +
		";" + a.Type +
		":" + escape(a.POBox) +
		";" + escape(a.Extended) +
		";" + escape(a.Street) +
		";" + escape(a.Locality) +
		";" + escape(a.Region) +
		";" + escape(a.PostalCode) +
		";" + escape(a.Country) +
		"\r\n"
}

// https://datatracker.ietf.org/doc/html/rfc6350#section-6.4.1
type Telephone struct {
	Type   []string // "text" / "voice" / "fax" / "cell" / "video" / "pager" / "textphone"
	Number string   // include dashes and country code
}

func (t Telephone) String() string {
	return "TEL" +
		";" + "VALUE=uri" +
		";" + `TYPE="` + escapeJoin(t.Type) + `"` +
		":" + "tel:" + escape(t.Number) +
		"\r\n"
}

// https://datatracker.ietf.org/doc/html/rfc6350#section-6.4.2
type Email struct {
	Type  string
	Email string
}

func (e Email) String() string {
	return "EMAIL" +
		";" + "TYPE=" + e.Type +
		":" + escape(e.Email) +
		"\r\n"
}

type URL struct {
	Type string

	URL *url.URL
}

func (u URL) String() string {
	return "URL" +
		";" + "VALUE=uri" +
		";" + u.Type +
		":" + escape(u.URL.String()) +
		"\r\n"
}

type SocialProfile struct {
	Type     string // the service
	Username string
	Profile  *url.URL
}

// https://www.rfc-editor.org/rfc/rfc9554.html#name-socialprofile
func (s SocialProfile) String() string {
	l := "SOCIALPROFILE" +
		";" + "VALUE=uri" +
		";" + "SERVICE-TYPE=" + s.Type
	if s.Username != "" {
		l += ";USERNAME=" + `"` + escape(s.Username) + `"`
	}
	l += ":" + escape(s.Profile.String()) + "\r\n"
	return l
}

var escaper = strings.NewReplacer(",", "\\,", ";", "\\;")

func escape(s string) string {
	return escaper.Replace(s)
}

// joins values with ","
func escapeJoin(ss []string) string {
	ns := make([]string, 0, len(ss))
	for _, s := range ss {
		ns = append(ns, escape(s))
	}
	return strings.Join(ns, ",")
}
