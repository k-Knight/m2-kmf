diff --git a/scripts/game/entity_system/systems/spellcasting/spelltypes.lua b/scripts/game/entity_system/systems/spellcasting/spelltypes.lua
index 72fdd61..f89463b 100644
--- a/scripts/game/entity_system/systems/spellcasting/spelltypes.lua
+++ b/scripts/game/entity_system/systems/spellcasting/spelltypes.lua
@@ -90,12 +90,18 @@ function SpellTypes.self(context)
 
 			return "ArmorWard"
 		else
-			local current = context.spellcast_system:get_current_spell_name(context.caster)
+			local active_self_shield
+
+			if kmf.vars.bugfix_enabled or kmf.vars.funprove_enabled then
+				active_self_shield = context.spellcast_system:has_spell_active(context.caster, "SelfShield")
+			else
+				active_self_shield = context.spellcast_system:get_current_spell_name(context.caster) == "SelfShield"
+			end
 
 			context.spellcast_system:cancel_spell(context.caster, "SelfShield")
 			context.spellcast_system:cancel_spell(context.caster, "ArmorWard")
 
-			if current == "SelfShield" then
+			if active_self_shield then
 				return nil
 			end
 
