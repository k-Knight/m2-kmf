diff --git a/scripts/game/entity_system/systems/locomotion/locomotion_system.lua b/scripts/game/entity_system/systems/locomotion/locomotion_system.lua
index 16682c8..02792b2 100644
--- a/scripts/game/entity_system/systems/locomotion/locomotion_system.lua
+++ b/scripts/game/entity_system/systems/locomotion/locomotion_system.lua
@@ -596,6 +596,7 @@ function update_locomotion_controllers(loco_controllers, loco_controllers_n, dt,
 				assert(input.add_rotation_speed ~= 0, "Bad rotation smooth set.")
 
 				state.rotation_speed = state.rotation_speed * input.add_rotation_speed
+				kmf.on_locomotion_rotation_speed_update(u, extension)
 				input.add_rotation_speed = nil
 			end
 
