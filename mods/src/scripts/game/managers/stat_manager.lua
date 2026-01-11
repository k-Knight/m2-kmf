diff --git a/scripts/game/managers/stat_manager.lua b/scripts/game/managers/stat_manager.lua
index 1fc53c5..7ee9a5f 100644
--- a/scripts/game/managers/stat_manager.lua
+++ b/scripts/game/managers/stat_manager.lua
@@ -28,31 +28,39 @@ function StatManager:set_stat(name, value)
 end
 
 function StatManager:modify_stat(name, modifier, local_player_index)
-	if self.enabled then
-		local v = self.stats[name]
-
-		if v == nil then
-			self.stats[name] = modifier
-		else
-			self.stats[name] = v + modifier
+	local status, res = pcall(function()
+		if self.enabled then
+			local v = tonumber(self.stats[name])
+
+			if v == nil then
+				self.stats[name] = modifier
+			else
+				self.stats[name] = v + modifier
+			end
 		end
-	end
 
-	local achievement_value = AchievementManager:event_stat_modified(name, modifier, local_player_index)
+		local achievement_value = AchievementManager:event_stat_modified(name, modifier, local_player_index)
 
-	if self.enabled and achievement_value ~= nil then
-		if achievement_value > self.stats[name] then
-			self.stats[name] = achievement_value
+		if self.enabled and achievement_value ~= nil then
+			if self.stats[name] < achievement_value then
+				self.stats[name] = achievement_value
 
-			return true
-		elseif achievement_value < self.stats[name] then
-			AchievementManager:event_stat_modified(name, self.stats[name] - achievement_value, local_player_index)
+				return true
+			elseif achievement_value < self.stats[name] then
+				AchievementManager:event_stat_modified(name, self.stats[name] - achievement_value, local_player_index)
 
-			return true
+				return true
+			end
 		end
-	end
 
-	return false
+		return false
+	end)
+
+	if status then
+		return res
+	else
+		return false
+	end
 end
 
 function StatManager:get_stat(name)
@@ -83,10 +91,12 @@ function StatManager:write_to_account()
 	assert(account)
 
 	for name, value in pairs(self.stats) do
-		account:write_variable("stats", name, value)
+		pcall(function()
+			account:write_variable("stats", name, value)
+		end)
 	end
 
-	account:write_modified_values_to_backend(self.persistence_manager.transaction_manager)
+	pcall(function() account:write_modified_values_to_backend(self.persistence_manager.transaction_manager) end)
 end
 
 function StatManager:read_from_account()
@@ -101,7 +111,9 @@ function StatManager:read_from_account()
 	local remote_stats = account:get_data("stats") or {}
 
 	for name, value in pairs(remote_stats) do
-		remote_stats[name] = tonumber(value) or value
+		pcall(function()
+			remote_stats[name] = tonumber(value) or value
+		end)
 	end
 
 	self.stats = table.clone(remote_stats)
@@ -111,9 +123,10 @@ function StatManager:read_from_account()
 	AchievementManager:set_enable_unlocking(false)
 
 	for name, value in pairs(self.stats) do
-		local stat_missmatch = self:modify_stat(name, 0)
-
-		one_or_many_stat_missmatchs = one_or_many_stat_missmatchs or stat_missmatch
+		pcall(function()
+			local stat_missmatch = self:modify_stat(name, 0)
+			one_or_many_stat_missmatchs = one_or_many_stat_missmatchs or stat_missmatch
+		end)
 	end
 
 	AchievementManager:set_enable_unlocking(true)
