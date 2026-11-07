package model

import (
	"github.com/QuantumNous/new-api/common"
	"github.com/glebarez/sqlite"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/mysql"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/schema"
	"os"
	"testing"
)

func TestRetiredFrontendOptionsAreInert(t *testing.T) {
	previous := common.OptionMap
	common.OptionMap = map[string]string{}
	t.Cleanup(func() { common.OptionMap = previous })
	for _, key := range []string{"SystemName", "Logo", "Footer", "HeaderNavModules", "console_setting.api_info", "legal.user_agreement", "DataExportDefaultTime"} {
		common.OptionMap[key] = "legacy"
		require.NoError(t, updateOptionMap(key, "new value"))
		assert.NotContains(t, common.OptionMap, key)
		require.Error(t, UpdateOption(key, "new value"))
		require.Error(t, UpdateOptionsBulk(map[string]string{key: "new value"}))
	}
}

func TestLegacyNavigationRetainsOnlyBusinessAccess(t *testing.T) {
	raw := common.LegacyPublicResourceAccess(`{"home":false,"docs":false,"pricing":{"enabled":true,"requireAuth":true},"rankings":false}`)
	assert.JSONEq(t, `{"pricing":{"enabled":true,"requireAuth":true},"rankings":false}`, raw)
	assert.Equal(t, "{}", common.LegacyPublicResourceAccess("invalid"))
	require.NoError(t, validateOptionValue("PublicResourceAccess", `{"pricing":{"enabled":true,"requireAuth":true}}`))
	require.Error(t, validateOptionValue("PublicResourceAccess", `null`))
	require.Error(t, validateOptionValue("PublicResourceAccess", `{"pricing":null}`))
	require.Error(t, validateOptionValue("PublicResourceAccess", `{"home":{"enabled":false}}`))
	require.Error(t, validateOptionValue("PublicResourceAccess", `{"pricing":{"label":false}}`))
}

func TestFrontendOptionStartupDatabaseMatrix(t *testing.T) {
	for _, dialect := range []string{"sqlite", "mysql", "postgres"} {
		t.Run(dialect, func(t *testing.T) {
			var driver gorm.Dialector
			switch dialect {
			case "sqlite":
				driver = sqlite.Open(":memory:")
			case "mysql":
				dsn := os.Getenv("TEST_MYSQL_DSN")
				require.NotEmpty(t, dsn, "TEST_MYSQL_DSN is required for this explicit matrix")
				driver = mysql.Open(dsn)
			case "postgres":
				dsn := os.Getenv("TEST_POSTGRES_DSN")
				require.NotEmpty(t, dsn, "TEST_POSTGRES_DSN is required for this explicit matrix")
				driver = postgres.Open(dsn)
			}
			db, err := gorm.Open(driver, &gorm.Config{NamingStrategy: schema.NamingStrategy{TablePrefix: "frontend_check_"}})
			require.NoError(t, err)
			sqlDB, err := db.DB()
			require.NoError(t, err)
			versionQuery := "SELECT VERSION()"
			if dialect == "sqlite" {
				versionQuery = "SELECT sqlite_version()"
			}
			var engineVersion string
			require.NoError(t, db.Raw(versionQuery).Scan(&engineVersion).Error)
			t.Logf("database engine: %s %s", dialect, engineVersion)
			previousDB, previousType, previousOptions := DB, common.MainDatabaseType(), common.OptionMap
			DB = db
			common.SetMainDatabaseType(common.DatabaseType(dialect))
			initCol()
			t.Cleanup(func() {
				require.NoError(t, db.Migrator().DropTable(&Option{}))
				require.NoError(t, sqlDB.Close())
				DB = previousDB
				common.SetMainDatabaseType(previousType)
				initCol()
				common.OptionMap = previousOptions
			})
			require.NoError(t, db.AutoMigrate(&Option{}))
			// The Option schema is unchanged from released versions. Seed historical
			// values to verify two startups do not transform or delete existing data.
			legacy := []Option{
				{Key: "Logo", Value: "/legacy.png"},
				{Key: "SystemName", Value: "Legacy Site"},
				{Key: "console_setting.faq", Value: `[{"question":"Q","answer":"A"}]`},
				{Key: "ApiInfo", Value: "legacy data"},
				{Key: "theme.frontend", Value: "classic"},
				{Key: "HeaderNavModules", Value: `{"home":false,"pricing":{"enabled":true,"requireAuth":true}}`},
			}
			require.NoError(t, db.Create(&legacy).Error)
			for startup := 0; startup < 2; startup++ {
				InitOptionMap()
				for _, option := range legacy {
					assert.NotContains(t, common.OptionMap, option.Key)
				}
				assert.JSONEq(t, `{"pricing":{"enabled":true,"requireAuth":true}}`, common.OptionMap["PublicResourceAccess"])
				stored, err := AllOption()
				require.NoError(t, err)
				values := make([]Option, len(stored))
				for i, option := range stored {
					values[i] = *option
				}
				assert.ElementsMatch(t, legacy, values)
			}
			require.Error(t, UpdateOption("Logo", "/new.png"))
			require.NoError(t, UpdateOption("PublicResourceAccess", `{"pricing":{"enabled":false}}`))
			InitOptionMap()
			assert.JSONEq(t, `{"pricing":{"enabled":false}}`, common.OptionMap["PublicResourceAccess"])
			require.Error(t, db.Create(&Option{Key: "Logo", Value: "duplicate"}).Error)
		})
	}
}
