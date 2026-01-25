diff --git a/scripts/game/menu2/menu_adventure_create_artifact_preset_ui.lua b/scripts/game/menu2/menu_adventure_create_artifact_preset_ui.lua
index 36859dd..e164125 100644
--- a/scripts/game/menu2/menu_adventure_create_artifact_preset_ui.lua
+++ b/scripts/game/menu2/menu_adventure_create_artifact_preset_ui.lua
@@ -114,8 +114,19 @@ local Prefabs = {
 			"artifact_list"
 		},
 		y = 0.5 * ArtifactPrefabs.artifact_detail.h
+	},
+	create_pvp_difficulty = {
+		id = "custom_pvp",
+		prefabs = {
+			"nav_confirm",
+			"artifact_difficulty_item"
+		},
+		vars = {
+			item_text = "P v P"
+		}
 	}
 }
+
 local Alias = "MenuAdventureCreateArtifactPresetUi"
 
 _MenuAdventureCreateArtifactPresetUi = class(_MenuAdventureCreateArtifactPresetUi, MenuBaseUi)
@@ -157,6 +168,15 @@ function C:update()
 end
 
 function C:on_show_menu_create_scenario_artifact_preset(direction, story, mission_name, debug_level)
+	if not self.menu_ui:find("custom_pvp") then
+		ui:push_prefabs(ArtifactPrefabs)
+
+		local new_item = ui:create(Prefabs, "create_pvp_difficulty")
+		self.menu_ui:find("difficulty_list"):append_child(new_item)
+
+		ui:pop_prefabs()
+	end
+
 	self.gamemode = "scenario"
 	self.story = story
 	self.mission_name = mission_name
@@ -167,6 +187,15 @@ function C:on_show_menu_create_scenario_artifact_preset(direction, story, missio
 end
 
 function C:on_show_menu_create_artifact_preset(direction, story, mission_name, debug_level)
+	if not self.menu_ui:find("custom_pvp") then
+		ui:push_prefabs(ArtifactPrefabs)
+
+		local new_item = ui:create(Prefabs, "create_pvp_difficulty")
+		self.menu_ui:find("difficulty_list"):append_child(new_item)
+
+		ui:pop_prefabs()
+	end
+
 	self.gamemode = "adventure"
 	self.story = story
 	self.mission_name = mission_name
@@ -200,6 +229,15 @@ function C:on_show_menu_create_artifact_preset(direction, story, mission_name, d
 end
 
 function C:on_show_menu_trial_create_artifact_preset(direction, challenge_data, from_debug)
+	if not self.menu_ui:find("custom_pvp") then
+		ui:push_prefabs(ArtifactPrefabs)
+
+		local new_item = ui:create(Prefabs, "create_pvp_difficulty")
+		self.menu_ui:find("difficulty_list"):append_child(new_item)
+
+		ui:pop_prefabs()
+	end
+
 	self.gamemode = "trial"
 	self.challenge_data = challenge_data
 	self.debug_level = from_debug
@@ -209,6 +247,13 @@ function C:on_show_menu_trial_create_artifact_preset(direction, challenge_data,
 end
 
 function C:on_show_menu_challenge_create_artifact_preset(direction, challenge_data, from_debug)
+	local pvp_difficulty_element = self.menu_ui:find("custom_pvp")
+	if pvp_difficulty_element then
+		self.menu_ui:find("difficulty_list"):remove_child(pvp_difficulty_element)
+	end
+
+	kmf.vars._MenuAdventureCreateArtifactPresetUi = self
+
 	self.gamemode = "challenge"
 	self.challenge_data = challenge_data
 	self.debug_level = from_debug
@@ -430,9 +475,19 @@ function C:on_click_create_game(evt)
 	local debug_level = self.debug_level
 	local id = evt.emitter.data.id
 
+	kmf.vars.pvp_gamemode = id == "custom_pvp"
+	if kmf.lobby_handler then
+		local msg = tostring(kmf.vars.pvp_gamemode == true)
+		local members = kmf.lobby_handler.connected_peers
+
+		for _, player_id in ipairs(members) do
+			kmf.send_kmf_msg(player_id, msg, "pvp-enbl")
+		end
+	end
+
 	if id == "familiar" then
 		-- block empty
-	elseif id == "custom" then
+	elseif id == "custom" or id == "custom_pvp" then
 		self:hide_menu("forward")
 
 		local modifiers = ArtifactManager:get_custom_artifacts(true)
