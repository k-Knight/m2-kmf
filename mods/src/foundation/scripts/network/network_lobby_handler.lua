diff --git a/foundation/scripts/network/network_lobby_handler.lua b/foundation/scripts/network/network_lobby_handler.lua
index f489a98..4523054 100644
--- a/foundation/scripts/network/network_lobby_handler.lua
+++ b/foundation/scripts/network/network_lobby_handler.lua
@@ -59,6 +59,7 @@ function NetworkLobbyHandler:init(local_player_list, server_name)
 		self.lobby_mode = "LOBBY_MODE_NONE"
 	end
 
+	kmf.network_lobby_handler = self
 	self.joined_order_index = 0
 	self.max_players = 4
 	self.server_name = server_name
@@ -236,6 +237,12 @@ function NetworkLobbyHandler:set_lobby_member_limit(limit)
 end
 
 function NetworkLobbyHandler:leave_lobby(reason)
+	for _, handler_func in pairs(kmf.vars.on_lobby_leave_handlers) do
+		handler_func()
+	end
+
+	kmf.clear_tmp_mod_state()
+
 	if not self.lobby then
 		return
 	end
@@ -368,7 +375,7 @@ function NetworkLobbyHandler:create_lobby()
 	self:reset_query_timers()
 
 	local port = NetworkSettings.lobby_port + PD_INSTANCE_ID
-	local newLobby = NetworkHandler:create_lobby(port, NetworkSettings.max_num_players, self.lobby_mode, self.server_name)
+	local newLobby = NetworkHandler:create_lobby(port, 16, self.lobby_mode, self.server_name)
 
 	assert(newLobby)
 
@@ -407,7 +414,7 @@ function NetworkLobbyHandler:update_lobby(dt)
 	if self.joining_timer >= 0 then
 		self.joining_timer = self.joining_timer + dt
 
-		if self.joining_timer > JOIN_TIMEOUT then
+		if self.joining_timer > JOIN_TIMEOUT * 2 then
 			cat_print("NetworkLobbyHandler", "Join timed out")
 			self:leave_lobby(self.REASON_JOIN_TIMEDOUT)
 			self:create_lobby()
@@ -478,6 +485,8 @@ function NetworkLobbyHandler:set_player_info(info)
 end
 
 function NetworkLobbyHandler:update(dt, player_manager)
+	self.kmf_player_manager = player_manager
+
 	if next(self.pending_lobby_data) ~= nil then
 		cat_print("NetworkLobbyHandler", "Got un-pushed values in lobby data")
 	end
@@ -567,9 +576,29 @@ function NetworkLobbyHandler:update_connections(dt)
 
 	self.connected_peers = current_peers
 
+	local add_self_last = false
+	local me_peer = kmf.lobby_handler:local_peer()
+	local need_to_add_self = false
+
+	if not kmf.lobby_handler:is_host() then
+		add_self_last = true
+	end
+
 	for index, peer in pairs(new_peers) do
-		self:on_added_peer(peer)
-		self.event_delegate:trigger("on_peer_added", peer)
+		if add_self_last and me_peer == peer then
+			need_to_add_self = true
+		else
+			self:on_added_peer(peer)
+			self.event_delegate:trigger("on_peer_added", peer)
+		end
+	end
+
+	if need_to_add_self then
+		kmf.task_scheduler.add(function()
+			kmf.vars.res_spec_sm.state = "spec"
+			self:on_added_peer(me_peer)
+			self.event_delegate:trigger("on_peer_added", me_peer)
+		end, 1000)
 	end
 
 	for index, peer in pairs(removed_peers) do
@@ -672,14 +701,26 @@ function NetworkLobbyHandler:_update_public_lobby_data(player_manager)
 
 	local backend_type = NetworkHandler:get_backend_type()
 
-	self.lobby:set_data("name", self.server_name)
+	local pvp_gamemode = kmf.vars.pvp_gamemode
+
+	if pvp_gamemode then
+		k_log("  lobby name (override) :: " .. "PvP Lobby ( " .. kmf.vars.player_names[kmf.const.me_peer] .. " )")
+		self.lobby:set_data("name", "PvP Lobby ( " .. kmf.vars.player_names[kmf.const.me_peer] .. " )")
+	else
+		self.lobby:set_data("name", self.server_name)
+	end
+
 	self.lobby:set_data("version", VERSION_IDENTIFIER)
 	self.lobby:set_data("owner", tostring(self:local_peer()))
 
-	local story = self:data("story")
+	if not pvp_gamemode then
+		local story = self:data("story")
 
-	if story then
-		self.lobby:set_data("story", story)
+		if story then
+			self.lobby:set_data("story", story)
+		end
+	else
+		self.lobby:set_data("story", "PvP")
 	end
 
 	if backend_type == "PSN" then
@@ -860,8 +901,21 @@ function NetworkLobbyHandler:release_player_id(player_id)
 end
 
 function NetworkLobbyHandler:on_added_peer(peer)
+	k_log("added peer :: " .. tostring(peer))
 	cat_print("NetworkLobbyHandler", "Peer added ", peer)
 
+	kmf.task_scheduler.add(function()
+		local status, err = pcall(function()
+			k_log("    sending my name to :: " .. tostring(peer))
+			kmf.send_kmf_msg(peer, kmf.vars.player_names[kmf.const.me_peer], "name-announce")
+		end)
+
+		if not status then
+			kmf_print("sending player name error ::")
+			kmf_print(err)
+		end
+	end, 3000)
+
 	if self.peers[peer] == nil then
 		self.peers[peer] = {}
 	end
@@ -894,6 +948,34 @@ function NetworkLobbyHandler:on_added_peer(peer)
 	end
 
 	self:update_lobby_data()
+
+	if not kmf.lobby_handler:is_host() then
+		return
+	end
+
+	local members = kmf.lobby_handler.connected_peers
+	for _, player_id in ipairs(members) do
+		if not kmf.vars.pvp_player_teams[player_id] then
+			kmf.vars.pvp_player_team_init_switcher = not kmf.vars.pvp_player_team_init_switcher
+			kmf.vars.pvp_player_teams[player_id] = kmf.vars.pvp_player_team_init_switcher and "player" or "evil"
+		end
+	end
+
+	kmf.task_scheduler.add(function()
+		local members = kmf.lobby_handler.connected_peers
+
+		local msg = peer .. ":" .. kmf.vars.pvp_player_teams[peer]
+
+		for _, player_id in ipairs(members) do
+			kmf.send_kmf_msg(player_id, msg, "set-team")
+		end
+
+		msg = tostring(kmf.vars.pvp_gamemode == true)
+
+		for _, player_id in ipairs(members) do
+			kmf.send_kmf_msg(player_id, msg, "pvp-enbl")
+		end
+	end, 3000)
 end
 
 function NetworkLobbyHandler:on_removed_peer(peer)
@@ -953,7 +1035,10 @@ function NetworkLobbyHandler:remove_player(peer, player_id)
 
 	local player_data = player_list[player_id]
 
-	assert(player_data)
+	if not player_data then
+		return
+	end
+
 	self.event_delegate:trigger("on_player_removed", peer, player_id, player_data.player_id)
 	self:release_player_id(player_data.player_id)
 
@@ -1181,9 +1266,11 @@ function NetworkLobbyHandler:lobby_set_data(sender, final, keys, values)
 	cat_print_spam("NetworkLobbyHandler", "lobby_set_data", sender, final)
 
 	local nr_of_keys = #keys
-
 	for i = 1, nr_of_keys do
-		self.incomming_lobby_data[keys[i]] = values[i]
+		local key = keys[i]
+		local data = values[i]
+
+		self.incomming_lobby_data[key] = data
 	end
 
 	if final then
@@ -1360,6 +1447,10 @@ function NetworkLobbyHandler:continue_to_game()
 end
 
 function NetworkLobbyHandler:back_in_menu()
+	for _, handler_func in pairs(kmf.vars.on_back_in_menu_handlers) do
+		handler_func()
+	end
+
 	self:set_data("game_has_started", "false")
 	self:push_data()
 end
@@ -1456,6 +1547,7 @@ function NetworkLobbyHandler:add_local_player(player_id)
 		end
 	else
 		cat_print("NetworkLobbyHandler", "is client,requesting add")
+		k_log("in NetworkLobbyHandler.add_local_player() as a client :: player_id [" .. tostring(player_id) .. "]")
 		RPC.lobby_add_local_player(self.lobby:lobby_host(), player_id)
 	end
 end
@@ -1512,7 +1604,7 @@ end
 function NetworkLobbyHandler:lobby_peer_join_respons(sender, fail_reason)
 	cat_print("NetworkLobbyHandler", "Got peer join respons: " .. fail_reason)
 
-	if fail_reason == self.REASON_NONE then
+	if fail_reason == self.REASON_NONE or fail_reason == self.REASON_FULL then
 		self.joining_timer = -1
 		self.joined = true
 		self.pending_join = false
@@ -1604,8 +1696,8 @@ function NetworkLobbyHandler:lobby_failed(lobby, dt)
 			create_new = false
 		elseif fail_cause == lobby.NO_SUCH_ROOM then
 			self:leave_lobby(NetworkLobbyHandler.REASON_NO_SUCH_ROOM)
-		elseif fail_cause == lobby.ROOM_FULL then
-			self:leave_lobby(NetworkLobbyHandler.REASON_FULL)
+		--elseif fail_cause == lobby.ROOM_FULL then
+		--	self:leave_lobby(NetworkLobbyHandler.REASON_FULL)
 		elseif fail_cause == lobby.ALREADY_IN_ROOM then
 			self:leave_lobby(NetworkLobbyHandler.READON_ALREADY_IN_ROOM)
 		end
