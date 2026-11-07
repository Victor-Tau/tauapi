package middleware

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/QuantumNous/new-api/common"
	"github.com/gin-gonic/gin"
)

type publicResourceAccess struct {
	Enabled     bool
	RequireAuth bool
}

func getPublicResourceAccess(module string) publicResourceAccess {
	fallback := publicResourceAccess{
		Enabled:     true,
		RequireAuth: false,
	}

	common.OptionMapRWMutex.RLock()
	raw := common.OptionMap["PublicResourceAccess"]
	common.OptionMapRWMutex.RUnlock()

	if strings.TrimSpace(raw) == "" {
		return fallback
	}

	var parsed map[string]any
	if err := common.Unmarshal([]byte(raw), &parsed); err != nil || parsed == nil {
		return publicResourceAccess{Enabled: false, RequireAuth: true}
	}

	return parsePublicResourceAccess(parsed[module], fallback)
}

func parsePublicResourceAccess(raw any, fallback publicResourceAccess) publicResourceAccess {
	switch value := raw.(type) {
	case bool:
		return publicResourceAccess{
			Enabled:     value,
			RequireAuth: fallback.RequireAuth,
		}
	case string:
		return publicResourceAccess{
			Enabled:     parsePublicResourceBool(value, fallback.Enabled),
			RequireAuth: fallback.RequireAuth,
		}
	case float64:
		return publicResourceAccess{
			Enabled:     parsePublicResourceBool(value, fallback.Enabled),
			RequireAuth: fallback.RequireAuth,
		}
	case map[string]any:
		access := fallback
		if enabled, ok := value["enabled"]; ok {
			access.Enabled = parsePublicResourceBool(enabled, fallback.Enabled)
		}
		if requireAuth, ok := value["requireAuth"]; ok {
			access.RequireAuth = parsePublicResourceBool(requireAuth, fallback.RequireAuth)
		}
		return access
	default:
		return fallback
	}
}

func parsePublicResourceBool(value any, fallback bool) bool {
	switch v := value.(type) {
	case bool:
		return v
	case string:
		switch strings.ToLower(strings.TrimSpace(v)) {
		case "true", "1":
			return true
		case "false", "0":
			return false
		default:
			return fallback
		}
	case float64:
		if v == 1 {
			return true
		}
		if v == 0 {
			return false
		}
		return fallback
	case int:
		if v == 1 {
			return true
		}
		if v == 0 {
			return false
		}
		return fallback
	default:
		return fallback
	}
}

func PublicResourceAuth(module string) gin.HandlerFunc {
	return func(c *gin.Context) {
		access := getPublicResourceAccess(module)
		if !access.Enabled {
			// Keep root pricing management available without reopening the public model square.
			if module == "pricing" && c.GetHeader("Authorization") != "" {
				RootAuth()(c)
				return
			}
			c.JSON(http.StatusForbidden, gin.H{
				"success": false,
				"message": fmt.Sprintf("%s is disabled", module),
			})
			c.Abort()
			return
		}

		if access.RequireAuth {
			UserAuth()(c)
			return
		}

		TryUserAuth()(c)
	}
}

func PublicResourceOrUserAuth(module string) gin.HandlerFunc {
	return func(c *gin.Context) {
		access := getPublicResourceAccess(module)
		if !access.Enabled || access.RequireAuth {
			UserAuth()(c)
			return
		}

		TryUserAuth()(c)
	}
}
