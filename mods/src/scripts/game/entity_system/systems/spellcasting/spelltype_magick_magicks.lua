diff --git a/scripts/game/entity_system/systems/spellcasting/spelltype_magick_magicks.lua b/scripts/game/entity_system/systems/spellcasting/spelltype_magick_magicks.lua
index 8aa0526..7634341 100644
--- a/scripts/game/entity_system/systems/spellcasting/spelltype_magick_magicks.lua
+++ b/scripts/game/entity_system/systems/spellcasting/spelltype_magick_magicks.lua
@@ -81,7 +81,10 @@ function get_spell_type(elements)
 	elseif (elements.arcane or 0) + (elements.life or 0) > 0 then
 		return "channeled"
 	elseif (elements.earth or 0) > 0 then
-		return "charged"
+		-- bugfix :: for prism timer bug
+		-- a little balance fix, since magickal rocks work differently and this code is retarded
+		--return "charged"
+		return "channeled"
 	elseif (elements.fire or 0) + (elements.water or 0) + (elements.steam or 0) + (elements.ice or 0) + (elements.poison or 0) + (elements.lightning or 0) + (elements.cold or 0) > 0 then
 		return "channeled"
 	else
@@ -578,10 +581,18 @@ local NUM_ACTIVE_BIRD_MAGICKS = {}
 Magicks = {
 	ice_tornado = {
 		on_enter = function(u, magick_context)
+			if not u or not Unit.alive(u) then
+				return false
+			end
 			EntityAux.set_input(u, "character", CSME.spell_cast, true)
 			EntityAux.set_input(u, "character", "args", "cast_magick_direct")
 
-			magick_context.duration = SpellSettings.ice_tornado_duration
+			-- fun-balance :: ice tornado duration nerf alive timer
+			if kmf.vars.pvp_gamemode and kmf.vars.funprove_enabled then
+				magick_context.duration = SpellSettings.ice_tornado_duration / 2.0
+			else
+				magick_context.duration = SpellSettings.ice_tornado_duration
+			end
 
 			if magick_context.is_local then
 				local unit_to_spawn = "content/units/effects/magicks/ice_tornado"
@@ -594,6 +605,7 @@ Magicks = {
 				local spawned_unit = us:spawn_unit(unit_to_spawn, "position_unit", go_data, position_to_spawn, Quaternion.identity())
 
 				Unit.set_flow_variable(spawned_unit, "caster", u)
+				Unit.set_data(spawned_unit, "ice_tornado", true)
 
 				magick_context.spawned_unit = spawned_unit
 
@@ -657,6 +669,10 @@ Magicks = {
 	},
 	haste = {
 		on_enter = function(u, magick_context)
+			if not u or not Unit.alive(u) then
+				return false
+			end
+
 			magick_context.world:trigger_timpani_event("play_magick_haste_event", u)
 			EntityAux.set_input(u, "character", CSME.spell_cast, true)
 			EntityAux.set_input(u, "character", "args", "cast_magick_self")
@@ -718,6 +734,11 @@ Magicks = {
 			magick_context.state.buffs.haste = hd
 
 			local caster = magick_context.caster
+
+			if not caster or not Unit.alive(caster) then
+				return false
+			end
+
 			local robe = EntityAux_extension(caster, "inventory").inventory.robe
 			local haste_timers = magick_context.haste_timers
 			local has_statemachine = Unit.has_animation_state_machine(robe)
@@ -965,7 +986,7 @@ Magicks = {
 			local caster = u
 
 			function magick_context.physics_overlap_callback(actors)
-				local current_world_time = magick_context.current_world_time
+				local current_world_time = magick_context.current_world_time or 0
 				local actors_n = #actors
 				local damaged_units = magick_context.damaged_units and table.clone(magick_context.damaged_units) or {}
 
@@ -1007,7 +1028,7 @@ Magicks = {
 				magick_context.damaged_units = damaged_units
 			end
 
-			return false
+			return kmf.vars.funprove_enabled and true or false
 		end,
 		update = function(u, magick_context, dt)
 			local world = magick_context.world
@@ -1166,7 +1187,13 @@ Magicks = {
 			local caster = u
 			local state_type = CSME.spell_cast
 
-			magick_context.damage_tick_interval = SpellSettings.spike_quake_damage_tick_interval
+			local tick_interval = SpellSettings.spike_quake_damage_tick_interval
+
+			if kmf.vars.funprove_enabled then
+				tick_interval = tick_interval * 2.0
+			end
+
+			magick_context.damage_tick_interval = tick_interval
 
 			if not magick_context.is_standalone then
 				EntityAux.set_input(caster, "character", state_type, true)
@@ -1222,7 +1249,7 @@ Magicks = {
 				caster = caster
 			}
 
-			function magick_context.physics_overlap_callback(actors)
+			magick_context.physics_overlap_callback = function (actors)
 				spell_data.query_done = true
 
 				if not Unit.alive(caster) then
@@ -1244,7 +1271,15 @@ Magicks = {
 
 							damage_data.push = SpellSettings.spike_quake_push
 							damage_data.elevate = SpellSettings.spike_quake_elevate
-							damage_data.earth = SpellSettings.spike_quake_earth_damage
+
+							if kmf.vars.funprove_enabled then
+								damage_data.push = damage_data.push * 1.75
+								damage_data.elevate = damage_data.elevate * 1.75
+							end
+
+							local earth_dmg = SpellSettings.spike_quake_earth_damage
+
+							damage_data.earth = earth_dmg
 
 							EntityAux_add_damage(unit, {
 								caster
@@ -1610,151 +1645,9 @@ Magicks = {
 			EntityAux.set_input(u, "character", CSME.spell_cast, true)
 			EntityAux.set_input(u, "character", "args", "cast_magick_global")
 
-			local caster = magick_context.caster
-			local world = magick_context.world
-			local damage_ext = EntityAux_extension(caster, "damage_receiver")
-
-			assert(damage_ext, "Magick:disruptor - " .. tostring(caster) .. " has no damage_receiver-extension !")
-
-			magick_context.damage_ext = damage_ext
-
-			if damage_ext.state.has_disruptor then
-				magick_context.duration = SpellSettings.disruptor_duration
-			else
-				damage_ext.state.has_disruptor = true
-				magick_context.damage_ext = damage_ext
-				magick_context.duration = SpellSettings.disruptor_duration
-
-				if EntityAux_extension(magick_context.caster, "player") then
-					if not SpellSettings.disruptor_allow_spells then
-						magick_context.network:transmit_all(u, "disable_all_elements", NetworkLookup.element_disable_earmarks.disruptor_magick)
-					end
-
-					if not SpellSettings.disruptor_allow_magicks then
-						local player_go_id = magick_context.unit_spawner.unit_storage:go_id(caster)
-
-						magick_context.network:transmit_message_all("network_disable_magicks", player_go_id)
-					end
-
-					local spellcast_extension = EntityAux_extension(u, "spellcast")
-
-					spellcast_extension.state.melee_allowed = SpellSettings.disruptor_allow_melee
-
-					local status_ext = EntityAux.extension(u, "status")
-
-					if status_ext then
-						EntityAux.set_input_by_extension(status_ext, "stop_all_statuses", true)
-					end
-				end
-
-				local selfshield_ext = EntityAux_extension(caster, "selfshield")
-
-				if selfshield_ext then
-					selfshield_ext.input.stop = true
-				end
-
-				local char_ext = EntityAux_extension(caster, "character")
-				local char_ext_internal = char_ext and char_ext.internal or nil
-
-				if char_ext_internal then
-					local loco_ext = char_ext_internal.loco_ext
-
-					if loco_ext and loco_ext.state.is_self_shielded then
-						local loco_input = loco_ext.input
-
-						if loco_input then
-							loco_input.set_self_shielded = false
-						end
-					end
-				end
-
-				Unit_set_data(caster, "spray_blocker", true)
-				Unit_set_data(caster, "reflector", nil)
-
-				local timpani_world = world:timpani_world()
-
-				magick_context.sfx_id = TimpaniWorld.trigger_event(timpani_world, "play_magic_disruptor_loop", caster)
-
-				local health_ext = EntityAux_extension(caster, "health")
-				local health_state = health_ext and health_ext.state or nil
-				local joint = 0
-
-				magick_context.particle_id = world:create_particles_linked("content/particles/spells/self/self_shield", caster, joint, ParticleOrphanedPolicy.destroy)
-
-				local effect = Unit.get_data(caster, "disruptor_effect") or "content/units/effects/magicks/disruptor_shield"
-
-				magick_context.shield_unit = magick_context.unit_spawner:spawn_unit_local(effect)
-
-				world:link_unit(magick_context.shield_unit, caster, joint)
-
-				local character_ext = EntityAux_extension(caster, "character")
-
-				if character_ext then
-					magick_context.character_ext = character_ext
-				end
-			end
-
-			return true
-		end,
-		update = function(u, magick_context, dt)
-			if SpellSettings.disruptor_duration == magick_context.duration then
-				set_input_by_extension(magick_context.character_ext, "update_character_material", true)
-				TimpaniWorld.trigger_event(magick_context.world:timpani_world(), "play_magic_disruptor_tail", magick_context.caster)
-				TimpaniWorld.trigger_event(magick_context.world:timpani_world(), "play_magic_disruptor_loop", magick_context.caster)
-			end
-
-			magick_context.duration = magick_context.duration - dt
-
-			return magick_context.duration > 0
-		end,
-		on_exit = function(u, magick_context)
-			magick_context.damage_ext.state.has_disruptor = false
-
-			Unit_set_data(magick_context.caster, "spray_blocker", false)
-
-			if EntityAux_extension(magick_context.caster, "player") then
-				if not SpellSettings.disruptor_allow_spells then
-					magick_context.network:transmit_all(u, "enable_all_elements", NetworkLookup.element_disable_earmarks.disruptor_magick)
-				end
-
-				if not SpellSettings.disruptor_allow_magicks then
-					local player_go_id = magick_context.unit_spawner.unit_storage:go_id(magick_context.caster)
-
-					magick_context.network:transmit_message_all("network_enable_magicks", player_go_id)
-				end
-
-				local spellcast_extension = EntityAux_extension(u, "spellcast")
-
-				spellcast_extension.state.melee_allowed = true
-			end
-
-			local world = magick_context.world
-
-			if magick_context.sfx_id then
-				world:stop_timpani_sound(magick_context.sfx_id)
-				TimpaniWorld.trigger_event(world:timpani_world(), "play_magic_disruptor_tail", magick_context.caster)
-			end
-
-			if magick_context.particle_id then
-				world:destroy_particles(magick_context.particle_id)
-			end
-
-			if magick_context.shield_unit then
-				world:unlink_unit(magick_context.shield_unit)
-				magick_context.unit_spawner:mark_for_deletion(magick_context.shield_unit)
-			end
-
-			local character_ext = magick_context.character_ext
-
-			if character_ext then
-				set_input_by_extension(character_ext, "update_character_material", true)
+			if u == nil or magick_context.caster == nil then
+				return false
 			end
-		end
-	},
-	disruptor = {
-		on_enter = function(u, magick_context)
-			EntityAux.set_input(u, "character", CSME.spell_cast, true)
-			EntityAux.set_input(u, "character", "args", "cast_magick_global")
 
 			local caster = magick_context.caster
 			local world = magick_context.world
@@ -1842,7 +1735,11 @@ Magicks = {
 
 			return true
 		end,
-		update = function(u, magick_context, dt)
+		update = function (u, magick_context, dt)
+			if u == nil or magick_context.caster == nil then
+				return false
+			end
+
 			if SpellSettings.disruptor_duration == magick_context.duration and magick_context.character_ext then
 				set_input_by_extension(magick_context.character_ext, "update_character_material", true)
 				TimpaniWorld.trigger_event(magick_context.world:timpani_world(), "play_magic_disruptor_tail", magick_context.caster)
@@ -1853,7 +1750,11 @@ Magicks = {
 
 			return magick_context.character_ext and magick_context.duration > 0
 		end,
-		on_exit = function(u, magick_context)
+		on_exit = function (u, magick_context)
+			if u == nil or magick_context.caster == nil then
+				return
+			end
+
 			if not Unit.alive(magick_context.caster) then
 				cat_print("Magicks", "No character extension")
 
@@ -1905,7 +1806,11 @@ Magicks = {
 		end
 	},
 	push = {
-		on_enter = function(u, magick_context)
+		on_enter = function (u, magick_context)
+			if u == nil or magick_context.caster == nil then
+				return false
+			end
+
 			local caster = magick_context.caster
 			local world = magick_context.world
 			local char_ext = EntityAux.extension(caster, "character")
@@ -1965,7 +1870,7 @@ Magicks = {
 
 			spellcast_extension.state.melee_allowed = false
 
-			function magick_context.area_callback(actors)
+			magick_context.area_callback = function (actors)
 				local caster = magick_context.caster
 				local from_pos = Vector3.unbox(magick_context.start_pos)
 				local forward = Vector3.unbox(magick_context.forward)
@@ -2047,7 +1952,6 @@ Magicks = {
 			local timpani_world = world:timpani_world()
 
 			TimpaniWorld.trigger_event(timpani_world, "magick_push", from_pos)
-
 			return true
 		end,
 		update = function(u, magick_context, dt)
@@ -2117,6 +2021,11 @@ Magicks = {
 									yellow_text("strength = " .. tostring(strength) .. " => push = " .. tostring(damage_push) .. ", elevate = " .. tostring(damage_elevate))
 								end
 
+								if kmf.vars.funprove_enabled then
+									damage_push = damage_push * 2
+									damage_elevate = damage_elevate * 2
+								end
+
 								local damage = {
 									push = damage_push,
 									elevate = damage_elevate
@@ -2152,7 +2061,11 @@ Magicks = {
 
 			return true
 		end,
-		on_exit = function(u, magick_context)
+		on_exit = function (u, magick_context)
+			if u == nil or magick_context.caster == nil then
+				return
+			end
+
 			local world = magick_context.world
 
 			world:stop_spawning_particles(magick_context.particle_id)
@@ -2169,7 +2082,11 @@ Magicks = {
 		end
 	},
 	abuse_a_scroll = {
-		on_enter = function(u, magick_context)
+		on_enter = function (u, magick_context)
+			if u == nil or magick_context.caster == nil then
+				return false
+			end
+
 			if not magick_context.is_local then
 				return true
 			end
@@ -2238,7 +2155,19 @@ Magicks = {
 				yellow_text("Chose Action: " .. AbuseAScrollActions_DEBUG[chosen_action])
 			end
 
-			function magick_context.area_callback(actors)
+			local caster_faction_ext = EntityAux.extension(magick_context.caster, "faction")
+			local caster_faction = caster_faction_ext and caster_faction_ext.internal.faction or nil
+			local pvp_req_met = caster_faction and kmf.vars.pvp_gamemode
+			local chosen_negative = (chosen_action == AbuseAScrollActions.Freeze) or (chosen_action == AbuseAScrollActions.LightningStrike)
+			local negative_target_player = (chosen_action == AbuseAScrollActions.LightningStrike)
+
+			magick_context.hit_units = {}
+
+			magick_context.area_callback = function (actors)
+				if u == nil or magick_context.caster == nil then
+					return
+				end
+
 				local caster = magick_context.caster
 				local cast_pos = Vector3.unbox(magick_context.start_pos)
 				local hit_unit_table = magick_context.hit_units
@@ -2247,27 +2176,55 @@ Magicks = {
 					local unit = Actor.unit(actor)
 
 					if Unit.alive(unit) then
-						local unit_pos = Unit.world_position(unit, 0)
-						local distance = Vector3.distance(cast_pos, unit_pos)
-						local is_within_radius = distance <= magick_context.radius
-						local is_character = EntityAux_extension(unit, "character") ~= nil
+						local allowed_target = true
 
-						if is_within_radius and is_character then
-							local data_table = FrameTable.alloc_table()
+						if chosen_negative then
+							local player_ext = EntityAux.extension(unit, "player")
+							allowed_target = negative_target_player or player_ext == nil
 
-							hit_unit_table[#hit_unit_table + 1] = data_table
-							data_table.distance = distance
-							data_table.position = Vector3.box({}, unit_pos)
-							data_table.unit = unit
+							if pvp_req_met then
+								if player_ext then
+									local faction_ext = EntityAux.extension(unit, "faction")
+									local faction = faction_ext and faction_ext.internal.faction or nil
 
-							if magick_context.debug then
-								if not magick_context.debug_spheres then
-									magick_context.debug_spheres = {}
+									if faction ~= caster_faction then
+										allowed_target = true
+									end
+								else
+									local faction_ext = EntityAux.extension(unit, "faction")
+									local faction = faction_ext and faction_ext.internal.faction or nil
+
+									if faction == caster_faction then
+										allowed_target = false
+									end
 								end
+							end
+						end
 
-								magick_context.debug_spheres[unit] = Vector3.box({}, unit_pos)
+						if allowed_target then
+							local unit_pos = Unit.world_position(unit, 0)
+							local distance = Vector3.distance(cast_pos, unit_pos)
+							local is_within_radius = distance <= magick_context.radius
+							local is_character = EntityAux_extension(unit, "character") ~= nil
+
+							if is_within_radius and is_character then
+								local data_table = FrameTable.alloc_table()
+
+								data_table.distance = distance
+								data_table.position = Vector3.box({}, unit_pos)
+								data_table.unit = unit
+								hit_unit_table[#hit_unit_table + 1] = data_table
+
+								if magick_context.debug then
+									if not magick_context.debug_spheres then
+										magick_context.debug_spheres = {}
+									end
+
+									magick_context.debug_spheres[unit] = Vector3.box({}, unit_pos)
+								end
 							end
 						end
+
 					end
 				end
 
@@ -2287,6 +2244,11 @@ Magicks = {
 
 				magick_context.collision_filter = affect_players and "character_query" or "enemy_query"
 				magick_context.status = "do_query"
+
+				if kmf.vars.pvp_gamemode then
+					magick_context.max_freeze_units = 12
+					magick_context.collision_filter = "character_query"
+				end
 			elseif chosen_action == AbuseAScrollActions.LightningStrike then
 				magick_context.radius = SpellSettings.abuse_a_scroll_lightning_strike_radius
 				magick_context.collision_filter = "character_query"
@@ -2296,13 +2258,28 @@ Magicks = {
 
 				for i = 1, players_n do
 					local unit = players[i].unit
-					local health_ext = EntityAux_extension(unit, "health")
 
-					if EntityAux.extension(unit, "ability_user") and health_ext then
-						local health = health_ext.state.health
+					if unit and Unit.alive(unit) then
+						local health_ext = EntityAux_extension(unit, "health")
+						local allowed_target = true
+
+						if pvp_req_met then
+							local faction_ext = EntityAux.extension(unit, "faction")
+							local faction = faction_ext and faction_ext.internal.faction or nil
 
-						if health > 0 then
-							magick_context.network:send_start_parameterless_ability(unit, "abuse_a_scroll_haste", true)
+							if faction ~= caster_faction then
+								allowed_target = false
+							end
+						end
+
+						if allowed_target then
+							if EntityAux.extension(unit, "ability_user") and health_ext then
+								local health = health_ext.state.health
+
+								if health > 0 then
+									magick_context.network:send_start_parameterless_ability(unit, "abuse_a_scroll_haste", true)
+								end
+							end
 						end
 					end
 				end
@@ -2325,25 +2302,40 @@ Magicks = {
 
 				for i = 1, players_n do
 					local unit = players[i].unit
-					local magick_ext = EntityAux.extension(unit, "magick_user")
-					local health_ext = EntityAux.extension(unit, "health")
 
-					if health_ext and health_ext.state.health <= 0 then
-						EntityAux.set_input_by_extension(health_ext, "resurrect", magick_context.caster)
-						EntityAux.set_input_by_extension(health_ext, "resurrect_health", 1)
+					if unit and Unit.alive(unit) then
+						local magick_ext = EntityAux.extension(unit, "magick_user")
+						local health_ext = EntityAux.extension(unit, "health")
+						local allowed_target = true
 
-						local loc_extension = EntityAux.extension(magick_context.caster, "locomotion")
+						if pvp_req_met then
+							local faction_ext = EntityAux.extension(unit, "faction")
+							local faction = faction_ext and faction_ext.internal.faction or nil
 
-						if loc_extension and loc_extension.state then
-							loc_extension.state.velocity = {
-								0,
-								0,
-								0
-							}
+							if faction ~= caster_faction then
+								allowed_target = false
+							end
 						end
 
-						if magick_ext then
-							magick_context.network:send_set_focus_percentage(unit, 1, 1, 1, 1)
+						if allowed_target then
+							if health_ext and health_ext.state.health <= 0 then
+								EntityAux.set_input_by_extension(health_ext, "resurrect", magick_context.caster)
+								EntityAux.set_input_by_extension(health_ext, "resurrect_health", 1)
+
+								local loc_extension = EntityAux.extension(magick_context.caster, "locomotion")
+
+								if loc_extension and loc_extension.state then
+									loc_extension.state.velocity = {
+										0,
+										0,
+										0
+									}
+								end
+
+								if magick_ext then
+									magick_context.network:send_set_focus_percentage(unit, 1, 1, 1, 1)
+								end
+							end
 						end
 					end
 				end
@@ -2365,7 +2357,10 @@ Magicks = {
 
 			return true
 		end,
-		update = function(u, magick_context, dt)
+		update = function (u, magick_context, dt)
+			if u == nil or magick_context.caster == nil then
+				return false
+			end
 			if not magick_context.is_local then
 				return false
 			end
@@ -2474,7 +2469,11 @@ Magicks = {
 		end
 	},
 	concussion = {
-		on_enter = function(u, magick_context)
+		on_enter = function (u, magick_context)
+			if u == nil or magick_context.caster == nil then
+				return false
+			end
+
 			local caster = magick_context.caster
 			local world = magick_context.world
 
@@ -2560,7 +2559,11 @@ Magicks = {
 
 			return true
 		end,
-		update = function(u, magick_context, dt)
+		update = function (u, magick_context, dt)
+			if u == nil or magick_context.caster == nil then
+				return false
+			end
+
 			if magick_context.debug then
 				magick_context.debug_duration = magick_context.debug_duration - dt
 
@@ -2610,6 +2613,11 @@ Magicks = {
 
 								damage = is_within_damage_radius and damage or 0
 
+								if kmf.vars.funprove_enabled then
+									damage_push = damage_push * 2
+									damage_elevate = damage_elevate * 2
+								end
+
 								local damage_data = {
 									push = damage_push,
 									elevate = damage_elevate,
@@ -2646,7 +2654,11 @@ Magicks = {
 		end
 	},
 	dispell = {
-		on_enter = function(u, magick_context)
+		on_enter = function (u, magick_context)
+			if u == nil or magick_context.caster == nil then
+				return false
+			end
+
 			local caster = magick_context.caster
 			local world = magick_context.world
 
@@ -2674,7 +2686,7 @@ Magicks = {
 			magick_context.start_pos = Vector3.box({}, magick_context.start_pos)
 			magick_context.hit_units = {}
 
-			function magick_context.area_callback(actors)
+			magick_context.area_callback = function (actors)
 				local hit_unit_table = table.clone(magick_context.hit_units)
 
 				for hit_data, actor in ipairs(actors) do
@@ -2726,7 +2738,11 @@ Magicks = {
 
 			return true
 		end,
-		update = function(u, magick_context, dt)
+		update = function (u, magick_context, dt)
+			if u == nil or magick_context.caster == nil then
+				return false
+			end
+
 			local start_pos = Vector3.unbox(magick_context.start_pos)
 			local distance = magick_context.distance
 			local world = magick_context.world
@@ -2761,104 +2777,159 @@ Magicks = {
 						local is_character = data.is_character
 
 						if unit and Unit.alive(unit) then
-							local is_local = is_local_unit(unit)
+							local skip_unit = false
 
-							if is_character then
-								if magick_context.is_local then
-									status_ext = EntityAux.extension(unit, "status")
+							if kmf.vars.funprove_enabled and unit ~= magick_context.caster then
+								repeat
+									local ext = EntityAux.extension(unit, "spellcast")
+									if not ext then break end
 
-									if status_ext then
-										if magick_context.debug then
-											red_text("DISPELL - Stopping all statuses on " .. tostring(unit))
+									local internal = ext.internal
+									if not internal then break end
+
+									local spells = internal.spells
+									local spells_data = internal.spells_data
+									if not spells or not spells_data then break end
+
+									for i, name in ipairs(spells) do
+										if name == "ArmorWard" and spells_data[i] and spells_data[i].elements and spells_data[i].elements.life >= 4 then
+											skip_unit = true
+											break
 										end
+									end
+								until true
+							end
 
-										magick_context.network:transmit_all(unit, "net_stop_all_statuses")
+							local is_local = is_local_unit(unit)
+							if skip_unit then
+								if is_local then
+									local spellcast_ext = EntityAux.extension(unit, "spellcast")
+
+									if spellcast_ext then
+										local internal = spellcast_ext.internal
+										local spells = internal.spells
+										local spells_data = internal.spells_data
+										local num_spells = #spells
+
+										for i = 1, num_spells do
+											repeat
+												local spell = spells[i]
+												local data = spells_data[i]
+
+												if not spell then
+													break
+												end
+
+												if spell == "ArmorWard" and data and data.ward_data then
+													local duration = math.min(data.ward_data.duration or 0.5, 0.5)
+
+													data.ward_data.duration = duration
+												end
+											until true
+										end
 									end
 								end
+							else
+								if is_character then
+									if magick_context.is_local then
+										status_ext = EntityAux.extension(unit, "status")
+
+										if status_ext then
+											if magick_context.debug then
+												red_text("DISPELL - Stopping all statuses on " .. tostring(unit))
+											end
+
+											magick_context.network:transmit_all(unit, "net_stop_all_statuses")
+										end
+									end
 
-								EntityAux.try_remove_imbuement(unit)
-								magick_context.network:send_remove_weapon_imbuement(unit)
+									EntityAux.try_remove_imbuement(unit)
+									magick_context.network:send_remove_weapon_imbuement(unit)
 
-								spellwheel_ext = EntityAux.extension(unit, "spellwheel")
+									spellwheel_ext = EntityAux.extension(unit, "spellwheel")
+
+									if spellwheel_ext then
+										local internal = spellwheel_ext.internal
+
+										if internal then
+											if magick_context.debug then
+												red_text("DISPELL - Clearing spellwheel on " .. tostring(unit))
+											end
+
+											internal.element_queue:clear()
+										end
+									end
 
-								if spellwheel_ext then
-									local internal = spellwheel_ext.internal
+									selfshield_ext = EntityAux.extension(unit, "selfshield")
 
-									if internal then
+									if selfshield_ext then
 										if magick_context.debug then
-											red_text("DISPELL - Clearing spellwheel on " .. tostring(unit))
+											red_text("DISPELL - Setting STOP on selfshield_ext unit " .. tostring(unit))
 										end
 
-										internal.element_queue:clear()
+										set_input_by_extension(selfshield_ext, "stop", true)
 									end
-								end
 
-								selfshield_ext = EntityAux.extension(unit, "selfshield")
+									shield_ext = EntityAux.extension(unit, "shield")
 
-								if selfshield_ext then
-									if magick_context.debug then
-										red_text("DISPELL - Setting STOP on selfshield_ext unit " .. tostring(unit))
-									end
+									if shield_ext then
+										if magick_context.debug then
+											red_text("DISPELL - Setting STOP on shield_ext unit " .. tostring(unit))
+										end
 
-									set_input_by_extension(selfshield_ext, "stop", true)
+										set_input_by_extension(shield_ext, "stop", true)
+									end
 								end
 
-								shield_ext = EntityAux.extension(unit, "shield")
+								if not is_nullifyable then
+									health_ext = EntityAux_extension(unit, "health")
+									health_state = health_ext and health_ext.state or nil
+									joint = 0
 
-								if shield_ext then
-									if magick_context.debug then
-										red_text("DISPELL - Setting STOP on shield_ext unit " .. tostring(unit))
+									if magick_context.hit_particle_ids == nil then
+										magick_context.hit_particle_ids = {}
 									end
 
-									set_input_by_extension(shield_ext, "stop", true)
+									magick_context.hit_particle_ids[#magick_context.hit_particle_ids + 1] = world:create_particles_linked("content/particles/spells/magicks/dispell_reciever", unit, joint, ParticleOrphanedPolicy.destroy)
 								end
-							end
-
-							if not is_nullifyable then
-								health_ext = EntityAux_extension(unit, "health")
-								health_state = health_ext and health_ext.state or nil
-								joint = 0
 
-								if magick_context.hit_particle_ids == nil then
-									magick_context.hit_particle_ids = {}
-								end
+								local effect_ext = EntityAux_extension(unit, "effect_producer")
 
-								magick_context.hit_particle_ids[#magick_context.hit_particle_ids + 1] = world:create_particles_linked("content/particles/spells/magicks/dispell_reciever", unit, joint, ParticleOrphanedPolicy.destroy)
-							end
+								if effect_ext then
+									if magick_context.debug then
+										red_text("Dispell: Stops all effects on " .. tostring(unit))
+									end
 
-							local effect_ext = EntityAux_extension(unit, "effect_producer")
+									local input = effect_ext.input
 
-							if effect_ext then
-								if magick_context.debug then
-									red_text("Dispell: Stops all effects on " .. tostring(unit))
+									input.stop_all = true
 								end
 
-								local input = effect_ext.input
+								if is_nullifyable then
+									if magick_context.is_local and magick_context.debug then
+										if is_local then
+											red_text("Dispell: Deleting local nullifyable unit " .. tostring(unit))
+										else
+											red_text("Dispell: nullifyable unit " .. tostring(unit) .. ", will hopefully be deleted by owner.")
+										end
+									end
 
-								input.stop_all = true
-							end
+									if unit and Unit.alive(unit) then
+										world:create_particles(DISPELL_ON_NULLIFYABLE_EFFECT, Unit.world_position(unit, 0) + Vector3.up(), Unit.world_rotation(unit, 0))
 
-							if is_nullifyable then
-								if magick_context.is_local and magick_context.debug then
-									if is_local then
-										red_text("Dispell: Deleting local nullifyable unit " .. tostring(unit))
-									else
-										red_text("Dispell: nullifyable unit " .. tostring(unit) .. ", will hopefully be deleted by owner.")
+										if magick_context.is_local then
+											magick_context.network:send_nullify_unit(unit)
+										end
 									end
-								end
 
-								world:create_particles(DISPELL_ON_NULLIFYABLE_EFFECT, Unit.world_position(unit, 0) + Vector3.up(), Unit.world_rotation(unit, 0))
-
-								if magick_context.is_local then
-									magick_context.network:send_nullify_unit(unit)
 								end
-							end
 
-							if unit ~= magick_context.caster then
-								local spellcast_ext = EntityAux_extension(unit, "spellcast")
+								if unit ~= magick_context.caster then
+									local spellcast_ext = EntityAux_extension(unit, "spellcast")
 
-								if spellcast_ext and not is_nullifyable then
-									magick_context.network:transmit_all(unit, "net_cancel_all_spells")
+									if spellcast_ext and not is_nullifyable then
+										magick_context.network:transmit_all(unit, "net_cancel_all_spells")
+									end
 								end
 							end
 						end
@@ -2886,10 +2957,15 @@ Magicks = {
 
 				magick_context.dispell_debug_drawer = nil
 			end
+
 		end
 	},
 	force_prism = {
-		on_enter = function(u, magick_context)
+		on_enter = function (u, magick_context)
+			if u == nil or magick_context.caster == nil then
+				return false
+			end
+
 			magick_context.spray_length = SpellSettings.magick_force_prism_spray_length
 			magick_context.spray_width = SpellSettings.magick_force_prism_spray_width
 			magick_context.projectile_force = SpellSettings.magick_force_prism_projectile_force
@@ -2904,6 +2980,13 @@ Magicks = {
 			local caster_faction_ext = EntityAux.extension(caster, "faction")
 
 			caster_faction = caster_faction_ext and caster_faction_ext.internal.faction or "neutral"
+			if kmf.vars.pvp_gamemode then
+				if caster_faction == "evil" then
+					caster_faction = "kmf_evil"
+				elseif caster_faction == "player" then
+					caster_faction = "kmf_player"
+				end
+			end
 
 			PRISM_DEBUG("This prism will have the faction '" .. caster_faction .. "' !", 1)
 
@@ -2935,12 +3018,41 @@ Magicks = {
 			assert(spellwheel_ext, "Magick:ForcePrism - Caster needs to have spellwheel_ext !")
 
 			local element_queue = spellwheel_ext.internal.element_queue
-			local _elements, _num_elements = element_queue:get_elements()
+			local _elements, _num_elements, is_illegal = element_queue:get_elements("forward")
+
+			if spellwheel_ext.input.magick_from_elements and caster and Unit.alive(caster) then
+				local spell_system_ext = EntityAux.extension(caster, "spellcast")
+				spell_system_ext = spell_system_ext or EntityAux.extension(caster, "spellcast_husk")
+
+				if spell_system_ext and spell_system_ext.internal.current_imbued_spell then
+					local elements = spell_system_ext.internal.current_imbued_spell.elements
+
+					_elements = table.deep_clone(elements)
+					_num_elements = 0
+
+					for _, count in pairs(_elements) do
+						_num_elements = _num_elements + (count or 0)
+					end
+
+					EntityAux.try_remove_imbuement(caster)
+					magick_context.network:send_remove_weapon_imbuement(caster)
+				end
+			end
+
+			local lok_count = _elements["lok"]
+
+			if lok_count and _num_elements == lok_count then
+				_num_elements = _num_elements - lok_count
+				_elements["lok"] = nil
+			end
 
 			element_queue:clear()
 
-			local spell_type = _num_elements == 0 and "empty" or get_spell_type(_elements)
+			if is_illegal then
+				return false
+			end
 
+			local spell_type = (_num_elements == 0 and "empty") or get_spell_type(_elements)
 			magick_context.duration = SpellSettings.magick_prism_duration[spell_type]
 			magick_context.delay = SpellSettings.magick_prism_delay[spell_type]
 
@@ -2963,6 +3075,10 @@ Magicks = {
 			if magick_context.is_local then
 				local _health = _num_elements == 0 and SpellSettings.magick_force_prism_empty_health or SpellSettings.magick_force_prism_health
 
+				if kmf.vars.funprove_enabled then
+					_health = 500
+				end
+
 				PRISM_DEBUG("health = " .. tostring(_health), 1)
 
 				local unit_to_spawn = "content/units/effects/magicks/force_prism"
@@ -3000,6 +3116,63 @@ Magicks = {
 			return true
 		end,
 		update = function(u, magick_context, dt)
+			if kmf.vars.funprove_enabled then
+				local caster = magick_context.caster
+				local spawned_unit = magick_context.spawned_unit
+
+				if caster and Unit.alive(caster) and spawned_unit and Unit.alive(spawned_unit) then
+					local uses_keboard = false
+					local is_local = false
+
+					if caster and Unit.alive(caster) then
+						local local_player = nil
+
+						if kmf.entity_manager and kmf.player_manager then
+							local players, players_n = kmf.entity_manager:get_entities("player")
+
+							for i = 1, players_n, 1 do
+								if players[i].extension.is_local then
+									if players[i].unit and Unit.alive(players[i].unit) and players[i].unit == caster and players[i].extension then
+										is_local = true
+										if kmf.player_manager:try_get_input_controller(players[i].extension.local_player_id) == "keyboard" then
+											uses_keboard = true
+										end
+									end
+								end
+							end
+						end
+					end
+
+					if is_local then
+						local prism_pos = Unit.world_position(spawned_unit, 0)
+						local aim_pos
+
+						kmf.unit_enable_network_sync(spawned_unit)
+
+						if uses_keboard and kmf.frame_camera then
+							local mouse_cursor = Mouse.axis(Mouse.axis_index("cursor"), Mouse.RAW, 3)
+							local x, y = mouse_cursor[1], mouse_cursor[2]
+
+							aim_pos = kmf.screen_2_world(x, y, caster)
+						elseif kmf.vars.gamepad_aiming and kmf.vars.gamepad_aiming.aim_pos then
+							local aim_coords = kmf.vars.gamepad_aiming.aim_pos
+
+							aim_pos = Vector3(aim_coords.x, aim_coords.y, aim_coords.z)
+						end
+
+						if aim_pos then
+							local dir = aim_pos - prism_pos
+
+							dir.z = 0
+
+							local rot = Quaternion.look(Vector3.normalize(dir), Vector3.up())
+							Unit.teleport_local_rotation(spawned_unit, 0, rot)
+						end
+					end
+
+				end
+			end
+
 			return update_prism(u, magick_context, dt, 1)
 		end,
 		on_exit = function(u, magick_context)
@@ -3025,7 +3198,11 @@ Magicks = {
 		end
 	},
 	area_prism = {
-		on_enter = function(u, magick_context)
+		on_enter = function (u, magick_context)
+			if u == nil or magick_context.caster == nil then
+				return false
+			end
+
 			magick_context.wall_health_mul = SpellSettings.magick_area_prism_wall_health_mul
 			magick_context.wall_decay_rate = SpellSettings.magick_area_prism_wall_decay_rate
 			magick_context.wall_num_mul = SpellSettings.magick_area_prism_wall_num_mul
@@ -3037,6 +3214,13 @@ Magicks = {
 			local caster_faction_ext = EntityAux.extension(caster, "faction")
 
 			caster_faction = caster_faction_ext and caster_faction_ext.internal.faction or "neutral"
+			if kmf.vars.pvp_gamemode then
+				if caster_faction == "evil" then
+					caster_faction = "kmf_evil"
+				elseif caster_faction == "player" then
+					caster_faction = "kmf_player"
+				end
+			end
 
 			PRISM_DEBUG("This prism will have the faction '" .. caster_faction .. "' !", 2)
 
@@ -3060,12 +3244,41 @@ Magicks = {
 			assert(spellwheel_ext, "Magick:ForcePrism - Caster needs to have spellwheel_ext !")
 
 			local element_queue = spellwheel_ext.internal.element_queue
-			local _elements, _num_elements = element_queue:get_elements()
+			local _elements, _num_elements, is_illegal = element_queue:get_elements("area")
+
+			if spellwheel_ext.input.magick_from_elements and caster and Unit.alive(caster) then
+				local spell_system_ext = EntityAux.extension(caster, "spellcast")
+				spell_system_ext = spell_system_ext or EntityAux.extension(caster, "spellcast_husk")
+
+				if spell_system_ext and spell_system_ext.internal.current_imbued_spell then
+					local elements = spell_system_ext.internal.current_imbued_spell.elements
+
+					_elements = table.deep_clone(elements)
+					_num_elements = 0
+
+					for _, count in pairs(_elements) do
+						_num_elements = _num_elements + (count or 0)
+					end
+
+					EntityAux.try_remove_imbuement(caster)
+					magick_context.network:send_remove_weapon_imbuement(caster)
+				end
+			end
+
+			for element, count in pairs(_elements) do
+				if element == "lok" then
+					_num_elements = _num_elements - _elements[element]
+					_elements[element] = nil
+				end
+			end
 
 			element_queue:clear()
 
-			local spell_type = _num_elements == 0 and "empty" or "area"
+			if is_illegal then
+				return false
+			end
 
+			local spell_type = (_num_elements == 0 and "empty") or "area"
 			magick_context.duration = SpellSettings.magick_prism_duration[spell_type]
 			magick_context.delay = SpellSettings.magick_prism_delay[spell_type]
 
@@ -3082,6 +3295,10 @@ Magicks = {
 			if magick_context.is_local then
 				local _health = _num_elements == 0 and SpellSettings.magick_area_prism_empty_health or SpellSettings.magick_area_prism_health
 
+				if kmf.vars.funprove_enabled then
+					_health = 500
+				end
+
 				PRISM_DEBUG("health = " .. tostring(_health), 2)
 
 				local unit_to_spawn = "content/units/effects/magicks/area_prism"
@@ -3104,6 +3321,7 @@ Magicks = {
 						owner = caster
 					}
 				}
+				magick_context.orig_spawn_z = magick_activate_position.z
 				local spawned_unit = us:spawn_unit(unit_to_spawn, "prism", go_data, magick_activate_position, rot, init_data)
 
 				magick_context.spawned_unit = spawned_unit
@@ -3117,6 +3335,68 @@ Magicks = {
 			magick_context.has_casted_once = false
 		end,
 		update = function(u, magick_context, dt)
+			if kmf.vars.funprove_enabled then
+				local caster = magick_context.caster
+				local spawned_unit = magick_context.spawned_unit
+
+				if caster and Unit.alive(caster) and spawned_unit and Unit.alive(spawned_unit) then
+					local uses_keboard = false
+					local is_local = false
+
+					if caster and Unit.alive(caster) then
+						local local_player = nil
+
+						if kmf.entity_manager and kmf.player_manager then
+							local players, players_n = kmf.entity_manager:get_entities("player")
+
+							for i = 1, players_n, 1 do
+								if players[i].extension.is_local then
+									if players[i].unit and Unit.alive(players[i].unit) and players[i].unit == caster and players[i].extension then
+										is_local = true
+										if kmf.player_manager:try_get_input_controller(players[i].extension.local_player_id) == "keyboard" then
+											uses_keboard = true
+										end
+									end
+								end
+							end
+						end
+					end
+
+					if is_local then
+						local prism_pos = Unit.world_position(spawned_unit, 0)
+						local aim_pos
+
+						kmf.unit_enable_network_sync(spawned_unit)
+
+						if uses_keboard and kmf.frame_camera then
+							local mouse_cursor = Mouse.axis(Mouse.axis_index("cursor"), Mouse.RAW, 3)
+							local x, y = mouse_cursor[1], mouse_cursor[2]
+
+							aim_pos = kmf.screen_2_world(x, y, caster)
+						elseif kmf.vars.gamepad_aiming and kmf.vars.gamepad_aiming.aim_pos then
+							local aim_coords = kmf.vars.gamepad_aiming.aim_pos
+
+							aim_pos = Vector3(aim_coords.x, aim_coords.y, aim_coords.z)
+						end
+
+						if aim_pos then
+							local time_scaled = os.clock() / 2
+							local height_adjust = math.abs(time_scaled - math.round(time_scaled)) * 2
+							local dir = aim_pos - prism_pos
+							dir.z = 0
+							dir = Vector3.normalize(dir)
+
+
+							local new_pos = prism_pos + dir * dt * 4.0
+							new_pos.z = magick_context.orig_spawn_z + height_adjust
+
+							Unit.teleport_local_position(spawned_unit, 0, new_pos)
+						end
+					end
+
+				end
+			end
+
 			return update_prism(u, magick_context, dt, 2)
 		end,
 		on_exit = function(u, magick_context)
@@ -3142,7 +3422,11 @@ Magicks = {
 		end
 	},
 	highland_breeze = {
-		on_enter = function(u, magick_context)
+		on_enter = function (u, magick_context)
+			if u == nil or magick_context.caster == nil then
+				return false
+			end
+
 			EntityAux.set_input(u, "character", CSME.spell_cast, true)
 			EntityAux.set_input(u, "character", "args", "cast_magick_direct")
 
@@ -3275,7 +3559,7 @@ Magicks = {
 			magick_context.damage_tick_interval = SpellSettings.highland_breeze_damage_tick_interval
 			magick_context.damaged_units = nil
 
-			function magick_context.physics_overlap_callback(actors)
+			magick_context.physics_overlap_callback = function (actors)
 				local current_world_time = magick_context.current_world_time
 				local damage_tick_interval = magick_context.damage_tick_interval
 				local damaged_units = magick_context.damaged_units and table.clone(magick_context.damaged_units) or {}
@@ -3346,7 +3630,7 @@ Magicks = {
 				magick_context.damaged_units = damaged_units
 			end
 
-			return false
+			return kmf.vars.funprove_enabled and true or false
 		end,
 		update = function(u, magick_context, dt)
 			magick_context.duration = magick_context.duration - dt
@@ -3503,8 +3787,12 @@ Magicks = {
 
 			local trigger_name = "play_magick_revive_cast_event"
 
-			magick_context.world:trigger_timpani_event(trigger_name, u)
+			if magick_context.caster then
+				local faction_ext = EntityAux.extension(magick_context.caster, "faction")
+				magick_context.caster_faction = faction_ext and faction_ext.internal.faction or "player"
+			end
 
+			magick_context.world:trigger_timpani_event(trigger_name, u)
 			return true
 		end,
 		animation_completed = function(magick_context)
@@ -3512,12 +3800,38 @@ Magicks = {
 				magick_context.resurrect_anim_done = true
 			end
 		end,
-		update = function(u, magick_context, dt)
+		update = function (u, magick_context, dt)
+			if u == nil or magick_context.caster == nil then
+				return false
+			end
+
 			if magick_context.resurrect_anim_done and magick_context.is_local then
 				local players, players_n = magick_context.entity_manager:get_entities("player")
 				local resurrect_units = {}
 				local best_time
 
+				local caster_faction = magick_context.caster_faction and magick_context.caster_faction or "player"
+				if kmf.vars.pvp_gamemode then
+					local new_player_array = {}
+
+					for i = 1, players_n do
+						local unit = players[i].unit
+
+						if unit and Unit.alive(unit) then
+							local faction_ext = EntityAux.extension(unit, "faction")
+							local faction = faction_ext and faction_ext.internal.faction or "player"
+
+							if faction == caster_faction then
+								new_player_array[#new_player_array + 1] = players[i]
+							end
+						end
+					end
+
+					players_n = #new_player_array
+					players = new_player_array
+				end
+
+
 				if SpellSettings.revive_resurrect_all then
 					for i = 1, players_n do
 						local extension_data = players[i]
@@ -3595,7 +3909,11 @@ Magicks = {
 
 			return true
 		end,
-		animation_completed = function(magick_context)
+		animation_completed = function (magick_context)
+			if magick_context.caster == nil then
+				return
+			end
+
 			if magick_context.resurrect_done == nil or magick_context.resurrect_done == false then
 				local players, players_n = magick_context.entity_manager:get_entities("player")
 
@@ -3707,6 +4025,27 @@ Magicks = {
 			local forward_box = Vector3.box({}, forward)
 			local half_spread = SpellSettings.thunderbolt_spread / 2
 
+			local caster =  magick_context.is_local and magick_context.caster or nil
+			local uses_keboard = false
+
+			if caster and Unit.alive(caster) then
+				local local_player = nil
+
+				if kmf.entity_manager and kmf.player_manager then
+					local players, players_n = kmf.entity_manager:get_entities("player")
+
+					for i = 1, players_n, 1 do
+						if players[i].extension.is_local then
+							if players[i].unit and Unit.alive(players[i].unit) and players[i].unit == caster and players[i].extension then
+								if kmf.player_manager:try_get_input_controller(players[i].extension.local_player_id) == "keyboard" then
+									uses_keboard = true
+								end
+							end
+						end
+					end
+				end
+			end
+
 			local function query_callback(actors)
 				magick_context.bolt_hit_unit = true
 
@@ -3718,95 +4057,173 @@ Magicks = {
 					0
 				}
 				local mypos = Vector3.unbox(pos_box)
+				-- fun-balance :: imrpoved thunderbolt aiming
+				local picl_better_target = kmf.generate_bernoulli(0.66)
+				local target_unit = nil
 
-				for i, actor in ipairs(actors) do
-					repeat
-						local unit = Actor.unit(actor)
+				if picl_better_target and kmf.vars.funprove_enabled then
+					if uses_keboard then
+						if kmf.frame_camera then
+							local mouse_cursor = Mouse.axis(Mouse.axis_index("cursor"), Mouse.RAW, 3)
+							mouse_cursor = { x = mouse_cursor[1], y = mouse_cursor[2]}
 
-						if not EntityAux_extension(unit, "damage_receiver") or unit == u then
-							break
-						end
+							local min_distance = 10000
 
-						local pose, box = Unit.box(unit)
-						local height = box[3]
-
-						if cutoff_height <= height then
-							local point, is_inside = closest_point_to_obb(mypos, pose, box)
-							local new_direction = Vector3.normalize(point - mypos)
-							local my_forward = Vector3.unbox(forward_box)
-							local a_dot_b = Vector3.dot(new_direction, my_forward)
-							local radians = math.acos_safe(a_dot_b)
-							local angle = math.radians_to_degrees(radians)
-
-							if angle < half_spread or is_inside then
-								if height >= target_heights[3] then
-									if table.map_size(possible_targets) > 2 then
-										table.remove(possible_targets, 1)
-									end
 
-									if table.map_size(target_heights) > 2 then
-										table.remove(target_heights, 1)
-									end
+							for i, actor in ipairs(actors) do
+								repeat
+									if not actor then break end
 
-									table.insert(target_heights, 3, height)
-									table.insert(possible_targets, 3, unit)
-								elseif height >= target_heights[2] then
-									if table.map_size(possible_targets) > 2 then
-										table.remove(possible_targets, 1)
-									end
+									local unit = Actor.unit(actor)
 
-									if table.map_size(target_heights) > 2 then
-										table.remove(target_heights, 1)
+									if not unit or not Unit.alive(unit) or unit == caster then
+										break
 									end
 
-									table.insert(target_heights, 2, height)
-									table.insert(possible_targets, 2, unit)
-								elseif height >= target_heights[1] then
-									if table.map_size(possible_targets) > 2 then
-										table.remove(possible_targets, 1)
-									end
+									local screen_pos = kmf.frame_camera:world_to_screen(Unit.world_position(unit, 0))
+									local diff_x = mouse_cursor.x - screen_pos.x
+									local diff_y = mouse_cursor.y - screen_pos.z
 
-									if table.map_size(target_heights) > 2 then
-										table.remove(target_heights, 1)
+									local dist = math.sqrt(diff_x * diff_x + diff_y * diff_y)
+									if min_distance > dist then
+										min_distance = dist
+										target_unit = unit
 									end
+								until true
+							end
+						end
+					elseif caster and Unit.alive(caster) then
+						local char_dir = Quaternion.forward(Unit.world_rotation(caster, 0))
+						local char_pos = Unit.world_position(caster, 0)
+						local max_score = 0
+
+						for i, actor in ipairs(actors) do
+							repeat
+								if not actor then break end
+
+								local unit = Actor.unit(actor)
 
-									table.insert(target_heights, 1, height)
-									table.insert(possible_targets, 1, unit)
+								if not unit or not Unit.alive(unit) or unit == caster or not EntityAux.extension(unit, "character") then
+									break
 								end
 
-								cutoff_height = target_heights[1] or height
-							end
+								local t_pos = Unit.world_position(unit, 0)
+								local t_dir = Vector3.normalize(t_pos - char_pos)
+
+								local angle = math.acos( Vector3.dot(char_dir, t_dir) / math.sqrt( Vector3.dot(char_dir, char_dir) * Vector3.dot(t_dir, t_dir) ) ) * 0.6366198
+								local dist = Vector3.distance(t_pos, char_pos) / 10
+
+								dist = dist > 0.1 and dist or 0.1
+								angle = angle / 10
+								angle = angle > 0.01 and angle or 0.01
+
+								local score = (1 / angle) + (1.0 / dist)
+
+								if score > max_score then
+									max_score = score
+									target_unit = unit
+								end
+							until true
 						end
-					until true
+					end
 				end
 
-				local hit_unit
+				if not target_unit then
+					for i, actor in ipairs(actors) do
+						repeat
+							local unit = Actor.unit(actor)
+
+							if not EntityAux_extension(unit, "damage_receiver") or unit == u then
+								break
+							end
 
-				if not table.empty(possible_targets) then
-					math.randomseed(os.time())
-					math.random()
-					math.random()
-					math.random()
+							local pose, box = Unit.box(unit)
+							local height = box[3]
+
+							if cutoff_height <= height then
+								local point, is_inside = closest_point_to_obb(mypos, pose, box)
+								local new_direction = Vector3.normalize(point - mypos)
+								local my_forward = Vector3.unbox(forward_box)
+								local a_dot_b = Vector3.dot(new_direction, my_forward)
+								local radians = math.acos_safe(a_dot_b)
+								local angle = math.radians_to_degrees(radians)
+
+								if angle < half_spread or is_inside then
+									if height >= target_heights[3] then
+										if table.map_size(possible_targets) > 2 then
+											table.remove(possible_targets, 1)
+										end
 
-					local random_hit_factor = math.random()
+										if table.map_size(target_heights) > 2 then
+											table.remove(target_heights, 1)
+										end
 
-					if random_hit_factor <= 0.1 then
-						hit_unit = u
-					elseif random_hit_factor <= 0.3 then
-						hit_unit = possible_targets[1]
-					elseif random_hit_factor <= 0.6 then
-						hit_unit = possible_targets[2]
-					else
-						hit_unit = possible_targets[3]
+										table.insert(target_heights, 3, height)
+										table.insert(possible_targets, 3, unit)
+									elseif height >= target_heights[2] then
+										if table.map_size(possible_targets) > 2 then
+											table.remove(possible_targets, 1)
+										end
+
+										if table.map_size(target_heights) > 2 then
+											table.remove(target_heights, 1)
+										end
+
+										table.insert(target_heights, 2, height)
+										table.insert(possible_targets, 2, unit)
+									elseif height >= target_heights[1] then
+										if table.map_size(possible_targets) > 2 then
+											table.remove(possible_targets, 1)
+										end
+
+										if table.map_size(target_heights) > 2 then
+											table.remove(target_heights, 1)
+										end
+
+										table.insert(target_heights, 1, height)
+										table.insert(possible_targets, 1, unit)
+									end
+
+									cutoff_height = target_heights[1] or height
+								end
+							end
+						until true
 					end
 
-					hit_unit = hit_unit or possible_targets[3]
+					local hit_unit
+
+					if not table.empty(possible_targets) then
+						math.randomseed(os.time())
+						math.random()
+						math.random()
+						math.random()
+
+						local random_hit_factor = math.random()
+
+						if random_hit_factor <= 0.1 then
+							hit_unit = u
+						elseif random_hit_factor <= 0.3 then
+							hit_unit = possible_targets[1]
+						elseif random_hit_factor <= 0.6 then
+							hit_unit = possible_targets[2]
+						else
+							hit_unit = possible_targets[3]
+						end
+
+						hit_unit = hit_unit or possible_targets[3]
+					end
+
+					magick_context.hit_unit = hit_unit or u
+				else
+					magick_context.hit_unit = target_unit
 				end
 
-				magick_context.hit_unit = hit_unit or u
 			end
 
 			local radius = SpellSettings.thunderbolt_range
+			if kmf.vars.funprove_enabled then
+				radius = 20
+			end
 			local forward = UnitAux.forward(u, 0)
 
 			magick_context.world:physics_overlap(query_callback, "shape", "sphere", "position", position, "size", radius, "types", "both", "collision_filter", "damage_query")
@@ -3825,15 +4242,25 @@ Magicks = {
 					local world = magick_context.world
 					local source_unit = magick_context.staff_unit
 					local unit_storage = magick_context.unit_spawner.unit_storage
+					local thunderbolt_damage = SpellSettings.thunderbolt_damage
+
+					-- fun-balance :: buff qfasa damage
+					if kmf.vars.funprove_enabled then
+						thunderbolt_damage = thunderbolt_damage * 2
+					end
 
 					if not source_unit or not Unit.alive(source_unit) then
 						source_unit = EntityAux_extension(u, "inventory").inventory.staff or magick_context.caster
 					end
 
+					if source_unit == nil then
+						return false
+					end
+
 					magick_context.source_pid = world:create_particles_linked("content/particles/magicks/thunderbolt_source", source_unit, "spell_source", ParticleOrphanedPolicy.destroy)
 
 					magick_context.network:send_create_damages_and_particles(hu, Unit.world_position(hu, 0), magick_context.caster, {
-						lightning = SpellSettings.thunderbolt_damage
+						lightning = thunderbolt_damage
 					}, "content/particles/spells/magicks/thunderbolt_hit", "play_magick_thunderbolt_event")
 				end
 			else
@@ -3847,7 +4274,10 @@ Magicks = {
 		end
 	},
 	summon_living_dead = {
-		on_enter = function(u, magick_context)
+		on_enter = function (u, magick_context)
+			if u == nil or magick_context.caster == nil then
+				return false
+			end
 			local char_ext = EntityAux.extension(magick_context.caster, "character")
 
 			EntityAux.set_input_by_extension(char_ext, CSME.spell_channel, nil)
@@ -3855,7 +4285,6 @@ Magicks = {
 			EntityAux.set_input_by_extension(char_ext, "args", "cast_magick_direct")
 
 			magick_context.timer = 0
-
 			return true
 		end,
 		update = function(u, magick_context, dt)
@@ -3863,6 +4292,10 @@ Magicks = {
 				magick_context.timer = magick_context.timer + dt
 
 				if magick_context.timer > 0.5 then
+					if u == nil or magick_context.caster == nil then
+						return false
+					end
+
 					local caster = magick_context.caster
 
 					magick_context.cast_done = true
@@ -3879,9 +4312,7 @@ Magicks = {
 					local start_position = Unit.world_position(caster, 0)
 					local cast_direction = Vector3.normalize(UnitAux.forward(caster, 0))
 					local players, players_n = magick_context.entity_manager:get_entities("player")
-					local base_num_units = SpellSettings.summon_living_dead_num_units
-					local per_player_unit_reduction = SpellSettings.summon_living_dead_unit_reduction_per_player
-					local num_units_to_spawn = base_num_units - players_n * per_player_unit_reduction + per_player_unit_reduction
+					local num_units_to_spawn = kmf.get_number_of_magick_skeleton_spawns(players_n)
 
 					assert(num_units_to_spawn > 0)
 
@@ -3904,7 +4335,7 @@ Magicks = {
 						ACTIVE_LIVING_DEAD_UNITS[caster] = nil
 					end
 
-					for i = 1, num_units_to_spawn do
+					for i = 1, num_units_to_spawn, 1 do
 						local direction = Quaternion.rotate(Quaternion(Vector3(0, 0, 1), angle_between_units * (i - 1)), cast_direction)
 						local spawn_position = start_position + direction * spawn_offset
 
@@ -3932,6 +4363,10 @@ Magicks = {
 							}
 						}
 
+						if kmf.vars.pvp_gamemode then
+							init_data.faction.faction = caster_faction == "evil" and "kmf_evil" or (caster_faction == "player" and "kmf_player" or caster_faction)
+						end
+
 						if magick_context.network.is_server then
 							local spawned_unit = unit_spawner:spawn_unit(unit_to_spawn, "character", nil, spawn_position, spawn_rotation, init_data)
 
@@ -3995,7 +4430,11 @@ Magicks = {
 		end
 	},
 	thunderhead = {
-		on_enter = function(u, magick_context)
+		on_enter = function (u, magick_context)
+			if u == nil or magick_context.caster == nil then
+				return false
+			end
+
 			EntityAux.set_input(u, "character", CSME.spell_cast, true)
 			EntityAux.set_input(u, "character", "args", "cast_magick_direct")
 
@@ -4047,7 +4486,7 @@ Magicks = {
 
 				magick_context.next_turn = 0
 
-				function magick_context.query_callback(actors)
+				magick_context.query_callback = function (actors)
 					local hit_units = {}
 
 					if actors and #actors then
@@ -4258,7 +4697,14 @@ Magicks = {
 		end
 	},
 	guardian = {
-		on_enter = function(u, magick_context)
+		on_enter = function (u, magick_context)
+			if u == nil or magick_context.caster == nil then
+				return false
+			end
+
+			local faction_ext = EntityAux.extension(magick_context.caster, "faction")
+			local caster_faction = faction_ext and faction_ext.internal.faction or "player"
+
 			local caster = magick_context.caster
 			local char_ext = EntityAux.extension(caster, "character")
 
@@ -4283,6 +4729,7 @@ Magicks = {
 				local spawned_unit = us:spawn_unit(unit_to_spawn, "position_unit", go_data, magick_activate_position, rot, init_data)
 
 				Unit.set_flow_variable(spawned_unit, "damage_replacer", caster)
+				Unit.set_data(spawned_unit, "kmf_guardian_caster_faction", caster_faction)
 			end
 
 			return false
@@ -4295,6 +4742,10 @@ Magicks = {
 		on_enter = function(u, magick_context)
 			local caster = magick_context.caster
 
+			if magick_context.caster then
+				magick_context.caster_faction = Unit.get_data(magick_context.caster, "kmf_guardian_caster_faction")
+			end
+
 			if caster == nil or not Unit.alive(caster) then
 				return false
 			end
@@ -4390,7 +4841,11 @@ Magicks = {
 
 			return true
 		end,
-		animation_completed = function(magick_context)
+		animation_completed = function (magick_context)
+			if magick_context.caster == nil then
+				return false
+			end
+
 			if not magick_context.is_standalone then
 				magick_context.animation_completed = true
 
@@ -4442,6 +4897,27 @@ Magicks = {
 				local best_time = 0
 				local resurrect_target
 
+				local caster_faction = magick_context.caster_faction and magick_context.caster_faction or "player"
+				if kmf.vars.pvp_gamemode then
+					local new_player_array = {}
+
+					for i = 1, players_n do
+						local unit = players[i].unit
+
+						if unit and Unit.alive(unit) then
+							local faction_ext = EntityAux.extension(unit, "faction")
+							local faction = faction_ext and faction_ext.internal.faction or "player"
+
+							if faction == caster_faction then
+								new_player_array[#new_player_array + 1] = players[i]
+							end
+						end
+					end
+
+					players_n = #new_player_array
+					players = new_player_array
+				end
+
 				if is_local and finished then
 					for i = 1, players_n do
 						local extension_data = players[i]
@@ -4597,6 +5073,10 @@ Magicks = {
 		end,
 		on_exit = function(u, magick_context)
 			if not magick_context.finished then
+				if u == nil or magick_context.caster == nil then
+					return
+				end
+
 				local caster = magick_context.caster
 				local is_local = magick_context.is_local
 
@@ -4620,7 +5100,11 @@ Magicks = {
 		end
 	},
 	sacrifice = {
-		on_enter = function(u, magick_context)
+		on_enter = function (u, magick_context)
+			if u == nil then
+				return false
+			end
+
 			local caster = u
 			local caster_health_ext = EntityAux_extension(caster, "health")
 
@@ -4678,7 +5162,11 @@ Magicks = {
 		on_cast = function(u, magick_context)
 			magick_context.do_trigger = true
 		end,
-		update = function(u, magick_context, dt)
+		update = function (u, magick_context, dt)
+			if u == nil or magick_context.caster == nil then
+				return false
+			end
+
 			local caster = magick_context.caster
 
 			if not magick_context.has_triggered then
@@ -4701,22 +5189,26 @@ Magicks = {
 
 				for i = 1, players_n do
 					local extension_data = players[i]
-					local u, extension = extension_data.unit, extension_data.extension
-					local health_ext = EntityAux_extension(u, "health")
-					local health_ext_state = health_ext.state
+					local u = extension_data.unit
 
-					if u ~= caster and health_ext_state.health <= 0 and magick_context.is_local then
-						set_input_by_extension(health_ext, "resurrect", caster)
-						set_input_by_extension(health_ext, "resurrect_health", SpellSettings.sacrifice_revive_health_percentage)
-						magick_context.network:send_set_focus_percentage(u, SpellSettings.sacrifice_revive_focus_percentage_tier1, SpellSettings.sacrifice_revive_focus_percentage_tier2, SpellSettings.sacrifice_revive_focus_percentage_tier3, SpellSettings.sacrifice_revive_focus_percentage_tier4)
+					if u ~= nil then
+						local extension = extension_data.extension
+						local health_ext = EntityAux_extension(u, "health")
+						local health_ext_state = health_ext.state
 
-						local resurrecter_player_ext = EntityAux.extension(caster, "player")
+						if u ~= caster and health_ext_state.health <= 0 and magick_context.is_local then
+							set_input_by_extension(health_ext, "resurrect", caster)
+							set_input_by_extension(health_ext, "resurrect_health", SpellSettings.sacrifice_revive_health_percentage)
+							magick_context.network:send_set_focus_percentage(u, SpellSettings.sacrifice_revive_focus_percentage_tier1, SpellSettings.sacrifice_revive_focus_percentage_tier2, SpellSettings.sacrifice_revive_focus_percentage_tier3, SpellSettings.sacrifice_revive_focus_percentage_tier4)
 
-						if resurrecter_player_ext then
-							StatManager:modify_stat("friends_revived", 1, resurrecter_player_ext.local_player_id)
-						end
+							local resurrecter_player_ext = EntityAux.extension(caster, "player")
+
+							if resurrecter_player_ext then
+								StatManager:modify_stat("friends_revived", 1, resurrecter_player_ext.local_player_id)
+							end
 
-						players_revived = players_revived + 1
+							players_revived = players_revived + 1
+						end
 					end
 				end
 
@@ -4732,11 +5224,21 @@ Magicks = {
 
 				tkey.sacrifice_explode = true
 
-				set_input_by_extension(ability_ext, "start_ability", tkey)
+				local status, err = pcall(function()
+					set_input_by_extension(ability_ext, "start_ability", tkey)
+				end)
+				if not status then
+					return false
+				end
 
 				local gib_offset = Vector3.box({}, Vector3(1, 1, 3))
 
-				set_input_by_extension(magick_context.caster_health_ext, "gib_offset", gib_offset)
+				local status, err = pcall(function()
+					set_input_by_extension(magick_context.caster_health_ext, "gib_offset", gib_offset)
+				end)
+				if not status then
+					return false
+				end
 
 				magick_context.has_triggered = true
 			elseif magick_context.caster_shall_die then
@@ -4765,6 +5267,10 @@ Magicks = {
 		on_exit = function(u, magick_context)
 			local caster = u
 
+			if u == nil or magick_context.caster_effect_unit == nil then
+				return
+			end
+
 			magick_context.world:unlink_unit(magick_context.caster_effect_unit)
 			magick_context.unit_spawner:mark_for_deletion(magick_context.caster_effect_unit)
 			set_input_by_extension(magick_context.caster_health_ext, "invulnerable", false)
