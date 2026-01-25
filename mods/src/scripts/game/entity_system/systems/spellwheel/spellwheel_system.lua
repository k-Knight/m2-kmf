diff --git a/scripts/game/entity_system/systems/spellwheel/spellwheel_system.lua b/scripts/game/entity_system/systems/spellwheel/spellwheel_system.lua
index ea1f0a4..5a46785 100644
--- a/scripts/game/entity_system/systems/spellwheel/spellwheel_system.lua
+++ b/scripts/game/entity_system/systems/spellwheel/spellwheel_system.lua
@@ -57,8 +57,7 @@ SpellWheelAux = SpellWheelAux or {
 }
 DEFAULT_ELEMENT_DISABLE_EARMARK = "flow"
 SpellWheelSystem = class(SpellWheelSystem, EntitySystemBase)
-
-local DisabledSpelltypes = {
+SpellWheelSystem.DisabledSpelltypes = {
 	weapon = false,
 	self = false,
 	area = false,
@@ -121,7 +120,7 @@ end
 function SpellWheelSystem:is_spelltype_enabled(spelltype)
 	local cast_type = type(spelltype) == "string" and spelltype or NetworkLookup.cast_types[spelltype]
 
-	if DisabledSpelltypes[cast_type] ~= nil and DisabledSpelltypes[cast_type] == true then
+	if SpellWheelSystem.DisabledSpelltypes[cast_type] ~= nil and SpellWheelSystem.DisabledSpelltypes[cast_type] == true then
 		return false
 	end
 
@@ -132,29 +131,29 @@ function SpellWheelSystem:disable_spelltype(spelltype)
 	local cast_type = type(spelltype) == "string" and spelltype or NetworkLookup.cast_types[spelltype]
 
 	assert(cast_type, "Unknown cast type: " .. tostring(spelltype))
-	assert(DisabledSpelltypes[cast_type] ~= nil, "Spelltype can't be disabled: " .. tostring(cast_type))
+	assert(SpellWheelSystem.DisabledSpelltypes[cast_type] ~= nil, "Spelltype can't be disabled: " .. tostring(cast_type))
 
-	DisabledSpelltypes[cast_type] = true
+	SpellWheelSystem.DisabledSpelltypes[cast_type] = true
 end
 
 function SpellWheelSystem:enable_spelltype(spelltype)
 	local cast_type = type(spelltype) == "string" and spelltype or NetworkLookup.cast_types[spelltype]
 
 	assert(cast_type, "Unknown cast type: " .. tostring(spelltype))
-	assert(DisabledSpelltypes[cast_type] ~= nil, "Spelltype can't be enabled: " .. tostring(cast_type))
+	assert(SpellWheelSystem.DisabledSpelltypes[cast_type] ~= nil, "Spelltype can't be enabled: " .. tostring(cast_type))
 
-	DisabledSpelltypes[cast_type] = false
+	SpellWheelSystem.DisabledSpelltypes[cast_type] = false
 end
 
 function SpellWheelSystem:disable_all_spelltypes()
-	for type, _ in pairs(DisabledSpelltypes) do
-		DisabledSpelltypes[type] = true
+	for type, _ in pairs(SpellWheelSystem.DisabledSpelltypes) do
+		SpellWheelSystem.DisabledSpelltypes[type] = true
 	end
 end
 
 function SpellWheelSystem:enable_all_spelltypes()
-	for type, _ in pairs(DisabledSpelltypes) do
-		DisabledSpelltypes[type] = false
+	for type, _ in pairs(SpellWheelSystem.DisabledSpelltypes) do
+		SpellWheelSystem.DisabledSpelltypes[type] = false
 	end
 end
 
@@ -184,7 +183,7 @@ function SpellWheelSystem:enable_element(unit, elem, earmark)
 			for _, _ in pairs(ext.disabled_elements[earmark]) do
 				remove = false
 
-				break
+				return
 			end
 
 			if remove then
@@ -198,7 +197,7 @@ function SpellWheelSystem:enable_element(unit, elem, earmark)
 					if element_list[elem] == true then
 						still_disabled = true
 
-						break
+						return
 					end
 				end
 
@@ -492,210 +491,423 @@ function SpellWheelSystem:game_object_sync_done(peer)
 	end
 end
 
-function SpellWheelSystem:update(context)
-	local entities, entities_n = self:get_entities("spellwheel")
-	local dt = context.dt
-	local pvm = self.player_variable_manager
+function SpellWheelSystem:sws_entity_update(extension_data, dt, pvm)
 	local EntityAux_set_input = EntityAux.set_input
-	local get_input_direction = input_direction_as_stringtable
-	local directions = {}
 	local all_elements = AllElements
 	local all_elements_n = #AllElements
 	local network = self.network_transport
 
-	for i = 1, entities_n do
-		repeat
-			local extension_data = entities[i]
-			local u, extension = extension_data.unit, extension_data.extension
-			local internal = extension.internal
-			local input = extension.input
-			local input_data = input.input_data or input
-			local reset_input = false
-			local input_data = input.input_data
-
-			if input_data == nil then
-				input_data = input
-				reset_input = true
-			else
-				input.input_data = nil
-			end
+	local u = extension_data.unit
+	local player_ext = EntityAux.extension(u, "player")
+	local extension = extension_data.extension
+	local internal = extension.internal
+	local input = extension.input
+	local input_data = input.input_data or input
+	local reset_input = false
+	local input_data = input.input_data
+	local fix_enabled = kmf.vars.bugfix_enabled
+	--local player_peer = player_ext and player_ext.owner_peer_id or nil
+
+	if input_data == nil then
+		input_data = input
+		reset_input = true
+	else
+		input.input_data = nil
+	end
 
-			local element_queue = internal.element_queue
-			local last_elements = internal.last_elements
+	local element_queue = internal.element_queue
+	local last_elements = internal.last_elements
 
-			if input.magick_cast then
-				internal.magicks_cast_cooldown = SpellSettings.elemental_magicks_cast_cooldown_time
-				input.magick_cast = nil
-			end
+	if player_ext then
+		local default_focus_mult = self.player_variable_manager:get_variable(u, "focus_regen_multiplier") or 1.0
+		local delta = (dt * default_focus_mult)
 
-			local imcc = internal.magicks_cast_cooldown
+		if not internal.magick_cds then
+			internal.magick_cds = {}
+		end
 
-			if imcc then
-				imcc = imcc - dt
+		for k, v in pairs(internal.magick_cds) do
+			v = v - delta
+			internal.magick_cds[k] = (v > 0) and v or nil
+		end
+	end
 
-				if imcc < 0 then
-					imcc = nil
-				end
+	if input.magick_cast then
+		local cd = SpellSettings.elemental_magicks_cast_cooldown_time
 
-				internal.magicks_cast_cooldown = imcc
-			end
+		-- fun-balance :: magick cds
+		if kmf.vars.funprove_enabled then
+			cd = cd / 2
+		end
+
+		if player_ext then
+			input.magick_cast_name = input.magick_cast_name or "unknown"
+			local cd = kmf.const.magicks_cooldown[input.magick_cast_name] or 1.5
+
+			internal.magick_cds[input.magick_cast_name] = cd
 
-			local icc = internal.cast_cooldown
+			local magick_user_ext = EntityAux.extension(u, "magick_user")
+			if magick_user_ext and kmf.vars.funprove_enabled then
+				local internal_magicks = magick_user_ext.internal.magicks
 
-			if icc then
-				icc = icc - dt
+				local ext = magick_user_ext
+				local used_tier = MagicksSettings[input.magick_cast_name] and MagicksSettings[input.magick_cast_name].tier or nil
+				local do_decrese_focus = false
 
-				if icc < 0 then
-					icc = nil
+				for _, magick_data in ipairs(internal_magicks) do
+					if magick_data.tier == used_tier and magick_data.name == input.magick_cast_name then
+						do_decrese_focus = true
+						break
+					end
 				end
 
-				internal.cast_cooldown = icc
-			end
+				if do_decrese_focus and internal_magicks and ext and used_tier then
+					ext.current_tier_focuses[used_tier] = 0
+					ext.input.current_tier_focuses = table.clone(ext.current_tier_focuses)
 
-			for elem, _ in pairs(internal.element_cooldowns) do
-				internal.element_cooldowns[elem] = internal.element_cooldowns[elem] - dt
+					for _, magick_data in ipairs(internal_magicks) do
+						local should_disable = magick_data.tier == used_tier
 
-				if internal.element_cooldowns[elem] <= 0 then
-					self.event_delegate:trigger("send_enable_element", u, elem, "artifact_cd")
+						if should_disable and magick_data.available then
+							magick_data.available = false
 
-					internal.element_cooldowns[elem] = nil
+							if magick_data.tier == ext.hidden_pending_magick_index and magick_data.cast_type ~= "normal" then
+								ext.hidden_pending_magick_index, ext.hidden_pending_magick = ext.pending_magick_index, ext.pending_magick
+								ext.pending_magick_index, ext.pending_magick, ext.magick_clears_spellwheel = nil, nil, nil
+							end
+						end
+					end
+
+					ext.input.force_visual_focus_percentage = {}
+					for i, focus in ipairs(ext.current_tier_focuses) do
+						ext.input.force_visual_focus_percentage[i] = focus / SpellSettings.max_focus
+					end
+					ext.input.dirty_flag = true
 				end
 			end
+		end
 
-			if input.dirty_flag and input.disabled ~= nil then
-				internal.disabled = input.disabled
+		internal.magicks_cast_cooldown = cd
 
-				if internal.disabled then
-					element_queue.element_um:clear()
-				end
+		kmf.on_magick_cooldown_update(u, extension)
+		input.magick_cast = nil
+	end
 
-				input.disabled = nil
-			end
+	local imcc = internal.magicks_cast_cooldown
 
-			if internal.disabled then
-				break
-			end
+	if imcc then
+		imcc = imcc - dt
 
-			if not input.dirty_flag then
-				element_queue:update(dt, extension.state)
+		if imcc < 0 then
+			imcc = nil
+		end
 
-				for k, v in pairs(last_elements) do
-					last_elements[k] = nil
-				end
+		internal.magicks_cast_cooldown = imcc
+	end
 
-				break
-			end
+	local icc = internal.cast_cooldown
 
-			if input.clear_spellwheel then
-				network:transmit_all(u, "clear_element_queue")
+	if icc then
+		icc = icc - dt
 
-				input.clear_spellwheel = nil
-			end
+		if icc < 0 then
+			icc = nil
+		end
 
-			input.dirty_flag = false
+		internal.cast_cooldown = icc
+	end
 
-			local state = extension.state
-			local new_elements = FrameTable.alloc_table()
-			local disabled_elements = state.disabled_elements
+	for elem, _ in pairs(internal.element_cooldowns) do
+		internal.element_cooldowns[elem] = internal.element_cooldowns[elem] - dt
 
-			for j = 1, all_elements_n do
-				local elem = all_elements[j]
+		if internal.element_cooldowns[elem] <= 0 then
+			self.event_delegate:trigger("send_enable_element", u, elem, "artifact_cd")
 
-				if input_data[elem] and not SpellWheelAux.element_disabled(disabled_elements, elem, true) then
-					new_elements[elem] = true
+			internal.element_cooldowns[elem] = nil
+		end
+	end
 
-					network:transmit_all(u, "queue_element", NetworkLookup.elements[elem])
-				end
+	if input.dirty_flag and input.disabled ~= nil then
+		internal.disabled = input.disabled
+
+		if internal.disabled then
+			element_queue.element_um:clear()
+		end
+
+		input.disabled = nil
+	end
+
+	if internal.disabled then
+		return
+	end
+
+	if not input.dirty_flag then
+		element_queue:update(dt, extension.state)
+
+		for k, v in pairs(last_elements) do
+			last_elements[k] = nil
+		end
+	else
+		if input.clear_spellwheel then
+			network:transmit_all(u, "clear_element_queue")
+
+			input.clear_spellwheel = nil
+		end
+
+		input.dirty_flag = false
+		local state = extension.state
+		local new_elements = FrameTable.alloc_table()
+		local disabled_elements = state.disabled_elements
+
+		local elem_str = ""
+
+		for j = 1, all_elements_n, 1 do
+			local elem = all_elements[j]
+			local elem_letter = nil
+
+			if elem == "water" then
+				elem_letter = "q"
+			elseif elem == "life" then
+				elem_letter = "w"
+			elseif elem == "shield" then
+				elem_letter = "e"
+			elseif elem == "cold" then
+				elem_letter = "r"
+			elseif elem == "lightning" then
+				elem_letter = "a"
+			elseif elem == "arcane" then
+				elem_letter = "s"
+			elseif elem == "earth" then
+				elem_letter = "d"
+			elseif elem == "fire" then
+				elem_letter = "f"
 			end
 
-			for k, _ in pairs(last_elements) do
-				last_elements[k] = nil
+			if elem_letter and input_data[elem] and not SpellWheelAux.element_disabled(disabled_elements, elem, true) then
+				elem_str = elem_str .. elem_letter
 			end
+		end
 
-			for k, v in pairs(new_elements) do
-				last_elements[k] = v
+		if elem_str and #elem_str > 0 then
+			local ordered = kmf.kbd_watcher_order_inputs_by_time(elem_str)
+
+			for i = 1, #ordered do
+				local c = ordered:sub(i,i)
+				local elem = nil
+
+				if c == "q" then
+					elem = "water"
+				elseif c == "w" then
+					elem = "life"
+				elseif c == "e" then
+					elem = "shield"
+				elseif c == "r" then
+					elem = "cold"
+				elseif c == "a" then
+					elem = "lightning"
+				elseif c == "s" then
+					elem = "arcane"
+				elseif c == "d" then
+					elem = "earth"
+				elseif c == "f" then
+					elem = "fire"
+				end
+
+				if elem then
+					new_elements[elem] = true
+					network:transmit_all(u, "queue_element", NetworkLookup.elements[elem])
+				end
 			end
+		end
 
-			local spell_cast = input_data.spell_cast
-			local disabled_check = spell_cast
+		for k, _ in pairs(last_elements) do
+			last_elements[k] = nil
+		end
 
-			if spell_cast == "magick_from_elements" then
-				disabled_check = "magick"
+		for k, v in pairs(new_elements) do
+			last_elements[k] = v
+		end
+
+		local spell_cast = input_data.spell_cast
+		local disabled_check = spell_cast
+
+		if spell_cast and fix_enabled then
+			local is_weapon_cast, _ = string.find(spell_cast, "weapon", 1, true)
+			is_weapon_cast = is_weapon_cast or false
+
+			local char_ext = EntityAux.extension(u, "character")
+			local spam_prevent = false
+
+			if char_ext and char_ext.state and char_ext.state.current_state then
+				local char_state = char_ext.state.current_state
+
+				if char_state == "casting" then
+					spam_prevent = true
+				end
+				if char_state == "inair" and (spell_cast == "forward") then
+					spam_prevent = true
+				end
+				if char_state == "channeling" and (spell_cast == "forward" or spell_cast == "magick" or spell_cast == "self" or is_weapon_cast) then
+					spam_prevent = true
+				end
+			elseif char_ext and char_ext.internal and char_ext.internal.last_anim_event then
+				local anim = char_ext.internal.last_anim_event
+
+				local was_idle, kmf_tag_end = string.find(anim, "idle", 1, true)
+				local was_moving, kmf_tag_end = string.find(anim, "run_", 1, true)
+				local was_aoe, kmf_tag_end = string.find(anim, "cast_area_", 1, true)
+				local was_forward_channel, kmf_tag_end = string.find(anim, "cast_force_beam", 1, true)
+				local was_self_channel, kmf_tag_end = string.find(anim, "cast_self_channeling", 1, true)
+				local was_magick, kmf_tag_end = string.find(anim, "cast_magick_", 1, true)
+
+				if not was_idle and not was_moving then
+					if was_aoe or was_magick then
+						spam_prevent = true
+					elseif was_forward_channel and (spell_cast == "forward" or spell_cast == "magick" or spell_cast == "self" or is_weapon_cast) then
+						spam_prevent = true
+					end
+				end
 			end
 
-			if spell_cast and DisabledSpelltypes[disabled_check] then
+			if spam_prevent then
 				spell_cast = nil
 				input_data.spell_cast = nil
+				return
 			end
+		end
 
-			if spell_cast == "magick_from_elements" and imcc then
-				spell_cast = nil
+		if spell_cast == "magick_from_elements" then
+			disabled_check = "magick"
+		end
+
+		if spell_cast and SpellWheelSystem.DisabledSpelltypes[disabled_check] then
+			spell_cast = nil
+			input_data.spell_cast = nil
+		end
+
+		if spell_cast == "magick_from_elements" and imcc then
+			spell_cast = nil
+			input_data.spell_cast = nil
+		end
+
+		local input_controller = EntityAux.extension(u, "input_controller")
+		local is_controller = false
+		local controller_type = nil
+		if input_controller then
+			controller_type = input_controller.state.controller
+		end
+		if controller_type then
+			is_controller = controller_type ~= "keyboard"
+		end
+
+		if spell_cast == "magick_from_elements" and not imcc then
+			local selected_elements, num_elements, is_illegal = element_queue:get_elements(spell_cast, is_controller)
+			if is_illegal then
 				input_data.spell_cast = nil
+				network:transmit_all(u, "clear_element_queue")
+				return
 			end
 
-			if spell_cast == "magick_from_elements" and not imcc then
-				local selected_elements, num_elements = element_queue:get_elements()
+			if num_elements == 0 then
+				input_data.spell_cast = nil
 
-				if num_elements == 0 then
-					input_data.spell_cast = nil
+				return
+			end
 
-					return
+			local element_queue_raw = element_queue:get_element_queue()
+			local spellcast_input = {
+				spell_type = spell_cast,
+				elements = selected_elements,
+				num_elements = num_elements,
+				element_queue = element_queue_raw
+			}
+
+			if input_data.kmf_input_times then
+				input_data.kmf_input_times[spell_cast] = 0
+
+				if spell_cast == "weapon" then
+					input_data.kmf_input_times.weapon_imbue = 0
+				elseif spell_cast == "weapon_imbue" then
+					input_data.kmf_input_times.weapon = 0
 				end
+			end
 
-				local element_queue_raw = element_queue:get_element_queue()
-				local spellcast_input = {
-					spell_type = spell_cast,
-					elements = selected_elements,
-					num_elements = num_elements,
-					element_queue = element_queue_raw
-				}
+			EntityAux_set_input(u, "spellcast", spellcast_input)
 
-				EntityAux_set_input(u, "spellcast", spellcast_input)
+			input_data.spell_cast = nil
+		elseif spell_cast and spell_cast ~= "magick_from_elements" and not icc then
+			local selected_elements, num_elements, is_illegal = element_queue:get_elements(spell_cast, is_controller)
+			if is_illegal then
+				input_data.spell_cast = nil
+				network:transmit_all(u, "clear_element_queue")
+				return
+			end
 
+			local element_queue_raw = element_queue:get_element_queue()
+
+			if num_elements == 0 and spell_cast ~= "weapon" then
 				input_data.spell_cast = nil
-			elseif spell_cast and spell_cast ~= "magick_from_elements" and not icc then
-				local selected_elements, num_elements = element_queue:get_elements()
-				local element_queue_raw = element_queue:get_element_queue()
 
-				if num_elements == 0 and spell_cast ~= "weapon" then
-					input_data.spell_cast = nil
+				return
+			end
 
+			if spell_cast ~= "weapon" then
+				if fix_enabled and spell_cast == "area" and input.kmf_aoe_fix_dont_skip_elements then
+					input_data.spell_cast = nil
 					return
 				end
+				network:transmit_all(u, "clear_element_queue")
+			end
 
-				if spell_cast ~= "weapon" then
-					network:transmit_all(u, "clear_element_queue")
-				end
+			local spellcast_input = {
+				spell_type = spell_cast,
+				elements = selected_elements,
+				num_elements = num_elements,
+				element_queue = element_queue_raw
+			}
 
-				local spellcast_input = {
-					spell_type = spell_cast,
-					elements = selected_elements,
-					num_elements = num_elements,
-					element_queue = element_queue_raw
-				}
 
-				EntityAux_set_input(u, "spellcast", spellcast_input)
+			if input_data.kmf_input_times then
+				input_data.kmf_input_times[spell_cast] = 0
 
-				input_data.spell_cast = nil
-				internal.cast_cooldown = SpellSettings.cast_cooldown * pvm:get_variable(u, "cast_cooldown")
+				if spell_cast == "weapon" then
+					input_data.kmf_input_times.weapon_imbue = 0
+				elseif spell_cast == "weapon_imbue" then
+					input_data.kmf_input_times.weapon = 0
+				end
 			end
 
-			element_queue:update(dt, extension.state)
-
-			if reset_input then
-				input.life = false
-				input.poison = false
-				input.water = false
-				input.arcane = false
-				input.cold = false
-				input.lightning = false
-				input.fire = false
-				input.shield = false
-				input.earth = false
-				input.ice = false
-				input.steam = false
-			end
-		until true
+			EntityAux_set_input(u, "spellcast", spellcast_input)
+
+			input_data.spell_cast = nil
+			internal.cast_cooldown = SpellSettings.cast_cooldown * pvm:get_variable(u, "cast_cooldown")
+		end
+
+		element_queue:update(dt, extension.state)
+
+		if reset_input then
+			input.life = false
+			input.poison = false
+			input.water = false
+			input.arcane = false
+			input.cold = false
+			input.lightning = false
+			input.fire = false
+			input.shield = false
+			input.earth = false
+			input.ice = false
+			input.steam = false
+		end
+	end
+end
+
+SpellWheelSystem.update = function (self, context)
+	local entities, entities_n = self:get_entities("spellwheel")
+	local dt = context.dt
+	local pvm = self.player_variable_manager
+
+	for i = 1, entities_n, 1 do
+		self:sws_entity_update(entities[i], dt, pvm)
 	end
 
 	entities, entities_n = self:get_entities("spellwheel_husk")
