diff --git a/scripts/game/network/network_gamemode_scenario_server_game.lua b/scripts/game/network/network_gamemode_scenario_server_game.lua
index a220501..6a6b744 100644
--- a/scripts/game/network/network_gamemode_scenario_server_game.lua
+++ b/scripts/game/network/network_gamemode_scenario_server_game.lua
@@ -68,6 +68,10 @@ function NetworkGameModeScenarioServerGame:game_object_sync_done(peer_id)
 end
 
 function NetworkGameModeScenarioServerGame:start_countdown(dt)
+	if kmf.vars.pvp_gamemode then
+		return
+	end
+
 	local sent_network_messages_to_peer = self.sent_network_messages_to_peer
 
 	if not self.start_countdown_has_run then
