diff --git a/scripts/game/game_state/game_state_ingame.lua b/scripts/game/game_state/game_state_ingame.lua
index 0fe3dbc..053d6b2 100644
--- a/scripts/game/game_state/game_state_ingame.lua
+++ b/scripts/game/game_state/game_state_ingame.lua
@@ -32,22 +32,56 @@ local TIME_CHALLENGE_CLOCK_FINAL = "ui_signal_countdown_final"
 GameStateInGame = class(GameStateInGame)
 GameStateInGame.state_name = "GameStateInGame"
 
+function GameStateInGame:soft_assert_back_to_menu(str, condition)
+	if not condition then
+		kmf_print("GameStateInGame:on_enter() assertion failed :: " .. str)
+		StateMachineAux.change_state(self, GameStateMenu, self.param_block)
+	end
+end
+
+kmf.heal_funnE_units = function()
+	kmf.task_scheduler.add(kmf.heal_funnE_units, 500)
+
+	if kmf.vars.pvp_gamemode and kmf.game_state_in_game and kmf.vars.level_funnE_units then
+		for _, unit in ipairs(kmf.vars.level_funnE_units) do
+			if unit then
+				local health_ext = EntityAux.extension(unit, "health")
+
+				if health_ext then
+					if health_ext.internal and health_ext.internal.health > 0 then
+						health_ext.internal.max_health = 32000
+						health_ext.internal.health = 32000
+					end
+					if health_ext.state and health_ext.state.health > 0  then
+						health_ext.state.max_health = 32000
+						health_ext.state.health = 32000
+						health_ext.state.original_max_health = 32000
+					end
+				end
+			end
+		end
+	end
+end
+
 function GameStateInGame:on_enter(param_block)
+	kmf.check_funbalance_unlocks()
 	cat_print("GameStateInGame", "on_enter")
-	assert(param_block.level_name ~= nil)
-	assert(param_block.level_name_short ~= nil)
-	assert(param_block.player_manager ~= nil)
-	assert(param_block.level_package ~= nil)
-	assert(param_block.game_settings)
-	assert(param_block.game_settings.game_mode)
-	assert(param_block.game_settings.artifact_setting)
-	assert(param_block.persistence_manager)
-	assert(param_block.transaction_handler)
-	assert(param_block.sound_manager)
+	self.param_block = param_block
+
+	self:soft_assert_back_to_menu("param_block.level_name ~= nil", param_block.level_name ~= nil)
+	self:soft_assert_back_to_menu("param_block.level_name_short ~= nil", param_block.level_name_short ~= nil)
+	self:soft_assert_back_to_menu("param_block.player_manager ~= nil", param_block.player_manager ~= nil)
+	self:soft_assert_back_to_menu("param_block.level_package ~= nil", param_block.level_package ~= nil)
+	self:soft_assert_back_to_menu("param_block.game_settings", param_block.game_settings)
+	self:soft_assert_back_to_menu("param_block.game_settings.game_mode", param_block.game_settings.game_mode)
+	self:soft_assert_back_to_menu("param_block.game_settings.artifact_setting", param_block.game_settings.artifact_setting)
+	self:soft_assert_back_to_menu("param_block.persistence_manager", param_block.persistence_manager)
+	self:soft_assert_back_to_menu("param_block.transaction_handler", param_block.transaction_handler)
+	self:soft_assert_back_to_menu("param_block.sound_manager", param_block.sound_manager)
 
 	if param_block.game_settings.game_mode == "challenge" then
-		assert(param_block.game_settings.challenge_id)
-		assert(param_block.game_settings.challenge_name)
+		self:soft_assert_back_to_menu("param_block.game_settings.challenge_id", param_block.game_settings.challenge_id)
+		self:soft_assert_back_to_menu("param_block.game_settings.challenge_name", param_block.game_settings.challenge_name)
 
 		self.creator_mode = param_block.game_settings.creator_mode
 		self.creator_mode_flag = param_block.game_settings.creator_mode_flag
@@ -71,7 +105,7 @@ function GameStateInGame:on_enter(param_block)
 	self.story = param_block.story
 	self.level_name = param_block.level_name
 	self.level_name_short = param_block.level_name_short
-	self.param_block = param_block
+	self.package_manager = self.context.package_manager
 	self.ingame_context = param_block
 	self.world_name = "game_world"
 	self.transaction_handler = param_block.transaction_handler
@@ -105,6 +139,7 @@ function GameStateInGame:on_enter(param_block)
 	self:_setup_world()
 
 	self.player_input_mapper = PlayerInputMapper(self.player_manager)
+	kmf.player_input_mapper = self.player_input_mapper
 
 	self.player_input_mapper:set_disable_keyboard(true)
 
@@ -116,10 +151,20 @@ function GameStateInGame:on_enter(param_block)
 	self:_setup_gui_systems()
 	self:_post_setup_game_handler()
 
+	kmf.game_state_in_game = self
+	kmf.vars.net_dmg_states = {}
+	kmf.update_magick_cds()
+	kmf.game_world = self.world
+	kmf.apply_spell_settings_patches()
+
 	if self.game_mode == "challenge" then
+		if self.world._timpani_world then
+			self.world._timpani_world = World.timpani_world(self.world._world)
+		end
+
 		self.timpani_world = self.world._timpani_world
 
-		assert(self.timpani_world, "TimpaniWorld needed for TimeChallenges !")
+		self:soft_assert_back_to_menu("TimpaniWorld needed for TimeChallenges !", self.timpani_world)
 	end
 
 	self:_setup_debug()
@@ -151,6 +196,28 @@ function GameStateInGame:on_enter(param_block)
 	self:_create_entity_system(self.game_handler)
 	self:_setup_entity_system()
 
+	if not kmf.initialized_heal_funnE_units then
+		kmf.initialized_heal_funnE_units = true
+
+		kmf.task_scheduler.add(kmf.heal_funnE_units, 500)
+	end
+
+	kmf.vars.level_init_units = self.world:level():units()
+	kmf.vars.level_funnE_units = {}
+
+	kmf.task_scheduler.add(function()
+		for _, unit in ipairs(kmf.vars.level_init_units) do
+			if unit then
+				local health_ext = EntityAux.extension(unit, "health")
+
+				if health_ext and health_ext.internal and health_ext.internal.max_health > 2000 then
+					local funnE_arr = kmf.vars.level_funnE_units
+					funnE_arr[#funnE_arr + 1] = unit
+				end
+			end
+		end
+	end, 3000)
+
 	local state_params = {
 		viewport_name = "players",
 		parent = self,
@@ -165,6 +232,8 @@ function GameStateInGame:on_enter(param_block)
 		entity_manager = self.entity_system.entity_manager
 	}
 
+	kmf.entity_manager = state_params.entity_manager
+
 	self.ingame_machine = StateMachine(self, "game", StateInGameRunning, state_params)
 
 	self:set_update_function_name("update_waiting_for_connection")
@@ -206,7 +275,6 @@ function GameStateInGame:on_enter(param_block)
 end
 
 function GameStateInGame:on_exit()
-	cat_print("GameStateInGame", "on_exit()")
 	self.network_lobby_handler_event_delegate:unregister("GameStateInGame")
 	self.network_handler_event_delegate:unregister("GameStateInGame")
 
@@ -215,10 +283,19 @@ function GameStateInGame:on_exit()
 		self.lobby_handler:push_data()
 	end
 
+	kmf_print("resetting pvp gamemode locally")
+	kmf.vars.pvp_gamemode = false
+	kmf.player_input_mapper = nil
+	kmf.entity_manager = nil
+
 	if Application.is_ps4() and NetworkHandler:get_backend_type() == "PSN" then
 		NetworkPSNAux:report_realtime_usage(false)
 	end
 
+	kmf.game_state_in_game = nil
+	kmf.game_world = nil
+	kmf.beam_system = nil
+
 	Debug.teardown()
 	ui:reset()
 	ui:set_world_to_frontend()
@@ -286,7 +363,8 @@ function GameStateInGame:init_menu_ui()
 		player_input_mapper = self.player_input_mapper,
 		persistence_manager = self.persistence_manager,
 		game = self,
-		game_mode = self.game_mode
+		game_mode = self.game_mode,
+		package_manager = self.package_manager
 	})
 
 	ui:activate_scene_update(true)
@@ -299,7 +377,7 @@ function GameStateInGame:init_menu_ui()
 		self.chat_ui = self.ui_component_handler:components()[1]
 	end
 
-	self.ui_component_handler:register_components({
+	local ui_components = {
 		require("scripts/game/menu2/ingame_menu_ui"),
 		require("scripts/game/menu2/menu_navigation_ui"),
 		require("scripts/game/menu2/menu_player_slots_ui"),
@@ -307,8 +385,17 @@ function GameStateInGame:init_menu_ui()
 		require("scripts/game/menu2/menu_settings_gameplay_ui"),
 		require("scripts/game/menu2/menu_settings_graphics_ui"),
 		require("scripts/game/menu2/menu_settings_audio_ui"),
-		require("scripts/game/menu2/menu_settings_keybindings_ui")
-	})
+		require("scripts/game/menu2/menu_settings_keybindings_ui"),
+		require("scripts/game/menu2/menu_equipment_ui"),
+		require("scripts/game/menu2/menu_equipment_robe_ui"),
+		require("scripts/game/menu2/menu_equipment_variant_ui"),
+		require("scripts/game/menu2/menu_equipment_staff_ui"),
+		require("scripts/game/menu2/menu_equipment_weapon_ui"),
+		require("scripts/game/menu2/menu_statistics_ui")
+	}
+
+	kmf.on_init_ui()
+	self.ui_component_handler:register_components(ui_components)
 end
 
 function GameStateInGame:on_playermanager_added(data)
@@ -1294,17 +1381,17 @@ function GameStateInGame:transition_to_menu(join_lobby, reason, leave_lobby)
 		self.cutscene_manager:stop_cutscene(self.world, 2)
 	end
 
-	local state_context = {}
-
-	state_context.level_exited = LevelSettings[self.level_name_short]
-	state_context.player_manager = self.player_manager
-	state_context.game_started = true
-	state_context.join_lobby = join_lobby
-	state_context.lobby_handler = self.lobby_handler
-	state_context.reason = reason
-	state_context.persistence_manager = self.persistence_manager
-	state_context.transaction_handler = self.transaction_handler
-	state_context.sound_manager = self.sound_manager
+	local state_context = {
+		level_exited = LevelSettings[self.level_name_short],
+		player_manager = self.player_manager,
+		game_started = true,
+		join_lobby = join_lobby,
+		lobby_handler = self.lobby_handler,
+		reason = reason,
+		persistence_manager = self.persistence_manager,
+		transaction_handler = self.transaction_handler,
+		sound_manager = self.sound_manager
+	}
 
 	if not self.exit_reason then
 		self.exit_reason = "early exit"
@@ -1324,15 +1411,15 @@ function GameStateInGame:transition_to_login(join_lobby)
 		self.cutscene_manager:stop_cutscene(self.world, 2)
 	end
 
-	local state_context = {}
-
-	state_context.player_manager = self.player_manager
-	state_context.game_started = true
-	state_context.join_lobby = join_lobby
-	state_context.lobby_handler = self.lobby_handler
-	state_context.persistence_manager = self.persistence_manager
-	state_context.transaction_handler = self.transaction_handler
-	state_context.sound_manager = self.sound_manager
+	local state_context = {
+		player_manager = self.player_manager,
+		game_started = true,
+		join_lobby = join_lobby,
+		lobby_handler = self.lobby_handler,
+		persistence_manager = self.persistence_manager,
+		transaction_handler = self.transaction_handler,
+		sound_manager = self.sound_manager
+	}
 
 	if not self.exit_reason then
 		self.exit_reason = "network fail"
@@ -1662,7 +1749,9 @@ function GameStateInGame:update_time_event_list(message, time_value)
 end
 
 function GameStateInGame:show_challenge_message(msg, time)
-	self.gm:show_challenge_message(msg, time)
+	if not kmf.vars.pvp_gamemode then
+		self.gm:show_challenge_message(msg, time)
+	end
 end
 
 function GameStateInGame:set_score_gui_kill_list(comma_delimitered_string)
