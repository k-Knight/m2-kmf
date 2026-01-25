diff --git a/foundation/scripts/network/network_unit_spawner.lua b/foundation/scripts/network/network_unit_spawner.lua
index 355b4d4..87913a7 100644
--- a/foundation/scripts/network/network_unit_spawner.lua
+++ b/foundation/scripts/network/network_unit_spawner.lua
@@ -221,9 +221,11 @@ function NetworkUnitSpawner:spawn_unit_local(unit_type, pos, rot)
 	local world_proxy = self.world_proxy
 	local u = world_proxy:spawn_unit(unit_type, pos, rot)
 
-	UnitAux_set_unique_id(u)
-	NetworkUnit_set_is_husk_unit(u, false)
-	cat_print_spam("NetworkUnitSpawner", "unit(", u, ") spawned with unique_id:", UnitAux_unique_id(u))
+	UnitAux.set_unique_id(u)
+	NetworkUnit.set_is_husk_unit(u, false)
+	--kmf.task_scheduler.add(function()
+		kmf.check_needed_units(u)
+	--end, 10)
 
 	return u
 end
@@ -243,12 +245,66 @@ function NetworkUnitSpawner:spawn_unit_local_register_extensions(unit_type, pos,
 	return u
 end
 
+local bad_units = {}
+bad_units["content/units/npc/goblin/goblin_desert_boss_dlc2/goblin_desert_boss_dlc2"] = true
+
 function NetworkUnitSpawner:spawn_unit(unit_type, go_type, go_data, pos, rot, extension_init_data)
-	pos = pos or Vector3_zero()
-	rot = rot or Quaternion_identity()
+	local is_bad_unit = bad_units[unit_type]
+	if is_bad_unit and kmf.vars.pvp_gamemode then
+		return
+	end
+
+	if extension_init_data and kmf.vars.pvp_gamemode then
+		if extension_init_data.familiar then
+			return nil
+		end
+		if extension_init_data.faction then
+			if extension_init_data.faction.faction == "kmf_evil" then
+				extension_init_data.faction.faction = "evil"
+			elseif extension_init_data.faction.faction == "kmf_player" then
+				extension_init_data.faction.faction = "player"
+			else
+				return nil
+			end
+		end
+		if extension_init_data.behaviour and extension_init_data.behaviour.alert_mode == "aggression" then
+			return nil
+		end
+	end
+
+	pos = pos or Vector3.zero()
+	rot = rot or Quaternion.identity()
 
 	local u = self:spawn_unit_local(unit_type, pos, rot)
 
+	if unit_type == "content/units/npc/human/human_skeleton_magick/human_skeleton_magick_00" then
+		if kmf.vars.funprove_enabled then
+			kmf.task_scheduler.add(function()
+				if u and Unit.alive(u) then
+					local char_ext = EntityAux.extension(u, "character")
+
+					if char_ext then
+						EntityAux.add_speed_multiplier_by_extension(char_ext, 2)
+					end
+
+					local health_ext = EntityAux.extension(u, "health")
+
+					if health_ext then
+						if health_ext.internal then
+							health_ext.internal.max_health = health_ext.internal.max_health * 3
+							health_ext.internal.health = health_ext.internal.max_health
+						end
+						if health_ext.state then
+							health_ext.state.max_health = health_ext.state.max_health * 3
+							health_ext.state.health = health_ext.state.max_health
+							health_ext.state.original_max_health = health_ext.state.max_health
+						end
+					end
+				end
+			end, 100)
+		end
+	end
+
 	if self.locked then
 		self:internal_add_to_pending(u, pos, rot, extension_init_data, true, go_type, go_data)
 
@@ -402,6 +458,20 @@ function NetworkUnitSpawner:get_initial_go_data(u, go_id, go_type)
 end
 
 function NetworkUnitSpawner:register_game_object(u, go_id, go_type, owner)
+	local extension_init_data
+
+	if go_type == "player_unit" then
+		if  kmf.vars.pvp_gamemode then
+			extension_init_data = {
+				faction = {
+					faction = kmf.vars.pvp_player_teams[owner] or "player"
+				}
+			}
+		end
+
+		kmf.send_modded_section_warning(owner)
+	end
+
 	NetworkUnit_set_is_husk_unit(u, true)
 
 	if not Unit_get_data(u, "network", "ignore_mobilize") then
@@ -416,7 +486,7 @@ function NetworkUnitSpawner:register_game_object(u, go_id, go_type, owner)
 
 	local gameobject_data = self:get_initial_go_data(u, go_id, go_type)
 
-	entity_manager:register_unit(u, nil, nil, gameobject_data)
+	entity_manager:register_unit(u, extension_init_data, nil, gameobject_data)
 	self:write_initial_go_data(u, go_id, go_type)
 	entity_manager:add_extension(u, "network_synced")
 	NetworkUnit_extensions_registered(u)
