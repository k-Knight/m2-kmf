diff --git a/scripts/game/network/network_gamemode_server_game.lua b/scripts/game/network/network_gamemode_server_game.lua
index 1d7fdf7..ef3d8d3 100644
--- a/scripts/game/network/network_gamemode_server_game.lua
+++ b/scripts/game/network/network_gamemode_server_game.lua
@@ -24,6 +24,11 @@ function NetworkGameModeServerGame:init(context, story, level_name, gamemode, ga
 	assert(game_context.lobby_handler)
 	assert(game_context.player_manager)
 
+	kmf.server_game = self
+	kmf.client_game = nil
+	--kmf.vars.last_local_player_id   = nil
+	--kmf.vars.last_local_player_data = nil
+
 	self.player_manager = game_context.player_manager
 	self.lobby_handler = game_context.lobby_handler
 	self.network_lobby_handler_event_delegate = self.lobby_handler:get_event_delegate()
@@ -202,6 +207,34 @@ function NetworkGameModeServerGame:register_events()
 end
 
 function NetworkGameModeServerGame:handle_on_all_players_dead_no_revive()
+	if kmf.vars.pvp_gamemode and kmf.lobby_handler:is_host() then
+		kmf_print("total player death !!!")
+		kmf.task_scheduler.add(function()
+			if kmf.vars.pvp_announce_lock then
+				return
+			end
+
+			kmf.vars.pvp_everyone_looses = true
+			kmf.vars.pvp_prevent_team_res = true
+			kmf.vars.pvp_defeat_team = nil
+
+			local members = kmf.lobby_handler.connected_peers
+
+			for _, player_id in ipairs(members) do
+				kmf.send_kmf_msg(player_id, "defeat:all", "pvp-announce")
+			end
+		end, 500)
+		kmf.task_scheduler.add(function()
+			kmf.vars.pvp_everyone_looses = false
+			kmf.pvp_resurrect_all_teams()
+
+			kmf.task_scheduler.add(function()
+				kmf.vars.pvp_announce_lock = false
+			end, 3000)
+		end, 3500)
+		return
+	end
+
 	print("DEATH!")
 	self:show_endgame(self.story, "", false, 0, nil)
 end
@@ -239,7 +272,7 @@ function NetworkGameModeServerGame:game_object_sync_done(peer_id)
 			self.dialogue_manager:sync_dialogues(peer_id)
 		end
 
-		if self.endgame then
+		if self.endgame and not kmf.vars.pvp_gamemode then
 			self.network_transport:transmit_to(peer_id, "from_server_show_endgame", self.endgame.story, self.endgame.next_level, self.endgame.max_players, self.endgame.victory, false, self.endgame.phase or -1, self.endgame.score or -1, self.endgame.target_score or -1, self.endgame.elapsed_time or -1, self.endgame.target_time or -1, self.endgame.message or "", self.endgame.is_custom_challenge, self.endgame.custom_challenge_name, self.endgame.custom_challenge_win_defeat_header, self.endgame.custom_challenge_win_defeat_body, self.endgame.challenge_session_id, self.endgame.challenge_online_id, self.endgame.ranked)
 		end
 	end
@@ -672,6 +705,9 @@ function NetworkGameModeServerGame:set_level_spawnpoint(name, level)
 end
 
 function NetworkGameModeServerGame:show_endgame(story, next_level, victory, score, target_score, win_fail_explanation, challenge_phase, elapsed_time, target_time, is_custom_challenge, custom_challenge_name, custom_challenge_win_defeat_header, custom_challenge_win_defeat_body)
+	if kmf.vars.pvp_gamemode then
+		return
+	end
 	assert(self.lobby_handler:is_host(), "Transit to new level should not be called on clients")
 
 	if victory and next_level and next_level ~= "" then
@@ -763,10 +799,16 @@ function NetworkGameModeServerGame:show_endgame(story, next_level, victory, scor
 end
 
 function NetworkGameModeServerGame:show_endgame_timed_challenge(story, next_level, victory, _elapsed_time, _target_time, win_fail_explanation, challenge_phase, is_custom_challenge, custom_challenge_name, custom_challenge_win_defeat_header, custom_challenge_win_defeat_body)
+	if kmf.vars.pvp_gamemode then
+		return
+	end
 	self:show_endgame(story, next_level, victory, nil, nil, win_fail_explanation, challenge_phase, _elapsed_time, _target_time, is_custom_challenge, custom_challenge_name, custom_challenge_win_defeat_header, custom_challenge_win_defeat_body)
 end
 
 function NetworkGameModeServerGame:show_endgame_skill(story, next_level, victory, win_fail_explanation, challenge_phase)
+	if kmf.vars.pvp_gamemode then
+		return
+	end
 	self:show_endgame(story, next_level, victory, nil, nil, win_fail_explanation, challenge_phase, nil, nil)
 end
 
@@ -1079,6 +1121,10 @@ function NetworkGameModeServerGame:send_stop_encounter()
 end
 
 function NetworkGameModeServerGame:send_add_encounter_unit(u)
+	if kmf.vars.pvp_gamemode then
+		return
+	end
+
 	local go_id = self.unit_storage:go_id(u)
 
 	self.network_transport:transmit_message_all("add_encounter_unit", go_id)
