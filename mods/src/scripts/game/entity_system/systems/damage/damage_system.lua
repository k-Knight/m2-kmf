diff --git a/scripts/game/entity_system/systems/damage/damage_system.lua b/scripts/game/entity_system/systems/damage/damage_system.lua
index 9e7b19f..87dbea9 100644
--- a/scripts/game/entity_system/systems/damage/damage_system.lua
+++ b/scripts/game/entity_system/systems/damage/damage_system.lua
@@ -113,6 +113,9 @@ function DamageSystem:sync_self_shield(sender, go_id, active)
 		damage_ext.locomotion_extension.state.is_self_shielded = active
 	else
 		damage_ext.state.selfshielded = active
+		if not damage_ext.state.selfshielded then
+			damage_ext.state.selfshielded_end = os.clock()
+		end
 	end
 
 	local character_ext = EntityAux.extension(u, "character")
@@ -186,18 +189,13 @@ function DamageSystem:update_damage_receivers()
 	local normalize = Vector3.normalize
 	local entities, entities_n = self:get_entities("damage_receiver")
 	local regain_focus_on_giving_melee = ArtifactManager:get_modifier_value("FRegenType") == 1
-
 	regain_focus_on_giving_melee = regain_focus_on_giving_melee and (SpellSettings.artifact_regen_on_giving_melee_damage or nil)
-
 	local regain_focus_on_giving_damage = ArtifactManager:get_modifier_value("FRegenType") == 2
-
 	regain_focus_on_giving_damage = regain_focus_on_giving_damage and (SpellSettings.artifact_regen_on_giving_damage or nil)
-
 	local regain_focus_on_taking_damage = ArtifactManager:get_modifier_value("FRegenType") == 3
-
 	regain_focus_on_taking_damage = regain_focus_on_taking_damage and (SpellSettings.artifact_regen_on_recieving_damage or nil)
-
 	local attacker_total_melee_damage_dealt
+	local fix_enabled = kmf.vars.bugfix_enabled
 
 	if regain_focus_on_giving_melee then
 		attacker_total_melee_damage_dealt = {}
@@ -238,6 +236,18 @@ function DamageSystem:update_damage_receivers()
 
 				input.dirty_flag = false
 
+				if fix_enabled then
+					local sorted_dmgs = {}
+
+					for k, v in pairs(input.damage) do
+						if v and v.damage then
+							sorted_dmgs[#sorted_dmgs + 1] = v
+						end
+					end
+
+					input.damage = sorted_dmgs
+				end
+
 				local inputdmg = input.damage
 				local damage_n = #inputdmg
 
@@ -277,13 +287,34 @@ function DamageSystem:update_damage_receivers()
 
 						inputdmg[damage_i] = nil
 
-						local medium = damage_data.medium
+						local medium
+						local secondary_medium
+
+						if type(damage_data.medium) == "table" then
+							medium = damage_data.medium[1]
+							secondary_medium = damage_data.medium[2]
+						else
+							medium = damage_data.medium
+						end
+
 						local impact_location = damage_data.impact_location
 						local damage_owner_name = damage_data.damage_owner_name
 						local num_attackers = damage_data.num_attackers
 						local attacker = damage_data[1]
 
 						last_attacker = attacker
+						local time = os.clock()
+
+						local assume_ice_armor = state.selfarmored_ice
+						local assume_earth_armor = state.selfarmored_earth
+						local assume_selfshielded = state.selfshielded
+						local virtual_shielding = fix_enabled and (not assume_ice_armor and not assume_earth_armor and not assume_selfshielded)
+
+						if state and fix_enabled then
+							assume_ice_armor = assume_ice_armor or ((time - (state.selfarmored_ice_end or 0)) < 0.05)
+							assume_earth_armor = assume_earth_armor or ((time - (state.selfarmored_earth_end or 0)) < 0.05)
+							assume_selfshielded = assume_selfshielded or ((time - (state.selfshielded_end or 0)) < 0.05)
+						end
 
 						if state.has_disruptor then
 							handle_disruptor_taking_damage(u, attacker, medium, damage_data.damage)
@@ -295,7 +326,7 @@ function DamageSystem:update_damage_receivers()
 							if medium == "physical" or medium == "melee" then
 								local character_extension = extension.character_extension
 
-								if character_extension and not state.selfarmored_earth and not state.selfarmored_ice then
+								if character_extension and not assume_earth_armor and not assume_ice_armor then
 									set_input_by_extension(character_extension, "took_phys_damage", true)
 								end
 							end
@@ -381,10 +412,70 @@ function DamageSystem:update_damage_receivers()
 									local redirected_armor_damages = false
 									local redirected_damages
 									local ignore_multipliers = damage_data.ignore_multipliers
+									local funprove_mod = 1.0
+									local funprove_mod_force = 1.0
+									local reverse_life_death = false
+									local is_barrier = false
+
+									-- fun-balance :: PvP and PvE damage multipliers
+									if kmf.vars.funprove_enabled then
+										if u then
+											is_barrier = Unit.get_data(u, "is_barrier")
+											local kmf_barrier_resist_arcane = Unit.get_data(u, "kmf_barrier_resist_arcane")
+
+											if is_barrier and kmf_barrier_resist_arcane then
+												reverse_life_death = true
+											end
+										end
+
+										if not ignore_multipliers and attacker and u then
+											local char1 = EntityAux.extension(u, "character")
+											local plyr1 = EntityAux.extension(u, "player")
+											local prism1 = EntityAux.extension(u, "prism")
+											local plyr2 = EntityAux.extension(attacker, "player")
+											local prism2 = EntityAux.extension(attacker, "prism")
+											local ice_tornado = Unit.get_data(attacker, "ice_tornado")
+
+											funprove_mod_force = 0.5
+
+											if char1 and char1.internal and char1.internal.kmf_push_elevate_resist then
+												funprove_mod_force = funprove_mod_force * char1.internal.kmf_push_elevate_resist
+											end
+
+											if (plyr1 or prism1) and (plyr2 or prism2) then
+												funprove_mod = 0.33
+											elseif plyr2 or prism2 then
+												funprove_mod = 0.5
+											elseif (plyr1 or prism1) and ice_tornado then
+												funprove_mod = 0.33
+												funprove_mod_force = funprove_mod_force / 1.5
+											end
+										end
+									end
 
 									for element, damage in pairs(damage_data.damage) do
+										local is_displacement_elem = element == "push" or element == "elevate" or element == "water_push" or element == "water_elevate"
+
+										if element == "poison" then
+											damage = damage * kmf.const.funbalance.poison_mult
+										end
+
+										if is_barrier and (element == "life" or element == "arcane") then
+											if reverse_life_death then
+												damage = -damage * 7.5
+											else
+												damage = -damage * 7.5
+											end
+										end
+
 										if not ignore_multipliers then
 											damage = damage * friendly_fire_damage_mod
+
+											if not is_displacement_elem then
+												damage = damage * funprove_mod
+											else
+												damage = damage * funprove_mod_force
+											end
 										end
 
 										local damage_redirected = false
@@ -396,7 +487,7 @@ function DamageSystem:update_damage_receivers()
 											end
 
 											if damage ~= 0 then
-												if state.selfshielded and DamageAux_selfshield_absorbs(element) then
+												if assume_selfshielded and DamageAux_selfshield_absorbs(element) then
 													redirected_selfshield_damages = true
 
 													if redirected_damages == nil then
@@ -412,7 +503,7 @@ function DamageSystem:update_damage_receivers()
 													damage = 0
 													damage_data.damage[element] = nil
 													damage_redirected = true
-												elseif (state.selfarmored_earth or state.selfarmored_ice) and (element == "earth" or element == "ice") then
+												elseif (assume_earth_armor or assume_ice_armor) and (element == "earth" or element == "ice") then
 													if redirected_damages == nil then
 														redirected_damages = {}
 													end
@@ -422,7 +513,7 @@ function DamageSystem:update_damage_receivers()
 													damage_data.damage[element] = nil
 													damage_redirected = true
 													redirected_armor_damages = true
-												elseif state.selfarmored_ice and (element == "fire" or element == "steam") then
+												elseif assume_ice_armor and (element == "fire" or element == "steam") then
 													if redirected_damages == nil then
 														redirected_damages = {}
 													end
@@ -433,6 +524,10 @@ function DamageSystem:update_damage_receivers()
 													redirected_armor_damages = true
 												end
 
+												if virtual_shielding then
+													redirected_damages = nil
+												end
+
 												if not damage_redirected then
 													damage_taken = true
 
@@ -492,6 +587,10 @@ function DamageSystem:update_damage_receivers()
 												new_dmg[4] = medium
 												new_dmg[7] = damage_owner_name
 
+												if secondary_medium then
+													new_dmg[55] = secondary_medium
+												end
+
 												if impact_location then
 													new_dmg[66] = impact_location
 												end
@@ -562,7 +661,7 @@ function DamageSystem:update_damage_receivers()
 										end
 									end
 
-									if state.selfshielded and redirected_selfshield_damages or (state.selfarmored_earth or state.selfarmored_ice) and redirected_armor_damages then
+									if (assume_selfshielded and redirected_selfshield_damages) or ((assume_earth_armor or assume_ice_armor) and redirected_armor_damages) then
 										local selfshield_ext = EntityAux_extension(u, "selfshield")
 
 										assert(selfshield_ext, "[DamageSystem] ignored damage due to state.selfshieleded, but unit has no selfshield-ext !")
