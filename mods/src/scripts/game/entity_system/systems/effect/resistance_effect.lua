diff --git a/scripts/game/entity_system/systems/effect/resistance_effect.lua b/scripts/game/entity_system/systems/effect/resistance_effect.lua
index 50751f4..83c7673 100644
--- a/scripts/game/entity_system/systems/effect/resistance_effect.lua
+++ b/scripts/game/entity_system/systems/effect/resistance_effect.lua
@@ -43,7 +43,7 @@ local function sort_elements(elements)
 	local sorted = {}
 
 	for elem, amt in pairs(elements) do
-		if amt > 0 then
+		if elem ~= nil and ELEMENT_RINGS_ORDER[elem] ~= nil and amt ~= nil and amt > 0 then
 			sorted[#sorted + 1] = {
 				amt = amt,
 				pref = ELEMENT_RINGS_ORDER[elem],
