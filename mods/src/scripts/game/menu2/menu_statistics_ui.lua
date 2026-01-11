diff --git a/scripts/game/menu2/menu_statistics_ui.lua b/scripts/game/menu2/menu_statistics_ui.lua
index 727ce9a..59bd8da 100644
--- a/scripts/game/menu2/menu_statistics_ui.lua
+++ b/scripts/game/menu2/menu_statistics_ui.lua
@@ -163,7 +163,12 @@ local stats_to_show = {
 }
 
 local function format_value(value)
-	value = tostring(math.clamp(math.floor(value), 0, 999999999999))
+	local status, err = pcall(function()
+		value = tostring(math.clamp(math.floor(value), 0, 999999999999))
+	end)
+	if not status then
+		value = 999999999999
+	end
 
 	local regex = "(%d+)(%d%d%d)"
 