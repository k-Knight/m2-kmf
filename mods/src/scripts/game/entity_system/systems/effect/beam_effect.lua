diff --git a/scripts/game/entity_system/systems/effect/beam_effect.lua b/scripts/game/entity_system/systems/effect/beam_effect.lua
index b6d6040..e6fc84e 100644
--- a/scripts/game/entity_system/systems/effect/beam_effect.lua
+++ b/scripts/game/entity_system/systems/effect/beam_effect.lua
@@ -256,6 +256,40 @@ function BeamEffect:update(dt)
 		self.staff_unit = self.beam_data.owner_staff_unit
 	end
 
+	local time = os.clock()
+	local beam_data = self.beam_data
+	local unit = beam_data.owner_unit
+
+	if beam_data.kmf_scan_time == nil then
+		beam_data.kmf_scan_time = -1
+	end
+
+	if unit and Unit.alive(unit) and not kmf.this_frame_beam_query_done and time - beam_data.kmf_scan_time > 0.25 then
+		kmf.this_frame_beam_query_done = true
+		beam_data.kmf_scan_time = time
+		local pos = Unit.world_position(unit, 0) + Quaternion.forward(Unit.world_rotation(unit, 0)) * 14
+		local function query_callback(actors)
+			if beam_data == nil or beam_data.owner_unit == nil then
+				return
+			end
+		
+			beam_data.targets = {}
+		
+			for i, actor in ipairs(actors) do
+				repeat
+					local unit = Actor.unit(actor)
+				
+					if not unit or unit == beam_data.owner_unit or not EntityAux.extension(unit, "damage_receiver") or not EntityAux.extension(unit, "character") then
+						break
+					end
+				
+					beam_data.targets[unit] = true
+				until true
+			end
+		end
+		kmf.effect_system.world_proxy:physics_overlap(query_callback, "shape", "sphere", "position", pos, "size", 15, "types", "both", "collision_filter", "damage_query")
+	end
+
 	local world = self.world
 	local timpani_world = World.timpani_world(world)
 	local beam_data = self.beam_data
@@ -298,13 +332,6 @@ function BeamEffect:update(dt)
 
 	World.move_particles(world, self.start_effect_id, position_start, rotation)
 
-	if DEBUG_DRAW_BEAM_EFFECT then
-		Debug.drawer("drawer_beams"):reset()
-		Debug.drawer("drawer_beams"):sphere(position_start, 0.2)
-		Debug.drawer("drawer_beams"):sphere(position_end, 0.3)
-		Debug.drawer("drawer_beams"):arrow(position_start, position_end - position_start, 1, Color(255, 0, 0))
-	end
-
 	local hit_target = beam_data.raycast_hit_unit and Vector3.unbox(beam_data.raycast_hit_position) or nil
 
 	if hit_target and not self.hit_effect_id then
@@ -344,11 +371,6 @@ function BeamEffect:update(dt)
 	World.set_particles_variable(world, effect_id, self.effect_start, position_start)
 	World.set_particles_variable(world, effect_id, self.effect_end, position_end)
 	World.set_particles_variable(world, effect_id, self.effect_length, Vector3(beam_data.length, 0, 0))
-
-	if DEBUG_DRAW_BEAM_EFFECT then
-		Debug.drawer("drawer_beams"):sphere(Unit.world_position(self.beam_unit_start, 0), 0.2)
-		Debug.drawer("drawer_beams"):sphere(Unit.world_position(self.beam_unit_end, 0), 0.3)
-	end
 end
 
 function BeamEffect:stop()
@@ -397,3 +419,103 @@ function BeamEffect:msg(message)
 		self.shrink_cooldown = 0.2
 	end
 end
+
+--AimBeamEffect = class(AimBeamEffect)
+--
+--function AimBeamEffect:init(context)
+--	assert(context.world)
+--	assert(context.unit_spawner)
+--	assert(context.caster)
+--
+--	self.world = context.world
+--	self.unit_spawner = context.unit_spawner
+--	self.caster = context.caster
+--	self.aim_beam_length = 0
+--
+--	self.elements = {
+--		ice = 0,
+--		steam = 0,
+--		arcane = 1,
+--		cold = 1,
+--		poison = 0,
+--		lightning = 0,
+--		life = 0,
+--		water = 0,
+--		lok = 0,
+--		earth = 0,
+--		fire = 0,
+--		shield = 0
+--	}
+--	local effect_type = BeamAux.get_beam_effect(self.elements)
+--	local world = self.world
+--
+--	self.effect_id = World.create_particles(world, effect_type, Vector3.zero())
+--	World.link_particles(world, self.effect_id, self.caster, Unit.node(self.caster, "root"), Matrix4x4.identity(), ParticleOrphanedPolicy.destroy)
+--
+--	local effect_id = self.effect_id
+--
+--	self.effect_id = effect_id
+--	self.effect_type = effect_type
+--	self.effect_start = World.find_particles_variable(world, effect_type, "beam_start")
+--	self.effect_end = World.find_particles_variable(world, effect_type, "beam_end")
+--	self.effect_width = World.find_particles_variable(world, effect_type, "beam_width")
+--	self.effect_length = World.find_particles_variable(world, effect_type, "beam_length")
+--
+--	local width_scale = 0.2
+--	World.set_particles_variable(world, effect_id, self.effect_width, Vector3(width_scale, 1, 1))
+--	self:create_source_particles()
+--end
+--
+--function AimBeamEffect:create_source_particles()
+--	if self.stop then
+--		return
+--	end
+--
+--	local caster = self.caster
+--
+--	if not caster or not Unit.alive(caster) then
+--		return
+--	end
+--
+--	local rotation = Unit.world_rotation(caster, 0)
+--	local start_position = Unit.world_position(caster, 0) + Vector3.normalize(Quaternion.forward(rotation))
+--	local effect_name = BeamAux.get_start_effect(self.elements)
+--
+--	self.start_effect_id = World.create_particles(self.world, effect_name, start_position, rotation)
+--end
+--
+--function AimBeamEffect:update(dt, stop)
+--	if self.stop then
+--		return
+--	end
+--
+--	self.aim_beam_length = self.aim_beam_length + dt
+--
+--	local world = self.world
+--	local caster = self.caster
+--	local effect_type = self.effect_type
+--	local effect_id = self.effect_id
+--
+--	if stop or not caster or not Unit.alive(caster) then
+--		self.stop = true
+--
+--		if self.effect_id then
+--			World.destroy_particles(world, self.effect_id)
+--		end
+--		if self.start_effect_id then
+--			World.destroy_particles(world, self.start_effect_id)
+--		end
+--	end
+--
+--	local rotation = Unit.world_rotation(caster, 0)
+--	local dir = Vector3.normalize(Quaternion.forward(rotation))
+--	local position_start = Unit.world_position(caster, 0) + dir
+--	local length = self.aim_beam_length
+--	local position_end = position_start + dir * length
+--
+--	World.move_particles(world, self.start_effect_id, position_start, rotation)
+--	World.move_particles(world, effect_id, position_start, rotation)
+--	World.set_particles_variable(world, effect_id, self.effect_start, position_start)
+--	World.set_particles_variable(world, effect_id, self.effect_end, position_end)
+--	World.set_particles_variable(world, effect_id, self.effect_length, Vector3(length, 0, 0))
+--end
\ No newline at end of file
