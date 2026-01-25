diff --git a/scripts/game/ui2/ui_renderer.lua b/scripts/game/ui2/ui_renderer.lua
index f52088d..d0f6326 100644
--- a/scripts/game/ui2/ui_renderer.lua
+++ b/scripts/game/ui2/ui_renderer.lua
@@ -407,6 +407,39 @@ function C:update(dt)
 		self:draw_rect(start_position, size, color)
 		self:draw_text(text, "philosopher_bold_outline", 12, position)
 	end
+
+	if rawget(_G, "kmf") then
+		for _, on_udate_func in pairs(kmf.vars.on_update_handlers) do
+			on_udate_func(dt)
+		end
+
+		if kmf.check_mod_enabled("movement convenience") then
+			local state = kmf.check_mod_hotkey_status("movement convenience")
+
+			if state ~= kmf.vars.movement_convenience.enabled then
+				if state then
+					local cur_cursor = Mouse.axis(Mouse.axis_index("cursor"), Mouse.RAW, 3)
+					kmf.vars.movement_convenience.orig_x = cur_cursor[1]
+					kmf.vars.movement_convenience.orig_y = cur_cursor[2]
+
+					local raw_w, raw_h = Application.resolution()
+					kmf.vars.movement_convenience.screen_scale = math.sqrt(raw_w * raw_w + raw_h * raw_h)
+				elseif kmf.vars.movement_convenience.orig_x and kmf.vars.movement_convenience.orig_y then
+					Window.set_cursor_position(Vector2(kmf.vars.movement_convenience.orig_x, kmf.vars.movement_convenience.orig_y))
+				end
+
+				kmf.vars.movement_convenience.enabled = state
+			end
+		end
+
+		local gamepad_aiming_enabled = kmf.check_mod_enabled("gamepad aiming")
+
+		if gamepad_aiming_enabled and not kmf.vars.gamepad_aiming then
+			kmf.setup_gamepad_aiming()
+		elseif not gamepad_aiming_enabled and kmf.vars.gamepad_aiming then
+			kmf.destroy_gamepad_aiming()
+		end
+	end
 end
 
 function C:get_clipping_rect_bounds(clipping_rect_settings)
@@ -490,6 +523,13 @@ local inv_log2 = 1 / math_log(2)
 local log16_div_log2 = inv_log2 * math_log(16)
 
 function C:get_font(font, font_size)
+	if not font then
+		font = "philosopher_bold_outline"
+	end
+	if not font_size then
+		font_size = 64
+	end
+
 	local font_data = font_lookup[font]
 	local scale = font_data.inv_size * (font_size + (LocalizationManager:is_chinese() and 4 or 0))
 	local clamped_scale = math_min_clamp(scale, 0.375)
@@ -500,6 +540,12 @@ function C:get_font(font, font_size)
 end
 
 function C:text_extents(text, font, font_size)
+	if not font then
+		font = "philosopher_bold_outline"
+	end
+	if not font_size then
+		font_size = 64
+	end
 	local font_path, src_size, material, scale = self:get_font(font, font_size)
 	local min_pos, max_pos, caret = Gui.text_extents(self.gui, text, font_path, font_size + (LocalizationManager:is_chinese() and 4 or 0))
 
@@ -507,6 +553,12 @@ function C:text_extents(text, font, font_size)
 end
 
 function C:text_extents_advance(text, font, font_size)
+	if not font then
+		font = "philosopher_bold_outline"
+	end
+	if not font_size then
+		font_size = 64
+	end
 	local font_path, src_size, material, scale = self:get_font(font, font_size)
 	local _, _, caret = Gui.text_extents(self.gui, text, font_path, font_size + (LocalizationManager:is_chinese() and 4 or 0))
 
@@ -514,12 +566,21 @@ function C:text_extents_advance(text, font, font_size)
 end
 
 function C:word_wrap(text, font, font_size, width, whitespace, soft_dividers, return_dividers)
+	if not font then
+		font = "philosopher_bold_outline"
+	end
+	if not font_size then
+		font_size = 64
+	end
 	local font_path, src_size, material, scale = self:get_font(font, font_size)
 
 	return Gui.word_wrap(self.gui, text, font_path, Resolution.scale * scale * src_size, Resolution.scale * width, whitespace, soft_dividers, return_dividers)
 end
 
 function C:draw_text_3d(text, font, size, position, color, transform, layer)
+	if not font then
+		font = "philosopher_bold_outline"
+	end
 	if self.disabled then
 		return
 	end
@@ -538,6 +599,12 @@ function C:draw_text_3d(text, font, size, position, color, transform, layer)
 end
 
 function C:draw_text(text, font, font_size, pos, color, rotation)
+	if not font then
+		font = "philosopher_bold_outline"
+	end
+	if not font_size then
+		font_size = 64
+	end
 	if self.disabled then
 		return
 	end
@@ -575,6 +642,12 @@ function C:draw_text(text, font, font_size, pos, color, rotation)
 end
 
 function C:draw_text_3d_2(text, font, font_size, tm, layer, color)
+	if not font then
+		font = "philosopher_bold_outline"
+	end
+	if not font_size then
+		font_size = 64
+	end
 	if self.disabled then
 		return
 	end
