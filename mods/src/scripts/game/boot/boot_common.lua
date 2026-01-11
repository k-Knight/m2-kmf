diff --git a/scripts/game/boot/boot_common.lua b/scripts/game/boot/boot_common.lua
index e049723..af3fa76 100644
--- a/scripts/game/boot/boot_common.lua
+++ b/scripts/game/boot/boot_common.lua
@@ -1,4 +1,6 @@
-﻿-- chunkname: @scripts/game/boot/boot_common.lua
+-- chunkname: @scripts/game/boot/boot_common.lua
+
+require("foundation/scripts/boot/foundation_setup")
 
 UPDATE_INDEX = UPDATE_INDEX or 0
 UPDATE_INDEX_MOD = 60
@@ -20,6 +22,8 @@ function FRAME_PRINT(format, ...)
 end
 
 function init_common()
+	print("KMF from dc5f8ad03326b768")
+
 	if EDITOR_LAUNCH then
 		Application.set_autoload_enabled(true)
 	end
@@ -30,7 +34,6 @@ function init_common()
 		require("foundation/scripts/util/strict")
 	end
 
-	require("foundation/scripts/boot/foundation_setup")
 	Boot:setup(game_require_func)
 
 	if PD_APPLICATION_PARAMETER["window-title"] and rawget(_G, "Window") then