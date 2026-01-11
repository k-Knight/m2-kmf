diff --git a/scripts/game/entity_system/systems/spellcasting/spellcasting_system.lua b/scripts/game/entity_system/systems/spellcasting/spellcasting_system.lua
index ac9ce7b..d0aeec9 100644
--- a/scripts/game/entity_system/systems/spellcasting/spellcasting_system.lua
+++ b/scripts/game/entity_system/systems/spellcasting/spellcasting_system.lua
@@ -176,6 +176,14 @@ function SpellCastingSystem:init(context)
 		spellcast_system = self
 	}
 
+	if _G.kmf then
+		--kmf.entity_manager = self.entity_manager
+		kmf.network = self.network_transport
+		kmf.unit_storage = self.unit_storage
+		kmf.world = self.world_proxy
+		kmf.spell_casting_system = self
+	end
+
 	self.spell_context = spell_context
 	self.spell_update_context = {
 		dt = 0,
@@ -455,6 +463,26 @@ function SpellCastingSystem:get_current_spell_name(caster)
 	return nil
 end
 
+function SpellCastingSystem:has_spell_active(caster, spell_name)
+	local extension = EntityAux.extension(caster, "spellcast")
+
+	if not extension then
+		return false
+	end
+
+	local internal = extension.internal
+
+	if internal and internal.spells then
+		for _, name in pairs(internal.spells) do
+			if spell_name == name then
+				return true
+			end
+		end
+	end
+
+	return false
+end
+
 function SpellCastingSystem:cast_spell_standalone(sender, go_id, cast_type_id, pos, agility, duration, show_chargeup, projectile_force, wall_health_mul, wall_decay_rate, wall_num_mul, spray_length, spray_width, elems, id, scale_damage)
 	local _agility = agility or 1
 	local _duration = duration > 0 and duration or math.huge
@@ -532,10 +560,10 @@ function SpellCastingSystem:cast_spell(sender, go_id, cast_id, magick_id, eq_net
 		end
 	end
 
-	self:local_cast_spell(unit, cast_type, magick, element_queue, target, rand_seed, magick_activate_position, standalone_data, _scale_damage, skip_waiting)
+	self:local_cast_spell(unit, cast_type, magick, element_queue, target, rand_seed, magick_activate_position, standalone_data, _scale_damage, skip_waiting, sender)
 end
 
-function SpellCastingSystem:local_cast_spell(unit, cast_type, magick, element_queue, target, rand_seed, magick_activate_position, standalone_data, scale_damage, skip_waiting)
+function SpellCastingSystem:local_cast_spell(unit, cast_type, magick, element_queue, target, rand_seed, magick_activate_position, standalone_data, scale_damage, skip_waiting, owner_peer)
 	if rand_seed == 0 then
 		rand_seed = nil
 	end
@@ -561,10 +589,24 @@ function SpellCastingSystem:local_cast_spell(unit, cast_type, magick, element_qu
 	temp_input.override_skip_waiting = skip_waiting
 	temp_input.magick_activate_position = magick_activate_position
 
-	self:_handle_spellcast(unit, temp_input, spellcast_ext.internal, false, spellcast_ext.state, target, standalone_data, rand_seed)
+	local kmf_unique_id
+	local kmf_owner_peer
+
+	if owner_peer and rand_seed and kmf.vars.funprove_enabled then
+		if cast_type == "weapon" then
+			kmf_unique_id = rand_seed
+			kmf_owner_peer = owner_peer
+		end
+	end
+
+	if kmf_unique_id then
+		kmf_print("received spell with unique_id :: " .. tostring(cast_type) .. "    # " .. tostring(kmf_unique_id))
+	end
+
+	self:_handle_spellcast(unit, temp_input, spellcast_ext.internal, false, spellcast_ext.state, target, standalone_data, rand_seed, kmf_unique_id, kmf_owner_peer)
 end
 
-function SpellCastingSystem:_handle_spellcast(unit, input, internal, is_local, state, target, standalone_data, rand_seed)
+function SpellCastingSystem:_handle_spellcast(unit, input, internal, is_local, state, target, standalone_data, rand_seed, kmf_received_unique_id, kmf_received_owner_peer)
 	if input.spell_type == "weapon" and state.melee_allowed == false then
 		return
 	end
@@ -574,6 +616,53 @@ function SpellCastingSystem:_handle_spellcast(unit, input, internal, is_local, s
 	local magick_casted = false
 	local magick_from_elements = input.spell_type == "magick_from_elements"
 	local player_ext = EntityAux.extension(unit, "player")
+	local fix_enabled = kmf.vars.bugfix_enabled
+	local funprove_enabled = kmf.vars.funprove_enabled
+
+	if player_ext and fix_enabled then
+		local char_ext = EntityAux.extension(unit, "character")
+		local spell_type = input.spell_type
+
+		if spell_type then
+			local is_weapon_cast, _ = string.find(spell_type, "weapon", 1, true)
+			is_weapon_cast = is_weapon_cast or false
+
+			if is_local then
+				if char_ext and char_ext.state and char_ext.state.current_state then
+					local char_state = char_ext.state.current_state
+
+					if char_state == "casting" then
+						return
+					end
+					if char_state == "inair" and (spell_type == "forward") then
+						return
+					end
+					if char_state == "channeling" and (spell_type == "forward" or spell_type == "magick" or spell_type == "self" or is_weapon_cast) then
+						return
+					end
+				end
+			else
+				if char_ext and char_ext.internal and char_ext.internal.last_anim_event then
+					local anim = char_ext.internal.last_anim_event
+					local was_idle, _ = string.find(anim, "idle", 1, true)
+					local was_moving, _ = string.find(anim, "run_", 1, true)
+					local was_aoe, _ = string.find(anim, "cast_area_", 1, true)
+					local was_forward_channel, _ = string.find(anim, "cast_force_beam", 1, true)
+					local was_self_channel, _ = string.find(anim, "cast_self_channeling", 1, true)
+					local was_magick, _ = string.find(anim, "cast_magick_", 1, true)
+
+					if not was_idle and not was_moving then
+						if was_aoe or was_magick then
+							return
+						end
+						if was_forward_channel and (spell_type == "forward" or spell_type == "magick" or spell_type == "self" or is_weapon_cast) then
+							return
+						end
+					end
+				end
+			end
+		end
+	end
 
 	if player_ext and input.element_queue then
 		local input_ext = EntityAux.extension(unit, "input_controller")
@@ -586,14 +675,20 @@ function SpellCastingSystem:_handle_spellcast(unit, input, internal, is_local, s
 			if magick_from_elements and controller_type == "keyboard" or controller_type ~= "keyboard" and input.spell_type == "weapon_imbue" and not magicks_cast_cooldown then
 				local magick_name, magick_tier = _magick_from_elements(input.element_queue)
 
-				if magick_name then
-					local apply_magick_cooldown = SpellSettings.elemental_magicks_cooldown
-					local hud_magicks = self.hud_manager:get_hud_magicks(unit)
-					local char_state = EntityAux.state(unit, "character")
-					local can_cast_magick = hud_magicks:has_magick(magick_name)
+				-- fun-balance :: magick cds
+				if not magicks_cast_cooldown and funprove_enabled and spellwheel_ext.internal.magick_cds then
+					magicks_cast_cooldown = spellwheel_ext.internal.magick_cds[magick_name]
+				end
+
+				if not magicks_cast_cooldown then
+					local kmf_magic = kmf.get_custom_magics(input.element_queue)
 
-					if can_cast_magick and apply_magick_cooldown and hud_magicks:is_magick_button_enabled(magick_tier) or can_cast_magick and not apply_magick_cooldown and EntityAux.state(unit, "character").current_state == "onground" and not hud_magicks:is_tier_force_disabled(magick_tier) then
-						EntityAux.set_input(unit, "magick_user", "activate_magick_by_name", magick_name)
+					if kmf_magic then
+						local magick_instance = kmf.setup_custom_magic_instance(kmf_magic, spell_context, unit)
+
+						if magick_instance and magick_instance.execute then
+							magick_instance:execute()
+						end
 
 						input.spell_type = nil
 						input.magick = nil
@@ -604,9 +699,40 @@ function SpellCastingSystem:_handle_spellcast(unit, input, internal, is_local, s
 						input.scale_damage = nil
 						magick_casted = true
 
-						self.statistics_keeper:add_magick_telemetry(unit, magick_name, "element_combo")
+						if unit then
+							local spellwheel_ext = EntityAux.extension(unit, "spellwheel")
+
+							if spellwheel_ext then
+								EntityAux.set_input_by_extension(spellwheel_ext, "magick_cast", true)
+								EntityAux.set_input_by_extension(spellwheel_ext, "magick_cast_name", magick_name)
+								EntityAux.set_input_by_extension(spellwheel_ext, "magick_from_elements", true)
+							end
+						end
 					else
-						cat_print("SpellCastingSystem", "Magick:", magick_name, "is locked or Tier:", magick_tier, "is not available.")
+						if magick_name then
+							local apply_magick_cooldown = SpellSettings.elemental_magicks_cooldown
+							local hud_magicks = self.hud_manager:get_hud_magicks(unit)
+							local char_state = EntityAux.state(unit, "character")
+							local can_cast_magick = hud_magicks:has_magick(magick_name)
+
+							if (can_cast_magick and apply_magick_cooldown and hud_magicks:is_magick_button_enabled(magick_tier)) or (can_cast_magick and not apply_magick_cooldown and EntityAux.state(unit, "character").current_state == "onground" and not hud_magicks:is_tier_force_disabled(magick_tier)) then
+								EntityAux.set_input(unit, "magick_user", "activate_magick_by_name", magick_name)
+								EntityAux.set_input_by_extension(spellwheel_ext, "magick_from_elements", true)
+
+								input.spell_type = nil
+								input.magick = nil
+								input.elements = nil
+								input.element_queue = nil
+								input.num_elements = nil
+								input.target_position = nil
+								input.scale_damage = nil
+								magick_casted = true
+
+								self.statistics_keeper:add_magick_telemetry(unit, magick_name, "element_combo")
+							else
+								cat_print("SpellCastingSystem", "Magick:", magick_name, "is locked or Tier:", magick_tier, "is not available.")
+							end
+						end
 					end
 				end
 			end
@@ -699,6 +825,7 @@ function SpellCastingSystem:_handle_spellcast(unit, input, internal, is_local, s
 	local current_imbued_spell_should_stop = was_weapon_cast and _csn and _csn ~= "Slash" or false
 	local weapon_unit
 
+
 	if was_weapon_cast and spell_context.is_standalone then
 		spell_context.weapon_unit = nil
 		spell_name = SpellTypes[spell_type](spell_context)
@@ -856,6 +983,28 @@ function SpellCastingSystem:_handle_spellcast(unit, input, internal, is_local, s
 		spell_context.spell_damage_replacer = spell_damage_replacer
 	end
 
+	local kmf_unique_id
+	local kmf_owner_peer
+
+	if funprove_enabled then
+		if is_local then
+			if spell_name == "Fissure" then
+				kmf.vars.my_fissure_instance_id = (kmf.vars.my_fissure_instance_id or 0) + 1
+				kmf.vars.my_fissure_instance_id = (kmf.vars.my_fissure_instance_id > 100) and 1 or kmf.vars.my_fissure_instance_id
+				kmf_unique_id = kmf.vars.my_fissure_instance_id
+			end
+		elseif kmf_received_unique_id and kmf_received_owner_peer then
+			kmf_unique_id = kmf_received_unique_id
+			kmf_owner_peer = kmf_received_owner_peer
+		end
+	end
+
+	if kmf_unique_id then
+		spell_context.kmf_unique_id = kmf_unique_id
+		spell_context.kmf_owner_peer = kmf_owner_peer
+		kmf_print("[unique id] spell cast :: " .. tostring(spell_name) .. "    # " .. tostring(spell_context.kmf_unique_id))
+	end
+
 	local spell_data, skip_waiting = S[spell_name].init(spell_context, spell_type)
 
 	if spell_data then
@@ -890,6 +1039,11 @@ function SpellCastingSystem:_handle_spellcast(unit, input, internal, is_local, s
 		elseif spell_context.scale_damage then
 			self.network_transport:send_cast_spell_scaled(unit, spell_type, magick, element_queue, target, input.magick_activate_position, spell_context.scale_damage, rand_seed)
 		else
+			if kmf_unique_id then
+				rand_seed = kmf_unique_id
+				kmf_print("[unique id] spell send :: " .. tostring(spell_type) .. "    # " .. tostring(rand_seed))
+			end
+
 			self.network_transport:send_cast_spell(unit, spell_type, magick, element_queue, target, input.magick_activate_position, rand_seed)
 		end
 
@@ -902,7 +1056,7 @@ function SpellCastingSystem:_handle_spellcast(unit, input, internal, is_local, s
 		end
 	end
 
-	if is_local and EntityAux.extension(unit, "player") then
+	if is_local and player_ext then
 		if spell_type == "magick" then
 			self.statistics_keeper:add_magick_telemetry(unit, magick, "quick_slot")
 		else
@@ -938,7 +1092,7 @@ function SpellCastingSystem:_handle_spellcast(unit, input, internal, is_local, s
 			end
 		end
 
-		if not spam_protect then
+		if not spam_protect and (not fix_enabled or (spell_name and spell_data)) then
 			internal._waiting_spell.name = spell_name
 			internal._waiting_spell.data = spell_data
 		end
@@ -958,6 +1112,19 @@ function SpellCastingSystem:add_to_active_spells(internal, spell_name, spell_dat
 		spell_table.on_cast(spell_data, spell_context)
 	end
 
+	if kmf.vars.bugfix_enabled then
+		local time = kmf.world_proxy:time()
+		local diff = spell_data.kmf_spell_init_data_time
+
+		diff = diff and diff or time
+		diff = time - diff
+
+		if diff > 0.450 then
+			kmf_print("cannot add spell, cuz its stale (1) [" .. diff .. "] :: " .. spell_name)
+			return
+		end
+	end
+
 	spells[#spells + 1] = spell_name
 
 	assert(spell_data, "Error: Received no spell_data")
@@ -978,10 +1145,41 @@ function SpellCastingSystem:on_cast_spell(unit)
 			return
 		end
 
+		-- fun-balance :: optional additional delay before casting a waiting spell
+		local time = kmf.world_proxy:time()
+
+		if kmf.vars.funprove_enabled and ws.data.kmf_time_to_cast then
+			local time = kmf.world_proxy:time()
+			local cast_time = ws.data.kmf_spell_init_data_time or 0
+
+			if time - cast_time < ws.data.kmf_time_to_cast then
+				kmf.vars.waiting_spells[unit] = true
+
+				return
+			else
+				kmf.vars.waiting_spells[unit] = nil
+			end
+		end
+
 		local ws_name = ws.name
 		local spells = internal.spells
 		local spells_data = internal.spells_data
 
+		if kmf.vars.bugfix_enabled then
+			local diff = ws.data.kmf_spell_init_data_time
+
+			diff = diff and diff or time
+			diff = time - diff
+
+			if diff > 0.450 then
+				kmf_print("cannot add spell, cuz its stale (2) [" .. diff .. "] :: " .. ws.name)
+				ws.name = nil
+				ws.data = nil
+
+				return
+			end
+		end
+
 		spells[#spells + 1] = ws.name
 		spells_data[#spells_data + 1] = ws.data
 
@@ -1012,8 +1210,23 @@ function SpellCastingSystem:on_cast_spell(unit)
 	end
 end
 
+kmf.reorder_spell_data = function(internal)
+	local sorted_spells = {}
+	for _, v in pairs(internal.spells) do
+		sorted_spells[#sorted_spells + 1] = v
+	end
+	internal.spells = sorted_spells
+
+	local sorted_spells_data = {}
+	for _, v in pairs(internal.spells_data) do
+		sorted_spells_data[#sorted_spells_data + 1] = v
+	end
+	internal.spells_data = sorted_spells_data
+end
+
 function SpellCastingSystem:update_spellcast_units(entities, entities_n, spell_update_context, dt)
 	local SpellTypes = Spells
+	local fix_enabled = kmf.vars.bugfix_enabled
 
 	for n = 1, entities_n do
 		repeat
@@ -1025,6 +1238,21 @@ function SpellCastingSystem:update_spellcast_units(entities, entities_n, spell_u
 			local channel_dur = internal.channel_duration
 			local input_channel = input.channel
 			local state = extension.state
+			local splwhl_ext = EntityAux.extension(u, "spellwheel")
+
+			if kmf.vars.bugfix_enabled or kmf.vars.pvp_gamemode then
+				local player_ext = EntityAux.extension(u, "player")
+
+				if player_ext then
+					if kmf.is_player_unit_dead(u) then
+						break
+					end
+				end
+			end
+
+			if fix_enabled then
+				kmf.reorder_spell_data(internal)
+			end
 
 			if input.cancel_armor_component then
 				local element = input.cancel_armor_component
@@ -1033,12 +1261,14 @@ function SpellCastingSystem:update_spellcast_units(entities, entities_n, spell_u
 
 				local did_something = false
 
+				local elem_is_shield = element == "shield"
+
 				for i, spell in ipairs(internal.spells) do
 					local data = internal.spells_data[i]
 
 					assert(data, "SpellcastingSystem recieved 'cancel_armor_component' (" .. element .. ") but were missing spelldata for spell '" .. spell .. "' no spell_data !")
 
-					if spell == "ArmorWard" then
+					if spell == "ArmorWard" and not elem_is_shield then
 						local spell_on_cancel_func = SpellTypes[spell].on_cancel_one
 
 						if spell_on_cancel_func then
@@ -1051,6 +1281,10 @@ function SpellCastingSystem:update_spellcast_units(entities, entities_n, spell_u
 
 						red_text("Warning: SpellcastingSystem recieved 'cancel_armor_component' (" .. element .. ") and had '" .. spell .. "' active but it had no 'on_cancel_one'-func")
 
+						break
+					elseif kmf.vars.funprove_enabled and elem_is_shield and spell == "SelfShield" then
+						SpellTypes[spell].on_cancel(data, self.spell_update_context, true)
+						did_something = true
 						break
 					end
 				end
@@ -1061,7 +1295,7 @@ function SpellCastingSystem:update_spellcast_units(entities, entities_n, spell_u
 			end
 
 			if input.remove_imbuement then
-				input.remove_imbuement, input.remove_from_imbuement = nil
+				input.remove_imbuement, input.remove_from_imbuement = nil, nil
 
 				if internal.current_imbued_spell then
 					EntityAux.stop_effect(internal.current_imbued_spell.caster, "charged_weapon")
@@ -1112,7 +1346,9 @@ function SpellCastingSystem:update_spellcast_units(entities, entities_n, spell_u
 			end
 
 			if internal.overload then
-				internal.overload:update(dt)
+				pcall(function()
+					internal.overload:update(dt)
+				end)
 
 				state.overload = internal.overload.overload
 				state.max_overload = internal.overload.max_overload
@@ -1130,6 +1366,20 @@ function SpellCastingSystem:update_spellcast_units(entities, entities_n, spell_u
 
 			local char_ext_state = char_ext and char_ext.state or nil
 
+			if splwhl_ext then
+				if char_ext and fix_enabled then
+					if char_ext.input and char_ext.input.kmf_aoe_lightning then
+						input.spell_type = ""
+						input.anti_spam = true
+						EntityAux.set_input_by_extension(splwhl_ext, "kmf_aoe_fix_dont_skip_elements", true)
+					else
+						EntityAux.set_input_by_extension(splwhl_ext, "kmf_aoe_fix_dont_skip_elements", false)
+					end
+				else
+					EntityAux.set_input_by_extension(splwhl_ext, "kmf_aoe_fix_dont_skip_elements", false)
+				end
+			end
+
 			if char_ext_state then
 				spell_update_context.target = char_ext_state.cursor_intersect_unit
 			end
@@ -1158,7 +1408,10 @@ function SpellCastingSystem:update_spellcast_units(entities, entities_n, spell_u
 						break
 					end
 
-					local val = current_spelltype.update(data, spell_update_context)
+					local val
+					pcall(function()
+						val = current_spelltype.update(data, spell_update_context)
+					end)
 
 					if val then
 						spells[j] = spell
@@ -1188,7 +1441,7 @@ function SpellCastingSystem:update_spellcast_units(entities, entities_n, spell_u
 				if ws_name then
 					local spell_table = Spells[ws_name]
 
-					if spell_table.waiting_spell_update then
+					if spell_table.waiting_spell_update and ws_data.kmf_status ~= 0 then
 						local keep = spell_table.waiting_spell_update(ws_data, spell_update_context)
 
 						if not channeling and ws_data.needs_channel and input.chargeup_ended then
@@ -1244,6 +1497,7 @@ function SpellCastingSystem:update_spellcast_units(entities, entities_n, spell_u
 				input.clear_overload = nil
 			end
 
+
 			if input.spell_type ~= nil and input.spell_type ~= "" then
 				if #internal.spells ~= 0 then
 					local _curr_imbue_spell = internal.current_imbued_spell and internal.current_imbued_spell.spell_name or nil
@@ -1282,6 +1536,10 @@ function SpellCastingSystem:update_spellcast_units(entities, entities_n, spell_u
 end
 
 function SpellCastingSystem:update(context)
+	for unit, _ in pairs(kmf.vars.waiting_spells) do
+		self:on_cast_spell(unit)
+	end
+
 	local dt = context.dt
 	local spell_update_context = self.spell_update_context
 
@@ -1508,6 +1766,10 @@ function SpellCastingSystem:cancel_magick(unit, magick_name, ext, spell_update_c
 end
 
 function SpellCastingSystem:cancel_all_spells(unit, ext, cancel_magicks)
+	if not unit then
+		return
+	end
+
 	local SpellTypes = Spells
 
 	ext = ext or EntityAux.extension(unit, "spellcast")
@@ -1527,6 +1789,10 @@ function SpellCastingSystem:cancel_all_spells(unit, ext, cancel_magicks)
 	local char_ext_state = char_ext and char_ext.state or nil
 	local num_spells = #spells
 
+	for _, handler_func in pairs(kmf.vars.on_cancel_all_spells_handlers) do
+		handler_func(unit, ext)
+	end
+
 	for i = 1, num_spells do
 		repeat
 			local spell = spells[i]
@@ -1669,6 +1935,9 @@ function SpellCastingSystem:create_damages_and_particles(sender, target_unit_id,
 
 	local world = self.world_proxy
 
+	local particles = NetworkLookup.particles[particles_id]
+	local sfx = NetworkLookup.sfx[sfx_id]
+
 	if target_unit then
 		local _damages = FrameTable.alloc_table()
 
@@ -1680,15 +1949,15 @@ function SpellCastingSystem:create_damages_and_particles(sender, target_unit_id,
 			caster_unit
 		}, _damages, "force")
 
-		if particles_id then
-			world:create_particles(NetworkLookup.particles[particles_id], Unit.world_position(target_unit, 0))
+		if particles then
+			world:create_particles(particles, Unit.world_position(target_unit, 0))
 		end
-	elseif target_position and particles_id then
-		world:create_particles(NetworkLookup.particles[particles_id], target_position)
+	elseif target_position and particles then
+		world:create_particles(particles, target_position)
 	end
 
-	if sfx_id then
-		world:trigger_timpani_event(NetworkLookup.sfx[sfx_id], caster_unit)
+	if sfx then
+		world:trigger_timpani_event(sfx, caster_unit)
 	end
 end
 
