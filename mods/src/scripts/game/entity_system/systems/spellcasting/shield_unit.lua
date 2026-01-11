diff --git a/scripts/game/entity_system/systems/spellcasting/shield_unit.lua b/scripts/game/entity_system/systems/spellcasting/shield_unit.lua
index 8ce24e0..8341974 100644
--- a/scripts/game/entity_system/systems/spellcasting/shield_unit.lua
+++ b/scripts/game/entity_system/systems/spellcasting/shield_unit.lua
@@ -12,7 +12,6 @@ local BARRIER_EARTH_TIME = SpellSettings.barrier_time_alive_sec_per_earth
 local BARRIER_DEBUG = SpellSettings.barrier_debug_print or false
 local ELEMENTAL_WALL_DO_DECAY = SETTINGS.elemental_wall_do_decay
 local ELEMENTAL_WALL_HAS_TIMER = SETTINGS.elemental_wall_has_timer
-local ELEMENTAL_WALL_MAX_TIME_ALIVE = SETTINGS.elemental_wall_max_time_alive
 local WATER_DAMAGE_ON_ELEMENTAL_WALLS = SETTINGS.water_dmg_on_elemental_walls
 local LIFE_DAMAGE_ON_ELEMENTAL_WALLS = SETTINGS.life_dmg_on_elemental_walls
 local LIGHTNING_REFLECT_DMG = SETTINGS.elemental_wall_lightning_reflect_damage
@@ -86,7 +85,18 @@ function ShieldUnit:init(context, unit_name, spawn_time, spawn_pose, elements, n
 
 	self.is_barrier = is_barrier
 
-	local num_elements = (elements.earth > 0 and 1 or 0) + (elements.cold > 0 and 1 or 0) + (elements.water > 0 and 1 or 0) + (elements.lightning > 0 and 1 or 0) + (elements.arcane > 0 and 1 or 0) + (elements.life > 0 and 1 or 0) + (elements.fire > 0 and 1 or 0) + (elements.ice > 0 and 1 or 0) + (elements.steam > 0 and 1 or 0) + (elements.poison > 0 and 1 or 0) + (elements.shield > 0 and 1 or 0)
+	local num_elements =
+		(elements.earth > 0 and 1 or 0) +
+		(elements.cold > 0 and 1 or 0) +
+		(elements.water > 0 and 1 or 0) +
+		(elements.lightning > 0 and 1 or 0) +
+		(elements.arcane > 0 and 1 or 0) +
+		(elements.life > 0 and 1 or 0) +
+		(elements.fire > 0 and 1 or 0) +
+		(elements.ice > 0 and 1 or 0) +
+		(elements.steam > 0 and 1 or 0) +
+		(elements.poison > 0 and 1 or 0) +
+		(elements.shield > 0 and 1 or 0)
 
 	self.deteriorate = num_elements == elements.shield
 	self.is_pure_shield = num_elements == elements.shield
@@ -99,6 +109,11 @@ function ShieldUnit:init(context, unit_name, spawn_time, spawn_pose, elements, n
 
 	if self.is_mine then
 		self.mine_explode_after_secs = elements.arcane > 0 and (SETTINGS.mine_explode_after_secs_death or 10) or SETTINGS.mine_explode_after_secs_life or 10
+
+		-- fun-balance :: nerf mine duration in pvp
+		if kmf.vars.funprove_enabled and kmf.vars.pvp_gamemode then
+			self.mine_explode_after_secs = 10
+		end
 	end
 
 	assert(pos ~= nil, "position is nil")
@@ -153,18 +168,27 @@ function ShieldUnit:init(context, unit_name, spawn_time, spawn_pose, elements, n
 		}
 	}
 
-	if _faction then
+
+
+	if _faction and not kmf.vars.pvp_gamemode then
 		init_data.faction = {
 			faction = _faction
 		}
 	end
 
+
 	if self.is_mine then
 		init_data.shield.mine_time_before_explode = mine_time_before_explode
 	end
 
 	self.unit = context.unit_spawner:spawn_unit(unit_name, go_type, go_data, pos, rot, init_data)
 
+	Unit.set_data(self.unit, "is_mine", self.is_mine)
+	Unit.set_data(self.unit, "is_pure_shield", self.is_pure_shield)
+	Unit.set_data(self.unit, "is_elemental_wall", self.is_elemental_wall)
+	Unit.set_data(self.unit, "is_barrier", self.is_barrier)
+	Unit.set_data(self.unit, "is_elemental", (num_elements - (elements.earth + elements.ice + elements.shield)) > 0)
+
 	Unit.set_data(self.unit, "shield", true)
 
 	if self.is_barrier then
@@ -314,7 +338,14 @@ function ShieldUnit:init(context, unit_name, spawn_time, spawn_pose, elements, n
 	end
 
 	if self.is_barrier then
-		self.is_exploding_barrier = elements.arcane + elements.life > 0
+		self.is_exploding_barrier = (elements.arcane + elements.life) > 0
+
+		-- fun-balance :: there is no explosion for ligthing ice barriers :/ (maybe it is possible to add it)
+		if kmf.vars.bugfix_enabled or kmf.vars.funprove_enabled then
+			self.is_exploding_barrier = self.is_exploding_barrier and (elements.lightning == 0)
+		end
+
+		Unit.set_data(self.unit, "kmf_barrier_resist_arcane", elements.arcane > 0)
 
 		if self.is_exploding_barrier then
 			if elements.arcane > 0 then
@@ -531,7 +562,14 @@ function ShieldUnit:complete_barrier_explode_ability_args(context)
 
 	self.barrier_explode_power_timer = 0
 	self.barrier_explode_power_step_timer = 0
-	self.barrier_explode_power_percentage_inc_per_sec = SpellSettings.barrier_explode_power_percentage_inc_per_sec
+
+	-- fun-balance :: speed up chanrging of the barrier explosion strength
+	if kmf.vars.funprove_enabled and kmf.vars.pvp_gamemode then
+		self.barrier_explode_power_percentage_inc_per_sec = SpellSettings.barrier_explode_power_percentage_inc_per_sec * 2.0
+	else
+		self.barrier_explode_power_percentage_inc_per_sec = SpellSettings.barrier_explode_power_percentage_inc_per_sec
+	end
+
 	self.barrier_explode_power_percentage_max = SpellSettings.barrier_explode_power_percentage_max
 	self.barrier_current_stage = 0
 end
@@ -817,7 +855,7 @@ local function get_barrier_decal(is_barrier, elements)
 	return decal
 end
 
-function ShieldUnit:_do_overlap_test(world, caster)
+function ShieldUnit:_do_overlap_test(world, caster, context)
 	if self.unit == nil or not Unit.alive(self.unit) then
 		self.overlap_done = true
 
@@ -827,6 +865,7 @@ function ShieldUnit:_do_overlap_test(world, caster)
 	end
 
 	local is_local = NetworkUnit.is_local_unit(caster)
+	local disallow_caster_spawn_hit = kmf.vars.bugfix_enabled or kmf.vars.funprove_enabled
 
 	self.overlap_done = false
 
@@ -894,11 +933,12 @@ function ShieldUnit:_do_overlap_test(world, caster)
 
 							ATTACKERS_TABLE[1] = nil
 						elseif self.is_barrier and (self.barrier_spawn_damage and EntityAux_extension(unit, "damage_receiver") or self.barrier_spawn_statuses and EntityAux.extension(unit, "status")) then
-							if self.hit_units_on_spawn == nil then
-								self.hit_units_on_spawn = {}
+							if not (disallow_caster_spawn_hit and unit == caster) then
+								if self.hit_units_on_spawn == nil then
+									self.hit_units_on_spawn = {}
+								end
+								self.hit_units_on_spawn[#self.hit_units_on_spawn + 1] = unit
 							end
-
-							self.hit_units_on_spawn[#self.hit_units_on_spawn + 1] = unit
 						end
 					end
 				end
@@ -908,7 +948,29 @@ function ShieldUnit:_do_overlap_test(world, caster)
 		self.overlap_done = true
 	end
 
+	local function verify_barrier_overlap(actors)
+		local spu = self.previous and self.previous.unit or nil
+		local snu = self.next and self.next.unit or nil
+		local su = self.unit
+
+		if su and Unit.alive(su) then
+			for _, actor in ipairs(actors) do
+				local unit = Actor.unit(actor)
+
+				if Unit.alive(unit) then
+					local is_barrier = Unit.get_data(unit, "is_barrier")
+					if is_barrier and unit ~= su and unit ~= snu and unit ~= spu then
+						Unit.set_data(unit, "kmf_barrier_explode", true)
+					end
+				end
+			end
+		end
+
+		self.overlap_done = true
+	end
+
 	local oobb, oobb_max = Unit.box(self.unit)
+	local pos = Unit.world_position(self.unit, 0)
 
 	if self.is_barrier then
 		oobb_max[1] = oobb_max[1] * 0.6
@@ -945,7 +1007,12 @@ function ShieldUnit:_do_overlap_test(world, caster)
 		oobb_max[1] = oobb_max[1] * 1.5
 	end
 
+
 	world:physics_overlap(query_callback, "shape", "oobb", "pose", oobb, "size", oobb_max, "types", "both", "collision_filter", "damage_query")
+
+	if kmf.vars.bugfix_enabled then
+		world:physics_overlap(verify_barrier_overlap, "shape", "sphere", "position", pos, "size", 1.1, "types", "both", "collision_filter", "damage_query")
+	end
 end
 
 function ShieldUnit:stop(context)
@@ -1036,7 +1103,7 @@ function ShieldUnit:update(data, context)
 
 		if self.time_elapsed >= self.spawn_time then
 			if self.overlap_done == false then
-				self:_do_overlap_test(world, caster)
+				self:_do_overlap_test(world, caster, context)
 
 				return true
 			else
@@ -1103,7 +1170,24 @@ function ShieldUnit:update(data, context)
 	elseif self.state == "spawned" then
 		self.time_elapsed = self.time_elapsed + dt
 
+		if self.is_barrier then
+			if self.unit and Unit.alive(self.unit) then
+				if Unit.get_data(self.unit, "kmf_barrier_explode") then
+					self:stop(context)
+					Unit.set_data(self.unit, "kmf_barrier_explode", false)
+					kmf.task_scheduler.add(function()
+						context.unit_spawner:mark_for_deletion(self.unit)
+					end)
+				end
+
+				Unit.set_data(self.unit, "barrier_time", self.time_elapsed)
+			end
+		end
+
 		if self.is_mine then
+			if self.unit and Unit.alive(self.unit) then
+				Unit.set_data(self.unit, "mine_time", self.time_elapsed)
+			end
 			if self.time_elapsed >= self.mine_explode_after_secs then
 				self:stop(context)
 				self:set_state("disabled")
@@ -1245,13 +1329,26 @@ function ShieldUnit:update(data, context)
 			local time_is_up = false
 
 			if self.is_elemental_wall and ELEMENTAL_WALL_HAS_TIMER then
-				time_is_up = self.time_elapsed >= ELEMENTAL_WALL_MAX_TIME_ALIVE
+				-- fun-balance :: nerf elemental wall duration in pvp
+				if kmf.vars.funprove_enabled and kmf.vars.pvp_gamemode then
+					time_is_up = self.time_elapsed >= 7.5
+				else
+					time_is_up = self.time_elapsed >= SpellSettings.elemental_wall_max_time_alive
+				end
 			elseif self.is_barrier and BARRIER_HAS_TIMER then
 				self:update_barrier_timers(dt)
 
 				time_is_up = self.num_barrier_timers == 0
 			end
 
+			if (self.is_barrier or self.is_exploding_barrier) and kmf.vars.funprove_enabled and kmf.vars.pvp_gamemode then
+				if self.is_exploding_barrier then
+					time_is_up = self.time_elapsed >= 7.5
+				else
+					time_is_up = self.time_elapsed >= 7.5
+				end
+			end
+
 			if self.is_exploding_barrier then
 				if self.barrier_values_inited then
 					self:update_barrier_explode_power(context, dt)
