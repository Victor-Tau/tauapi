package common

import (
	"errors"
	"regexp"
	"strings"
)

// DefaultSystemUpdateRepository is the GitHub repository whose Releases the
// admin "system update" check reads when no override is configured.
const DefaultSystemUpdateRepository = "Victor-Tau/tauapi"

// SystemUpdateRepositoryOptionKey stores the owner/repo override.
const SystemUpdateRepositoryOptionKey = "SystemUpdateRepository"

var githubRepositoryPattern = regexp.MustCompile(`^[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})/[A-Za-z0-9._-]{1,100}$`)

var ErrInvalidSystemUpdateRepository = errors.New("invalid GitHub repository")

// NormalizeSystemUpdateRepository accepts "owner/repo" or a github.com URL
// (https://github.com/owner/repo[.git][/...]) and returns "owner/repo".
// An empty value means "use the default".
func NormalizeSystemUpdateRepository(value string) (string, error) {
	v := strings.TrimSpace(value)
	if v == "" {
		return "", nil
	}
	lower := strings.ToLower(v)
	for _, prefix := range []string{"https://github.com/", "http://github.com/", "https://www.github.com/", "github.com/", "git@github.com:"} {
		if strings.HasPrefix(lower, prefix) {
			v = v[len(prefix):]
			parts := strings.Split(strings.Trim(v, "/"), "/")
			if len(parts) < 2 {
				return "", ErrInvalidSystemUpdateRepository
			}
			v = parts[0] + "/" + parts[1]
			break
		}
	}
	v = strings.TrimSuffix(strings.Trim(v, "/"), ".git")
	if !githubRepositoryPattern.MatchString(v) {
		return "", ErrInvalidSystemUpdateRepository
	}
	repo := v[strings.Index(v, "/")+1:]
	if repo == "." || repo == ".." {
		return "", ErrInvalidSystemUpdateRepository
	}
	return v, nil
}

// EffectiveSystemUpdateRepository returns the configured repository or the default.
// Callers must hold OptionMapRWMutex (read) when passing OptionMap values.
func EffectiveSystemUpdateRepository(configured string) string {
	if repo, err := NormalizeSystemUpdateRepository(configured); err == nil && repo != "" {
		return repo
	}
	return DefaultSystemUpdateRepository
}
