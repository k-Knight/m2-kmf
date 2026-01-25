diff --git a/scripts/game/managers/encounter_manager.lua b/scripts/game/managers/encounter_manager.lua
index 1405897..c8eb1e0 100644
--- a/scripts/game/managers/encounter_manager.lua
+++ b/scripts/game/managers/encounter_manager.lua
@@ -64,9 +64,16 @@ function EncounterManager:add_encounter_unit(sender, unit_id)
 
 	local unit = self.unit_storage:unit(unit_id)
 
-	assert(Unit.alive(unit), "Add Encounter Unit: Trying to add dead unit!")
+	if not Unit.alive(unit) then
+		return
+	end
+
+	--assert(Unit.alive(unit), "Add Encounter Unit: Trying to add dead unit!")
 
 	local health_ext = EntityAux.extension(unit, "health")
+	if not health_ext then
+		return
+	end
 
 	self.encounter_units[unit_id] = {
 		unit = unit,
@@ -107,6 +114,9 @@ function EncounterManager:sync_encounter_unit(sender, unit_id)
 
 	if Unit.alive(unit) then
 		local health_ext = EntityAux.extension(unit, "health")
+		if not health_ext then
+			return
+		end
 
 		self.encounter_units[unit_id] = {
 			unit = unit,
