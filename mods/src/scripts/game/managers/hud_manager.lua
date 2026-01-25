diff --git a/scripts/game/managers/hud_manager.lua b/scripts/game/managers/hud_manager.lua
index a8d2892..73c0a4c 100644
--- a/scripts/game/managers/hud_manager.lua
+++ b/scripts/game/managers/hud_manager.lua
@@ -327,6 +327,9 @@ function HudManager:init(context)
 	self.challenge_gamemode = context.challenge_gamemode
 	self.unit_storage = context.unit_storage
 
+	kmf.hud_manager = self
+	self.player_hud_init_data = {}
+
 	self:init_ui()
 
 	self.shading_environment_manager = context.shading_environment_manager
@@ -620,7 +623,7 @@ function HudManager:show_endgame_victory(show)
 end
 
 function HudManager:create_encounter(sender, encounter_id, animated_bar, bar_type_id)
-	if self.encounter_bar then
+	if self.encounter_bar or kmf.vars.pvp_gamemode then
 		return
 	end
 
@@ -648,6 +651,10 @@ function HudManager:sync_encounter_state(peer)
 end
 
 function HudManager:sync_encounter_bar(sender, encounter_id, bar_type_id)
+	if kmf.vars.pvp_gamemode then
+		return
+	end
+
 	local bar_type = NetworkLookup.bar_type_id[bar_type_id] or ""
 	local context = {
 		animated_bar = false,
@@ -703,6 +710,10 @@ function HudManager:lok_ball_destroyed(sender, name)
 end
 
 function HudManager:start_encounter()
+	if kmf.vars.pvp_gamemode then
+		return
+	end
+
 	assert(self.encounter_bar, "Start Encounter: No encounter created!")
 
 	if self.encounter_bar then
@@ -719,6 +730,10 @@ function HudManager:start_encounter()
 end
 
 function HudManager:stop_encounter()
+	if kmf.vars.pvp_gamemode then
+		return
+	end
+
 	if self.encounter_bar then
 		self.encounter_bar = nil
 
@@ -826,8 +841,16 @@ function HudManager:init_player_ui(is_local_player, local_player_id, global_play
 			UIElement.set_first(self.gpad_magicks_menu_components[ctrl_index], "scenegraph", "scene_name", control_bar)
 		end
 
-		local is_keyboard = is_local_player and self.player_manager:try_get_input_controller(local_player_id) == "keyboard" or false
-		local frame = UIElement(PlayerFrameLayout)
+		local is_keyboard = (is_local_player and self.player_manager:try_get_input_controller(local_player_id) == "keyboard") or false
+		local layout = table.deep_clone(PlayerFrameLayout)
+		if kmf.check_mod_enabled("remove magick hud") then
+			local act_w, act_h = Application.resolution()
+			local w_coef = (act_w - 1280) / 1280
+			local h_coef = (act_h - 720) / 720
+
+			layout.passes[2].offset = {(-40 + (130 * w_coef)) + ((-132 + (262 * w_coef)) * (ctrl_index - 1)), -5 + (10 * h_coef), 0}
+		end
+		local frame = UIElement(layout)
 
 		frame:set("scenegraph", "scene_name", control_bar)
 		frame:set("revive_button_icon", "size", is_keyboard and {
@@ -1088,6 +1111,15 @@ function HudManager:add_player_hud(u, magicks, magick_ext, is_local_player, loca
 	local spellwheel_ext = EntityAux.extension(u, "spellwheel")
 	local input_ext = EntityAux.extension(u, "input_controller")
 	local health_state = EntityAux.state(u, "health")
+
+	self.player_hud_init_data[global_player_id] = {
+		u = u,
+		magicks = magicks,
+		magick_ext = magick_ext,
+		is_local_player = is_local_player,
+		local_player_id = local_player_id
+	}
+
 	local player_data = {
 		gamepad_gui_index = -1,
 		magick_gui_index = -1,
@@ -1131,23 +1163,31 @@ function HudManager:add_player_hud(u, magicks, magick_ext, is_local_player, loca
 		unit_storage = self.unit_storage
 	}
 
-	self.hud_magicks[player_data.ctrl_index] = HudMagicks(hud_magicks_context)
+	if is_local_player then
+		kmf.vars.local_player_input_ext = input_ext
+	end
 
-	for _, hudmagicks in pairs(self.hud_magicks) do
-		local highlighted_magick_tiers = hudmagicks.highlighted_magick_tiers
+	if not kmf.check_mod_enabled("remove magick hud") then
+		self.hud_magicks[player_data.ctrl_index] = HudMagicks(hud_magicks_context)
 
-		if hudmagicks ~= self.hud_magicks[player_data.ctrl_index] then
-			self.hud_magicks[player_data.ctrl_index]:highlight_gui(highlighted_magick_tiers)
+		for _, hudmagicks in pairs(self.hud_magicks) do
+			local highlighted_magick_tiers = hudmagicks.highlighted_magick_tiers
 
-			self.hud_magicks[player_data.ctrl_index].magick_tier_highlight_value = hudmagicks.magick_tier_highlight_value
+			if hudmagicks ~= self.hud_magicks[player_data.ctrl_index] then
+				self.hud_magicks[player_data.ctrl_index]:highlight_gui(highlighted_magick_tiers)
 
-			break
-		elseif self.synced_magick_tiers then
-			self.hud_magicks[player_data.ctrl_index]:highlight_gui(self.synced_magick_tiers)
+				self.hud_magicks[player_data.ctrl_index].magick_tier_highlight_value = hudmagicks.magick_tier_highlight_value
 
-			self.hud_magicks[player_data.ctrl_index].magick_tier_highlight_value = hudmagicks.magick_tier_highlight_value
-			self.synced_magick_tiers = nil
+				break
+			elseif self.synced_magick_tiers then
+				self.hud_magicks[player_data.ctrl_index]:highlight_gui(self.synced_magick_tiers)
+
+				self.hud_magicks[player_data.ctrl_index].magick_tier_highlight_value = hudmagicks.magick_tier_highlight_value
+				self.synced_magick_tiers = nil
+			end
 		end
+	else
+		self.hud_magicks[player_data.ctrl_index] = HudMagickMock.create_magick_list(hud_magicks_context)
 	end
 
 	self.unit_to_gui_index[u] = player_data.ctrl_index
@@ -1457,15 +1497,11 @@ function HudManager:update_player_huds(dt, input_data)
 								frame:set("chilled_and_wet", "current_frame", 1)
 
 								local color = frame:get("chilled_and_wet", "color")
-
 								color[1] = 0
 							else
 								local alpha = frame:get("chilled_and_wet", "color")[1]
-
 								alpha = alpha + dt * STATUS_FADE_SPEED
-
 								local color = frame:get("chilled_and_wet", "color")
-
 								color[1] = math.min(alpha, 255)
 							end
 						elseif status_name ~= "shocked" and frame:has_pass(status_name) then
@@ -1474,15 +1510,11 @@ function HudManager:update_player_huds(dt, input_data)
 								frame:set(status_name, "current_frame", 1)
 
 								local color = frame:get(status_name, "color")
-
 								color[1] = 0
 							else
 								local alpha = frame:get(status_name, "color")[1]
-
 								alpha = alpha + dt * STATUS_FADE_SPEED
-
 								local color = frame:get(status_name, "color")
-
 								color[1] = math.min(alpha, 255)
 							end
 						end
@@ -1493,11 +1525,8 @@ function HudManager:update_player_huds(dt, input_data)
 
 						if (not status[status_name] or status_name == "chilled_and_wet" and (not status.chilled or not status.wet)) and frame:get_pass_enabled(status_name) then
 							local alpha = frame:get(status_name, "color")[1]
-
 							alpha = alpha - dt * STATUS_FADE_SPEED
-
 							local color = frame:get(status_name, "color")
-
 							color[1] = math.max(alpha, 0)
 
 							if alpha <= 0 then
