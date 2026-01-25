diff --git a/scripts/game/entity_system/systems/effect/effect_system.lua b/scripts/game/entity_system/systems/effect/effect_system.lua
index 8c517a2..d397136 100644
--- a/scripts/game/entity_system/systems/effect/effect_system.lua
+++ b/scripts/game/entity_system/systems/effect/effect_system.lua
@@ -33,6 +33,7 @@ function EffectSystem:init(context)
 
 	self:register_events(unpack(events))
 	self:register_network_messages("stop_effect_descriptor", "network_synced_projectile_hit", "stop_network_synced_projectile")
+	kmf.effect_system = self
 end
 
 function EffectSystem:finalize_setup(context)
@@ -190,12 +191,33 @@ function EffectSystem:update(context)
 
 	local effect_context = self._effect_context
 	local entities, entities_n = self:get_entities("effect_producer")
+	local fix_enabled = kmf.vars.bugfix_enabled
 
 	for i = 1, entities_n do
 		local extension_data = entities[i]
 		local u, extension = extension_data.unit, extension_data.extension
 		local input = extension.input
 
+		if input.new_effects then
+			local new_effects = {}
+
+			for _, v in pairs(input.new_effects) do
+				new_effects[#new_effects + 1] = v
+			end
+
+			input.new_effects = new_effects
+		end
+
+		if input.stop_effects and fix_enabled then
+			local stop_effects = {}
+
+			for _, v in pairs(input.stop_effects) do
+				stop_effects[#stop_effects + 1] = v
+			end
+
+			input.stop_effects = stop_effects
+		end
+
 		if #input.stop_effects > 0 then
 			local failed_to_destroy = em:destroy_effects(u, input.stop_effects)
 
