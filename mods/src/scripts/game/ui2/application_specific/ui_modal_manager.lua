diff --git a/scripts/game/ui2/application_specific/ui_modal_manager.lua b/scripts/game/ui2/application_specific/ui_modal_manager.lua
index 2ea2a2c..3eddc45 100644
--- a/scripts/game/ui2/application_specific/ui_modal_manager.lua
+++ b/scripts/game/ui2/application_specific/ui_modal_manager.lua
@@ -93,11 +93,16 @@ function C:push_modal(desc)
 		},
 		id = desc.id,
 		vars = {
-			modal_text_y = -90,
-			modal_title_localize = desc.title_localize,
-			modal_text_localize = desc.text_localize
+			modal_text_y = -90
 		}
 	}
+	if desc.cancel_localization then
+		prefab.vars.modal_title = desc.title_localize
+		prefab.vars.modal_text = desc.text_localize
+	else
+		prefab.vars.modal_title_localize = desc.title_localize
+		prefab.vars.modal_text_localize = desc.text_localize
+	end
 
 	if desc.type == "block" then
 		prefab.vars.modal_text_y = -10
