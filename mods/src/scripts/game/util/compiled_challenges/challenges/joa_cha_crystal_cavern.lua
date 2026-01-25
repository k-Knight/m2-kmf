diff --git a/scripts/game/util/compiled_challenges/challenges/joa_cha_crystal_cavern.lua b/scripts/game/util/compiled_challenges/challenges/joa_cha_crystal_cavern.lua
index 7308cff..5b8cdde 100644
--- a/scripts/game/util/compiled_challenges/challenges/joa_cha_crystal_cavern.lua
+++ b/scripts/game/util/compiled_challenges/challenges/joa_cha_crystal_cavern.lua
@@ -2,6 +2,41 @@
 
 local joa_cha_crystal_cavern = {}
 
-joa_cha_crystal_cavern.xml = "<level>\n\t<initialize>\n\t\t<level>joa_cha_crystal_cavern</level>\n\t\t<gamemode type=\"time\">60</gamemode>\n\t\t<name>joa_challenge_summary_5_name</name>\n\t\t<description>joa_challenge_summary_5_desc</description>\n\t\t<victory>joa_challenge_summary_5_victory</victory>\n\t\t<defeat>joa_challenge_summary_5_defeat</defeat>\n\t\t<artifactSets>\n\t\t\t<artifactSet level=\"wizard\">\n\t\t\t\t<unlockMagick name=\"revive\" score=\"0\" />\n\t\t\t\t<unlockMagick name=\"haste\" score=\"30\" />\n\t\t\t\t<unlockMagick name=\"push\" score=\"30\" />\n\t\t\t</artifactSet>\n\t\t\t<artifactSet level=\"professor\">\n\t\t\t\t<modifier name=\"EnemyHealth\">3</modifier>\n\t\t\t\t<modifier name=\"EnemyMovementSpeed\">3</modifier>\n\t\t\t\t<modifier name=\"EnemyHealthRegeneration\">1</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"WizardHealth\">3</modifier>\n\t\t\t\t<modifier name=\"WSpeed\">3</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"WFRegen\">2</modifier>\n\t\t\t\t<unlockMagick name=\"revive\" score=\"10\" />\n\t\t\t\t<unlockMagick name=\"push\" score=\"30\" />\n\t\t\t</artifactSet>\n\t\t\t<artifactSet level=\"sage\">\t\t\t\t\n\t\t\t\t<modifier name=\"EnemyHealth\">4</modifier>\n\t\t\t\t<modifier name=\"EnemyMovementSpeed\">4</modifier>\n\t\t\t\t<modifier name=\"EnemyHealthRegeneration\">2</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"WizardHealth\">2</modifier>\n\t\t\t\t<modifier name=\"SpellWeight\">2</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"FRegenType\">1</modifier>\n\t\t\t\t<unlockMagick name=\"revive\" score=\"30\" />\n\t\t\t\t<unlockMagick name=\"dragon_strike\" score=\"50\" />\n\t\t\t</artifactSet>\n\t\t</artifactSets>\n\t</initialize>\n\n\t<!-- Phases run automatically and in order, one by one, and only progress to the next if victory is reached either manually or automatically. The first phase runs automatically. -->\n\n\t<phases>\n\t\t<phase delay=\"1\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<level_event name=\"init_time_challenge\" />\n\t\t\t\t<spawn type=\"crustacean_ranged\" area=\"sp_grotto1\" number=\"1\" number2=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"crustacean_ranged\" area=\"sp_grotto2\" number=\"1\" number2=\"2\" delay=\"3\" />\n\n\t\t\t\t<spawn type=\"goblin_rogue\" area=\"sp_arena\" number=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_ranger\" area=\"sp_arena\" number=\"2\" number3=\"3\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_warrior\" area=\"sp_arena\" number=\"1\" delay=\"0\" />\n\t\t\t\t<spawn type=\"orc_warrior_male_00\" area=\"sp_arena\" number=\"1\" number2=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"orc_warrior_noshield\" area=\"sp_arena\" number=\"1\" delay=\"0\" />\n\n\t\t\t\t<spawn type=\"crustacean_swarmpincher\" area=\"sp_path_left\" number=\"4\" number4=\"8\" delay=\"0\" />\n\t\t\t\t<spawn type=\"crustacean_swarmpincher_cold\" area=\"sp_path_left\" number=\"2\" number3=\"3\" delay=\"0\" />\n\n\t\t\t\t<spawn type=\"dwarf_rifleman_male_00\" area=\"sp_path_right\" number=\"2\" delay=\"4\" />\n\t\t\t\t<startVictoryCheck delay=\"2\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\t</phases>\n</level>"
+--joa_cha_crystal_cavern.xml = "<level>\n\t<initialize>\n\t\t<level>joa_cha_crystal_cavern</level>\n\t\t<gamemode type=\"time\">60</gamemode>\n\t\t<name>joa_challenge_summary_5_name</name>\n\t\t<description>joa_challenge_summary_5_desc</description>\n\t\t<victory>joa_challenge_summary_5_victory</victory>\n\t\t<defeat>joa_challenge_summary_5_defeat</defeat>\n\t\t<artifactSets>\n\t\t\t<artifactSet level=\"wizard\">\n\t\t\t\t<unlockMagick name=\"revive\" score=\"0\" />\n\t\t\t\t<unlockMagick name=\"haste\" score=\"30\" />\n\t\t\t\t<unlockMagick name=\"push\" score=\"30\" />\n\t\t\t</artifactSet>\n\t\t\t<artifactSet level=\"professor\">\n\t\t\t\t<modifier name=\"EnemyHealth\">3</modifier>\n\t\t\t\t<modifier name=\"EnemyMovementSpeed\">3</modifier>\n\t\t\t\t<modifier name=\"EnemyHealthRegeneration\">1</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"WizardHealth\">3</modifier>\n\t\t\t\t<modifier name=\"WSpeed\">3</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"WFRegen\">2</modifier>\n\t\t\t\t<unlockMagick name=\"revive\" score=\"10\" />\n\t\t\t\t<unlockMagick name=\"push\" score=\"30\" />\n\t\t\t</artifactSet>\n\t\t\t<artifactSet level=\"sage\">\t\t\t\t\n\t\t\t\t<modifier name=\"EnemyHealth\">4</modifier>\n\t\t\t\t<modifier name=\"EnemyMovementSpeed\">4</modifier>\n\t\t\t\t<modifier name=\"EnemyHealthRegeneration\">2</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"WizardHealth\">2</modifier>\n\t\t\t\t<modifier name=\"SpellWeight\">2</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"FRegenType\">1</modifier>\n\t\t\t\t<unlockMagick name=\"revive\" score=\"30\" />\n\t\t\t\t<unlockMagick name=\"dragon_strike\" score=\"50\" />\n\t\t\t</artifactSet>\n\t\t</artifactSets>\n\t</initialize>\n\n\t<!-- Phases run automatically and in order, one by one, and only progress to the next if victory is reached either manually or automatically. The first phase runs automatically. -->\n\n\t<phases>\n\t\t<phase delay=\"1\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<level_event name=\"init_time_challenge\" />\n\t\t\t\t<spawn type=\"crustacean_ranged\" area=\"sp_grotto1\" number=\"1\" number2=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"crustacean_ranged\" area=\"sp_grotto2\" number=\"1\" number2=\"2\" delay=\"3\" />\n\n\t\t\t\t<spawn type=\"goblin_rogue\" area=\"sp_arena\" number=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_ranger\" area=\"sp_arena\" number=\"2\" number3=\"3\" delay=\"0\" />\n\t\t\t\t<spawn type=\"goblin_warrior\" area=\"sp_arena\" number=\"1\" delay=\"0\" />\n\t\t\t\t<spawn type=\"orc_warrior_male_00\" area=\"sp_arena\" number=\"1\" number2=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"orc_warrior_noshield\" area=\"sp_arena\" number=\"1\" delay=\"0\" />\n\n\t\t\t\t<spawn type=\"crustacean_swarmpincher\" area=\"sp_path_left\" number=\"4\" number4=\"8\" delay=\"0\" />\n\t\t\t\t<spawn type=\"crustacean_swarmpincher_cold\" area=\"sp_path_left\" number=\"2\" number3=\"3\" delay=\"0\" />\n\n\t\t\t\t<spawn type=\"dwarf_rifleman_male_00\" area=\"sp_path_right\" number=\"2\" delay=\"4\" />\n\t\t\t\t<startVictoryCheck delay=\"2\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\t</phases>\n</level>"
+joa_cha_crystal_cavern.xml = [[
+<level>
+	<initialize>
+		<level>joa_cha_crystal_cavern</level>
+		<gamemode type="skill"></gamemode>
+		<name>joa_challenge_summary_5_name</name>
+		<description>joa_challenge_summary_5_desc</description>
+		<victory>joa_challenge_summary_5_victory</victory>
+		<defeat>joa_challenge_summary_5_defeat</defeat>
+		<artifactSets>
+			<artifactSet level="wizard">
+			</artifactSet>
+			<artifactSet level="professor">
+				<modifier name="EnemyHealth">3</modifier>
+				<modifier name="EnemyMovementSpeed">3</modifier>
+				<modifier name="EnemyHealthRegeneration">1</modifier>
+				<modifier name="WizardHealth">3</modifier>
+				<modifier name="WSpeed">3</modifier>
+				<modifier name="WFRegen">2</modifier>
+			</artifactSet>
+			<artifactSet level="sage">
+				<modifier name="EnemyHealth">4</modifier>
+				<modifier name="EnemyMovementSpeed">4</modifier>
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
 
 return joa_cha_crystal_cavern
