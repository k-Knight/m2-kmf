diff --git a/scripts/game/entity_system/systems/effect/lightning_effect.lua b/scripts/game/entity_system/systems/effect/lightning_effect.lua
index 3454c4e..a6f56fa 100644
--- a/scripts/game/entity_system/systems/effect/lightning_effect.lua
+++ b/scripts/game/entity_system/systems/effect/lightning_effect.lua
@@ -81,6 +81,7 @@ function LightningEffect:init(context)
 	self._effect_manager = context.effect_manager
 	self._owner = owner
 	self.is_standalone = context.is_standalone
+	self.kmf_color_mult = context.args.kmf_color_mult or 1
 
 	local effect_type = lightning_effects.lightning
 	local effect_hit = lightning_effects.lightning_hit
@@ -180,7 +181,7 @@ function LightningEffect:spawn()
 	local world = self._world
 	local pids = {}
 	local effect_type = self._effect_type
-	local effect_color = self._effect_color[self._color_index]:unbox()
+	local effect_color = self._effect_color[self._color_index]:unbox() * self.kmf_color_mult
 
 	if self._play_start and staff_unit then
 		pids[#pids + 1] = world:create_particles_linked(self.effect_source, staff_unit, attach, ParticleOrphanedPolicy.stop_spawning, nil, effect_color)
