diff --git a/scripts/game/entity_system/systems/gui_2d/gui_2d_system.lua b/scripts/game/entity_system/systems/gui_2d/gui_2d_system.lua
index e7c5004..275eed8 100644
--- a/scripts/game/entity_system/systems/gui_2d/gui_2d_system.lua
+++ b/scripts/game/entity_system/systems/gui_2d/gui_2d_system.lua
@@ -592,6 +592,28 @@ function Gui2DSystem:update(context)
 	gui_manager:update(context.dt)
 end
 
+kmf.draw_cooldown_magick = function(ui_renderer, magick, cd, slot)
+	local raw_w, raw_h = Application.resolution()
+	local x = raw_w * 0.01
+	local y = x
+	local border = math.round(0.0015 * raw_h)
+	local cd_percent = cd / (kmf.const.magicks_cooldown[magick] or 1.5)
+	local sz = math.round(0.03333333 * raw_h)
+
+	border = border > 1 and border or 1
+	sz = sz > 24 and sz or 24
+	cd_percent = cd_percent < 1.0 and cd_percent or 1.0
+
+	local sz_border = sz + border * 2
+	local sz_cd = sz * cd_percent
+	y = y + slot * (sz_border * 1.1)
+
+	local icon = MagicksSettings[magick] and MagicksSettings[magick].icon or "hud_magick_disruptor"
+	ui_renderer:draw_rect(Vector3(x - border, y - border, 0), Vector2(sz_border, sz_border), Color(0, 0, 0))
+	ui_renderer:draw_texture(Vector3(x, y, 0), Vector2(sz, sz), icon, Color(255, 0, 64, 64))
+	ui_renderer:draw_rect(Vector3(x, y, 1), Vector2(sz, sz_cd), Color(215, 32, 32, 32))
+end
+
 function Gui2DSystem:draw_magick_name(ui_renderer, position, unit, hud_magicks, elements, element_queue_hud, show_template)
 	local selected_magick_template = false
 	local magick_name, magick_tier = _magick_from_elements(elements)
@@ -623,7 +645,22 @@ function Gui2DSystem:draw_magick_name(ui_renderer, position, unit, hud_magicks,
 			local spellwheel_ext = EntityAux.extension(unit, "spellwheel")
 
 			if spellwheel_ext then
-				magick_cast_cooldown = spellwheel_ext.internal.magicks_cast_cooldown
+				local internal = spellwheel_ext.internal
+
+				magick_cast_cooldown = internal.magicks_cast_cooldown
+
+				-- fun-balance :: magick cds
+				if kmf.vars.funprove_enabled and internal.magick_cds then
+					if not magick_cast_cooldown then
+						magick_cast_cooldown = internal.magick_cds[magick_name]
+					end
+
+					local slot = 0
+					for magick_name, cd in pairs(internal.magick_cds) do
+						kmf.draw_cooldown_magick(ui_renderer, magick_name, cd, slot)
+						slot = slot + 1
+					end
+				end
 			end
 
 			if SpellSettings.elemental_magicks_cooldown and not hud_magicks:is_magick_button_enabled(magick_tier) or magick_cast_cooldown or selected_magick_template then
@@ -647,7 +684,12 @@ function Gui2DSystem:draw_elements(element_queue_hud, elements, position, unit,
 	assert(hud_magicks)
 
 	local magick_name, magick_tier = _magick_from_elements(element_queue_hud:get_selected_magick_template_elements())
-	local show_template = hud_magicks:has_magick(magick_name or "") and hud_magicks:is_tier_enabled(magick_tier or "")
+
+	local show_template = nil
+
+	if hud_magicks:has_magick(magick_name or "") then
+		show_template = hud_magicks:is_tier_enabled(magick_tier or "")
+	end
 
 	if element_queue_hud:only_template_elements() and not show_template then
 		return
