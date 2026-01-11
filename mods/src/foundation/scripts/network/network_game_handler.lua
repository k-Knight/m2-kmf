diff --git a/foundation/scripts/network/network_game_handler.lua b/foundation/scripts/network/network_game_handler.lua
index b383bc7..98d6268 100644
--- a/foundation/scripts/network/network_game_handler.lua
+++ b/foundation/scripts/network/network_game_handler.lua
@@ -53,6 +53,7 @@ end
 NetworkGameHandler = class(NetworkGameHandler)
 
 function NetworkGameHandler:init(network_lookup, server_id, lobby, event_delegate)
+	kmf.network_game_handler = self
 	self.own_network_id = Network_peer_id()
 
 	local local_mode = NetworkHandlerAux.get_local_mode()
@@ -73,6 +74,10 @@ function NetworkGameHandler:init(network_lookup, server_id, lobby, event_delegat
 end
 
 function NetworkGameHandler:shutdown()
+	kmf.destroy_gamepad_aiming()
+	kmf.unit_spawner = nil
+	kmf.world_proxy = nil
+
 	if self.unit_spawner then
 		self.unit_spawner:unregister_network_messages()
 	end
@@ -175,6 +180,9 @@ function NetworkGameHandler:start(world_proxy, object_settings, object_types, ne
 
 	self.go_event_broadcaster = event_broadcaster
 	self.unit_spawner = NetworkUnitSpawner(self.game, self.lobby, world_proxy, entity_manager, unit_storage, network_message_router, event_broadcaster, self.network_lookup.husks_hash, object_settings, object_types, network_game_object_initializers, network_game_object_sync_settings.sync_settings)
+	kmf.destroy_gamepad_aiming()
+	kmf.unit_spawner = self.unit_spawner
+	kmf.world_proxy = world_proxy
 
 	self:set_world(world_proxy:world())
 
@@ -369,6 +377,12 @@ function NetworkGameHandler:remove_client(client, reason)
 	GameSession_remove_peer(game, client)
 end
 
+function NetworkGameHandler:transmit_message_me(message, ...)
+	local self_id = self.own_network_id
+
+	self.message_router:transmit(message, self_id, ...)
+end
+
 function NetworkGameHandler:transmit_message_all(message, ...)
 	self:transmit_all_except_me(message, ...)
 
