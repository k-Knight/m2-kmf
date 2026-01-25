diff --git a/scripts/game/player/player_manager.lua b/scripts/game/player/player_manager.lua
index 73b2f21..36b1fb1 100644
--- a/scripts/game/player/player_manager.lua
+++ b/scripts/game/player/player_manager.lua
@@ -119,13 +119,18 @@ function PlayerManager:post_request_add_local_player(slot_id, add_local_player_c
 	else
 		local has_free_slot = self:first_free_local_slot()
 
-		add_local_player_callback(has_free_slot)
+		if add_local_player_callback then
+			add_local_player_callback(has_free_slot)
+		end
 	end
 end
 
 function PlayerManager:request_add_local_player(slot_id, user_id, add_local_player_callback)
+	k_log("in PlayerManager.request_add_local_player() :: slot [" .. tostring(slot_id) .. "]    user [" .. tostring(user_id) .. "]")
 	if self.primary_only and self:get_num_local_players() > 0 then
-		add_local_player_callback(false, "primary_only")
+		if add_local_player_callback then
+			add_local_player_callback(false, "primary_only")
+		end
 
 		return
 	end
@@ -141,7 +146,9 @@ function PlayerManager:request_add_local_player(slot_id, user_id, add_local_play
 end
 
 function PlayerManager:on_add_local_player(has_free_slot)
-	self.add_local_player_callback(has_free_slot)
+	if self.add_local_player_callback then
+		self.add_local_player_callback(has_free_slot)
+	end
 
 	self.add_local_player_callback = nil
 
@@ -208,6 +215,10 @@ function PlayerManager:get_player_data(local_player_id)
 end
 
 function PlayerManager:get_local_player_data(local_player_id)
+	if not self._local_player_data[local_player_id] then
+		return kmf.vars.last_local_player_data
+	end
+
 	return self._local_player_data[local_player_id]
 end
 
@@ -266,7 +277,9 @@ function PlayerManager:try_get_input_controller(index)
 end
 
 function PlayerManager:get_input_controller(index)
-	assert(self._local_player_data[index], "Trying to get input type from a none-local player.")
+	if not self._local_player_data[index] then
+		return nil
+	end
 
 	return self._local_player_data[index].controller
 end
@@ -327,6 +340,7 @@ end
 function PlayerManager:add_local_player(profile_index, controller, name, extended_name)
 	local new_data = PlayerData(profile_index, controller, name, extended_name)
 
+	kmf.vars.last_local_player_data = PlayerData(profile_index, controller, name, extended_name)
 	self._local_player_data[profile_index] = new_data
 
 	local user_id_or_name = new_data.user_id or name
@@ -517,7 +531,9 @@ function PlayerManager:update_global_player_data()
 			for _, player_id in pairs(player_list) do
 				local global_player_id = self.lobby_handler:local_to_global_id(peer, player_id)
 
-				assert(global_player_id)
+				if not global_player_id then
+					return
+				end
 
 				local data = self._global_player_data[global_player_id]
 
