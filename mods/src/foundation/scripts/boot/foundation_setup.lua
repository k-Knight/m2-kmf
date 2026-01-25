diff --git a/foundation/scripts/boot/foundation_setup.lua b/foundation/scripts/boot/foundation_setup.lua
index 1133d1d..1a6748e 100644
--- a/foundation/scripts/boot/foundation_setup.lua
+++ b/foundation/scripts/boot/foundation_setup.lua
@@ -42,9 +42,9 @@ function Boot:setup(game_require_callback)
 		boot_base_require("development", "development_update", "local_boot")
 	end
 
-	self:load_context()
-	self:create_context()
-	self:load_scriptfiles_package()
+	--self:load_context()
+	--self:create_context()
+	--self:load_scriptfiles_package()
 	self:load_scriptutils()
 	self:load_init_worldmanager()
 	self:load_entity_system()
@@ -225,3 +225,13 @@ end
 function Boot:destroy()
 	self.package_manager:destroy()
 end
+
+if not cat_printf_spam then
+	cat_printf_spam = function(...) end
+end
+Boot:load_context()
+Boot:create_context()
+Boot:load_scriptfiles_package()
+require("foundation/scripts/network/network_settings")
+
+return
