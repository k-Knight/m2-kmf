diff --git a/scripts/game/entity_system/systems/defense/defense_system.lua b/scripts/game/entity_system/systems/defense/defense_system.lua
index a3bd865..eb48c15 100644
--- a/scripts/game/entity_system/systems/defense/defense_system.lua
+++ b/scripts/game/entity_system/systems/defense/defense_system.lua
@@ -473,6 +473,7 @@ function DefenseSystem:update_defense(context)
 			local input, internal = extension.input, extension.internal
 			local internal_resistances = internal.resistances
 			local status_resistances = internal.status_resistances
+			local kmf_res = false
 
 			if input.dirty_flag then
 				input.dirty_flag = false
@@ -485,14 +486,47 @@ function DefenseSystem:update_defense(context)
 					local element = resistance_data[1]
 					local modifier = resistance_data[2]
 					local value = resistance_data[3]
+					kmf_res = resistance_data[4] or false
+					local proc_res = true
 
 					cat_print("defense_system", "removing resistance( " .. tostring(element) .. " )," .. "modifier( " .. tostring(modifier) .. " )," .. "value( " .. tostring(value) .. ") ")
 
 					local current_resistance_data = internal_resistances[element]
-					local result = array_pop_item(current_resistance_data[modifier], value)
 
-					if result then
-						current_resistance_data.sum_of_modifiers = current_resistance_data.sum_of_modifiers - 1
+					if element and modifier then
+						local mod_res_table = current_resistance_data[modifier]
+						if mod_res_table then
+							local res_table = mod_res_table[1]
+							if res_table and #res_table > 0 then
+								local last_kmf_res = mod_res_table.last_kmf
+								if last_kmf_res then
+									if last_kmf_res.on_remove_res and last_kmf_res.check_amount then
+										local found = false
+	
+										for _, value in ipairs(res_table) do
+											if last_kmf_res:check_amount(element, value) then
+												found = true
+												break
+											end
+										end
+
+										if found then
+											last_kmf_res:on_remove_res()
+										end
+
+										mod_res_table.last_kmf = nil
+									end
+								end
+							end
+						end
+					end
+
+					if proc_res then
+						local result = array_pop_item(current_resistance_data[modifier], value)
+
+						if result then
+							current_resistance_data.sum_of_modifiers = current_resistance_data.sum_of_modifiers - 1
+						end
 					end
 
 					remove_resistance[j] = nil
@@ -535,6 +569,8 @@ function DefenseSystem:update_defense(context)
 					local element = resistance[1]
 					local modifier = resistance[2]
 					local value = resistance[3]
+					kmf_res = resistance[4] or false
+					local proc_res = true
 
 					cat_print_spam("defense_system", "adding resistance( " .. tostring(element) .. " )," .. "modifier( " .. tostring(modifier) .. " )," .. "value( " .. tostring(value) .. ") ")
 					assert(element)
@@ -543,9 +579,27 @@ function DefenseSystem:update_defense(context)
 
 					local current_resistance_data = internal_resistances[element]
 
-					array_push_back(current_resistance_data[modifier], value)
+					if element and modifier then
+						local mod_res_table = current_resistance_data[modifier]
+						if mod_res_table then
+							local last_kmf_res = mod_res_table.last_kmf
+							if last_kmf_res then
+								if last_kmf_res.on_remove_res then
+									last_kmf_res:on_remove_res()
+									mod_res_table.last_kmf = nil
+								end
+							end
+
+							if kmf_res then
+								mod_res_table.last_kmf = kmf_res
+							end
+						end
+					end
 
-					current_resistance_data.sum_of_modifiers = current_resistance_data.sum_of_modifiers + 1
+					if proc_res then
+						array_push_back(current_resistance_data[modifier], value)
+						current_resistance_data.sum_of_modifiers = current_resistance_data.sum_of_modifiers + 1
+					end
 
 					local multiplier = 1
 
@@ -577,6 +631,8 @@ function DefenseSystem:update_defense(context)
 					end
 
 					add_resistance[j] = nil
+
+					::add_continue::
 				end
 
 				local mres = input.modify_resistances
@@ -596,11 +652,15 @@ function DefenseSystem:update_defense(context)
 				internal.sum_of_all_resistances = internal.sum_of_all_resistances + diff
 
 				if internal.sum_of_all_resistances < 0 then
-					assert(false)
+					if kmf_res then
+						internal.sum_of_all_resistances = 0
+					else
+						assert(false)
+					end
 				end
 			end
 
-			if internal.sum_of_all_resistances == 0 then
+			if internal.sum_of_all_resistances == 0 and not kmf_res then
 				break
 			end
 
