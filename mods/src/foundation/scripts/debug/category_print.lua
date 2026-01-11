diff --git a/foundation/scripts/debug/category_print.lua b/foundation/scripts/debug/category_print.lua
index 72ae320..c0f6aad 100644
--- a/foundation/scripts/debug/category_print.lua
+++ b/foundation/scripts/debug/category_print.lua
@@ -162,7 +162,7 @@ local function _print_category_check_color(category, message)
 end
 
 local function _build_cat_print(channel_name, category_prefix, console_log_function, string_converter)
-	return function(cat, ...)
+	return function (cat, ...)
 		if _should_log(_console_filters[channel_name], cat) then
 			return console_log_function(category_prefix .. cat, string_converter(...))
 		elseif _should_log(_logfile_filters[channel_name], cat) then
@@ -171,10 +171,25 @@ local function _build_cat_print(channel_name, category_prefix, console_log_funct
 	end
 end
 
-cat_print = _build_cat_print("info", "", _print_category_check_color, var_args_as_string)
-cat_printf = _build_cat_print("info", "", _print_category_check_color, string.format)
-cat_print_spam = _build_cat_print("spam", "", _print_category_check_color, var_args_as_string)
-cat_printf_spam = _build_cat_print("spam", "", _print_category_check_color, string.format)
+if kmf_enable_debug then
+	print("kmf_enable_debug")
+
+	cat_print = _build_cat_print("info", "", _print_category_check_color, var_args_as_string)
+	cat_printf = _build_cat_print("info", "", _print_category_check_color, string.format)
+	cat_print_spam = _build_cat_print("spam", "", _print_category_check_color, var_args_as_string)
+	cat_printf_spam = _build_cat_print("spam", "", _print_category_check_color, string.format)
+else
+	print("release, no debugging")
+	cat_print = function(...) end
+	cat_printf = function(...) end
+	cat_print_spam = function(...) end
+	cat_printf_spam = function(...) end
+end
+
+kmf_print = function (cat, ...)
+	print("[KMF][" .. cat .. "]" .. var_args_as_string(...))
+end
+
 cat_print_warning = _build_cat_print("warning", "WARN][", print_warning_category, var_args_as_string)
 cat_printf_warning = _build_cat_print("warning", "WARN][", print_warning_category, string.format)
 
