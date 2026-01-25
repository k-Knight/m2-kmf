diff --git a/scripts/game/entity_system/systems/character/character_state_knockeddown.lua b/scripts/game/entity_system/systems/character/character_state_knockeddown.lua
index 35e986a..65811a0 100644
--- a/scripts/game/entity_system/systems/character/character_state_knockeddown.lua
+++ b/scripts/game/entity_system/systems/character/character_state_knockeddown.lua
@@ -20,6 +20,7 @@ local cancel_spell_list = {
 
 function CharacterStateKnockedDown:on_enter()
 	local unit = self._unit
+	self._duration = 0
 
 	self:animation_event("knockdown")
 
@@ -34,6 +35,15 @@ function CharacterStateKnockedDown:on_enter()
 
 	EntityAux.set_input_by_extension(loco_ext, "disabled", true)
 	EntityAux.set_input(unit, "character", "stop_move_destination", true)
+
+	self.spellcast_input_restrictions = {
+		melee_attack = true,
+		imbue_weapon = true,
+		cast_magick = true,
+		spell_forward = true,
+		spell_aoe = true,
+		spell_self = true
+	}
 end
 
 function CharacterStateKnockedDown:update(context)
@@ -41,6 +51,7 @@ function CharacterStateKnockedDown:update(context)
 	local unit = self._unit
 	local csm = self._csm
 	local input = context.input
+	self._duration = self._duration + (context.dt or 0)
 
 	input.knockdown = false
 
@@ -53,6 +64,26 @@ function CharacterStateKnockedDown:update(context)
 
 		csm:change_state("move_towards")
 	end
+
+	-- fun-balance :: allow element entry in kocked-down state
+	if kmf.vars.funprove_enabled and context.input_data and self._duration > 0.33 then
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
+		if self._duration > 0.66 then
+			self.spellcast_input_restrictions.spell_self = false
+		end
+
+		self:handle_spellwheel_input(unit, context.input_data, context.internal, self.spellcast_input_restrictions)
+	end
 end
 
 function CharacterStateKnockedDown:on_exit()
