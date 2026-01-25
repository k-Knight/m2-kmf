diff --git a/scripts/game/managers/localization_manager.lua b/scripts/game/managers/localization_manager.lua
index 0b7fa4e..e2ba26b 100644
--- a/scripts/game/managers/localization_manager.lua
+++ b/scripts/game/managers/localization_manager.lua
@@ -373,6 +373,11 @@ function LocalizationManager:lookup(text_id, no_error)
 		return ""
 	end
 
+	local kmf_tag_start, kmf_tag_end = string.find(text_id, "[KMF]", 1, true)
+	if kmf_tag_start and kmf_localisation_lookup then
+		return kmf_localisation_lookup(string.sub(text_id, kmf_tag_end + 1, #text_id))
+	end
+
 	text = Localizer.lookup(self.loc, text_id)
 
 	if not no_error then
