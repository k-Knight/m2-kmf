diff --git a/scripts/game/entity_system/systems/spellcasting/spell_spray.lua b/scripts/game/entity_system/systems/spellcasting/spell_spray.lua
index 46ab6ff..e6ff6c1 100644
--- a/scripts/game/entity_system/systems/spellcasting/spell_spray.lua
+++ b/scripts/game/entity_system/systems/spellcasting/spell_spray.lua
@@ -1,5 +1,7 @@
 -- chunkname: @scripts/game/entity_system/systems/spellcasting/spell_spray.lua
 
+local LENGTH_MULT = 1.15
+
 local SETTINGS = SpellSettings
 local DO_DEBUG_DRAW = SETTINGS.spray_debug_enabled
 local DO_DEBUG_DRAW_MISSED_BOXES = SETTINGS.spray_debug_draw_missed_boxes
@@ -195,9 +197,11 @@ function Spray_Effect.init(context, spell_context)
 end
 
 function Spray_Effect.set_range(data, range)
+	-- fun-balance :: buff spray length
+	local mult = kmf.vars.funprove_enabled and LENGTH_MULT or 1.0
 	local world = data.world
 	local effect = data.effect
-	local amount = range / data.max_range
+	local amount = range / (data.max_range / mult)
 	local element_amount = data.element_amount
 
 	if element_amount == 1 then
@@ -331,6 +335,11 @@ Spells_Spray = {
 		smr = smr * length_mul
 		range = range * length_mul
 
+		-- fun-balance :: buff spray length
+		local mult = kmf.vars.funprove_enabled and LENGTH_MULT or 1.0
+		range = range * mult
+		smr = smr * mult
+
 		local _spray_width
 
 		if context.is_standalone then
@@ -354,7 +363,6 @@ Spells_Spray = {
 			range = range,
 			original_range = range,
 			max_range = smr,
-			elements = elements,
 			duration = _duration,
 			idle_time = 1 / SETTINGS.spray_hits_per_second,
 			hit_units = {},
