diff --git a/scripts/game/entity_system/systems/player/magicks_system.lua b/scripts/game/entity_system/systems/player/magicks_system.lua
index 920a63c..79151b2 100644
--- a/scripts/game/entity_system/systems/player/magicks_system.lua
+++ b/scripts/game/entity_system/systems/player/magicks_system.lua
@@ -205,6 +205,7 @@ function MagicksSystem:on_add_extension(u, extension_name, init_data, net_init_d
 		assert(net_init_data)
 		assert(net_init_data.local_player_id)
 		assert(net_init_data.global_player_id)
+
 		self.hud_manager:add_player_hud(u, internal.magicks, extension, false, net_init_data.local_player_id, net_init_data.global_player_id)
 	end
 
@@ -416,8 +417,10 @@ function MagicksSystem:update(context)
 					elseif activate_magick_index or activate_magick_by_name then
 						local magick
 						local apply_cooldown = true
+						local magick_casted_from_hud = false
 
 						if activate_magick_index then
+							magick_casted_from_hud = true
 							magick = internal_magicks[activate_magick_index]
 						elseif activate_magick_by_name then
 							for index, M in ipairs(self.all_available_magicks) do
@@ -503,7 +506,8 @@ function MagicksSystem:update(context)
 										}
 									end
 								elseif apply_cooldown then
-									if magick.focus_regain then
+									-- fun-balance :: magick cds
+									if magick.focus_regain and not kmf.vars.funprove_enabled then
 										self:set_focus(ext, magick.tier, magick.focus_regain)
 									else
 										self:decrease_focus(magick.tier, internal_magicks, ext, u)
@@ -515,6 +519,8 @@ function MagicksSystem:update(context)
 
 							assert(spellwheel_ext, "Missing spellwheel ext when casting a magick: " .. tostring(magick.name) .. " Unit: " .. tostring(u))
 							EntityAux.set_input_by_extension(spellwheel_ext, "magick_cast", true)
+							EntityAux.set_input_by_extension(spellwheel_ext, "magick_cast_name", magick.name)
+							EntityAux.set_input_by_extension(spellwheel_ext, "magick_from_elements", not magick_casted_from_hud)
 
 							local char_ext = EntityAux.extension(u, "character")
 
@@ -771,7 +777,7 @@ function MagicksSystem:decrease_focus(used_tier, internal_magicks, ext, unit)
 
 			if magick_data.tier == ext.hidden_pending_magick_index and magick_data.cast_type ~= "normal" then
 				ext.hidden_pending_magick_index, ext.hidden_pending_magick = ext.pending_magick_index, ext.pending_magick
-				ext.pending_magick_index, ext.pending_magick, ext.magick_clears_spellwheel = nil
+				ext.pending_magick_index, ext.pending_magick, ext.magick_clears_spellwheel = nil, nil, nil
 			end
 		end
 	end
@@ -818,6 +824,11 @@ function MagicksSystem:increase_focus(ext, internal_magicks, dt, unit)
 
 	local default_focus_mult = self.player_variable_manager:get_variable(unit, "focus_regen_multiplier")
 	local artifact_mod = ArtifactManager:get_modifier_value("WFRegen") or 1
+	local tiered_magicks = {}
+
+	for _, magick_data in ipairs(internal_magicks) do
+		tiered_magicks[magick_data.tier] = magick_data
+	end
 
 	for i = 1, self.num_tiers do
 		local current_tier_focus = ext.current_tier_focuses[i]
@@ -831,7 +842,17 @@ function MagicksSystem:increase_focus(ext, internal_magicks, dt, unit)
 
 			local num_alive_players = self:get_num_alive_player()
 
-			current_tier_focus = current_tier_focus + dt * SpellSettings.focus_regeneration(i, num_alive_players) * artifact_mod * this_tier_focus_mult
+			-- fun-balance :: magick cds
+			local base_regen_rate
+			local magick_data = tiered_magicks[i]
+
+			if kmf.vars.funprove_enabled and magick_data then
+				base_regen_rate = SpellSettings.max_focus / (MagicksSettings[magick_data.name] and MagicksSettings[magick_data.name].cooldown or 15)
+			else
+				base_regen_rate = SpellSettings.focus_regeneration(i, num_alive_players)
+			end
+
+			current_tier_focus = current_tier_focus + dt * base_regen_rate * artifact_mod * this_tier_focus_mult
 			current_tier_focus = math.clamp(current_tier_focus, 0, max_focus)
 			current_tier_focuses[i] = current_tier_focus
 		else
@@ -847,7 +868,7 @@ function MagicksSystem:increase_focus(ext, internal_magicks, dt, unit)
 
 			if magick_data.tier == ext.hidden_pending_magick_index and magick_data.cast_type ~= "normal" then
 				ext.pending_magick_index, ext.pending_magick = ext.hidden_pending_magick_index, ext.hidden_pending_magick
-				ext.hidden_pending_magick_index, ext.hidden_pending_magick, ext.magick_clears_spellwheel = nil
+				ext.hidden_pending_magick_index, ext.hidden_pending_magick, ext.magick_clears_spellwheel = nil, nil, nil
 			end
 		end
 	end
