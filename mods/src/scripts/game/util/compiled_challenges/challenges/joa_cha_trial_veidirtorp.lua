diff --git a/scripts/game/util/compiled_challenges/challenges/joa_cha_trial_veidirtorp.lua b/scripts/game/util/compiled_challenges/challenges/joa_cha_trial_veidirtorp.lua
index 6f5a99a..249804d 100644
--- a/scripts/game/util/compiled_challenges/challenges/joa_cha_trial_veidirtorp.lua
+++ b/scripts/game/util/compiled_challenges/challenges/joa_cha_trial_veidirtorp.lua
@@ -3,5 +3,40 @@
 local joa_cha_trial_veidirtorp = {}
 
 joa_cha_trial_veidirtorp.xml = "<level>\n\t<initialize>\n\t\t<level>joa_cha_trial_veidirtorp</level>\n\t\t<gamemode type=\"score\">0</gamemode>\n\t\t<name>joa_trial_summary_4_name</name>\n\t\t<description>joa_trial_summary_4_desc</description>\n\t\t<victory>joa_trial_summary_4_victory</victory>\n\t\t<defeat>joa_trial_summary_4_defeat</defeat>\t\t\n\t\t<artifactSets>\n\t\t\t<artifactSet level=\"wizard\">\n\t\t\t</artifactSet>\n\t\t\t<artifactSet level=\"professor\">\n\t\t\t\t<modifier name=\"TimerDeathPenalty\">2</modifier>\n\t\t\t\t<modifier name=\"EnemyHealth\">3</modifier>\t\t\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"EnemyHealthRegeneration\">1</modifier>\t\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"WizardHealth\">3</modifier>\n\t\t\t\t<modifier name=\"WSpeed\">3</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"WFRegen\">2</modifier>\t\t\t\t\n\t\t\t</artifactSet>\n\t\t\t<artifactSet level=\"sage\">\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"TimerDeathPenalty\">3</modifier>\n\t\t\t\t<modifier name=\"EnemyHealth\">4</modifier>\n\t\t\t\t<modifier name=\"EnemyHealthRegeneration\">2</modifier>\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"WizardHealth\">2</modifier>\n\t\t\t\t<modifier name=\"SpellWeight\">2</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"FRegenType\">1</modifier>\n\t\t\t</artifactSet>\n\t\t</artifactSets>\n\t</initialize>\n\n\t<!-- Phases run automatically and in order, one by one, and only progress\n\t\t\tto the next if victory is reached either manually or automatically.\n\t\t\tThe first phase runs automatically. -->\n\t<!--\n\n\t\tPhase #1 - Civilians & crustaceans\n\t\tPhase #2 - Goblins, crustaceans and a clobster\n\t\tPhase #3 - Alliance & terrans\n\t\t - pan cam left -\n\t\tPhase #4 - Civilians and barbarians\n\t\tPhase #5 - Alliance\n\t\tPhase #6 - Alliance and barbarian\n\n\t-->\n\n\t<phases>\n\n\t\t<!-- Phase #1 -->\n\t\t<phase delay=\"2\" name=\"joa_trial_phase_1of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<level_event name=\"camera_lock_right\" />\n\t\t\t\t<spawn type=\"crustacean_swarmpincher\" area=\"sp_shore\" number=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"human_farmer_male_01\" area=\"sp_boat\" number=\"1\" number2=\"3\" delay=\"1\" />\n\t\t\t\t<spawn type=\"human_farmer_female_02\" area=\"sp_boat\" number=\"1\" delay=\"2\" />\n\t\t\t\t<spawn type=\"human_smith_female_01\" area=\"sp_boat\" number=\"1\" delay=\"3\" />\n\t\t\t\t<spawn type=\"human_fisher_female_01\" area=\"sp_boat\" number=\"1\" number3=\"3\" delay=\"4\" />\n\t\t\t\t<spawn type=\"human_fisher_male_02\" area=\"sp_boat\" number=\"1\" number4=\"3\" delay=\"5\" />\n\t\t\t\t<startVictoryCheck delay=\"6\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #2 -->\n\t\t<phase delay=\"1\" name=\"joa_trial_phase_2of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"goblin_rogue\" area=\"sp_mid_left\" number=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_ranger\" area=\"sp_mid_left\" number=\"2\" number2=\"3\" delay=\"0\" />\n\n\t\t\t\t<spawn type=\"crustacean_swarmpincher\" area=\"sp_shore\" number=\"4\" delay=\"0\" />\n\t\t\t\t<!-- spawn type=\"crustacean_clobster\" area=\"sp_shore\" number=\"1\" delay=\"3\" /-->\n\t\t\t\t<spawn type=\"crustacean_clobster\" area=\"sp_path_forward\" number=\"1\" delay=\"0\" />\n\t\t\t</actions>\n\t\t\t<actions delay=\"8\">\n\t\t\t\t<spawn type=\"goblin_sprayer\" area=\"sp_water\" number=\"2\" number3=\"3\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_warrior\" area=\"sp_water\" number=\"1\" number4=\"3\" delay=\"2\" />\n\t\t\t\t<startVictoryCheck delay=\"3\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #3 -->\n\t\t<phase delay=\"1\" name=\"joa_trial_phase_3of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"elf_warrior_male_00\" area=\"sp_boat\" number=\"1\" number3=\"2\" delay=\"0\" />\n\t\t\t\t\n\t\t\t\t<spawn type=\"human_soldier_pike_female\" area=\"sp_path_forward\" number=\"1\" delay=\"0\" />\n\t\t\t\t<spawn type=\"human_soldier_pike_male\" area=\"sp_path_forward\" number=\"1\" number2=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"human_soldier_female\" area=\"sp_path_forward\" number=\"1\" number2=\"2\" delay=\"1\" />\n\t\t\t\t<spawn type=\"human_soldier_male\" area=\"sp_path_forward\" number=\"1\" delay=\"1\" />\n\t\t\t</actions>\n\t\t\t<actions delay=\"8\">\n\t\t\t\t<spawn type=\"creation_terrane\" area=\"sp_mid_right\" number=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"dwarf_rifleman_male_00\" area=\"sp_mid_left\" number=\"1\" number4=\"2\" delay=\"3\" />\n\t\t\t\t<startVictoryCheck delay=\"4\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #4 -->\n\t\t<phase delay=\"1\" name=\"joa_trial_phase_4of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<level_event name=\"camera_lock_left\" />\n\t\t\t\t<spawn type=\"human_farmer_female_01\" area=\"sp_tent\" number=\"1\" number2=\"2\" delay=\"1\" />\n\t\t\t\t<spawn type=\"human_farmer_male_02\" area=\"sp_tent\" number=\"1\" delay=\"2\" />\n\t\t\t\t<spawn type=\"human_smith_female_01\" area=\"sp_tent\" number=\"1\" number4=\"2\" delay=\"3\" />\n\t\t\t\t<spawn type=\"human_fisher_male_01\" area=\"sp_tent\" number=\"1\" delay=\"4\" />\n\n\t\t\t\t<spawn type=\"barbarian_elite_female\" area=\"sp_path_behind\" number=\"1\" delay=\"0\" />\n\t\t\t\t<spawn type=\"barbarian_warrior_female\" area=\"sp_path_behind\" number=\"1\" number3=\"3\" delay=\"0\" />\n\t\t\t\t<startVictoryCheck delay=\"6\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #5 -->\n\t\t<phase delay=\"2\" name=\"joa_trial_phase_5of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"elf_priestess_female_00\" area=\"sp_mid_right\" number=\"1\" number2=\"2\" delay=\"0\" />\n\n\t\t\t\t<spawn type=\"dwarf_priest_00\" area=\"sp_path_behind\" number=\"1\" number4=\"2\" delay=\"1\" />\n\t\t\t\t<spawn type=\"creation_terrane\" area=\"sp_path_behind\" number=\"2\" number3=\"3\" delay=\"10\" />\n\t\t\t\t<startVictoryCheck delay=\"16\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #6 -->\n\t\t<phase delay=\"2\" name=\"joa_trial_phase_6of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"human_soldier_pike_female\" area=\"sp_mid_right\" number=\"1\" delay=\"0\" />\n\t\t\t\t<spawn type=\"human_smith_female_01\" area=\"sp_mid_right\" number=\"1\" number4=\"3\" delay=\"0\" />\n\n\t\t\t\t<spawn type=\"creation_midge\" area=\"sp_path_behind\" number=\"4\" delay=\"2\" />\n\t\t\t</actions>\n\t\t\t<actions delay=\"8\">\n\t\t\t\t<spawn type=\"elf_warrior_male_00\" area=\"sp_path_behind\" number=\"1\" number2=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"barbarian_elite\" area=\"sp_path_behind\" number=\"1\" number3=\"3\" delay=\"5\" />\n\t\t\t\t<spawn type=\"barbarian_warrior_male\" area=\"sp_path_behind\" number=\"1\" delay=\"5\" />\n\t\t\t\t<!-- level_event name=\"check_achievement_trial\" delay=\"6\" /-->\n\t\t\t\t<startVictoryCheck delay=\"6\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\t</phases>\n</level>"
+joa_cha_trial_veidirtorp.xml2 = [[
+<level>
+	<initialize>
+		<level>joa_cha_trial_veidirtorp</level>
+		<gamemode type="skill"></gamemode>
+		<name>joa_trial_summary_4_name</name>
+		<description>joa_trial_summary_4_desc</description>
+		<victory>joa_trial_summary_4_victory</victory>
+		<defeat>joa_trial_summary_4_defeat</defeat>
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
 
 return joa_cha_trial_veidirtorp
