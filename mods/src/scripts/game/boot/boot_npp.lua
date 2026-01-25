diff --git a/scripts/game/boot/boot_npp.lua b/scripts/game/boot/boot_npp.lua
index ee5b158..5f35a01 100644
--- a/scripts/game/boot/boot_npp.lua
+++ b/scripts/game/boot/boot_npp.lua
@@ -180,6 +180,9 @@ local function parse_module(out, mod, mod_name)
 
 	for k, v in pairs(mod) do
 		repeat
+			if mod_name == "RPC" then
+				print(k .. " :: " .. type(v))
+			end
 			if string_starts_with(k, "_") then
 				break
 			end
