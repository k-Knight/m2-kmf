diff --git a/scripts/game/entity_system/systems/effect/earthprojectile_effect.lua b/scripts/game/entity_system/systems/effect/earthprojectile_effect.lua
index 95d33ff..05e646e 100644
--- a/scripts/game/entity_system/systems/effect/earthprojectile_effect.lua
+++ b/scripts/game/entity_system/systems/effect/earthprojectile_effect.lua
@@ -31,12 +31,23 @@ function EarthProjectileEffect:init(context)
 	self._elements = elements
 
 	local owner = context.owner
+	local unique_id
+	local owner_peer
+
+	if context.args then
+		if context.args.kmf_unique_id then
+			unique_id = context.args.kmf_unique_id
+		end
+		if context.args.kmf_owner_peer then
+			owner_peer = context.args.kmf_owner_peer
+		end
+	end
 
 	self._owner = owner
 	self.trail_effect_ids = {}
 	self._is_local = owner and NetworkUnit.is_local_unit(owner)
-	self._is_network_synced = elements.steam == 0 and elements.arcane == 0 and elements.cold == 0 and elements.poison == 0 and elements.lightning == 0 and elements.life == 0 and elements.lok == 0 and elements.water == 0 and elements.fire == 0 and elements.shield == 0 and elements.earth > 0
-
+	local is_pure_rock = elements.steam == 0 and elements.arcane == 0 and elements.cold == 0 and elements.poison == 0 and elements.lightning == 0 and elements.life == 0 and elements.lok == 0 and elements.water == 0 and elements.fire == 0 and elements.shield == 0 and elements.earth > 0
+	self._is_network_synced = is_pure_rock
 	local earth_magnitude = elements.earth
 	local ice_magnitude = elements.ice
 
@@ -56,11 +67,22 @@ function EarthProjectileEffect:init(context)
 		self.detonation_radius = nil
 	end
 
+	local player_ext = EntityAux.extension(owner, "player")
+	self._fun_rock = nil
+
+	if player_ext and not is_pure_rock and not (elements.ice > 0) and _G.kmf.settings ~= nil and kmf.vars.funprove_enabled then
+		self._fun_rock = {}
+		self._fun_rock.is_local = self._is_local
+		self._fun_rock.spawn_time = os.clock()
+		self._fun_rock.unique_id = unique_id
+		self._fun_rock.owner_peer = owner_peer
+	end
+
 	if not self._is_local and self._is_network_synced then
 		return
 	end
 
-	local scale = context.scale
+	local scale = self:get_projectile_scale(context, is_pure_rock)
 
 	self._scale = scale
 	self._num_hits = 0
@@ -74,13 +96,13 @@ function EarthProjectileEffect:init(context)
 	self._unit_spawner = context.unit_spawner
 	self._previous_velocity = {}
 
-	if self._is_local and self._is_network_synced then
+	if self._is_local or self._fun_rock then
 		assert(context.network_transport, "Pure earth projectiles require a network_transport !")
 
 		self.network_transport = context.network_transport
 	end
 
-	self:_spawn_ball(context)
+	self:_spawn_ball(context, player_ext)
 
 	self.may_register_hit = true
 end
@@ -203,6 +225,30 @@ local function get_hit_effect_names(elements)
 	return en
 end
 
+function EarthProjectileEffect:get_max_hits()
+	return MAX_HITS
+end
+
+function EarthProjectileEffect:get_earth_projectile_raycast_cutoff()
+	return EARTH_PROJECTILE_RAYCAST_CUTOFF
+end
+
+function EarthProjectileEffect:get_earth_projectile_raycast_extra_length()
+	return EARTH_PROJECTILE_RAYCAST_EXTRA_LENGTH
+end
+
+function EarthProjectileEffect:get_projectile_scale(context, is_pure_rock)
+	return context.scale
+end
+
+function EarthProjectileEffect:pure_earth_projectile_velocity_check()
+	local my_actor = self._spawned_actor
+	local my_velocity = Actor.velocity(my_actor)
+	local _vel = Vector3.length(my_velocity)
+
+	return _vel < MIN_VELOCITY_DESTROY
+end
+
 function EarthProjectileEffect:create_abilities_effects_and_decals(owner, my_unit, my_unit_pos, elements, hit_unit, tm, create_ability, charge_factor)
 	local damage_mul, magnitudes, range_mul = SpellSettings:get_earthprojectile_ability_damage(self._pvm, owner, elements, charge_factor)
 
@@ -257,14 +303,16 @@ function EarthProjectileEffect:create_abilities_effects_and_decals(owner, my_uni
 			num_decals_created = num_decals_created + 1
 		end
 
+		local earth_projectile_raycast_cutoff = self:get_earth_projectile_raycast_cutoff()
+		local earth_projectile_raycast_extra_length = self:get_earth_projectile_raycast_extra_length()
 		local effect_table = FrameTable.alloc_table()
 
 		effect_table.effect_type = effect_name
 		effect_table.scale = effect_range
 		effect_table.elements = elements
 		effect_table.position = Vector3.box(effect_table.position or {}, my_unit_pos)
-		effect_table.raycast_cutoff = EARTH_PROJECTILE_RAYCAST_CUTOFF
-		effect_table.raycast_extra_length = EARTH_PROJECTILE_RAYCAST_EXTRA_LENGTH
+		effect_table.raycast_cutoff = earth_projectile_raycast_cutoff
+		effect_table.raycast_extra_length = earth_projectile_raycast_extra_length
 
 		EntityAux.add_effect(owner, effect_table)
 	end
@@ -326,6 +374,9 @@ function EarthProjectileEffect:create_abilities_effects_and_decals(owner, my_uni
 			num_decals_created = num_decals_created + 1
 		end
 
+		local earth_projectile_raycast_cutoff = self:get_earth_projectile_raycast_cutoff()
+		local earth_projectile_raycast_extra_length = self:get_earth_projectile_raycast_extra_length()
+
 		if effect_name then
 			local effect_table = FrameTable.alloc_table()
 
@@ -333,8 +384,8 @@ function EarthProjectileEffect:create_abilities_effects_and_decals(owner, my_uni
 			effect_table.scale = effect_range
 			effect_table.elements = elements
 			effect_table.position = Vector3.box(effect_table.position or {}, my_unit_pos)
-			effect_table.raycast_cutoff = EARTH_PROJECTILE_RAYCAST_CUTOFF
-			effect_table.raycast_extra_length = EARTH_PROJECTILE_RAYCAST_EXTRA_LENGTH
+			effect_table.raycast_cutoff = earth_projectile_raycast_cutoff
+			effect_table.raycast_extra_length = earth_projectile_raycast_extra_length
 
 			EntityAux.add_effect(owner, effect_table)
 		end
@@ -473,6 +524,11 @@ function EarthProjectileEffect:on_effect_hit(my_unit, hit_unit, hit_normal, hit_
 	Matrix4x4.set_rotation(tm, q)
 
 	local hit_unit_char_ext = EntityAux.extension(hit_unit, "character")
+	local time = os.clock()
+
+	if self._fun_rock and (time - self._fun_rock.spawn_time) < 0.1 then
+		return
+	end
 
 	if self.is_enchanted or not hit_unit_char_ext then
 		local my_actor = self._spawned_actor
@@ -483,9 +539,10 @@ function EarthProjectileEffect:on_effect_hit(my_unit, hit_unit, hit_normal, hit_
 		self._num_hits = self._num_hits + 1
 	end
 
-	cat_print("EarthProjectileEffect", "Hit ", tostring(hit_unit), ", num_hits =", tostring(self._num_hits), "/", tostring(MAX_HITS))
+	local max_hits = self:get_max_hits()
+	cat_print("EarthProjectileEffect", "Hit ", tostring(hit_unit), ", num_hits =", tostring(self._num_hits), "/", tostring(max_hits))
 
-	local create_ability = self.is_enchanted and self._num_hits > 0 or self._num_hits == MAX_HITS
+	local create_ability = (self.is_enchanted and self._num_hits > 0) or self._num_hits == max_hits
 
 	self:create_abilities_effects_and_decals(self._owner, my_unit, hit_position, elements, hit_unit, tm, create_ability, self.charge_factor)
 
@@ -611,19 +668,156 @@ function EarthProjectileEffect:update(context)
 		local my_velocity = Actor.velocity(my_actor)
 
 		if not self.is_enchanted then
-			local _vel = Vector3.length(my_velocity)
-
-			vel_too_low = _vel < MIN_VELOCITY_DESTROY
+			vel_too_low = self:pure_earth_projectile_velocity_check()
 
 			if vel_too_low then
 				cat_print("EarthProjectileEffect", "Removing projectile, velocity (" .. tostring(_vel) .. ") too low!")
 			end
 		end
 
+		if self._fun_rock then
+			if self._fun_rock.delta_z then
+				local z_vel =  Vector3.z(my_velocity)
+
+				z_vel = z_vel + (self._fun_rock.delta_z * dt)
+				Vector3.set_z(my_velocity, z_vel)
+				Actor.set_velocity(my_actor, my_velocity)
+				my_velocity = Actor.velocity(my_actor)
+			end
+
+			local anchors = self._fun_rock.anchors
+			local owner_peer = self._fun_rock.owner_peer
+			local unique_id = self._fun_rock.unique_id
+			local time = kmf.world_proxy:time()
+			local delta_t = time - (self._fun_rock.last_update_time or 0)
+
+			-- fun-balance :: elemental rock anchor-based position correction
+			if self._fun_rock.is_local and anchors and (#anchors) > 0 and delta_t > 0.05 then
+				self._fun_rock.last_update_time = time
+
+				local my_pos = Actor.position(my_actor)
+				local anchors_positions = {}
+				local weight_sum = 0
+				local unit_storage = self.network_transport.unit_storage
+
+				for _, unit in pairs(anchors) do
+					if unit and Unit.alive(unit) then
+						local go_id = unit_storage:go_id(unit)
+
+						if go_id then
+							local a_delta = my_pos - Unit.world_position(unit, 0)
+							local weight = Vector3.length(a_delta)
+
+							weight = weight * weight
+							weight = weight < 0.001 and 0.001 or weight
+							weight_sum = weight_sum + weight
+
+							anchors_positions[#anchors_positions + 1] = {
+								delta = Vector3.box({}, a_delta),
+								weight = weight,
+								go_id = unit_storage:go_id(unit)
+							}
+						end
+					end
+				end
+
+				local me_peer = self._fun_rock.me_peer
+				local members = kmf.lobby_handler.connected_peers
+				local msg = ""
+
+				msg = msg .. "eu:" .. tostring(unique_id) .. ";"
+
+				if my_velocity then
+					local vel_box = Vector3.box({}, my_velocity)
+
+					msg = msg .. "vx:" .. tostring(vel_box[1]) .. ";"
+					msg = msg .. "vy:" .. tostring(vel_box[2]) .. ";"
+					msg = msg .. "vz:" .. tostring(vel_box[3]) .. ";"
+				end
+
+				if #anchors_positions == 1 then
+					anchors_positions[1].weight = 0
+				end
+
+				for _, a_pos in pairs(anchors_positions) do
+					local key = "an-" .. tostring(a_pos.go_id) .. "-"
+
+					a_pos.weight = 1.0 - (a_pos.weight / weight_sum)
+
+					msg = msg .. key .. "dx:" .. tostring(a_pos.delta[1]) .. ";"
+					msg = msg .. key .. "dy:" .. tostring(a_pos.delta[2]) .. ";"
+					msg = msg .. key .. "dz:" .. tostring(a_pos.delta[3]) .. ";"
+					msg = msg .. key .. "wgh:" .. tostring(a_pos.weight) .. ";"
+				end
+
+				for _, peer in ipairs(members) do
+					if me_peer ~= peer then
+						kmf.send_kmf_msg(peer, msg, "eptc")
+					end
+				end
+			elseif not self._fun_rock.is_local and owner_peer and unique_id then
+				local elem_rocks_info = kmf.vars.elem_rocks_peer_dicts[owner_peer] or {}
+				local elem_rocks_data = elem_rocks_info[unique_id] or {}
+				local unit_storage = self.network_transport.unit_storage
+
+				if elem_rocks_data.data then
+					local data = elem_rocks_data.data
+					local my_vel
+					local anchors = {}
+					local weight_sum = 0
+
+					if data.vel then
+						my_vel = Vector3.unbox(data.vel)
+					end
+
+					for _, anchor_data in pairs(data.anchors) do
+						local go_id = anchor_data.go_id
+						local weight = anchor_data.weight
+						local delta
+
+						if anchor_data.delta then
+							delta = Vector3.unbox(anchor_data.delta)
+						end
+
+						if go_id and weight and delta ~= nil then
+							local unit = unit_storage:unit(go_id)
+
+							if unit and Unit.alive(unit) then
+								weight_sum = weight_sum + weight
+
+								anchors[#anchors + 1] = {
+									pos = Unit.world_position(unit, 0) + delta,
+									weight = weight
+								}
+							end
+						end
+					end
+
+					if my_vel then
+						Actor.set_velocity(my_actor, my_vel)
+					end
+
+					if #anchors > 0 then
+						local avg_pos = Vector3.zero()
+
+						for _, anchor in pairs(anchors) do
+							avg_pos = avg_pos + (anchor.pos * (anchor.weight / weight_sum))
+						end
+
+						Actor.teleport_position(my_actor, avg_pos)
+					end
+
+					kmf.vars.elem_rocks_peer_dicts[owner_peer][unique_id].data = nil
+				end
+			end
+		end
+
 		Vector3.box(self._previous_velocity, my_velocity)
 	end
 
-	if vel_too_low or self.is_enchanted and self._num_hits > 0 or self._num_hits >= MAX_HITS then
+	local max_hits = self:get_max_hits()
+
+	if vel_too_low or (self.is_enchanted and self._num_hits > 0) or max_hits <= self._num_hits then
 		if self._is_network_synced and self._is_local then
 			local u = self._spawned_unit
 			local magnitude = self.magnitude
@@ -754,14 +948,16 @@ local earth_units = {
 	"content/units/effects/projectiles/earth4"
 }
 
-function EarthProjectileEffect:_spawn_ball(context)
+function EarthProjectileEffect:_spawn_ball(context, player_ext)
 	local owner = self._owner
 	local elements = self._elements
 	local unit_name, num_elems
+	local has_ice = false
 
 	if elements.ice > 0 then
 		num_elems = math.min(elements.earth + elements.ice - 1, 4)
 		unit_name = ice_units[num_elems]
+		has_ice = true
 	else
 		num_elems = math.min(elements.earth, 4)
 		unit_name = earth_units[num_elems]
@@ -773,56 +969,28 @@ function EarthProjectileEffect:_spawn_ball(context)
 	local direction = UnitAux.forward(owner)
 	local forward_rot = Unit.world_rotation(owner, 0)
 	local velocity_scale = math.min(scale, MAX_CHARGE)
+	local percent_charge = velocity_scale / MAX_CHARGE
 	local velocity = velocity_scale / MAX_CHARGE * MAX_VELOCITY
 
 	if scale > 0 then
-		if DEBUG_VELOCITY_MATH then
-			cat_print("EarthProjectileEffect", "[spawn] unclamped charge-value = " .. tostring(scale) .. ", clamped = " .. tostring(math.min(scale, MAX_CHARGE)))
-			cat_print("EarthProjectileEffect", "[spawn] velocity = (charge / MAX_CHARGE) * MAX_VELOCITY")
-			cat_print("EarthProjectileEffect", "                 = (" .. tostring(velocity_scale) .. " / " .. tostring(MAX_CHARGE) .. ") * " .. tostring(MAX_VELOCITY) .. ")")
-			cat_print("EarthProjectileEffect", "                 = " .. tostring(velocity))
-		end
-
 		if velocity < MIN_VELOCITY then
 			velocity = MIN_VELOCITY
-
-			if DEBUG_VELOCITY_MATH then
-				cat_print("EarthProjectileEffect", "Clamped to MIN_VELOCITY = " .. tostring(MIN_VELOCITY))
-			end
 		end
 
 		if ELEMENTS_AFFECT_VELOCITY then
 			local dbg_vel = velocity
 
 			velocity = velocity * (1 / num_elems)
-
-			if DEBUG_VELOCITY_MATH then
-				cat_print("EarthProjectileEffect", "        velocity = velocity * (1.0 / num_elems)")
-				cat_print("EarthProjectileEffect", "                 = " .. tostring(dbg_vel) .. " * (1.0 / " .. tostring(num_elems) .. ")")
-				cat_print("EarthProjectileEffect", "                 = " .. tostring(velocity))
-			end
 		end
 
 		if velocity > MAX_VELOCITY then
 			velocity = MAX_VELOCITY
-
-			if DEBUG_VELOCITY_MATH then
-				cat_print("EarthProjectileEffect", "Clamping to MAX_VELOCITY = " .. tostring(MAX_VELOCITY))
-			end
 		elseif velocity < MIN_VELOCITY then
 			velocity = MIN_VELOCITY
-
-			if DEBUG_VELOCITY_MATH then
-				cat_print("EarthProjectileEffect", "Clamping to MIN_VELOCITY = " .. tostring(MIN_VELOCITY))
-			end
 		end
 
 		velocity = velocity * SpellSettings:get_artifact_modifier_for_element("earth")
 
-		if DEBUG_VELOCITY_MATH then
-			cat_print("EarthProjectileEffect", "Please note that velocity degrades over time in air. But does not affect damage!")
-		end
-
 		local elevation = pvm:get_variable(owner, "projectile_elevation")
 
 		if elevation == 1 then
@@ -853,12 +1021,78 @@ function EarthProjectileEffect:_spawn_ball(context)
 		sphere_unit = us:spawn_unit_local_register_extensions(unit_name, position, owner_rot)
 	end
 
+	Unit.set_data(sphere_unit, "kmf_proj_spawn_time", os.clock())
+	if owner then
+		Unit.set_data(sphere_unit, "kmf_proj_owner", owner)
+	end
 	context.effect_manager:bind_unit_callback(sphere_unit, self, "on_effect_hit")
 
 	local sphere_actor = unit_actor(sphere_unit, 0)
 
 	if scale > 0 then
-		Actor.set_velocity(sphere_actor, direction * velocity)
+		local vel = nil
+
+		-- fun-balance :: elemental rock anchor acquisition
+		if self._fun_rock then
+			if self._fun_rock.owner_peer and self._fun_rock.unique_id then
+				local elem_rocks_info = kmf.vars.elem_rocks_peer_dicts[self._fun_rock.owner_peer] or {}
+				local elem_rocks_data = elem_rocks_info[self._fun_rock.unique_id] or {}
+
+				elem_rocks_data.unit = sphere_unit
+				elem_rocks_info[self._fun_rock.unique_id] = elem_rocks_data
+				kmf.vars.elem_rocks_peer_dicts[self._fun_rock.owner_peer] = elem_rocks_info
+			end
+
+			local query_callback = function(actors)
+				local targets = {}
+				local cutoff_height = -1
+				local added_units = {}
+
+				for i, actor in ipairs(actors) do
+					repeat
+						local unit = Actor.unit(actor)
+
+						if (not unit or not Unit.alive(unit)) or added_units[unit] then
+							break
+						end
+
+						-- yeah, pve does not benefit, very unlucky, too much data
+						local player_ext = EntityAux.extension(unit, "player")
+
+						if player_ext then
+							added_units[unit] = true
+							targets[#targets + 1] = unit
+						end
+					until true
+				end
+
+				self._fun_rock.anchors = targets
+			end
+
+			if self._is_local then
+				self._fun_rock.me_peer = kmf.const.me_peer
+			end
+
+			context.world:physics_overlap(
+				query_callback,
+				"shape", "sphere",
+				"position", position,
+				"size", 40,
+				"types", "both",
+				"collision_filter", "character_query"
+			)
+
+			local z_scale = math.sqrt(math.min((percent_charge + 0.01) * 2.0, 1.0))
+			local max_v_speed = 45.0
+
+			vel = direction * (velocity / 2.0)
+			self._fun_rock.delta_z = max_v_speed * (-3.0) * z_scale
+			Vector3.set_z(vel, max_v_speed * z_scale)
+		else
+			vel = direction * velocity
+		end
+
+		Actor.set_velocity(sphere_actor, vel)
 	else
 		self.was_self_cast = true
 
