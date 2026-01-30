diff --git a/scripts/game/entity_system/systems/spellcasting/spell_ward.lua b/scripts/game/entity_system/systems/spellcasting/spell_ward.lua
index 8e1d276..b71dc79 100644
--- a/scripts/game/entity_system/systems/spellcasting/spell_ward.lua
+++ b/scripts/game/entity_system/systems/spellcasting/spell_ward.lua
@@ -22,71 +22,116 @@ res_buff_lookup = {
 	steam = "steam_immunity"
 }
 
+-- fun-balance :: ward buff
 local function resistance_effect_extract_data(elements, resistance_mul)
 	local num_types = 0
 	local wanted_elements = {}
 	local types = {}
 	local resistances = {}
 	local largest = -1
-	local largest_element
+	local largest_element = nil
 	local magnitude = 0
 
+	local life_ward_res_elems = {
+		"arcane",
+		"cold",
+		"fire",
+		"lightning",
+		"steam",
+		"poison",
+		"water",
+		"water_push",
+		"water_elevate",
+	}
+
+	local funprove_enabled = kmf.vars.funprove_enabled
+
 	for elem, amt in pairs(elements) do
 		if amt > 0 and elem ~= "shield" and elem ~= "earth" and elem ~= "ice" then
 			magnitude = magnitude + amt
-
 			local res = 0
 
+			if funprove_enabled and elem == "water" and amt then
+				local index = #resistances + 1
+				local mult = 1.0 / (amt / 2 + 1.25)
+
+				resistances[index] = {
+					"water_push",
+					"mul",
+					mult
+				}
+				index = #resistances + 1
+				resistances[index] = {
+					"water_elevate",
+					"mul",
+					mult
+				}
+			end
+
 			if amt == 1 then
-				res = resistance_1_element
+				res = funprove_enabled and 0.6 or SpellSettings.ward_resistance_1_elements
 			end
 
 			if amt == 2 then
-				res = resistance_2_element
+				res = funprove_enabled and 1.0 or SpellSettings.ward_resistance_2_elements
 			end
 
 			if amt == 3 then
-				res = resistance_3_element
+				res = funprove_enabled and 1.5 or SpellSettings.ward_resistance_3_elements
 			end
 
 			if amt == 4 then
-				res = resistance_4_element
+				res = funprove_enabled and 2.5 or SpellSettings.ward_resistance_4_elements
 
 				if elem == "water" then
 					local index = #resistances + 1
-
-					resistances[index] = {}
-					resistances[index][1] = "water_push"
-					resistances[index][2] = "mul"
-					resistances[index][3] = 0
+					resistances[index] = {
+						"water_push",
+						"mul",
+						0
+					}
 					index = #resistances + 1
-					resistances[index] = {}
-					resistances[index][1] = "water_elevate"
-					resistances[index][2] = "mul"
-					resistances[index][3] = 0
+					resistances[index] = {
+						"water_elevate",
+						"mul",
+						0
+					}
 				end
 			end
 
-			res = res * resistance_mul
-			res = 1 - res
-
-			local index = #resistances + 1
-
-			resistances[index] = {}
-			resistances[index][1] = elem
-			resistances[index][2] = "mul"
-			resistances[index][3] = res
-
-			if DEBUG_RESISTANCE then
-				yellow_text("Resistance val for " .. elem .. " is " .. tostring(res))
-
-				if res == 0 then
-					yellow_text("Should be IMMUNE")
-				elseif res < 0 then
-					yellow_text("Should be HEALED by " .. elem)
+			if funprove_enabled and elem == "life" then
+				res = 0.125
+				res = amt == 2 and 0.25 or res
+				res = amt == 3 and 0.375 or res
+				res = amt == 4 and 0.501 or res
+
+				for _, elem in ipairs(life_ward_res_elems) do
+					local final_res = res * resistance_mul
+					final_res = 1 - final_res
+
+					resistances[#resistances + 1] = {
+						elem,
+						"mul",
+						final_res
+					}
+
+					if final_res <= 0.5 then
+						num_types = num_types + 1
+						types[num_types] = elem
+					end
 				end
+
+				res = math.min(res * 3, 1)
 			end
 
+			res = res * resistance_mul
+			res = 1 - res
+			resistances[#resistances + 1] = {
+				elem,
+				"mul",
+				res
+			}
+
 			if res <= 0.5 then
 				num_types = num_types + 1
 				types[num_types] = elem
@@ -101,10 +146,6 @@ local function resistance_effect_extract_data(elements, resistance_mul)
 		end
 	end
 
-	if DEBUG_RESISTANCE then
-		yellow_text("Resistance magnitude = " .. tostring(magnitude) .. ", largest_element = " .. largest_element)
-	end
-
 	if num_types == 0 then
 		types = nil
 	end
@@ -180,8 +221,10 @@ Spells_Ward = {
 		end
 
 		if context.is_local then
-			EntityAux_set_input(caster, "character", CSME.spell_cast, true)
-			EntityAux_set_input(caster, "character", "args", "cast_force_shield")
+			if not kmf.vars.funprove_enabled then
+				EntityAux_set_input(caster, "character", CSME.spell_cast, true)
+				EntityAux_set_input(caster, "character", "args", "cast_force_shield")
+			end
 
 			if types ~= nil then
 				local buffs = context.state.buffs
@@ -198,6 +241,16 @@ Spells_Ward = {
 			end
 		end
 
+		local status, err = pcall(function()
+			if kmf.vars.experimental_balance then
+				data.kmf_aura_effect = KMFAuraEffect(context, duration)
+			end
+		end)
+
+		if not status then
+			kmf_print("KMFAuraEffect.init() failed :: " .. tostring(err))
+		end
+
 		return data
 	end,
 	update = function(data, context)
@@ -223,6 +276,17 @@ Spells_Ward = {
 
 		data.duration = dur
 
+		local status, err = pcall(function()
+			if data.kmf_aura_effect then
+				data.kmf_aura_effect:update(context)
+			end
+		end)
+
+		if not status then
+			kmf_print("KMFAuraEffect.update() failed :: " .. tostring(err))
+		end
+
+
 		return true
 	end,
 	on_cancel = function(data, context)
@@ -253,5 +317,365 @@ Spells_Ward = {
 			context.network:send_stop_elemental_ward_effect(caster, "resistance_effect")
 			EntityAux.stop_effect(caster, "resistance_effect")
 		end
+
+		local status, err = pcall(function()
+			if data.kmf_aura_effect then
+				data.kmf_aura_effect:stop(context)
+			end
+		end)
+
+		if not status then
+			kmf_print("KMFAuraEffect.stop() failed :: " .. tostring(err))
+		end
 	end
 }
+
+KMFAuraEffect = class(KMFAuraEffect)
+
+function KMFAuraEffect:init(context, duration)
+	self.caster = context.caster
+	self.world = context.world
+	self.unit_spawner = context.unit_spawner
+	self.max_duration = duration
+
+	if not (self.unit_spawner and self.world and self.caster and Unit.alive(self.caster)) then
+		return
+	end
+
+	local elements = context.elements
+	local aura_element
+	local aura_element_count = 2
+
+	for element, count in pairs(elements) do
+		if count > aura_element_count then
+			aura_element_count = count
+			aura_element = element
+		end
+	end
+
+	if not aura_element then
+		return
+	end
+
+	local color = SpellSettings.invulnerability[aura_element]
+	color = color and color.color or nil
+
+	if not color then
+		return
+	end
+
+	color = Vector3.unbox(color)
+	self.color = Vector3.box({}, color)
+
+	if aura_element == "shield" then
+		aura_element = "lok"
+	end
+
+	local position = Unit.world_position(self.caster, 0) + Vector3(0, 0, 0.1)
+	self.element = aura_element
+	self.is_life_aura = aura_element == "life"
+	self.strength = aura_element_count - 2
+	self.scale = (self.strength + 1) * 5.0
+	self._duration = 0
+	self.dmg_interval = 0.5
+	self.next_dmg_t = self.dmg_interval
+
+	self.aura_unit = kmf.unit_spawner:spawn_unit_local(GameSettings.move_to_unit, position, Quaternion.identity())
+
+	local u_mesh = Unit.mesh(self.aura_unit, "g_body")
+	local u_material = Mesh.material(u_mesh, 0)
+
+	if self.is_life_aura then
+		Material.set_vector3(u_material, "color_tint", Vector3(0, 0, 0))
+		Material.set_vector3(u_material, "scale", Vector3(0.1, 0.1, 2))
+		Material.set_texture(u_material, "\xb5\xce\x3d\xd0\x83\x1b\x92\xa8", "\xa0\x3b\xa0\x1c\xe4\x57\x4a\x60")
+	else
+		Material.set_vector3(u_material, "color_tint", color / 3)
+		Material.set_vector3(u_material, "scale", Vector3(self.scale, self.scale, 2))
+		Material.set_texture(u_material, "\xb5\xce\x3d\xd0\x83\x1b\x92\xa8", "\x5c\x81\xb4\x17\x5c\xbe\xb2\xbd")
+	end
+
+	self.aura_pusle_unit = kmf.unit_spawner:spawn_unit_local(GameSettings.move_to_unit, position, Quaternion.identity())
+
+	u_mesh = Unit.mesh(self.aura_pusle_unit, "g_body")
+	u_material = Mesh.material(u_mesh, 0)
+	Material.set_vector3(u_material, "color_tint", Vector3(0, 0, 0))
+	Material.set_vector3(u_material, "scale", Vector3(0.1, 0.1, 2))
+	Material.set_texture(u_material, "\xb5\xce\x3d\xd0\x83\x1b\x92\xa8", "\xa0\x3b\xa0\x1c\xe4\x57\x4a\x60")
+
+	local fake_elements = {}
+	fake_elements[aura_element] = self.strength
+	local pvm = context.player_variable_manager
+	local damages, magnitudes = SpellSettings:get_aoe_damage(pvm, self.caster, fake_elements)
+	local dmg_mult = 0.715
+
+	for k, v in pairs(magnitudes) do
+		magnitudes[k] = v / self.dmg_interval
+	end
+
+	if aura_element == "water" then
+		self.water_status_interval = self.dmg_interval
+		self.next_water_status_t = self.water_status_interval
+		self.dmg_interval = -1
+
+		damages.water_push = (damages.water_push * 1.5) / 2.0
+		damages.push = damages.water_push
+
+		damages.water_elevate = 500
+		damages.elevate = damages.water_elevate
+	else
+		for k, v in pairs(damages) do
+			damages[k] = v * self.dmg_interval * dmg_mult
+		end
+	end
+
+	if self.is_life_aura then
+		damages.pure = -damages.life * 0.6125
+		damages.life = nil
+	end
+
+	self.default_focus_mult = pvm:get_variable(self.caster, "focus_regen_multiplier")
+	self.damages = damages
+	self.magnitudes = magnitudes
+	self._initialized = true
+
+	if kmf.effect_manager then
+		local sound_pos_offset = Vector3(0, 0, -25)
+		local sfx_name
+
+		if aura_element == "water" then
+			sfx_name = "play_spell_beam_water_addon"
+			sound_pos_offset = Vector3(0, 0, -26)
+		elseif aura_element == "fire" then
+			sfx_name = "play_spell_beam_fire_addon"
+		elseif aura_element == "cold" then
+			sfx_name = "play_spell_beam_cold_addon"
+		elseif aura_element == "lightning" then
+			sfx_name = "play_spell_beam_lightning_addon"
+			sound_pos_offset = Vector3(0, 0, -26)
+		elseif aura_element == "steam" then
+			sfx_name = "play_spell_beam_steam_addon"
+		elseif aura_element == "poison" then
+			sfx_name = "play_spell_beam_poison_addon"
+		elseif aura_element == "life" then
+			sfx_name = "play_spell_beam_life_loop"
+			sound_pos_offset = Vector3(0, 0, -26)
+		else
+			sfx_name = "play_spell_beam_arcane_loop"
+		end
+
+		self.sound_pos_offset = Vector3.box({}, sound_pos_offset)
+		self.dummy_sound_unit = kmf.unit_spawner:spawn_unit_local("content/units/effects/misc/beam_dummy", position + sound_pos_offset, Quaternion.identity())
+		self.sound_id = kmf.effect_manager:play_sound(sfx_name, self.dummy_sound_unit)
+	end
+end
+
+function KMFAuraEffect:update(context)
+	if not self._initialized then
+		return
+	end
+
+	self._duration = self._duration + context.dt
+
+	if kmf.is_unit_dead(self.caster) or self.max_duration <= self._duration then
+		self:stop(context)
+		return
+	end
+
+	local angle, dir, aura_rot
+	local position = Unit.world_position(self.caster, 0) + Vector3(0, 0, 0.1)
+	local t_left = self.max_duration - self._duration
+	local max_opaque = math.floor(t_left * 8) % 2 == 0
+	local dmg_radius = self.scale / 2.1
+
+	if self.dummy_sound_unit then
+		Unit.teleport_local_position(self.dummy_sound_unit, 0, position + Vector3.unbox(self.sound_pos_offset))
+	end
+
+	if self.is_life_aura then
+		angle = (self._duration - 0.67) * 1 * math.pi
+		dir = Vector3(math.cos(angle), math.sin(angle), 0)
+		aura_rot = Quaternion.look(dir)
+
+		local spellwheel_ext = EntityAux.extension(self.caster, "spellwheel")
+
+		if spellwheel_ext and spellwheel_ext.internal then
+			local delta = context.dt * self.default_focus_mult * 0.25 * self.strength
+
+			if not spellwheel_ext.internal.magick_cds then
+				spellwheel_ext.internal.magick_cds = {}
+			end
+
+			for k, v in pairs(spellwheel_ext.internal.magick_cds) do
+				v = v - delta
+				spellwheel_ext.internal.magick_cds[k] = (v > 0) and v or nil
+			end
+		end
+	else
+		angle = self._duration * 0.1 * math.pi
+		dir = Vector3(math.cos(angle), math.sin(angle), 0)
+		aura_rot = Quaternion.look(dir)
+	end
+	
+	angle = self._duration * 1 * math.pi
+	dir = Vector3(math.cos(angle), math.sin(angle), 0)
+	local aura_pulse_rot = Quaternion.look(dir)
+
+	if position and self._duration > self.next_dmg_t then
+		self.next_dmg_t = self.next_dmg_t + self.dmg_interval
+		local do_apply_status = false
+
+		if self.water_status_interval then
+			if self._duration > self.next_water_status_t then
+				self.next_water_status_t =  self.next_water_status_t + self.water_status_interval
+				do_apply_status = true
+			end
+		else
+			do_apply_status = true
+		end
+
+		local callback = function(actors)
+			if not Unit.alive(self.caster) then
+				return
+			end
+
+			local victims = {}
+
+			for i, a in ipairs(actors) do
+				local unit = Actor.unit(a)
+
+				if Unit.alive(unit) and unit ~= self.caster then
+					if not victims[unit] then
+						local damage_receiver = EntityAux.extension(unit, "damage_receiver")
+						local status_ext = EntityAux.extension(unit, "status")
+						local victim_pos = Unit.world_position(unit, 0)
+	
+						if damage_receiver then
+							victims[unit] = true
+
+							if self.dmg_interval < 0 then
+								local damages = {}
+								local water_force_strength = (1 - (Vector3.length(victim_pos - position) / dmg_radius)) * 2.0
+								
+								for k, v in pairs(self.damages) do
+									damages[k] = v * context.dt * water_force_strength
+								end
+
+								EntityAux.add_damage(unit, { self.caster }, damages, "aura", nil, position)
+							else
+								EntityAux.add_damage(unit, { self.caster }, self.damages, "aura", nil, position)
+							end
+	
+							if do_apply_status and status_ext then
+								EntityAux.add_status_magnitude_by_extension(status_ext, self.magnitudes, self.caster)
+							end
+						end
+					end
+				end
+			end
+		end
+
+		if self.is_life_aura then
+			local damage_receiver = EntityAux.extension(self.caster, "damage_receiver")
+			local status_ext = EntityAux.extension(self.caster, "status")
+
+			if damage_receiver then
+				EntityAux.add_damage(self.caster, { self.caster }, self.damages, "aura", nil, position)
+			end
+
+			if status_ext then
+				EntityAux.add_status_magnitude_by_extension(status_ext, self.magnitudes, self.caster)
+			end
+		else
+			self.world:physics_overlap(callback, "shape", "sphere", "position", position, "size", dmg_radius, "types", "both", "collision_filter", "damage_query")
+		end
+	end
+
+	local pulse_freq = self.is_life_aura and 0.75 or 1.33
+	local pulse_time = self._duration * pulse_freq
+	local pulse_t = pulse_time - math.floor(pulse_time)
+	local orig_color = Vector3.unbox(self.color)
+
+	if self.is_life_aura then
+		pulse_t = 1 - pulse_t
+	end
+
+	local color = Vector3.lerp(orig_color, Vector3(0, 0, 0), self.is_life_aura and math.sqrt(pulse_t) or pulse_t * pulse_t)
+	local scale = pulse_t * self.scale * 1.2
+
+	if self.aura_unit and Unit.alive(self.aura_unit) then
+		Unit.teleport_local_rotation(self.aura_unit, 0, aura_rot)
+
+		if position then
+			Unit.teleport_local_position(self.aura_unit, 0, position)
+		end
+
+		if not self.is_life_aura then
+			local u_mesh = Unit.mesh(self.aura_unit, "g_body")
+			local u_material = Mesh.material(u_mesh, 0)
+			Material.set_vector3(u_material, "color_tint", orig_color / (not max_opaque and t_left < 3 and 6 or 3))
+		else
+			local pulse_time = (self._duration - (0.5 / pulse_freq)) * pulse_freq
+			local pulse_t = pulse_time - math.floor(pulse_time)
+
+			if self.is_life_aura then
+				pulse_t = 1 - pulse_t
+			end
+
+			local color = Vector3.lerp(orig_color, Vector3(0, 0, 0), self.is_life_aura and math.sqrt(pulse_t) or pulse_t * pulse_t)
+			local scale = pulse_t * self.scale * 1.2
+
+			if not max_opaque and t_left < 3 then
+				color = color / 3
+			end
+
+			local u_mesh = Unit.mesh(self.aura_unit, "g_body")
+			local u_material = Mesh.material(u_mesh, 0)
+			Material.set_vector3(u_material, "color_tint", color)
+			Material.set_vector3(u_material, "scale", Vector3(scale, scale, 2))
+		end
+	end
+
+	if self.aura_pusle_unit and Unit.alive(self.aura_pusle_unit) then
+		Unit.teleport_local_rotation(self.aura_pusle_unit, 0, aura_pulse_rot)
+
+		if position then
+			Unit.teleport_local_position(self.aura_pusle_unit, 0, position)
+		end
+
+		if scale and color then
+			if not max_opaque and t_left < 3 then
+				color = color / 3
+			end
+
+			local u_mesh = Unit.mesh(self.aura_pusle_unit, "g_body")
+			local u_material = Mesh.material(u_mesh, 0)
+			Material.set_vector3(u_material, "color_tint", color)
+			Material.set_vector3(u_material, "scale", Vector3(scale, scale, 2))
+		end
+	end
+end
+
+function KMFAuraEffect:stop(context)
+	if not self._initialized then
+		return
+	end
+
+	if self.sound_id then
+		local timpani_world = World.timpani_world(kmf.world_proxy._world)
+		timpani_world:stop(self.sound_id)
+		self.sound_id = nil
+
+		kmf.unit_spawner:mark_for_deletion(self.dummy_sound_unit)
+	end
+
+	if self.aura_unit and Unit.alive(self.aura_unit) then
+		kmf.unit_spawner:mark_for_deletion(self.aura_unit)
+	end
+
+	if self.aura_pusle_unit and Unit.alive(self.aura_pusle_unit) then
+		kmf.unit_spawner:mark_for_deletion(self.aura_pusle_unit)
+	end
+
+	self._initialized = false
+end
