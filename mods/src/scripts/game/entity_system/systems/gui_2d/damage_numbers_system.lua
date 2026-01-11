diff --git a/scripts/game/entity_system/systems/gui_2d/damage_numbers_system.lua b/scripts/game/entity_system/systems/gui_2d/damage_numbers_system.lua
index 6846fc5..d0f13b1 100644
--- a/scripts/game/entity_system/systems/gui_2d/damage_numbers_system.lua
+++ b/scripts/game/entity_system/systems/gui_2d/damage_numbers_system.lua
@@ -333,6 +333,23 @@ function DamageNumbersSystem:update(system_context)
 		local state = extension.state
 		local old_timer = state.timer
 
+		local unit_go_id
+		local unit_owner
+		local no_dmg_num_display = kmf.vars.pvp_gamemode == true
+		local send_dmg_num_data = false
+		
+		if no_dmg_num_display and kmf.unit_storage then
+			unit_go_id = kmf.unit_storage:go_id(u)
+			unit_owner = kmf.unit_storage:owner(u)
+
+			if unit_go_id and unit_owner then
+				if unit_owner == kmf.const.me_peer then
+					send_dmg_num_data = true
+					no_dmg_num_display = false
+				end
+			end
+		end
+
 		state.timer = state.timer + dt
 
 		if state.timer > HIT_INDICATION_BLINK_DURATION and old_timer <= HIT_INDICATION_BLINK_DURATION then
@@ -391,6 +408,57 @@ function DamageNumbersSystem:update(system_context)
 			local damage_state = extensions_cache.damage_receiver_state
 			local damage_category_data = {}
 
+			if no_dmg_num_display then
+				damage_state = {}
+			end
+
+			if send_dmg_num_data and damage_state and damage_state.damage_taken then
+				local unit_go_id = kmf.unit_storage:go_id(u)
+				local msg = ""
+
+				msg = msg .. tostring(unit_go_id) .. ";"
+
+				for j = 1, damage_state.damage_n do
+					local dmg_data = damage_state.damage[j]
+
+					msg = msg .. tostring(j) .. ";"
+					msg = msg .. "1:" .. tostring(dmg_data[1]) .. ";"
+					msg = msg .. "2:" .. tostring(dmg_data[2]) .. ";"
+					msg = msg .. "4:" .. tostring(dmg_data[4]) .. ";"
+
+					if dmg_data[5] then
+						msg = msg .. "5:" .. tostring(dmg_data[5]) .. ";"
+					end
+				end
+
+				local members = kmf.lobby_handler.connected_peers
+				local me_peer = kmf.const.me_peer
+
+				for _, peer in ipairs(members) do
+					if peer ~= me_peer then
+						kmf.send_kmf_msg(peer, msg, "dmg-num")
+					end
+				end
+			end
+
+			if no_dmg_num_display and unit_go_id and unit_owner and kmf.vars.net_dmg_states[unit_go_id] then
+				local dmg_states = kmf.vars.net_dmg_states[unit_go_id]
+				
+				if #dmg_states > 0 then
+					local new_dmg_states = {}
+					
+					damage_state = dmg_states[1]
+
+					for i, dmg_data in ipairs(dmg_states) do
+						if i > 1 then
+							new_dmg_states[#new_dmg_states + 1] = dmg_data
+						end
+					end
+
+					kmf.vars.net_dmg_states[unit_go_id] = new_dmg_states
+				end
+			end
+
 			if damage_state.damage_taken and not extensions_cache.health_state.invulnerable and not extension.state.death_handled then
 				local temp_resistance_text_cache = make_cachemap(all_text_names)
 				local temp_resistance_text_damageamount_cache = make_cachemap(all_text_names)
@@ -632,6 +700,7 @@ function DamageNumbersSystem:update(system_context)
 					local time_to_live = data.ttl
 					local start_color = data.start_color
 					local end_color = data.end_color
+					--here dmg is the value that we add to the display
 					local damage_number = self:alloc_damage_number_data(extension, category, dmg, time_to_live, number_font, start_color, end_color, world_position_node_id)
 
 					table_assign_v3(damage_number.velocity, scaled_random_3d_vector(damage_number_velocity_func(dmg)))
