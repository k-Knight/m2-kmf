diff --git a/scripts/game/entity_system/systems/character/character_state_base.lua b/scripts/game/entity_system/systems/character/character_state_base.lua
index e8cac73..f47d6f5 100644
--- a/scripts/game/entity_system/systems/character/character_state_base.lua
+++ b/scripts/game/entity_system/systems/character/character_state_base.lua
@@ -188,6 +188,69 @@ function CharacterStateBase:handle_spellwheel_input(unit, input_data, internal,
 
 	local sw_ext = internal.spellwheel_ext
 
+	if kmf.vars.input_queue_enabled then
+		local os_time = os.clock()
+
+		if not input_data.kmf_input_times then
+			input_data.kmf_input_times = {}
+			input_data.kmf_input_times.self = 0
+			input_data.kmf_input_times.area = 0
+			input_data.kmf_input_times.forward = 0
+			input_data.kmf_input_times.weapon_imbue = 0
+			input_data.kmf_input_times.weapon = 0
+		end
+
+		local kmf_input_pressed = input_data.spell_self or input_data.spell_aoe or input_data.spell_forward or input_data.imbue_weapon or input_data.melee_attack
+		local kmf_last_cast
+		local kmf_last_time = 0
+
+		if not kmf_input_pressed then
+			local max_dt
+
+			if kmf_last_time < input_data.kmf_input_times.self then
+				kmf_last_time = input_data.kmf_input_times.self
+				kmf_last_cast = "spell_self"
+				max_dt = 0.33
+			end
+			if kmf_last_time < input_data.kmf_input_times.area then
+				kmf_last_time = input_data.kmf_input_times.area
+				kmf_last_cast = "spell_aoe"
+				max_dt = 0.25
+			end
+			if kmf_last_time < input_data.kmf_input_times.forward then
+				kmf_last_time = input_data.kmf_input_times.forward
+				kmf_last_cast = "spell_forward"
+				max_dt = 0.25
+			end
+			if kmf_last_time < input_data.kmf_input_times.weapon_imbue then
+				kmf_last_time = input_data.kmf_input_times.weapon_imbue
+				kmf_last_cast = "imbue_weapon"
+				max_dt = 0.25
+			end
+			if kmf_last_time < input_data.kmf_input_times.weapon then
+				kmf_last_time = input_data.kmf_input_times.weapon
+				kmf_last_cast = "melee_attack"
+				max_dt = 0.25
+			end
+
+			if kmf_last_cast and (os_time - kmf_last_time) < max_dt then
+				if kmf_last_cast == "imbue_weapon" and (os_time - input_data.kmf_input_times.weapon) < 0.25 then
+					input_data.melee_attack = true
+				elseif kmf_last_cast == "melee_attack" and (os_time - input_data.kmf_input_times.weapon_imbue) < 0.25 then
+					input_data.imbue_weapon = true
+				end
+
+				input_data[kmf_last_cast] = true
+			end
+		else
+			input_data.kmf_input_times.self = input_data.spell_self and os_time or input_data.kmf_input_times.self
+			input_data.kmf_input_times.area = input_data.spell_aoe and os_time or input_data.kmf_input_times.area
+			input_data.kmf_input_times.forward = input_data.spell_forward and os_time or input_data.kmf_input_times.forward
+			input_data.kmf_input_times.weapon_imbue = input_data.imbue_weapon and os_time or input_data.kmf_input_times.weapon_imbue
+			input_data.kmf_input_times.weapon = input_data.melee_attack and os_time or input_data.kmf_input_times.weapon
+		end
+	end
+
 	if input_data.spell_magick == true then
 		if spellcast_input_restrictions.cast_magick then
 			input_data.spell_magick = nil
@@ -261,6 +324,12 @@ function CharacterStateBase:handle_spellwheel_input(unit, input_data, internal,
 				local valid_magick, valid_tier = _magick_from_elements(sw_ext.internal.element_queue.element_queue)
 				local spellwheel_ext = EntityAux.extension(unit, "spellwheel")
 				local magicks_cast_cooldown = spellwheel_ext.internal.magicks_cast_cooldown
+
+				-- fun-balance :: magick cds
+				if not magicks_cast_cooldown and kmf.vars.funprove_enabled and spellwheel_ext.internal.magick_cds then
+					magicks_cast_cooldown = spellwheel_ext.internal.magick_cds[valid_magick]
+				end
+
 				local char_ext = EntityAux_extension(unit, "character")
 				local can_cast_magick
 
