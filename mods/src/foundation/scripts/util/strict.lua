diff --git a/foundation/scripts/util/strict.lua b/foundation/scripts/util/strict.lua
index 756a1e3..06396db 100644
--- a/foundation/scripts/util/strict.lua
+++ b/foundation/scripts/util/strict.lua
@@ -55,7 +55,8 @@ function meta.__newindex(t, k, v)
 			local info = debug_getinfo(2, "Sl")
 
 			if k ~= "to_console_line" and info and info.what ~= "main" and info.what ~= "C" then
-				error_func("[ERROR] cannot assign undeclared global %q, %s", k, debug_info_string(info))
+				--error_func("[ERROR] cannot assign undeclared global %q, %s", k, debug_info_string(info))
+				print(sprintf("[strict error] cannot assign undeclared global %q", k))
 			end
 		end
 
@@ -70,7 +71,8 @@ function meta.__index(t, k)
 		local info = debug_getinfo(2, "Sl")
 
 		if k ~= "to_console_line" and info and info.what ~= "main" and info.what ~= "C" then
-			error_func("[ERROR] cannot index undeclared global %q, %s", k, debug_info_string(info))
+			--error_func("[ERROR] cannot index undeclared global %q, %s", k, debug_info_string(info))
+			print(sprintf("[strict error] cannot index undeclared global %q", k))
 		end
 	end
 end
