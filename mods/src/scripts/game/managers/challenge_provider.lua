diff --git a/scripts/game/managers/challenge_provider.lua b/scripts/game/managers/challenge_provider.lua
index c1f4e38..bb362a7 100644
--- a/scripts/game/managers/challenge_provider.lua
+++ b/scripts/game/managers/challenge_provider.lua
@@ -23,7 +23,7 @@ end
 
 function ChallengeProvider:load()
 	self._official_challenge_data = CompiledChallenges.load_all_data()
-	self._custom_challenge_data = {}
+	self._custom_challenge_data = CompiledChallenges.load_all_data(true)
 end
 
 function ChallengeProvider:loaded()
@@ -74,11 +74,16 @@ function ChallengeProvider:get_all_init_data()
 	return official, custom
 end
 
-function ChallengeProvider:get_data(challenge_id)
+function ChallengeProvider:get_data(challenge_id, force_custom)
 	assert(challenge_id)
 
-	local official = true
-	local data = self._official_challenge_data[challenge_id]
+	local official
+	local data
+
+	if not force_custom then
+		official = true
+		data = self._official_challenge_data[challenge_id]
+	end
 
 	if not data then
 		data = self._custom_challenge_data[challenge_id]
@@ -90,8 +95,8 @@ function ChallengeProvider:get_data(challenge_id)
 	return data, official
 end
 
-function ChallengeProvider:get_init_data(challenge_id)
-	local data, is_official = self:get_data(challenge_id)
+function ChallengeProvider:get_init_data(challenge_id, force_custom)
+	local data, is_official = self:get_data(challenge_id, force_custom)
 
 	if not data then
 		return nil, false
