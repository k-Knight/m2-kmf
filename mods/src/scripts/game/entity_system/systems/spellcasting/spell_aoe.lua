diff --git a/scripts/game/entity_system/systems/spellcasting/spell_aoe.lua b/scripts/game/entity_system/systems/spellcasting/spell_aoe.lua
index 5ef132e..5b73dbc 100644
--- a/scripts/game/entity_system/systems/spellcasting/spell_aoe.lua
+++ b/scripts/game/entity_system/systems/spellcasting/spell_aoe.lua
@@ -66,7 +66,11 @@ Spells_Aoe = {
 		local pvm = context.player_variable_manager
 
 		if elements.ice > 0 then
-			range = (elements.ice > 1 and SETTINGS.aoe_max_range or SETTINGS.aoe_max_range * 0.5) * pvm:get_variable("physical_aoe_range")
+			if kmf.vars.funprove_enabled then
+				range = calculate_aoe_range(SETTINGS.aoe_min_range, SETTINGS.aoe_max_range, elements.ice) * pvm:get_variable("physical_aoe_range")
+			else
+				range = (elements.ice > 1 and SETTINGS.aoe_max_range or SETTINGS.aoe_max_range * 0.5) * pvm:get_variable("physical_aoe_range")
+			end
 			animation_event = "cast_area_ground"
 		elseif elements.earth > 0 then
 			range = calculate_aoe_range(SETTINGS.aoe_min_range, SETTINGS.aoe_max_range, elements.earth) * pvm:get_variable("physical_aoe_range")
@@ -110,6 +114,8 @@ Spells_Aoe = {
 			EntityAux.set_input(caster, "character", "args", animation_event)
 		end
 
+		data.kmf_spell_init_data_time = kmf.world_proxy:time()
+
 		return data, context.is_standalone
 	end,
 	update = function(data, context)
