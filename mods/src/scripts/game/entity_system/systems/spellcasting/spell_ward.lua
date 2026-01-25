diff --git a/scripts/game/entity_system/systems/spellcasting/spell_ward.lua b/scripts/game/entity_system/systems/spellcasting/spell_ward.lua
index 8e1d276..da7943e 100644
--- a/scripts/game/entity_system/systems/spellcasting/spell_ward.lua
+++ b/scripts/game/entity_system/systems/spellcasting/spell_ward.lua
@@ -180,8 +180,10 @@ Spells_Ward = {
 		end
 
 		if context.is_local then
-			EntityAux_set_input(caster, "character", CSME.spell_cast, true)
-			EntityAux_set_input(caster, "character", "args", "cast_force_shield")
+			if not kmf.vars.funprove_enabled then
+				EntityAux_set_input(caster, "character", CSME.spell_cast, true)
+				EntityAux_set_input(caster, "character", "args", "cast_force_shield")
+			end
 
 			if types ~= nil then
 				local buffs = context.state.buffs
