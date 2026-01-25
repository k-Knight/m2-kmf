diff --git a/scripts/game/util/challenge_updater.lua b/scripts/game/util/challenge_updater.lua
index 8245f4a..468d8a3 100644
--- a/scripts/game/util/challenge_updater.lua
+++ b/scripts/game/util/challenge_updater.lua
@@ -13,7 +13,9 @@ local DEBUG_PRECALCING = false
 local USE_PHASE_DELAY_AS_TIMER = true
 
 function ChallengeUpdater:init(is_official, phases_data, utilities, score_limit, time_limit, challenge_init_data, num_players, is_trial)
-	assert(num_players ~= nil and type(num_players) == "number" and num_players > 0, "param num_players is invalid !")
+	if num_players == nil or type(num_players) ~= "number" or num_players <= 0 then
+		return
+	end
 
 	self.is_trial = is_trial or false
 
@@ -76,7 +78,9 @@ function ChallengeUpdater:init(is_official, phases_data, utilities, score_limit,
 end
 
 function ChallengeUpdater:set_num_players(num_players)
-	assert(num_players ~= nil and type(num_players) == "number" and num_players > 0, "param num_players is invalid !")
+	if num_players == nil or type(num_players) ~= "number" or num_players <= 0 then
+		return
+	end
 
 	if num_players > self.max_num_players then
 		yellow_text("*** ChallengeUpdater:set_num_players( " .. tostring(num_players) .. " ) > " .. tostring(self.max_num_players) .. ", will recalc phases healths ***")
@@ -238,6 +242,10 @@ function ChallengeUpdater:handle_player_died(killed_player)
 end
 
 function ChallengeUpdater:handle_time_change_event(event_message, time_value)
+	if kmf.vars.pvp_gamemode then
+		return
+	end
+
 	assert(self.has_time_limit, "Should only ever happen on TimeChallenges !")
 	assert(type(time_value) == "number", "time_value needs to be a number !")
 
@@ -330,6 +338,10 @@ function ChallengeUpdater:handle_character_killed_character(killed_character, ki
 end
 
 function ChallengeUpdater:on_challenge_unit_spawned(u)
+	if kmf.vars.pvp_gamemode then
+		return
+	end
+
 	local assert_msg = "[ChallengeUpdater:on_challenge_unit_spawned] (phase " .. tostring(self.current_phase) .. ") - "
 
 	assert(u, assert_msg .. " u == NIL !")
@@ -353,6 +365,10 @@ function ChallengeUpdater:on_challenge_unit_spawned(u)
 end
 
 function ChallengeUpdater:force_phase(phase)
+	if kmf.vars.pvp_gamemode then
+		return
+	end
+
 	assert(phase ~= nil and phase > 0 and phase <= self.num_phases, "ChallengeUpdater:force_phase( " .. (phase and tostring(phase) or "NIL") .. " ) - Invalid param, it's either NIL or lower than 1 or higher than " .. self.num_phases .. " !")
 
 	self.this_phase_dead_units = nil
@@ -369,6 +385,10 @@ function ChallengeUpdater:force_phase(phase)
 end
 
 function ChallengeUpdater:phase_should_have_progressbar(phase_index)
+	if kmf.vars.pvp_gamemode then
+		return false
+	end
+
 	if self.is_official and self.has_time_limit and (self.phases_data == nil or self.phases_data[phase_index] == nil) then
 		return false
 	end
@@ -396,6 +416,10 @@ function ChallengeUpdater:phase_should_have_progressbar(phase_index)
 end
 
 function ChallengeUpdater:phase_has_victory_cond(phase, cond)
+	if kmf.vars.pvp_gamemode then
+		return false
+	end
+
 	if phase == nil then
 		red_text("\t\tChallengeUpdater:phase_has_victory_cond() Phase was NIL, \n\t\tsomeone should look in to why that is, \n\t\tAre we perhaps working on a reference to a collection of phases, \n\t\tthat are now shorter then when we first got it ?\n\t\t")
 
@@ -432,12 +456,20 @@ function ChallengeUpdater:phase_has_victory_cond(phase, cond)
 end
 
 function ChallengeUpdater:sync_phase_data()
+	if kmf.vars.pvp_gamemode then
+		return
+	end
+
 	local phase_name = self:get_phase_name(self.current_phase)
 
 	self:invoke_callback("set_phase_data", self.current_phase, phase_name)
 end
 
 function ChallengeUpdater:get_phase_name(phase_index)
+	if kmf.vars.pvp_gamemode then
+		return ""
+	end
+
 	if self.is_official and self.has_time_limit and (self.phases_data == nil or self.phases_data[phase_index] == nil) then
 		return ""
 	end
@@ -448,6 +480,10 @@ function ChallengeUpdater:get_phase_name(phase_index)
 end
 
 function ChallengeUpdater:start()
+	if kmf.vars.pvp_gamemode then
+		return
+	end
+
 	assert(self.current_phase == nil or self.current_phase == 0, "start() called when current_phase == " .. tostring(self.current_phase))
 
 	self.tagged_units_this_phase = nil
@@ -501,6 +537,10 @@ function ChallengeUpdater:start()
 end
 
 function ChallengeUpdater:on_new_phase()
+	if kmf.vars.pvp_gamemode then
+		return
+	end
+
 	self.tagged_units_this_phase = nil
 	self.all_units_are_dead = true
 
@@ -587,6 +627,9 @@ function ChallengeUpdater:update_action_collections(action_collections, internal
 end
 
 function ChallengeUpdater:update_phases(dt)
+	if kmf.vars.pvp_gamemode then
+		return
+	end
 	if self.all_phases_done then
 		return
 	end
@@ -599,6 +642,9 @@ function ChallengeUpdater:update_phases(dt)
 
 	local _phase = self.phases_data[self.current_phase]
 
+	if not _phase then
+		return
+	end
 	assert(_phase, "[ChallengeUpdater] - No phase for current_phase (" .. (self.current_phase and tostring(self.current_phase) or "NIL") .. ")")
 
 	if not USE_PHASE_DELAY_AS_TIMER and _phase.delay ~= nil and _phase.delay > 0 then
@@ -719,6 +765,10 @@ function ChallengeUpdater:try_remove_tagged_unit(u)
 end
 
 function ChallengeUpdater:update_progress_bar(dt)
+	if kmf.vars.pvp_gamemode then
+		return
+	end
+
 	if self.tagged_units_this_phase and not self.all_units_are_dead then
 		if self.update_progress_timer >= UPDATE_PROGRESS_TIME then
 			self.update_progress_timer = self.update_progress_timer - UPDATE_PROGRESS_TIME
@@ -853,6 +903,10 @@ function ChallengeUpdater:resume()
 end
 
 function ChallengeUpdater:pause_timer()
+	if kmf.vars.pvp_gamemode then
+		return
+	end
+
 	if not self.elapsed_time_paused then
 		yellow_text("Pausing elapsed_time-timer.")
 	end
@@ -861,6 +915,10 @@ function ChallengeUpdater:pause_timer()
 end
 
 function ChallengeUpdater:resume_timer()
+	if kmf.vars.pvp_gamemode then
+		return
+	end
+
 	if self.elapsed_time_paused then
 		yellow_text("Starting/Resuming elapsed_time-timer.")
 	end
@@ -877,6 +935,10 @@ function ChallengeUpdater:is_elapsed_time_paused()
 end
 
 function ChallengeUpdater:restart(phases_data)
+	if kmf.vars.pvp_gamemode then
+		return
+	end
+
 	cat_print("challenges", "ChallengeUpdater:restart()")
 
 	self.paused = false
@@ -916,6 +978,10 @@ function ChallengeUpdater:restart(phases_data)
 end
 
 function ChallengeUpdater:update(dt)
+	if kmf.vars.pvp_gamemode then
+		return
+	end
+
 	if self.paused then
 		return
 	end
