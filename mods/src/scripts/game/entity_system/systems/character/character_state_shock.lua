diff --git a/scripts/game/entity_system/systems/character/character_state_shock.lua b/scripts/game/entity_system/systems/character/character_state_shock.lua
index db7908c..5c386e5 100644
--- a/scripts/game/entity_system/systems/character/character_state_shock.lua
+++ b/scripts/game/entity_system/systems/character/character_state_shock.lua
@@ -7,7 +7,14 @@ function CharacterStateShock:init(context)
 end
 
 function CharacterStateShock:on_enter(args)
-	return
+	self.spellcast_input_restrictions = {
+		imbue_weapon = true,
+		spell_self = true,
+		melee_attack = true,
+		spell_aoe = true,
+		spell_forward = true,
+		cast_magick = true
+	}
 end
 
 function CharacterStateShock:on_exit()
@@ -17,6 +24,7 @@ end
 function CharacterStateShock:update(context)
 	local input = context.input
 	local csm = self._csm
+	local unit = self._unit
 
 	if input.die then
 		csm:change_state("dead")
@@ -35,6 +43,22 @@ function CharacterStateShock:update(context)
 			csm:change_state("onground")
 		end
 	end
+
+	-- fun-balance :: allow element entry in shocked state
+	if kmf.vars.funprove_enabled and context.input_data then
+		local input_data = {
+			water = context.input_data.water,
+			life = context.input_data.life,
+			shield = context.input_data.shield,
+			cold = context.input_data.cold,
+			lightning = context.input_data.lightning,
+			arcane = context.input_data.arcane,
+			earth = context.input_data.earth,
+			fire = context.input_data.fire
+		}
+
+		self:handle_spellwheel_input(unit, context.input_data, context.internal, self.spellcast_input_restrictions)
+	end
 end
 
 function CharacterStateShock:animation_completed(context)
