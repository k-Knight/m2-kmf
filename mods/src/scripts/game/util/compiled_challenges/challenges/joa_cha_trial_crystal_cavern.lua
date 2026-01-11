diff --git a/scripts/game/util/compiled_challenges/challenges/joa_cha_trial_crystal_cavern.lua b/scripts/game/util/compiled_challenges/challenges/joa_cha_trial_crystal_cavern.lua
index a52ea3e..1402313 100644
--- a/scripts/game/util/compiled_challenges/challenges/joa_cha_trial_crystal_cavern.lua
+++ b/scripts/game/util/compiled_challenges/challenges/joa_cha_trial_crystal_cavern.lua
@@ -3,5 +3,40 @@
 local joa_cha_trial_crystal_cavern = {}
 
 joa_cha_trial_crystal_cavern.xml = "<level>\n\t<initialize>\n\t\t<level>joa_cha_trial_crystal_cavern</level>\n\t\t<gamemode type=\"score\">0</gamemode>\n\t\t<name>joa_trial_summary_5_name</name>\n\t\t<description>joa_trial_summary_5_desc</description>\n\t\t<victory>joa_trial_summary_5_victory</victory>\n\t\t<defeat>joa_trial_summary_5_defeat</defeat>\n\t\t<artifactSets>\n\t\t\t<artifactSet level=\"wizard\">\n\t\t\t</artifactSet>\n\t\t\t<artifactSet level=\"professor\">\n\t\t\t\t<modifier name=\"TimerDeathPenalty\">2</modifier>\n\t\t\t\t<modifier name=\"EnemyHealth\">3</modifier>\t\t\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"EnemyHealthRegeneration\">1</modifier>\t\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"WizardHealth\">3</modifier>\n\t\t\t\t<modifier name=\"WSpeed\">3</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"WFRegen\">2</modifier>\t\t\t\t\n\t\t\t</artifactSet>\n\t\t\t<artifactSet level=\"sage\">\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"TimerDeathPenalty\">3</modifier>\n\t\t\t\t<modifier name=\"EnemyHealth\">4</modifier>\n\t\t\t\t<modifier name=\"EnemyHealthRegeneration\">2</modifier>\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"WizardHealth\">2</modifier>\n\t\t\t\t<modifier name=\"SpellWeight\">2</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"FRegenType\">1</modifier>\n\t\t\t</artifactSet>\n\t\t</artifactSets>\n\t</initialize>\n\n\t<!-- Phases run automatically and in order, one by one, and only progress\n\t\t\tto the next if victory is reached either manually or automatically.\n\t\t\tThe first phase runs automatically. -->\n\n\t<!--\n\n\t\tPhase #1 - Swarmpinchers\n\t\tPhase #2 - Swarmpinchers, spitters and goblin archers\n\t\tPhase #3 - Goblin rogues and sprayers\n\t\tPhase #4 - Goblins (rogues, rangers, sprayers, shamans and bombers) and orc regulars\n\t\tPhase #5 -  -- \" --\n\t\tPhase #6 - Orcs and a clobbster, spitters\n\n\t-->\n\n\t<phases>\n\n\t\t<!-- Phase #1  -->\n\t\t<phase delay=\"2\" name=\"joa_trial_phase_1of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<level_event name=\"init_time_challenge\" />\n\t\t\t\t<spawn type=\"crustacean_swarmpincher\" area=\"sp_path_right\" number=\"3\" number4=\"5\" delay=\"0\" />\n\t\t\t\t<spawn type=\"crustacean_swarmpincher_cold\" area=\"sp_path_right\" number=\"2\" number3=\"3\" delay=\"2\" />\n\t\t\t\t<spawn type=\"crustacean_swarmpincher\" area=\"sp_path_right\" number=\"3\" number2=\"3\" delay=\"4\" />\n\t\t\t\t<startVictoryCheck delay=\"6\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #2 -->\n\t\t<phase delay=\"0\" name=\"joa_trial_phase_2of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"goblin_rogue\" area=\"sp_path_left\" number=\"2\" number2=\"3\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_ranger\" area=\"sp_path_left\" number=\"3\" number4=\"5\" delay=\"2\" />\n\t\t\t\t<spawn type=\"crustacean_swarmpincher\" area=\"sp_path_right\" number=\"3\" number3=\"6\" delay=\"6\" />\n\t\t\t\t<spawn type=\"crustacean_ranged\" area=\"sp_path_right\" number=\"2\" delay=\"8\" />\n\t\t\t\t<spawn type=\"crustacean_swarmpincher\" area=\"sp_path_right\" number=\"3\" delay=\"10\" />\n\t\t\t\t<startVictoryCheck delay=\"11\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #3 -->\n\t\t<phase delay=\"1\" name=\"joa_trial_phase_3of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"goblin_warrior\" area=\"sp_path_left\" number=\"1\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_sprayer_fire\" area=\"sp_grotto2\" number=\"1\" number2=\"2\" delay=\"4\" />\n\t\t\t</actions>\n\t\t\t<actions delay=\"10\">\n\t\t\t\t<spawn type=\"goblin_warrior\" area=\"sp_path_left\" number=\"2\" number4=\"4\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_ranger\" area=\"sp_path_left\" number=\"1\" number3=\"3\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_sprayer_fire\" area=\"sp_grotto1\" number=\"1\" delay=\"2\" />\n\t\t\t\t<spawn type=\"goblin_sprayer\" area=\"sp_grotto2\" number=\"1\" delay=\"4\" />\n\t\t\t\t<startVictoryCheck delay=\"5\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #4 -->\n\t\t<phase delay=\"1\" name=\"joa_trial_phase_4of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"goblin_sprayer\" area=\"sp_path_left\" number=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"orc_regular\" area=\"sp_grotto1\" number=\"1\" number2=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_bomber\" area=\"sp_grotto1\" number=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_shaman\" area=\"sp_path_left\" number=\"2\" number4=\"3\" delay=\"2\" />\n\t\t\t\t<spawn type=\"orc_regular\" area=\"sp_grotto2\" number=\"1\" number3=\"2\" delay=\"10\" />\n\t\t\t\t<startVictoryCheck delay=\"11\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #5 -->\n\t\t<phase delay=\"1\" name=\"joa_trial_phase_5of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"goblin_rogue\" area=\"sp_path_left\" number=\"4\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_shaman\" area=\"sp_path_left\" number=\"1\" number2=\"2\" delay=\"2\" />\n\t\t\t\t<spawn type=\"goblin_ranger\" area=\"sp_path_left\" number=\"1\" delay=\"4\" />\n\n\t\t\t\t<spawn type=\"orc_regular\" area=\"sp_grotto2\" number=\"1\" number4=\"3\" delay=\"5\" />\n\n\t\t\t\t<spawn type=\"crustacean_swarmpincher\" area=\"sp_path_right\" number=\"4\" delay=\"0\" />\n\t\t\t\t<spawn type=\"crustacean_ranged\" area=\"sp_path_right\" number=\"2\" number3=\"3\" delay=\"0\" />\n\t\t\t\t<startVictoryCheck delay=\"5\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #6 -->\n\t\t<phase delay=\"2\" name=\"joa_trial_phase_6of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"orc_regular\" area=\"sp_path_left\" number=\"1\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_bomber\" area=\"sp_path_left\" number=\"1\" number2=\"3\" delay=\"2\" />\n\t\t\t\t<spawn type=\"goblin_shaman\" area=\"sp_path_left\" number=\"1\" delay=\"4\" />\n\n\t\t\t\t<spawn type=\"crustacean_clobster\" area=\"sp_path_right\" number=\"1\" delay=\"0\" />\n\t\t\t\t<spawn type=\"crustacean_swarmpincher\" area=\"sp_path_right\" number=\"2\" number3=\"3\" delay=\"2\" />\n\t\t\t\t<spawn type=\"crustacean_ranged\" area=\"sp_path_right\" number=\"1\" number4=\"3\" delay=\"4\" />\n\t\t\t\t<startVictoryCheck delay=\"5\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t</phases>\n</level>"
+joa_cha_trial_crystal_cavern.xml2 = [[
+<level>
+	<initialize>
+		<level>joa_cha_trial_crystal_cavern</level>
+		<gamemode type="skill"></gamemode>
+		<name>joa_trial_summary_5_name</name>
+		<description>joa_trial_summary_5_desc</description>
+		<victory>joa_trial_summary_5_victory</victory>
+		<defeat>joa_trial_summary_5_defeat</defeat>
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
 
 return joa_cha_trial_crystal_cavern
