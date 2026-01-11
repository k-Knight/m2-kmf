diff --git a/scripts/game/entity_system/systems/spellcasting/spell_armorward.lua b/scripts/game/entity_system/systems/spellcasting/spell_armorward.lua
index 4b2829f..13398a3 100644
--- a/scripts/game/entity_system/systems/spellcasting/spell_armorward.lua
+++ b/scripts/game/entity_system/systems/spellcasting/spell_armorward.lua
@@ -6,53 +6,101 @@ require("scripts/game/entity_system/systems/spellcasting/spell_ward")
 Spells_ArmorWard = {
 	init = function(context)
 		local data = {}
-		local elements = context.elements
+		local elements = table.deep_clone(context.elements)
+
+		-- fun-balance :: armor-ward require animation finish befere cast
+		if not kmf.vars.funprove_enabled then
+			assert(elements.shield == 1, "Spells_ArmorWard must have exactly one shield-element !")
+	
+			if elements.earth + elements.ice >= 1 then
+				data.armor_data = Spells_SelfArmor.init(context)
+			end
+	
+			local n_ward_elements = (elements.fire or 0) + (elements.cold or 0) + (elements.life or 0) + (elements.arcane or 0) + (elements.water or 0) + (elements.steam or 0) + (elements.lightning or 0) + (elements.poison or 0)
+	
+			if n_ward_elements >= 1 then
+				data.ward_data = Spells_Ward.init(context)
+			end
+	
+			return data
+		else
+			local caster = context.caster
 
-		assert(elements.shield == 1, "Spells_ArmorWard must have exactly one shield-element !")
+			data.kmf_elements = elements
+			data.kmf_status = 0
+			data.kmf_context = {}
+			data.kmf_time_to_cast = 0.25
+			data.kmf_spell_init_data_time = kmf.world_proxy:time()
 
-		if elements.earth + elements.ice >= 1 then
-			data.armor_data = Spells_SelfArmor.init(context)
-		end
+			for k, v in pairs(context) do
+				data.kmf_context[k] = v
+			end
+			data.kmf_context.elements = data.kmf_elements
 
-		local n_ward_elements = (elements.fire or 0) + (elements.cold or 0) + (elements.life or 0) + (elements.arcane or 0) + (elements.water or 0) + (elements.steam or 0) + (elements.lightning or 0) + (elements.poison or 0)
+			EntityAux.set_input(caster, "character", CSME.spell_cast, true)
+			EntityAux.set_input(caster, "character", "args", "cast_force_shield")
 
-		if n_ward_elements >= 1 then
-			data.ward_data = Spells_Ward.init(context)
+			return data, false
 		end
-
-		return data
 	end,
 	on_cast = function(data, context)
 		if data.armor_data then
+			if data.kmf_status == 0 then
+				data.kmf_need_on_cast = true
+			end
+
 			Spells_SelfArmor.on_cast(data.armor_data, context)
 		end
 	end,
 	update = function(data, context)
-		local keep_armor = true
+		if data.kmf_status == 0 then
+			local elements = data.kmf_elements
+			local old_context = data.kmf_context
 
-		if data.armor_data then
-			keep_armor = Spells_SelfArmor.update(data.armor_data, context)
+			if elements.earth + elements.ice >= 1 then
+				data.armor_data = Spells_SelfArmor.init(old_context)
+			end
+	
+			local n_ward_elements = (elements.fire or 0) + (elements.cold or 0) + (elements.life or 0) + (elements.arcane or 0) + (elements.water or 0) + (elements.steam or 0) + (elements.lightning or 0) + (elements.poison or 0)
+	
+			if n_ward_elements >= 1 then
+				data.ward_data = Spells_Ward.init(old_context)
+			end
 
-			if not keep_armor then
-				data.armor_data = nil
+			data.kmf_status = 1
+
+			if data.kmf_need_on_cast then
+				Spells_ArmorWard.on_cast(data, old_context)
 			end
+
+			return true
 		else
-			keep_armor = false
-		end
+			local keep_armor = true
 
-		local keep_ward = true
+			if data.armor_data then
+				keep_armor = Spells_SelfArmor.update(data.armor_data, context)
 
-		if data.ward_data then
-			keep_ward = Spells_Ward.update(data.ward_data, context)
+				if not keep_armor then
+					data.armor_data = nil
+				end
+			else
+				keep_armor = false
+			end
 
-			if not keep_ward then
-				data.ward_data = nil
+			local keep_ward = true
+
+			if data.ward_data then
+				keep_ward = Spells_Ward.update(data.ward_data, context)
+
+				if not keep_ward then
+					data.ward_data = nil
+				end
+			else
+				keep_ward = false
 			end
-		else
-			keep_ward = false
-		end
 
-		return keep_armor or keep_ward
+			return keep_armor or keep_ward
+		end
 	end,
 	on_cancel_one = function(element, data, context, notify)
 		if data.armor_data then
