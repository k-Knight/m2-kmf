diff --git a/scripts/game/util/compiled_challenges/challenges/joa_cha_trial_snowy_higherlands.lua b/scripts/game/util/compiled_challenges/challenges/joa_cha_trial_snowy_higherlands.lua
index 3d26629..e59ea51 100644
--- a/scripts/game/util/compiled_challenges/challenges/joa_cha_trial_snowy_higherlands.lua
+++ b/scripts/game/util/compiled_challenges/challenges/joa_cha_trial_snowy_higherlands.lua
@@ -3,5 +3,40 @@
 local joa_cha_trial_snowy_higherlands = {}
 
 joa_cha_trial_snowy_higherlands.xml = "<level>\n\t<initialize>\n\t\t<level>joa_cha_trial_snowy_higherlands</level>\n\t\t<gamemode type=\"score\">0</gamemode>\n\t\t<name>joa_trial_summary_2_name</name>\n\t\t<description>joa_trial_summary_2_desc</description>\n\t\t<victory>joa_trial_summary_2_victory</victory>\n\t\t<defeat>joa_trial_summary_2_defeat</defeat>\t\t\n\t\t<artifactSets>\n\t\t\t<artifactSet level=\"wizard\">\n\t\t\t</artifactSet>\n\t\t\t<artifactSet level=\"professor\">\n\t\t\t\t<modifier name=\"TimerDeathPenalty\">2</modifier>\n\t\t\t\t<modifier name=\"EnemyHealth\">3</modifier>\t\t\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"EnemyHealthRegeneration\">1</modifier>\t\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"WizardHealth\">3</modifier>\n\t\t\t\t<modifier name=\"WSpeed\">3</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"WFRegen\">2</modifier>\t\t\t\t\n\t\t\t</artifactSet>\n\t\t\t<artifactSet level=\"sage\">\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"TimerDeathPenalty\">3</modifier>\n\t\t\t\t<modifier name=\"EnemyHealth\">4</modifier>\n\t\t\t\t<modifier name=\"EnemyHealthRegeneration\">2</modifier>\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"WizardHealth\">2</modifier>\n\t\t\t\t<modifier name=\"SpellWeight\">2</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"FRegenType\">1</modifier>\t\n\t\t\t</artifactSet>\n\t\t</artifactSets>\n\t</initialize>\n\n\t<!-- Phases run automatically and in order, one by one, and only progress\n\t\t\tto the next if victory is reached either manually or automatically.\n\t\t\tThe first phase runs automatically. -->\n\n\t<!--\n\n\t\tPhase #1 - Goblins\n\t\tPhase #2 - Goblins and beastkin\n\t\tPhase #3 - Beastkin\n\t\tPhase #4 - Goblins and orcs\n\t\tPhase #5 - Goblins, orcs and beastkin\n\t\tPhase #6 - Beastkin and troll\n\n\t-->\n\n\t<phases>\n\t\t<!-- Phase #1 -->\n\t\t<phase delay=\"0\" name=\"joa_trial_phase_1of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"goblin_rogue\" area=\"sp_tent\" number=\"2\" number2=\"3\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_rogue_boss\" area=\"sp_tent\" number=\"1\" number4=\"2\" delay=\"4\" />\n\t\t\t\t<spawn type=\"goblin_ranger\" area=\"sp_bottom\" number=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_rogue_boss\" area=\"sp_bottom\" number=\"1\" number3=\"2\" delay=\"0\" />\n\t\t\t\t<startVictoryCheck delay=\"3\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #2 -->\n\t\t<phase delay=\"0\" name=\"joa_trial_phase_2of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"goblin_rogue_boss\" area=\"sp_tent\" number=\"1\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_rogue\" area=\"sp_tent\" number=\"2\" number3=\"3\" delay=\"2\" />\n\t\t\t\t<spawn type=\"goblin_ranger\" area=\"sp_tent\" number=\"2\" number3=\"3\" delay=\"4\" />\n\n\t\t\t\t<spawn type=\"goblin_sprayer\" area=\"sp_bottom\" number=\"1\" number2=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_sprayer_fire\" area=\"sp_bottom\" number=\"1\" delay=\"0\" />\n\t\t\t</actions>\n\t\t\t<actions delay=\"10\">\n\t\t\t\t<spawn type=\"beastman_raider\" area=\"sp_forest\" number=\"4\" number4=\"6\" delay=\"0\" />\n\t\t\t\t<startVictoryCheck delay=\"3\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #3 -->\n\t\t<phase delay=\"1\" name=\"joa_trial_phase_3of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"beastman_elder\" area=\"sp_top\" number=\"1\" delay=\"0\" />\n\t\t\t</actions>\n\t\t\t<actions delay=\"8\">\n\t\t\t\t<spawn type=\"beastman_raider\" area=\"sp_top\" number=\"4\" number3=\"5\" delay=\"0\" />\n\t\t\t\t<spawn type=\"beastman_brute\" area=\"sp_forest\" number=\"2\" number4=\"3\" delay=\"0\" />\n\t\t\t\t<startVictoryCheck delay=\"2\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #4 -->\n\t\t<phase delay=\"2\" name=\"joa_trial_phase_4of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"goblin_rogue\" area=\"sp_bottom\" number=\"4\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_shaman\" area=\"sp_tent\" number=\"1\" number2=\"2\" delay=\"0\" />\n\n\t\t\t\t<spawn type=\"orc_regular\" area=\"sp_bottom\" number=\"1\" delay=\"0\" />\n\t\t\t\t<spawn type=\"orc_warrior_male_00\" area=\"sp_bottom\" number=\"1\" delay=\"3\" />\n\t\t\t\t<spawn type=\"orc_warrior_noshield\" area=\"sp_bottom\" number=\"1\" number3=\"3\" delay=\"6\" />\n\t\t\t\t<spawn type=\"goblin_bomber\" area=\"sp_bottom\" number=\"2\" number4=\"3\" delay=\"0\" />\n\t\t\t\t<startVictoryCheck delay=\"6\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #5 -->\n\t\t<phase delay=\"1\" name=\"joa_trial_phase_5of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"orc_sorc_male_00\" area=\"sp_tent\" number=\"1\" number4=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_bomber\" area=\"sp_tent\" number=\"1\" delay=\"3\" />\n\t\t\t\t<spawn type=\"goblin_shaman\" area=\"sp_bottom\" number=\"1\" number3=\"2\" delay=\"6\" />\n\t\t\t</actions>\n\t\t\t<actions delay=\"6\">\n\t\t\t\t<spawn type=\"beastman_raider\" area=\"sp_forest\" number=\"1\" delay=\"0\" />\n\t\t\t\t<spawn type=\"beastman_raider_nojump\" area=\"sp_top\" number=\"1\" number2=\"3\" delay=\"0\" />\n\t\t\t\t<startVictoryCheck delay=\"1\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\n\t\t<!-- Phase #6 -->\n\t\t<phase delay=\"2\" name=\"joa_trial_phase_6of6\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<spawn type=\"beastman_raider\" area=\"sp_top\" number=\"1\" number3=\"3\" delay=\"0\" />\n\t\t\t\t<spawn type=\"beastman_raider\" area=\"sp_top\" number=\"1\" number2=\"3\" delay=\"0\" />\n\t\t\t\t<spawn type=\"beastman_brute_lightning\" area=\"sp_top\" number=\"1\" number4=\"3\" delay=\"0\" />\n\n\t\t\t\t<spawn type=\"troll_war\" area=\"sp_bottom\" number=\"1\" delay=\"0\" />\n\t\t\t\t<startVictoryCheck delay=\"2\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\t</phases>\n</level>"
+joa_cha_trial_snowy_higherlands.xml2 = [[
+<level>
+	<initialize>
+		<level>joa_cha_trial_snowy_higherlands</level>
+		<gamemode type="skill"></gamemode>
+		<name>joa_trial_summary_2_name</name>
+		<description>joa_trial_summary_2_desc</description>
+		<victory>joa_trial_summary_2_victory</victory>
+		<defeat>joa_trial_summary_2_defeat</defeat>		
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
 
 return joa_cha_trial_snowy_higherlands
