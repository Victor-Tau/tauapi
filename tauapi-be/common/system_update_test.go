package common

import "testing"

func TestNormalizeSystemUpdateRepository(t *testing.T) {
	ok := map[string]string{
		"":                                     "",
		"  ":                                   "",
		"Victor-Tau/tauapi":                    "Victor-Tau/tauapi",
		" owner/repo.name ":                    "owner/repo.name",
		"https://github.com/Victor-Tau/tauapi": "Victor-Tau/tauapi",
		"https://github.com/Victor-Tau/tauapi.git": "Victor-Tau/tauapi",
		"https://GitHub.com/a/b/releases/tag/v1":   "a/b",
		"github.com/a/b/":                          "a/b",
		"git@github.com:a/b.git":                   "a/b",
	}
	for in, want := range ok {
		got, err := NormalizeSystemUpdateRepository(in)
		if err != nil || got != want {
			t.Errorf("%q => %q, %v; want %q", in, got, err, want)
		}
	}
	for _, in := range []string{"owner", "a/b/c", "https://gitlab.com/a/b", "-a/b", "a/..", "a/b?x=1", "a b/c", "https://github.com/a", "../../x"} {
		if got, err := NormalizeSystemUpdateRepository(in); err == nil {
			t.Errorf("%q accepted as %q", in, got)
		}
	}
	if EffectiveSystemUpdateRepository("") != DefaultSystemUpdateRepository || EffectiveSystemUpdateRepository("bad") != DefaultSystemUpdateRepository {
		t.Error("default fallback")
	}
}
