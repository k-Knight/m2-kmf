diff --git a/scripts/game/entity_system/systems/status/status_system_statuses.lua b/scripts/game/entity_system/systems/status/status_system_statuses.lua
index 7fa995b..7273d13 100644
--- a/scripts/game/entity_system/systems/status/status_system_statuses.lua
+++ b/scripts/game/entity_system/systems/status/status_system_statuses.lua
@@ -71,9 +71,9 @@ local ice_element_queue = {
 local cold_element_queue = {
 	"cold"
 }
-local steam_element_queue = {
-	"steam"
-}
+--local steam_element_queue = {
+--	"steam"
+--}
 local bleed_element_queue = {
 	"bleed"
 }
@@ -87,7 +87,7 @@ local queue_to_elements_lut = {
 	[poison_element_queue] = make_elements_from_queue(poison_element_queue),
 	[ice_element_queue] = make_elements_from_queue(ice_element_queue),
 	[cold_element_queue] = make_elements_from_queue(cold_element_queue),
-	[steam_element_queue] = make_elements_from_queue(steam_element_queue),
+	--[steam_element_queue] = make_elements_from_queue(steam_element_queue),
 	[bleed_element_queue] = make_elements_from_queue(bleed_element_queue)
 }
 local ATTACKERS_TABLE = {}
@@ -161,6 +161,19 @@ StatusSystemStatuses = {
 				end
 			end
 
+			-- fun-balance :: buff burning starting dot damage
+			if kmf.vars.funprove_enabled then
+				local mult = 2.0
+
+				if EntityAux.extension(u, "player") then
+					mult = 3.0
+				end
+
+				internal.burning_dps = internal.burning_dps * mult
+			end
+
+			internal.kmf_fire_tick_time = kmf.world_proxy:time()
+
 			if internal.burning_dps < 0 then
 				internal.burning_dps = math.abs(internal.burning_dps)
 			end
@@ -197,15 +210,19 @@ StatusSystemStatuses = {
 		end,
 		update = function(u, internal, status, network, context)
 			local dt = context.dt
+			local interval = kmf.vars.experimental_balance and 0.5 or 1
 
 			internal.burning_damage_time = internal.burning_damage_time + dt or 1
 
-			if internal.burning_damage_time > 1 then
+			if internal.burning_damage_time > interval then
 				internal.burning_damage_time = 0
 
+				-- fun-balance :: buff fire dot damage for players
 				local damage_table = FrameTable.alloc_table()
+				local player_ext = EntityAux.extension(u, "player")
+				local dot_dmg_mult = (player_ext and kmf.vars.funprove_enabled) and 1.5 or 1.0
 
-				damage_table.fire = internal.burning_dps
+				damage_table.fire = internal.burning_dps * dot_dmg_mult * interval
 
 				local burning_dealer_name = "other"
 				local burning_dealer = internal.last_burning_dealer
@@ -239,7 +256,7 @@ StatusSystemStatuses = {
 				assert(max_health, "burning unit does not have health extension")
 
 				local old_dps = internal.burning_dps or 0
-				local new_dps = old_dps - SpellSettings.status_burning_dot_decrease_ammount
+				local new_dps = old_dps - (SpellSettings.status_burning_dot_decrease_ammount * interval)
 
 				if new_dps < 0 or internal.immunities.burning then
 					status.burning = nil
@@ -336,7 +353,19 @@ StatusSystemStatuses = {
 
 					for _, damage in ipairs(damages.damage) do
 						if damage[1] == "fire" then
-							internal.burning_dps = internal.burning_dps + math.floor(fire_to_burning_factor * damage[2])
+							local additive = math.floor(fire_to_burning_factor * damage[2])
+
+							-- fun-balance :: buff burning damage and control stacking
+							if kmf.vars.funprove_enabled then
+								local time = kmf.world_proxy:time()
+								local time_scale = (time - (internal.kmf_fire_tick_time or 0)) / 0.1
+
+								time_scale = math.min(time_scale * time_scale, 1.0)
+								additive = additive * 2.0 * time_scale
+								internal.kmf_fire_tick_time = time
+							end
+
+							internal.burning_dps = internal.burning_dps + additive
 						end
 					end
 
@@ -1186,6 +1215,36 @@ StatusSystemStatuses = {
 			internal.poison_dot_timer = 0
 			internal.extension_timer = 0.5
 
+			internal.kmf_poison_tick_time = kmf.world_proxy:time()
+			internal.kmf_poison_dps = 0
+			internal.kmf_poisoned_damage_time = 0
+
+			local damage_reciever_state = EntityAux.state(u, "damage_receiver")
+			local damage_table = damage_reciever_state.damage
+			local fire_to_burning_factor = SpellSettings.status_burning_fire_to_burning_factor
+			local start_mult = 2.0
+
+			if EntityAux.extension(u, "player") then
+				start_mult = 3.0
+			end
+
+			-- fun-balance :: buff poison starting dot damage
+			for _, damage in ipairs(damage_table) do
+				if damage[1] == "poison" then
+					internal.kmf_poison_dps = ((internal.kmf_poison_dps or 0) + math.floor(fire_to_burning_factor * damage[2])) * start_mult
+				end
+			end
+
+			internal.kmf_poison_tick_time = kmf.world_proxy:time()
+
+			if internal.kmf_poison_dps < 0 then
+				internal.kmf_poison_dps = math.abs(internal.kmf_poison_dps)
+			end
+
+			if internal.kmf_poison_dps > SpellSettings.status_poisoned_max_damage then
+				internal.kmf_poison_dps = SpellSettings.status_poisoned_max_damage
+			end
+
 			StatusAux_add_effect_descriptor(u, 0, poison_element_queue)
 			EntityAux.add_speed_multiplier(u, SpellSettings.status_poisoned_speed_factor)
 			network:transmit_all_except_me("on_start_event_status_husk", network.unit_storage:go_id(u), StatusSystem:lookup_status("poisoned"), internal.poison_magnitude, internal.poison_multiplier)
@@ -1222,79 +1281,161 @@ StatusSystemStatuses = {
 			end
 		end,
 		update = function(u, internal, status, network, context)
-			local dt = context.dt
+			if not kmf.vars.funprove_enabled then
+				local dt = context.dt
 
-			internal.poisoned_duration = internal.poisoned_duration - dt
-			internal.poison_dot_timer = internal.poison_dot_timer + dt
+				internal.poisoned_duration = internal.poisoned_duration - dt
+				internal.poison_dot_timer = internal.poison_dot_timer + dt
 
-			if internal.extension_timer > 0 then
-				internal.extension_timer = internal.extension_timer - dt
-			end
+				if internal.extension_timer > 0 then
+					internal.extension_timer = internal.extension_timer - dt
+				end
 
-			if internal.poisoned_duration <= 0 or internal.immunities.poisoned or status.frozen then
-				status.poisoned = nil
-			elseif internal.poison_dot_timer > SpellSettings.status_poisoned_dot_timer then
-				internal.poison_dot_timer = 0
-				internal.poison_dot_ticks = internal.poison_dot_ticks + 1
-				internal.poison_dot_percent = internal.poison_dot_percent + internal.poison_magnitude * 1 / internal.poison_dot_ticks * SpellSettings.status_poisoned_tick_diminishing * internal.poison_multiplier
+				if internal.poisoned_duration <= 0 or internal.immunities.poisoned or status.frozen then
+					status.poisoned = nil
+				elseif internal.poison_dot_timer > SpellSettings.status_poisoned_dot_timer then
+					internal.poison_dot_timer = 0
+					internal.poison_dot_ticks = internal.poison_dot_ticks + 1
+					internal.poison_dot_percent = internal.poison_dot_percent + internal.poison_magnitude * 1 / internal.poison_dot_ticks * SpellSettings.status_poisoned_tick_diminishing * internal.poison_multiplier
 
-				local max_health = EntityAux.extension(u, "health").state.max_health
+					local max_health = EntityAux.extension(u, "health").state.max_health
 
-				assert(max_health, "Poisoned unit does not have health extension")
+					assert(max_health, "Poisoned unit does not have health extension")
 
-				local dot_value = math.clamp(max_health * internal.poison_dot_percent, 1, SpellSettings.status_poisoned_max_damage)
-				local damage_table = FrameTable.alloc_table()
+					local dot_value = math.clamp(max_health * internal.poison_dot_percent, 1, SpellSettings.status_poisoned_max_damage)
+					local damage_table = FrameTable.alloc_table()
 
-				damage_table.poison = dot_value
+					damage_table.poison = dot_value
 
-				local poison_dealer_name = "other"
-				local poison_dealer = internal.last_poison_dealer
+					local poison_dealer_name = "other"
+					local poison_dealer = internal.last_poison_dealer
 
-				if poison_dealer then
-					if not Unit.alive(poison_dealer) then
-						internal.last_poison_dealer = nil
+					if poison_dealer then
+						if not Unit.alive(poison_dealer) then
+							internal.last_poison_dealer = nil
+							poison_dealer = u
+							poison_dealer_name = internal.last_poison_dealer_name and internal.last_poison_dealer_name or "other"
+						elseif Unit.alive(poison_dealer) then
+							poison_dealer_name = EntityAux.get_unit_owner_name(poison_dealer)
+							internal.last_poison_dealer_name = poison_dealer_name
+						else
+							poison_dealer_name = internal.last_poison_dealer_name
+						end
+					else
 						poison_dealer = u
 						poison_dealer_name = internal.last_poison_dealer_name and internal.last_poison_dealer_name or "other"
-					elseif Unit.alive(poison_dealer) then
-						poison_dealer_name = EntityAux.get_unit_owner_name(poison_dealer)
-						internal.last_poison_dealer_name = poison_dealer_name
-					else
-						poison_dealer_name = internal.last_poison_dealer_name
 					end
-				else
-					poison_dealer = u
-					poison_dealer_name = internal.last_poison_dealer_name and internal.last_poison_dealer_name or "other"
+
+					ATTACKERS_TABLE[1] = poison_dealer
+
+					EntityAux.add_damage(u, ATTACKERS_TABLE, damage_table, "dot", nil, nil, nil, poison_dealer_name)
+
+					ATTACKERS_TABLE[1] = nil
 				end
+			else
+				-- fun-balance :: new poison dot damage application
+				local dt = context.dt
+				local interval = kmf.vars.experimental_balance and 0.5 or 1
 
-				ATTACKERS_TABLE[1] = poison_dealer
+				internal.kmf_poisoned_damage_time = internal.kmf_poisoned_damage_time + dt or 1
 
-				EntityAux.add_damage(u, ATTACKERS_TABLE, damage_table, "dot", nil, nil, nil, poison_dealer_name)
+				if internal.kmf_poisoned_damage_time > interval then
+					internal.kmf_poisoned_damage_time = 0
 
-				ATTACKERS_TABLE[1] = nil
+					local damage_table = FrameTable.alloc_table()
+					local player_ext = EntityAux.extension(u, "player")
+					local dot_dmg_mult = (player_ext and 1.5 or 1.0) / 2.8 -- divider has to be adjusted with flat poison multiplier in PvE / PvP multipliers section
+
+					damage_table.poison = internal.kmf_poison_dps * dot_dmg_mult * interval
+
+					local poison_dealer_name = "other"
+					local poison_dealer = internal.last_poison_dealer
+
+					if poison_dealer then
+						if not Unit.alive(poison_dealer) then
+							internal.last_poison_dealer = nil
+							poison_dealer = u
+							poison_dealer_name = internal.last_poison_dealer_name and internal.last_poison_dealer_name or "other"
+						elseif Unit.alive(poison_dealer) then
+							poison_dealer_name = EntityAux.get_unit_owner_name(poison_dealer)
+							internal.last_poison_dealer_name = poison_dealer_name
+						else
+							poison_dealer_name = internal.last_poison_dealer_name
+						end
+					else
+						poison_dealer = u
+						poison_dealer_name = internal.last_poison_dealer_name and internal.last_poison_dealer_name or "other"
+					end
+
+					ATTACKERS_TABLE[1] = poison_dealer
+
+					EntityAux.add_damage(u, ATTACKERS_TABLE, damage_table, "dot", nil, nil, nil, poison_dealer_name)
+
+					ATTACKERS_TABLE[1] = nil
+
+					local old_dps = internal.kmf_poison_dps or 0
+					local new_dps = old_dps - (SpellSettings.status_burning_dot_decrease_ammount * interval)
+
+					if new_dps < 0 or internal.immunities.poisoned or status.frozen then
+						status.poisoned = nil
+						internal.kmf_poison_dps = 0
+
+						return
+					end
+
+					internal.kmf_poison_dps = new_dps
+				end
 			end
 		end,
 		on_damages = function(u, types, internal, status, network, damages, dealers)
 			for dmg_type, dmg_amount in pairs(types) do
 				if dmg_type == "life" and dmg_amount > 0 then
 					status.poisoned = nil
-				elseif dmg_type == "poison" and internal.extension_timer <= 0 then
+					internal.kmf_poison_dps = 0
+				elseif dmg_type == "poison"then
 					internal.last_poison_dealer = dealers[1]
 
-					local time_extension = SpellSettings.status_poisoned_extend_duration
-					local max_poisoned_duration = SpellSettings.status_poisoned_max_duration
 
-					if max_poisoned_duration >= internal.total_time_poisoned + time_extension then
-						local new_poison_magnitude = dmg_amount
+					if not kmf.vars.funprove_enabled then
+						if internal.extension_timer <= 0 then
+							local time_extension = SpellSettings.status_poisoned_extend_duration
+							local max_poisoned_duration = SpellSettings.status_poisoned_max_duration
+							if max_poisoned_duration >= internal.total_time_poisoned + time_extension then
+								local new_poison_magnitude = dmg_amount
 
-						if new_poison_magnitude > internal.poison_magnitude then
-							internal.poison_magnitude = new_poison_magnitude
+								if new_poison_magnitude > internal.poison_magnitude then
+									internal.poison_magnitude = new_poison_magnitude
+								end
+
+								internal.poisoned_duration = internal.poisoned_duration + time_extension
+								internal.total_time_poisoned = internal.total_time_poisoned + time_extension
+							end
+
+							internal.extension_timer = 0.5
 						end
+					else
+						-- fun-balance :: new poison dot stacking
+						local old_dps = internal.kmf_poison_dps
+						local fire_to_burning_factor = SpellSettings.status_burning_fire_to_burning_factor
 
-						internal.poisoned_duration = internal.poisoned_duration + time_extension
-						internal.total_time_poisoned = internal.total_time_poisoned + time_extension
-					end
+						for _, damage in ipairs(damages.damage) do
+							if damage[1] == "poison" then
+								local additive = math.floor(fire_to_burning_factor * damage[2])
+								local time = kmf.world_proxy:time()
+								local time_scale = (time - (internal.kmf_poison_tick_time or 0)) / 0.1
 
-					internal.extension_timer = 0.5
+								time_scale = math.min(time_scale * time_scale, 1.0)
+								additive = additive * 2.0 * time_scale
+								internal.kmf_poison_tick_time = time
+
+								internal.kmf_poison_dps = internal.kmf_poison_dps + additive
+							end
+						end
+
+						if internal.kmf_poison_dps > SpellSettings.status_poisoned_max_damage then
+							internal.kmf_poison_dps = SpellSettings.status_poisoned_max_damage
+						end
+					end
 				end
 			end
 		end,
