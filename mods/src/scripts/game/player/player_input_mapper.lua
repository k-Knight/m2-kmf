diff --git a/scripts/game/player/player_input_mapper.lua b/scripts/game/player/player_input_mapper.lua
index 154fb97..b3eaae9 100644
--- a/scripts/game/player/player_input_mapper.lua
+++ b/scripts/game/player/player_input_mapper.lua
@@ -103,9 +103,17 @@ function PlayerInputMapper:update_controller_activation(dt)
 		assert(player_controller)
 
 		local disabled = self.disabled_controllers[player_controller]
+		if input.override_disabled then
+			kmf_print("    using override_disabled")
+			input.override_disabled = false
+			disabled = false
+		elseif kmf.vars.res_spec_sm.state == "spec" or kmf.vars.res_spec_sm.state == "go_spec" then
+			disabled = true
+		end
 
 		if not disabled and self._queued_sign_in_controller == nil and input and (input.activate or i == self.auto_sign_in_input or self.auto_sign_in_user and self.auto_sign_in_user == input.user_id) and not self._player_manager:is_controller_mapped(player_controller) then
-			cat_print("PlayerInputMapper", "Sign in request")
+			kmf_print("activating controller !!!")
+			kmf.vars.res_spec_sm.last_activated_controller = i
 
 			local free_slot = self._player_manager:first_free_local_slot()
 
