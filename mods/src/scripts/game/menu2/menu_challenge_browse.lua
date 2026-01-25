diff --git a/scripts/game/menu2/menu_challenge_browse.lua b/scripts/game/menu2/menu_challenge_browse.lua
index 68e2ed5..1372269 100644
--- a/scripts/game/menu2/menu_challenge_browse.lua
+++ b/scripts/game/menu2/menu_challenge_browse.lua
@@ -1214,7 +1214,17 @@ function C:on_enter_row(evt)
 	end
 end
 
-function C:on_click_play(offline_challenge_id, online_challenge_id, online_challenge_resource_uri, online_challenge_timestamp, public)
+function C:on_click_play(offline_challenge_id, online_challenge_id, online_challenge_resource_uri, online_challenge_timestamp, public, picked_pvp_option)
+	kmf.vars.pvp_gamemode = false
+
+	if kmf.lobby_handler then
+		local members = kmf.lobby_handler.connected_peers
+
+		for _, player_id in ipairs(members) do
+			kmf.send_kmf_msg(player_id, "false", "pvp-enbl")
+		end
+	end
+
 	if (not online_challenge_id or not online_challenge_resource_uri or not online_challenge_timestamp or not public) and (self.currently_browsing ~= "my_challenges" or not online_challenge_id or not online_challenge_resource_uri) and not offline_challenge_id then
 		return
 	end
@@ -1222,7 +1232,7 @@ function C:on_click_play(offline_challenge_id, online_challenge_id, online_chall
 	local local_timestamp = self.persistence_manager:get_challenge_timestamp(online_challenge_id) or 0
 	local online_timestamp = online_challenge_timestamp and OS_Aux.convert_UTC_timestamp_to_local_epoch(online_challenge_timestamp) or 0
 
-	if local_timestamp < online_timestamp then
+	if not picked_pvp_option and local_timestamp < online_timestamp then
 		local transaction_id = self.transaction_handler:retrieve_challenge_blob(online_challenge_resource_uri)
 
 		if transaction_id == -1 then
@@ -1242,9 +1252,9 @@ function C:on_click_play(offline_challenge_id, online_challenge_id, online_chall
 			is_official = not not offline_challenge_id,
 			timestamp = online_timestamp
 		}
-	elseif online_timestamp <= local_timestamp then
+	elseif online_timestamp <= local_timestamp or picked_pvp_option then
 		local challenge_id = offline_challenge_id or online_challenge_id
-		local challenge_data, is_official = ChallengeProvider.instance():get_init_data(challenge_id)
+		local challenge_data, is_official = ChallengeProvider.instance():get_init_data(challenge_id, picked_pvp_option)
 
 		assert(challenge_data)
 
@@ -1252,9 +1262,39 @@ function C:on_click_play(offline_challenge_id, online_challenge_id, online_chall
 		challenge_data.online_id = online_challenge_id
 		challenge_data.official = is_official
 
+		kmf.vars._MenuAdventureCreateArtifactPresetUi = nil
+
 		self:on_hide_menu_challenge_browse_official("backward")
 		self.context.event_delegate:trigger1("on_hide_menu_create", "forward")
-		self.context.event_delegate:trigger2("on_show_menu_challenge_create_artifact_preset", "forward", challenge_data)
+		if not picked_pvp_option then
+			self.context.event_delegate:trigger2("on_show_menu_challenge_create_artifact_preset", "forward", challenge_data)
+		else
+			local modifiers = ArtifactManager:get_custom_artifacts(true)
+			local mod_string
+
+			if next(modifiers) then
+				mod_string = ArtifactAux.modifiers_to_string(modifiers)
+			end
+
+			local function callback_to_come_back_here()
+				self:hide_menu("backward")
+				self.context.event_delegate:trigger2("on_show_menu_create", "backward", "challenge")
+			end
+
+			local function callback_to_start_game_with_custom_artifacts()
+				self.context.event_delegate:trigger2("on_menu2_create_challenge", challenge_data, "custom")
+			end
+
+			self.context.event_delegate:trigger5("on_show_menu_create_artifact_custom", "forward", self.title_text, mod_string, callback_to_come_back_here, callback_to_start_game_with_custom_artifacts)
+			kmf.vars.pvp_gamemode = true
+			if kmf.lobby_handler then
+				local members = kmf.lobby_handler.connected_peers
+
+				for _, player_id in ipairs(members) do
+					kmf.send_kmf_msg(player_id, "true", "pvp-enbl")
+				end
+			end
+		end
 	end
 end
 
@@ -1613,6 +1653,16 @@ function C:display_context_menu(pos_x, pos_y)
 				glow = glow
 			}
 		}))
+		table.insert(context, ui:create(Prefabs, {
+			id = "play_pvp",
+			prefabs = {
+				"context_menu_button"
+			},
+			vars = {
+				item_text = "P v P",
+				glow = glow
+			}
+		}))
 
 		if not offline and is_public then
 			table.insert(context, ui:create(Prefabs, {
@@ -1752,6 +1802,9 @@ function C:on_click_context_menu_button(evt)
 		self.transaction_handler:publish_challenge(challenge_data.online_challenge_id, false)
 	elseif clicked_button_id == "play" then
 		self:on_click_play(challenge_data.offline_challenge_id, challenge_data.online_challenge_id, challenge_data.online_challenge_resource_uri, challenge_data.online_challenge_timestamp, public)
+	elseif clicked_button_id == "play_pvp" then
+		self.last_browsed = self.currently_browsing
+		self:on_click_play(challenge_data.offline_challenge_id, challenge_data.online_challenge_id, challenge_data.online_challenge_resource_uri, challenge_data.online_challenge_timestamp, public, true)
 	elseif clicked_button_id == "upsell" then
 		self:on_click_upsell(challenge_data.dlc_id)
 	elseif clicked_button_id == "leaderboard" then
