diff --git a/scripts/game/entity_system/systems/spellcasting/spell_fissure.lua b/scripts/game/entity_system/systems/spellcasting/spell_fissure.lua
index e2bb1c5..a1a662a 100644
--- a/scripts/game/entity_system/systems/spellcasting/spell_fissure.lua
+++ b/scripts/game/entity_system/systems/spellcasting/spell_fissure.lua
@@ -112,7 +112,10 @@ Spells_Fissure = {
 		local elements = context.elements
 		local weapon_unit = context.weapon_unit
 		local pvm = context.player_variable_manager
+		local unique_id = context.kmf_unique_id
+		local owner_peer = context.kmf_owner_peer
 		local char_ext = EntityAux.extension(caster, "character")
+		local is_local = caster and NetworkUnit.is_local_unit(caster)
 
 		if char_ext and not context.is_standalone then
 			local animation_event = "melee_attack_thrust"
@@ -162,6 +165,52 @@ Spells_Fissure = {
 			scale_damage = context.scale_damage
 		}
 
+		if kmf.vars.funprove_enabled and unique_id then
+			if is_local then
+				local query_callback = function(actors)
+					local targets = {}
+					local cutoff_height = -1
+					local added_units = {}
+
+					for i, actor in ipairs(actors) do
+						repeat
+							local unit = Actor.unit(actor)
+
+							if (not unit or not Unit.alive(unit)) or (caster and unit == caster) or added_units[unit] then
+								break
+							end
+
+							-- yeah, pve does not benefit, very unlucky, too much data
+							local player_ext = EntityAux.extension(unit, "player")
+
+							if player_ext then
+								added_units[unit] = true
+								targets[#targets + 1] = unit
+							end
+						until true
+					end
+
+					data.kmf_anchors = targets
+				end
+
+				data.kmf_anchors = nil
+
+				context.world:physics_overlap(
+					query_callback,
+					"shape", "sphere",
+					"position", position,
+					"size", 40,
+					"types", "both",
+					"collision_filter", "character_query"
+				)
+			end
+
+			data.kmf_start_point = Vector3.box({}, Unit.world_position(caster, 0))
+			data.kmf_is_local = is_local
+			data.kmf_unique_id = unique_id
+			data.kmf_owner_peer = owner_peer
+		end
+
 		function data.raycast_callback(any_hit, position, distance, normal, actor)
 			if any_hit then
 				local explosions_done = data.explosions_done
@@ -188,6 +237,17 @@ Spells_Fissure = {
 
 		local damage, magnitudes = SETTINGS:get_fissure_damage(pvm, caster, elements)
 
+		if kmf.vars.funprove_enabled then
+			if damage.knockdown then
+				damage.knockdown = damage.knockdown * 2
+			end
+			if magnitudes["earth"] then
+				magnitudes["earth"] = magnitudes["earth"] * 2
+			end
+		end
+
+		data.kmf_fissure_hit_units = {}
+
 		assert(damage, "no damage table for spell_fissure")
 		assert(magnitudes, "no magnitudes table for spell_fissure")
 
@@ -217,11 +277,15 @@ Spells_Fissure = {
 						local damage_receiver = EntityAux_extension(unit, "damage_receiver")
 
 						if damage_receiver then
-							ATTACKERS_TABLE[1] = caster
-
-							EntityAux.add_damage(unit, ATTACKERS_TABLE, damage, "force", data.scale_damage)
-
-							ATTACKERS_TABLE[1] = nil
+							if data.kmf_fissure_hit_units[unit] and kmf.vars.bugfix_enabled then
+								-- block empty
+							else
+								data.kmf_fissure_hit_units[unit] = true
+
+								ATTACKERS_TABLE[1] = caster
+								EntityAux.add_damage(unit, ATTACKERS_TABLE, damage, {"force", "fissure"}, data.scale_damage)
+								ATTACKERS_TABLE[1] = nil
+							end
 						end
 
 						if magnitudes then
@@ -245,14 +309,157 @@ Spells_Fissure = {
 		local time_elapsed = data.time_elapsed + dt
 		local explosions_done = data.explosions_done
 		local effect_manager = context.effect_manager
+		local time_between = SpellSettings.fissure_time_between_explosions
+		local funprove_enabled = kmf.vars.funprove_enabled
+		local my_pos
+
+		if funprove_enabled then
+			local time = kmf.world_proxy:time()
+			local delta_t = time - (data.last_update_time or 0)
+			my_pos = Vector3.unbox(data.kmf_start_point)
+
+			time_between = time_between * 0.625
+
+			if data.kmf_is_local and data.kmf_unique_id and data.kmf_anchors and delta_t > 0.05 then
+				data.last_update_time = time
+
+				local my_dir = Vector3.normalize(Vector3.unbox(data.forward_table))
+				local unit_storage = kmf.network.unit_storage
+				local archor_dirs = {}
+				local archor_deltas = {}
+				local weight_sum = 0
+
+				for _, unit in pairs(data.kmf_anchors) do
+					if unit and Unit.alive(unit) then
+						local go_id = unit_storage:go_id(unit)
+
+						if go_id then
+							local a_dir = Unit.world_position(unit, 0) - my_pos
+							a_dir.z = my_dir.z
+							local a_delta = my_dir - Vector3.normalize(a_dir)
+							local weight = Vector3.length(a_delta)
+
+							weight = weight * weight
+							weight = weight < 0.001 and 0.001 or weight
+							weight_sum = weight_sum + weight
+
+							archor_deltas[#archor_deltas + 1] = {
+								delta = Vector3.box({}, a_delta),
+								weight = weight,
+								go_id = unit_storage:go_id(unit)
+							}
+						end
+					end
+				end
+
+				local me_peer = kmf.const.me_peer
+				local members = kmf.lobby_handler.connected_peers
+				local msg = ""
+
+				msg = msg .. "fi:" .. tostring(data.kmf_unique_id) .. ";"
+
+				if #archor_deltas == 1 then
+					archor_deltas[1].weight = 0
+				end
+
+				for _, a_delta in pairs(archor_deltas) do
+					local key = "an-" .. tostring(a_delta.go_id) .. "-"
 
-		if time_elapsed > SpellSettings.fissure_time_between_explosions then
-			time_elapsed = time_elapsed - SpellSettings.fissure_time_between_explosions
+					a_delta.weight = 1.0 - (a_delta.weight / weight_sum)
+
+					msg = msg .. key .. "dx:" .. tostring(a_delta.delta[1]) .. ";"
+					msg = msg .. key .. "dy:" .. tostring(a_delta.delta[2]) .. ";"
+					msg = msg .. key .. "dz:" .. tostring(a_delta.delta[3]) .. ";"
+					msg = msg .. key .. "wgh:" .. tostring(a_delta.weight) .. ";"
+				end
+
+				for _, peer in ipairs(members) do
+					if me_peer ~= peer then
+						kmf.send_kmf_msg(peer, msg, "fidc")
+					end
+				end
+			elseif not data.kmf_is_local and data.kmf_owner_peer and data.kmf_unique_id then
+				local owner_peer = data.kmf_owner_peer
+				local unique_id = data.kmf_unique_id
+
+				if data.explosions_done > 3 then
+					local peer_fissures = kmf.vars.fissure_instance_peer_dicts[owner_peer]
+
+					if peer_fissures and peer_fissures[unique_id] then
+						peer_fissures[unique_id].data = nil
+					end
+				else
+					local my_dir = Vector3.normalize(Vector3.unbox(data.forward_table))
+
+					local fissure_instance_info = kmf.vars.fissure_instance_peer_dicts[owner_peer] or {}
+					local fissure_instance_data = fissure_instance_info[unique_id] or {}
+					local unit_storage = kmf.network.unit_storage
+
+					if fissure_instance_data.data then
+						local fi_data = fissure_instance_data.data
+						local my_vel
+						local anchors = {}
+						local weight_sum = 0
+
+						for _, anchor_data in pairs(fi_data.anchors) do
+							local go_id = anchor_data.go_id
+							local weight = anchor_data.weight
+							local delta
+
+							if anchor_data.delta then
+								delta = Vector3.unbox(anchor_data.delta)
+							end
+
+							if go_id and weight and delta ~= nil then
+								local unit = unit_storage:unit(go_id)
+
+								if unit and Unit.alive(unit) then
+									local a_dir = Vector3.normalize(Unit.world_position(unit, 0) - my_pos)
+									weight_sum = weight_sum + weight
+
+									anchors[#anchors + 1] = {
+										dir = Vector3.normalize(delta + a_dir),
+										weight = weight
+									}
+								end
+							end
+						end
+
+						if #anchors > 0 then
+							local avg_dir = Vector3.zero()
+
+							for _, anchor in pairs(anchors) do
+								avg_dir = avg_dir + (anchor.dir * (anchor.weight / weight_sum))
+							end
+
+							avg_dir = Vector3.normalize(avg_dir)
+							data.forward_table = Vector3.box({}, avg_dir)
+						end
+
+						kmf.vars.fissure_instance_peer_dicts[owner_peer][unique_id].data = nil
+					end
+				end
+			end
+		end
+
+		if time_elapsed > time_between then
+			time_elapsed = time_elapsed - time_between
 			explosions_done = explosions_done + 1
 			data.explosions_done = explosions_done
 
+			if funprove_enabled then
+				explosions_done = explosions_done * 0.625
+			end
+
 			local forward = Vector3.unbox(data.forward_table)
-			local pos = Vector3.unbox(data.pos_table) + forward + forward * explosions_done * SpellSettings:get_value(caster, "fissure_distance_between_explosions")
+			local additive = forward * explosions_done * SpellSettings:get_value(caster, "fissure_distance_between_explosions")
+			local pos
+
+			if data.kmf_start_point and my_pos then
+				pos = my_pos + forward * 1.5 + additive
+			else
+				pos = Vector3.unbox(data.pos_table) + forward + additive
+			end
 
 			world:physics_overlap(data.area_callback, "shape", "sphere", "position", pos, "size", FISSURE_RADIUS, "types", "both", "collision_filter", "damage_query")
 
@@ -267,7 +474,12 @@ Spells_Fissure = {
 
 		data.time_elapsed = time_elapsed
 
-		if not data.blocker_hit and explosions_done < SpellSettings:get_value(caster, "fissure_num_hits") and data.time_elapsed < 5 then
+		local max_explosion_count = SpellSettings:get_value(caster, "fissure_num_hits")
+		if funprove_enabled then
+			max_explosion_count = 8
+		end
+
+		if not data.blocker_hit and explosions_done < max_explosion_count and data.time_elapsed < 5 then
 			return true
 		else
 			Spells_Fissure.on_cancel(data, context)
