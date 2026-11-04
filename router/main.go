package router

import (
	"github.com/QuantumNous/new-api/controller"
	"github.com/QuantumNous/new-api/middleware"

	"github.com/gin-gonic/gin"
)

// SetRouter registers every backend route. The backend is API-only: the
// dashboard frontend is built, released and served separately, so unmatched
// requests never fall back to an HTML page.
func SetRouter(router *gin.Engine) {
	SetApiRouter(router)
	SetDashboardRouter(router)
	SetRelayRouter(router)
	SetTaskPluginProtocolRouter(router)
	SetVideoRouter(router)
	SetTaskRouter(router)
	pluginDispatcher := SetPluginRouter(router)
	SetFallbackRouter(router, pluginDispatcher)
}

// SetFallbackRouter is the API-only NoRoute contract: dynamic plugin routes
// get the first chance to answer, and anything they do not own ends in an
// uncached JSON 404 instead of a frontend page.
func SetFallbackRouter(router *gin.Engine, pluginDispatcher gin.HandlerFunc) {
	router.NoRoute(
		pluginDispatcher,
		middleware.RouteTag("fallback"),
		middleware.AccessTokenAudit(),
		middleware.GlobalWebRateLimit(),
		controller.RelayNotFound,
	)
}
