diff --git a/scripts/game/managers/player_variable_manager.lua b/scripts/game/managers/player_variable_manager.lua
index e568893..38cc21d 100644
--- a/scripts/game/managers/player_variable_manager.lua
+++ b/scripts/game/managers/player_variable_manager.lua
@@ -17,7 +17,20 @@ function PlayerVariableManager:get_variable(unit, variable, assert_on_none_exist
 
 	local unit_data = pvm[unit]
 
-	return unit_data and pvm[unit][variable] or 1
+	if unit_data then
+		local additional_mult = 1
+
+		if variable == "focus_regen_multiplier" then
+			additional_mult = pvm[unit]["robe_" .. variable] or 1
+		elseif string.find(variable, "staff_modifier_element_") then
+			local robe_mult_var = string.gsub(variable, "staff_", "robe_", 1)
+			additional_mult = pvm[unit][robe_mult_var] or 1
+		end
+
+		return (pvm[unit][variable] or 1) * additional_mult
+	end
+
+	return 1
 end
 
 function PlayerVariableManager:get_variable_unsafe(unit, variable, assert_on_none_existing)
@@ -29,7 +42,20 @@ function PlayerVariableManager:get_variable_unsafe(unit, variable, assert_on_non
 
 	local unit_data = pvm[unit]
 
-	return unit_data and pvm[unit][variable] or nil
+	if unit_data and pvm[unit][variable] then
+		local additional_mult = 1
+
+		if variable == "focus_regen_multiplier" then
+			additional_mult = pvm[unit]["robe_" .. variable] or 1
+		elseif string.find(variable, "staff_modifier_element_") then
+			local robe_mult_var = string.gsub(variable, "staff_", "robe_", 1)
+			additional_mult = pvm[unit][robe_mult_var] or 1
+		end
+
+		return pvm[unit][variable] * additional_mult
+	end
+
+	return nil
 end
 
 function PlayerVariableManager:multiply_variables(unit, variable_multiplier_mapping)
