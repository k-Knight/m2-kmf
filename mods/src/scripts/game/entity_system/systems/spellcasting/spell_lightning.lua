diff --git a/scripts/game/entity_system/systems/spellcasting/spell_lightning.lua b/scripts/game/entity_system/systems/spellcasting/spell_lightning.lua
index b1ef7a6..d0cc5d0 100644
--- a/scripts/game/entity_system/systems/spellcasting/spell_lightning.lua
+++ b/scripts/game/entity_system/systems/spellcasting/spell_lightning.lua
@@ -131,6 +131,9 @@ Spells_Lightning = {
 			is_standalone = context.is_standalone,
 			spell_source = context.spell_source
 		}
+		data.kmf_is_aoe = false
+		data.kmf_targets = {}
+		data.kmf_potential_targets = {}
 
 		if data.loco_ext then
 			EntityAux.add_rotation_speed_by_extension(data.loco_ext, rotation_speed)
@@ -253,13 +256,27 @@ Spells_Lightning = {
 			data.did_damage_caster = nil
 			data.num_jumps = data.initial_num_jumps
 
-			Spells_Lightning_Helper.cast_lightning_bolt(data, data.start_pos, data.direction, data.caster, true, context.world, true, data.range, data.arc_range, data.arc_width, data.effect_table, context.effect_manager, 1, data.is_standalone)
+			local helper_fun = nil
+
+			if kmf.vars.funprove_enabled then
+				helper_fun = Spells_Lightning_Helper.cast_lightning_bolt_obstacle_respectful
+			else
+				helper_fun = Spells_Lightning_Helper.cast_lightning_bolt
+			end
+
+			helper_fun(data, data.start_pos, data.direction, data.caster, true, context.world, true, data.range, data.arc_range, data.arc_width, data.effect_table, context.effect_manager, 1, data.is_standalone)
 		end
 
 		if not data.is_standalone and not context.spell_channel and data.atleast_once and not data.pending_cancel then
 			data.pending_cancel = true
 		end
 
+		-- fun-balance :: more lightining hits
+		if kmf.vars.funprove_enabled then
+			local dt = context.dt
+			data.damage_interval = data.damage_interval - (dt * 1.5)
+		end
+
 		return true
 	end,
 	on_cancel = function(data, context)
