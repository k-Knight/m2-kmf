diff --git a/scripts/game/game_state/game_state_menu.lua b/scripts/game/game_state/game_state_menu.lua
index b8cff8b..1caba54 100644
--- a/scripts/game/game_state/game_state_menu.lua
+++ b/scripts/game/game_state/game_state_menu.lua
@@ -108,6 +108,8 @@ function GameStateMenu:on_enter(param_block)
 	self.player_input_mapper = PlayerInputMapper(self.player_manager, function()
 		self:logout(true)
 	end)
+	kmf.player_input_mapper = self.player_input_mapper
+
 	self.event_delegate = EventDelegate()
 
 	self.event_delegate:register(Alias, self, "on_menu2_invite_player", "on_menu2_kick_player", "on_menu2_toggle_mute_player", "on_menu2_player_leave", "on_menu2_join_public_game", "on_menu2_join_any_public_game", "on_menu2_join_friend_game", "on_menu2_create_game", "on_menu2_create_challenge", "on_lobby_browser_public_list_refreshed", "on_lobby_browser_error", "on_go_online", "on_menu2_enter_creator_clean", "on_menu2_enter_creator", "on_playermanager_added", "on_playermanager_removed", "on_playermanager_added_local", "on_unlink")
@@ -116,6 +118,9 @@ function GameStateMenu:on_enter(param_block)
 	self:setup_lobby_handling_browsing_keys(self.lobby_handler)
 	self:setup_lobby_browser()
 
+	kmf_print("resetting pvp gamemode locally")
+	kmf.vars.pvp_gamemode = false
+
 	self.auto_start_level = param_block.auto_start_level
 	param_block.auto_start_level = nil
 
@@ -180,6 +185,7 @@ function GameStateMenu:on_enter(param_block)
 end
 
 function GameStateMenu:on_exit()
+	kmf.player_input_mapper = nil
 	cat_print("GameStateMenu", " GAMESTATEMENU:ON_EXIT")
 
 	if self.autojoining_state ~= "none" then
@@ -537,6 +543,7 @@ function GameStateMenu:setup_lobby_handler(old_lobby_handler)
 		end
 
 		self.lobby_handler = NetworkLobbyHandler(player_list, server_name)
+		_G.kmf.lobby_handler = self.lobby_handler
 
 		if not self.param_block.join_lobby then
 			self.lobby_handler:create_lobby()
@@ -639,7 +646,7 @@ function GameStateMenu:init_ui()
 		})
 	end
 
-	self.ui_component_handler:register_components({
+	local ui_components = {
 		require("scripts/game/menu2/menu_map_ui"),
 		require("scripts/game/menu2/menu_navigation_ui"),
 		require("scripts/game/menu2/menu_player_slots_ui"),
@@ -669,7 +676,10 @@ function GameStateMenu:init_ui()
 		require("scripts/game/menu2/menu_statistics_ui"),
 		require("scripts/game/menu2/debug_levelselect_menu_ui"),
 		require("scripts/game/menu2/legal_menu_ui")
-	})
+	}
+
+	kmf.on_init_ui()
+	self.ui_component_handler:register_components(ui_components)
 end
 
 function GameStateMenu:on_menu2_invite_player()
