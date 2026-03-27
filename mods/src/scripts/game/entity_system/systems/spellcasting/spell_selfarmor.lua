diff --git a/scripts/game/entity_system/systems/spellcasting/spell_selfarmor.lua b/scripts/game/entity_system/systems/spellcasting/spell_selfarmor.lua
index bcbf013..eafe324 100644
--- a/scripts/game/entity_system/systems/spellcasting/spell_selfarmor.lua
+++ b/scripts/game/entity_system/systems/spellcasting/spell_selfarmor.lua
@@ -109,6 +109,11 @@ Spells_SelfArmor = {
 		local elements = context.elements
 		local world = context.world
 		local caster = context.caster
+
+		if not caster then
+			return
+		end
+
 		local pvm = context.player_variable_manager
 		local spawned_units = {}
 		local us = context.unit_spawner
@@ -172,7 +177,7 @@ Spells_SelfArmor = {
 			end
 		end
 
-		if context.is_local then
+		if not kmf.vars.funprove_enabled and context.is_local then
 			EntityAux_set_input(caster, "character", CSME.spell_cast, true)
 			EntityAux_set_input(caster, "character", "args", "cast_force_shield")
 		end
@@ -191,6 +196,18 @@ Spells_SelfArmor = {
 			end
 		end
 
+		-- fun-balance :: buff armor health
+		if kmf.vars.funprove_enabled then
+			if element_healths.earth then
+				element_healths.earth = element_healths.earth * 1.5
+			end
+			if element_healths.ice then
+				element_healths.ice = element_healths.ice * 1.5
+			end
+
+			total_health = total_health * 1.5
+		end
+
 		if element_healths.earth == 0 then
 			element_healths.earth = nil
 		end
@@ -262,7 +279,15 @@ Spells_SelfArmor = {
 		local weight_mod = pvm:get_variable(caster, "armor_weight_modifier") or 1
 
 		if character_extension then
-			weight_mod = 1 + weight_mod * SpellSettings.knockdown_resist_per_armor_element * (elements.earth + elements.ice - 1)
+			-- fun-balance :: knockdown armor resistance
+			if kmf.vars.funprove_enabled then
+				local e_count = elements.earth * 2
+				local i_count = elements.ice * 2
+
+				weight_mod = 1 + weight_mod * SpellSettings.knockdown_resist_per_armor_element * (e_count + i_count - 1)
+			else
+				weight_mod = 1 + weight_mod * SpellSettings.knockdown_resist_per_armor_element * (elements.earth + elements.ice - 1)
+			end
 
 			if weight_mod ~= 1 then
 				character_extension.knockdown_limit = character_extension.knockdown_limit * weight_mod
@@ -291,6 +316,10 @@ Spells_SelfArmor = {
 	on_cast = function(data, context)
 		local caster = data.caster
 
+		if not caster then
+			return
+		end
+
 		context.effect_manager:play_sound(data.on_cast_sfx, caster)
 
 		local num_ice = data.elements.ice or 0
@@ -343,6 +372,10 @@ Spells_SelfArmor = {
 		local elements = data.elements
 		local status_ext = data.status_ext
 
+		if not caster then
+			return
+		end
+
 		if data.element_healths == nil or table.map_size(data.element_healths) == 0 then
 			if context.is_local and state.shield_running then
 				internal.health = -1
@@ -498,6 +531,11 @@ Spells_SelfArmor = {
 		local shield_ext = data.shield_ext
 		local internal = shield_ext.internal
 		local caster = data.caster
+
+		if not caster then
+			return
+		end
+
 		local world = context.world
 		local us = context.unit_spawner
 		local elements = data.elements
@@ -505,6 +543,19 @@ Spells_SelfArmor = {
 		local status_ext = data.status_ext
 		local character_extension = EntityAux.extension(caster, "character")
 		local exists = data.element_healths[element] ~= nil
+		local time = os.clock()
+
+		if damage_ext then
+			for elem, amt in pairs(elements) do
+				if elem == element then
+					if elem == "ice" then
+						damage_ext.state.selfarmored_ice_end = time
+					elseif elem == "earth" then
+						damage_ext.state.selfarmored_earth_end = time
+					end
+				end
+			end
+		end
 
 		if exists then
 			for elem, amt in pairs(elements) do
@@ -545,11 +596,19 @@ Spells_SelfArmor = {
 		end
 
 		local weight_mod = context.player_variable_manager:get_variable(caster, "armor_weight_modifier") or 1
+		local e_count = elements.earth * 2
+		local i_count = elements.ice * 2
 
 		if element == "ice" then
 			weight_mod = 1 + weight_mod * (elements.ice - 1 * SpellSettings.knockdown_resist_per_armor_element)
+			i_count = 0
 		else
 			weight_mod = 1 + weight_mod * (elements.earth - 1 * SpellSettings.knockdown_resist_per_armor_element)
+			e_count = 0
+		end
+
+		if kmf.vars.funprove_enabled then
+			weight_mod = 1 + weight_mod * SpellSettings.knockdown_resist_per_armor_element * (e_count + i_count - 1)
 		end
 
 		data.weight_mod = weight_mod
@@ -588,6 +647,12 @@ Spells_SelfArmor = {
 		end
 
 		local caster = data.caster
+
+		if not caster then
+			return
+		end
+
+		local time = os.clock()
 		local world = context.world
 		local us = context.unit_spawner
 		local elements = data.elements
@@ -598,6 +663,9 @@ Spells_SelfArmor = {
 		if damage_ext then
 			damage_ext.state.selfarmored_earth = false
 			damage_ext.state.selfarmored_ice = false
+
+			damage_ext.state.selfarmored_earth_end = time
+			damage_ext.state.selfarmored_ice_end = time
 		end
 
 		data.should_reflect_beams = false
