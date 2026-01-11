diff --git a/scripts/game/menu2/menu_ui.lua b/scripts/game/menu2/menu_ui.lua
index b260b12..edcc481 100644
--- a/scripts/game/menu2/menu_ui.lua
+++ b/scripts/game/menu2/menu_ui.lua
@@ -22,7 +22,8 @@ local MainMenuPrefabs = {
 		children = {
 			"main_menu_bar",
 			"main_menu_list",
-			"pops_widget"
+			"pops_widget",
+			"k_special_button"
 		}
 	},
 	main_menu_bar = {
@@ -59,6 +60,31 @@ local MainMenuPrefabs = {
 			hover = "pc_quit_button_hover"
 		}
 	},
+	k_special_button = {
+		z = 1,
+		h = 90,
+		name = "button",
+		horizontal_alignment = "center",
+		vertical_alignment = "top",
+		x = 650,
+		y = 780,
+		id = "k_special_button",
+		prefabs = {
+			"nav_confirm",
+			"button_behavior"
+		},
+		w = UI.Grid.col_2 + 100,
+		vars = {
+			x_from = 650,
+			x_to = 650,
+			item_text_localize = "[KMF]mod_settings_btn",
+			button_bitmap = "button_col_3"
+		},
+		children = {
+			"main_menu_item_text",
+			"button_bg"
+		}
+	},
 	pops_widget = {
 		name = "anchor",
 		h = 400,
@@ -229,7 +255,6 @@ local MainMenuPrefabs = {
 }
 local user_has_dlc2 = true
 local menu_options = {}
-
 menu_options[#menu_options + 1] = {
 	id = "continue",
 	prefabs = {
@@ -284,18 +309,15 @@ menu_options[#menu_options + 1] = {
 		item_text_localize = "legal_title_privacy_caps"
 	}
 }
-
-if Application.build() ~= "release" then
-	menu_options[#menu_options + 1] = {
-		id = "debug_levels",
-		prefabs = {
-			"main_menu_item"
-		},
-		vars = {
-			item_text = "Debug Levels"
-		}
+menu_options[#menu_options + 1] = {
+	id = "debug_levels",
+	prefabs = {
+		"main_menu_item"
+	},
+	vars = {
+		item_text = "Debug Levels"
 	}
-end
+}
 
 menu_options[#menu_options + 1] = {
 	id = "go_online",
@@ -323,6 +345,9 @@ local ui_elements_disabled_when_not_host = {
 
 function C:init(context)
 	cat_printf_spam("UI", "[%s] init", Alias)
+	if not rawget(_G, "kmf") then
+		return
+	end
 
 	self.context = context
 
@@ -351,6 +376,9 @@ function C:init(context)
 
 	self.rss_news:get_event_delegate():register(Alias, self, "on_rss_news_received")
 
+	rawset(_G, "k_mod_settings_button", self.menu_ui:find("k_special_button"))
+	_G.k_mod_settings_button:on("click", self, self.on_click_k_mod_button)
+
 	self.unlink_button = self.menu_ui:find("unlink")
 
 	self.unlink_button:on("click", self, self.on_click_unlink)
@@ -362,6 +390,10 @@ function C:init(context)
 	ui_aux.connect_gamepad_horizontal(self.privacy_policy_button, self.unlink_button)
 end
 
+function C:on_click_k_mod_button(self)
+	_G.kmf.mod_settings_manager.c_mod_mngr.display_settings_menu()
+end
+
 function C:destroy()
 	self.context.event_delegate:unregister(Alias)
 	self.context.lobby_handler:get_event_delegate():unregister(Alias)
@@ -664,7 +696,6 @@ function C:on_click_list_item(evt)
 	self:on_hide_main_menu("forward")
 
 	local menu_event = menu_event_lookup[id]
-
 	self.context.event_delegate:trigger1(menu_event, "forward")
 end
 
