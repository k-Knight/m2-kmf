diff --git a/scripts/game/network/network_gamemode_challenge_server_game.lua b/scripts/game/network/network_gamemode_challenge_server_game.lua
index 59cfdbf..016f71e 100644
--- a/scripts/game/network/network_gamemode_challenge_server_game.lua
+++ b/scripts/game/network/network_gamemode_challenge_server_game.lua
@@ -96,7 +96,7 @@ function NetworkGameModeChallengeServerGame:init(context, story, level_name, gam
 
 	assert(self.level_proxy, "NetworkGameModeChallengeServerGame:init - no level-proxy, actions depending on level will not validate proparly !")
 
-	local challenge_data, is_official = ChallengeProvider.instance():get_data(self.challenge_id)
+	local challenge_data, is_official = ChallengeProvider.instance():get_data(self.challenge_id, kmf.vars.pvp_gamemode)
 
 	if self.creator_mode == "edit" then
 		is_official = false
@@ -132,6 +132,10 @@ function NetworkGameModeChallengeServerGame:init(context, story, level_name, gam
 		assert(challenge_gamemode == self.mode, "Trial-type (" .. challenge_gamemode .. ") does not match xml-defined gamemode (" .. self.mode .. ") !")
 	end
 
+	if self.mode ~= "score" and self.mode ~= "time" then
+		self.mode = "skill"
+	end
+
 	assert(self.mode == "score" or self.mode == "time" or self.mode == "skill", "Unsupported challenge gamemode " .. (self.mode and "'" .. self.mode .. "'" or "NIL") .. " ! This should have been picked up by the xml-parser !")
 
 	if self.mode == "score" then
@@ -595,6 +599,10 @@ function NetworkGameModeChallengeServerGame:start_countdown(dt)
 end
 
 function NetworkGameModeChallengeServerGame:sync_gui(peer_id)
+	if kmf.vars.pvp_gamemode then
+		return
+	end
+
 	local phase_current, phase_max, current_phase_name
 
 	if self.mode == "score" then
@@ -669,6 +677,9 @@ function NetworkGameModeChallengeServerGame:from_client_player_spawned(client, u
 end
 
 function NetworkGameModeChallengeServerGame:on_challenge_won(message)
+	if kmf.vars.pvp_gamemode then
+		return
+	end
 	self.challenge_updater:pause()
 
 	if message == nil then
@@ -696,11 +707,42 @@ function NetworkGameModeChallengeServerGame:on_challenge_won(message)
 end
 
 function NetworkGameModeChallengeServerGame:handle_on_all_players_dead_no_revive()
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
 	print("NetworkGameModeChallengeServerGame::handle_on_all_players_dead_no_revive")
 	self:on_challenge_failed()
 end
 
 function NetworkGameModeChallengeServerGame:on_challenge_failed(message)
+	if kmf.vars.pvp_gamemode then
+		return
+	end
 	self.challenge_updater:pause()
 
 	if message == nil then
