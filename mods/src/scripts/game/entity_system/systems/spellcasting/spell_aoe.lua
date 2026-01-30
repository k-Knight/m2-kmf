diff --git a/scripts/game/entity_system/systems/spellcasting/spell_aoe.lua b/scripts/game/entity_system/systems/spellcasting/spell_aoe.lua
index 5ef132e..0e9acd6 100644
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
@@ -154,7 +160,7 @@ Spells_Aoe = {
 					if EntityAux.extension(u, "damage_receiver") then
 						ATTACKERS_TABLE[1] = caster
 
-						EntityAux.add_damage(u, ATTACKERS_TABLE, damage, "aoe", data.scale_damage, position)
+						EntityAux.add_damage(u, ATTACKERS_TABLE, damage, {"aoe", "aoe"}, data.scale_damage, position)
 					end
 
 					local status_ext = EntityAux.extension(u, "status")
