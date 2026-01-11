diff --git a/scripts/game/managers/save_manager.lua b/scripts/game/managers/save_manager.lua
index f2a4ab5..799882f 100644
--- a/scripts/game/managers/save_manager.lua
+++ b/scripts/game/managers/save_manager.lua
@@ -669,6 +669,10 @@ function SaveManager:update_generic(dt)
 
 	local info = self.system.progress(self.token)
 
+	if not info then
+		return
+	end
+
 	if info.error then
 		cat_print("SaveManager", "Failed to load:", info.error)
 		self.system.close(self.token)
