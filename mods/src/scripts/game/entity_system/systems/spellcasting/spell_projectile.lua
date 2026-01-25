diff --git a/scripts/game/entity_system/systems/spellcasting/spell_projectile.lua b/scripts/game/entity_system/systems/spellcasting/spell_projectile.lua
index e917c12..eeb3b4c 100644
--- a/scripts/game/entity_system/systems/spellcasting/spell_projectile.lua
+++ b/scripts/game/entity_system/systems/spellcasting/spell_projectile.lua
@@ -55,7 +55,8 @@ Spells_Projectile = {
 			is_standalone = context.is_standalone,
 			standalone_data = context.standalone_data,
 			spell_source = context.spell_source,
-			rand_seed = _rand_seed
+			rand_seed = _rand_seed,
+			effect_type = Spells_Projectile.get_effect_type(context.elements)
 		}
 
 		if projectile_type == "self" then
@@ -70,6 +71,33 @@ Spells_Projectile = {
 
 			if not data.is_standalone then
 				EntityAux.set_input_by_extension(data.char_ext, "next_animation", "cast_self")
+
+				-- fun-balance :: nerf casting animation of self ice shards
+				if kmf.vars.funprove_enabled and data.elements.ice > 0 then
+					kmf.task_scheduler.add(function()
+						if caster and Unit.alive(caster) then
+							local char_ext = EntityAux.extension(caster, "character")
+
+							if char_ext and char_ext.state and char_ext.state.current_state and char_ext.state.current_state == "inair" then
+								return
+							end
+
+							EntityAux.set_input_by_extension(char_ext, CSME.spell_channel, true)
+							EntityAux.set_input_by_extension(char_ext, CSME.spell_cast, false)
+							EntityAux.set_input_by_extension(char_ext, "args", "cast_area_lightning")
+							EntityAux.set_input(caster, "locomotion", "disable_movement", true)
+							EntityAux.set_input(caster, "locomotion", "disabled", true)
+
+							kmf.task_scheduler.add(function()
+								if caster and Unit.alive(caster) then
+									EntityAux.set_input_by_extension(char_ext, CSME.spell_channel, false)
+									EntityAux.set_input(caster, "locomotion", "disable_movement", false)
+									EntityAux.set_input(caster, "locomotion", "disabled", "cleared")
+								end
+							end, 750)
+						end
+					end)
+				end
 			end
 
 			return data, true
@@ -105,6 +133,15 @@ Spells_Projectile = {
 			return data, skip_waiting
 		end
 	end,
+	get_effect_type = function(elements)
+		if elements.earth > 0 and elements.ice == 0 then
+			return "earth_projectile"
+		elseif elements.ice > 0 then
+			return "ice_projectiles"
+		else
+			assert(false, "Invalid projectile-spell.")
+		end
+	end,
 	waiting_spell_update = function(data, context)
 		local status_ext = EntityAux.extension(context.caster, "status")
 
@@ -118,6 +155,8 @@ Spells_Projectile = {
 			data.standalone_dt = (data.standalone_dt or 0) + context.dt
 
 			local standalone_done = data.standalone_dt >= data.standalone_data.duration
+			-- bugfix :: for prism timer bug
+			standalone_done = data.standalone_dt >= (SpellSettings.magick_force_prism_time_between_casts - 0.2)
 
 			if standalone_done then
 				data.standalone_dt = 0
@@ -133,7 +172,7 @@ Spells_Projectile = {
 						position = info.node_position
 					end
 
-					local effect_type
+					local effect_type = data.effect_type
 					local scale = data.standalone_data.duration
 					local elements = data.elements
 
@@ -150,14 +189,6 @@ Spells_Projectile = {
 						position = position + direction * 2 + Vector3.up()
 					end
 
-					if elements.earth > 0 and elements.ice == 0 then
-						effect_type = "earth_projectile"
-					elseif elements.ice > 0 then
-						effect_type = "ice_projectiles"
-					else
-						assert(false, "Invalid projectile-spell.")
-					end
-
 					if data.show_charge_effect then
 						data.has_stopped_charge_effect = true
 
@@ -175,7 +206,8 @@ Spells_Projectile = {
 
 		return true
 	end,
-	update = function(data, context)
+	update = function (data, context)
+		local fix_enabled = kmf.vars.bugfix_enabled
 		if not context.spell_channel then
 			if context.is_local then
 				local caster = data.caster
@@ -202,7 +234,9 @@ Spells_Projectile = {
 					EntityAux.set_input_by_extension(data.char_ext, CSME.spell_charge, nil)
 				end
 
-				if elements.earth > 0 and elements.ice == 0 then
+				local is_pure_rock = elements.steam == 0 and elements.arcane == 0 and elements.cold == 0 and elements.poison == 0 and elements.lightning == 0 and elements.life == 0 and elements.lok == 0 and elements.water == 0 and elements.fire == 0 and elements.shield == 0
+
+				if data.effect_type == "earth_projectile" then
 					if data.projectile_type == "self" then
 						position = position + Vector3.up() * 10
 						scale = 0
@@ -214,9 +248,27 @@ Spells_Projectile = {
 
 							position = (info.node_position or position) + direction
 						elseif elements.ice > 0 then
-							position = position + direction + direction * (elements.ice + 1) * 0.17 + Vector3.up()
+							if fix_enabled then
+								position = position + Vector3.up() + direction * 0.1
+							else
+								position = position + direction + direction * (elements.ice + 1) * 0.17 + Vector3.up()
+							end
 						else
-							position = position + direction + direction * elements.earth * 0.17 + Vector3.up()
+							if fix_enabled then
+								if kmf.vars.funprove_enabled and not is_pure_rock then
+									local norm_dir = Vector3.normalize(direction)
+
+									kmf.vars.my_elem_rock_id = (kmf.vars.my_elem_rock_id or 0) + 1
+									kmf.vars.my_elem_rock_id = (kmf.vars.my_elem_rock_id > 100) and 0 or kmf.vars.my_elem_rock_id
+									data.rand_seed = kmf.vars.my_elem_rock_id  -- this is the unique id of a elem rock
+
+									position = position + Vector3.up() + norm_dir * 1.5 + norm_dir * elements.earth * 0.19
+								else
+									position = position + Vector3.up() + direction * 0.1
+								end
+							else
+								position = position + direction + direction * elements.earth * 0.17 + Vector3.up()
+							end
 						end
 					end
 
