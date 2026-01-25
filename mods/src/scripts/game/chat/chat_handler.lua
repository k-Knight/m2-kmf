diff --git a/scripts/game/chat/chat_handler.lua b/scripts/game/chat/chat_handler.lua
index 31eb73f..0b19385 100644
--- a/scripts/game/chat/chat_handler.lua
+++ b/scripts/game/chat/chat_handler.lua
@@ -5,6 +5,10 @@ require("scripts/game/chat/chat_buffer")
 ChatHandler = class(ChatHandler)
 
 function ChatHandler:init(player_manager)
+	if rawget(_G, "kmf") ~= nil then
+		kmf.chat_handler = self
+	end
+
 	self.buffer = ChatBuffer(100)
 	self.lobby = nil
 	self.player_manager = player_manager
@@ -118,7 +122,7 @@ function ChatHandler:send_chat_msg(message, custom_msg, system_msg)
 
 	local chunk_start = 1
 	local chunk_stop = math.min(CHUNK_SIZE, message_size)
-	local peers = self.lobby:get_peers()
+	local me_peer = kmf.const.me_peer
 
 	repeat
 		local utf8_end = StringEncodeAux.utf8_end(message, chunk_stop)
@@ -127,9 +131,17 @@ function ChatHandler:send_chat_msg(message, custom_msg, system_msg)
 		chunk_start = utf8_end + 1
 		chunk_stop = math.min(chunk_start + CHUNK_SIZE - 1, message_size)
 
-		for _, peer in pairs(peers) do
-			RPC.rpc_chat_message(peer, system_msg, custom_msg, message_chunk)
-		end
+		self:rpc_chat_message(me_peer, system_msg, custom_msg, message_chunk)
+
+		kmf.task_scheduler.add(function()
+			local peers = self.lobby:get_peers()
+
+			for _, peer in pairs(peers) do
+				if peer ~= me_peer then
+					RPC.rpc_chat_message(peer, system_msg, custom_msg, message_chunk)
+				end
+			end
+		end, 100)
 	until message_size < chunk_start
 end
 
@@ -160,5 +172,10 @@ function ChatHandler:get_peer_info(peer)
 		end
 	end
 
+	local kmf_name = kmf.vars.player_names[peer]
+	if type(kmf_name) == "string" then
+		return kmf_name, -2
+	end
+
 	return "N/A", -1
 end
