diff --git a/scripts/game/entity_system/systems/ability/ability_system.lua b/scripts/game/entity_system/systems/ability/ability_system.lua
index 9c5ccf3..5ae70b4 100644
--- a/scripts/game/entity_system/systems/ability/ability_system.lua
+++ b/scripts/game/entity_system/systems/ability/ability_system.lua
@@ -150,6 +150,8 @@ function AbilitySystem:update(context)
 		DEBUG_ADD_ABILITY_UPDATE(ability_context)
 	end
 
+	local boosted_damage_mul_tables = {}
+
 	for i = 1, entities_n do
 		repeat
 			local extension_data = entities[i]
@@ -179,17 +181,45 @@ function AbilitySystem:update(context)
 
 						start_abilities[name] = nil
 					else
-						local template = templates[name]
+						local template = kmf.before_start_ability(name, templates[name], u)
+
+						if kmf.vars.funprove_enabled then
+							local i_start, _ = string.find(name, "earth_projectile_", 1, true)
+
+							-- fun-balance :: buff elemental rock projectile aoe
+							if i_start and args.damage_mul and boosted_damage_mul_tables[args.damage_mul] ~= true then
+								boosted_damage_mul_tables[args.damage_mul] = true
+
+								for k, v in pairs(args.damage_mul) do
+									if k ~= "water" and k ~= "water_push" and k ~= "water_elevate" and k ~= "push" and k ~= "elevate" then
+										args.damage_mul[k] = v * 2
+									else
+										args.damage_mul[k] = v * 2.5
+									end
+								end
+
+								if args.damage_mul["life"] then
+									args.damage_mul["life"] = args.damage_mul["life"] * 0.6
+								end
+							-- fun-balance :: buff lightinging self electrecute heal
+							elseif name == "conjure_electrify_self" then
+								local tmp = table.clone(template)
 
-						assert(template, "Ability '" .. name .. "' not found in AbilityTemplates !")
+								if tmp.deal_self_damage.damage then
+									tmp.deal_self_damage.damage.lightning = tmp.deal_self_damage.damage.lightning * 1.5
+								end
+
+								template = tmp
+							end
+						end
+
+						assert(template, "[Abilities] template '" .. name .. "' not found in AbilityTemplates !")
 
 						ability_context.template_name = name
 						ability_context.params = args
 
 						local update_funs = {}
 
-						assert(template, sprintf("[Abilities] Error, %s template does not exist.", name))
-
 						for ability_type, ability_data in pairs(template) do
 							ability_context.args = ability_data
 
@@ -197,6 +227,29 @@ function AbilitySystem:update(context)
 
 							if ability then
 								if ability.on_activate then
+									-- kmf safeguards start
+									if ability.on_activate == Abilities.resurrected.on_activate then
+										local player_ents = ability_context.entity_manager:get_entities("player")
+
+										if #player_ents > 0 then
+											for i, player in ipairs(player_ents) do
+												if not player.unit then
+													goto continue
+												end
+											end
+										end
+
+										local resurrectee = ability_context.params
+
+										if type(resurrectee) ~= "unit" then
+											ability_context.params = ability_context.unit
+											--goto continue
+										end
+									end
+									if ability_context.unit == nil then
+										goto continue
+									end
+									-- kmf safeguards end
 									local update_fun = ability.on_activate(ability_context)
 
 									if update_fun then
@@ -206,6 +259,7 @@ function AbilitySystem:update(context)
 							else
 								cat_printf("Abilities", "Error in ability argument name %s: %s does not exist.", name, ability_type)
 							end
+							::continue::
 						end
 
 						if abilities[name] then
