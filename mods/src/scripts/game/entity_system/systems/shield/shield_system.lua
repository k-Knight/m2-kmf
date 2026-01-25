diff --git a/scripts/game/entity_system/systems/shield/shield_system.lua b/scripts/game/entity_system/systems/shield/shield_system.lua
index f485add..cc7aa2b 100644
--- a/scripts/game/entity_system/systems/shield/shield_system.lua
+++ b/scripts/game/entity_system/systems/shield/shield_system.lua
@@ -106,7 +106,7 @@ function ShieldSystem:sync_shield_stage(sender, go_id, stage)
 	end
 end
 
-function ShieldSystem:shield_init_data_sync(sender, go_id, shield_type, owner_id, damage_replacer_id, time_to_explode, show_healthbar, health, max_health, ...)
+function ShieldSystem:_old_shield_init_data_sync(sender, go_id, shield_type, owner_id, damage_replacer_id, time_to_explode, show_healthbar, health, max_health, ...)
 	local u = self.unit_storage:unit(go_id)
 	local damage_replacer = self.unit_storage:unit(damage_replacer_id)
 	local is_barrier = false
@@ -172,6 +172,60 @@ function ShieldSystem:shield_init_data_sync(sender, go_id, shield_type, owner_id
 	local barrier_does_dot = false
 	local barrier_does_explosion = false
 
+	local owner_shield_unit_groups = kmf.vars.shield_unit_groups.owners[owner_id] or {
+		prev_elems = {},
+		last_id = 0,
+		last_time = -1
+	}
+
+	local time = self.world_proxy:time()
+	local prev_elements = owner_shield_unit_groups.prev_elems
+	local last_group_id = owner_shield_unit_groups.last_id
+	local last_group_time = owner_shield_unit_groups.last_time
+	local same_elements = true
+	local spawn_dt = time - last_group_time
+
+	for k, v in pairs(elements) do
+		if v == prev_elements[k] then
+			prev_elements[k] = nil
+		else
+			same_elements = false
+		end
+	end
+
+	for k, v in pairs(prev_elements) do
+		same_elements = false
+		break
+	end
+
+	if not same_elements or spawn_dt > 0.25 then
+		last_group_id = last_group_id + 1
+		last_group_time = time
+	end
+
+	local last_gc_time = kmf.vars.shield_unit_groups.gc_time
+	if (time - last_gc_time) > 3.0 then
+		kmf.vars.shield_unit_groups.gc_time = last_gc_time
+
+		for unit, _ in pairs(kmf.vars.shield_unit_groups.units) do
+			if not unit or not Unit.alive(unit) then
+				kmf.vars.shield_unit_groups.units[unit] = nil
+			end
+		end
+	end
+
+	kmf.vars.shield_unit_groups.units[u] = {
+		group_id = last_group_id,
+		owner = owner_id
+	}
+	Unit.set_data(u, "kmf_shield_group", last_group_id)
+	Unit.set_data(u, "kmf_shield_owner", owner_id)
+
+	owner_shield_unit_groups.prev_elems = table.clone(elements)
+	owner_shield_unit_groups.last_id = last_group_id
+	owner_shield_unit_groups.last_time = last_group_time
+	kmf.vars.shield_unit_groups.owners[owner_id] = owner_shield_unit_groups
+
 	if elements.earth > 0 or elements.ice > 0 then
 		barrier_does_explosion, barrier_does_dot = handle_barrier_spawn(u, elements, owner, self.player_variable_manager)
 
@@ -252,6 +306,48 @@ function ShieldSystem:shield_init_data_sync(sender, go_id, shield_type, owner_id
 	end
 end
 
+ShieldSystem.shield_init_data_sync = function(self, sender, go_id, shield_type, owner_id, damage_replacer_id, time_to_explode, show_healthbar, health, max_health, ...)
+	local unit = self.unit_storage:unit(owner_id)
+	local shield_unit = self.unit_storage:unit(go_id)
+	local allowed_spawn = true
+
+	if unit and Unit.alive(unit) then
+		local player_ext = EntityAux.extension(unit, "player")
+
+		if player_ext and kmf.vars.bugfix_enabled then
+			local char_ext = EntityAux.extension(unit, "character")
+
+			if char_ext and char_ext.state and char_ext.state.current_state then
+				local char_state = char_ext.state.current_state
+
+				if (char_state == "casting" and char_ext.input and char_ext.input.args ~= "cast_force_shield") or char_state == "channeling" then
+					allowed_spawn = false
+				end
+			elseif char_ext and char_ext.internal and char_ext.internal.last_anim_event then
+				local anim = char_ext.internal.last_anim_event
+				local was_idle, _ = string.find(anim, "idle", 1, true)
+				local was_moving, _ = string.find(anim, "run_", 1, true)
+				local was_aoe, _ = string.find(anim, "cast_area_", 1, true)
+				local was_forward_channel, _ = string.find(anim, "cast_force_beam", 1, true)
+				local was_self_channel, _ = string.find(anim, "cast_self_channeling", 1, true)
+				local was_magick, _ = string.find(anim, "cast_magick_", 1, true)
+
+				if not was_idle and not was_moving then
+					if was_aoe or was_magick or was_forward_channel then
+						allowed_spawn = false
+					end
+				end
+			end
+		end
+	end
+
+	if allowed_spawn then
+		self:_old_shield_init_data_sync(sender, go_id, shield_type, owner_id, damage_replacer_id, time_to_explode, show_healthbar, health, max_health, ...)
+	else
+		self.unit_spawner:mark_for_deletion(shield_unit)
+	end
+end
+
 function ShieldSystem:barrier_spawn_damages(sender, go_id, hit_go_id)
 	local error_msg = "ShieldSystem:barrier_spawn_damages - "
 	local u = self.unit_storage:unit(go_id)
@@ -325,7 +421,9 @@ end
 function ShieldSystem:shield_unit_spawned(sender, go_id, is_hot_join)
 	local u = self.unit_storage:unit(go_id)
 
-	assert(u, "ShieldSystem:shield_unit_spawned - Unit not found !")
+	if not u or not self.unit_elements_cache or not self.unit_elements_cache[u] then
+		return
+	end
 
 	local is_barrier = Unit_get_data(u, "barrier")
 	local is_mine = Unit_get_data(u, "mine")
@@ -342,6 +440,11 @@ function ShieldSystem:shield_unit_spawned(sender, go_id, is_hot_join)
 		ability_data.damage_mul = Unit_get_data(u, "dot_ability_damage_mul")
 		ability_data.ignore_staff_multiplier = true
 
+		local unit_grouping = kmf.vars.shield_unit_groups.units[u]
+		if unit_grouping then
+			ability_data.kmf_shield_unit_grouping = unit_grouping
+		end
+
 		EntityAux.add_ability(u, ability_name, ability_data)
 		Unit.set_data(u, "dot_ability_damage_replacer", nil)
 		Unit.set_data(u, "dot_ability_damage_mul", nil)
@@ -404,9 +507,14 @@ function ShieldSystem:update_mine_explode_power(u, internal, dt, is_local_unit)
 		return
 	end
 
-	local P_max = MINE_MAX_POWER
-	local P_min = MINE_MIN_POWER
+	local P_max = SpellSettings.mine_explode_power_percentage_max
+	local P_min = SpellSettings.mine_explode_power_percentage_min
+	local MINE_POWER_INC_PER_SEC = SpellSettings.mine_explode_power_percentage_inc_per_sec
+
 	local current_percentage = Unit_get_data(u, "damage_mul_factor")
+	if not current_percentage and kmf.vars.bugfix_enabled then
+		current_percentage = SpellSettings.mine_explode_power_percentage_min
+	end
 
 	if current_percentage < P_max then
 		local T = internal.mine_explode_power_step_timer + dt
@@ -1227,6 +1335,11 @@ function handle_elemental_wall_spawn(unit, elements, owner, pvm)
 		ability_data.set_magnitudes = true
 		ability_data.ignore_staff_multiplier = true
 
+		local unit_grouping = kmf.vars.shield_unit_groups.units[unit]
+		if unit_grouping then
+			ability_data.kmf_shield_unit_grouping = unit_grouping
+		end
+
 		EntityAux.add_ability(unit, ability, ability_data)
 
 		local defense_ext = EntityAux.extension(unit, "defense")
