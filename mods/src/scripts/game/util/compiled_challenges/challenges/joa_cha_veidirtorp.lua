diff --git a/scripts/game/util/compiled_challenges/challenges/joa_cha_veidirtorp.lua b/scripts/game/util/compiled_challenges/challenges/joa_cha_veidirtorp.lua
index 48d4294..0780b9c 100644
--- a/scripts/game/util/compiled_challenges/challenges/joa_cha_veidirtorp.lua
+++ b/scripts/game/util/compiled_challenges/challenges/joa_cha_veidirtorp.lua
@@ -2,6 +2,41 @@
 
 local joa_cha_veidirtorp = {}
 
-joa_cha_veidirtorp.xml = "<level>\n\t<initialize>\n\t\t<level>joa_cha_veidirtorp</level>\n\t\t<gamemode type=\"time\">200</gamemode>\n\t\t<name>joa_challenge_summary_4_name</name>\n\t\t<description>joa_challenge_summary_4_desc</description>\n\t\t<victory>joa_challenge_summary_4_victory</victory>\n\t\t<defeat>joa_challenge_summary_4_defeat</defeat>\n\t\t<artifactSets>\n\t\t\t<artifactSet level=\"wizard\">\n\t\t\t\t<unlockMagick name=\"revive\" score=\"0\" />\n\t\t\t\t<unlockMagick name=\"haste\" score=\"30\" />\n\t\t\t</artifactSet>\n\t\t\t<artifactSet level=\"professor\">\n\t\t\t\t<modifier name=\"EnemyHealth\">3</modifier>\n\t\t\t\t<modifier name=\"EnemyMovementSpeed\">3</modifier>\n\t\t\t\t<modifier name=\"EnemyHealthRegeneration\">1</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"WizardHealth\">3</modifier>\n\t\t\t\t<modifier name=\"WSpeed\">3</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"WFRegen\">2</modifier>\n\t\t\t\t<unlockMagick name=\"revive\" score=\"10\" />\n\t\t\t\t<unlockMagick name=\"haste\" score=\"30\" />\n\t\t\t</artifactSet>\n\t\t\t<artifactSet level=\"sage\">\t\t\t\t\n\t\t\t\t<modifier name=\"EnemyHealth\">4</modifier>\n\t\t\t\t<modifier name=\"EnemyMovementSpeed\">4</modifier>\n\t\t\t\t<modifier name=\"EnemyHealthRegeneration\">2</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"WizardHealth\">2</modifier>\n\t\t\t\t<modifier name=\"SpellWeight\">2</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"FRegenType\">1</modifier>\n\t\t\t\t<unlockMagick name=\"revive\" score=\"30\" />\n\t\t\t\t<unlockMagick name=\"haste\" score=\"60\" />\n\t\t\t</artifactSet>\n\t\t</artifactSets>\n\t</initialize>\n\n\t<!-- Phases run automatically and in order, one by one, and only progress to the next if victory is reached either manually or automatically. The first phase runs automatically. -->\n\n\t<!--\n\tSummary of phases: NEEDS UPDATING\n\n\t 1. Goblins\n\t    Crustaceans\n\t    and a dwarf?\n\n\n\t-->\n\n\t<phases>\n\t\t<!-- Phase #1 - Goblin rogues -->\n\t\t<phase delay=\"1\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<!--level_event name=\"eventname\" /-->\n\t\t\t\t<spawn type=\"dwarf_rifleman_male_00\" area=\"sp_tent\" number=\"1\" number2=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"human_soldier_male\" area=\"sp_path_behind\" number=\"2\" number3=\"3\" number4=\"4\" delay=\"0\" />\n\t\t\t\t<spawn type=\"elf_warrior_male_00\" area=\"sp_path_forward\" number=\"3\" number2=\"4\" delay=\"0\" />\n\t\t\t\t<spawn type=\"human_soldier_pike_female\" area=\"sp_path_behind\" number=\"4\" number3=\"5\" number4=\"6\" delay=\"0\" />\n\t\t\t\t<spawn type=\"elf_priestess_female_00\" area=\"sp_tent\" number=\"1\" number4=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"orc_mortar_male_00\" area=\"sp_path_behind\" number=\"1\" number2=\"2\" number3=\"3\" delay=\"0\" />\n\t\t\t\t<spawn type=\"barbarian_elite\" area=\"sp_path_forward\" number=\"1\" number2=\"2\" number3=\"3\" delay=\"0\" />\n\t\t\t\t<spawn type=\"barbarian_crone_female_00\" area=\"sp_path_behind\" number=\"1\" number4=\"2\" delay=\"0\" />\n\t\t\t\t<startVictoryCheck delay=\"2\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\t</phases>\n</level>"
+--joa_cha_veidirtorp.xml = "<level>\n\t<initialize>\n\t\t<level>joa_cha_veidirtorp</level>\n\t\t<gamemode type=\"time\">200</gamemode>\n\t\t<name>joa_challenge_summary_4_name</name>\n\t\t<description>joa_challenge_summary_4_desc</description>\n\t\t<victory>joa_challenge_summary_4_victory</victory>\n\t\t<defeat>joa_challenge_summary_4_defeat</defeat>\n\t\t<artifactSets>\n\t\t\t<artifactSet level=\"wizard\">\n\t\t\t\t<unlockMagick name=\"revive\" score=\"0\" />\n\t\t\t\t<unlockMagick name=\"haste\" score=\"30\" />\n\t\t\t</artifactSet>\n\t\t\t<artifactSet level=\"professor\">\n\t\t\t\t<modifier name=\"EnemyHealth\">3</modifier>\n\t\t\t\t<modifier name=\"EnemyMovementSpeed\">3</modifier>\n\t\t\t\t<modifier name=\"EnemyHealthRegeneration\">1</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"WizardHealth\">3</modifier>\n\t\t\t\t<modifier name=\"WSpeed\">3</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"WFRegen\">2</modifier>\n\t\t\t\t<unlockMagick name=\"revive\" score=\"10\" />\n\t\t\t\t<unlockMagick name=\"haste\" score=\"30\" />\n\t\t\t</artifactSet>\n\t\t\t<artifactSet level=\"sage\">\t\t\t\t\n\t\t\t\t<modifier name=\"EnemyHealth\">4</modifier>\n\t\t\t\t<modifier name=\"EnemyMovementSpeed\">4</modifier>\n\t\t\t\t<modifier name=\"EnemyHealthRegeneration\">2</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"WizardHealth\">2</modifier>\n\t\t\t\t<modifier name=\"SpellWeight\">2</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"FRegenType\">1</modifier>\n\t\t\t\t<unlockMagick name=\"revive\" score=\"30\" />\n\t\t\t\t<unlockMagick name=\"haste\" score=\"60\" />\n\t\t\t</artifactSet>\n\t\t</artifactSets>\n\t</initialize>\n\n\t<!-- Phases run automatically and in order, one by one, and only progress to the next if victory is reached either manually or automatically. The first phase runs automatically. -->\n\n\t<!--\n\tSummary of phases: NEEDS UPDATING\n\n\t 1. Goblins\n\t    Crustaceans\n\t    and a dwarf?\n\n\n\t-->\n\n\t<phases>\n\t\t<!-- Phase #1 - Goblin rogues -->\n\t\t<phase delay=\"1\">\n\t\t\t<actions delay=\"0\">\n\t\t\t\t<!--level_event name=\"eventname\" /-->\n\t\t\t\t<spawn type=\"dwarf_rifleman_male_00\" area=\"sp_tent\" number=\"1\" number2=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"human_soldier_male\" area=\"sp_path_behind\" number=\"2\" number3=\"3\" number4=\"4\" delay=\"0\" />\n\t\t\t\t<spawn type=\"elf_warrior_male_00\" area=\"sp_path_forward\" number=\"3\" number2=\"4\" delay=\"0\" />\n\t\t\t\t<spawn type=\"human_soldier_pike_female\" area=\"sp_path_behind\" number=\"4\" number3=\"5\" number4=\"6\" delay=\"0\" />\n\t\t\t\t<spawn type=\"elf_priestess_female_00\" area=\"sp_tent\" number=\"1\" number4=\"2\" delay=\"0\" />\n\t\t\t\t<spawn type=\"orc_mortar_male_00\" area=\"sp_path_behind\" number=\"1\" number2=\"2\" number3=\"3\" delay=\"0\" />\n\t\t\t\t<spawn type=\"barbarian_elite\" area=\"sp_path_forward\" number=\"1\" number2=\"2\" number3=\"3\" delay=\"0\" />\n\t\t\t\t<spawn type=\"barbarian_crone_female_00\" area=\"sp_path_behind\" number=\"1\" number4=\"2\" delay=\"0\" />\n\t\t\t\t<startVictoryCheck delay=\"2\" condition=\"all_units_are_dead\" />\n\t\t\t</actions>\n\t\t</phase>\n\t</phases>\n</level>"
+joa_cha_veidirtorp.xml = [[
+<level>
+	<initialize>
+		<level>joa_cha_veidirtorp</level>
+		<gamemode type="skill"></gamemode>
+		<name>joa_challenge_summary_4_name</name>
+		<description>joa_challenge_summary_4_desc</description>
+		<victory>joa_challenge_summary_4_victory</victory>
+		<defeat>joa_challenge_summary_4_defeat</defeat>
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
 
 return joa_cha_veidirtorp
