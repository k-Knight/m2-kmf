diff --git a/scripts/game/managers/profile_manager.lua b/scripts/game/managers/profile_manager.lua
index 3ea98a6..b361a9f 100644
--- a/scripts/game/managers/profile_manager.lua
+++ b/scripts/game/managers/profile_manager.lua
@@ -59,6 +59,10 @@ function ProfileManager:get_player_name(index, queued_controller)
 			self.usernames[index] = base_name
 		end
 
+		if not is_guest then
+			kmf.vars.player_names[kmf.const.me_peer] = self.usernames[index]
+		end
+
 		return self.usernames[index]
 	else
 		local steam_name = Application.have_steam() and Steam.user_name()
@@ -80,6 +84,10 @@ function ProfileManager:get_player_name(index, queued_controller)
 			base_name = steam_name
 		end
 
+		if not is_guest then
+			kmf.vars.player_names[kmf.const.me_peer] = base_name
+		end
+
 		return base_name, extended_name
 	end
 end
