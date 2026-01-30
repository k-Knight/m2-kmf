diff --git a/scripts/game/entity_system/systems/gui_2d/damage_numbers_system.lua b/scripts/game/entity_system/systems/gui_2d/damage_numbers_system.lua
index ec7bcd7..b4bea24 100644
--- a/scripts/game/entity_system/systems/gui_2d/damage_numbers_system.lua
+++ b/scripts/game/entity_system/systems/gui_2d/damage_numbers_system.lua
@@ -227,6 +227,10 @@ function DamageNumbersSystem:update_and_draw_damage_number(u, number, delta_test
 	local time_to_live = number.time_to_live
 	local dissapear_time = number.dissapear_time
 
+	if number.elapsed_time then
+		number.elapsed_time = number.elapsed_time + dt
+	end
+
 	time_to_live = time_to_live - dt
 	number.time_to_live = time_to_live
 
@@ -321,8 +325,6 @@ function DamageNumbersSystem:update(system_context)
 	local color_lut = settings.color_lut
 	local damage_number_spawn_offset_z = 0.8
 	local damage_number_velocity_func = settings.damage_number_velocity_func
-	local damage_number_text_font_size = settings.damage_text_font_size_func
-	local damage_number_number_font_size = settings.damage_number_font_size_func
 	local resistance_amount_limit = settings.resistance_amount_limit
 	local entities, entities_n = self:get_entities("damage_numbers")
 
@@ -333,6 +335,21 @@ function DamageNumbersSystem:update(system_context)
 		local state = extension.state
 		local old_timer = state.timer
 
+		local unit_go_id = kmf.unit_storage:go_id(u)
+		local unit_owner = kmf.unit_storage:owner(u)
+		local is_my_unit = unit_owner == kmf.const.me_peer
+		local no_dmg_num_display = kmf.vars.pvp_gamemode == true
+		local send_dmg_num_data = false
+
+		if no_dmg_num_display and kmf.unit_storage then
+			if unit_go_id and unit_owner then
+				if is_my_unit then
+					send_dmg_num_data = true
+					no_dmg_num_display = false
+				end
+			end
+		end
+
 		state.timer = state.timer + dt
 
 		if state.timer > HIT_INDICATION_BLINK_DURATION and old_timer <= HIT_INDICATION_BLINK_DURATION then
@@ -391,6 +408,55 @@ function DamageNumbersSystem:update(system_context)
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
+					damage_state = {
+						damage_taken = true,
+						damage = dmg_states,
+						damage_n = #dmg_states
+					}
+
+					kmf.vars.net_dmg_states[unit_go_id] = nil
+				end
+			end
+
 			if damage_state.damage_taken and not extensions_cache.health_state.invulnerable and not extension.state.death_handled then
 				local temp_resistance_text_cache = make_cachemap(all_text_names)
 				local temp_resistance_text_damageamount_cache = make_cachemap(all_text_names)
@@ -632,6 +698,7 @@ function DamageNumbersSystem:update(system_context)
 					local time_to_live = data.ttl
 					local start_color = data.start_color
 					local end_color = data.end_color
+
 					local damage_number = self:alloc_damage_number_data(extension, category, dmg, time_to_live, number_font, start_color, end_color, world_position_node_id)
 
 					table_assign_v3(damage_number.velocity, scaled_random_3d_vector(damage_number_velocity_func(dmg)))
@@ -737,6 +804,37 @@ function DamageNumbersSystem:update(system_context)
 	end
 end
 
+DamageNumbersSystem.damage_text_font_size_func = function(damage_amount, damage_number_data, change_color)
+	local dmg = damage_amount or 0
+	local font_size = DamageNumberSettings.min_font_size
+	local max = DamageNumberSettings.max_font_size
+	local font_step_size = DamageNumberSettings.font_size_step_size
+	local step_size = DamageNumberSettings.font_size_step
+	local dmg_treshold = step_size
+
+	while true do
+		if (dmg_treshold + step_size > dmg) or (font_size + font_step_size > max) then
+			break
+		end
+
+		dmg_treshold = dmg_treshold + step_size
+		font_size = font_size + font_step_size
+	end
+
+	if change_color and damage_number_data then
+		local level = (max - font_size) / font_step_size
+
+		if level < 0.5 then
+			damage_number_data.start_color[4] = damage_number_data.start_color[4] / 8
+			damage_number_data.start_color[3] = damage_number_data.start_color[3] / 2
+		elseif level < 1.5 then
+			damage_number_data.start_color[4] = damage_number_data.start_color[4] / 4
+		end
+	end
+
+	return font_size, font_size
+end
+
 function DamageNumbersSystem:alloc_damage_number_data(ext, category, value, ttl, font, start_color, end_color, _world_position_node_id)
 	local damage_list = ext.damage_numbers[category]
 	local damage_number_list_n = 0
@@ -751,9 +849,12 @@ function DamageNumbersSystem:alloc_damage_number_data(ext, category, value, ttl,
 	end
 
 	local new_index = damage_number_list_n
+	local elapsed_time = 0
 
 	if damage_number_data and damage_number_data.time_to_live > 0 then
-		-- block empty
+		if damage_number_data.elapsed_time then
+			elapsed_time = damage_number_data.elapsed_time
+		end
 	else
 		new_index = new_index + 1
 
@@ -789,15 +890,30 @@ function DamageNumbersSystem:alloc_damage_number_data(ext, category, value, ttl,
 		damage_list[new_index] = damage_number_data
 	end
 
-	damage_number_data.time_to_live = ttl
-
+	damage_number_data.time_to_live = ttl - elapsed_time
+	local change_dmg_nmbr_display = kmf.vars.pvp_gamemode or kmf.vars.funprove_enabled
 	local in_value_type = type(value)
+	local prevent_color_copy = false
+	local is_damage_direct = category == "damage_direct"
+
+	if change_dmg_nmbr_display then
+		damage_number_data.elapsed_time = elapsed_time
+		prevent_color_copy = true
+	end
 
 	assert(damage_number_data.value == nil or type(damage_number_data.value) == in_value_type, "Damage number type missmatch !")
 
 	if in_value_type == "number" then
 		local _v = (damage_number_data.value or 0) + value
 
+		if change_dmg_nmbr_display and is_damage_direct then
+			if _v > DamageNumberSettings.direct_damage_threshold.threshold then
+				damage_number_data.start_color = table.clone(DamageNumberSettings.direct_damage_threshold.color_high)
+				damage_number_data.end_color = table.clone(DamageNumberSettings.direct_damage_threshold.color_low)
+				damage_number_data.time_to_live = 0
+			end
+		end
+
 		damage_number_data.value = _v
 
 		if category == "healing" then
@@ -806,22 +922,22 @@ function DamageNumbersSystem:alloc_damage_number_data(ext, category, value, ttl,
 			damage_number_data.text = tostring(_v)
 		end
 
-		damage_number_data.start_font_size, damage_number_data.end_font_size = DamageNumberSettings.damage_number_font_size_func(_v)
+		damage_number_data.start_font_size, damage_number_data.end_font_size = DamageNumbersSystem.damage_text_font_size_func(_v, damage_number_data, prevent_color_copy)
 	else
 		damage_number_data.value = nil
 		damage_number_data.text = value
-		damage_number_data.start_font_size, damage_number_data.end_font_size = DamageNumberSettings.damage_text_font_size_func()
+		damage_number_data.start_font_size, damage_number_data.end_font_size = DamageNumbersSystem.damage_text_font_size_func()
 	end
 
 	damage_number_data.font = font
 
-	local dnd_start_color = damage_number_data.start_color
-
-	dnd_start_color[1], dnd_start_color[2], dnd_start_color[3] = start_color[1], start_color[2], start_color[3]
-
-	local dnd_end_color = damage_number_data.end_color
-
-	dnd_end_color[1], dnd_end_color[2], dnd_end_color[3] = end_color[1], end_color[2], end_color[3]
+	if not prevent_color_copy then
+		local dnd_start_color = damage_number_data.start_color
+		local dnd_end_color = damage_number_data.end_color
+	
+		dnd_start_color[1], dnd_start_color[2], dnd_start_color[3] = start_color[1], start_color[2], start_color[3]
+		dnd_end_color[1], dnd_end_color[2], dnd_end_color[3] = end_color[1], end_color[2], end_color[3]
+	end
 
 	return damage_number_data
 end
