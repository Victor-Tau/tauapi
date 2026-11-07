package controller

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/QuantumNous/new-api/common"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestUpdateOptionRejectsFrontendPresentation(t *testing.T) {
	for _, key := range []string{"DrawingEnabled", "TaskEnabled", "SystemUpdateRepository", "SystemName", "Logo", "Footer", "Notice", "About", "HomePageContent", "HeaderNavModules", "SidebarModulesAdmin", "DefaultCollapseSidebar", "DataExportDefaultTime", "DemoSiteEnabled", "Chats", "theme.frontend", "general_setting.docs_link", "console_setting.faq", "legal.user_agreement"} {
		t.Run(key, func(t *testing.T) {
			body, err := common.Marshal(map[string]string{"key": key, "value": "ignored"})
			require.NoError(t, err)
			response := httptest.NewRecorder()
			context, _ := gin.CreateTestContext(response)
			context.Request = httptest.NewRequest(http.MethodPut, "/api/option/", strings.NewReader(string(body)))
			UpdateOption(context)
			var payload map[string]any
			require.NoError(t, common.Unmarshal(response.Body.Bytes(), &payload))
			assert.Equal(t, false, payload["success"])
		})
	}
}

func TestGetStatusDoesNotControlFrontendPresentation(t *testing.T) {
	previousMap := common.OptionMap
	common.OptionMap = map[string]string{"Logo": "https://backend.example/logo.png", "Notice": "backend notice", "PublicResourceAccess": `{"pricing":{"requireAuth":true}}`}
	t.Cleanup(func() { common.OptionMap = previousMap })
	response := httptest.NewRecorder()
	context, _ := gin.CreateTestContext(response)
	context.Request = httptest.NewRequest(http.MethodGet, "/api/status", nil)
	GetStatus(context)
	var payload struct {
		Success bool           `json:"success"`
		Data    map[string]any `json:"data"`
	}
	require.NoError(t, common.Unmarshal(response.Body.Bytes(), &payload))
	require.True(t, payload.Success)
	for _, field := range []string{"enable_drawing", "enable_task", "system_update_repository", "theme", "system_name", "logo", "footer_html", "docs_link", "HeaderNavModules", "SidebarModulesAdmin", "chats", "demo_site_enabled", "default_collapse_sidebar", "data_export_default_time", "api_info", "announcements", "faq", "api_info_enabled", "announcements_enabled", "faq_enabled", "uptime_kuma_enabled", "user_agreement_enabled", "privacy_policy_enabled"} {
		assert.NotContains(t, payload.Data, field)
	}
	assert.Equal(t, common.OptionMap["PublicResourceAccess"], payload.Data["public_resource_access"])
	assert.Contains(t, payload.Data, "quota_per_unit")
	assert.Contains(t, payload.Data, "passkey_login")
}

func TestGetOptionsOmitsRetiredFrontendSettings(t *testing.T) {
	previousMap := common.OptionMap
	common.OptionMap = map[string]string{"SystemName": "legacy", "Logo": "/legacy.png", "console_setting.faq": "[]", "PublicResourceAccess": "{}"}
	t.Cleanup(func() { common.OptionMap = previousMap })
	response := httptest.NewRecorder()
	context, _ := gin.CreateTestContext(response)
	context.Request = httptest.NewRequest(http.MethodGet, "/api/option/", nil)
	GetOptions(context)
	var payload struct {
		Success bool `json:"success"`
		Data    []struct {
			Key string `json:"key"`
		} `json:"data"`
	}
	require.NoError(t, common.Unmarshal(response.Body.Bytes(), &payload))
	require.True(t, payload.Success)
	for _, option := range payload.Data {
		assert.False(t, common.IsFrontendOption(option.Key), option.Key)
	}
}

func TestGetStatusIdentifiesBackendVersionForIndependentFrontends(t *testing.T) {
	previousVersion := common.Version
	common.Version = "v1.2.3+be.abc123"
	t.Cleanup(func() { common.Version = previousVersion })
	response := httptest.NewRecorder()
	context, _ := gin.CreateTestContext(response)
	context.Request = httptest.NewRequest(http.MethodGet, "/api/status", nil)

	GetStatus(context)

	var payload struct {
		Success bool           `json:"success"`
		Data    map[string]any `json:"data"`
	}
	require.Equal(t, http.StatusOK, response.Code)
	require.NoError(t, common.Unmarshal(response.Body.Bytes(), &payload))
	require.True(t, payload.Success)
	assert.Equal(t, "v1.2.3+be.abc123", payload.Data["backend_version"])
	assert.Equal(t, payload.Data["backend_version"], payload.Data["version"])
	assert.NotContains(t, payload.Data, "frontend_version")
}

func TestUpdateSelfRejectsServerSideSidebarPreferences(t *testing.T) {
	response := httptest.NewRecorder()
	context, _ := gin.CreateTestContext(response)
	context.Request = httptest.NewRequest(http.MethodPut, "/api/user/self", strings.NewReader(`{"sidebar_modules":"{}"}`))
	UpdateSelf(context)
	assert.Equal(t, http.StatusBadRequest, response.Code)
}
