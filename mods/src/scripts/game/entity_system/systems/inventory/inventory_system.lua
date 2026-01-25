diff --git a/scripts/game/entity_system/systems/inventory/inventory_system.lua b/scripts/game/entity_system/systems/inventory/inventory_system.lua
index 92d6bdb..5901ab5 100644
--- a/scripts/game/entity_system/systems/inventory/inventory_system.lua
+++ b/scripts/game/entity_system/systems/inventory/inventory_system.lua
@@ -77,6 +77,9 @@ function InventorySystem:init(context)
 	}
 
 	self:register_named_network_messages(network_messages)
+
+	setmetatable(AbilityTemplates, kmf.const.item_ability_proxy)
+
 	self:add_ability_template(RobeSettings.robes)
 	self:add_ability_template(StaffSettings.staffs)
 	self:add_ability_template(WeaponSettings.weapons)
@@ -232,7 +235,7 @@ function InventorySystem:on_extensions_added(u, extension_name, extension)
 		}
 		local robe, sword, staff, voice = extension.robe, extension.sword, extension.staff, extension.voice
 
-		extension.robe, extension.sword, extension.staff, extension.voice = nil
+		extension.robe, extension.sword, extension.staff, extension.voice = nil, nil, nil, nil
 
 		local us = self.unit_spawner
 		local world = self.world_proxy
@@ -507,8 +510,7 @@ function InventorySystem:add_ability_template(settings)
 		for k, v in pairs(data) do
 			if k == "item_ability" then
 				for ability_name, ability_data in pairs(v) do
-					AbilityTemplates[ability_name] = ability_data
-
+					kmf.const.orig_unlock_item_abilities[ability_name] = ability_data
 					break
 				end
 			end
