diff --git a/scripts/game/entity_system/systems/spellcasting/spell_lightning_helper.lua b/scripts/game/entity_system/systems/spellcasting/spell_lightning_helper.lua
index 970a473..11e10c8 100644
--- a/scripts/game/entity_system/systems/spellcasting/spell_lightning_helper.lua
+++ b/scripts/game/entity_system/systems/spellcasting/spell_lightning_helper.lua
@@ -65,6 +65,10 @@ local function _sort_by_distance_and_resistance(a, b)
 	return a.distance < b.distance
 end
 
+local function _sort_by_attack_time(a, b)
+	return a.dmg_time < b.dmg_time
+end
+
 local function _remove_from_table(item, tbl)
 	for i, _u in ipairs(tbl) do
 		if item == _u then
@@ -363,6 +367,348 @@ function Spells_Lightning_Helper.cast_lightning_bolt(data, start_pos_box, forwar
 	end
 end
 
+-- fun-balance :: make some obstacles block ligt path
+function Spells_Lightning_Helper.cast_lightning_bolt_obstacle_respectful(data, start_pos_box, forward_box, caster, is_local, world, chain, base_range, arc_range, arc_width, effect_table, effect_manager, _this_id, is_standalone, z_lvl, prev_target)
+	if not data.kmf_targets[_this_id] then
+		data.kmf_targets[_this_id] = {}
+	end
+	data.kmf_potential_targets[_this_id] = {}
+
+	local first = _this_id == 1 and true or false
+	local range = first and base_range or arc_range
+	if not first and data.kmf_is_aoe then
+		range = range / _this_id
+	end
+	local start_pos = Vector3.unbox(start_pos_box)
+	local check_start_pos = Vector3.unbox(start_pos_box)
+	if first then
+		z_lvl = Vector3.z(check_start_pos) - (data.kmf_is_aoe and 0.5 or 0.15)
+	end
+	Vector3.set_z(check_start_pos, z_lvl)
+
+	assert(start_pos, "Invalid start_pos for lightning !")
+
+	local time = os.clock()
+	local old_targets = data.kmf_targets[_this_id]
+	local old_size = #old_targets
+
+	data.kmf_targets[_this_id] = {}
+
+	for i=#old_targets,1,-1 do
+		local target = old_targets[i]
+
+		if (time - target.time) < 0.5 and target.unit and Unit.alive(target.unit) then
+			local exists = false
+
+			for _, existing in pairs(data.kmf_targets[_this_id]) do
+				if existing.unit == target.unit then
+					exists = true
+					break
+				end
+			end
+
+			if not exists then
+				target.dmg_time = target.dmg_time or 0
+				data.kmf_targets[_this_id][#(data.kmf_targets[_this_id]) + 1] = target
+			end
+		end
+	end
+
+	local forward = Vector3.unbox(forward_box)
+	local overlaps = data.overlaps
+	local min_dot = math.cos(arc_width)
+
+	if DO_DEBUG_DRAW then
+		local dbg_id = "lightning_fov_" .. tostring(_this_id)
+		local dbg_c = first and Color(0, 255, 0) or Color(10 * _this_id, 0, 10 * _this_id)
+
+		Debug.drawer(dbg_id):reset()
+		Debug.drawer(dbg_id):fov(start_pos, forward, math.radians_to_degrees(arc_width), range, dbg_c)
+	end
+
+	table.filter_inplace(overlaps, Unit_alive)
+
+	local caster_data
+	local added_units = {}
+	local physics_world = world:physics_world()
+	local visual_miss_range = range
+
+	if data.kmf_is_aoe then
+		visual_miss_range = visual_miss_range * 0.90
+	end
+
+	for i, u in ipairs(overlaps) do
+		local u_pos = Unit.world_position(u, 0)
+
+		if u == caster then
+			yellow_text("Standalone lightning ignores hitting self !!!!!")
+		else
+			local delta = u_pos - start_pos
+			local dist = Vector3.length(delta)
+			local dir
+
+			if dist <= range then
+				dir = dist > 0 and delta or forward
+
+				local flat_forward = Vector3.normalize(Vector3(forward.x, forward.y, 0))
+				local flat_dir = Vector3.normalize(Vector3(dir.x, dir.y, 0))
+				local d_dot_n = Vector3.dot(flat_forward, flat_dir)
+
+				dir = Vector3.normalize(dir)
+
+				local dot_by_distance = math.min(0.3 * dist, min_dot)
+
+				if DO_DEBUG_DRAW then
+					local dbg_id = "lightning_fov_2_" .. tostring(_this_id)
+					local dbg_c = Color(255, 255, 255)
+
+					Debug.drawer(dbg_id):reset()
+					Debug.drawer(dbg_id):fov(start_pos, forward, math.radians_to_degrees(math.acos(dot_by_distance)), range, dbg_c)
+				end
+
+				if dot_by_distance <= d_dot_n then
+					if u == caster then
+						caster_data = {
+							unit = u,
+							distance = dist,
+							pos = Vector3.box({}, u_pos),
+							direction = Vector3.box({}, dir)
+						}
+					elseif u ~= prev_target and not added_units[u] then
+						local target = {
+							unit = u,
+							distance = dist,
+							pos = Vector3.box({}, u_pos),
+							direction = Vector3.box({}, dir)
+						}
+
+						added_units[u] = true
+						data.kmf_potential_targets[_this_id][#(data.kmf_potential_targets[_this_id]) + 1] = target
+
+						local target_verify_callback = function(hits)
+							local found_blocker = false
+
+							if hits then
+								local hit_count = #hits
+					
+								for i=1, hit_count do
+									if hits[i] and hits[i][4] then
+										local unit = Actor.unit(hits[i][4])
+					
+										if unit and Unit.alive(unit) then
+											if target.unit == unit then
+												break
+											end
+
+											local is_elemental_wall = Unit.get_data(unit, "is_elemental_wall")
+											local is_pure_shield = Unit.get_data(unit, "is_pure_shield")
+					
+											if is_elemental_wall or is_pure_shield then
+												found_blocker = true
+												break
+											end
+										end
+									end
+								end
+							end
+
+							if not found_blocker then
+								data.kmf_targets[_this_id][#(data.kmf_targets[_this_id]) + 1] = {
+									unit = target.unit,
+									distance = target.distance,
+									pos = target.pos,
+									direction = target.direction,
+									time = os.clock()
+								}
+							end
+						end
+
+						local my_dir = Vector3(u_pos.x, u_pos.y, u_pos.z + 0.5) - start_pos
+						local my_ray = PhysicsWorld.make_raycast(physics_world, target_verify_callback, "all", "collision_filter", "lightning_query")
+
+						Raycast.cast(my_ray, check_start_pos, my_dir, Vector3.length(my_dir))
+					end
+				end
+			end
+		end
+	end
+
+	if data.kmf_is_aoe and first then
+		table.sort(data.kmf_targets[_this_id], _sort_by_attack_time)
+	else
+		table.sort(data.kmf_targets[_this_id], _sort_by_distance_and_resistance)
+	end
+
+	local target_count = #(data.kmf_targets[_this_id])
+
+	if caster_data and _this_id > 1 and _this_id < data.initial_num_jumps and _this_id >= 3 then
+		data.kmf_targets[_this_id][target_count + 1] = caster_data
+	end
+
+	target_count = #(data.kmf_targets[_this_id])
+
+	if target_count == 0 then
+		if first then
+			Spells_Lightning_Helper.cast_lightning_bolt_miss(start_pos_box, forward_box, caster, physics_world, visual_miss_range, arc_width, effect_table, is_standalone)
+		end
+	else
+		local MAX_RAYCASTS = 3
+		local ray
+		local idx = 1
+		local next_idx = 1
+		local has_hit = false
+		local start_pos_boxed = Vector3Box(start_pos)
+		local effect_start_pos = start_pos_box
+
+		local function callback(hit, pos, distance, normal, actor)
+			if has_hit then
+				return
+			end
+
+			local target = data.kmf_targets[_this_id][idx]
+
+			if target then
+				local u = target.unit
+				local is_caster = u == caster
+
+				if hit then
+					local inner_start_pos = Vector3.unbox(effect_start_pos)
+
+					if Unit_alive(u) then
+						if is_local then
+							local damage_receiver = EntityAux.extension(u, "damage_receiver")
+
+							if damage_receiver then
+								if data.damage and is_caster then
+									data.lightning_hit_caster = true
+								end
+
+								ATTACKERS_TABLE[1] = caster
+
+								target.dmg_time = os.clock()
+								EntityAux.add_damage(u, ATTACKERS_TABLE, data.damage, "force", data.scale_damage)
+
+								ATTACKERS_TABLE[1] = nil
+							end
+
+							local status_ext = EntityAux.extension(u, "status")
+
+							if status_ext then
+								EntityAux.add_status_elements_by_extension(status_ext, data.element_queue, data.caster)
+							end
+						end
+
+						effect_manager:play_sound("play_spell_lightning_hit", u)
+
+						local effect_pos = Vector3.unbox(target.pos)
+						local pose, extents = Unit.box(u)
+						local effect_height = math.min(extents[3], 2)
+
+						effect_pos[3] = effect_pos[3] + effect_height * 0.5
+
+						if first and data.kmf_is_aoe then
+							Spells_Lightning_Helper.cast_lightning_bolt_miss(start_pos_box, forward_box, caster, physics_world, visual_miss_range, arc_width, effect_table, is_standalone)
+						else
+							Spells_Lightning_Helper.spawn_lightning_effect(caster, inner_start_pos, effect_pos, first, u, effect_table, nil, is_standalone)
+						end
+
+						local status_template_name = Unit.has_data(u, "status_template") and Unit.get_data(u, "status_template") or nil
+						local status_template = not status_template_name and StatusTemplates.default or StatusTemplates[status_template_name]
+						local status_effects = status_template.status_effect_settings
+
+						if status_effects.lightning then
+							local effect = status_effects.lightning.effects[1]
+							local joint
+							local health_ext = EntityAux.extension(u, "health")
+
+							if health_ext then
+								local joint_name = health_ext.state.status_joint
+
+								if joint_name and Unit.has_node(u, joint_name) then
+									joint = Unit.node(u, joint_name)
+								end
+							end
+
+							if not joint then
+								local joint_name = status_effects.lightning and status_effects.lightning.joint
+
+								if joint_name and Unit.has_node(u, joint_name) then
+									joint = Unit.node(u, joint_name)
+								end
+							end
+
+							joint = joint or 0
+
+							world:create_particles_linked(effect, u, joint, ParticleOrphanedPolicy.destroy)
+						end
+
+						if chain then
+							_remove_from_table(u, overlaps)
+
+							local next_chain = true
+
+							if u == caster then
+								next_chain = false
+							end
+
+							data.num_jumps = data.num_jumps - 1
+
+							if data.num_jumps <= 0 then
+								has_hit = true
+								next_chain = false
+							end
+
+							Spells_Lightning_Helper.cast_lightning_bolt_obstacle_respectful(data, target.pos, target.direction, caster, is_local, world, next_chain, base_range, arc_range, JUMP_ARC_WIDTH, effect_table, effect_manager, _this_id + 1, is_standalone, z_lvl, u)
+						end
+
+						has_hit = true
+
+						return
+					end
+				end
+
+				idx = idx + 1
+
+				if idx == next_idx then
+					if next_idx <= target_count then
+						local start_position
+
+						if first then
+							start_position = Unit.world_position(caster, 0)
+						else
+							start_position = Vector3.unbox(start_pos_box)
+						end
+
+						while next_idx <= target_count and next_idx <= MAX_RAYCASTS do
+							local target = data.kmf_targets[_this_id][next_idx]
+							local u_pos = Unit.world_position(target.unit, 0)
+							local dir = Vector3.unbox(target.direction)
+
+							Raycasts.cast(ray, start_position, dir, target.distance)
+
+							next_idx = next_idx + 1
+						end
+					elseif first then
+						Spells_Lightning_Helper.cast_lightning_bolt_miss(start_pos_box, forward_box, caster, physics_world, visual_miss_range, arc_width, effect_table, is_standalone)
+					end
+				end
+			end
+		end
+
+		ray = PhysicsWorld.make_raycast(physics_world, callback, "collision_filter", "lightning_query")
+
+		while next_idx <= target_count and next_idx <= MAX_RAYCASTS do
+			local target = data.kmf_targets[_this_id][next_idx]
+			local u_pos = Unit.world_position(target.unit, 0)
+			local dir = Vector3.unbox(target.direction)
+
+			Raycast.cast(ray, start_pos, dir, range)
+
+			next_idx = next_idx + 1
+		end
+	end
+end
+
 function Spells_Lightning_Helper.spawn_lightning_effect(caster, start_pos, end_pos, play_start, hit_unit, effect_table, is_miss, is_standalone)
 	if Unit.alive(caster) == false then
 		return
