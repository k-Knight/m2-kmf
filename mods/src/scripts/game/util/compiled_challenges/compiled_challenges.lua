diff --git a/scripts/game/util/compiled_challenges/compiled_challenges.lua b/scripts/game/util/compiled_challenges/compiled_challenges.lua
index c8ebc6e..bccccc8 100644
--- a/scripts/game/util/compiled_challenges/compiled_challenges.lua
+++ b/scripts/game/util/compiled_challenges/compiled_challenges.lua
@@ -27,7 +27,7 @@ CompiledChallenges = CompiledChallenges or {}
 
 local _compiled_challenge_data = _compiled_challenge_data or {}
 
-function CompiledChallenges.load_data(challenge_id)
+function CompiledChallenges.load_data(challenge_id, prefer_modified)
 	if _compiled_challenge_data[challenge_id] then
 		return table.deep_clone(_compiled_challenge_data[challenge_id])
 	else
@@ -37,10 +37,19 @@ function CompiledChallenges.load_data(challenge_id)
 
 		_compiled_challenge_data[challenge_id] = {}
 
-		local sucess, errors = ChallengeAux.load_challenge_from_xml(_compiled_challenge_data[challenge_id], CH.xml)
+		local sucess, errors = ChallengeAux.load_challenge_from_xml(_compiled_challenge_data[challenge_id], (prefer_modified and CH.xml2 ~= nil) and CH.xml2 or CH.xml)
 
 		if not sucess or errors then
-			assert(false, "compiled challenge '" .. challenge_id .. "' failed to parse !")
+			print("[challenge parse error] compiled challenge '" .. challenge_id .. "' failed to parse !")
+			if type(errors) == "table" then
+				for k, v in pairs(errors) do
+					print("    " .. tostring(k) .. " :: " .. tostring(v))
+				end
+			else
+				print(errors)
+			end
+
+			return nil
 		end
 
 		return table.deep_clone(_compiled_challenge_data[challenge_id])
@@ -51,15 +60,17 @@ function CompiledChallenges.clear_full_data()
 	_compiled_challenge_data = {}
 end
 
-function CompiledChallenges.load_all_data()
+function CompiledChallenges.load_all_data(prefer_modified)
 	if _compiled_challenge_data == nil then
 		_compiled_challenge_data = {}
 	end
 
 	for challenge_id, _ in pairs(challenges) do
-		local data = CompiledChallenges.load_data(challenge_id, nil)
+		local data = CompiledChallenges.load_data(challenge_id, prefer_modified)
 
-		_compiled_challenge_data[challenge_id] = data
+		if data then
+			_compiled_challenge_data[challenge_id] = data
+		end
 	end
 
 	return _compiled_challenge_data
