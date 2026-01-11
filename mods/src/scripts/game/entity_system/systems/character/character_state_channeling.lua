diff --git a/scripts/game/entity_system/systems/character/character_state_channeling.lua b/scripts/game/entity_system/systems/character/character_state_channeling.lua
index 8b178cf..33ba478 100644
--- a/scripts/game/entity_system/systems/character/character_state_channeling.lua
+++ b/scripts/game/entity_system/systems/character/character_state_channeling.lua
@@ -82,22 +82,25 @@ function CharacterStateChanneling:update(context)
 	local spellcast_extension = EntityAux.extension(unit, "spellcast")
 	local has_disruptor = false
 	local damage_receiver_ext = EntityAux.extension(unit, "damage_receiver")
+	local is_self_channeling, is_forward_channeling = kmf.get_channeling_statuses(unit)
 
 	if damage_receiver_ext then
 		has_disruptor = damage_receiver_ext.state.has_disruptor
 	end
 
 	if not has_disruptor then
-		local channel
+		local channel = nil
 
 		if context.has_keyboard then
-			if InputAux.button_triggered(input_data.spell_forward_hold, 0.5) or InputAux.button_triggered(input_data.spell_self_channel, 0) then
+			if is_forward_channeling and InputAux.button_triggered(input_data.spell_forward_hold, 0.5) then
+				channel = true
+			elseif is_self_channeling and InputAux.button_triggered(input_data.spell_self_channel, 0) then
 				channel = true
 			end
 		elseif input_data.spell_forward then
 			local len = math.sqrt(input_data.spell_forward[1] * input_data.spell_forward[1] + input_data.spell_forward[2] * input_data.spell_forward[2])
 
-			if len >= SpellSettings.right_stick_chargeup_release_threashold or input_data.spell_self_channel > 0 then
+			if SpellSettings.right_stick_chargeup_release_threashold <= len or (input_data.spell_self_channel > 0 and is_self_channeling) then
 				channel = true
 			end
 		end
@@ -115,7 +118,7 @@ function CharacterStateChanneling:update(context)
 		local has_lightning = false
 		local spells = spellcast_extension.internal.spells
 
-		for i = 1, #spells do
+		for i = 1, #spells, 1 do
 			if spells[i] == "Lightning" or spells[i] == "LightningAoe" then
 				has_lightning = true
 
@@ -125,7 +128,6 @@ function CharacterStateChanneling:update(context)
 
 		if has_lightning then
 			local tkey = FrameTable.alloc_table()
-
 			tkey.conjure_electrify_self = true
 
 			EntityAux.set_input(unit, "ability_user", "start_ability", tkey)
@@ -173,7 +175,7 @@ function CharacterStateChanneling:update(context)
 		csm:change_state("knocked_down")
 
 		return
-	elseif internal.loco_ext and internal.loco_ext.state.time_flying > internal.airtime then
+	elseif internal.loco_ext and internal.airtime < internal.loco_ext.state.time_flying then
 		set_input_by_extension(spellcast_extension, "channel", false)
 		csm:change_state("inair")
 
@@ -203,16 +205,14 @@ function CharacterStateChanneling:update(context)
 	local anim_unit = internal.animation_unit
 
 	if self.handle_complex_animations then
-		local _anim
+		local _anim = nil
 		local _dbg_pre = "CharacterStateChanneling:update() - "
 
 		if loco_ext and anim_unit then
 			local velocity = Vector3.unbox(loco_ext.state.velocity)
-
 			velocity.z = 0
-
 			local velocity_length = Vector3.length(velocity)
-			local should_move = velocity_length > 0.1 and true or false
+			local should_move = (velocity_length > 0.1 and true) or false
 
 			if should_move and not loco_ext.input.disabled then
 				_anim = CSM_complex_channeling_spells[self.anim_type][1]
