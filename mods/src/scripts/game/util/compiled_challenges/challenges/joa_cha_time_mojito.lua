diff --git a/scripts/game/util/compiled_challenges/challenges/joa_cha_time_mojito.lua b/scripts/game/util/compiled_challenges/challenges/joa_cha_time_mojito.lua
index abfd8ce..4ea589a 100644
--- a/scripts/game/util/compiled_challenges/challenges/joa_cha_time_mojito.lua
+++ b/scripts/game/util/compiled_challenges/challenges/joa_cha_time_mojito.lua
@@ -3,5 +3,39 @@
 local joa_cha_time_mojito = {}
 
 joa_cha_time_mojito.xml = "<level>\n\t<initialize>\n\t\t<level>joa_cha_time_mojito</level>\n\t\t<gamemode type=\"time\">40</gamemode> <!-- 10min 05s -->\n\t\t<name>joa_trial_summary_6_name</name>\n\t\t<description>joa_trial_summary_6_desc</description>\n\t\t<victory>joa_trial_summary_6_victory</victory>\n\t\t<defeat>joa_trial_summary_6_defeat</defeat>\n\t\t<artifactSets>\n\t\t\t<artifactSet level=\"wizard\">\t\t\t\t\n\t\t\t</artifactSet>\n\t\t\t<artifactSet level=\"professor\">\n\t\t\t\t<modifier name=\"TimerDeathPenalty\">2</modifier>\n\t\t\t\t<modifier name=\"EnemyHealth\">3</modifier>\t\t\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"EnemyHealthRegeneration\">1</modifier>\t\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"WizardHealth\">3</modifier>\n\t\t\t\t<modifier name=\"WSpeed\">3</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"WFRegen\">2</modifier>\t\t\t\t\n\t\t\t</artifactSet>\n\t\t\t<artifactSet level=\"sage\">\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"TimerDeathPenalty\">3</modifier>\n\t\t\t\t<modifier name=\"EnemyHealth\">4</modifier>\n\t\t\t\t<modifier name=\"EnemyHealthRegeneration\">2</modifier>\t\t\t\t\t\t\n\t\t\t\t<modifier name=\"WizardHealth\">2</modifier>\n\t\t\t\t<modifier name=\"SpellWeight\">2</modifier>\t\t\t\t\n\t\t\t\t<modifier name=\"FRegenType\">1</modifier>\t\t\t\t\n\t\t\t</artifactSet>\n\t\t</artifactSets>\n\t</initialize>\n\t<phases>\n\t</phases>\n</level>"
+joa_cha_time_mojito.xml2 = [[
+<level>
+	<initialize>
+		<level>joa_cha_time_mojito</level>
+		<gamemode type="skill"></gamemode>
+		<name>joa_trial_summary_6_name</name>
+		<description>joa_trial_summary_6_desc</description>
+		<victory>joa_trial_summary_6_victory</victory>
+		<defeat>joa_trial_summary_6_defeat</defeat>
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
+	<phases>
+	</phases>
+</level>
+]]
 
 return joa_cha_time_mojito
