diff --git a/scripts/game/util/compiled_challenges/challenges/joa_cha_trial_festival.lua b/scripts/game/util/compiled_challenges/challenges/joa_cha_trial_festival.lua
index 80990ad..06fb97c 100644
--- a/scripts/game/util/compiled_challenges/challenges/joa_cha_trial_festival.lua
+++ b/scripts/game/util/compiled_challenges/challenges/joa_cha_trial_festival.lua
@@ -3,5 +3,40 @@
 local joa_cha_trial_festival = {}
 
 joa_cha_trial_festival.xml = "<level>\n\t<initialize>\n\t\t<level>joa_cha_trial_festival</level>\n\t\t<gamemode type=\"score\">0</gamemode>\n\t\t<name>joa_trial_summary_1_name</name>\n\t\t<description>joa_trial_summary_1_desc</description>\n\t\t<victory>joa_trial_summary_1_victory</victory>\n\t\t<defeat>joa_trial_summary_1_defeat</defeat>\n\t\t<artifactSets>\n\t\t\t<artifactSet level=\"wizard\">\n\t\t\t</artifactSet>\n\t\t\t<artifactSet level=\"professor\">\n\t\t\t\t<modifier name=\"TimerDeathPenalty\">2</modifier>\n\t\t\t\t<modifier name=\"EnemyHealth\">3</modifier>\t\t\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"EnemyHealthRegeneration\">1</modifier>\t\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"WizardHealth\">3</modifier>\n\t\t\t\t<modifier name=\"WSpeed\">3</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"WFRegen\">2</modifier>\t\t\t\t\n\t\t\t</artifactSet>\n\t\t\t<artifactSet level=\"sage\">\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"TimerDeathPenalty\">3</modifier>\n\t\t\t\t<modifier name=\"EnemyHealth\">4</modifier>\n\t\t\t\t<modifier name=\"EnemyHealthRegeneration\">2</modifier>\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"WizardHealth\">2</modifier>\n\t\t\t\t<modifier name=\"SpellWeight\">2</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"FRegenType\">1</modifier>\t\n\t\t\t</artifactSet>\n\t\t</artifactSets>\n\t</initialize>\n\n\t<!-- Phases run automatically and in order, one by one, and only progress \n\t\t\tto the next if victory is reached either manually or automatically. \n\t\t\tThe first phase runs automatically. -->\n\n\t<phases>\n\n\t\t<!-- Phase #1 -->\n\t\t<phase delay=\"2\" name=\"joa_trial_phase_1of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"goblin_rogue\" area=\"sp_path_forward\" number=\"3\" number2=\"4\" number4=\"6\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_rogue\" area=\"sp_path_forward\" number=\"3\" number3=\"4\" delay=\"4\" />\n\t\t\t\t<startVictoryCheck delay=\"3\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #2 -->\n\t\t<phase delay=\"1\" name=\"joa_trial_phase_2of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"goblin_rogue\" area=\"sp_path_behind\" number=\"4\" number2=\"5\" number4=\"6\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_ranger\" area=\"sp_path_behind\" number=\"4\" number3=\"5\" delay=\"2\" />\n\t\t\t\t<startVictoryCheck delay=\"3\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #3 -->\n\t\t<phase delay=\"1\" name=\"joa_trial_phase_3of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"goblin_rogue\" area=\"sp_path_forward\" number=\"1\" number2=\"3\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_ranger\" area=\"sp_forest\" number=\"2\" number3=\"3\" delay=\"0\" />\n\t\t\t</actions>\n\t\t\t<actions delay=\"12\">\n\t\t\t\t<spawn type=\"goblin_rogue_boss\" area=\"sp_path_behind\" number=\"2\" number4=\"3\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_ranger\" area=\"sp_path_forward\" number=\"2\" delay=\"0\" />\n\t\t\t\t<startVictoryCheck delay=\"4\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #4 -->\n\t\t<phase delay=\"1\" name=\"joa_trial_phase_4of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"goblin_rogue\" area=\"sp_tent\" number=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_rogue\" area=\"sp_tent\" number=\"2\" number2=\"3\" delay=\"2\" />\n\t\t\t\t<spawn type=\"goblin_ranger\" area=\"sp_path_forward\" number=\"1\" number4=\"3\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_ranger\" area=\"sp_path_behind\" number=\"1\" number3=\"3\" delay=\"0\" />\n\t\t\t\t<startVictoryCheck delay=\"4\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #5 -->\n\t\t<phase delay=\"1\" name=\"joa_trial_phase_5of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"goblin_rogue\" area=\"sp_tent\" number=\"3\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_rogue\" area=\"sp_tent\" number=\"3\" number2=\"4\" delay=\"2\" />\n\t\t\t\t<spawn type=\"goblin_ranger\" area=\"sp_path_forward\" number=\"1\" number4=\"3\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_ranger\" area=\"sp_path_behind\" number=\"2\" number3=\"3\" delay=\"0\" />\n\t\t\t\t<startVictoryCheck delay=\"4\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\t\t\n\n\t\t<!-- Phase #6 -->\n\t\t<phase delay=\"2\" name=\"joa_trial_phase_6of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"goblin_ranger\" area=\"sp_path_behind\" number=\"3\" number3=\"4\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_rogue\" area=\"sp_tent\" number=\"1\" delay=\"2\" />\n\t\t\t\t<spawn type=\"goblin_rogue\" area=\"sp_tent\" number=\"1\" delay=\"4\" />\n\t\t\t\t<spawn type=\"goblin_rogue_boss\" area=\"sp_forest\" number=\"2\" number4=\"3\" delay=\"12\" />\n\t\t\t\t<spawn type=\"goblin_ranger\" area=\"sp_path_forward\" number=\"3\" number2=\"4\" delay=\"13\" />\n\t\t\t\t<spawn type=\"goblin_ranger\" area=\"sp_path_behind\" number=\"3\" delay=\"13\" />\n\t\t\t\t<startVictoryCheck delay=\"5\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\n\n\t</phases>\n</level>"
+joa_cha_trial_festival.xml2 = [[
+<level>
+	<initialize>
+		<level>joa_cha_trial_festival</level>
+		<gamemode type="skill"></gamemode>
+		<name>joa_trial_summary_1_name</name>
+		<description>joa_trial_summary_1_desc</description>
+		<victory>joa_trial_summary_1_victory</victory>
+		<defeat>joa_trial_summary_1_defeat</defeat>
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
 
 return joa_cha_trial_festival
