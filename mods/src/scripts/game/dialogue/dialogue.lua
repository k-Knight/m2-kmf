diff --git a/scripts/game/dialogue/dialogue.lua b/scripts/game/dialogue/dialogue.lua
index f5f787a..a124090 100644
--- a/scripts/game/dialogue/dialogue.lua
+++ b/scripts/game/dialogue/dialogue.lua
@@ -848,6 +848,14 @@ function Dialogue:on_activate(entity_manager, ignore_sound)
 end
 
 function Dialogue:update(dt)
+	if not self then
+		return false
+	end
+
+	if not self._tool or not self.data then
+		return false
+	end
+
 	if self.resetted then
 		return true
 	end
@@ -859,7 +867,7 @@ function Dialogue:update(dt)
 			pos = self._tool:get_unit_screen_position(self._unit)
 			pos[3] = 1
 
-			if self.data.offset then
+			if self.data and self.data.offset then
 				pos[1] = pos[1] + self.data.offset[1]
 				pos[2] = pos[2] + self.data.offset[2]
 			end
@@ -876,23 +884,23 @@ function Dialogue:update(dt)
 
 			return false
 		end
-	else
+	elseif self._tool then
 		local anchor_w, anchor_h = self._tool:anchor_resolution()
 
 		pos[1] = 0
 		pos[2] = 0
 
-		if self.data.align_horizontal == "center" then
+		if self.data and self.data.align_horizontal == "center" then
 			pos[1] = (anchor_w - self._width) / 2
-		elseif self.data.align_horizontal == "right" then
+		elseif self.data and self.data.align_horizontal == "right" then
 			pos[1] = anchor_w - self._width - anchor_w * (1 - self.safe_area_ratio) * 0.5
 		else
 			pos[1] = anchor_w * (1 - self.safe_area_ratio) * 0.5
 		end
 
-		if self.data.align_vertical == "middle" then
+		if self.data and self.data.align_vertical == "middle" then
 			pos[2] = (anchor_h - self._height) / 2
-		elseif self.data.align_vertical == "top" then
+		elseif self.data and self.data.align_vertical == "top" then
 			pos[2] = anchor_h - self._height + anchor_h * (1 - self.safe_area_ratio) * 0.5
 		else
 			pos[2] = anchor_h * (1 - self.safe_area_ratio) * 0.5
@@ -903,7 +911,7 @@ function Dialogue:update(dt)
 
 	local size = Vector3(self._width, self._height, 0)
 
-	if self._render_inside then
+	if self._render_inside and self._tool  then
 		local scaled_size = self._tool:scale_to_target_dim(size)
 		local screen_width, screen_height = self._tool:get_dialogue_dimensions()
 		local x_min = 1
@@ -932,9 +940,9 @@ function Dialogue:update(dt)
 	local time
 
 	if self.paused or self.enabled == false then
-		time = self._saved_time
+		time = self._saved_time or 0
 	else
-		time = self._saved_time - dt
+		time = (self._saved_time or 0) - dt
 	end
 
 	if self._done and time <= 0 then
@@ -967,12 +975,17 @@ function Dialogue:update(dt)
 			end_pos = 1
 		end
 
-		local current_text = text_chunks[current_chunk][2]
-		local chunk_length = text_chunks[current_chunk][3]
+		local current_text
+		local chunk_length
+
+		if text_chunks[current_chunk] then
+			current_text = text_chunks[current_chunk][2]
+			chunk_length = text_chunks[current_chunk][3]
+		end
 
 		if not text_chunks[current_chunk] or current_chunk == #text_chunks and end_pos == chunk_length then
 			self._done = true
-		else
+		elseif text_chunks[current_chunk] then
 			local chunk_type = text_chunks[current_chunk][1]
 
 			time = time + self.speed
@@ -982,10 +995,10 @@ function Dialogue:update(dt)
 			elseif chunk_type == "pause" then
 				time = time + (tonumber(current_text) or 1)
 				self._previous_chunk_was_pause = true
-			elseif chunk_length < end_pos then
+			elseif chunk_length and chunk_length < end_pos then
 				current_chunk = math.min(current_chunk + 1, #text_chunks)
 				end_pos = 1
-			else
+			elseif current_text then
 				if self.pause_on_punctuation and _is_punctuation(StringEncodeAux.utf8_sub(current_text, end_pos)) then
 					time = time + 0.25
 				end
