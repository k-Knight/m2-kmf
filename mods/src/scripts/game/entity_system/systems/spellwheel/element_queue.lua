diff --git a/scripts/game/entity_system/systems/spellwheel/element_queue.lua b/scripts/game/entity_system/systems/spellwheel/element_queue.lua
index eb760d1..afa0b9b 100644
--- a/scripts/game/entity_system/systems/spellwheel/element_queue.lua
+++ b/scripts/game/entity_system/systems/spellwheel/element_queue.lua
@@ -110,14 +110,109 @@ function ElementQueue:clear()
 	end
 end
 
-function ElementQueue:get_elements()
+local function _magick_from_elements(element_queue)
+	local inverted_queue = table.invert_array_order(element_queue)
+	local num_elements = #inverted_queue
+
+	for magick_name, magick_element_queue in pairs(MagickByElements) do
+		local match_found = false
+
+		if num_elements == #magick_element_queue then
+			for i = 1, num_elements, 1 do
+				if inverted_queue[i] == magick_element_queue[i] then
+					match_found = true
+				else
+					match_found = false
+
+					break
+				end
+			end
+
+			if match_found then
+				local magick_tier = MagicksSettings[magick_name].tier
+
+				return magick_name, magick_tier
+			end
+		end
+	end
+
+	return nil
+end
+
+function ElementQueue:get_elements(spell_type, is_controller)
 	local elems = {}
+	local is_illegal = false
+
+	local has_life = false
+	local has_poison = false
+	local has_earth = false
+	local has_lightning = false
+	local has_shield = false
+	local has_ice = false
+	local has_lok = false
+	local has_water = false
+	local has_arcane = false
+
+	for elem, amt in pairs(self.selected_elements) do
+		if elem == "life" and amt > 0 then
+			has_life = true
+		elseif elem == "poison" and amt > 0 then
+			has_poison = true
+		elseif elem == "lightning" and amt > 0 then
+			has_lightning = true
+		elseif elem == "earth" and amt > 0 then
+			has_earth = true
+		elseif elem == "ice" and amt > 0 then
+			has_ice = true
+		elseif elem == "lok" and amt > 0 then
+			has_lok = true
+		elseif elem == "water" and amt > 0 then
+			has_water = true
+		elseif elem == "arcane" and amt > 0 then
+			has_arcane = true
+		elseif elem == "shield" and amt > 0 then
+			has_shield = true
+		end
+	end
+
+	if spell_type == "forward" then
+		if	(has_life and has_poison and not has_shield and not has_ice) or
+			(has_earth and has_lightning and not has_shield and not has_ice) or
+			(has_arcane and has_water and not has_shield and not has_earth and not has_ice)
+		then
+			is_illegal = true
+		end
+	elseif spell_type == "area" then
+		if	(has_life and has_poison and not has_shield and not has_ice) or
+			(has_lok and has_earth and not has_ice and not has_shield and not (has_lightning and not has_life))
+		then
+			is_illegal = true
+		end
+	elseif spell_type == "self" then
+		if	(has_earth and has_lightning and not has_shield and not has_ice) or
+			(has_lok and has_earth and not has_ice and not has_shield and not has_lightning)
+		then
+			is_illegal = true
+		end
+	elseif spell_type == "weapon_imbue" then
+		if has_lok then
+			if is_controller then
+				local magick_name, magick_tier = _magick_from_elements(self.element_queue)
+				if not magick_name then
+					is_illegal = true
+				end
+			else
+				is_illegal = true
+			end
+		end
+	elseif spell_type == "magick_from_elements" then
+	end
 
 	for elem, amt in pairs(self.selected_elements) do
 		elems[elem] = amt
 	end
 
-	return elems, #self.element_queue
+	return elems, #self.element_queue, is_illegal
 end
 
 function ElementQueue:get_elements_nowrite()
