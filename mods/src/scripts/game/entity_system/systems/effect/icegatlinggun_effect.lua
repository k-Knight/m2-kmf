diff --git a/scripts/game/entity_system/systems/effect/icegatlinggun_effect.lua b/scripts/game/entity_system/systems/effect/icegatlinggun_effect.lua
index fe2a190..ba5cf8f 100644
--- a/scripts/game/entity_system/systems/effect/icegatlinggun_effect.lua
+++ b/scripts/game/entity_system/systems/effect/icegatlinggun_effect.lua
@@ -188,6 +188,114 @@ end
 
 function IceGatlingGunEffect:update(context)
 	self.effect_timeout = self.effect_timeout + context.dt
+	local time = os.clock()
+	local query_time = self.kmf_query_time
+	if not query_time then
+		query_time = -1
+	end
+
+	if not kmf.this_frame_ice_gatling_query_done and (time - query_time) > 0.25 then
+		local unit = self._owner
+
+		local function query_callback(actors)
+			if unit == nil or not Unit.alive(unit) then
+				return
+			end
+
+			self.kmf_targets = {}
+	
+			for i, actor in ipairs(actors) do
+				repeat
+					local unit = Actor.unit(actor)
+	
+					if not unit or unit == self._owner or not EntityAux.extension(unit, "damage_receiver") or not EntityAux.extension(unit, "character") then
+						break
+					end
+	
+					self.kmf_targets[unit] = true
+				until true
+			end
+		end
+
+		if unit and Unit.alive(unit) then
+			local pos = Unit.world_position(unit, 0) + Quaternion.forward(Unit.world_rotation(unit, 0)) * 14
+			
+			kmf.this_frame_ice_gatling_query_done = true
+			self.kmf_query_time = time
+			self._world:physics_overlap(query_callback, "shape", "sphere", "position", pos, "size", 15, "types", "both", "collision_filter", "damage_query")
+		end
+	end
+
+	if kmf.vars.funprove_enabled and self.kmf_targets then
+		local targets_info = {}
+
+		for target, _ in pairs(self.kmf_targets) do
+			if target and Unit.alive(target) then
+				targets_info[#targets_info + 1] = Vector3.box({}, Unit.world_position(target, 0))
+			end
+		end
+		
+		if #targets_info > 0 then
+
+			for my_unit, spawned in pairs(self._spawned_units) do
+				repeat
+					if not spawned or not my_unit or not Unit.alive(my_unit) then
+						break
+					end
+
+					local my_actor = Unit.actor(my_unit, 0)
+					if not my_actor then break end
+
+					local my_pos = Unit.world_position(my_unit, 0)
+					local my_vel = Actor.velocity(my_actor)
+					local my_dir = Vector3.normalize(my_vel)
+					local my_dot = Vector3.dot(my_dir, my_dir)
+
+					my_vel = Vector3.length(my_vel)
+
+					local smallest_distance = 10
+					local target_pos
+
+					for _, t_pos in ipairs(targets_info) do
+						local pos = Vector3.unbox(t_pos)
+						local dist = Vector3.distance(my_pos, pos)
+						if dist <  smallest_distance then
+							local dir = Vector3.normalize(pos - my_pos)
+							local angle = math.acos( Vector3.dot(my_dir, dir) / math.sqrt( my_dot * Vector3.dot(dir, dir) ) ) * 57.2957795131
+							if angle < 40 then
+								smallest_distance = dist
+								target_pos = pos
+							end
+						end
+					end
+
+					local my_actor = Unit.actor(my_unit, 0)
+					if not target_pos or not my_actor then
+						break
+					end
+					
+					local my_z = Vector3.z(my_pos)
+					
+					if Vector3.z(target_pos) < my_z then
+						Vector3.set_z(target_pos, my_z)
+					end
+					
+					local dir = Vector3.normalize(target_pos - my_pos)
+					dir = Vector3.lerp(my_dir, dir, 55 * context.dt)
+
+					local new_rot = Quaternion.look(dir, Vector3.up())
+					if not new_rot then break end
+					
+					if Vector3.z(dir) < 0 then
+						Vector3.set_z(dir, 0)
+					end
+					
+					Actor.set_velocity(my_actor, dir * my_vel)
+					Actor.teleport_rotation(my_actor, new_rot)
+				until true
+			end
+		end
+	end
 
 	if self.effect_timeout < SpellSettings.ice_gatling_max_shard_delay * 4 then
 		return true
@@ -214,8 +322,11 @@ function IceGatlingGunEffect:_spawn_icicle(context)
 		else
 			local staff_node = EntityAux.find_spellcasting_node(nil, self._owner, is_standalone)
 			local staff_position = staff_node.node_position
-
-			position = staff_position + direction * 0.5
+			if kmf.vars.bugfix_enabled then
+				position = staff_position + direction * 0.25
+			else
+				position = staff_position + direction * 0.5
+			end
 		end
 	else
 		local rand_xy = direction * math.random(-5, 5)
