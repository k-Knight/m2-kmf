diff --git a/scripts/game/settings/templates/effect_system_settings.lua b/scripts/game/settings/templates/effect_system_settings.lua
index cea8ee9..814234b 100644
--- a/scripts/game/settings/templates/effect_system_settings.lua
+++ b/scripts/game/settings/templates/effect_system_settings.lua
@@ -539,6 +539,12 @@ EffectTemplates = {
 		duration = 1,
 		effect = "content/particles/spells/magicks/thunderhead_lighting_bolt",
 		linked = false
+	},
+
+	blast_fire = {
+		duration = 1,
+		effect = "content/particles/spells/blast/blast_fire",
+		radius = 2
 	}
 }
 EffectTemplateLUT = {}
