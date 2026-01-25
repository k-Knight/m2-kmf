diff --git a/scripts/game/entity_system/systems/spellcasting/spell_selfarmor.lua b/scripts/game/entity_system/systems/spellcasting/spell_selfarmor.lua
index bcbf013..ce549ba 100644
--- a/scripts/game/entity_system/systems/spellcasting/spell_selfarmor.lua
+++ b/scripts/game/entity_system/systems/spellcasting/spell_selfarmor.lua
@@ -172,7 +172,7 @@ Spells_SelfArmor = {
 			end
 		end
 
-		if context.is_local then
+		if not kmf.vars.funprove_enabled and context.is_local then
 			EntityAux_set_input(caster, "character", CSME.spell_cast, true)
 			EntityAux_set_input(caster, "character", "args", "cast_force_shield")
 		end
@@ -191,6 +191,18 @@ Spells_SelfArmor = {
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
@@ -262,7 +274,15 @@ Spells_SelfArmor = {
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
@@ -545,11 +565,19 @@ Spells_SelfArmor = {
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
