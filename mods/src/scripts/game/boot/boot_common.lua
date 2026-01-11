diff --git a/scripts/game/boot/boot_common.lua b/scripts/game/boot/boot_common.lua
index 28f3e8a..997b518 100644
--- a/scripts/game/boot/boot_common.lua
+++ b/scripts/game/boot/boot_common.lua
@@ -1,4 +1,6 @@
-﻿-- chunkname: @scripts/game/boot/boot_common.lua
+-- chunkname: @scripts/game/boot/boot_common.lua
+
+require("foundation/scripts/boot/foundation_setup")
 
 UPDATE_INDEX = UPDATE_INDEX or 0
 UPDATE_INDEX_MOD = 60
@@ -30,7 +32,6 @@ function init_common()
 		require("foundation/scripts/util/strict")
 	end
 
-	require("foundation/scripts/boot/foundation_setup")
 	Boot:setup(game_require_func)
 
 	if PD_APPLICATION_PARAMETER["window-title"] and rawget(_G, "Window") then
