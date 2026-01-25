diff --git a/scripts/game/network/network_lobby_browser.lua b/scripts/game/network/network_lobby_browser.lua
index e15d02c..53d9ca8 100644
--- a/scripts/game/network/network_lobby_browser.lua
+++ b/scripts/game/network/network_lobby_browser.lua
@@ -107,7 +107,11 @@ function NetworkLobbyBrowser:update(dt)
 end
 
 function NetworkLobbyBrowser:validate_entry(entry)
-	if entry.owner_peer ~= NetworkHandler:local_peer_id() and entry.name ~= nil and entry.name ~= "" and entry.id_address ~= nil and entry.id_address ~= "" and entry.players ~= nil and entry.players ~= "" and entry.gamemode ~= nil and entry.gamemode ~= "" and entry.level_name ~= nil and entry.level_index ~= "" and entry.owner_peer ~= nil and entry.owner_peer ~= "" and entry.artifact_setting ~= nil and entry.artifact_setting ~= "" then
+	--if entry.owner_peer ~= NetworkHandler:local_peer_id() and entry.name ~= nil and entry.name ~= "" and entry.id_address ~= nil and entry.id_address ~= "" and entry.players ~= nil and entry.players ~= "" and entry.gamemode ~= nil and entry.gamemode ~= "" and entry.level_name ~= nil and entry.level_index ~= "" and entry.owner_peer ~= nil and entry.owner_peer ~= "" and entry.artifact_setting ~= nil and entry.artifact_setting ~= "" then
+	--	return true
+	--end
+
+	if entry.owner_peer ~= NetworkHandler:local_peer_id() then
 		return true
 	end
 
@@ -362,7 +366,20 @@ function NetworkLobbyBrowser:_update_psn_friend_serverlist(dt)
 end
 
 function LobbySort(a, b)
-	return a.name < b.name
+	local diff_a = tonumber(a.artifact_setting) or 1
+	local diff_b = tonumber(b.artifact_setting) or 1
+
+	diff_a = (diff_a == 4) and 1.5 or diff_a
+	diff_b = (diff_b == 4) and 1.5 or diff_b
+
+	diff_a = a.story == "PvP" and 4 or diff_a
+	diff_b = b.story == "PvP" and 4 or diff_b
+
+	if diff_a == diff_b then
+		return a.name < b.name
+	else
+		return diff_a > diff_b
+	end
 end
 
 function NetworkLobbyBrowser:request_refresh_public()
@@ -464,6 +481,11 @@ function NetworkLobbyBrowser:_update_friends_server_list(dt)
 	end
 end
 
+kmf.set_steam_lobby_browser_filters = function(browser)
+	browser:clear_filters()
+	browser:add_distance_filter(browser.WORLD)
+end
+
 function NetworkLobbyBrowser:_refresh_public_serverlist()
 	if self.offline then
 		self.public_dirty_list = true
@@ -473,6 +495,8 @@ function NetworkLobbyBrowser:_refresh_public_serverlist()
 		end
 
 		if self.steam or self.psn then
+			kmf.vars.steam_lobby_broswer = self.browser
+			kmf.set_steam_lobby_browser_filters(self.browser)
 			self.browser:refresh()
 		else
 			self.browser:refresh(NetworkSettings.lobby_port)
