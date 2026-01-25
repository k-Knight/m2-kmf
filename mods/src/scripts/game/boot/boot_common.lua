diff --git a/scripts/game/boot/boot_common.lua b/scripts/game/boot/boot_common.lua
index c63e3da..04ad5f8 100644
--- a/scripts/game/boot/boot_common.lua
+++ b/scripts/game/boot/boot_common.lua
@@ -1,5 +1,7 @@
 -- chunkname: @scripts/game/boot/boot_common.lua
 
+require("foundation/scripts/boot/foundation_setup")
+
 UPDATE_INDEX = UPDATE_INDEX or 0
 UPDATE_INDEX_MOD = 60
 G_HACK_INGAME = false
@@ -30,7 +32,6 @@ function init_common()
 		require("foundation/scripts/util/strict")
 	end
 
-	require("foundation/scripts/boot/foundation_setup")
 	Boot:setup(game_require_func)
 
 	if PD_APPLICATION_PARAMETER["window-title"] and rawget(_G, "Window") then
