diff --git a/scripts/game/entity_system/systems/character/character_state_inair.lua b/scripts/game/entity_system/systems/character/character_state_inair.lua
index fb0ddc6..f34bf12 100644
--- a/scripts/game/entity_system/systems/character/character_state_inair.lua
+++ b/scripts/game/entity_system/systems/character/character_state_inair.lua
@@ -15,9 +15,34 @@ function CharacterStateInAir:on_enter()
 		melee_attack = true,
 		spell_aoe = true
 	}
+
+	self.kmf_enter_time = kmf.world_proxy:time()
 end
 
 function CharacterStateInAir:on_exit()
+	local exit_time = kmf.world_proxy:time()
+	local unit = self._unit
+
+	local remove_push_elevate_res
+	remove_push_elevate_res = function()
+		local time = kmf.world_proxy:time()
+		local t_left = 0.5 - (time - exit_time)
+
+		if t_left > 0 then
+			kmf.task_scheduler.add(remove_push_elevate_res, t_left)
+		else
+			if unit and Unit.alive(unit) then
+				local char_ext = EntityAux.extension(unit, "character")
+
+				if char_ext then
+					char_ext.internal.kmf_push_elevate_resist = nil
+				end
+			end
+		end
+	end
+
+	kmf.task_scheduler.add(remove_push_elevate_res, 500)
+
 	return
 end
 
@@ -26,6 +51,19 @@ function CharacterStateInAir:update(context)
 	local loco_state = context.internal.loco_ext.state
 	local csm = self._csm
 	local input = context.input
+	local time = kmf.world_proxy:time()
+	local t_diff = time - self.kmf_enter_time
+
+	if t_diff > 0.5 then
+		local res = 1.0 - ((t_diff - 0.25) * 1.33)
+		local char_ext = EntityAux.extension(unit, "character")
+
+		res = res < 0 and 0 or res
+
+		if char_ext then
+			char_ext.internal.kmf_push_elevate_resist = res
+		end
+	end
 
 	self:handle_spellwheel_input(unit, context.input_data, context.internal, self.spellcast_input_restrictions)
 
