diff --git a/scripts/game/entity_system/systems/status/status_system.lua b/scripts/game/entity_system/systems/status/status_system.lua
index eb3b3f4..4ff630a 100644
--- a/scripts/game/entity_system/systems/status/status_system.lua
+++ b/scripts/game/entity_system/systems/status/status_system.lua
@@ -456,6 +456,8 @@ function StatusSystem:update(context)
 	Profiler.start("status_statuses")
 
 	local temp_status_check = FrameTable.alloc_table()
+	local funprove_enabled = kmf.vars.funprove_enabled
+	local bugfix_enabled = kmf.vars.bugfix_enabled
 
 	for i = 1, entities_n do
 		repeat
@@ -486,6 +488,16 @@ function StatusSystem:update(context)
 				for imm, _ in pairs(internal.immunities) do
 					if mags[imm] then
 						mags[imm] = 0
+
+						-- fun-balance :: fix steam and water exclusive wetting
+						if bugfix_enabled or funprove_enabled then
+							if imm == "water" then
+								mags.steam = 0
+							elseif funprove_enabled and imm == "steam" then
+								mags.water = 0
+							end
+						end
+
 					end
 				end
 
