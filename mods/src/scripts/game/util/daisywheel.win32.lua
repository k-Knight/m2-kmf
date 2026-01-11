diff --git a/scripts/game/util/daisywheel.win32.lua b/scripts/game/util/daisywheel.win32.lua
index 2e54312..b596fc5 100644
--- a/scripts/game/util/daisywheel.win32.lua
+++ b/scripts/game/util/daisywheel.win32.lua
@@ -22,7 +22,7 @@ if DaisyWheel == nil then
 		if submitted then
 			_last_submitted_text, _last_submitted_text_length = Steam.get_entered_gamepad_textinput(submitted_text_length)
 		else
-			_last_submitted_text, _last_submitted_text_length = nil
+			_last_submitted_text, _last_submitted_text_length = nil, nil
 		end
 
 		if _listners == nil or table.map_size(_listners) == 0 then
@@ -89,7 +89,9 @@ if DaisyWheel == nil then
 	end
 
 	local function available()
-		if not Application.have_steam() then
+		local has_steam = (rawget(_G, "Steam") ~= nil) or Application.have_steam()
+
+		if not has_steam then
 			if DaisyWheel_Debug then
 				print("DaisyWheel:available() = false (no steam)")
 			end
@@ -97,6 +99,16 @@ if DaisyWheel == nil then
 			return false
 		end
 
+		local steam_connected = Steam.connected()
+
+		if not steam_connected then
+			if DaisyWheel_Debug then
+				print("DaisyWheel:available() = false (not connected)")
+			end
+
+			--return false
+		end
+
 		if not Steam.is_overlay_enabled() then
 			if DaisyWheel_Debug then
 				print("DaisyWheel:available() = false (is_overlay_enabled() == false)")
