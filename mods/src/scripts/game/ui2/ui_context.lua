diff --git a/scripts/game/ui2/ui_context.lua b/scripts/game/ui2/ui_context.lua
index 9deefe3..1b33b36 100644
--- a/scripts/game/ui2/ui_context.lua
+++ b/scripts/game/ui2/ui_context.lua
@@ -262,6 +262,11 @@ _UIContext = class(_UIContext)
 
 local C = _UIContext
 
+
+if rawget(_G, "kmf") then
+	kmf.early_init()
+end
+
 function C:init(viewport_template, level_name)
 	cat_printf_spam("UI", "UICONTEXT:INIT %s", caller(3))
 
@@ -342,6 +347,10 @@ function C:init(viewport_template, level_name)
 	self.ui_modal_manager = self.ui_scene:find("modal_manager")
 	self.ui_message_manager = self.ui_scene:find("message_manager")
 	self.input_stack = {}
+
+	if rawget(_G, "kmf") then
+		kmf.ui_modal_manager = self.ui_modal_manager
+	end
 end
 
 function C:reset()
@@ -529,9 +538,17 @@ function C:keybinding(output)
 	local mapping_info = self.input_manager:get_mapping_info(target, output)
 
 	if mapping_info then
-		local controller_type
-
-		controller_type = (mapping_info.controller_type == "keyboard" or mapping_info.controller_type == "mouse") and "keyboard_mouse" or mapping_info.controller and (mapping_info.controller.type() == "xbox_controller" or mapping_info.controller.type() == "glfw_controller" or mapping_info.controller.type() == "sdl_controller" or mapping_info.controller.type() == "osx_controller") and "pad360" or mapping_info.controller and mapping_info.controller.type() == "steam_controller" and "padsteam" or "padps4"
+		local controller_type = nil
+
+		if mapping_info.controller_type == "keyboard" or mapping_info.controller_type == "mouse" then
+			controller_type = "keyboard_mouse"
+		elseif mapping_info.controller and (mapping_info.controller.type() == "xbox_controller" or mapping_info.controller.type() == "glfw_controller" or mapping_info.controller.type() == "sdl_controller" or mapping_info.controller.type() == "osx_controller") then
+			controller_type = "pad360"
+		elseif mapping_info.controller and mapping_info.controller.type() == "steam_controller" then
+			controller_type = "padsteam"
+		else
+			controller_type = "padps4"
+		end
 
 		return mapping_info.key, controller_type
 	end
@@ -770,11 +787,7 @@ function C:update_gamepad_navigation()
 	}
 	local modal = self.ui_modal_manager:active_modal()
 
-	if modal then
-		input_event_params.propagate = false
-	else
-		input_event_params.propagate = true
-	end
+	input_event_params.propagate = not modal
 
 	local input_data = self.input_data
 	local gamepad_input_target
@@ -1151,6 +1164,26 @@ end
 
 function C:render()
 	self.ui_scene:render(self.ui_renderer)
+
+	if rawget(_G, "my_debugger") ~= nil then
+		local wrapper = function ()
+			_G.my_debugger.check_exec_queue()
+		end
+		pcall(wrapper)
+	end
+
+	if rawget(_G, "kmf") then
+		local status, err = pcall(kmf.get_mod_settings)
+
+		if status ~= true then
+			if _G.my_debugger then
+				kmf_print("get_mod_settings()", err)
+			end
+		end
+
+		kmf.on_reder()
+		--kmf.task_scheduler.try_run_next_task()
+	end
 end
 
 function C:trigger_event_level(event_name)
