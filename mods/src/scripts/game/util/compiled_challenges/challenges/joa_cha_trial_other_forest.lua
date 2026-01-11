diff --git a/scripts/game/util/compiled_challenges/challenges/joa_cha_trial_other_forest.lua b/scripts/game/util/compiled_challenges/challenges/joa_cha_trial_other_forest.lua
index 24ba898..9618bde 100644
--- a/scripts/game/util/compiled_challenges/challenges/joa_cha_trial_other_forest.lua
+++ b/scripts/game/util/compiled_challenges/challenges/joa_cha_trial_other_forest.lua
@@ -3,5 +3,40 @@
 local joa_cha_trial_other_forest = {}
 
 joa_cha_trial_other_forest.xml = "<level>\n\t<initialize>\n\t\t<level>joa_cha_trial_other_forest</level>\n\t\t<gamemode type=\"score\">0</gamemode>\n\t\t<name>joa_trial_summary_3_name</name>\n\t\t<description>joa_trial_summary_3_desc</description>\n\t\t<victory>joa_trial_summary_3_victory</victory>\n\t\t<defeat>joa_trial_summary_3_defeat</defeat>\t\t\n\t\t<artifactSets>\n\t\t\t<artifactSet level=\"wizard\">\n\t\t\t</artifactSet>\n\t\t\t<artifactSet level=\"professor\">\n\t\t\t\t<modifier name=\"TimerDeathPenalty\">2</modifier>\n\t\t\t\t<modifier name=\"EnemyHealth\">3</modifier>\t\t\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"EnemyHealthRegeneration\">1</modifier>\t\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"WizardHealth\">3</modifier>\n\t\t\t\t<modifier name=\"WSpeed\">3</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"WFRegen\">2</modifier>\t\t\t\t\n\t\t\t</artifactSet>\n\t\t\t<artifactSet level=\"sage\">\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"TimerDeathPenalty\">3</modifier>\n\t\t\t\t<modifier name=\"EnemyHealth\">4</modifier>\n\t\t\t\t<modifier name=\"EnemyHealthRegeneration\">2</modifier>\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"WizardHealth\">2</modifier>\n\t\t\t\t<modifier name=\"SpellWeight\">2</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"FRegenType\">1</modifier>\t\n\t\t\t</artifactSet>\n\t\t</artifactSets>\n\t</initialize>\n\n\t<!-- Phases run automatically and in order, one by one, and only progress\n\t\t\tto the next if victory is reached either manually or automatically.\n\t\t\tThe first phase runs automatically. -->\n\t<!--\n\n\t\tPhase #1 - Goblins & crustaceans\n\t\tPhase #2 - Goblins, orcs and humans\n\t\tPhase #3 - Orcs and rifle men\n\t\tPhase #4 - Spell casters\n\t\tPhase #5 - Elf, shamans and mortar\n\t\tPhase #6 - A troll and some elves\n\n\t-->\n\n\t<phases>\n\t\t<!-- Phase #1 -->\n\t\t<phase delay=\"0\" name=\"joa_trial_phase_1of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"goblin_forest_rogue\" area=\"sp_left\" number=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_forest_ranger\" area=\"sp_left\" number=\"1\" number2=\"3\" delay=\"1\" />\n\t\t\t\t<spawn type=\"goblin_forest_bomber\" area=\"sp_left\" number=\"1\" delay=\"2\" />\n\n\t\t\t\t<spawn type=\"crustacean_swarmpincher\" area=\"sp_water\" number=\"3\" number4=\"5\" delay=\"0\" />\n\t\t\t\t<spawn type=\"crustacean_swarmpincher\" area=\"sp_water\" number=\"3\" number3=\"4\" delay=\"4\" />\n\t\t\t\t<startVictoryCheck delay=\"4\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #2 -->\n\t\t<phase delay=\"0\" name=\"joa_trial_phase_2of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"goblin_medibomber\" area=\"sp_left\" number=\"2\" number2=\"3\" delay=\"2\" />\n\t\t\t\t<spawn type=\"goblin_forest_warrior\" area=\"sp_left\" number=\"1\" delay=\"2\" />\n\t\t\t\t<spawn type=\"orc_mortar_male_00\" area=\"sp_left\" number=\"1\" number4=\"3\" delay=\"0\" />\n\n\t\t\t\t<spawn type=\"human_soldier_female\" area=\"sp_right\" number=\"1\" delay=\"1\" />\n\t\t\t\t<spawn type=\"human_soldier_male\" area=\"sp_right\" number=\"1\" number3=\"3\" delay=\"2\" />\n\t\t\t\t<spawn type=\"human_soldier_pike_female\" area=\"sp_right\" number=\"1\" delay=\"3\" />\n\t\t\t\t<spawn type=\"human_soldier_pike_male\" area=\"sp_right\" number=\"1\" delay=\"4\" />\n\t\t\t\t<startVictoryCheck delay=\"4\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #3 -->\n\t\t<phase delay=\"1\" name=\"joa_trial_phase_3of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"orc_captain\" area=\"sp_left\" number=\"1\" number3=\"2\" delay=\"0\" />\n\n\t\t\t\t<spawn type=\"dwarf_rifleman_male_00\" area=\"sp_right\" number=\"2\" number4=\"3\" delay=\"3\" />\n\t\t\t\t<spawn type=\"human_soldier_female\" area=\"sp_right\" number=\"1\" number2=\"3\" delay=\"4\" />\n\t\t\t\t<spawn type=\"human_soldier_male\" area=\"sp_right\" number=\"1\" delay=\"4\" />\n\t\t\t\t<startVictoryCheck delay=\"4\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #4 -->\n\t\t<phase delay=\"2\" name=\"joa_trial_phase_4of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"crustacean_ranged\" area=\"sp_water\" number=\"2\" delay=\"0\" />\n\n\t\t\t\t<spawn type=\"dwarf_priest_00\" area=\"sp_right\" number=\"1\" number3=\"2\" delay=\"1\" />\n\t\t\t\t<spawn type=\"elf_priestess_female_00\" area=\"sp_right\" number=\"1\" number4=\"2\" delay=\"1\" />\n\n\t\t\t\t<spawn type=\"goblin_shaman\" area=\"sp_left\" number=\"1\" number2=\"2\" delay=\"2\" />\n\t\t\t\t<spawn type=\"goblin_shaman_2\" area=\"sp_left\" number=\"1\" delay=\"2\" />\n\t\t\t\t<startVictoryCheck delay=\"3\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #5 -->\n\t\t<phase delay=\"2\" name=\"joa_trial_phase_5of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"elf_warrior_male_00\" area=\"sp_right\" number=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"elf_elite\" area=\"sp_right\" number=\"2\" number3=\"3\" elay=\"0\" />\n\n\t\t\t\t<spawn type=\"goblin_shaman_2\" area=\"sp_left\" number=\"1\" number2=\"2\" delay=\"3\" />\n\t\t\t\t<spawn type=\"orc_mortar_male_00\" area=\"sp_left\" number=\"2\" number4=\"4\" delay=\"3\" />\n\t\t\t\t<startVictoryCheck delay=\"3\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #6 -->\n\t\t<phase delay=\"1\" name=\"joa_trial_phase_6of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"troll_war\" area=\"sp_left\" number=\"1\" number4=\"2\" delay=\"0\" />\n\n\t\t\t\t<spawn type=\"elf_elite\" area=\"sp_right\" number=\"2\" number3=\"4\" delay=\"0\" />\n\t\t\t\t<spawn type=\"human_soldier_pike_female\" area=\"sp_right\" number=\"1\" delay=\"0\" />\n\t\t\t\t<spawn type=\"human_soldier_pike_male\" area=\"sp_right\" number=\"1\" number2=\"2\" delay=\"0\" />\n\t\t\t\t<startVictoryCheck delay=\"1\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t</phases>\n</level>"
+joa_cha_trial_other_forest.xm2l = [[
+<level>
+	<initialize>
+		<level>joa_cha_trial_other_forest</level>
+		<gamemode type="skill"></gamemode>
+		<name>joa_trial_summary_3_name</name>
+		<description>joa_trial_summary_3_desc</description>
+		<victory>joa_trial_summary_3_victory</victory>
+		<defeat>joa_trial_summary_3_defeat</defeat>		
+		<artifactSets>
+			<artifactSet level="wizard">
+			</artifactSet>
+			<artifactSet level="professor">
+				<modifier name="TimerDeathPenalty">2</modifier>
+				<modifier name="EnemyHealth">3</modifier>								
+				<modifier name="EnemyHealthRegeneration">1</modifier>							
+				<modifier name="WizardHealth">3</modifier>
+				<modifier name="WSpeed">3</modifier>				
+				<modifier name="WFRegen">2</modifier>				
+			</artifactSet>
+			<artifactSet level="sage">						
+				<modifier name="TimerDeathPenalty">3</modifier>
+				<modifier name="EnemyHealth">4</modifier>
+				<modifier name="EnemyHealthRegeneration">2</modifier>						
+				<modifier name="WizardHealth">2</modifier>
+				<modifier name="SpellWeight">2</modifier>				
+				<modifier name="FRegenType">1</modifier>	
+			</artifactSet>
+		</artifactSets>
+	</initialize>
+
+	<phases>
+	</phases>
+</level>
+]]
 
 return joa_cha_trial_other_forest
