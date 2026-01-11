diff --git a/scripts/game/menu2/artifact_aux.lua b/scripts/game/menu2/artifact_aux.lua
index 7e5c530..bc35b93 100644
--- a/scripts/game/menu2/artifact_aux.lua
+++ b/scripts/game/menu2/artifact_aux.lua
@@ -144,7 +144,7 @@ function ArtifactAux.string_to_modifiers(custom_artifact_setting)
 		local modifier_name = NetworkLookup.artifact_modifiers[tonumber(modifiers[i])]
 
 		if modifier_name == nil or modifier_name == "" then
-			cat_print("ArtifactAux", "No modifiers set, will be ignored !")
+			--cat_print("ArtifactAux", "No modifiers set, will be ignored !")
 		else
 			mods[modifier_name] = {
 				level = tonumber(modifiers[i + 1])
