package goreleases

import "testing"

func TestVersion(t *testing.T) {
	testcases := []struct {
		version                       string
		major, minor, patch, rc, beta int
	}{
		{
			"go1.2",
			1, 2, 0, 0, 0,
		}, {
			"go1.2.3",
			1, 2, 3, 0, 0,
		}, {
			"go1.4rc5",
			1, 4, 0, 5, 0,
		}, {
			"go1.6beta7",
			1, 6, 0, 0, 7,
		},
	}
	for _, tc := range testcases {
		major, minor, patch, rc, beta := Version(tc.version).Parts()
		if major != tc.major {
			t.Errorf("Version(%v).major = %v, want %v", tc.version, major, tc.major)
		}
		if minor != tc.minor {
			t.Errorf("Version(%v).minor = %v, want %v", tc.version, minor, tc.minor)
		}
		if patch != tc.patch {
			t.Errorf("Version(%v).patch = %v, want %v", tc.version, patch, tc.patch)
		}
		if rc != tc.rc {
			t.Errorf("Version(%v).rc = %v, want %v", tc.version, rc, tc.rc)
		}
		if beta != tc.beta {
			t.Errorf("Version(%v).beta = %v, want %v", tc.version, beta, tc.beta)
		}
	}
}
