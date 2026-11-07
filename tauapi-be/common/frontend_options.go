package common

import "strings"

// IsFrontendOption identifies retired presentation settings. Historical rows
// remain stored for rollback, but are neither applied nor exposed by the API.
func IsFrontendOption(key string) bool {
	if strings.HasPrefix(key, "console_setting.") || strings.HasPrefix(key, "legal.") {
		return true
	}
	switch key {
	case "DrawingEnabled", "TaskEnabled", "SystemUpdateRepository", "SystemName", "Logo", "Footer", "Notice", "About", "HomePageContent", "HeaderNavModules", "SidebarModulesAdmin", "DefaultCollapseSidebar", "DataExportDefaultTime", "DemoSiteEnabled", "Chats", "general_setting.docs_link", "theme.frontend", "ApiInfo", "Announcements", "FAQ", "UptimeKumaUrl", "UptimeKumaSlug", "Midjourney":
		return true
	}
	return false
}

// LegacyPublicResourceAccess retains only API restrictions from the retired
// navigation option. No presentation settings survive this compatibility read.
func LegacyPublicResourceAccess(raw string) string {
	var legacy map[string]any
	if UnmarshalJsonStr(raw, &legacy) != nil {
		return "{}"
	}
	access := make(map[string]any)
	for _, resource := range []string{"pricing", "rankings"} {
		if value, ok := legacy[resource]; ok {
			access[resource] = value
		}
	}
	encoded, err := Marshal(access)
	if err != nil {
		return "{}"
	}
	return string(encoded)
}
