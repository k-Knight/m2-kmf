diff --git a/scripts/game/network/network_gamemode_client_game.lua b/scripts/game/network/network_gamemode_client_game.lua
index 6787e2e..db4146a 100644
--- a/scripts/game/network/network_gamemode_client_game.lua
+++ b/scripts/game/network/network_gamemode_client_game.lua
@@ -12,6 +12,11 @@ local EntityAux_set_input = EntityAux.set_input
 function NetworkGameModeClientGame:init(context, story, level_name, gamemode, game_context, diagMan, cutsceneMan, videoMan)
 	NetworkGameModeClient.init(self, context, story, level_name, gamemode, game_context)
 
+	kmf.client_game = self
+	kmf.server_game = nil
+	--kmf.vars.last_local_player_id   = nil
+	--kmf.vars.last_local_player_data = nil
+
 	self.player_manager = game_context.player_manager
 	self.lobby_handler = game_context.lobby_handler
 
@@ -185,6 +190,36 @@ function NetworkGameModeClientGame:from_server_req_spawn_details(sender, player_
 	RPC.from_client_spawn_details(sender, player_index, player_inventory)
 end
 
+function NetworkGameModeClientGame:my_spawn_player(sender, player_index, player_data)
+	local player_manager = self.player_manager
+	local voice_id = player_data.voice
+	local robe_id = player_data.robe
+	local staff_id = player_data.bound_staff
+	local weapon_id = player_data.bound_weapon
+	local robe_variant_id = player_data.robe_variant
+	local familiar_id = player_data.familiar
+
+	assert(voice_id)
+	assert(robe_id)
+	assert(staff_id)
+	assert(weapon_id)
+	assert(robe_variant_id)
+	assert(familiar_id)
+
+	local staff = self.network_lookup_inventory_units[staff_id]
+	local weapon = self.network_lookup_inventory_units[weapon_id]
+	local player_inventory = {
+		robe_id,
+		robe_variant_id,
+		staff_id,
+		weapon_id,
+		familiar_id,
+		voice_id
+	}
+
+	RPC.from_client_spawn_details(sender, player_index, player_inventory)
+end
+
 function NetworkGameModeClientGame:from_server_spawn_details(server, player_index, pos, rot, player_inventory, spawn_as_dead)
 	self:spawn_player(player_index, pos, rot, player_inventory, spawn_as_dead)
 end
@@ -232,12 +267,21 @@ end
 function NetworkGameModeClientGame:spawn_player(local_player_id, pos, rot, player_inventory, spawn_as_dead)
 	cat_print("NetworkGameModeClientGame", "Got spawn player from server: local_player:" .. local_player_id)
 
+	-- for debugging
+	kmf.send_modded_section_warning(self.lobby_handler:local_peer())
+
 	if not self.player_manager:have_local_player(local_player_id) then
 		return
 	end
 
 	local is_host_player = self.player_manager:get_lobby():is_host() and local_player_id == 1
-	local global_player_id = self.lobby_handler:local_to_global_id(self.lobby_handler:local_peer(), local_player_id)
+	local peer = self.lobby_handler:local_peer()
+	local global_player_id = self.lobby_handler:local_to_global_id(peer, local_player_id)
+
+	if not kmf.vars.pvp_player_teams[peer] then
+		kmf.vars.pvp_player_teams[peer] = "player"
+	end
+	local desired_team = kmf.vars.pvp_player_teams[peer]
 
 	assert(global_player_id and global_player_id >= 1 and global_player_id <= 4)
 
@@ -285,6 +329,13 @@ function NetworkGameModeClientGame:spawn_player(local_player_id, pos, rot, playe
 			global_player_id = global_player_id
 		}
 	}
+
+	if kmf.vars.pvp_gamemode then
+		extension_init_data.faction = {
+			faction = desired_team
+		}
+	end
+
 	local unit_spawner = StateContext.manager("unit_spawner")
 	local entity_manager = unit_spawner.entity_manager
 	local unit_storage = unit_spawner.unit_storage
@@ -511,7 +562,16 @@ function NetworkGameModeClientGame:skip_dialogue(sender)
 end
 
 function NetworkGameModeClientGame:on_message(sender, category, message_id, go_id)
-	if category ~= "sound" and category ~= "invisible" then
+	go_id = tonumber(go_id)
+	category = tostring(category)
+	message_id = tostring(message_id)
+
+	if not (go_id and category and message_id) then
+		return
+	end
+
+	--if category ~= "sound" and category ~= "invisible" then
+	if category == "visible" then
 		ui:push_message(category, LocalizationManager:lookup(message_id))
 	end
 end
