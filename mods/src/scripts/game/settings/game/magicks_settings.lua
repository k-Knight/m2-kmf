diff --git a/scripts/game/settings/game/magicks_settings.lua b/scripts/game/settings/game/magicks_settings.lua
index e47c80e..4498994 100644
--- a/scripts/game/settings/game/magicks_settings.lua
+++ b/scripts/game/settings/game/magicks_settings.lua
@@ -197,6 +197,13 @@ MagicksSettings.force_prism = {
 		0.5,
 		2.5,
 		0.5
+	},
+	element_queue = {
+		"ice",
+		"ice",
+		"shield",
+		"arcane",
+		"arcane"
 	}
 }
 MagicksSettings.area_prism = {
@@ -213,6 +220,13 @@ MagicksSettings.area_prism = {
 		2.5,
 		1.5,
 		2.5
+	},
+	element_queue = {
+		"ice",
+		"ice",
+		"shield",
+		"lightning",
+		"lightning"
 	}
 }
 MagicksSettings.dragon_strike = {
