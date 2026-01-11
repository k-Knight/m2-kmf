diff --git a/foundation/scripts/util/unit_aux.lua b/foundation/scripts/util/unit_aux.lua
index 1b8c2ef..9fea6dc 100644
--- a/foundation/scripts/util/unit_aux.lua
+++ b/foundation/scripts/util/unit_aux.lua
@@ -129,6 +129,14 @@ function UnitAux.local_position(unit, node)
 end
 
 function UnitAux.world_position(unit, node)
+	if (unit == nil) then
+		if kmf.camera_proxy then
+			return kmf.camera_proxy:world_position()
+		else
+			return nil
+		end
+	end
+
 	if type(node) == "string" then
 		return Unit.world_position(unit, Unit.node(unit, node))
 	else