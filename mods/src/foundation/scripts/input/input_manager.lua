diff --git a/foundation/scripts/input/input_manager.lua b/foundation/scripts/input/input_manager.lua
index 9c51e4d..83b461f 100644
--- a/foundation/scripts/input/input_manager.lua
+++ b/foundation/scripts/input/input_manager.lua
@@ -35,6 +35,10 @@ function InputManager:_reset_mappings()
 end
 
 function InputManager:map_controller(controller, slot)
+	if not controller then
+		return
+	end
+
 	if type(controller) == "string" then
 		controller = InputAux.get_engine_controller(controller)
 	end
@@ -126,7 +130,8 @@ function InputManager:_get_keymapping_type(slot)
 		end
 	end
 
-	assert(false, sprintf("InputManager:_get_keymapping_type(...) : Failed for slot(%d)", slot))
+	return nil
+	--assert(false, sprintf("InputManager:_get_keymapping_type(...) : Failed for slot(%d)", slot))
 end
 
 function InputManager:map_slot(slot, target, mapping, dryrun)
@@ -257,6 +262,12 @@ function InputManager:update(dt)
 
 	for target, mapping in pairs(self._target_mappings) do
 		self:_send_input(target, mapping, dt)
+
+		if target.input_data.override_activate then
+			kmf_print("    using override_activate")
+			target.input_data.override_activate = false
+			target.input_data.activate = true
+		end
 	end
 end
 
@@ -530,25 +541,31 @@ function InputAux.get_engine_controller(controller)
 end
 
 function InputAux.merge_input_data(table1, table2)
+	if not table1 then
+		return table.clone(table2)
+	end
+
 	local merged = table.clone(table1)
 
-	for key, v1 in pairs(merged) do
-		local v2 = table2[key]
+	if table2 then
+		for key, v1 in pairs(merged) do
+			local v2 = table2[key]
 
-		if v2 then
-			if type(v1) == "boolean" and type(v2) == "boolean" and v2 and not v1 then
-				merged[key] = true
-			end
+			if v2 then
+				if type(v1) == "boolean" and type(v2) == "boolean" and v2 and not v1 then
+					merged[key] = true
+				end
 
-			if type(v1) == "number" and type(v2) == "number" and v1 < v2 then
-				merged[key] = v2
+				if type(v1) == "number" and type(v2) == "number" and v1 < v2 then
+					merged[key] = v2
+				end
 			end
 		end
-	end
 
-	for key, v2 in pairs(table2) do
-		if not merged[key] then
-			merged[key] = v2
+		for key, v2 in pairs(table2) do
+			if not merged[key] then
+				merged[key] = v2
+			end
 		end
 	end
 
