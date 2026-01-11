diff --git a/scripts/game/network/network_game_transport.lua b/scripts/game/network/network_game_transport.lua
index ce375a4..fc94e97 100644
--- a/scripts/game/network/network_game_transport.lua
+++ b/scripts/game/network/network_game_transport.lua
@@ -428,6 +428,30 @@ function NetworkGameTransport:projectile_effect(sender, owner_id, effect_type, p
 	local owner = self.unit_storage:unit(owner_id)
 	local effect_name = effect_type
 
+	if owner and kmf.vars.bugfix_enabled then
+		local player_ext = EntityAux.extension(owner, "player")
+		local last_time = Unit.get_data(owner, "kmf_projectile_effect")
+		local time = os.clock()
+		
+		if player_ext and last_time then
+
+			if effect_name == "ice_gatling_gun" then
+				if (time - last_time) < 0.12 then
+					return
+				end
+
+				Unit.set_data(owner, "kmf_last_ice_gatling", time)
+			elseif effect_name == "ice_projectiles" or effect_name == "earth_projectile" then
+				if (time - last_time) < 0.05 then
+					return
+				end
+
+			end
+		end
+
+		Unit.set_data(owner, "kmf_projectile_effect", time)
+	end
+
 	if rand_seed == 0 then
 		-- block empty
 	end
@@ -445,6 +469,13 @@ function NetworkGameTransport:projectile_effect(sender, owner_id, effect_type, p
 		element_queue[#element_queue + 1] = element
 	end
 
+	local unique_id
+
+	if kmf.vars.funprove_enabled and effect_name == "earth_projectile" then
+		unique_id = rand_seed
+		rand_seed = math.floor(math.random(0, 32000))
+	end
+
 	local elements = ElementQueue_queue_to_table(element_queue)
 	local effect_table = {
 		effect_type = effect_name,
@@ -454,6 +485,11 @@ function NetworkGameTransport:projectile_effect(sender, owner_id, effect_type, p
 		elements = elements
 	}
 
+	if unique_id then
+		effect_table.kmf_unique_id = unique_id
+		effect_table.kmf_owner_peer = sender
+	end
+
 	EntityAux.add_effect(owner, effect_table)
 end
 
@@ -772,7 +808,7 @@ function NetworkGameTransport:send_spawn_npc(unit_name, position)
 
 	local self_id = self.own_network_id
 
-	self.spawn_npc(self, self_id, unit_index, position)
+	self:spawn_npc(self_id, unit_index, position)
 end
 
 local function NetworkGameTransportAux_make_go_data_npc(u, go_type)
@@ -1121,24 +1157,26 @@ function NetworkGameTransport:send_shield_init_data_sync(u, shield_type, owner,
 
 	local owner_id = self.unit_storage:go_id(owner)
 	local damage_replacer_id = damage_replacer and self.unit_storage:go_id(damage_replacer) or owner_id
-	local var_83_0 = self
-	local var_83_1 = self.transmit_all
-	local var_83_2 = u
-	local var_83_3 = "shield_init_data_sync"
-	local var_83_4 = shield_type
-	local var_83_5 = owner_id
-	local var_83_6 = damage_replacer_id
-	local var_83_7 = mine_time_before_explode
-
-	if show_healthbar == nil then
-		-- block empty
-	end
-
-	var_83_1(var_83_0, var_83_2, var_83_3, var_83_4, var_83_5, var_83_6, var_83_7, show_healthbar, health == nil and 0 or health, max_health == nil and 0 or max_health, e1, e2, e3, e4, e5)
+	pcall(function ()
+		local var_83_0 = self
+		local var_83_1 = self.transmit_all
+		local var_83_2 = u
+		local var_83_3 = "shield_init_data_sync"
+		local var_83_4 = shield_type
+		local var_83_5 = owner_id
+		local var_83_6 = damage_replacer_id
+		local var_83_7 = mine_time_before_explode
+		
+		if show_healthbar == nil then
+			-- block empty
+		end
+	
+		var_83_1(var_83_0, var_83_2, var_83_3, var_83_4, var_83_5, var_83_6, var_83_7, show_healthbar, health == nil and 0 or health, max_health == nil and 0 or max_health, e1, e2, e3, e4, e5)
 
-	for i, _ in ipairs(temporary_queue) do
-		temporary_queue[i] = nil
-	end
+		for i, _ in ipairs(temporary_queue) do
+			temporary_queue[i] = nil
+		end
+	end)
 end
 
 function NetworkGameTransport:send_shield_unit_die(shield_unit)
@@ -1734,6 +1772,18 @@ function NetworkGameTransport:send_network_synced_projectile_hit(earth_projectil
 	local is_level_unit = false
 	local hit_go_id
 
+	
+	if kmf.vars.bugfix_enabled and hit_unit and Unit.alive(hit_unit) then
+		local time = os.clock()
+		local last_time = Unit.get_data(hit_unit, "kmf_synced_proj_hit")
+
+		if last_time and (time - last_time) < 0.33 then
+			return
+		end
+
+		Unit.set_data(hit_unit, "kmf_synced_proj_hit", time)
+	end
+
 	if hit_unit == nil then
 		hit_go_id = NetworkUnit_invalid_game_object_id
 	else
