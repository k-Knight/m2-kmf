diff --git a/scripts/game/entity_system/systems/spellcasting/spell_lightningaoe.lua b/scripts/game/entity_system/systems/spellcasting/spell_lightningaoe.lua
index 20528aa..1850668 100644
--- a/scripts/game/entity_system/systems/spellcasting/spell_lightningaoe.lua
+++ b/scripts/game/entity_system/systems/spellcasting/spell_lightningaoe.lua
@@ -39,10 +39,11 @@ Spells_LightningAoe = {
 		if not context.is_standalone then
 			EntityAux.set_input(caster, "character", CSME.spell_channel, true)
 			EntityAux.set_input(caster, "character", "args", "cast_area_lightning")
+			EntityAux.set_input(caster, "character", "kmf_aoe_lightning", true)
 
 			_loco_ext = entityaux_extension(caster, "locomotion")
 
-			if _loco_ext then
+			if _loco_ext and not ((_loco_ext.state and _loco_ext.state.time_flying and _loco_ext.state.time_flying > 0) and kmf.vars.bugfix_enabled) then
 				EntityAux.set_input_by_extension(_loco_ext, "disabled", true)
 			end
 		end
@@ -84,6 +85,13 @@ Spells_LightningAoe = {
 		local rotation_speed = ROTATION_SPEED * agility
 		local damage_interval = DAMAGE_INTERVAL * pvm:get_variable(caster, "lightning_interval")
 		local damage, magnitudes = SpellSettings:get_lightning_damage(pvm, caster, elements, damage_interval, true)
+		
+		-- fun-balance :: nerf ligthing aoe damage
+		if kmf.vars.funprove_enabled then
+			for k, v in pairs(damage) do
+				damage[k] = v / 2.0
+			end
+		end
 
 		assert(damage, "no damage table for spell_lightningaoe")
 		assert(magnitudes, "no magnitudes table for spell_lightningaoe")
@@ -126,6 +134,9 @@ Spells_LightningAoe = {
 			scale_damage = context.scale_damage,
 			is_standalone = context.is_standalone
 		}
+		data.kmf_is_aoe = true
+		data.kmf_targets = {}
+		data.kmf_potential_targets = {}
 
 		if data.loco_ext then
 			EntityAux.add_rotation_speed_by_extension(data.loco_ext, rotation_speed)
@@ -232,8 +243,22 @@ Spells_LightningAoe = {
 			data.overlap_done = nil
 			data.num_jumps = data.initial_num_jumps
 
-			Spells_Lightning_Helper.cast_lightning_bolt(data, data.start_pos, data.direction, context.caster, true, context.world, true, data.range, data.arc_range, data.arc_width, data.effect_table[1], context.effect_manager, 1, data.is_standalone)
-			Spells_Lightning_Helper.cast_lightning_bolt(data, data.start_pos, data.direction_neg, context.caster, true, context.world, true, data.range, data.arc_range, data.arc_width, data.effect_table[2], context.effect_manager, 1, data.is_standalone)
+			local helper_fun = nil
+
+			if kmf.vars.funprove_enabled then
+				helper_fun = Spells_Lightning_Helper.cast_lightning_bolt_obstacle_respectful
+			else
+				helper_fun = Spells_Lightning_Helper.cast_lightning_bolt
+			end
+
+			helper_fun(data, data.start_pos, data.direction, context.caster, true, context.world, true, data.range, data.arc_range, data.arc_width, data.effect_table[1], context.effect_manager, 1, data.is_standalone)
+			helper_fun(data, data.start_pos, data.direction_neg, context.caster, true, context.world, true, data.range, data.arc_range, data.arc_width, data.effect_table[2], context.effect_manager, 1, data.is_standalone)
+		end
+
+		-- fun-balance :: more lightining aoe hits
+		if kmf.vars.funprove_enabled then
+			local dt = context.dt
+			data.damage_interval = data.damage_interval - (dt * 1.5)
 		end
 
 		return true
@@ -247,6 +272,7 @@ Spells_LightningAoe = {
 
 		if not data.is_standalone then
 			EntityAux.set_input(caster, "character", CSME.spell_channel, nil)
+			EntityAux.set_input(caster, "character", "kmf_aoe_lightning", false)
 
 			local status_ext = EntityAux.extension(context.caster, "status")
 			local is_panicked = false
