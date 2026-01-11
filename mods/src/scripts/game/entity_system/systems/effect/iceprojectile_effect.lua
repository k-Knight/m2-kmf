diff --git a/scripts/game/entity_system/systems/effect/iceprojectile_effect.lua b/scripts/game/entity_system/systems/effect/iceprojectile_effect.lua
index 3bfe29e..0cf7c8a 100644
--- a/scripts/game/entity_system/systems/effect/iceprojectile_effect.lua
+++ b/scripts/game/entity_system/systems/effect/iceprojectile_effect.lua
@@ -69,6 +69,12 @@ function IceProjectileEffect:init(context)
 		math.random()
 	end
 
+	if elements.life > 0 then
+		self._healing_shards = true
+	else
+		self._healing_shards = false
+	end
+
 	self.is_forward = scale > 0
 	self._spawned_units = {}
 	self._num_hits = 0
@@ -79,6 +85,38 @@ function IceProjectileEffect:init(context)
 
 	local damage, magnitudes = SpellSettings:get_icicle_damage(pvm, self._owner, elements, false)
 
+	-- fun-balance :: balance ice shard damage
+	if kmf.vars.funprove_enabled then
+		if self.is_forward then
+			local mult = 2.25
+
+			-- fun-balance :: ice shotgun damage buff
+			if self._elements.earth > 0 then
+				mult = 1.75
+			end
+
+			for k, v in pairs(damage) do
+				if magnitudes[k] ~= nil then
+					local mag = magnitudes[k]
+					damage[k] = (v / math.sqrt(mag)) * mult
+				end
+			end
+		else
+			local ice_am = elements["ice"]
+
+			if ice_am then
+				local div = math.sqrt(ice_am / 2) * 2
+
+				for k, v in pairs(damage) do
+					if magnitudes[k] ~= nil then
+						local mag = magnitudes[k]
+						damage[k] = (v / div) * 1.5
+					end
+				end
+			end
+		end
+	end
+
 	assert(damage, "no damage table for iceprojectile")
 	assert(magnitudes, "no magnitudes table for iceprojectile")
 
@@ -198,6 +236,104 @@ function IceProjectileEffect:update(context)
 		self:_spawn_icicle(context)
 	end
 
+	if not self.is_forward and kmf.vars.funprove_enabled then
+		if not self.scan_done then
+			self.scan_done = {}
+			self.scan_done.finished = false
+			self.scan_done.targets = {}
+
+			if self._owner and Unit.alive(self._owner) then
+				local pos = Unit.world_position(self._owner, 0)
+
+				local function query_callback(actors)
+					for i, actor in ipairs(actors) do
+						repeat
+							local unit = Actor.unit(actor)
+
+							if not unit or unit == self._owner or not EntityAux.extension(unit, "damage_receiver") or not EntityAux.extension(unit, "character") then
+								break
+							end
+
+							self.scan_done.targets[#self.scan_done.targets + 1] = unit
+						until true
+					end
+
+					self.scan_done.finished = true
+				end
+
+				-- fun-balance :: self cast ice shard homing
+				if not self._healing_shards then
+					self._world:physics_overlap(query_callback, "shape", "sphere", "position", pos, "size", 6.5, "types", "both", "collision_filter", "damage_query")
+				else
+					self.scan_done.finished = true
+					self.scan_done.targets[1] = self._owner
+				end
+			end
+		elseif self.scan_done.finished then
+			local targets = {}
+			for _, unit in ipairs(self.scan_done.targets) do
+				repeat
+					if not unit or not Unit.alive(unit) then
+						break
+					end
+
+					targets[#targets + 1] = Vector3.box({}, Unit.world_position(unit, 0))
+				until true
+			end
+
+			for my_unit, spawned in pairs(self._spawned_units) do
+				repeat
+					if not my_unit or not spawned or not Unit.alive(my_unit) then
+						break
+					end
+
+					local my_actor = Unit.actor(my_unit, 0)
+					if not my_actor then break end
+
+					local my_pos = Unit.world_position(my_unit, 0)
+					local my_vel = Actor.velocity(my_actor)
+					local my_dir = my_vel / Vector3.length(my_vel)
+					my_vel = Vector3.length(my_vel)
+
+					local target_pos = nil
+					local min_dist = 10
+
+					for _, target in ipairs(targets) do
+						repeat
+							local pos = Vector3.unbox(target)
+							local dist = Vector3.distance(pos, my_pos)
+
+							if dist < min_dist then
+								min_dist = dist
+								target_pos = Vector3.box({}, pos)
+							end
+						until true
+					end
+
+
+					if not target_pos then break end
+					target_pos = Vector3.unbox(target_pos)
+					Vector3.set_z(target_pos, Vector3.z(target_pos) + 0.5)
+					if Vector3.z(target_pos) < 0 then
+						Vector3.set_z(target_pos, 0)
+					end
+
+					local dir = target_pos - my_pos
+					dir = dir / Vector3.length(dir)
+					dir = Vector3.lerp(my_dir, dir, 15 * context.dt)
+					local new_rot = Quaternion.look(dir, Vector3.up())
+					if not new_rot then break end
+
+					my_actor = Unit.actor(my_unit, 0)
+					if not my_actor then break end
+
+					Actor.set_velocity(my_actor, dir * my_vel)
+					Actor.teleport_rotation(my_actor, new_rot)
+				until true
+			end
+		end
+	end
+
 	return true
 end
 
@@ -205,16 +341,18 @@ local function is_enchanted(elements)
 	return elements.arcane + elements.life + elements.poison + elements.cold + elements.steam + elements.water > 0
 end
 
+local unit_names = {
+	"content/units/effects/projectiles/ice2",
+	"content/units/effects/projectiles/ice1",
+	"content/units/effects/projectiles/ice1"
+}
+
 function IceProjectileEffect:_spawn_icicle(context)
-	local unit_names = {
-		"content/units/effects/projectiles/ice2",
-		"content/units/effects/projectiles/ice1",
-		"content/units/effects/projectiles/ice1"
-	}
 	local scale = self._scale
 	local velocity_scale = scale > MAX_CHARGE and MAX_CHARGE or scale
 	local velocity = VELOCITY_BASE + VELOCITY_VAR * velocity_scale
 	local theta = scale > 0 and ICE_THETA / scale or ICE_THETA
+	local owner = self._owner
 
 	theta = theta > ICE_THETA and ICE_THETA or theta
 
@@ -229,16 +367,20 @@ function IceProjectileEffect:_spawn_icicle(context)
 	self.rand_seed, theta = Math.next_random(self.rand_seed, -half, half)
 
 	local theta_rot = Quaternion.axis_angle(Vector3.up(), math.degrees_to_radians(theta))
-	local direction = Quaternion.rotate(theta_rot, UnitAux.forward(self._owner))
+	local direction = Quaternion.rotate(theta_rot, UnitAux.forward(owner))
 	local position
 
 	if self.is_forward then
-		position = UnitAux.local_position(self._owner) + direction * 2 + Vector3.up()
+		if kmf.vars.bugfix_enabled then
+			position = UnitAux.local_position(owner) + direction * 0.25 + Vector3.up()
+		else
+			position = UnitAux.local_position(owner) + direction * 2 + Vector3.up()
+		end
 	else
 		local rand_xy = direction * math.random(-5, 5)
 		local rand_z = Vector3.up() * math.random(9, 11)
 
-		position = UnitAux.local_position(self._owner) + rand_xy + rand_z
+		position = UnitAux.local_position(owner) + rand_xy + rand_z
 	end
 
 	local ignore_new_seed, unit_index = Math.next_random(self.rand_seed, 1, #unit_names)
@@ -246,7 +388,7 @@ function IceProjectileEffect:_spawn_icicle(context)
 	local self_direction
 
 	if not self.is_forward then
-		self_direction = Quaternion.rotate(theta_rot, Vector3.normalize(UnitAux.local_position(self._owner) - position))
+		self_direction = Quaternion.rotate(theta_rot, Vector3.normalize(UnitAux.local_position(owner) - position))
 
 		local rand_dir = direction * math.random(-0.5, 0.5)
 
@@ -262,6 +404,10 @@ function IceProjectileEffect:_spawn_icicle(context)
 	end
 
 	local ice_unit = self._unit_spawner:spawn_unit_local(unit_name, position, ice_rot)
+	Unit.set_data(ice_unit, "kmf_proj_spawn_time", os.clock())
+	if owner then
+		Unit.set_data(ice_unit, "kmf_proj_owner", owner)
+	end
 
 	self._effect_manager:bind_unit_callback(ice_unit, self, "on_effect_hit")
 
