diff --git a/scripts/game/menu2/menu_player_slots_ui.lua b/scripts/game/menu2/menu_player_slots_ui.lua
index 06da73c..c16c862 100644
--- a/scripts/game/menu2/menu_player_slots_ui.lua
+++ b/scripts/game/menu2/menu_player_slots_ui.lua
@@ -601,7 +601,9 @@ function C:update()
 		elseif not vacant_slot_processed then
 			vacant_slot_processed = true
 
-			self:refresh_player_slot_invite_join(player_slot, slot_index)
+			pcall(function()
+				self:refresh_player_slot_invite_join(player_slot, slot_index)
+			end)
 		else
 			self:refresh_player_slot_clear(player_slot)
 		end
@@ -898,6 +900,36 @@ function C:get_slot_context(slot_index)
 	local glow = slot_glow[slot_index]
 	local context = {}
 
+	local player_faction = "player"
+	local owner_peer_id
+
+	if self.in_game_version and kmf.entity_manager then
+		local players, players_n = kmf.entity_manager:get_entities("player")
+
+		for i = 1, players_n, 1 do
+			local player = players[i]
+
+			if player and player.unit and player.extension and player.extension.global_player_id == slot_index then
+				local faction_ext = EntityAux.extension(player.unit, "faction")
+
+				owner_peer_id = player.extension.owner_peer_id
+
+				if faction_ext and faction_ext.internal then
+					player_faction = faction_ext.internal.faction
+				end
+
+				break
+			end
+		end
+	end
+
+	self.kmf_player_team = {
+		peer = owner_peer_id,
+		team = player_faction,
+	}
+
+	player_faction = player_faction == "player" and "Vlad" or "Grimnir"
+
 	if is_vacant then
 		if NetworkHandler:is_offline() then
 			local slot_button = ui:create(Prefabs, {
@@ -928,6 +960,20 @@ function C:get_slot_context(slot_index)
 				}
 			}))
 		end
+
+		if kmf.vars.res_spec_sm.state == "spec" then
+			table.insert(context, ui:create(Prefabs, {
+				id = "k_mod_return_spec",
+				prefabs = {
+					"player_slot_button"
+				},
+				vars = {
+					item_text_localize = "[KMF]return_from_spec_btn",
+					item_text_color = UI.Color.font_light,
+					glow = glow
+				}
+			}))
+		end
 	else
 		if not is_self and is_hosting then
 			table.insert(context, ui:create(Prefabs, {
@@ -987,7 +1033,39 @@ function C:get_slot_context(slot_index)
 			}))
 		end
 
-		if is_self and not self.in_game_version then
+		for _, create_menu_btns in pairs(kmf.vars.player_menu_buttons) do
+			create_menu_btns(context, Prefabs, ui, UI, glow, is_self, is_local, is_hosting)
+		end
+
+		if is_self and is_hosting then
+			table.insert(context, ui:create(Prefabs, {
+				id = "k_mod_sync_mods",
+				prefabs = {
+					"player_slot_button"
+				},
+				vars = {
+					item_text_localize = "[KMF]sync_mods_player_btn",
+					item_text_color = UI.Color.font_light,
+					glow = glow
+				}
+			}))
+		end
+
+		if self.in_game_version and kmf.vars.pvp_gamemode and is_hosting then
+			table.insert(context, ui:create(Prefabs, {
+				id = "k_mod_set_team",
+				prefabs = {
+					"player_slot_button"
+				},
+				vars = {
+					item_text = "Team: " .. player_faction,
+					item_text_color = UI.Color.font_light,
+					glow = glow
+				}
+			}))
+		end
+
+		if is_self then
 			table.insert(context, ui:create(Prefabs, {
 				id = "stats",
 				prefabs = {
@@ -1001,7 +1079,7 @@ function C:get_slot_context(slot_index)
 			}))
 		end
 
-		if is_local and not self.in_game_version then
+		if is_local and (not self.in_game_version or kmf.check_mod_enabled("change equipment in-game")) then
 			table.insert(context, ui:create(Prefabs, {
 				id = "equipment",
 				prefabs = {
@@ -1014,6 +1092,48 @@ function C:get_slot_context(slot_index)
 				}
 			}))
 		end
+
+		if is_local then
+			table.insert(context, ui:create(Prefabs, {
+				id = "k_mod_settings",
+				prefabs = {
+					"player_slot_button"
+				},
+				vars = {
+					item_text_localize = "[KMF]mod_settings_player_btn",
+					item_text_color = UI.Color.font_light,
+					glow = glow
+				}
+			}))
+		end
+
+		if is_local and kmf.check_mod_enabled("become spectator button") then
+			table.insert(context, ui:create(Prefabs, {
+				id = "k_mod_spectator",
+				prefabs = {
+					"player_slot_button"
+				},
+				vars = {
+					item_text_localize = "[KMF]become_spectator_player_btn",
+					item_text_color = UI.Color.font_light,
+					glow = glow
+				}
+			}))
+		end
+
+		if is_local and kmf.game_state_in_game then
+			table.insert(context, ui:create(Prefabs, {
+				id = "k_mod_reset_player",
+				prefabs = {
+					"player_slot_button"
+				},
+				vars = {
+					item_text_localize = "[KMF]reset_player_btn",
+					item_text_color = UI.Color.font_light,
+					glow = glow
+				}
+			}))
+		end
 	end
 
 	cat_print("UI", "Context menu for", slot_index, "is: ")
@@ -1055,7 +1175,47 @@ function C:on_click_player_slot_button(evt)
 	local id = evt.emitter.data.id
 
 	if not evt.emitter:metadata("disabled") then
-		if id == "stats" and not StatManager:is_enabled() then
+		if id == "k_mod_settings" then
+			kmf.mod_settings_manager.c_mod_mngr.display_settings_menu()
+		elseif id == "k_mod_spectator" then
+			kmf.become_spectator()
+		elseif id == "k_mod_set_team" then
+			if self.kmf_player_team and self.kmf_player_team.peer then
+				local team = self.kmf_player_team.team
+				local peer = self.kmf_player_team.peer
+
+				team = team == "evil" and "player" or "evil"
+				kmf.vars.pvp_player_teams[peer] = team
+
+				local members = kmf.lobby_handler.connected_peers
+				local msg = peer .. ":" .. team
+
+				for _, player_id in ipairs(members) do
+					kmf.send_kmf_msg(player_id, msg, "set-team")
+				end
+			end
+		elseif id == "k_mod_return_spec" then
+			kmf.respawn_local_player()
+		elseif id == "k_mod_reset_player" then
+			kmf.on_reset_player_btn_click()
+		elseif id == "k_mod_sync_mods" then
+			if kmf.lobby_handler then
+				local me_peer = kmf.lobby_handler:local_peer()
+				local members = kmf.lobby_handler.connected_peers
+
+				for _, mod in ipairs(kmf.const.sync_mods) do
+					local state = kmf.check_mod_enabled(mod)
+					local msg_type = (state and "m-enbl" or "m-dsbl")
+					local msg = mod
+
+					for _, player_id in ipairs(members) do
+						if player_id ~= me_peer then
+							kmf.send_kmf_msg(player_id, msg, msg_type)
+						end
+					end
+				end
+			end
+		elseif id == "stats" and not StatManager:is_enabled() then
 			ui:push_modal_inform("joa_ui_playerstats_unavailable")
 		elseif id == "leave" then
 			ui:push_modal({
@@ -1067,14 +1227,25 @@ function C:on_click_player_slot_button(evt)
 				end
 			})
 		else
-			local slot_index = evt.emitter.parent.parent.parent:metadata("slot_index")
-			local event = event_lookup[id]
+			local handled = false
 
-			if event == "on_show_menu_equipment" or event == "on_show_menu_stats" then
-				self.context.event_delegate:trigger2("on_remove_nav_guide", Alias)
+			for _, player_menu_btn_handler in pairs(kmf.vars.player_menu_btn_handlers) do
+				if player_menu_btn_handler(evt, id) then
+					handled = true
+					break
+				end
 			end
 
-			self.context.event_delegate:trigger2(event, "backward", slot_index)
+			if not handled then
+				local slot_index = evt.emitter.parent.parent.parent:metadata("slot_index")
+				local event = event_lookup[id]
+
+				if event == "on_show_menu_equipment" or event == "on_show_menu_stats" then
+					self.context.event_delegate:trigger2("on_remove_nav_guide", Alias)
+				end
+
+				self.context.event_delegate:trigger2(event, "backward", slot_index)
+			end
 		end
 
 		self:destroy_context_menu(evt.emitter.parent.parent)
