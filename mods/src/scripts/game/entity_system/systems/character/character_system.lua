diff --git a/scripts/game/entity_system/systems/character/character_system.lua b/scripts/game/entity_system/systems/character/character_system.lua
index 757c093..67a4353 100644
--- a/scripts/game/entity_system/systems/character/character_system.lua
+++ b/scripts/game/entity_system/systems/character/character_system.lua
@@ -1678,6 +1678,30 @@ local function update_forced_move(input, internal, my_pos, unit_spawner)
 end
 
 function CharacterSystem:update_magick_input(u, magick_ext, has_keyboard, input, input_data, internal, state, my_pos, input_disabled, is_dead, dt)
+	local player_ext = EntityAux.extension(u, "player")
+
+	if player_ext and kmf.vars.bugfix_enabled then
+		local char_ext = EntityAux.extension(u, "character")
+
+		if char_ext and char_ext.state and char_ext.state.current_state then
+			local char_state = char_ext.state.current_state
+
+			if char_state == "casting" or char_state == "channeling" then
+				input.magick_casted = nil
+				input_data.cast_magick = nil
+				input_data.magick_tier1 = nil
+				input_data.magick_tier2 = nil
+				input_data.magick_tier3 = nil
+				input_data.magick_tier4 = nil
+				input_data.magick1_up = nil
+				input_data.magick2_up = nil
+				input_data.magick3_up = nil
+				input_data.magick4_up = nil
+				input_disabled = true
+			end
+		end
+	end
+
 	local USE_TOGGLE = self.settings.toggle_magick_state
 	local currently_pending_magick = magick_ext.pending_magick_index
 	local pending_magick = magick_ext.pending_magick
@@ -2113,10 +2137,19 @@ local function is_stuck(dt, current_position, internal)
 		local last_position = Vector3.unbox(internal.stuck_data.last_position)
 
 		if Vector3.distance(current_position, last_position) < 0.01 then
+			local time = kmf.world_proxy:time()
+
+			internal.stuck_data.kmf_stuck_time = internal.stuck_data.kmf_stuck_time or time
+
+			if (time - internal.stuck_data.kmf_stuck_time) < 0.33 then
+				return false
+			end
+
 			internal.stuck_data = nil
 
 			return true
 		else
+			internal.stuck_data.kmf_stuck_time = nil
 			internal.stuck_data.last_position = Vector3.box({}, current_position)
 		end
 	end
@@ -2321,10 +2354,18 @@ end
 local water_navmesh_debug_drawer, gpad_magick_pos_debug_drawer, navmesh_debug_drawer
 
 function CharacterSystem:on_message(sender, category, message_id, go_id)
+	go_id = tonumber(go_id)
+	category = tostring(category)
+	message_id = tostring(message_id)
+
+	if not (go_id and category and message_id) then
+		return
+	end
+
 	if go_id and message_id == "revive" then
 		local unit = self.unit_storage:unit(go_id)
 
-		if Unit.alive(unit) then
+		if unit and Unit.alive(unit) then
 			local character_state = EntityAux.state(unit, "character")
 
 			if self.settings.enable_revive_message_sound then
@@ -2397,12 +2438,31 @@ function CharacterSystem:update_characters(context)
 
 	for i = 1, entities_n do
 		local extension_data = entities[i]
-		local u, extension = extension_data.unit, extension_data.extension
+		if not extension_data then
+			goto continue
+		end
+		local u = extension_data.unit
+		if not u then
+			goto continue
+		end
+		local extension = extension_data.extension
+		if not extension then
+			goto continue
+		end
 		local uwp = Unit.world_position(u, 0)
 		local internal = extension.internal
+		if not internal then
+			goto continue
+		end
 		local input = extension.input
 		local state = extension.state
+		if not internal.input_ext then
+			goto continue
+		end
 		local input_controller_state = internal.input_ext.state
+		if not input_controller_state then
+			goto continue
+		end
 		local input_data = input_controller_state.input_data
 		local has_keyboard = input_controller_state.controller == "keyboard"
 		local magick_ext = EntityAux.extension(u, "magick_user")
@@ -2518,6 +2578,7 @@ function CharacterSystem:update_characters(context)
 		end
 
 		input.took_phys_damage = nil
+		::continue::
 	end
 end
 
@@ -2620,7 +2681,31 @@ function CharacterSystem:update_aim_assist(u, input_data, spellcast_internal)
 	end
 end
 
+function CharacterSystem:delete_aiming_units(internal)
+	for _, aim_unit in pairs(internal.aim_units) do
+		self.unit_spawner:mark_for_deletion(aim_unit)
+	end
+
+	internal.aim_units = nil
+	internal.aim_units_spawn_delay = nil
+end
+
+function CharacterSystem:create_new_aiming_dot(internal, magick, _wp, scale, dot_color)
+	local aim_unit = self.unit_spawner:spawn_unit_local(GameSettings.projections_charge_dots, _wp, Quaternion.identity())
+
+	internal.aim_units[#internal.aim_units + 1] = aim_unit
+
+	local mesh = Unit.mesh(aim_unit, "g_body")
+	local material = Mesh.material(mesh, "g_material")
+
+	Material.set_vector3(material, "color_tint", dot_color)
+	Material.set_vector3(material, "scale", scale)
+end
+
 function CharacterSystem:update_character_input(input_disabled, failsafe_switch_back, internal, state, hud_intersect_input_data_clear, has_keyboard, input_data, u, magick_ext, camera, hud_gui_intersects, uwp, input, ignore_rotation, ignore_click, dt, debug_drawing_enabled, cutscene_running)
+	local movement_convenience = kmf.vars.movement_convenience.enabled
+	local char_player_ext = EntityAux.extension(u, "player")
+
 	if not input_disabled then
 		if not has_keyboard then
 			self:update_aim_assist(u, input_data, internal.spellcast_ext.internal)
@@ -2647,6 +2732,7 @@ function CharacterSystem:update_character_input(input_disabled, failsafe_switch_
 		local cursor_look_x, cursor_look_y = 0, 0
 		local _wp = uwp
 		local last_valid_gpad_rel_aim
+		local cursor_delta_x, cursor_delta_y
 
 		if has_keyboard then
 			local cursor = input_data.cursor
@@ -2658,6 +2744,29 @@ function CharacterSystem:update_character_input(input_disabled, failsafe_switch_
 				input.align_towards = nil
 			end
 
+			if movement_convenience and not hud_gui_intersects then
+				local cur_cursor = Mouse.axis(Mouse.axis_index("cursor"), Mouse.RAW, 3)
+
+				cursor_delta_x = cur_cursor[1] - kmf.vars.movement_convenience.orig_x
+				cursor_delta_y = cur_cursor[2] - kmf.vars.movement_convenience.orig_y
+
+				local dist = math.sqrt(cursor_delta_x * cursor_delta_x + cursor_delta_y * cursor_delta_y)
+				local max_dist = kmf.vars.movement_convenience.screen_scale / 20
+
+				if dist > max_dist then
+					dist = dist / max_dist
+					local new_delta_x = cursor_delta_x / dist
+					local new_delta_y = cursor_delta_y / dist
+					Window.set_cursor_position(Vector2(kmf.vars.movement_convenience.orig_x + new_delta_x, kmf.vars.movement_convenience.orig_y + new_delta_y))
+				end
+
+
+				cursor_delta_x = cur_cursor[1] - kmf.vars.movement_convenience.orig_x
+				cursor_delta_y = cur_cursor[2] - kmf.vars.movement_convenience.orig_y
+				cursor_delta_x = math.abs(cursor_delta_x) > 3 and cursor_delta_x or 0
+				cursor_delta_y = math.abs(cursor_delta_y) > 3 and cursor_delta_y or 0
+			end
+
 			internal.prev_cursor_pos = {
 				x = cursor_move_x,
 				y = cursor_move_y
@@ -2835,13 +2944,34 @@ function CharacterSystem:update_character_input(input_disabled, failsafe_switch_
 
 		local plane = Plane.from_point_and_normal(_plane_pos, Vector3.up())
 		local cam_movement, dir_movement = camera:screen_ray(cursor_move_x, cursor_move_y)
-		local t = Intersect.ray_plane(cam_movement, dir_movement, plane)
 
+		local t = Intersect.ray_plane(cam_movement, dir_movement, plane)
 		if t == nil then
 			t = 0
 		end
 
 		local intersect_pos_movement = cam_movement + dir_movement * t
+
+		if movement_convenience and cursor_delta_x and cursor_delta_y then
+			local delta_mov, delta_dir = camera:screen_ray(cursor_move_x + cursor_delta_x, cursor_move_y + cursor_delta_y)
+
+			local t2 = Intersect.ray_plane(cam_movement, dir_movement, plane)
+			if t2 == nil then
+				t2 = 0
+			end
+
+			local intersect_pos_movement2 = delta_mov + delta_dir * t2
+			local dir = Vector3.normalize(intersect_pos_movement2 - intersect_pos_movement)
+
+			dir.z = 0
+
+			if Vector3.length(dir) > 0.3 and u and Unit.alive(u) then
+				intersect_pos_movement = Unit.world_position(u, 0) + (dir * 100)
+				input_data.do_move = 0.9
+			end
+		end
+
+
 		local intersect_pos_gpad_magick
 
 		if magick_ext and state.gpad_magick_aim_rel_pos then
@@ -2861,72 +2991,124 @@ function CharacterSystem:update_character_input(input_disabled, failsafe_switch_
 		local magick = magick_ext and magick_ext.pending_magick or nil
 
 		if axis and InputAux.axis_has_values(axis) or magick and magick.cast_type == "direction" then
+			local time = os.clock()
 			local directional_magick = magick and magick.cast_type == "direction"
 
 			if directional_magick or input.spell_charge and input.args == "force_charge" and self.settings.show_reticles and state.current_state ~= "panic" then
-				local dot_distance = SpellSettings.charge_dot_distance or 2
+				local dot_distance
+				local funprove_enabled = kmf.vars.funprove_enabled
+				if not funprove_enabled then
+					dot_distance = SpellSettings.charge_dot_distance or 2
+				else
+					dot_distance = 2.5
+				end
 
 				dot_distance = magick and magick.projection_unit_dutt_distance or dot_distance
 				internal.charge_time = internal.charge_time and internal.charge_time + dt or 0
 
-				if not internal.aim_units then
-					if not internal.aim_units_spawn_delay then
-						internal.aim_units_spawn_delay = true
-					else
-						internal.aim_units_timer = nil
-						internal.aim_units = {}
-						internal.charge_time = 0
-						internal.colored_dots = 1
-
-						local number_of_dots = SpellSettings.charge_dot_num_dots or 14
+				if not internal.kmf_start_chage_time then
+					internal.kmf_start_chage_time = time
+					internal.kmf_count_aim_units = 0
+				end
 
-						number_of_dots = magick and magick.projection_unit_num_dutts or number_of_dots
+				local diff = time - internal.kmf_start_chage_time
+				diff = diff < SpellSettings.projectile_max_charge_duration and diff or SpellSettings.projectile_max_charge_duration
+				local covered_distance = diff * 28
+				covered_distance = covered_distance >= 1 and covered_distance or 0
+
+				-- fun-balance :: earth charge recticles
+				if funprove_enabled and not internal.kmf_aim_spell_elems and internal.spellcast_ext and internal.spellcast_ext.internal and internal.spellcast_ext.internal._waiting_spell then
+					local waiting_data = internal.spellcast_ext.internal._waiting_spell.data
+					local elements = waiting_data.elements
+
+					if elements then
+						local has_ice = elements.ice > 0
+						local rock_amnt = elements.earth
+
+						internal.kmf_aim_spell_elems = {
+							has_ice = elements.ice > 0,
+							rock_amnt = elements.earth,
+							ice_amnt = elements.ice,
+							effect_type = waiting_data.effect_type
+						}
+					end
+				end
 
-						local dot_color = SpellSettings.use_colored_projectile_charge_reticles and dot_color_for_spell(internal.spellcast_ext.input.element_queue) or Vector3.unbox(SpellSettings.charge_dot_color) or Vector3(1, 1, 1)
+				if internal.kmf_aim_spell_elems then
+					if internal.kmf_aim_spell_elems.has_ice and not (internal.kmf_aim_spell_elems.effect_type == "earth_projectile") then
+						covered_distance = covered_distance / 2
+					elseif internal.kmf_aim_spell_elems.rock_amnt > 1 or internal.kmf_aim_spell_elems.ice_amnt > 1 then
+						local rock_amnt = internal.kmf_aim_spell_elems.rock_amnt
+						local amnt = (rock_amnt * 1.25) + internal.kmf_aim_spell_elems.ice_amnt - 1
 
-						if magick and magick.projection_color then
-							dot_color = Vector3.unbox(magick.projection_color)
+						if rock_amnt == 2 then
+							amnt = amnt + 0.5
 						end
+						covered_distance = covered_distance / amnt * 1.1
+					end
+				end
 
-						local scale = magick and magick.projection_unit_scale and Vector3.unbox(magick.projection_unit_scale) or Vector3(0.75, 0.75, 0.75)
+				covered_distance = covered_distance < 30 and covered_distance or 30
+				local desired_units = math.floor(covered_distance / dot_distance)
 
-						for i = dot_distance, number_of_dots * dot_distance, dot_distance do
-							local aim_unit = self.unit_spawner:spawn_unit_local(GameSettings.projections_charge_dots, _wp, Quaternion.identity())
+				if not internal.aim_units and not (funprove_enabled and desired_units < 1) then
+					internal.aim_units_timer = nil
+					internal.aim_units = {}
+					internal.colored_dots = 1
 
-							internal.aim_units[#internal.aim_units + 1] = aim_unit
+					local number_of_dots
+					local scale
 
-							local mesh = Unit.mesh(aim_unit, "g_body")
-							local material = Mesh.material(mesh, "g_material")
+					local dot_color = SpellSettings.use_colored_projectile_charge_reticles and dot_color_for_spell(internal.spellcast_ext.input.element_queue) or Vector3.unbox(SpellSettings.charge_dot_color) or Vector3(1, 1, 1)
 
-							Material.set_vector3(material, "color_tint", dot_color)
-							Material.set_vector3(material, "scale", scale)
-						end
+					if magick and magick.projection_color then
+						dot_color = Vector3.unbox(magick.projection_color)
+					end
 
-						local aim_unit_name
+					scale = magick and magick.projection_unit_scale and Vector3.unbox(magick.projection_unit_scale) or Vector3(0.75, 0.75, 0.75)
+					local aim_unit_name
 
-						if directional_magick and magick.projection_unit then
-							aim_unit_name = magick.projection_unit
-						else
-							aim_unit_name = GameSettings.projection_charge_target
-						end
+					if directional_magick and magick.projection_unit then
+						aim_unit_name = magick.projection_unit
+					else
+						aim_unit_name = GameSettings.projection_charge_target
+					end
 
-						local aim_unit = self.unit_spawner:spawn_unit_local(aim_unit_name, _wp, Quaternion.identity())
+					local aim_unit = self.unit_spawner:spawn_unit_local(aim_unit_name, _wp, Quaternion.identity())
 
-						internal.aim_units[#internal.aim_units + 1] = aim_unit
+					internal.aim_units[#internal.aim_units + 1] = aim_unit
 
-						local mesh = Unit.mesh(aim_unit, "g_body")
-						local material = Mesh.material(mesh, "decal_mat") or Mesh.material(mesh, "g_material")
+					local mesh = Unit.mesh(aim_unit, "g_body")
+					local material = Mesh.material(mesh, "decal_mat") or Mesh.material(mesh, "g_material")
 
-						if material then
-							Material.set_vector3(material, "color_tint", dot_color)
-							Material.set_vector3(material, "scale", scale)
-						end
+					if material then
+						Material.set_vector3(material, "color_tint", dot_color)
+						Material.set_vector3(material, "scale", scale)
+					end
 
-						internal.dot_color = Vector3.box({}, dot_color)
+					internal.dot_color = Vector3.box({}, dot_color)
+
+					if not funprove_enabled then
+						number_of_dots = SpellSettings.charge_dot_num_dots or 14
+						number_of_dots = magick and magick.projection_unit_num_dutts or number_of_dots
+						scale = magick and magick.projection_unit_scale and Vector3.unbox(magick.projection_unit_scale) or Vector3(0.75, 0.75, 0.75)
+					else
+						number_of_dots = internal.kmf_count_aim_units
+						scale = magick and magick.projection_unit_scale and Vector3.unbox(magick.projection_unit_scale) or Vector3(0.5, 0.5, 0.5)
+					end
+
+					for i = dot_distance, number_of_dots * dot_distance, dot_distance do
+						self:create_new_aiming_dot(internal, magick, _wp, scale, dot_color)
 					end
 				end
 
 				if internal.aim_units then
+					if funprove_enabled and (desired_units - 2) > internal.kmf_count_aim_units then
+						local scale = magick and magick.projection_unit_scale and Vector3.unbox(magick.projection_unit_scale) or Vector3(0.5, 0.5, 0.5)
+						self:create_new_aiming_dot(internal, magick, _wp, scale, Vector3.unbox(internal.dot_color))
+						internal.kmf_count_aim_units = internal.kmf_count_aim_units + 1
+					end
+
 					local number_of_dots = SpellSettings.charge_dot_num_dots or 14
 
 					if internal.charge_time >= SpellSettings.projectile_max_charge_duration / (number_of_dots + 1) then
@@ -2939,8 +3121,16 @@ function CharacterSystem:update_character_input(input_disabled, failsafe_switch_
 					local aim = Quaternion.forward(unit_rot)
 					local pos = Unit.local_position(u, 0)
 
+					local end_pos
+					if funprove_enabled then
+						end_pos = pos + aim * covered_distance
+					else
+						local unit_count = #internal.aim_units
+						end_pos = pos + dot_distance * unit_count * aim
+					end
+
 					for i, aim_unit in ipairs(internal.aim_units) do
-						Unit.set_local_position(aim_unit, 0, pos + i * dot_distance * aim)
+						Unit.set_local_position(aim_unit, 0, end_pos - i * dot_distance * aim)
 
 						local rotation
 
@@ -2967,21 +3157,18 @@ function CharacterSystem:update_character_input(input_disabled, failsafe_switch_
 						Unit.set_unit_visibility(aim_unit, not cutscene_running)
 					end
 				end
-			elseif internal.aim_units then
-				for _, aim_unit in pairs(internal.aim_units) do
-					self.unit_spawner:mark_for_deletion(aim_unit)
-				end
+			else
+				internal.kmf_count_aim_units = 0
+				internal.kmf_aim_spell_elems = nil
+				internal.kmf_start_chage_time = time
+				internal.charge_time = 0
 
-				internal.aim_units = nil
-				internal.aim_units_spawn_delay = nil
+				if internal.aim_units then
+					self:delete_aiming_units(internal)
+				end
 			end
 		elseif internal.aim_units then
-			for _, aim_unit in pairs(internal.aim_units) do
-				self.unit_spawner:mark_for_deletion(aim_unit)
-			end
-
-			internal.aim_units = nil
-			internal.aim_units_spawn_delay = nil
+			self:delete_aiming_units(internal)
 		end
 
 		local activate_position = not ignore_click and intersect_pos_movement
@@ -2998,7 +3185,22 @@ function CharacterSystem:update_character_input(input_disabled, failsafe_switch_
 			end
 		end
 
-		if input_data.do_move and input_data.do_move < 0.5 and internal.loco_ext.state.blocked and not internal.pending_magick or input.frozen then
+		local dont_forgive_block = false
+
+		if not internal.loco_ext.state.blocked then
+			internal.kmf_last_move_stop_timer = nil
+		else
+			local time = kmf.world_proxy:time()
+
+			dont_forgive_block = true
+			internal.kmf_last_move_stop_timer = internal.kmf_last_move_stop_timer or time
+
+			if (time - internal.kmf_last_move_stop_timer) < 0.33 then
+				dont_forgive_block = false
+			end
+		end
+
+		if input_data.do_move and input_data.do_move < 0.5 and dont_forgive_block and not internal.pending_magick or input.frozen then
 			internal.move_destination = nil
 
 			if internal.move_to_unit then
@@ -3018,7 +3220,7 @@ function CharacterSystem:update_character_input(input_disabled, failsafe_switch_
 
 		if not internal.rotation_lock_time then
 			if has_keyboard then
-				if not ignore_rotation then
+				if not ignore_rotation and not movement_convenience then
 					update_align_towards(u, dt, input, internal, uwp, cam_movement, dir_movement)
 				end
 			else
@@ -3266,7 +3468,6 @@ function CharacterSystem:update_character_water(entities, n_entities, dt)
 end
 
 function CharacterSystem:update_ai_characters(entities, entities_n)
-	local type, pairs = type, pairs
 	local table_clone = table.clone
 	local link_system = self.link_system
 	local network = self.network_transport
