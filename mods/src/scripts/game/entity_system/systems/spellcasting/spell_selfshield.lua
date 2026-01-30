diff --git a/scripts/game/entity_system/systems/spellcasting/spell_selfshield.lua b/scripts/game/entity_system/systems/spellcasting/spell_selfshield.lua
index a226fe9..c97e433 100644
--- a/scripts/game/entity_system/systems/spellcasting/spell_selfshield.lua
+++ b/scripts/game/entity_system/systems/spellcasting/spell_selfshield.lua
@@ -3,15 +3,41 @@
 local EntityAux_set_input = EntityAux.set_input
 local EntityAux_set_input_by_extension = EntityAux.set_input_by_extension
 local Unit_set_data = Unit.set_data
-local SHIELD_SELF_DECAY = SpellSettings.shield_self_decay or 1
-local SHIELD_SELF_DECAY_RATE = SpellSettings.shield_self_decay_rate or 1
 local DECAY_AFTER_HEAL_TIME = SpellSettings.pure_shield_decay_after_heal_time
 local DECAY_AFTER_SPAWN_TIME = SpellSettings.pure_shield_decay_after_spawn_time
 local PURE_SHIELD_MIN_DECAY = SpellSettings.pure_shield_min_decay
 
 Spells_SelfShield = {
 	init = function(context, shield_type)
-		local elements = context.elements
+		local elements = table.deep_clone(context.elements)
+
+		-- fun-balance :: self-shield require animation finish befere cast
+		if not kmf.vars.funprove_enabled then
+			return Spells_SelfShield._old_init({}, context, shield_type, elements)
+		else
+			local caster = context.caster
+			local data = {}
+
+			data.kmf_elements = elements
+			data.kmf_status = 0
+			data.kmf_context = context
+			data.kmf_shield_type = shield_type
+			data.kmf_time_to_cast = 0.25
+			data.kmf_spell_init_data_time = kmf.world_proxy:time()
+			data.kmf_context = {}
+
+			for k, v in pairs(context) do
+				data.kmf_context[k] = v
+			end
+			data.kmf_context.elements = data.kmf_elements
+
+			EntityAux.set_input(caster, "character", CSME.spell_cast, true)
+			EntityAux.set_input(caster, "character", "args", "cast_force_shield")
+
+			return data, false
+		end
+	end,
+	_old_init = function(data, context, shield_type, elements)
 		local world = context.world
 		local caster = context.caster
 		local pvm = context.player_variable_manager
@@ -48,17 +74,16 @@ Spells_SelfShield = {
 
 		internal.changed = true
 
-		if is_forced_by then
-			local mh = SpellSettings:pure_shield_max_health("self")
 
-			internal.health, internal.max_health = mh, mh
+		if is_forced_by then
+			local mh = SpellSettings:pure_shield_max_health(pvm, caster, "self")
+			internal.max_health = mh
+			internal.health = mh
 		else
 			local new_health = SpellSettings:pure_shield_health(pvm, caster, "self")
-
 			internal.health = new_health
 
 			local max_health = SpellSettings:pure_shield_max_health(pvm, caster, "self")
-
 			internal.max_health = max_health
 		end
 
@@ -83,13 +108,11 @@ Spells_SelfShield = {
 			_sound_id = nil
 		end
 
-		local data = {
-			elements = elements,
-			sound_id = _sound_id,
-			shield_ext = shield_ext,
-			damage_ext = damage_ext,
-			caster = caster
-		}
+		data.elements = elements
+		data.sound_id = _sound_id
+		data.shield_ext = shield_ext
+		data.damage_ext = damage_ext
+		data.caster = caster
 
 		EntityAux_set_input(caster, "selfshield", "stop", nil)
 		EntityAux_set_input(caster, "selfshield", "start", true)
@@ -120,7 +143,7 @@ Spells_SelfShield = {
 
 		return data, true
 	end,
-	on_cancel = function(data, context)
+	on_cancel = function (data, context, do_not_notify)
 		local caster = data.caster
 
 		Unit_set_data(caster, "spray_blocker", nil)
@@ -170,11 +193,30 @@ Spells_SelfShield = {
 			context.network:send_cancel_spell(caster, "SelfShield")
 			context.network:send_sync_self_shield(caster, false)
 		end
+
+		if do_not_notify ~= true and kmf.vars.funprove_enabled then
+			context.network:send_cancel_armor_component(caster, "shield")
+		end
+
+		local time = os.clock()
+
+		if data and data.damage_ext then
+			data.damage_ext.state.selfshielded_end = time
+		end
 	end,
 	waiting_spell_update = function(data, context)
-		return Spells_SelfShield.update(data, context)
+		if data.kmf_status ~= 0 then
+			return Spells_SelfShield.update(data, context)
+		end
 	end,
 	update = function(data, context)
+		if data.kmf_status == 0 then
+			Spells_SelfShield._old_init(data, data.kmf_context, data.kmf_shield_type, data.kmf_elements)
+			data.kmf_status = 1
+
+			return true
+		end
+
 		local dt = context.dt
 		local shield_ext = data.shield_ext
 		local internal = shield_ext.internal
@@ -190,6 +232,10 @@ Spells_SelfShield = {
 					dmg = 0
 				end
 
+				if element == "water_push" or element == "water_elevate" then
+					dmg = dmg * 0.6
+				end
+
 				if dmg and dmg > 0 then
 					dmg = dmg * (data.resistances and data.resistances[element] or 1)
 				end
@@ -207,6 +253,8 @@ Spells_SelfShield = {
 
 		if decay_allowed then
 			local det_timer = internal.deteriorate_timer + dt
+			local SHIELD_SELF_DECAY = SpellSettings.shield_self_decay or 1
+			local SHIELD_SELF_DECAY_RATE = SpellSettings.shield_self_decay_rate or 1
 
 			if det_timer >= SHIELD_SELF_DECAY_RATE then
 				det_timer = det_timer - SHIELD_SELF_DECAY_RATE
