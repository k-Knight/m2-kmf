diff --git a/scripts/game/entity_system/systems/player/player_system.lua b/scripts/game/entity_system/systems/player/player_system.lua
index 4e290d8..42c59b2 100644
--- a/scripts/game/entity_system/systems/player/player_system.lua
+++ b/scripts/game/entity_system/systems/player/player_system.lua
@@ -108,6 +108,8 @@ function PlayerSystem:init(context)
 	end
 
 	self.no_defeat_mode = false
+
+	kmf.player_system = self
 end
 
 function PlayerSystem:set_no_defeat_mode(active)
@@ -420,6 +422,11 @@ function PlayerSystem:network_player_added(sender, global_player_id)
 
 		self.world_proxy:trigger_timpani_event(timpani_events.player_join_party)
 	end
+
+	--if kmf.vars.set_to_respawn_local_player then
+	--	kmf.vars.set_to_respawn_local_player = false
+	--	kmf.task_scheduler.add(kmf.resurrect_local_player)
+	--end
 end
 
 function PlayerSystem:network_player_removed(sender, global_player_id)
@@ -496,6 +503,12 @@ function PlayerSystem:update(context)
 	local entities, entities_n = self:get_entities("player")
 	local num_players_alive = self.num_players
 
+	self.timer = (self.timer or 0) + dt
+	if self.timer > 1 then
+		self.timer = 0
+		self:check_dead_players()
+	end
+
 	for i = 1, entities_n do
 		repeat
 			local extension_data = entities[i]
@@ -631,7 +644,11 @@ function PlayerSystem:register_pending_revive(sender, tag_id)
 		self.pending_revives = {}
 	end
 
-	self.pending_revives[tag_name] = true
+	if tag_name then
+		local count = (self.pending_revives[tag_name] or 0) + 1
+
+		self.pending_revives[tag_name] = count
+	end
 end
 
 function PlayerSystem:unregister_pending_revive(sender, tag_id)
@@ -645,7 +662,15 @@ function PlayerSystem:unregister_pending_revive(sender, tag_id)
 		return
 	end
 
-	self.pending_revives[tag_name] = nil
+	if tag_name then
+		local count = (self.pending_revives[tag_name] or 0) - 1
+
+		if count < 0 or count == 0 then
+			self.pending_revives[tag_name] = nil
+		else
+			self.pending_revives[tag_name] = count
+		end
+	end
 end
 
 function PlayerSystem:update_all_players_dead(entities, entities_n)
@@ -672,7 +697,79 @@ function PlayerSystem:update_all_players_dead(entities, entities_n)
 	end
 end
 
+function PlayerSystem:check_dead_players()
+	if kmf.vars.pvp_gamemode and kmf.entity_manager and kmf.lobby_handler:is_host() then
+		local players, players_n = kmf.entity_manager:get_entities("player")
+		local team_counter = {
+			evil = 0,
+			player = 0
+		}
+
+		for i = 1, players_n, 1 do
+			if players[i].unit then
+				local unit_faction
+				local unit_faction_ext = EntityAux.extension(players[i].unit, "faction")
+
+				unit_faction = unit_faction_ext and unit_faction_ext.internal.faction or "player"
+
+				if not kmf.is_player_unit_dead(players[i].unit) then
+					team_counter[unit_faction] = team_counter[unit_faction] + 1
+				end
+			end
+		end
+
+		local total_alive = 0
+		for _, alive in pairs(team_counter) do
+			total_alive = total_alive + alive
+		end
+
+		if total_alive < 1 then
+			return
+		end
+
+		if total_alive < players_n then
+			for player_team, alive in pairs(team_counter) do
+				if alive < 1 then
+					kmf.task_scheduler.add(function()
+						if kmf.vars.pvp_announce_lock then
+							return
+						end
+
+						if not kmf.vars.pvp_everyone_looses and not kmf.vars.pvp_defeat_team then
+							kmf.vars.pvp_prevent_team_res = false
+							kmf.vars.pvp_defeat_team = player_team
+
+							local msg = "defeat:" .. player_team
+							local members = kmf.lobby_handler.connected_peers
+
+							for _, player_id in ipairs(members) do
+								kmf.send_kmf_msg(player_id, msg, "pvp-announce")
+							end
+						end
+					end, 3000)
+					kmf.task_scheduler.add(function()
+						kmf.vars.pvp_everyone_looses = false
+						kmf.vars.pvp_defeat_team = nil
+
+						if not kmf.vars.pvp_prevent_team_res then
+							kmf.pvp_resurrect_team(player_team)
+							kmf.task_scheduler.add(function()
+								kmf.vars.pvp_announce_lock = false
+							end, 3000)
+						end
+					end, 7000)
+				end
+			end
+		end
+
+	end
+end
+
 function PlayerSystem:on_player_died(player, killer)
+	local player_team
+
+	self:check_dead_players()
+
 	assert(player, "player-param can't be nil !")
 
 	local player_ext = EntityAux.extension(player, "player")
