diff --git a/scripts/game/util/entity_aux_game.lua b/scripts/game/util/entity_aux_game.lua
index 34d7b97..150e30a 100644
--- a/scripts/game/util/entity_aux_game.lua
+++ b/scripts/game/util/entity_aux_game.lua
@@ -35,19 +35,24 @@ local function revert_rotation_speed(ext, smooth)
 end
 
 local function local_add_effect(u, effect_table)
-	assert(effect_table.effect_type, "Nil effect provided to add-effect.")
-
-	local input = local_extension(u, "effect_producer", true).input
-
-	input.dirty_flag = true
+	local ext = local_extension(u, "effect_producer", true)
+	if effect_table == nil or ext == nil or ext.input == nil then
+		return
+	end
 
-	local new_effects = input.new_effects
+	ext.input.dirty_flag = true
+	local new_effects = ext.input.new_effects
+	if new_effects == nil then
+		return
+	end
 
 	new_effects[#new_effects + 1] = effect_table
 end
 
 local function local_add_effect_by_extension(extension, effect_table)
-	assert(effect_table.effect_type, "Nil effect provided to add-effect.")
+	if effect_table == nil or ext == nil or ext.input == nil then
+		return
+	end
 
 	local input = extension.input
 
@@ -82,7 +87,7 @@ local temp_attack_id_table = {}
 local temp_damage_type_id_table = {}
 local temp_damage_amount_table = {}
 
-local function local_add_damage(u, attackers, damages, medium, scale_damage, impact_location, ignore_multipliers, damage_owner_name)
+local function _old_local_add_damage(u, attackers, damages, medium, scale_damage, impact_location, ignore_multipliers, damage_owner_name)
 	assert(attackers, "No attackers in add_damage")
 
 	local num_attackers = #attackers
@@ -143,6 +148,85 @@ local function local_add_damage(u, attackers, damages, medium, scale_damage, imp
 	end
 end
 
+local function local_add_damage(u, attackers, damages, medium, scale_damage, impact_location, ignore_multipliers, damage_owner_name, kmf_misc_data)
+	local damages_new = {}
+	local player_ext = EntityAux.extension(u, "player")
+
+	for k, v in pairs(damages) do
+		damages_new[k] = v
+	end
+
+	if kmf_misc_data and kmf.vars.bugfix_enabled then
+		local time =  kmf.world_proxy:time()
+
+		if kmf_misc_data.type == 1 then
+			local added = false
+
+			for grouping, hit_data in pairs(kmf.vars.shield_unit_hits) do
+				local dt = time - hit_data.time
+
+				if dt >= 0.15 then
+					kmf.vars.shield_unit_hits[grouping] = nil
+				elseif grouping.owner == kmf_misc_data.owner and grouping.group_id == kmf_misc_data.group_id then
+					if hit_data[u] then
+						return
+					else
+						kmf.vars.shield_unit_hits[grouping][u] = true
+						added = true
+					end
+				end
+			end
+
+			if not added then
+				local grouping = {
+					owner = kmf_misc_data.owner,
+					group_id = kmf_misc_data.group_id
+				}
+
+				kmf.vars.shield_unit_hits[grouping] = {
+					time = time
+				}
+				kmf.vars.shield_unit_hits[grouping][u] = true
+			end
+		end
+	end
+
+	if player_ext and kmf.vars.funprove_enabled then
+		local faction_ext = EntityAux.extension(u, "faction")
+		local faction = faction_ext and faction_ext.internal and faction_ext.internal.faction or "player"
+		local friendly_fire = false
+
+		for k, v in pairs(attackers) do
+			local faction_ext = EntityAux.extension(v, "faction")
+			if faction_ext and faction_ext.internal and faction_ext.internal.faction == faction then
+				friendly_fire = true
+				break
+			end
+		end
+
+		if friendly_fire then
+			local defense_ext = EntityAux.extension(u, "defense")
+
+			for elem, amount in pairs(damages_new) do
+				local mul
+
+				if defense_ext.internal.resistances and defense_ext.internal.resistances[elem] then
+					mul = 1
+					for _, v in pairs(defense_ext.internal.resistances[elem].mul[1]) do
+						mul = mul * v
+					end
+				end
+
+				if mul and mul < 0 then
+					damages_new[elem] = amount / 4.545455 -- so that 150% healing will be instead 33% healing
+				end
+			end
+		end
+	end
+
+	return _old_local_add_damage(u, attackers, damages_new, medium, scale_damage, impact_location, ignore_multipliers, damage_owner_name)
+end
+
 local function local_add_ability(u, ability, arg)
 	if not ability then
 		return
@@ -176,11 +260,17 @@ local function local_add_ability_by_extension(extension, ability, arg)
 end
 
 local function local_stop_ability(u, ability)
-	local input = local_extension(u, "ability_user", true).input
+	local ext = local_extension(u, "ability_user", true)
+	if ext == nil or ext.input == nil then
+		return
+	end
 
-	input.dirty_flag = true
+	ext.input.dirty_flag = true
 
-	local abilities = input.stop_ability
+	local abilities = ext.input.stop_ability
+	if abilities == nil then
+		return
+	end
 
 	abilities[#abilities + 1] = ability
 end
