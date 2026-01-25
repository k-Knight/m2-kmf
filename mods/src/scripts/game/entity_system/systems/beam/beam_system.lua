diff --git a/scripts/game/entity_system/systems/beam/beam_system.lua b/scripts/game/entity_system/systems/beam/beam_system.lua
index d96dfc6..a879cba 100644
--- a/scripts/game/entity_system/systems/beam/beam_system.lua
+++ b/scripts/game/entity_system/systems/beam/beam_system.lua
@@ -46,6 +46,8 @@ function BeamSystem:init(context)
 	if DEBUG_BEAMS then
 		self.test_timer = 0
 	end
+
+	kmf.beam_system = self
 end
 
 function BeamSystem:finalize_setup(context)
@@ -343,6 +345,113 @@ function BeamSystem:pre_update_beams(dt)
 	end
 end
 
+_G.kmf.fix_beam_start_pos = function(beam_data)
+	if beam_data.bugfix_enabled == nil then
+		beam_data.bugfix_enabled = kmf.vars.bugfix_enabled
+	end
+
+	local unit = beam_data.owner_unit
+
+	if unit and beam_data.staff_pos and beam_data.bugfix_enabled then
+		local beam_pos = Vector3Box.unbox(beam_data.staff_pos)
+
+		if Unit.alive(unit) and beam_pos then
+			local dir = Vector3.normalize(UnitAux.forward(unit, 0))
+			Vector3.set_z(dir, 0)
+			local new_pos = beam_pos - dir * 1.15
+			beam_data.position_start = new_pos
+		end
+	else
+		return false
+	end
+
+	return true
+end
+
+-- fun-balance :: beam auto-aiming
+_G.kmf.auto_aim_beam_rotation = function(beam_data, dt)
+	if not kmf.vars.funprove_enabled then
+		return false
+	end
+
+	local unit = beam_data.owner_unit
+	local player_ext = EntityAux.extension(unit, "player")
+
+	if not Unit.alive(unit) then-- or not player_ext then
+		return false
+	end
+
+	local old_rotation = beam_data.rotation
+	if beam_data.kmf_prev_dir then
+		beam_data.rotation = Quaternion.look(Vector3.unbox(beam_data.kmf_prev_dir), Vector3.up())
+	end
+
+	if beam_data.targets == nil then
+		return false
+	end
+
+	local my_dir = Quaternion.forward(beam_data.rotation)
+	local char_dir = Quaternion.forward(Unit.world_rotation(unit, 0))
+	local my_pos = beam_data.position_start
+	local my_z = Vector3.z(my_pos)
+	local t_scores = {}
+
+	Vector3.set_z(char_dir, 0)
+	char_dir = Vector3.normalize(char_dir)
+
+	for target, _ in pairs(beam_data.targets) do
+		repeat
+			if target == nil or not Unit.alive(target) then
+				break
+			end
+
+			local t_pos = Unit.world_position(target, 0)
+			if Vector3.z(t_pos) < my_z then
+				Vector3.set_z(t_pos, my_z)
+			end
+			local t_dir = Vector3.normalize(t_pos - my_pos)
+
+			Vector3.set_z(t_dir, 0)
+			t_dir = Vector3.normalize(t_dir)
+
+			local angle = math.acos( Vector3.dot(char_dir, t_dir) / math.sqrt( Vector3.dot(char_dir, char_dir) * Vector3.dot(t_dir, t_dir) ) ) * 57.2957795131
+			local dist = Vector3.distance(t_pos, my_pos)
+			if angle > 30 then
+				break
+			end
+
+			local angle_score = (angle / 30)
+
+			angle_score = angle_score * angle_score
+			dist = dist > 0.01 and dist or 0.01
+			angle_score = angle_score > 0.01 and angle_score or 0.01
+
+			local score = (1 / angle_score) + (1.0 / dist)
+
+			t_scores[#t_scores + 1] = {dir = t_dir, score = score}
+		until true
+	end
+
+	local new_dir
+
+	if #t_scores > 0 then
+		local max_score = -1
+		for _, t_info in pairs(t_scores) do
+			if t_info.score > max_score then
+				max_score = t_info.score
+				new_dir = t_info.dir
+			end
+		end
+	else
+		new_dir = char_dir
+	end
+
+	beam_data.rotation = Quaternion.look(Vector3.lerp(my_dir, new_dir, 20 * dt), Vector3.up())
+	beam_data.kmf_prev_dir = Vector3.box({}, Quaternion.forward(beam_data.rotation))
+
+	return true
+end
+
 function BeamSystem:update_beams_recursively(dt)
 	local beams_to_update = {}
 
@@ -357,17 +466,6 @@ function BeamSystem:update_beams_recursively(dt)
 	for i = 1, num_beams do
 		repeat
 			local beam_data = self.beams[i]
-
-			if DEBUG_BEAMS and beam_data.debug_start_pos ~= nil then
-				beam_data.rotation = Quaternion.axis_angle(Vector3.up(), beam_data.debug_anim_t)
-				beam_data.position_start = Vector3.unbox(beam_data.debug_start_pos)
-				beam_data.position_end = beam_data.position_start + Quaternion.forward(beam_data.rotation) * beam_data.length
-				beam_data.debug_anim_t = beam_data.debug_anim_t + dt * beam_data.debug_anim_speed * 0.3
-				beams_to_update[#beams_to_update + 1] = beam_data
-
-				break
-			end
-
 			local owner_unit = beam_data.owner_unit
 
 			if owner_unit == nil then
@@ -380,8 +478,12 @@ function BeamSystem:update_beams_recursively(dt)
 				break
 			end
 
+			if not kmf.fix_beam_start_pos(beam_data) then
+				beam_data.position_start = Unit.world_position(beam_data.owner_staff_unit, beam_data.owner_staff_node)
+			end
 			beam_data.rotation = Unit.local_rotation(owner_unit, 0)
-			beam_data.position_start = Unit.world_position(beam_data.owner_staff_unit, beam_data.owner_staff_node)
+			_G.kmf.auto_aim_beam_rotation(beam_data, dt)
+
 			beam_data.position_end = beam_data.position_start + Quaternion.forward(beam_data.rotation) * beam_data.length
 			beams_to_update[#beams_to_update + 1] = beam_data
 		until true
