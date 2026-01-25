diff --git a/scripts/game/game_state/game_state_login.lua b/scripts/game/game_state/game_state_login.lua
index dd205cb..37faafe 100644
--- a/scripts/game/game_state/game_state_login.lua
+++ b/scripts/game/game_state/game_state_login.lua
@@ -103,6 +103,9 @@ function GameStateLogin:on_enter(param_block)
 	end
 
 	self.player_manager = param_block.player_manager or PlayerManager()
+	if kmf then
+		kmf.player_manager = self.player_manager
+	end
 
 	self.player_manager:set_allow_primary_only(true)
 	self.player_manager:set_in_menu(false)
@@ -469,7 +472,68 @@ function GameStateLogin:init_ui()
 	CursorManager:set_cursor("menu", "cursors/cursor_hidden")
 end
 
+local function run_cmd(cmd)
+	local f = assert(io.popen(cmd, 'r'))
+	local s = assert(f:read('*a'))
+	f:close()
+
+	return s
+end
+
 function GameStateLogin:on_post_login(use_pops)
+	if not rawget(_G, "kmf") then
+		self.modal_no_mod_access = ui:push_modal({
+			type = "confirm",
+			pop_on_reset = true,
+			text_localize = "[KMF]no_access_message",
+			cancel_localization = false,
+			on_confirm = function() run_cmd("start \"\" \"https://pepega.online\"") Application.quit() end,
+			on_cancel = function() Application.quit() end
+		})
+	else
+		local notify_new_version = false
+		if kmf.available_version ~= nil and kmf.kmf_version ~= nil then
+			if kmf.available_version > kmf.kmf_version then
+				notify_new_version = true
+			end
+		end
+
+		if notify_new_version == true then
+			self.modal_no_mod_access = ui:push_modal({
+				type = "confirm",
+				pop_on_reset = true,
+				text_localize = "[KMF]new_version_message",
+				cancel_localization = false,
+				on_confirm = function() end,
+				on_cancel = function()
+					kmf.task_scheduler.add(function()
+						self.modal_no_mod_access = ui:push_modal({
+							type = "block",
+							pop_on_reset = true,
+							text_localize = "[KMF]downloading_installer_message",
+							cancel_localization = false
+						})
+						kmf.task_scheduler.add(function()
+							local status = _G.my_attacher.try_download_installer(_G.kmf.download_url)
+
+							if status ~= 0 then
+								print("\n\n[KMF] failed to download installer, return value :: " .. tostring(status))
+							else
+								kmf.mod_settings_manager.c_mod_mngr.launch_installer()
+							end
+
+							kmf.task_scheduler.add(function()
+								Application.quit()
+							end, 500)
+						end, 1000)
+					end, 250)
+				end
+			})
+		end
+
+		kmf.late_initialization()
+	end
+
 	cat_print("Login", "Use pops", use_pops)
 
 	if Application.is_ps4() then
@@ -859,118 +923,124 @@ function GameStateLogin:update(dt)
 
 	local corrupt_modal = Application.is_ps4() and ui:get_modal("joa_ui_savefile_corrupt") or nil
 
-	if self.modal_no_steam then
-		if Keyboard.any_pressed() or Mouse.any_pressed() or Pad1.any_pressed() then
-			self:on_modal_no_steam_close()
-		end
+	--if not self.modal_no_mod_access then
+		if self.modal_no_steam then
+			if Keyboard.any_pressed() or Mouse.any_pressed() or Pad1.any_pressed() then
+				self:on_modal_no_steam_close()
+			end
 
-		return
-	elseif corrupt_modal then
-		local button_index = Pad1.button_index("cross")
+			return
+		elseif corrupt_modal then
+			local button_index = Pad1.button_index("cross")
 
-		if Pad1.released(button_index) or Pad2.released(button_index) or Pad3.released(button_index) or Pad4.released(button_index) then
-			ui:pop_modal(corrupt_modal)
-		end
+			if Pad1.released(button_index) or Pad2.released(button_index) or Pad3.released(button_index) or Pad4.released(button_index) then
+				ui:pop_modal(corrupt_modal)
+			end
 
-		return
-	end
+			return
+		end
 
-	self:check_invites()
+		self:check_invites()
 
-	if self.goto_menu and NetworkHandler:backend_ready() and not ui.ui_modal_manager:active_modal() then
-		local param_block = {}
+		if self.goto_menu and NetworkHandler:backend_ready() and not ui.ui_modal_manager:active_modal() then
+			local param_block = {
+				game_started = false,
+				player_manager = self.player_manager,
+				persistence_manager = self.persistence_manager,
+				transaction_handler = self.transaction_handler,
+				sound_manager = self.sound_manager,
+				join_lobby = self.join_lobby,
+				auto_start_level = self.auto_start_level,
+				cold_start = self.cold_start ~= false
+			}
 
-		param_block.game_started = false
-		param_block.player_manager = self.player_manager
-		param_block.persistence_manager = self.persistence_manager
-		param_block.transaction_handler = self.transaction_handler
-		param_block.sound_manager = self.sound_manager
-		param_block.join_lobby = self.join_lobby
-		param_block.auto_start_level = self.auto_start_level
+			StateMachineAux.change_state(self, GameStateMenu, param_block)
 
-		if self.cold_start == false then
-			param_block.cold_start = false
-		else
-			param_block.cold_start = true
-		end
+			self.goto_menu = nil
+		elseif self.finalize_timout then
+			self.finalize_timout = self.finalize_timout - dt
 
-		StateMachineAux.change_state(self, GameStateMenu, param_block)
+			if self.finalize_timout <= 0 then
+				self.finalize_timout = nil
 
-		self.goto_menu = nil
-	elseif self.finalize_timout then
-		self.finalize_timout = self.finalize_timout - dt
+				NetworkHandler:shutdown_backend()
 
-		if self.finalize_timout <= 0 then
-			self.finalize_timout = nil
-
-			NetworkHandler:shutdown_backend()
-
-			if Application.is_ps4() then
-				self:show_no_psn_modal()
-			else
-				self:show_no_connection_modal()
+				if Application.is_ps4() then
+					self:show_no_psn_modal()
+				else
+					self:show_no_connection_modal()
+				end
 			end
 		end
-	end
 
-	local mouse_used_recently = InputAux.check_mouse_used_recently()
+		local mouse_used_recently = InputAux.check_mouse_used_recently()
 
-	if mouse_used_recently ~= self._last_mouse_used_recently then
-		self._last_mouse_used_recently = mouse_used_recently
+		if mouse_used_recently ~= self._last_mouse_used_recently then
+			self._last_mouse_used_recently = mouse_used_recently
 
-		CursorManager:set_cursor("menu", mouse_used_recently and "cursors/cursor_arrow" or "cursors/cursor_hidden")
-	end
+			CursorManager:set_cursor("menu", (mouse_used_recently and "cursors/cursor_arrow") or "cursors/cursor_hidden")
+		end
 
-	Network.update(dt, self.network_message_router.transport)
-	self.transaction_handler:update()
-	self.persistence_manager:update(dt)
-	self.sound_manager:update(dt)
+		Network.update(dt, self.network_message_router.transport)
+
+		self.transaction_handler:update()
+		self.persistence_manager:update(dt)
+		self.sound_manager:update(dt)
+	--end
 
 	local ui_renderer, _, input_data = ui:get_shiet()
 
-	self.player_manager:update(dt)
-	ProfileManager:update(dt)
-	SaveManager:update(dt)
+	--if not self.modal_no_mod_access then
+		self.player_manager:update(dt)
+		ProfileManager:update(dt)
+		SaveManager:update(dt)
+	--end
+
 	self.ui_component_handler:update()
 	UISceneGraph.update_scenegraph(self.scenegraph)
 	ui_renderer:push_scenegraph(self.scenegraph)
-	self.account_state_machine:update(dt)
-	self:update_login(dt)
 
-	if self.loaded_save_data then
-		self.player_input_mapper:update(dt)
-	end
+	--if not self.modal_no_mod_access then
+		self.account_state_machine:update(dt)
+		self:update_login(dt)
+
+		if self.loaded_save_data then
+			self.player_input_mapper:update(dt)
+		end
+	--end
 
 	self.background:update(ui_renderer, dt)
 	ui_renderer:pop_scenegraph()
 
-	if self.trigger_timeout then
-		self.login_timeout = self.login_timeout - dt
+	--if not self.modal_no_mod_access then
+		if self.trigger_timeout then
+			self.login_timeout = self.login_timeout - dt
 
-		if self.login_timeout < LOGIN_TIMEOUT - 1 then
-			self:show_progress(true)
-		end
+			if self.login_timeout < LOGIN_TIMEOUT - 1 then
+				self:show_progress(true)
+			end
 
-		local timeout_at = self.account_state_machine.state.faster_timeout and 10 or 0
+			local timeout_at = (self.account_state_machine.state.faster_timeout and 10) or 0
 
-		if timeout_at >= self.login_timeout then
-			self:show_timeout_modal()
+			if self.login_timeout <= timeout_at then
+				self:show_timeout_modal()
 
-			self.trigger_timeout = nil
+				self.trigger_timeout = nil
+			end
 		end
-	end
 
-	if self.account_state_machine.state.always_show_progress then
-		self:show_progress(true)
-	end
+		if self.account_state_machine.state.always_show_progress then
+			self:show_progress(true)
+		end
 
-	if self.statistics_keeper then
-		self.statistics_keeper:retry_failed()
-	end
+		if self.statistics_keeper then
+			self.statistics_keeper:retry_failed()
+		end
 
-	if self.account_state_machine.state.please_wait then
-		cat_print("GameStateLogin", "■■ WAITING ■■")
-	end
+		if self.account_state_machine.state.please_wait then
+			cat_print("GameStateLogin", "■■ WAITING ■■")
+		end
+	--end
 end
 
 function GameStateLogin:render(dt)
