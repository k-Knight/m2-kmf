diff --git a/foundation/scripts/network/network_settings.win32.lua b/foundation/scripts/network/network_settings.win32.lua
index ebff170..ebb05d8 100644
--- a/foundation/scripts/network/network_settings.win32.lua
+++ b/foundation/scripts/network/network_settings.win32.lua
@@ -1,4 +1,4 @@
--- chunkname: @foundation/scripts/network/network_settings.win32.lua
+﻿-- chunkname: @foundation/scripts/network/network_settings.win32.lua
 
 NetworkSettings = {
 	lobby_port = 51623,
@@ -8,3 +8,4449 @@ NetworkSettings = {
 	max_num_players = 8,
 	game_type = "Change Me"
 }
+
+Application.is_win32 = function()
+	return Application.platform() == "win32"
+end
+
+rawset(_G, "kmf", {})
+_G.kmf.settings = {}
+_G.kmf.vars = {}
+_G.kmf.const = {}
+_G.kmf.download_url = "https://raw.githubusercontent.com/k-Knight/m2-kmf/master/installer.exe" -- for user convenience
+
+local load_debugger = function()
+	rawset(_G, "my_debugger", {})
+	_G.my_debugger.ffi = require("ffi")
+	_G.my_debugger.ffi.cdef([[
+		int __cdecl setup_IPC();
+		void __cdecl my_free(void *Block);
+		void __cdecl console_log(const char *message);
+		void __cdecl print(const char *message);
+		int __cdecl check_exec_queue(char **ptr, unsigned int *size);
+	]])
+
+	if Application.is_win32() then
+		_G.my_debugger.c_dbg = _G.my_debugger.ffi.load(".\\attacher.dll")
+	else
+		_G.my_debugger.c_dbg = _G.my_debugger.ffi.load(".\\libattacher.so")
+	end
+
+	local ret = _G.my_debugger.c_dbg.setup_IPC()
+
+	if ret == 0 then
+		print("FAILED TO ATTACH TO DEBUGGER !!!")
+
+		_G.my_debugger.exec_string = function(...) end
+		_G.my_debugger.check_exec_queue = function(...) end
+		rawset(_G, "k_log", function(...) kmf_print(...) end)
+	else
+		_G.my_debugger.exec_string = function(command)
+			local exec_fun = assert(loadstring(command))
+			if exec_fun ~= nil then
+				local status, err = pcall(exec_fun)
+				if status ~= true then
+					local msg = tostring(err)
+					_G.my_debugger.c_dbg.console_log(msg)
+				end
+			end
+		end
+
+		_G.my_debugger.check_exec_queue = function()
+			local msg = _G.my_debugger.ffi.new("char *[?]", 1)
+			local len = _G.my_debugger.ffi.new("unsigned long[?]", 1)
+			local status = _G.my_debugger.c_dbg.check_exec_queue(msg, len)
+			if status == 1 then
+				local command = _G.my_debugger.ffi.string(msg[0], len[0])
+				_G.my_debugger.c_dbg.my_free(msg[0])
+				local status, err = pcall(_G.my_debugger.exec_string, command)
+				if status ~= true then
+					local msg = tostring(err)
+					_G.my_debugger.c_dbg.console_log(msg)
+				end
+			end
+		end
+
+		rawset(_G, "k_log", function(msg)
+			local to_print = nil
+			if type(msg) == "string" then
+				to_print = msg
+			else
+				to_print = tostring(msg)
+			end
+			local ffi =  _G.my_debugger.ffi
+
+			if ffi then
+				local ffi_str = ffi.new("char[?]", #to_print + 1)
+
+				ffi.copy(ffi_str, to_print)
+				_G.my_debugger.c_dbg.console_log(ffi_str)
+			end
+		end)
+	end
+
+	return ret
+end
+
+local load_attacher = function()
+	rawset(_G, "my_attacher", {})
+	_G.my_attacher.ffi = require("ffi")
+
+	local status, err = pcall(function()
+		_G.my_attacher.ffi.cdef([[
+			int __cdecl try_download_installer(const char *url);
+			void __cdecl enable_stdout_logging();
+			int __cdecl try_setup_lua_state_getter();
+			int __cdecl register_global_dofile();
+			void __cdecl my_free(void *Block);
+			char *__cdecl try_get_request_or_cache(const char *url, const char *file_name);
+		]])
+
+		if Application.is_win32() then
+			_G.my_attacher.c_atch = _G.my_attacher.ffi.load(".\\attacher.dll")
+		else
+			_G.my_attacher.c_atch = _G.my_attacher.ffi.load(".\\libattacher.so")
+		end
+	end)
+
+	_G.my_attacher.c_atch.enable_stdout_logging()
+	local setup_res = tonumber(_G.my_attacher.c_atch.try_setup_lua_state_getter())
+	print("[KMF] lua state getter setup result :: " .. tostring(setup_res))
+
+	_G.my_attacher.try_download_installer = function(url)
+		local ffi = _G.my_attacher.ffi
+
+		local c_url = ffi.new("char [?]", #url + 1)
+		ffi.copy(c_url, url)
+
+		return tonumber(_G.my_attacher.c_atch.try_download_installer(c_url))
+	end
+
+	_G.kmf.try_register_dofile = function()
+		local ret = tonumber(_G.my_attacher.c_atch.register_global_dofile())
+
+		if ret ~= 0 then
+			print("[KMF] failed to register global dofile :: " .. tostring(ret))
+		end
+	end
+
+	_G.kmf.check_available_kmf_version = function()
+		local ffi = _G.my_attacher.ffi
+		local url = "https://raw.githubusercontent.com/k-Knight/m2-kmf/master/kmf_version.txt"
+		local cache_name = "kmf_version.txt"
+		local c_url = ffi.new("char [?]", #url + 1)
+		local c_f_name = ffi.new("char [?]", #cache_name + 1)
+
+		ffi.copy(c_url, url)
+		ffi.copy(c_f_name, cache_name)
+
+		local tmp = _G.my_attacher.c_atch.try_get_request_or_cache(c_url, c_f_name)
+		local version_text = ffi.string(tmp)
+
+		_G.my_debugger.c_dbg.my_free(tmp)
+
+		_G.kmf.available_version = tonumber(version_text)
+		print("avaialbe kmf version for download :: " .. tostring(_G.kmf.available_version))
+
+		return _G.kmf.available_version
+	end
+end
+
+local status, err = pcall(load_debugger)
+if status ~= true then
+	rawset(_G, "my_debugger", nil)
+	rawset(_G, "k_log",  function (msg)
+		print(str)
+	end)
+	rawset(_G, "kmf_enable_debug", false)
+else
+	rawset(_G, "kmf_enable_debug", tostring(err) == "1")
+end
+
+status, err = pcall(load_attacher)
+if status ~= true then
+	print("\n\n[KMF] FAILED TO LOAD ATTACHER ::\n" .. tostring(err) .. "\n")
+	print("\n\n[KMF] CRITICAL COMPONENT MISSING, shutting down...\n")
+	Application.quit()
+end
+
+local load_settings_manager = function()
+	kmf.mod_settings_manager = {}
+	kmf.mod_settings_manager.ffi = require("ffi")
+	local ffi = kmf.mod_settings_manager.ffi
+	local new_mod_config = ""
+	local c_decls = [[
+		typedef struct {
+			char *name;
+			char *value;
+		} ModSetting;
+
+		typedef struct {
+			char *mod_name;
+			bool enabled;
+			size_t setting_length;
+			ModSetting *setting_data;
+		} ModData;
+
+		typedef struct {
+			ModData *data;
+			size_t length;
+		} ModDataArray;
+
+		void __cdecl update_config_file(char *config_str);
+		void __cdecl lock_mod_settings();
+		void __cdecl unlock_mod_settings();
+		ModDataArray *__cdecl get_mod_settings();
+		void __cdecl display_settings_menu();
+		void __cdecl launch_installer();
+		bool __cdecl gamepad_btn_pressed(int btn);
+		void __cdecl tmp_enable_mod(const char *name);
+		void __cdecl tmp_disable_mod(const char *name);
+		void __cdecl clear_tmp_mod_state();
+
+		bool __cdecl try_init_keyboard_watcher();
+		void __cdecl set_kbd_mapping(const char *mapping);
+		void __cdecl order_inputs_by_time(char *elem_str);
+
+		float __cdecl generate_radom_number();
+		int __cdecl generate_uniform_from_to(int min, int max);
+		int __cdecl generate_my_random_from_to(int min, int max);
+		bool __cdecl generate_bernoulli(float p);
+	]]
+
+	kmf.gamepad_buttons = {}
+	kmf.gamepad_buttons["d_up"] = 0
+	kmf.gamepad_buttons["d_down"] = 1
+	kmf.gamepad_buttons["d_left"] = 2
+	kmf.gamepad_buttons["d_right"] = 3
+	kmf.gamepad_buttons["start"] = 4
+	kmf.gamepad_buttons["back"] = 5
+	kmf.gamepad_buttons["left_thumb"] = 6
+	kmf.gamepad_buttons["right_thumb"] = 7
+	kmf.gamepad_buttons["left_shoulder"] = 8
+	kmf.gamepad_buttons["right_shoulder"] = 9
+	kmf.gamepad_buttons["left_trigger"] = 10
+	kmf.gamepad_buttons["right_trigger"] = 11
+	kmf.gamepad_buttons["a"] = 12
+	kmf.gamepad_buttons["b"] = 13
+	kmf.gamepad_buttons["x"] = 14
+	kmf.gamepad_buttons["y"] = 15
+
+	ffi.cdef(c_decls)
+	if Application.is_win32() then
+		kmf.mod_settings_manager.c_mod_mngr = ffi.load(".\\kmf_util.dll")
+	else
+		kmf.mod_settings_manager.c_mod_mngr = ffi.load(".\\libkmf_util.so")
+	end
+end
+
+status, err = pcall(load_settings_manager)
+if status ~= true then
+	k_log("\n\n\nFAILED TO LOAD SETTINGS MANAGER ::\n\n" .. tostring(err) .. "\n\n\n\n\n")
+end
+
+kmf.check_mod_enabled = function(setting_name)
+	local setting = kmf.settings[setting_name]
+
+	if setting then
+		return setting.enabled
+	else
+		return false
+	end
+end
+
+kmf.get_mod_option = function(setting_name, option_name)
+	local setting = kmf.settings[setting_name]
+
+	if setting and setting.options then
+		return setting.options[option_name]
+	end
+
+	return nil
+end
+
+kmf.generate_radom_number = function()
+	return kmf.mod_settings_manager.c_mod_mngr.generate_radom_number()
+end
+
+kmf.generate_uniform_from_to = function(min, max)
+	if type(min) ~= "number" or type(max) ~= "number" then
+		return
+	end
+
+	return kmf.mod_settings_manager.c_mod_mngr.generate_uniform_from_to(min, max)
+end
+
+kmf.generate_my_random_from_to = function(min, max)
+	if type(min) ~= "number" or type(max) ~= "number" then
+		return
+	end
+
+	return kmf.mod_settings_manager.c_mod_mngr.generate_my_random_from_to(min, max)
+end
+
+kmf.generate_bernoulli = function(p)
+	if type(p) ~= "number" then
+		return
+	end
+
+	return kmf.mod_settings_manager.c_mod_mngr.generate_bernoulli(p) == true
+end
+
+kmf.gamepad_btn_down = function(btn)
+	local btn_id = kmf.gamepad_buttons[btn]
+
+	if btn_id == nil then
+		return false
+	end
+
+	return kmf.mod_settings_manager.c_mod_mngr.gamepad_btn_pressed(btn_id) == true
+end
+
+kmf.get_mod_settings = function()
+	if kmf.mod_settings_manager ~= nil then
+		kmf.mod_settings_manager.counter = kmf.mod_settings_manager.counter + 1
+		if kmf.mod_settings_manager.counter == 60 then
+			kmf.mod_settings_manager.counter = 0
+			kmf.mod_settings_manager.c_mod_mngr.unlock_mod_settings()
+			kmf.mod_settings_manager.c_mod_mngr.lock_mod_settings()
+			local mod_data_array = kmf.mod_settings_manager.c_mod_mngr.get_mod_settings()
+			local ffi = kmf.mod_settings_manager.ffi
+			local mod_data_len = tonumber(mod_data_array.length)
+
+			for i = 0, mod_data_len - 1 do
+				local mod_data = mod_data_array.data[i]
+				local mod_opt_len = tonumber(mod_data.setting_length)
+				local mod_name = ffi.string(mod_data.mod_name)
+				local mod_setting = kmf.settings[mod_name]
+
+				mod_setting.enabled = mod_data.enabled == true
+
+				for j = 0, mod_opt_len - 1 do
+					local option = mod_data.setting_data[j]
+					local option_name = ffi.string(option.name)
+					local option_value = ffi.string(option.value)
+
+					if option_name == "keyboard hotkey" then
+						mod_setting.options["keyboard_hotkey"] = kmf.parse_hotkey_setting("keyboard", option_value)
+					elseif option_name == "gamepad hotkey" then
+						mod_setting.options["gamepad_hotkey"] = kmf.parse_hotkey_setting("gamepad", option_value)
+					else
+						mod_setting.options[option_name] = option_value
+					end
+				end
+			end
+
+			kmf.mod_settings_manager.c_mod_mngr.unlock_mod_settings()
+		end
+	end
+end
+
+kmf.try_init_kbd_watcher = function()
+	kmf.kbd_watcher_initialized = kmf.mod_settings_manager.c_mod_mngr.try_init_keyboard_watcher() == true
+end
+
+kmf.kbd_watcher_set_kbd_mapping = function()
+	if not kmf.kbd_watcher_initialized then
+		return
+	end
+
+	local mapping = PlayerControllerSettings.default.active.keyboard_mouse
+	local ffi = _G.kmf.mod_settings_manager.ffi
+
+	local mapping_str = ""
+	local not_first = false
+	for _, fun_key in ipairs(mapping) do
+		if fun_key.output and fun_key.key then
+			if not_first then
+				mapping_str = mapping_str .. ";"
+			end
+			not_first = true
+			mapping_str = mapping_str .. tostring(fun_key.output) .. ":" .. tostring(fun_key.key)
+		end
+	end
+
+	local ffi_mapping_str = ffi.new("char[?]", #mapping_str + 1)
+	ffi.copy(ffi_mapping_str, mapping_str)
+
+	kmf.mod_settings_manager.c_mod_mngr.set_kbd_mapping(ffi_mapping_str)
+end
+
+kmf.kbd_watcher_order_inputs_by_time = function(elem_str)
+	if not kmf.kbd_watcher_initialized then
+		return
+	end
+
+	local ffi = _G.kmf.mod_settings_manager.ffi
+	local ffi_elem_str = ffi.new("char[?]", #elem_str + 1)
+
+	ffi.copy(ffi_elem_str, elem_str)
+	kmf.mod_settings_manager.c_mod_mngr.order_inputs_by_time(ffi_elem_str)
+
+	return ffi.string(ffi_elem_str)
+end
+
+kmf.tmp_enable_mod = function(name)
+	kmf.mod_settings_manager.void_c_str_call(kmf.mod_settings_manager.c_mod_mngr.tmp_enable_mod, name)
+end
+
+kmf.tmp_disable_mod = function(name)
+	kmf.mod_settings_manager.void_c_str_call(kmf.mod_settings_manager.c_mod_mngr.tmp_disable_mod, name)
+end
+
+kmf.clear_tmp_mod_state = function(name)
+	kmf.mod_settings_manager.c_mod_mngr.clear_tmp_mod_state()
+end
+
+kmf_init_localisation = function()
+	kmf_localisation = {}
+	kmf_localisation["default"] = {
+		no_access_message = "It appears that You do not have access to Magicka 2 mods.\nPerhaps You want to join The Magicka College to gain access?",
+		new_version_message = "There is a new version of mods available, do you wish to skip downloading new version and continue?",
+		mod_settings_btn = "MOD SETTINGS",
+		mod_settings_player_btn = "Mod Settings",
+		become_spectator_player_btn = "Become Spectator",
+		reset_player_btn = "Reset Player",
+		reset_player_btn_requirement = "Player must be alive and\nbe fully healed.",
+		sync_mods_player_btn = "Sync Mods",
+		downloading_installer_message = "Downloading installer for the new version, please wait ...",
+		return_from_spec_btn = "Become Player",
+	}
+	kmf_localisation["ru"] = {
+		no_access_message = "Похоже у вас нет доступа к модам.\nВозможно вы хотите присоединиться в The Magicka College чтобы получить доступ?",
+		new_version_message = "Доступна новая версия модов, хотители ли вы пропустить загрузку новой версии и продолжить?",
+		mod_settings_btn = "НАСТРОЙКИ\nМОДОВ",
+		mod_settings_player_btn = "Настройки Модов",
+		become_spectator_player_btn = "Cтать Наблюдателем",
+		reset_player_btn = "Перезагрузить Игрока",
+		sync_mods_player_btn = "Синхронизировать Моды",
+		reset_player_btn_requirement = "Игрок должен быть жив\nи полностью здоров.",
+		downloading_installer_message = "Загрузка установщика новой версии, пожалуйста подождите ...",
+		return_from_spec_btn = "Cтать Игроком",
+	}
+	kmf_localisation["de"] = {
+		no_access_message = "Es scheint so, als hättest du keinen Zugang zu Magicka 2 Modifikationen.\nÜberlege dir, dich dem Magicka 2 College anzuschließen, um Zugang zu bekommen.",
+		new_version_message = "Es gibt eine neuere Version der Modifikationen. Willst du das Herunterladen der neuen Version überspringen um fortzufahren?",
+		mod_settings_btn = "MOD EINSTELLUNGEN",
+		mod_settings_player_btn = "Mod Einstellungen",
+		become_spectator_player_btn = "Zuschauer Werden",
+		reset_player_btn = "Spieler Zurücksetzen",
+		reset_player_btn_requirement = "Der Spieler muss am Leben\nund vollständig\ngeheilt sein.",
+		sync_mods_player_btn = "Mods Synchronisieren",
+		downloading_installer_message = "Installationsprogramm für die neue version wird heruntergeladen, bitte warten ...",
+		return_from_spec_btn = "Spieler Werden",
+	}
+	kmf_localisation["es"] = {
+		no_access_message = "Parece que no tienes permision para acceder los mods de Magicka 2.\nTalvez quieres unirte a The Magicka College para optener acceso?",
+		new_version_message = "Hay una version nueva de los mods disponible, quieres saltar la descarga y continuar?",
+		mod_settings_btn = "CONFIGURACION\nDE MODS",
+		mod_settings_player_btn = "Configuracion de mods",
+		become_spectator_player_btn = "Convertirse en Espectador",
+		reset_player_btn = "Reiniciar Jugador",
+		reset_player_btn_requirement = "El jugador debe estar vivo\ny completamente curado.",
+		sync_mods_player_btn = "Sincronizar Mods",
+		downloading_installer_message = "Descargando el instalador para la nueva versión, espere, por favor ...",
+		return_from_spec_btn = "Convertirse en Jugador",
+	}
+	kmf_localisation["pl"] = {
+		no_access_message = "Wygląda na to że nie masz dostępu do modów do gry Magicka 2.\nByć może chcesz dołączyć do Magicka College aby uzyskać do nich dostęp?",
+		new_version_message = "Jest dostępna nowa wersja modów, czy chcesz pominąć pobieranie nowej wersji i kontynuować?",
+		mod_settings_btn = "USTAWIENIA MODÓW",
+		mod_settings_player_btn = "Ustawienia Modów",
+		become_spectator_player_btn = "Tryb Obserwatora",
+		reset_player_btn = "Zresetuj Gracza",
+		reset_player_btn_requirement = "Gracz musi żyć i być\nw pełni wyleczony.",
+		sync_mods_player_btn = "Zsynchronizuj Mody",
+		downloading_installer_message = "Pobieranie nowej wersji instalatora, proszę czekać ...",
+		return_from_spec_btn = "Tryb Gracza",
+	}
+
+	kmf_localisation_lookup = function(string)
+		local current_language = LocalizationManager:get_language()
+		local lang = kmf_localisation[current_language]
+
+		if not lang then
+			lang = kmf_localisation["default"]
+		end
+
+		if lang[string] then
+			return lang[string]
+		end
+
+		return string
+	end
+end
+kmf_init_localisation()
+
+kmf.append_translations = function(language, strings)
+	local localisation = kmf_localisation[language] or {}
+
+	for k, v in pairs(strings) do
+		localisation[k] = v
+	end
+
+	kmf_localisation[language] = localisation
+end
+
+function kmf_log_table_helper(table, depth, indent)
+	local accum = ""
+
+	if type(table) ~= "table" then
+		accum = accum .. type(table) .. " is not a table type !!!\n"
+		return accum
+	end
+
+	if not depth or type(depth) ~= "number" or depth < 0 then
+		return accum
+	end
+
+	if not indent or type(indent) ~= "string" then
+		indent = "    "
+	end
+
+	local depth_left = depth - 1
+	local new_indent = indent .. "    "
+
+	for k, v in pairs(table) do
+		accum = accum .. indent .. tostring(k) .. " :: " .. type(v) .. " :: " .. tostring(v) .. "\n"
+		if type(v) == "table" then
+			accum = accum .. kmf_log_table_helper(v, depth_left, new_indent)
+		end
+	end
+
+	return accum
+end
+
+function kmf_log_table(table, depth, indent)
+	local res = kmf_log_table_helper(table, depth, indent)
+	k_log(res)
+end
+
+function kmf_snitch_table(table, table_name, on_get, on_set)
+	local src = {}
+	local name = type(table_name) == "string" and "[" .. table_name .. "]" or ""
+
+	for k, v in pairs(table) do
+		src[k] = v
+		table[k] = nil
+	end
+
+	local mt = {
+		__index = function(t, k)
+			k_log(name .. " get :: " .. tostring(k))
+
+			if on_get then
+				on_get(src, t, k)
+			end
+
+			return src[k]
+		end,
+
+		__newindex = function(t, k, v)
+			k_log(name .. " set :: " .. tostring(k) .. " = " .. tostring(v))
+
+			if on_set then
+				on_set(src, t, k, v)
+			end
+
+			src[k] = v
+		end
+	}
+
+	setmetatable(table, mt)
+end
+
+
+function kmf_table_2_json(table, depth, indent)
+	if not indent or type(indent) ~= "string" then
+		indent = ""
+	end
+
+	local str = indent .. "{"
+	if type(table) ~= "table" then
+		str = str .. type(table) .. " is not a table type !!!\n"
+		return ""
+	end
+
+	if not depth or type(depth) ~= "number" or depth < 0 then
+		return ""
+	end
+
+	local depth_left = depth - 1
+	local new_indent = indent .. "    "
+	local pending_comma = false
+
+	for k, v in pairs(table) do
+		if pending_comma then
+			str = str .. ",\n"
+		else
+			str = str .. "\n"
+		end
+
+		local var_type = type(v)
+
+		if var_type == "boolean" or var_type == "number" then
+			str = str .. new_indent .. "\"" .. tostring(k) .. "\": " .. tostring(v)
+			pending_comma = true
+		elseif var_type == "table" then
+			if depth_left < 0 then
+				str = str .. new_indent .. "\"" .. tostring(k) .. "\": null"
+				pending_comma = true
+			else
+				str = str .. new_indent .. "\"" .. tostring(k) .. "\":\n"
+			end
+		else
+			str = str .. new_indent .. "\"" .. tostring(k) .. "\": \"" .. tostring(v) .. "\""
+			pending_comma = true
+		end
+
+		if depth_left >= 0 and var_type == "table" then
+			str = str .. kmf_table_2_json(v, depth_left, new_indent)
+			pending_comma = true
+		end
+	end
+
+	return str .. "\n" .. indent .. "}"
+end
+
+function kmf_dump_table(name, table, depth)
+	local file_name = name .. string.format("%.2f", os.clock()):gsub("%.", "_") .. ".json"
+	local content = kmf_table_2_json(table, depth)
+
+	local file = io.open(file_name, "w")
+	io.output(file)
+	io.write(content)
+	io.close(file)
+	io.output(nil)
+end
+
+kmf.early_init = function()
+	kmf.init_valid_keys = function()
+		kmf.valid_keys = {}
+
+		kmf.valid_keys.keyboard = {}
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "f1"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "f2"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "f3"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "f4"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "f5"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "f6"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "f7"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "f8"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "f9"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "f10"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "f11"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "f12"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "alt"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "ctrl"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "shift"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "enter"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "space"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "insert"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "delete"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "backspace"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "tab"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "minus"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "equal"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "home"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "end"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "pageup"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "pagedown"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "up"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "down"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "left"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "right"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "0"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "1"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "2"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "3"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "4"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "5"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "6"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "7"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "8"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "9"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "mouse_forward"
+		kmf.valid_keys.keyboard[#kmf.valid_keys.keyboard + 1] = "mouse_backward"
+
+		kmf.valid_keys.gamepad = {}
+
+		kmf.valid_keys.gamepad.xbox = {}
+		kmf.valid_keys.gamepad.xbox[#kmf.valid_keys.gamepad.xbox + 1] = "d_up"
+		kmf.valid_keys.gamepad.xbox[#kmf.valid_keys.gamepad.xbox + 1] = "d_down"
+		kmf.valid_keys.gamepad.xbox[#kmf.valid_keys.gamepad.xbox + 1] = "d_left"
+		kmf.valid_keys.gamepad.xbox[#kmf.valid_keys.gamepad.xbox + 1] = "d_right"
+		kmf.valid_keys.gamepad.xbox[#kmf.valid_keys.gamepad.xbox + 1] = "start"
+		kmf.valid_keys.gamepad.xbox[#kmf.valid_keys.gamepad.xbox + 1] = "back"
+		kmf.valid_keys.gamepad.xbox[#kmf.valid_keys.gamepad.xbox + 1] = "left_thumb"
+		kmf.valid_keys.gamepad.xbox[#kmf.valid_keys.gamepad.xbox + 1] = "right_thumb"
+		kmf.valid_keys.gamepad.xbox[#kmf.valid_keys.gamepad.xbox + 1] = "left_shoulder"
+		kmf.valid_keys.gamepad.xbox[#kmf.valid_keys.gamepad.xbox + 1] = "right_shoulder"
+		kmf.valid_keys.gamepad.xbox[#kmf.valid_keys.gamepad.xbox + 1] = "left_trigger"
+		kmf.valid_keys.gamepad.xbox[#kmf.valid_keys.gamepad.xbox + 1] = "right_trigger"
+		kmf.valid_keys.gamepad.xbox[#kmf.valid_keys.gamepad.xbox + 1] = "a"
+		kmf.valid_keys.gamepad.xbox[#kmf.valid_keys.gamepad.xbox + 1] = "b"
+		kmf.valid_keys.gamepad.xbox[#kmf.valid_keys.gamepad.xbox + 1] = "x"
+		kmf.valid_keys.gamepad.xbox[#kmf.valid_keys.gamepad.xbox + 1] = "y"
+
+		kmf.valid_keys.gamepad.ps = {}
+		kmf.valid_keys.gamepad.ps[#kmf.valid_keys.gamepad.ps + 1] = "up"
+		kmf.valid_keys.gamepad.ps[#kmf.valid_keys.gamepad.ps + 1] = "down"
+		kmf.valid_keys.gamepad.ps[#kmf.valid_keys.gamepad.ps + 1] = "left"
+		kmf.valid_keys.gamepad.ps[#kmf.valid_keys.gamepad.ps + 1] = "right"
+		kmf.valid_keys.gamepad.ps[#kmf.valid_keys.gamepad.ps + 1] = "options"
+		kmf.valid_keys.gamepad.ps[#kmf.valid_keys.gamepad.ps + 1] = "share"
+		kmf.valid_keys.gamepad.ps[#kmf.valid_keys.gamepad.ps + 1] = "l3"
+		kmf.valid_keys.gamepad.ps[#kmf.valid_keys.gamepad.ps + 1] = "r3"
+		kmf.valid_keys.gamepad.ps[#kmf.valid_keys.gamepad.ps + 1] = "l1"
+		kmf.valid_keys.gamepad.ps[#kmf.valid_keys.gamepad.ps + 1] = "r1"
+		kmf.valid_keys.gamepad.ps[#kmf.valid_keys.gamepad.ps + 1] = "l2"
+		kmf.valid_keys.gamepad.ps[#kmf.valid_keys.gamepad.ps + 1] = "r2"
+		kmf.valid_keys.gamepad.ps[#kmf.valid_keys.gamepad.ps + 1] = "cross"
+		kmf.valid_keys.gamepad.ps[#kmf.valid_keys.gamepad.ps + 1] = "circle"
+		kmf.valid_keys.gamepad.ps[#kmf.valid_keys.gamepad.ps + 1] = "square"
+		kmf.valid_keys.gamepad.ps[#kmf.valid_keys.gamepad.ps + 1] = "triangle"
+	end
+
+	kmf.init_valid_keys()
+
+	kmf.get_valid_btn = function(btn_type, btn_str)
+		if btn_type == "keyboard" then
+			for _, key in ipairs(kmf.valid_keys.keyboard) do
+				if key == btn_str then
+					return key
+				end
+			end
+		elseif btn_type == "gamepad" then
+			for i, key in ipairs(kmf.valid_keys.gamepad.xbox) do
+				if key == btn_str then
+					return key
+				end
+			end
+
+			for i, key in ipairs(kmf.valid_keys.gamepad.ps) do
+				if key == btn_str then
+					return kmf.valid_keys.gamepad.xbox[i]
+				end
+			end
+		end
+
+		return nil
+	end
+
+	kmf.parse_hotkey_setting = function(btn_type, option_value)
+		local btn_array = {}
+		local btn_str = ""
+		local paserd_btn = nil
+
+		for i = 1, #option_value do
+			local c = option_value:sub(i,i)
+
+			if (c == " " or c == "+") then
+				if #btn_str > 0 then
+					paserd_btn = kmf.get_valid_btn(btn_type, string.lower(btn_str))
+
+					if paserd_btn then
+						btn_array[#btn_array + 1] = paserd_btn
+						btn_str = ""
+					else
+						return {}
+					end
+				end
+			else
+				btn_str = btn_str .. c
+			end
+		end
+
+		if #btn_str > 0 then
+			paserd_btn = kmf.get_valid_btn(btn_type, string.lower(btn_str))
+
+			if paserd_btn then
+				btn_array[#btn_array + 1] = paserd_btn
+				btn_str = ""
+			else
+				return {}
+			end
+
+		end
+
+		return btn_array
+	end
+
+	kmf.check_mod_hotkey_status = function(setting_name)
+		local setting = kmf.settings[setting_name]
+
+		if setting then
+			local options = setting.options
+
+			if not options then
+				return false
+			end
+
+			local kbd_hotkey = options.keyboard_hotkey
+			local pad_hotkey = options.gamepad_hotkey
+
+			if kbd_hotkey then
+				local status = true
+
+				for _, key in ipairs(kbd_hotkey) do
+					if key == "mouse_forward" then
+						status = status and Mouse_down("extra_2")
+					elseif key == "mouse_backward" then
+						status = status and Mouse_down("extra_1")
+					elseif key == "ctrl" or key == "shift" or key == "alt" then
+						local r_key = "right " .. key
+						local l_key = "left " .. key
+
+						status = status and (Keyboard_down(key) or Keyboard_down(r_key) or Keyboard_down(l_key))
+					else
+						status = status and Keyboard_down(key)
+					end
+				end
+
+				if status then
+					return true
+				end
+			end
+
+			if pad_hotkey then
+				local status = true
+
+				for _, key in ipairs(pad_hotkey) do
+					status = status and kmf.gamepad_btn_down(key)
+				end
+
+				if status then
+					return true
+				end
+			end
+		end
+
+		return false
+	end
+
+	kmf.get_game_and_game_type = function()
+		local game = nil
+		local game_type = nil
+
+		if kmf.server_game == nil and kmf.client_game ~= nil then
+			game = kmf.client_game
+			game_type = true
+		elseif kmf.client_game == nil and kmf.server_game ~= nil then
+			game = kmf.server_game
+			game_type = false
+		end
+
+		return game, game_type
+	end
+
+	kmf.get_lobby_and_lobby_host = function(player_manager)
+		local lobby = player_manager:get_lobby()
+		local lobby_host = nil
+		if lobby then
+			lobby_host = lobby:host_peer()
+		else
+			return nil, nil
+		end
+
+		return lobby, lobby_host
+	end
+
+	NetworkHandler.set_current_network_message_router = function(self, router)
+		kmf.network_message_router = router
+		kmf.register_network_msg_handlers(kmf.network_message_router)
+
+		self.current_network_message_router = router
+	end
+
+	kmf.vars.res_spec_sm = {}
+	kmf.vars.res_spec_sm.state = "normal"
+	kmf.vars.player_names = {}
+	kmf.vars.elem_rocks_peer_dicts = {}
+	kmf.vars.fissure_instance_peer_dicts = {}
+	kmf.vars.shield_unit_hits = {}
+	kmf.vars.shield_unit_groups = {
+		units = {},
+		owners = {},
+		gc_time = 3
+	}
+	kmf.vars.net_dmg_states = {}
+	kmf.vars.waiting_spells = {}
+	kmf.vars.pvp_player_teams = {}
+	kmf.vars.on_update_handlers = {}
+	kmf.vars.on_render_handlers = {}
+	kmf.vars.on_lobby_leave_handlers = {}
+	kmf.vars.on_back_in_menu_handlers = {}
+	kmf.vars.player_menu_buttons = {}
+	kmf.vars.player_menu_btn_handlers = {}
+	kmf.vars.on_cancel_all_spells_handlers = {}
+	kmf.vars.before_start_ability_filters = {}
+
+	kmf.get_number_of_local_players = function()
+		kmf_print("in get_number_of_local_players()")
+		local res = 0
+
+		if kmf.player_manager then
+			local local_players = kmf.player_manager:get_local_players()
+			kmf_print("    local_players :: " .. tostring(local_players))
+
+			res = #local_players
+		end
+
+		return res
+	end
+
+	kmf.on_magick_cooldown_update = function(unit, spellwheel_ext)
+	end
+
+	kmf.on_init_ui = function()
+	end
+
+	kmf.on_locomotion_rotation_speed_update = function(unit, locomotion_ext)
+	end
+
+	kmf.get_number_of_magick_skeleton_spawns = function(players_n)
+		local base_num_units = SpellSettings.summon_living_dead_num_units
+		local per_player_unit_reduction = SpellSettings.summon_living_dead_unit_reduction_per_player
+		local num_units_to_spawn = base_num_units - players_n * per_player_unit_reduction + per_player_unit_reduction
+
+		if kmf.vars.funprove_enabled then
+			num_units_to_spawn = base_num_units
+		end
+
+		return num_units_to_spawn
+	end
+
+	kmf.try_enter_spec = function()
+		kmf_print("in get_number_of_local_players()")
+
+		if not kmf.vars.res_spec_sm.state == "go_spec" then
+			kmf_print("    wrong state :: " .. tostring(kmf.vars.res_spec_sm.state))
+			return
+		end
+
+		if kmf.lobby_handler then
+			local num_of_players = kmf.get_number_of_local_players()
+			kmf_print("    num_of_players :: " .. tostring(num_of_players))
+
+			if num_of_players < 1 then
+				-- add a bit of delay for safety, maybe unneeded
+				kmf.task_scheduler.add(function()
+					kmf.vars.res_spec_sm.state = "spec"
+
+					if kmf.player_manager then
+						kmf.player_manager:update_lobby_member_info(true)
+					end
+
+					if kmf.player_input_mapper then
+						for k, v in pairs(kmf.player_input_mapper._sign_in_delay) do
+							kmf.player_input_mapper._sign_in_delay[k] = 0
+						end
+					end
+				end, 100)
+
+				return
+			elseif kmf.player_input_mapper then
+				local local_peer =  kmf.lobby_handler:local_peer()
+				kmf_print("    local_peer :: " .. tostring(local_peer))
+
+				for _, player_local_id in pairs(kmf.player_manager:get_local_players()) do
+					kmf_print("     signing out player :: " .. tostring(player_local_id))
+					kmf.player_input_mapper:sign_out_player(player_local_id)
+				end
+			end
+		end
+
+		kmf.task_scheduler.add(kmf.try_enter_spec, 250)
+	end
+
+	kmf.on_reset_player_btn_click = function()
+		local players, players_n = kmf.entity_manager:get_entities("player")
+
+		if players then
+			for i = 1, players_n, 1 do
+				if  players[i] then
+					if  players[i].extension and players[i].unit then
+						if players[i].extension.is_local then
+							local health_ext = EntityAux.extension(players[i].unit, "health")
+
+							if health_ext and health_ext.state and (health_ext.state.max_health - health_ext.state.health) < 1 then
+								kmf.respawn_local_player()
+							else
+								kmf.send_status_message_me(LocalizationManager:lookup("[KMF]reset_player_btn_requirement"))
+							end
+
+							break
+						end
+					end
+				end
+			end
+		end
+	end
+
+	kmf.become_spectator = function()
+		kmf_print("in become_spectator()")
+
+		if not kmf.vars.res_spec_sm.state == "normal" then
+			kmf_print("    wrong state :: " .. tostring(kmf.vars.res_spec_sm.state))
+			return
+		end
+
+		kmf.vars.res_spec_sm.state = "go_spec"
+
+		kmf.try_enter_spec()
+	end
+
+	kmf.try_return_from_spec = function()
+		kmf_print("in try_return_from_spec()")
+
+		if not kmf.vars.res_spec_sm.state == "go_normal" then
+			kmf_print("    wrong state :: " .. tostring(kmf.vars.res_spec_sm.state))
+			return
+		end
+
+		if kmf.lobby_handler then
+			local num_of_players = kmf.get_number_of_local_players()
+			kmf_print("    num_of_players :: " .. tostring(num_of_players))
+			local is_host = kmf.lobby_handler.hosting
+			kmf_print("    is_host :: " .. tostring(is_host))
+			local free_slots = kmf.lobby_handler.max_players - kmf.lobby_handler:nr_of_players()
+			kmf_print("    free_slots :: " .. tostring(free_slots))
+
+			if num_of_players > 0 then
+				kmf.vars.res_spec_sm.state = "normal"
+
+				if kmf.player_manager then
+					kmf.player_manager:update_lobby_member_info(true)
+				end
+
+				kmf.send_resurrect_local_player()
+
+				return
+			elseif kmf.player_manager and free_slots > 0 then
+				local free_slot = kmf.player_manager:first_free_local_slot()
+				kmf_print("    free_slot :: " .. tostring(free_slot))
+
+				if free_slot then
+					if kmf.player_input_mapper then
+						local target_mapping = kmf.player_input_mapper._input_mappings[kmf.vars.res_spec_sm.last_activated_controller]
+
+						if not target_mapping then
+							for _, mapping in pairs(kmf.player_input_mapper._input_mappings) do
+								local input = mapping.input_data
+								if input and input.cursor and input.keystrokes then
+									target_mapping = mapping
+								end
+							end
+						end
+
+						kmf_print("    target_mapping :: " .. tostring(target_mapping))
+						if target_mapping and target_mapping.input_data then
+							kmf_print("    setting overrides for target_mapping")
+							target_mapping.input_data.override_activate = true
+							target_mapping.input_data.override_disabled = true
+						end
+					end
+				end
+			end
+
+		end
+
+		kmf.task_scheduler.add(kmf.try_return_from_spec, 250)
+	end
+
+	kmf.return_from_spectator = function()
+		kmf_print("in return_from_spectator()")
+		if not kmf.vars.res_spec_sm.state == "spec" then
+			kmf_print("    wrong state :: " .. tostring(kmf.vars.res_spec_sm.state))
+			return
+		end
+
+		kmf.vars.res_spec_sm.state = "go_normal"
+
+		kmf.try_return_from_spec()
+	end
+
+	kmf.respawn_local_player = function()
+		kmf_print("in respawn_local_player()")
+		-- state correction, maybe not needed
+		if kmf.vars.res_spec_sm.state == "spec" and kmf.get_number_of_local_players() > 0 then
+			kmf.vars.res_spec_sm.state = "normal"
+			kmf_print("    STATE CORRECTION, new state :: " .. tostring(kmf.vars.res_spec_sm.state))
+		end
+
+		kmf.vars.res_spec_sm.respawn_attempts = 0
+		kmf.become_spectator()
+		kmf.task_scheduler.add(kmf.return_from_spectator, 250)
+	end
+
+	kmf.local_player_alive = function()
+		local alive = false
+		local players, players_n = kmf.entity_manager:get_entities("player")
+
+		if players then
+			for i = 1, players_n, 1 do
+				if  players[i] then
+					if  players[i].extension and players[i].unit then
+						if players[i].extension.is_local then
+							return (not kmf.is_unit_dead(players[i].unit)), players[i].unit
+						end
+					end
+				end
+			end
+		end
+
+		return alive, nil
+	end
+
+	kmf.try_resurrect_local_player = function()
+		kmf_print("in try_resurrect_local_player()")
+		local alive, unit = kmf.local_player_alive()
+
+		if not alive then
+			kmf_print("    not alive")
+			kmf.network:send_resurrect(unit, 0, 1)
+			kmf.task_scheduler.add(kmf.try_resurrect_local_player, 100)
+		else
+			kmf_print("    going to normal sate")
+			kmf.vars.res_spec_sm.state = "normal"
+		end
+	end
+
+	kmf.send_resurrect_local_player = function()
+		kmf_print("in send_resurrect_local_player()")
+		local attempts = kmf.vars.res_spec_sm.respawn_attempts or 0
+		local state_normal = kmf.vars.res_spec_sm.state == "normal"
+
+		if kmf.entity_manager == nil then
+			kmf_print("    entity manager is missing !!!")
+			return
+		end
+
+		local alive, unit = kmf.local_player_alive()
+
+		if not alive and state_normal then
+			kmf_print("    not alive")
+			kmf.vars.res_spec_sm.state = "go_res"
+			kmf.try_resurrect_local_player()
+		elseif attempts > 0 then
+			kmf_print("    attempts > 0, respawning ...")
+			kmf.vars.res_spec_sm.respawn_attempts = attempts - 1
+			kmf.respawn_local_player()
+		end
+	end
+
+	kmf.resurrect_local_player = function()
+		kmf_print("in resurrect_local_player()")
+		-- state correction, maybe not needed
+		if kmf.vars.res_spec_sm.state == "normal" and kmf.get_number_of_local_players() < 0 then
+			kmf.vars.res_spec_sm.state = "spec"
+			kmf_print("    STATE CORRECTION, new state :: " .. tostring(kmf.vars.res_spec_sm.state))
+		end
+
+		kmf.vars.res_spec_sm.respawn_attempts = 1
+		local status, err = pcall(kmf.send_resurrect_local_player)
+
+		if status ~= true then
+			kmf_print("resurrect_local_player()", err)
+		end
+	end
+
+	kmf.vars.mod_hotkey_cooldowns = {}
+	kmf.vars.movement_convenience = {
+		bg_tex = "hud_element_arcane",
+		fg_texs = {
+			"icons_controller_pad_d_left_active",
+			"icons_controller_pad_d_up_active",
+			"icons_controller_pad_d_right_active",
+			"icons_controller_pad_d_down_active"
+		}
+	}
+
+	kmf.check_mod_hotkey_cooldown = function(mod)
+		if not kmf.check_mod_hotkey_status(mod) then
+			kmf.vars.mod_hotkey_cooldowns[mod] = false
+		else
+			local recursion = function()
+				kmf.check_mod_hotkey_cooldown(mod)
+			end
+			kmf.task_scheduler.add(recursion, 10)
+		end
+	end
+
+	kmf.start_mod_hotkey_cooldown = function(mod, ms)
+		kmf.vars.mod_hotkey_cooldowns[mod] = true
+		local disable_func = function()
+			kmf.vars.mod_hotkey_cooldowns[mod] = false
+		end
+
+		if ms ~= nil and ms > 0 then
+			kmf.task_scheduler.add(disable_func, ms)
+		else
+			kmf.check_mod_hotkey_cooldown(mod)
+		end
+	end
+
+	kmf.world_2_screen = function(pos)
+		if not kmf.frame_camera or not kmf.frame_camera.camera then
+			return nil, nil
+		end
+
+		local screen_pos = kmf.frame_camera:world_to_screen(pos)
+
+		if screen_pos then
+			return screen_pos.x, screen_pos.z
+		end
+
+		return nil, nil
+	end
+
+	kmf.screen_2_dir = function(x, y)
+		if not kmf.frame_camera or not kmf.frame_camera.camera then
+			return nil
+		end
+
+		local pos_1 = Camera.screen_to_world(kmf.frame_camera.camera, Vector3(x, 0 , y))
+		local pos_2 = Camera.screen_to_world(kmf.frame_camera.camera, Vector3(x, 1 , y))
+		local dir = Vector3.normalize(pos_2 - pos_1)
+
+		return pos_1, dir
+	end
+
+	kmf.screen_2_world = function(x, y, anchor_unit)
+		if not (anchor_unit and Unit.alive(anchor_unit)) then
+			return nil
+		end
+
+		local pos_1, dir = kmf.screen_2_dir(x, y)
+
+		if not (pos_1 and dir) then
+			return nil
+		end
+
+		local pos = Unit.world_position(anchor_unit, 0)
+		local z_level = pos.z
+		local cam_z = pos_1.z
+		local dir_z = dir.z
+		local intersect_point
+
+		if z_level < cam_z and dir_z < 0 then
+			intersect_point = pos_1 + dir * ((z_level - cam_z) / dir_z)
+		elseif z_level > cam_z and dir_z > 0 then
+			intersect_point = pos_1 + dir * ((z_level - cam_z) / dir_z)
+		end
+
+		return intersect_point
+	end
+
+	kmf.unit_enable_network_sync = function(unit)
+		if kmf.entity_manager and unit and not EntityAux.extension(unit, "network_sync") then
+			kmf.entity_manager:add_extension(unit, "network_sync")
+		end
+	end
+
+	kmf.transmit_message_all = function (message, ...)
+		local arg={...}
+		local send_arg = {}
+
+		for k, v in pairs(arg) do
+			if type(v) == "vector3box" then
+				send_arg[k] = Vector3Box.unbox(v)
+			else
+				send_arg[k] = v
+			end
+		end
+
+		kmf.network:transmit_all_except_me(message, unpack(send_arg))
+
+		local self_id = kmf.network.own_network_id
+
+		kmf.network.message_router:transmit(message, self_id, ...)
+	end
+
+	kmf.transmit_all = function (u, message, ...)
+		if not Unit.alive(u) then
+			return
+		end
+
+		local go_id = NetworkUnit.game_object_id(u)
+
+		if not go_id then
+			return
+		end
+
+		kmf.transmit_message_all(message, go_id, ...)
+	end
+
+	kmf.send_effect = function (owner, effect_type, position, scale, element_queue)
+		local no_elem = NetworkLookup.elements.none
+		local e1 = NetworkLookup.elements[element_queue[1]] or no_elem
+		local e2 = NetworkLookup.elements[element_queue[2]] or no_elem
+		local e3 = NetworkLookup.elements[element_queue[3]] or no_elem
+		local e4 = NetworkLookup.elements[element_queue[4]] or no_elem
+		local e5 = NetworkLookup.elements[element_queue[5]] or no_elem
+
+		local rand_seed = math.floor(math.random(0, 32000))
+
+		kmf.transmit_all(owner, "projectile_effect", effect_type, position, scale, rand_seed, e1, e2, e3, e4, e5)
+	end
+
+	kmf.send_status_message_all = function(message)
+		if kmf.network then
+			local filler = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
+			local msg = filler .. message .. filler
+
+			kmf.network:transmit_message_all("on_message", "visible", msg, 0)
+		end
+	end
+
+	kmf.send_status_message_me = function(message)
+		if kmf.network then
+			local filler = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
+			local msg = filler .. message .. filler
+
+			kmf.network:transmit_message_me("on_message", "visible", msg, 0)
+		end
+	end
+
+	kmf.send_status_message_peer = function(peer, message)
+		if kmf.network then
+			local filler = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
+			local msg = filler .. message .. filler
+
+			kmf.network:transmit_to(peer, "on_message", "visible", msg, 0)
+		end
+	end
+
+	kmf.send_unit_visual_effect = function (unit, effect)
+		if not unit then
+			return
+		end
+
+		local effect_id = EffectTemplateLUT[effect]
+
+		if effect_id then
+			kmf.network:send_add_effect_descriptor(unit, "once_effect", effect_id, nil)
+		end
+	end
+
+	kmf.send_unit_sound_effect = function (unit, effect)
+		if not unit then
+			return
+		end
+
+		local effect_id = EffectTemplateLUT[effect]
+		local position = Unit.world_position(unit, 0)
+
+		if effect_id then
+			kmf.network:send_projectile_effect(unit, "once_effect", position, effect_id, 0, {})
+		end
+	end
+
+	kmf.send_cast_spell_scaled = function (unit, cast_type, magick, element_queue, target, magick_target_position, scale_damage, rand_seed)
+		local LUT = NetworkLookup.elements
+		magick_target_position = magick_target_position or {
+			0,
+			0,
+			-1000,
+			0,
+			0,
+			-1000
+		}
+		local eq_net = {}
+
+		if not magick then
+			eq_net = FrameTable.alloc_table()
+
+			for i, elem in ipairs(element_queue) do
+				eq_net[i] = LUT[element_queue[i]]
+			end
+		end
+
+		local eq_scale = {}
+		local es_scale = {}
+		local i = 1
+
+		for k, v in pairs(scale_damage) do
+			eq_scale[i] = LUT[k]
+			es_scale[i] = v
+			i = i + 1
+		end
+
+		local cast_id = NetworkLookup.cast_types[cast_type] or NetworkLookup.cast_types.forward
+		local magick_id = NetworkLookup.magicks[magick] or 0
+		local go_id = kmf.network.unit_storage:go_id(unit)
+		local target_id = (target and kmf.network.unit_storage:go_id(target)) or NetworkUnit.invalid_game_object_id
+
+		if rand_seed == nil then
+			rand_seed = 0
+		end
+
+		kmf.network:transmit_message_all("cast_spell_scaled", go_id, cast_id, magick_id, eq_net, eq_scale, es_scale, target_id, rand_seed, magick_target_position)
+	end
+
+	kmf.const.kmf_message_offset = 65000 -- to prevent accidentally sending messages with valid go_id
+	kmf.const.kmf_message_types = {}
+	kmf.const.kmf_message_types["m-enbl"] = 1
+	kmf.const.kmf_message_types["m-dsbl"] = 2
+	kmf.const.kmf_message_types["set-team"] = 3
+	kmf.const.kmf_message_types["pvp-announce"] = 4
+	kmf.const.kmf_message_types["pvp-enbl"] = 5
+	kmf.const.kmf_message_types["name-announce"] = 6
+	kmf.const.kmf_message_types["eptc"] = 7
+	kmf.const.kmf_message_types["dmg-num"] = 8
+	kmf.const.kmf_message_types["uspwn-u"] = 9
+	kmf.const.kmf_message_types["fidc"] = 10
+
+	kmf.const.kmf_message_handlers = {}
+
+	-- m-enbl
+	kmf.const.kmf_message_handlers[1] = function(sender, msg)
+		kmf.tmp_enable_mod(msg)
+	end
+
+	-- m-dsbl
+	kmf.const.kmf_message_handlers[2] = function(sender, msg)
+		kmf.tmp_disable_mod(msg)
+	end
+
+	-- set-team
+	kmf.const.kmf_message_handlers[3] = function(sender, msg)
+		local i_beg, i_end = string.find(msg, ":", 1, true)
+
+		if i_end then
+			local peer = msg:sub(1, i_end - 1)
+			local team = msg:sub(i_end + 1)
+
+			kmf.vars.pvp_player_teams[peer] = team
+
+			if kmf.entity_manager and kmf.vars.pvp_gamemode then
+				local players, players_n = kmf.entity_manager:get_entities("player")
+
+				for i = 1, players_n do
+					if players[i] and players[i].extension and players[i].extension.is_local and players[i].extension.owner_peer_id == peer then
+						kmf.resurrect_local_player()
+					end
+				end
+			end
+		end
+	end
+
+	-- pvp-announce
+	kmf.const.kmf_message_handlers[4] = function(sender, msg)
+		if not kmf.vars.pvp_announce_lock then
+			kmf.vars.pvp_announce_lock = true
+			local i_beg, i_end = string.find(msg, ":", 1, true)
+			if i_end then
+				local msg_type = msg:sub(1, i_end - 1)
+				local team = msg:sub(i_end + 1)
+
+				if msg_type == "defeat" then
+					if team == "all" then
+						kmf.task_scheduler.add(function()
+							kmf.game_state_in_game.gm:show_challenge_message("Draw, nobody wins!", 3)
+						end)
+					else
+						kmf.task_scheduler.add(function()
+							team = team == "player" and "Grimnir" or "Vlad"
+							kmf.game_state_in_game.gm:show_challenge_message("Team \"" .. team  .. "\" wins!", 4)
+						end)
+					end
+
+					kmf.task_scheduler.add(function()
+						local hosting = kmf.lobby_handler:is_host()
+						local players, players_n = kmf.entity_manager:get_entities("player")
+
+						for i = 1, players_n, 1 do
+							local player_unit = players[i].unit
+							if player_unit and Unit.alive(player_unit) then
+								if hosting then
+									kmf.network:transmit_all(player_unit, "net_cancel_all_spells")
+									kmf.network:transmit_all(player_unit, "net_stop_all_statuses")
+								end
+
+								local health_ext = EntityAux.extension(players[i].unit, "health")
+								local alive = health_ext and health_ext.state and health_ext.state.health > 0
+
+								if alive then
+									local max_health = ((health_ext.internal and health_ext.internal.max_health) or (health_ext.state and health_ext.state.max_health)) or nil
+
+									if max_health then
+										health_ext.internal.health = max_health
+										health_ext.state.health = max_health
+									end
+								end
+							end
+						end
+					end)
+				end
+			end
+		end
+	end
+
+	-- pvp-enbl
+	kmf.const.kmf_message_handlers[5] = function(sender, msg)
+		kmf.vars.pvp_gamemode = msg == "true"
+
+		if kmf.vars.pvp_gamemode then
+			kmf.apply_pvp_unlocks()
+		else
+			kmf.remove_pvp_unlocks()
+		end
+
+		if kmf.network_lobby_handler and kmf.network_lobby_handler.hosting then
+			if kmf.network_lobby_handler.kmf_player_manager then
+				kmf.network_lobby_handler:_update_public_lobby_data(kmf.network_lobby_handler.kmf_player_manager)
+			end
+		end
+	end
+
+	-- name-announce
+	kmf.const.kmf_message_handlers[6] = function(sender, msg)
+		if sender ~= kmf.const.me_peer then
+			k_log("got kmf player name [ " .. sender .. " :: " .. msg .. " ]")
+			kmf.vars.player_names[sender] = tostring(msg)
+		end
+	end
+
+	-- eptc
+	kmf.const.kmf_message_handlers[7] = function(sender, msg)
+		local eptc_data = {
+			owner_peer = sender,
+			anchors = {}
+		}
+
+		for key_value in string.gmatch(msg, "[^;]+") do
+			local i_beg, i_end = string.find(key_value, ":", 1, true)
+
+			if i_end then
+				local key = key_value:sub(1, i_end - 1)
+				local value = key_value:sub(i_end + 1)
+
+				if key == "eu" then
+					eptc_data.unique_id = tonumber(value)
+				elseif key == "vx" then
+					eptc_data.vel_x = tonumber(value)
+				elseif key == "vy" then
+					eptc_data.vel_y = tonumber(value)
+				elseif key == "vz" then
+					eptc_data.vel_z = tonumber(value)
+				else
+					i_beg, i_end = string.find(key, "an-", 1, true)
+
+					if i_end then
+						key = key:sub(i_end + 1)
+						i_beg, i_end = string.find(key, "-", 1, true)
+
+						if i_end > 1 then
+							local anchor_go_id = tonumber(key:sub(1, i_end - 1))
+							local anchor_data = eptc_data.anchors[anchor_go_id] or {}
+
+							key = key:sub(i_end + 1)
+
+							if key == "dx" then
+								anchor_data.dx = tonumber(value)
+							elseif key == "dy" then
+								anchor_data.dy = tonumber(value)
+							elseif key == "dz" then
+								anchor_data.dz = tonumber(value)
+							elseif key == "wgh" then
+								anchor_data.weight = tonumber(value)
+							end
+
+							eptc_data.anchors[anchor_go_id] = anchor_data
+						end
+					end
+				end
+			end
+		end
+
+		if eptc_data.owner_peer and eptc_data.unique_id then
+			local anchors = {}
+			for anchor_go_id, anchor_data in pairs(eptc_data.anchors) do
+				if anchor_data.weight and anchor_data.dx and anchor_data.dy and anchor_data.dz then
+					anchors[#anchors + 1] = {
+						go_id = anchor_go_id,
+						weight = anchor_data.weight,
+						delta = {anchor_data.dx, anchor_data.dy, anchor_data.dz}
+					}
+				end
+			end
+
+			local ordered_data = {
+				anchors = anchors
+			}
+
+			if eptc_data.vel_x and eptc_data.vel_y and eptc_data.vel_z then
+				ordered_data.vel = {eptc_data.vel_x, eptc_data.vel_y, eptc_data.vel_z}
+			end
+
+			local elem_rocks_info = kmf.vars.elem_rocks_peer_dicts[eptc_data.owner_peer] or {}
+			local elem_rocks_data = elem_rocks_info[eptc_data.unique_id] or {}
+
+			elem_rocks_data.data = ordered_data
+			elem_rocks_info[eptc_data.unique_id] = elem_rocks_data
+			kmf.vars.elem_rocks_peer_dicts[eptc_data.owner_peer] = elem_rocks_info
+		end
+	end
+
+	-- dmg-num
+	kmf.const.kmf_message_handlers[8] = function(sender, msg)
+		local dmg_state_data = {}
+		local last_id = 0
+		local go_id
+		local fist_entry = true
+
+		for key_value in string.gmatch(msg, "[^;]+") do
+			if fist_entry then
+				go_id = tonumber(key_value)
+				fist_entry = false
+			else
+				local i_beg, i_end = string.find(key_value, ":", 1, true)
+
+				if i_end and dmg_state_data[last_id] then
+					local key = tonumber(key_value:sub(1, i_end - 1))
+					local value = key_value:sub(i_end + 1)
+
+					if key == 1 then
+						dmg_state_data[last_id][1] = value
+					elseif key == 2 then
+						dmg_state_data[last_id][2] = tonumber(value)
+					elseif key == 4 then
+						dmg_state_data[last_id][4] = value
+					elseif key == 5 then
+						dmg_state_data[last_id][5] = tonumber(value)
+					end
+				else
+					last_id = tonumber(key_value)
+
+					if last_id then
+						dmg_state_data[last_id] = {}
+					end
+				end
+			end
+		end
+
+		if go_id then
+			local final_data = {}
+			local count = 0
+
+			for _, dmg_info in pairs(dmg_state_data) do
+				if dmg_info[1] and dmg_info[2] and dmg_info[4] then
+					count = count + 1
+					final_data[count] = dmg_info
+				end
+			end
+
+			if count > 0 then
+				local dmg_state = {
+					damage_taken = true,
+					damage = final_data,
+					damage_n = count
+				}
+
+				local net_dmg_states = kmf.vars.net_dmg_states[go_id] or {}
+
+				net_dmg_states[#net_dmg_states + 1] = dmg_state
+
+				kmf.vars.net_dmg_states[go_id] = net_dmg_states
+			end
+		end
+	end
+
+	-- uspwn-u
+	kmf.const.kmf_message_handlers[9] = function(sender, msg)
+		if kmf.unit_storage then
+			local go_id = tonumber(msg)
+
+			if go_id then
+				local unit = kmf.unit_storage:unit(go_id)
+
+				if unit and Unit.alive(unit) then
+					G_flow_delegate:trigger1("unspawn_unit", unit)
+				end
+			end
+		end
+	end
+
+	-- fidc
+	kmf.const.kmf_message_handlers[10] = function(sender, msg)
+		local fidc_data = {
+			owner_peer = sender,
+			anchors = {}
+		}
+
+		for key_value in string.gmatch(msg, "[^;]+") do
+			local i_beg, i_end = string.find(key_value, ":", 1, true)
+
+			if i_end then
+				local key = key_value:sub(1, i_end - 1)
+				local value = key_value:sub(i_end + 1)
+
+				if key == "fi" then
+					fidc_data.unique_id = tonumber(value)
+				else
+					i_beg, i_end = string.find(key, "an-", 1, true)
+
+					if i_end then
+						key = key:sub(i_end + 1)
+						i_beg, i_end = string.find(key, "-", 1, true)
+
+						if i_end > 1 then
+							local anchor_go_id = tonumber(key:sub(1, i_end - 1))
+							local anchor_data = fidc_data.anchors[anchor_go_id] or {}
+
+							key = key:sub(i_end + 1)
+
+							if key == "dx" then
+								anchor_data.dx = tonumber(value)
+							elseif key == "dy" then
+								anchor_data.dy = tonumber(value)
+							elseif key == "dz" then
+								anchor_data.dz = tonumber(value)
+							elseif key == "wgh" then
+								anchor_data.weight = tonumber(value)
+							end
+
+							fidc_data.anchors[anchor_go_id] = anchor_data
+						end
+					end
+				end
+			end
+		end
+
+		if fidc_data.owner_peer and fidc_data.unique_id then
+			local anchors = {}
+			for anchor_go_id, anchor_data in pairs(fidc_data.anchors) do
+				if anchor_data.weight and anchor_data.dx and anchor_data.dy and anchor_data.dz then
+					anchors[#anchors + 1] = {
+						go_id = anchor_go_id,
+						weight = anchor_data.weight,
+						delta = {anchor_data.dx, anchor_data.dy, anchor_data.dz}
+					}
+				end
+			end
+
+			local ordered_data = {
+				anchors = anchors
+			}
+
+			local fissure_instance_info = kmf.vars.fissure_instance_peer_dicts[fidc_data.owner_peer] or {}
+			local fissure_instance_data = fissure_instance_info[fidc_data.unique_id] or {}
+
+			fissure_instance_data.data = ordered_data
+			fissure_instance_info[fidc_data.unique_id] = fissure_instance_data
+			kmf.vars.fissure_instance_peer_dicts[fidc_data.owner_peer] = fissure_instance_info
+		end
+	end
+
+	kmf.send_kmf_msg = function(peer, msg, type)
+		local msg_type = kmf.const.kmf_message_types[type]
+		local me_peer = kmf.const.me_peer
+
+		if not msg_type then
+			kmf_print("KMF MESSAGE TYPE DOES NOT EXIST :: " .. tostring(type))
+			return
+		end
+
+		msg_type = msg_type + kmf.const.kmf_message_offset
+
+		if peer == me_peer then
+			kmf.network_message_router:transmit("on_message", me_peer, "invisible", msg, msg_type)
+		else
+			RPC["on_message"](peer, "invisible", msg, msg_type)
+		end
+	end
+
+	kmf.handle_kmf_msg = function(sender, category, msg, msg_type)
+		msg_type = tonumber(msg_type)
+		category = tostring(category)
+		msg = tostring(msg)
+
+		if not (msg_type and category and msg) or msg_type < kmf.const.kmf_message_offset then
+			return
+		end
+
+		msg_type = msg_type - kmf.const.kmf_message_offset
+
+		if category ~= "invisible" then
+			return
+		end
+
+		local msg_handler = kmf.const.kmf_message_handlers[msg_type]
+		local i_beg, i_end
+
+		if not msg_handler then
+			kmf_print("WRONG KMF MESSAGE TYPE :: " .. tostring(msg_type))
+			return
+		end
+
+		kmf_print("got kmf msg [ " .. msg_type .. " :: " .. msg .. " ]")
+
+		msg_handler(sender, msg)
+	end
+
+	kmf.vars.network_msg_handlers = {}
+	kmf.add_network_msg_handler = function(message, handler)
+		local hanlder_table = {}
+
+		hanlder_table[message] = function(self, ...)
+			handler(...)
+		end
+
+		kmf.vars.network_msg_handlers[message] = hanlder_table
+	end
+
+	kmf.register_network_msg_handlers = function(router)
+		for message, handler in pairs(kmf.vars.network_msg_handlers) do
+			router:register(message .. "_handler", handler, message)
+		end
+	end
+
+	kmf.add_network_msg_handler("on_message", kmf.handle_kmf_msg)
+
+	kmf.vars.needed_units_to_spawn = {}
+	kmf.check_needed_units = function(unit)
+		local time = os.clock()
+
+		if unit and Unit.alive(unit) then
+			for request_time, needed in pairs(kmf.vars.needed_units_to_spawn) do
+				if time - request_time > 5.0 then
+					table.remove(kmf.vars.needed_units_to_spawn, request_time)
+				else
+					if Unit.is_a(unit, needed.name) then
+						needed.callback(unit)
+						table.remove(kmf.vars.needed_units_to_spawn, request_time)
+						break
+					end
+				end
+			end
+		end
+	end
+
+	kmf.wait_unit_to_spawn = function(unit_name, unit_callback)
+		local array = kmf.vars.needed_units_to_spawn
+		array[os.clock()] = {name = unit_name, callback = unit_callback}
+	end
+
+	kmf.const.custom_magic_prototype = {}
+	kmf.vars.custom_magics = {}
+	kmf.const.custom_magics = {}
+
+	kmf.init_custom_magics = function ()
+		SaveManager.is_magick_unlocked = function (self, magick)
+			assert(MagicksSettings)
+
+			if not MagicksSettings[magick] then
+				return
+			end
+
+			if kmf.vars.pvp_gamemode then
+				return true
+			end
+
+			if MagicksSettings[magick].unlocked then
+				return true
+			end
+
+			if self.persistence_manager:item_available(self.game_name .. ".magick." .. tostring(magick)) then
+				return true
+			end
+
+			if self:is_dlc_owned(MagicksSettings[magick]) then
+				return true
+			end
+
+			return self.save_data.unlocked_magicks[magick]
+		end
+
+		HudMagicks.has_magick = function (self, magick_name)
+			assert(magick_name, "Supply a magick_name")
+
+			for k, v in pairs(kmf.const.custom_magics) do
+				if v.translation_string == magick_name then
+					return true
+				end
+			end
+
+			for tier, list in ipairs(self.selectable_magicks) do
+				for name, data in pairs(list) do
+					if name == magick_name then
+						return true
+					end
+				end
+			end
+
+			return false
+		end
+
+		HudMagicks.is_tier_enabled = function (self, tier)
+			if self.all_magicks_disabled then
+				return false
+			end
+
+			if self.magicks_forced_disabled then
+				return false
+			end
+
+			if self:is_tier_force_disabled(tier) then
+				return false
+			end
+
+			if ArtifactManager:get_modifier_value("NoMagickT" .. tier) then
+				return false
+			end
+
+			if tier == -321 then
+				return true
+			end
+
+			if NetworkUnit.is_local_unit(self.unit) then
+				local tier_magicks = self:filter_unlocked(get_all_magicks_for_tier(tier))
+
+				if #tier_magicks <= 0 then
+					return false
+				end
+			end
+
+			return true
+		end
+
+		HudMagicks.update_magick_template_selection_mouse_wheel = function (self, input_data)
+			if self.controller == "keyboard" and input_data.wheel and input_data.wheel[2] ~= 0 then
+				local magick_list = {
+					""
+				}
+
+				for tier = 1, self.num_tiers, 1 do
+					if self:is_tier_enabled(tier) then
+						local all_magicks = self:filter_unlocked(get_all_magicks_for_tier(tier))
+
+						table.sort(all_magicks)
+						table.append(all_magicks, magick_list)
+					end
+				end
+
+				for _, magick in pairs(kmf.const.custom_magics) do
+					magick_list[#magick_list + 1] = magick.translation_string
+				end
+
+				local index = table.indexof(magick_list, self.selected_magick_template or "") or 1
+				local next_magick = ""
+				local num_magicks = #magick_list
+
+				repeat
+					index = index + input_data.wheel[2]
+
+					if index <= 0 then
+						index = num_magicks
+					end
+
+					if num_magicks < index then
+						index = 1
+					end
+
+					next_magick = magick_list[index]
+				until index == 1 or MagickByElements[next_magick]
+
+				self:set_magick_template(self.unit, next_magick)
+			end
+		end
+
+		HudMagicks.load_selected_magicks = function (self)
+			if not self.player_data then
+				return
+			end
+
+			local selected = self.player_data:get_selected_magicks()
+
+			if selected then
+				for tier, magick in ipairs(selected) do
+					if tier ~= nil and magick ~= nil then
+						local i_start, i_end = string.find(magick, "[KMF]", 1, true)
+						if not i_start then
+							local tier_locked = ArtifactManager:get_modifier_value("NoMagickT" .. tier)
+
+							if self:is_magick_unlocked(magick) and not tier_locked then
+								self:set_magick_button_from_selection(tier, magick)
+							end
+						end
+					end
+				end
+			end
+
+			self.selected_magick_template = self.player_data:get_selected_magick_template()
+			local tier, index = self:find_tier_and_index_of_magick(self.selected_magick_template)
+
+			if tier == nil then
+				self.selected_magick_template = ""
+				return
+			end
+
+			if self.selected_magick_template and (not self:has_magick(self.selected_magick_template) or ArtifactManager:get_modifier_value("NoMagickT" .. tier)) then
+				self.selected_magick_template = ""
+			end
+
+			SpellWheelSystem:set_magick_template(self.unit, self.selected_magick_template)
+			self:set_selected_magicks_in_extension()
+		end
+	end
+
+	kmf.register_custom_magics = function()
+		for k, v in pairs(kmf.const.custom_magics) do
+			MagicksSettings[v.translation_string] = {
+				name = v.name,
+				tier = -321,
+				cast_type = "position",
+				cooldown = 1,
+				icon = "hud_magick_sacrifice",
+				element_queue = v.elements,
+				enabled = false
+			}
+			MagickByElements[v.translation_string] = v.elements
+		end
+	end
+
+	kmf.get_unit_faction = function (unit)
+		local unit_faction
+		local unit_faction_ext = EntityAux.extension(unit, "faction")
+
+		unit_faction = unit_faction_ext and unit_faction_ext.internal.faction or "neutral"
+
+		return unit_faction
+	end
+
+	kmf.get_custom_magics = function (elems)
+		for _, magic in pairs(kmf.const.custom_magics) do
+			local match = true
+
+			if #elems == #magic.elements then
+				for i, elem in pairs(elems) do
+					if elem ~= magic.elements[#magic.elements - i + 1] then
+						match = false
+						break
+					end
+				end
+			else
+				match = false
+			end
+
+			if match then
+				return magic
+			end
+		end
+
+		return nil
+	end
+
+	kmf.setup_custom_magic_instance = function(custom_magick, spell_context, unit)
+		local magick_instance = {}
+		magick_instance.context = {}
+
+		if not unit then
+			if spell_context then
+				magick_instance.context.unit = spell_context.caster
+			end
+		else
+			magick_instance.context.unit = unit
+		end
+
+		if spell_context then
+			magick_instance.context.is_standalone = spell_context.is_standalone
+			magick_instance.context.entity_manager = spell_context.entity_manager
+			magick_instance.context.unit_spawner = spell_context.unit_spawner
+			magick_instance.context.player_variable_manager = spell_context.player_variable_manager
+			magick_instance.context.tactic_manager = spell_context.tactic_manager
+			magick_instance.context.spellcast_system = spell_context.spellcast_system
+			magick_instance.context.world = spell_context.world
+			magick_instance.context.network = spell_context.network
+			magick_instance.context.caster = spell_context.caster
+			magick_instance.context.internal = spell_context.internal
+			magick_instance.context.effect_manager = spell_context.effect_manager
+			magick_instance.context.is_local = spell_context.is_local
+		end
+
+		if magick_instance.context.unit then
+			local pos = Unit.world_position(magick_instance.context.unit)
+			local x = math.round(Vector3.x(pos), 0.1)
+			local y = math.round(Vector3.y(pos), 0.1)
+			local z = math.round(Vector3.z(pos), 0.1) + 0.1
+			Vector3.set_x(pos, x)
+			Vector3.set_y(pos, y)
+			Vector3.set_z(pos, z)
+
+			local pos_box = Vector3Box(pos)
+			magick_instance.context.position = pos_box
+		end
+
+		setmetatable(magick_instance, {__index = custom_magick})
+
+		return magick_instance
+	end
+
+	kmf.schedule_custom_magic_aoe = function(context, data)
+		kmf.task_scheduler.add(function ()
+			kmf.send_effect(
+				context.unit,
+				data.name,
+				context.position,
+				data.scale,
+				data.elems)
+		end, data.delay)
+	end
+
+	kmf.play_custom_magic_character_animation = function(context, animation, stop_moving, dont_ungrab)
+		local char_ext = EntityAux.extension(context.unit, "character")
+
+		if stop_moving then
+			EntityAux.set_input(context.unit, "character", "stop_move_destination", true)
+		end
+
+		if not dont_ungrab then
+			EntityAux.extension(context.unit, "character").grabbable = false
+		end
+
+		EntityAux.set_input_by_extension(char_ext, CSME.spell_channel, nil)
+		EntityAux.set_input_by_extension(char_ext, CSME.spell_cast, true)
+		EntityAux.set_input_by_extension(char_ext, "args", animation)
+	end
+
+	kmf.task_scheduler = {}
+	kmf.task_scheduler.schedule = {}
+
+	kmf.task_scheduler.get_time_after = function (delay)
+		return os.clock() + (delay / 1000.0)
+	end
+
+	kmf.task_scheduler.add = function (callback, delay)
+		if type(callback) ~= "function" then
+			return
+		end
+
+		local time = 0
+
+		if delay then
+			time = os.clock() + (delay / 1000.0)
+		end
+
+		local schedule = kmf.task_scheduler.schedule
+		local entry = {}
+		entry.callback = callback
+		entry.time = time
+		schedule[#schedule + 1] = entry
+	end
+
+	kmf.task_scheduler.add_at = function (callback, timestamp)
+		if type(callback) ~= "function" then
+			return
+		end
+
+		local schedule = kmf.task_scheduler.schedule
+		local entry = {}
+		entry.callback = callback
+		entry.time = timestamp
+		schedule[#schedule + 1] = entry
+	end
+
+	kmf.task_scheduler.try_run_next_task = function (callback)
+		local schedule = kmf.task_scheduler.schedule
+
+		if #schedule < 1 then
+			return
+		end
+
+		local schedule_count = #schedule
+		local time = os.clock()
+		local max_exec = (schedule_count > 5 and 3) or (schedule_count > 3 and 2) or 1
+		local exec_count = 0
+
+		repeat
+			local index = nil
+			local callback = nil
+
+			for i, v in pairs(schedule) do
+				if v.time < time then
+					index = i
+					callback = v.callback
+					break
+				end
+			end
+
+			if index then
+				table.remove(schedule, index)
+				pcall(callback)
+			else
+				exec_count = max_exec
+			end
+
+			exec_count = exec_count + 1
+		until exec_count >= max_exec
+	end
+
+	kmf.runtime_bug_fixes = function()
+		local function unit_data_vec3(u, name)
+			if Unit.has_data(u, "obstacle", name) == false then
+				return
+			end
+
+			local x = Unit.get_data(u, "obstacle", name, 0)
+			local y = Unit.get_data(u, "obstacle", name, 1)
+			local z = Unit.get_data(u, "obstacle", name, 2)
+
+			return Vector3(x, y, z)
+		end
+
+		AISystem.update_obstacles = function (self)
+			local ext = self._obstacle_queue:peek()
+
+			if ext == nil then
+				return
+			end
+
+			while ext do
+				if ext.in_queue == true then
+					if ext.num_of_obstacles then
+						local num_of_obstacles = 0
+
+						while Unit.has_data(ext.u, "obstacle", num_of_obstacles) do
+							--kmf_print("AISystem.update_obstacles()", "obstacle 1")
+							if ext.obstacle_handle[num_of_obstacles + 1] == nil then
+								local obstacle_type = Unit.get_data(ext.u, "obstacle_type") or "cylinder"
+								local hollow = (obstacle_type == "cylinder_hollow" and 1) or 0
+								ext.obstacle_pos[num_of_obstacles + 1] = Vector3Box(Matrix4x4.transform(ext.m, unit_data_vec3(ext.u, num_of_obstacles)))
+								local obstacle_handle = CaneTileCache.add_cylinder_obstacle(self.cane_tilecache, Matrix4x4.transform(ext.m, unit_data_vec3(ext.u, num_of_obstacles)), 1, hollow, 2, 2)
+
+								if obstacle_handle == nil then
+									return
+								end
+
+								ext.obstacle_handle[num_of_obstacles + 1] = obstacle_handle
+								num_of_obstacles = num_of_obstacles + 1
+							end
+						end
+					else
+						return
+						-- this seems to be fixed code that should be normally executed anyway, lmao
+						--kmf_print("AISystem.update_obstacles()", "obstacle 2")
+						--ext.obstacle_pos[1] = Vector3Box(Unit.world_position(ext.u, 0))
+						--local obstacle_handle = CaneTileCache.add_cylinder_obstacle(self.cane_tilecache, Unit.world_position(ext.u, 0), ext.size, 0, 2, 2)
+
+						--if obstacle_handle == nil then
+						--	return
+						--end
+
+						--ext.in_queue = false
+						--ext.obstacle_handle[1] = obstacle_handle
+					end
+				end
+
+				self._obstacle_queue:pop()
+
+				ext = self._obstacle_queue:peek()
+			end
+		end
+	end
+
+	kmf.bugfixes = {}
+	kmf.bugfixes.damage_comms_fix = function()
+		if not Spells_SelfArmor._old_on_cancel then
+			Spells_SelfArmor._old_on_cancel = Spells_SelfArmor.on_cancel
+		end
+		Spells_SelfArmor.on_cancel = function (data, context)
+			local time = os.clock()
+			local ret = Spells_SelfArmor._old_on_cancel(data, context)
+
+			if data and data.damage_ext then
+				data.damage_ext.state.selfarmored_earth_end = time
+				data.damage_ext.state.selfarmored_ice_end = time
+			end
+		end
+
+		if not Spells_SelfArmor._old_on_cancel_one then
+			Spells_SelfArmor._old_on_cancel_one = Spells_SelfArmor.on_cancel_one
+		end
+		Spells_SelfArmor.on_cancel_one = function (element, data, context, notify)
+			local time = os.clock()
+			local ret = Spells_SelfArmor._old_on_cancel_one(element, data, context, notify)
+
+			for elem, amt in pairs(data.elements) do
+				if elem == element then
+					if elem == "ice" then
+						if data and data.damage_ext then
+							data.damage_ext.state.selfarmored_ice_end = time
+						end
+					elseif elem == "earth" then
+						if data and data.damage_ext then
+							data.damage_ext.state.selfarmored_earth_end = time
+						end
+					end
+				end
+			end
+		end
+	end
+	kmf.bugfixes.shield_unit_fixes = function()
+		function flow_callback_mine_explode(params)
+			local unit = params.unit
+
+			if not Unit.alive(unit) then
+				return
+			end
+
+			local ability = Unit.get_data(unit, "mine_ability")
+			local magnitudes = {}
+
+			if ability then
+				local tkey = {}
+				local mine_owner = Unit.get_data(unit, "mine_owner")
+				local damage_replacer = Unit.get_data(unit, "damage_replacer") or mine_owner
+				local damage_mul = Unit.get_data(unit, "mine_multipliers")
+
+				if not damage_mul then
+					damage_mul = {
+						steam = 1,
+						water = 1,
+						earth = 1,
+						push = 1,
+						fire = 1,
+						elevate = 1,
+						lightning = 1,
+						poison = 1,
+						cold = 1,
+						arcane = 1,
+						life = 1,
+						ice = 1
+					}
+				end
+
+				magnitudes = Unit.get_data(unit, "mine_magnitudes")
+
+				assert(magnitudes, "Missing element magnitudes for mine")
+
+				local damage_mul_factor = Unit.get_data(unit, "damage_mul_factor")
+
+				if not damage_mul_factor then
+					if kmf.vars.bugfix_enabled then
+						local mul = SpellSettings.mine_explode_power_percentage_min
+
+						damage_mul_factor = mul
+					else
+						damage_mul_factor = 1
+					end
+				end
+
+				local orig_mult
+
+				-- fun-balance :: buff mines damage
+				if kmf.vars.funprove_enabled then
+					orig_mult = damage_mul_factor
+					damage_mul_factor = damage_mul_factor * 3.0
+					damage_mul_factor = damage_mul_factor < 1 and damage_mul_factor or 1
+
+					local mine_fast_scale = Unit.get_data(unit, "mine_time") or 0
+					mine_fast_scale = mine_fast_scale * 1.66
+
+					if mine_fast_scale < 1 then
+						local base_orig = orig_mult * 0.33
+						local scale_orig = orig_mult * 0.66
+
+						local base_new = damage_mul_factor * 0.33
+						local scale_new = damage_mul_factor * 0.66
+
+						orig_mult = base_orig + scale_orig * mine_fast_scale
+						damage_mul_factor = base_new + scale_new * mine_fast_scale
+					end
+
+					damage_mul_factor = damage_mul_factor * 2.0
+				end
+
+				local push_min = SpellSettings.mine_explode_push_percentage_min
+				local push_max = SpellSettings.mine_explode_push_percentage_max
+				local elevate_min = SpellSettings.mine_explode_elevate_percentage_min
+				local elevate_max = SpellSettings.mine_explode_elevate_percentage_max
+
+				if damage_mul_factor then
+					for elem, d_mul in pairs(damage_mul) do
+						if elem == "push" or elem == "water_push" then
+							local mul = math.clamp(damage_mul_factor * d_mul, push_min, push_max)
+							damage_mul[elem] = mul
+						elseif elem == "elevate" or elem == "water_elevate" then
+							local mul = math.clamp(damage_mul_factor * d_mul, elevate_min, elevate_max)
+							damage_mul[elem] = mul
+						elseif kmf.vars.funprove_enabled and elem == "life" then
+							damage_mul[elem] = d_mul * orig_mult
+						else
+							damage_mul[elem] = d_mul * damage_mul_factor
+						end
+					end
+				end
+
+				if kmf.vars.funprove_enabled and damage_mul.life then
+					damage_mul.life = damage_mul.life * 2.0
+				end
+
+				local group_id = Unit.get_data(unit, "kmf_shield_group")
+				local owner_id = Unit.get_data(unit, "kmf_shield_owner")
+
+				tkey[ability] = {
+					ignore_staff_multiplier = true,
+					damage_mul = damage_mul,
+					damage_replacer = damage_replacer,
+					magnitudes = magnitudes
+				}
+
+				if group_id and owner_id then
+					tkey[ability].kmf_shield_unit_grouping = {
+						group_id = group_id,
+						owner = owner_id
+					}
+				end
+
+				EntityAux.set_input(unit, "ability_user", "start_ability", tkey)
+			end
+
+			G_flow_delegate:trigger2("mine_explode", unit, magnitudes)
+		end
+
+		function flow_callback_barrier_explode(params)
+			local unit = params.unit
+			local ability = Unit.get_data(unit, "barrier_ability")
+
+			if ability then
+				local tkey = {}
+				local damage_mul, area_multiplier, damage_mul_factor
+				local barrier_explode_ability_args = Unit.get_data(unit, "barrier_explode_ability_args")
+
+				damage_mul = barrier_explode_ability_args and barrier_explode_ability_args.damage_mul or damage_mul
+
+				if not damage_mul then
+					damage_mul = {
+						steam = 1,
+						water = 1,
+						earth = 1,
+						push = 1,
+						fire = 1,
+						elevate = 1,
+						lightning = 1,
+						cold = 1,
+						arcane = 1,
+						life = 1,
+						ice = 1
+					}
+				end
+
+				local orig_mult
+
+				area_multiplier = barrier_explode_ability_args and barrier_explode_ability_args.area_multiplier or area_multiplier
+
+				if not area_multiplier then
+					area_multiplier = 1
+				end
+
+				damage_mul_factor = barrier_explode_ability_args and barrier_explode_ability_args.damage_mul_factor or damage_mul_factor
+
+				if damage_mul_factor == nil then
+					damage_mul_factor = 1
+
+					if kmf.vars.bugfix_enabled then
+						damage_mul_factor = SpellSettings.barrier_explode_power_percentage_min
+					else
+						damage_mul_factor = 1
+					end
+				end
+
+				-- fun-balance :: buff and scale barrier explode damage multiplier
+				if kmf.vars.funprove_enabled then
+					damage_mul_factor = damage_mul_factor < 0.25 and 0.25 or damage_mul_factor
+					damage_mul_factor = damage_mul_factor < 1 and damage_mul_factor or 1
+					damage_mul_factor = damage_mul_factor * 3.0
+				end
+
+				if damage_mul_factor ~= 1 then
+					for elem, d_mul in pairs(damage_mul) do
+						damage_mul[elem] = (d_mul or 0) * damage_mul_factor
+					end
+				end
+
+				if kmf.vars.funprove_enabled and damage_mul.life then
+					damage_mul.life = damage_mul.life * 0.5
+				end
+
+				local args = {}
+
+				args.damage_replacer = Unit.get_data(unit, "barrier_owner")
+				args.damage_mul = damage_mul
+				args.area_mul = area_multiplier
+
+				local group_id = Unit.get_data(unit, "kmf_shield_group")
+				local owner_id = Unit.get_data(unit, "kmf_shield_owner")
+
+				if group_id and owner_id then
+					args.kmf_shield_unit_grouping = {
+						group_id = -1 * group_id, -- this is needed to prevent problems of mixing things up with barrier dots
+						owner = owner_id
+					}
+				end
+
+				tkey[ability] = args
+
+				EntityAux.set_input(unit, "ability_user", "start_ability", tkey)
+			end
+
+			G_flow_delegate:trigger1("barrier_explode", unit)
+		end
+
+		Abilities.aoe_damage.on_activate = function(context)
+			if not context then
+				return
+			end
+
+			local my_shield_grouping
+
+			if kmf.vars.bugfix_enabled and type(context.params) == "table" and context.args.damage and context.params.kmf_shield_unit_grouping then
+				local my_grouping = context.params.kmf_shield_unit_grouping
+
+				my_shield_grouping = {
+					owner = my_grouping.owner,
+					group_id = my_grouping.group_id,
+					type = 1
+				}
+			end
+
+			local damage_mul, imbuement_multiplier, damage_replacer, area_multiplier, magnitudes
+			local args = context.args
+			local params = context.params
+			local do_status = args.do_status
+			local ignore_unit = not args.hit_user
+			local set_magnitudes
+			local ignore_multipliers = args.ignore_multipliers
+			local ignore_staff_multiplier = args.ignore_staff_multiplier
+			local range = args.range
+			local damage_source
+
+			if type(params) == "table" then
+				damage_mul = params.damage_mul
+				imbuement_multiplier = params.imbuement_multiplier or Unit.get_data(context.unit, "imbuement_multiplier") or 1
+				area_multiplier = params.area_mul
+				damage_replacer = params.damage_replacer
+				magnitudes = params.magnitudes
+				set_magnitudes = params.set_magnitudes
+
+				if params.ignore_staff_multiplier ~= nil then
+					ignore_staff_multiplier = params.ignore_staff_multiplier
+				end
+
+				if params.add_range then
+					range = range + params.add_range
+				end
+
+				if params.damage_source then
+					damage_source = params.damage_source
+				end
+			elseif type(params) ~= "boolean" then
+				damage_replacer = context.params
+			end
+
+			local pr = context.pfx_requests
+			local u = context.unit
+			local pvm = context.player_variable_manager
+			local damage_dealer, dmg_dealers
+
+			if type(damage_replacer) == "table" then
+				damage_dealer = Unit.alive(damage_replacer[1]) and damage_replacer[1] or u
+				dmg_dealers = table.clone(damage_replacer)
+			else
+				damage_dealer = damage_replacer or u
+				dmg_dealers = {
+					damage_dealer
+				}
+			end
+
+			local modify_liquid
+			local liquid_influence_amount = 0
+			local position = Unit.world_position(u, 0)
+
+			if type(params) == "table" and params.position then
+				position = Vector3.unbox(params.position)
+			end
+
+			local damages = args.damage and table.clone(args.damage)
+
+			if not damages and type(params) == "table" and params.damage then
+				damages = table.clone(params.damage)
+			end
+
+			RagdollManager:handle_ragdoll_zone({
+				type = "aoe",
+				position = position,
+				size = range,
+				damage = damages,
+				template = context.template_name
+			})
+
+			local world = context.world
+
+			if type(params) == "table" and params.destroy_particle_id then
+				world:destroy_particles(params.destroy_particle_id)
+			end
+
+			if type(params) == "table" and args.allow_extra_particles and params.spawn_particle then
+				local spawn_particle = params.spawn_particle
+				local p_id = world:create_particles(spawn_particle, position, Quaternion.identity())
+
+				if params.set_particle_variable then
+					local var = params.set_particle_variable.var
+					local value = params.set_particle_variable.value
+
+					if type(value) == "table" then
+						world:set_particles_variable(spawn_particle, p_id, var, Vector3.unbox(value))
+					else
+						world:set_particles_variable(spawn_particle, p_id, var, value)
+					end
+				end
+			end
+
+			local request = {
+				size = range * (area_multiplier or 1),
+				unit = context.unit,
+				position = position,
+				func = function(actors)
+					if not Unit.alive(u) then
+						return
+					end
+
+					if type(params) == "table" and params.position then
+						position = Vector3.unbox(params.position)
+					else
+						position = Unit.world_position(u, 0)
+					end
+
+					if args.offset then
+						position = position + Quaternion.rotate(Unit.world_rotation(u, 0), Vector3.unbox(args.offset))
+					end
+
+					local do_damage = damages ~= nil
+					local elements = FrameTable.alloc_table()
+					local temp_dealers = {}
+
+					for i = 1, #dmg_dealers do
+						if Unit.alive(dmg_dealers[i]) then
+							temp_dealers[#temp_dealers + 1] = dmg_dealers[i]
+						end
+					end
+
+					dmg_dealers = temp_dealers
+
+					if do_damage then
+						for element, amt in pairs(damages) do
+							elements[element] = magnitudes and magnitudes[element] or 1
+
+							if not ignore_multipliers then
+								local pvm_mod = 1
+
+								if not ignore_staff_multiplier then
+									pvm_mod = #dmg_dealers > 0 and pvm:get_variable(dmg_dealers[1], "staff_modifier_element_" .. tostring(element)) or 1
+								end
+
+								damages[element] = amt * (damage_mul and damage_mul[element] or 1) * (imbuement_multiplier or 1) * pvm_mod
+							end
+
+							if (element == "fire" or element == "steam") and elements[element] > 0 then
+								modify_liquid = "fire"
+								liquid_influence_amount = liquid_influence_amount + elements[element]
+							elseif element == "cold" and elements[element] > 0 then
+								modify_liquid = "cold"
+								liquid_influence_amount = liquid_influence_amount + elements[element]
+							end
+						end
+					end
+
+					local already_handled_units = {}
+					local liquid_influence_radius = range * (area_multiplier or 1)
+
+					for _, actor in ipairs(actors) do
+						local unit = Actor.unit(actor)
+
+						if Unit.alive(unit) and not already_handled_units[unit] then
+							already_handled_units[unit] = true
+
+							local units_are_barriers = Unit.get_data(unit, "barrier") and Unit.get_data(u, "barrier") or false
+							local same_barrier_group = units_are_barriers and Unit.get_data(unit, "barrier_group") == Unit.get_data(u, "barrier_group") or false
+							local barrier_check_passed = not units_are_barriers or units_are_barriers and not same_barrier_group
+
+							if barrier_check_passed and unit and (not ignore_unit or unit ~= u) then
+								if do_damage and EntityAux.extension(unit, "damage_receiver") and #dmg_dealers > 0 then
+									EntityAux.add_damage(unit, dmg_dealers, damages, {"volume", "aoe_damage"}, nil, position, ignore_multipliers, damage_source, my_shield_grouping)
+								end
+
+								if do_status and EntityAux.extension(unit, "status") then
+									if set_magnitudes then
+										EntityAux.set_status_magnitude(unit, elements, damage_dealer)
+									else
+										EntityAux.add_status_magnitude(unit, elements, damage_dealer)
+									end
+								end
+
+								local liquid_ext = EntityAux.extension(unit, "liquid")
+
+								if liquid_ext and modify_liquid then
+									local pos = position
+
+									EntityAux.add_liquid_influence(liquid_ext, pos, liquid_influence_radius, modify_liquid, liquid_influence_amount)
+								end
+							end
+						end
+					end
+
+					already_handled_units = nil
+				end
+			}
+
+			pr[#pr + 1] = request
+		end
+	end
+	kmf.bugfixes.dry_ice_fix = function()
+		if not StatusSystemStatuses.frozen._old_on_exit then
+			StatusSystemStatuses.frozen._old_on_exit = StatusSystemStatuses.frozen.on_exit
+		end
+
+		StatusSystemStatuses.frozen.on_exit = function(u, internal, status, network)
+			if internal and kmf.vars.bugfix_enabled then
+				if internal.immunities and internal.immunities["wet"] then
+					internal.immunities["wet"] = false
+				end
+				if internal.temp_immunities and internal.temp_immunities["wet"] then
+					internal.temp_immunities["wet"] = nil
+				end
+			end
+
+			StatusSystemStatuses.frozen._old_on_exit(u, internal, status, network)
+		end
+	end
+
+	kmf.is_unit_dead = function(unit)
+		if not unit or not Unit.alive(unit) then
+			return true
+		end
+
+		local health_ext = EntityAux.extension(unit, "health")
+		local alive = health_ext and health_ext.state
+
+		if alive then
+			local health = health_ext.state.health
+
+			alive = health > 0 and health == health
+
+			if alive then
+				local str = tostring(health)
+				local has_n = str:find('n', 1, true) or false
+
+				alive = not has_n
+			end
+		end
+
+		return not alive
+	end
+
+	kmf.get_channeling_statuses = function(unit)
+		local is_self_channeling = true
+		local is_forward_channeling = true
+
+		local player_ext = EntityAux.extension(unit, "player")
+
+		if player_ext and kmf.vars.bugfix_enabled then
+			local char_ext = EntityAux.extension(unit, "character")
+
+			if char_ext then
+				local char_state = char_ext.input.cast_force_projectile
+				if not char_state then
+					char_state = char_ext.input.args
+				end
+				if char_state == "cast_force_projectile" or char_state == "cast_force_beam" or char_state == "force_charge" or char_state == "cast_force_spray" or char_state == "cast_force_lightning" then
+					is_self_channeling = false
+					is_forward_channeling = true
+				elseif char_state == "cast_self_channeling" then
+					is_self_channeling = true
+					is_forward_channeling = false
+				else
+					is_self_channeling = false
+					is_forward_channeling = false
+				end
+			end
+		end
+
+		return is_self_channeling, is_forward_channeling
+	end
+
+	kmf.bugfixes.channeling_button_fix = function()
+		CharacterStateChargeup.is_channeling = function (self, context, input_data, spellcast_extension)
+			local has_disruptor = false
+			local damage_receiver_ext = EntityAux.extension(self._unit, "damage_receiver")
+			local is_self_channeling, is_forward_channeling = kmf.get_channeling_statuses(self._unit)
+
+			if damage_receiver_ext then
+				has_disruptor = damage_receiver_ext.state.has_disruptor
+			end
+
+			local threshold = (context.has_keyboard and 0.5) or 0.101
+
+			if context.has_keyboard then
+				if (not has_disruptor and threshold < input_data.spell_forward_hold and is_forward_channeling) or (input_data.spell_self_channel > 0 and is_self_channeling) then
+					return true
+				end
+			elseif input_data.spell_forward then
+				local len = math.sqrt(input_data.spell_forward[1] * input_data.spell_forward[1] + input_data.spell_forward[2] * input_data.spell_forward[2])
+
+				if SpellSettings.right_stick_chargeup_release_threashold <= len and spellcast_extension.internal.last_spell ~= "weapon" then
+					return true
+				end
+			end
+
+			return false
+		end
+	end
+	kmf.bugfixes.projectile_pos_fix = function()
+		function flow_callback_on_effect_hit(context)
+			local proj_unit = context.damaging_unit
+			local hit_unit = context.hit_unit
+			local hit_normal = context.hit_normal
+			local hit_position = context.hit_position
+
+			if proj_unit and kmf.vars.bugfix_enabled then
+				local kmf_proj_spawn_time = Unit.get_data(proj_unit, "kmf_proj_spawn_time")
+				local kmf_proj_owner = Unit.get_data(proj_unit, "kmf_proj_owner")
+
+				if kmf_proj_spawn_time then
+					local time = os.clock()
+
+					if kmf_proj_owner and kmf_proj_owner == hit_unit and (time - kmf_proj_spawn_time) < 0.1 then
+						return
+					end
+				end
+			end
+
+			G_flow_delegate:trigger4("on_effect_hit", proj_unit, hit_unit, hit_normal, hit_position)
+		end
+	end
+	kmf.bugfixes.beam_pos_fix = function()
+		Spells_Beam.update = function(data, context)
+			local caster = data.caster
+
+			if not Unit.alive(data.beam_data.owner_staff_unit) then
+				local inventory_ext = EntityAux.extension(caster, "inventory")
+
+				if inventory_ext then
+					local node_data = EntityAux.find_spellcasting_node(nil, caster, data.beam_data.is_standalone)
+					data.beam_data.owner_staff_unit = inventory_ext.inventory.staff
+					data.beam_data.owner_staff_node = node_data.node
+					data.beam_data.position_start = node_data.node_position
+					data.beam_data.position_end = node_data.node_position
+				end
+			end
+
+			if caster and Unit.alive(caster) then
+				local inventory_ext = EntityAux.extension(caster, "inventory")
+
+				if inventory_ext then
+					local node_data = EntityAux.find_spellcasting_node(nil, caster, data.beam_data.is_standalone)
+					data.beam_data.caster_unit = caster
+					data.beam_data.staff_pos = Vector3Box(node_data.node_position)
+				end
+			end
+
+			if context.explode_beam then
+				Spells_Beam.on_cancel(data, context)
+
+				return false
+			elseif ((context.spell_channel == true or data.is_standalone) and data.duration > 0) or (not data.is_standalone and data.run_time < 0.2) then
+				data.duration = data.duration - context.dt
+				data.run_time = data.run_time + context.dt
+
+				return true
+			else
+				Spells_Beam.on_cancel(data, context)
+
+				return false
+			end
+		end
+	end
+
+	kmf.hotbar_disable_mod_patch = function()
+		rawset(_G, "HudMagickMock", {})
+		HudMagickMock.create_magick_list = function(context)
+			local self = {
+				impostor = true
+			}
+			for k, v in pairs(HudMagickMock) do
+				self[k] = v
+			end
+
+			self.magick_ext = context.magick_ext
+			self.all_magicks_disabled = self.magick_ext.all_magicks_disabled
+			self.num_tiers = MagicksSettings.get_num_tiers()
+			self.msg_alias = "hud_magick_mock" .. tostring(context.ctrl_index)
+			self.force_disabled_tiers = self.magick_ext.force_disabled_tiers
+			self.unit = context.unit
+			self.unit_storage = context.unit_storage
+			self.game_mode = context.game_mode
+			self.challenge_gamemode = context.challenge_gamemode
+			self.selectable_magicks = {}
+			self.magicks = context.magicks
+			self.network_message_router = context.network_message_router
+			self.controller = context.controller
+			self.player_manager = context.player_manager
+			self.is_local_player = context.is_local_player
+
+			self.magick_buttons = {}
+			self.magick_buttons[1] = {name = ""}
+			self.magick_buttons[2] = {name = ""}
+			self.magick_buttons[3] = {name = ""}
+			self.magick_buttons[4] = {name = ""}
+
+			assert(context.ctrl_index)
+			local network_messages = {
+				"network_enable_magicks",
+				"network_disable_magicks"
+			}
+			self.network_message_router:register(self.msg_alias, self, unpack(network_messages))
+
+			for tier = 1, self.num_tiers, 1 do
+				local all_magicks = self:filter_unlocked(get_all_magicks_for_tier(tier))
+
+				self.selectable_magicks[tier] = {}
+
+				table.sort(all_magicks)
+
+				for _, magick_name in ipairs(all_magicks) do
+					self.selectable_magicks[tier][magick_name] = true
+				end
+			end
+
+			if self.magick_ext.local_player_id then
+				assert(self.magick_ext.local_player_id)
+
+				self.player_data = self.player_manager:get_player_data(self.magick_ext.local_player_id)
+
+				assert(self.player_data)
+			end
+
+			if self.is_local_player then
+				self:load_selected_magicks()
+			end
+
+			return self
+		end
+
+		HudMagickMock.find_tier_and_index_of_magick = function (self, magick_name)
+			local found_tier = nil
+
+			for tier, list in ipairs(self.selectable_magicks) do
+				for name, data in pairs(list) do
+					if name == magick_name then
+						found_tier = tier
+						break
+					end
+				end
+			end
+
+			return found_tier, 0
+		end
+
+		HudMagickMock.set_magick_template = function (self, unit, name)
+			if self.selected_magick_template == name then
+				self.selected_magick_template = nil
+			else
+				self.selected_magick_template = name
+			end
+
+			SpellWheelSystem:set_magick_template(unit, self.selected_magick_template)
+		end
+
+		HudMagickMock.gpad_clear_gpad_magick_menu_changes = function(self, ...) end
+		HudMagickMock.gpad_clear_gpad_magick_menu_changes_on_tier = function(self, ...) end
+
+		HudMagickMock.on_magicks_updated = function (self, select_magick_template)
+			self:set_selected_magicks_in_extension()
+
+			if select_magick_template and self.is_local_player then
+				self:set_magick_template(self.unit, select_magick_template)
+			end
+		end
+
+		HudMagickMock.clear_magick_template = function (self, unit)
+			self:set_magick_template(unit, "")
+		end
+
+		HudMagickMock.destroy = function (self)
+			self.network_message_router:unregister(self.msg_alias)
+		end
+
+		HudMagickMock.get_selected_magicks_name = function (self, tier, index)
+			return ""
+		end
+
+		HudMagickMock.select_template_from_list = function (self, tier, index, unit)
+			self:set_magick_template(unit, self:get_selected_magicks_name(tier, index))
+		end
+
+		HudMagickMock.is_magick_unlocked = function (self, magick)
+			local challenge_gamemode = self.challenge_gamemode
+			if self.game_mode == "challenge" and (challenge_gamemode == nil or (challenge_gamemode ~= "skilltrial" and challenge_gamemode ~= "timetrial")) then
+				if self.unlocked_challenge_magicks then
+					return self.unlocked_challenge_magicks[magick]
+				end
+
+				return true
+			else
+				return SaveManager:is_magick_unlocked(magick)
+			end
+		end
+
+		HudMagickMock.load_selected_magicks = function (self)
+			if not self.player_data then
+				return
+			end
+
+			self.selected_magick_template = self.player_data:get_selected_magick_template()
+			local tier, index = self:find_tier_and_index_of_magick(self.selected_magick_template)
+
+			if tier then
+				if self.selected_magick_template and (not self:has_magick(self.selected_magick_template) or ArtifactManager:get_modifier_value("NoMagickT" .. tier)) then
+					self.selected_magick_template = ""
+				end
+			end
+
+			SpellWheelSystem:set_magick_template(self.unit, self.selected_magick_template)
+			self:set_selected_magicks_in_extension()
+		end
+
+		HudMagickMock.set_selected_magicks_in_extension = function (self)
+			local magicks = {
+				self.magick_buttons[1].name,
+				self.magick_buttons[2].name,
+				self.magick_buttons[3].name,
+				self.magick_buttons[4].name
+			}
+			local invalid_id = NetworkLookup.invalid_magick_id
+			local selected_magick_ids = {
+				invalid_id,
+				invalid_id,
+				invalid_id,
+				invalid_id
+			}
+			self.magick_ext.selected_magick_ids = selected_magick_ids
+		end
+
+		HudMagickMock.is_magicks_selection_visible = function (self)
+			return false
+		end
+
+		HudMagickMock.network_enable_magicks = function (self, sender, player_go_id)
+			if not self.magicks_forced_disabled then
+				return
+			end
+
+			local player = self.unit_storage:unit(player_go_id)
+
+			if player_go_id == NetworkUnit.invalid_game_object_id or player == self.unit then
+				self.magicks_forced_disabled = false
+			end
+		end
+
+		HudMagickMock.network_disable_magicks = function (self, sender, player_go_id)
+			if self.magicks_forced_disabled then
+				return
+			end
+
+			local player = self.unit_storage:unit(player_go_id)
+
+			if player_go_id == NetworkUnit.invalid_game_object_id or player == self.unit then
+				self.magicks_forced_disabled = true
+			end
+		end
+
+		HudMagickMock.has_magick = function (self, magick_name)
+			if magick_name == nil then
+				return false
+			end
+
+			for k, v in pairs(kmf.const.custom_magics) do
+				if v.translation_string == magick_name then
+					return true
+				end
+			end
+
+			for tier, list in ipairs(self.selectable_magicks) do
+				for name, data in pairs(list) do
+					if name == magick_name then
+						return true
+					end
+				end
+			end
+
+			return false
+		end
+
+		HudMagickMock.is_magick_button_enabled = function (self, magick_tier)
+			return false
+		end
+
+		HudMagickMock.is_tier_force_disabled = function (self, tier)
+			if self.force_disabled_tiers == nil or #self.force_disabled_tiers == 0 then
+				return false
+			else
+				return self.force_disabled_tiers[tier]
+			end
+		end
+
+		HudMagickMock.set_unlocked_challenge_magicks = function (self, unlocked_magicks)
+			self.unlocked_challenge_magicks = unlocked_magicks
+		end
+
+		HudMagickMock.update = function (self, dt, input_data, show_network_huds)
+			self:update_magick_template_selection_mouse_wheel(input_data)
+		end
+
+		HudMagickMock.update_magick_template_selection_mouse_wheel = HudMagicks.update_magick_template_selection_mouse_wheel
+
+		HudMagickMock.filter_unlocked = function (self, all_magicks)
+			local filtered = {}
+			local challenge_gamemode = self.challenge_gamemode
+
+			if self.game_mode == "challenge" and (challenge_gamemode == nil or (challenge_gamemode ~= "skilltrial" and challenge_gamemode ~= "timetrial")) then
+				for nr, magick in ipairs(all_magicks) do
+					if not self.unlocked_challenge_magicks or self.unlocked_challenge_magicks[magick] then
+						table.insert(filtered, magick)
+					end
+				end
+			else
+				for nr, magick in ipairs(all_magicks) do
+					if SaveManager:is_magick_unlocked(magick) then
+						table.insert(filtered, magick)
+					end
+				end
+			end
+
+			return filtered
+		end
+
+		HudMagickMock.is_tier_enabled = function (self, tier)
+			if self.all_magicks_disabled then
+				return false
+			end
+
+			if self.magicks_forced_disabled then
+				return false
+			end
+
+			if self:is_tier_force_disabled(tier) then
+				return false
+			end
+
+			if ArtifactManager:get_modifier_value("NoMagickT" .. tier) then
+				return false
+			end
+
+			if tier == -321 then
+				return true
+			end
+
+			if NetworkUnit.is_local_unit(self.unit) then
+				local tier_magicks = self:filter_unlocked(get_all_magicks_for_tier(tier))
+
+				if #tier_magicks <= 0 then
+					return false
+				end
+			end
+
+			return true
+		end
+
+		HudMagickMock.hide_magicks_selection_tier = function (self, tier, reset_focus_animator)
+		end
+
+		HudMagickMock.hide_magicks_selection  = function (self, tier, reset_focus_animator)
+		end
+	end
+
+	kmf.const.unlock_settings = {
+		orig = {},
+		unlocked = {},
+		save_mgr_methods = {
+			"is_voice_unlocked",
+			"is_robe_unlocked",
+			"is_robe_variant_unlocked",
+			"is_staff_unlocked",
+			"is_weapon_unlocked",
+			"is_familiar_unlocked",
+			"is_magick_unlocked",
+			"is_artifact_unlocked",
+			"is_artifact_level_unlocked",
+			"is_prev_mission_unlocked",
+			"is_mission_unlocked"
+		}
+	}
+	kmf.const.orig_unlock_item_abilities = {}
+	kmf.vars.item_abilities_overrides = {}
+	kmf.const.item_ability_proxy = {
+		__index = function(t, k)
+			if not k then
+				return nil
+			end
+
+			local override = kmf.vars.item_abilities_overrides[k]
+			if override and override.active then
+				return override.data
+			end
+
+			if kmf.const.orig_unlock_item_abilities[k] then
+				return kmf.const.orig_unlock_item_abilities[k]
+			end
+
+			return nil
+		end
+	}
+
+	kmf.default_custom_balance_overrides = function()
+		local recursive_buff_scale
+		recursive_buff_scale = function(table, root)
+			local root_name = root or ""
+
+			if type(table) ~= "table" then
+				return
+			end
+
+			for k, v in pairs(table) do
+				if type(v) == "table" then
+					recursive_buff_scale(v, root_name .. "." .. k)
+				elseif root then
+					if string.find(root, "resistance") and type(v) == "number" then
+						v = ((v - 1) / 2) + 1
+						table[k] = v
+					elseif k == "robe_movement_speed" then
+						v = ((v - 1) / 2) + 1
+						table[k] = v
+					elseif k == "imbuement_multiplier" then
+						v = ((v - 1) / 2) + 1
+						table[k] = v
+					elseif k == "focus_regen_multiplier" then
+						v = ((v - 1) / 2) + 1
+						table[k] = v
+					elseif string.find(k, "staff_modifier_element_") then
+						v = ((v - 1) / 2) + 1
+						table[k] = v
+					end
+				end
+			end
+		end
+
+		recursive_buff_scale(kmf.vars.item_abilities_overrides)
+
+		-- crow staff
+		kmf.vars.item_abilities_overrides.staff_crow.data.modify_tweak_variables.staff_modifier_element_earth = 1.5
+
+		-- peace treaties staff
+		for k, _ in pairs(kmf.vars.item_abilities_overrides.staff_peace_treaties.data.modify_tweak_variables) do
+			kmf.vars.item_abilities_overrides.staff_peace_treaties.data.modify_tweak_variables[k] = 1.30
+		end
+		kmf.vars.item_abilities_overrides.staff_peace_treaties.data.modify_tweak_variables.focus_regen_multiplier = 0.1
+
+		-- lok light staff
+		for k, _ in pairs(kmf.vars.item_abilities_overrides.staff_lok_light.data.modify_tweak_variables) do
+			kmf.vars.item_abilities_overrides.staff_lok_light.data.modify_tweak_variables[k] = 1.15
+		end
+		kmf.vars.item_abilities_overrides.staff_lok_light.data.modify_tweak_variables.focus_regen_multiplier = 0.65
+
+		-- freskar
+		kmf.vars.item_abilities_overrides.feskar_robe_ability.data.resistance[1] = 1.2
+		kmf.vars.item_abilities_overrides.feskar_robe_ability.data.resistance[2] = 0.6
+		kmf.vars.item_abilities_overrides.feskar_robe_ability.data.resistance[3] = 0.6
+
+		-- warlock
+		kmf.vars.item_abilities_overrides.warlock_robe_ability.data.modify_tweak_variables = {
+			robe_movement_speed = 1.15,
+			-- not gonna do for water :/
+			robe_modifier_element_life = 1.5,
+			-- not gonna do for shield :/
+			robe_modifier_element_cold = 1.5,
+			robe_modifier_element_lightning = 1.5,
+			robe_modifier_element_arcane = 1.5,
+			robe_modifier_element_earth = 1.5,
+			robe_modifier_element_fire = 1.5,
+			robe_modifier_element_steam = 1.5,
+			robe_modifier_element_ice = 1.5,
+			robe_modifier_element_poison = 1.5,
+			robe_focus_regen_multiplier = 0.75
+		}
+		kmf.vars.item_abilities_overrides.warlock_robe_ability.data.resistance = {
+			{ "water", "mul", 1.5 },
+			{ "life", "mul", 1.5 },
+			{ "cold", "mul", 1.5 },
+			{ "lightning", "mul", 1.5 },
+			{ "arcane", "mul", 1.5 },
+			{ "earth", "mul", 1.5 },
+			{ "fire", "mul", 1.5 },
+			{ "steam", "mul", 1.5 },
+			{ "ice", "mul", 1.5 },
+			{ "poison", "mul", 1.5 },
+		}
+
+		-- epic
+		kmf.vars.item_abilities_overrides.epic_robe_ability.data.modify_tweak_variables = {
+			robe_movement_speed = 0.85,
+			-- not gonna do for water :/
+			robe_modifier_element_life = 0.5,
+			-- not gonna do for shield :/
+			robe_modifier_element_cold = 0.5,
+			robe_modifier_element_lightning = 0.5,
+			robe_modifier_element_arcane = 0.5,
+			robe_modifier_element_earth = 0.5,
+			robe_modifier_element_fire = 0.5,
+			robe_modifier_element_steam = 0.5,
+			robe_modifier_element_ice = 0.5,
+			robe_modifier_element_poison = 0.5,
+			robe_focus_regen_multiplier = 1.25
+		}
+		kmf.vars.item_abilities_overrides.epic_robe_ability.data.resistance = {
+			{ "water", "mul", 0.5 },
+			{ "life", "mul", 0.5 },
+			{ "cold", "mul", 0.5 },
+			{ "lightning", "mul", 0.5 },
+			{ "arcane", "mul", 0.5 },
+			{ "earth", "mul" , 0.5 },
+			{ "fire", "mul", 0.5 },
+			{ "steam", "mul", 0.5 },
+			{ "ice", "mul", 0.5 },
+			{ "poison", "mul", 0.5 },
+		}
+	end
+
+	kmf.prepare_unlocks = function()
+		local copy_item_abilities = function(settings)
+			for name, data in pairs(settings) do
+				for k, v in pairs(data) do
+					if k == "item_ability" then
+						for ability_name, ability_data in pairs(v) do
+							kmf.vars.item_abilities_overrides[ability_name] = {
+								active = false,
+								data = table.deep_clone(ability_data)
+							}
+						end
+					end
+				end
+			end
+		end
+
+		copy_item_abilities(RobeSettings.robes)
+		copy_item_abilities(WeaponSettings.weapons)
+		copy_item_abilities(StaffSettings.staffs)
+
+		kmf.default_custom_balance_overrides()
+
+		kmf.const.unlock_settings.orig.RobeSettings = table.deep_clone(RobeSettings)
+		kmf.const.unlock_settings.orig.WeaponSettings = table.deep_clone(WeaponSettings)
+		kmf.const.unlock_settings.orig.StaffSettings = table.deep_clone(StaffSettings)
+		kmf.const.unlock_settings.orig.MagicksSettings = table.deep_clone(MagicksSettings)
+		kmf.const.unlock_settings.orig.LevelSettings = table.deep_clone(LevelSettings)
+
+		kmf.const.unlock_settings.unlocked.RobeSettings = table.deep_clone(RobeSettings)
+		kmf.const.unlock_settings.unlocked.WeaponSettings = table.deep_clone(WeaponSettings)
+		kmf.const.unlock_settings.unlocked.StaffSettings = table.deep_clone(StaffSettings)
+		kmf.const.unlock_settings.unlocked.MagicksSettings = table.deep_clone(MagicksSettings)
+		kmf.const.unlock_settings.unlocked.LevelSettings = table.deep_clone(LevelSettings)
+
+		local recursive_unlock
+		recursive_unlock = function(table)
+			if type(table) ~= "table" then
+				return
+			end
+
+			for k, v in pairs(table) do
+				if type(v) == "table" then
+					recursive_unlock(v)
+				else
+					if k == "unlocked" then
+						table[k] = true
+					elseif k == "dlc" or k == "hide_locked" or k == "unlocked_from_other_source" or k == "skip_package_generation" then
+						table[k] = nil
+					end
+				end
+			end
+		end
+
+		recursive_unlock(kmf.const.unlock_settings.unlocked.RobeSettings)
+		recursive_unlock(kmf.const.unlock_settings.unlocked.WeaponSettings)
+		recursive_unlock(kmf.const.unlock_settings.unlocked.StaffSettings)
+		recursive_unlock(kmf.const.unlock_settings.unlocked.MagicksSettings)
+		recursive_unlock(kmf.const.unlock_settings.unlocked.LevelSettings)
+
+		for _, method in pairs(kmf.const.unlock_settings.save_mgr_methods) do
+			pcall(function()
+				SaveManager["_ulk_" .. method] = function (self, ...) return true end
+				SaveManager["_org_" .. method] = SaveManager[method]
+			end)
+		end
+	end
+
+	kmf.check_funbalance_unlocks = function()
+		if kmf.check_mod_enabled("equipment re-balance") then
+			for abil_name, abil_override in pairs(kmf.vars.item_abilities_overrides) do
+				abil_override.active = true
+			end
+		else
+			for abil_name, abil_override in pairs(kmf.vars.item_abilities_overrides) do
+				abil_override.active = false
+			end
+		end
+	end
+
+	kmf.apply_pvp_unlocks = function()
+		RobeSettings = kmf.const.unlock_settings.unlocked.RobeSettings
+		WeaponSettings = kmf.const.unlock_settings.unlocked.WeaponSettings
+		StaffSettings = kmf.const.unlock_settings.unlocked.StaffSettings
+		MagicksSettings = kmf.const.unlock_settings.unlocked.MagicksSettings
+
+		for _, method in pairs(kmf.const.unlock_settings.save_mgr_methods) do
+			pcall(function()
+				SaveManager[method] = SaveManager["_ulk_" .. method]
+			end)
+		end
+	end
+
+	kmf.remove_pvp_unlocks = function()
+		RobeSettings = kmf.const.unlock_settings.orig.RobeSettings
+		WeaponSettings = kmf.const.unlock_settings.orig.WeaponSettings
+		StaffSettings = kmf.const.unlock_settings.orig.StaffSettings
+		MagicksSettings = kmf.const.unlock_settings.orig.MagicksSettings
+
+		for _, method in pairs(kmf.const.unlock_settings.save_mgr_methods) do
+			pcall(function()
+				SaveManager[method] = SaveManager["_org_" .. method]
+			end)
+		end
+	end
+
+	kmf.add_host_mod_warning_patch = function()
+		if not _UIMessageManager._old_push_message then
+			_UIMessageManager._old_push_message = _UIMessageManager.push_message
+		end
+		_UIMessageManager.push_message = function (self, category, message)
+			local idx_start, _ = string.find(message, "please visit pepega.online", 1, true)
+			if idx_start then
+				kmf_print("received modded lobby warning !!!")
+				return
+			end
+
+			return _UIMessageManager._old_push_message(self, category, message)
+		end
+
+		if not NetworkGameModeChallengeClientGame._old_from_server_show_challenge_message then
+			NetworkGameModeChallengeClientGame._old_from_server_show_challenge_message = NetworkGameModeChallengeClientGame.from_server_show_challenge_message
+		end
+		NetworkGameModeChallengeClientGame.from_server_show_challenge_message = function(self, sender, msg, time)
+			local idx_start, _ = string.find(msg, "please visit pepega.online", 1, true)
+			if idx_start then
+				kmf_print("received modded lobby warning !!!")
+				return
+			end
+
+			return NetworkGameModeChallengeClientGame._old_from_server_show_challenge_message(self, sender, msg, time)
+		end
+	end
+
+	kmf.send_modded_section_warning = function(peer)
+		if (not kmf.lobby_handler) or (not kmf.lobby_handler:is_host()) or (peer == kmf.const.me_peer) then
+			return
+		end
+
+		kmf.task_scheduler.add(function ()
+			if kmf.event_delegate and (kmf.event_delegate.registered_eventhandlers["gamemode_challenge_server"] or kmf.event_delegate.registered_eventhandlers["gamemode_challenge_client_game"]) then
+				kmf.task_scheduler.add(function ()
+					RPC.from_server_show_challenge_message(peer, "This is a modded session\nplease visit pepega.online", 3)
+				end, 2000)
+			else
+				kmf.send_status_message_peer(peer, "This is a modded session\nplease visit pepega.online")
+			end
+		end, 3000)
+	end
+
+	kmf.apply_spell_settings_patches = function()
+		if not SpellSettings._old_get_spray_damage then
+			SpellSettings._old_get_spray_damage = SpellSettings.get_spray_damage
+		end
+
+		SpellSettings.get_spray_damage = function(self, pvm, caster, elements)
+			local damage, magnitudes = SpellSettings._old_get_spray_damage(self, pvm, caster, elements)
+
+			-- fun-balance :: buff spray damage
+			if kmf.vars.funprove_enabled then
+				kmf_print("in SpellSettings.get_spray_damage()")
+				for k, v in pairs(damage) do
+					damage[k] = v * 2
+				end
+			end
+
+			return damage, magnitudes
+		end
+
+		if not SpellSettings._old_get_beam_damage then
+			SpellSettings._old_get_beam_damage = SpellSettings.get_beam_damage
+		end
+
+		SpellSettings.get_beam_damage = function(self, pvm, caster, elements, beam_level)
+			local damage, magnitudes = SpellSettings._old_get_spray_damage(self, pvm, caster, elements, beam_level)
+
+			-- fun-balance :: buff beam damage
+			if kmf.vars.funprove_enabled then
+				kmf_print("in SpellSettings.get_beam_damage()")
+				for k, v in pairs(damage) do
+					damage[k] = v * 4.0
+				end
+			end
+
+			return damage, magnitudes
+		end
+
+		local function get_phys_damage_mult(elements)
+			local non_phys_elem = (elements.arcane or 0) +
+					(elements.lightning or 0) +
+					(elements.fire or 0) +
+					(elements.cold or 0) +
+					(elements.poison or 0) +
+					(elements.steam or 0) +
+					(elements.life or 0)
+
+			--local phys_elem = (elements.ice or 0) +
+			--	(elements.earth or 0)
+
+			if non_phys_elem > 0.5 then
+				return 0.75
+			else
+				return 1.33
+			end
+		end
+
+		if not SpellSettings._old_get_aoe_damage then
+			SpellSettings._old_get_aoe_damage = SpellSettings.get_aoe_damage
+		end
+
+		SpellSettings.get_aoe_damage = function (self, pvm, caster, elements)
+			local damage, magnitudes = SpellSettings._old_get_aoe_damage(self, pvm, caster, elements)
+
+			-- fun-balance :: buff aoe damage
+			if kmf.vars.funprove_enabled then
+				kmf_print("in SpellSettings.get_aoe_damage()")
+				for k, v in pairs(damage) do
+					if k ~= "knockdown" then
+						damage[k] = v * 1.5
+					end
+				end
+
+				-- fun-balance :: buff to aoe knockdown, constant multiplier has to be adjusted to fit the balance player damage multiplier
+				if damage.knockdown then
+					damage.knockdown = damage.knockdown * 1.5 * self:get_pvm_element_modifier(pvm, caster, "earth")
+				end
+
+				local phys_mult = get_phys_damage_mult(elements)
+
+				if damage.earth then
+					damage.earth = damage.earth * 4.5 * phys_mult
+				end
+
+				if damage.ice then
+					damage.ice = damage.ice * 1.5 * phys_mult
+				end
+			end
+
+			return damage, magnitudes
+		end
+
+		if not SpellSettings._old_get_fissure_damage then
+			SpellSettings._old_get_fissure_damage = SpellSettings.get_fissure_damage
+		end
+
+		SpellSettings.get_fissure_damage = function (self, pvm, caster, elements)
+			local damage, magnitudes = SpellSettings._old_get_fissure_damage(self, pvm, caster, elements)
+
+			if kmf.vars.funprove_enabled then
+				kmf_print("in SpellSettings.get_fissure_damage()")
+
+				-- fun-balance :: buff to fissure damage and knockdown, constant multiplier has to be adjusted to fit the balance player damage multiplier
+				for k, v in pairs(damage) do
+					if k ~= "knockdown" then
+						damage[k] = v * 1.5
+					end
+				end
+
+				if elements.earth and elements.earth > 0 then
+					local base_damage = SpellSettings:get_type_damage(pvm, caster, "earth")
+					local calculated_damage = self:scale_amount(base_damage, elements.earth, "AOE", "earth")
+
+					damage.earth = calculated_damage * 3
+					damage.earth = damage.earth * SpellSettings.aoe_earth_damage_scale
+				end
+
+				local phys_mult = get_phys_damage_mult(elements)
+				phys_mult = phys_mult > 1.0 and ((phys_mult + 1.0) / 2.0) or phys_mult
+
+				if damage.earth then
+					damage.earth = damage.earth * 2 * phys_mult
+				end
+
+				if damage.ice then
+					damage.ice = damage.ice * 2 * phys_mult
+				end
+
+				if damage.knockdown then
+					damage.knockdown = damage.knockdown * 1.5 * self:get_pvm_element_modifier(pvm, caster, "earth")
+				end
+			end
+
+			return damage, magnitudes
+		end
+
+		if not SpellSettings._old_get_elemental_wall_damage then
+			SpellSettings._old_get_elemental_wall_damage = SpellSettings.get_elemental_wall_damage
+		end
+
+		SpellSettings.get_elemental_wall_damage = function (self, pvm, owner, elements, ability)
+			local multipliers, magnitudes = SpellSettings._old_get_elemental_wall_damage(self, pvm, owner, elements, ability)
+
+			-- fun-balance :: increase elemental wall
+			if kmf.vars.funprove_enabled then
+				kmf_print("in SpellSettings.get_elemental_wall_damage()")
+				for k, v in pairs(multipliers) do
+					multipliers[k] = v * 4.0
+				end
+			end
+
+			return multipliers, magnitudes
+		end
+
+		if not SpellSettings._old_get_barrier_elemental_dot_damage then
+			SpellSettings._old_get_barrier_elemental_dot_damage = SpellSettings.get_barrier_elemental_dot_damage
+		end
+
+		SpellSettings.get_barrier_elemental_dot_damage = function(self, pvm, caster, elements, ability)
+			local multipliers, magnitudes = SpellSettings._old_get_barrier_elemental_dot_damage(self, pvm, caster, elements, ability)
+
+			-- fun-balance :: increase barrier damage
+			if kmf.vars.funprove_enabled then
+				kmf_print("in SpellSettings.get_barrier_elemental_dot_damage()")
+				for k, v in pairs(multipliers) do
+					if k ~= "life" then
+						multipliers[k] = v * 3
+					--else
+					--	multipliers[k] = v * 1
+					end
+				end
+			end
+
+			return multipliers, magnitudes
+		end
+
+		function SpellSettings:get_pvm_element_modifier(pvm, caster, elem)
+			if not pvm or not caster then
+				return 1
+			end
+
+			return pvm:get_variable(caster, "staff_modifier_element_" .. elem) or 1
+		end
+
+		if not SpellSettings._old_get_earthprojectile_damage then
+			SpellSettings._old_get_earthprojectile_damage = SpellSettings.get_earthprojectile_damage
+		end
+
+		SpellSettings.get_earthprojectile_damage = function (self, pvm, caster, elements, charge_factor)
+			local damage, magnitudes = SpellSettings._old_get_earthprojectile_damage(self, pvm, caster, elements, charge_factor)
+
+			-- fun-balance :: buff pure rock damage
+			if kmf.vars.funprove_enabled then
+				kmf_print("in SpellSettings.get_earthprojectile_damage()")
+				local earth_count_mult = (elements["earth"] or 1) / 10.0
+
+				for k, v in pairs(damage) do
+					if k == "earth" then
+						damage[k] = v * (1.5 + earth_count_mult)
+					end
+				end
+			end
+
+			return damage, magnitudes
+		end
+	end
+
+	kmf.balance_patches = function()
+		local selfshield_ignoring_elements = {
+			force_life = true,
+			lokif = true,
+			elevate = true,
+			push = true,
+			lokel = true,
+			lokts = true,
+			lokld = true,
+			tachyon = true,
+			earth = true,
+			ice = true
+		}
+
+		function DamageAux_selfshield_absorbs(element)
+			if selfshield_ignoring_elements[element] then
+				return false
+			end
+
+			if kmf.vars.funprove_enabled and element == "knockdown" then
+				return false
+			end
+
+			return true
+		end
+
+		if not CharacterStateMachine._old_init then
+			CharacterStateMachine._old_init = CharacterStateMachine.init
+		end
+
+		CharacterStateMachine.init = function(self, context)
+			self._kmf_unit = context.unit
+
+			return CharacterStateMachine._old_init(self, context)
+		end
+
+		CharacterStateMachine.change_state = function(self, new_state)
+			cat_print_spam("CharacterStateMachine", "Switching to state:", new_state)
+
+			if self._states[new_state] == nil then
+				kmf_print("Trying to change to a state that doesn't exist.")
+				return
+			end
+
+			if new_state == self._state_name then
+				kmf_print("Trying to change to state that we are already in.")
+				return
+			end
+
+			if self._state_name == "knocked_down" then
+				local time = kmf.world_proxy:time()
+				self._kmf_last_knockdown_exit_time = time
+			end
+
+			if new_state == "knocked_down" and self._kmf_unit and Unit.alive(self._kmf_unit) then
+				local char_ext = EntityAux.extension(self._kmf_unit, "character")
+
+				if char_ext then
+					local time = kmf.world_proxy:time()
+					local exit_time = self._kmf_last_knockdown_exit_time or 0
+					local delta = time - exit_time
+
+					if delta < 0.33 then
+						EntityAux.set_input_by_extension(char_ext, CSME.knockdown, false)
+						return
+					end
+				end
+			end
+
+			local args = {}
+
+			args.new_state = new_state
+
+			self._active_state:on_exit(args)
+
+			self._active_state = self._states[new_state]
+
+			self._active_state:on_enter(self.args, self._state_name)
+
+			self._state_name = new_state
+		end
+
+		function flow_callback_unspawn_unit(params)
+			local u = params.unit
+
+			if not (u and Unit.alive(u)) then
+				return
+			end
+
+			if kmf.unit_storage and (kmf.vars.bugfix_enabled or kmf.vars.funprove_enabled) then
+				local go_id = kmf.unit_storage:go_id(u)
+
+				if go_id then
+					local members = kmf.lobby_handler.connected_peers
+					local me_peer = kmf.const.me_peer
+					local msg = tostring(kmf.unit_storage:go_id(go_id))
+
+					for _, peer in ipairs(members) do
+						if peer ~= me_peer then
+							kmf.send_kmf_msg(peer, msg, "uspwn-u")
+						end
+					end
+				end
+			end
+
+			if not NetworkUnit.is_local_unit(u) then
+				return
+			end
+
+			G_flow_delegate:trigger1("unspawn_unit", u)
+		end
+	end
+
+	kmf.const.funbalance = {}
+	kmf.const.funbalance.poison_mult = 2.8
+
+	kmf.pvp_patches = function()
+		if not kmf.const.orig_magick_cds then
+			kmf.const.orig_magick_cds = {}
+		end
+
+		for k, v in pairs(MagicksSettings) do
+			if type(MagicksSettings[k]) == "table" and MagicksSettings[k].cooldown then
+				kmf.const.orig_magick_cds[k] = MagicksSettings[k].cooldown
+			end
+		end
+
+		if not kmf.const.magicks_cooldown then
+			kmf.const.magicks_cooldown = {}
+		end
+
+		for k, v in pairs(Magicks) do
+			kmf.const.magicks_cooldown[k] = 15
+		end
+
+		kmf.const.magicks_cooldown["haste"] = 10
+		kmf.const.magicks_cooldown["haste"] = 10
+		kmf.const.magicks_cooldown["teleport"] = 5
+		kmf.const.magicks_cooldown["emergency_teleport"] = 5
+		kmf.const.magicks_cooldown["concussion"] = 5
+		kmf.const.magicks_cooldown["push"] = 5
+		kmf.const.magicks_cooldown["abuse_a_scroll"] = 3
+		kmf.const.magicks_cooldown["summon_living_dead"] = 20
+		kmf.const.magicks_cooldown["thunderbolt"] = 10
+		kmf.const.magicks_cooldown["guardian"] = 60
+		kmf.const.magicks_cooldown["revive"] = 30
+		kmf.const.magicks_cooldown["dispell"] = 7.5
+		kmf.const.magicks_cooldown["disruptor"] = 10
+		kmf.const.magicks_cooldown["sacrifice"] = 60
+		kmf.const.magicks_cooldown["force_prism"] = 10
+		kmf.const.magicks_cooldown["area_prism"] = 10
+	end
+
+	kmf.misc_convenience = function()
+		GameStateLoading.is_allowed_to_join = function(self)
+			if self.lobby_handler:data("cutscene_active") == "true" then
+				self.kmf_last_allowed_join_result = false
+				return false, "joa_ui_loadingscreen_waitingcutscene"
+			end
+
+			if self.lobby_handler:data("video_active") == "true" then
+				self.kmf_last_allowed_join_result = false
+				return false, "joa_ui_loadingscreen_waitingvideo"
+			end
+
+			if not self.kmf_last_allowed_join_result then
+				self.auto_continue = true
+			end
+
+			self.kmf_last_allowed_join_result = true
+
+			return true
+		end
+	end
+
+	kmf.execute_autoexec_scripts = function()
+		local file_list
+
+		if Application.is_win32() then
+			file_list = io.popen([[dir "./autoexec" /b]]):lines()
+		else
+			file_list = io.popen([[ls -pa ./autoexec | grep -v /]]):lines()
+		end
+
+		for file in file_list do
+			if file:match(".lua$") or (kmf_dofile and (file:match(".luac$") or file:match(".ljbc$"))) then
+				local path = "./autoexec/" .. file
+
+				local staus, err = pcall(function()
+					if kmf_dofile then
+						kmf_dofile(path)
+					else
+						local f = io.open(path, "r")
+						local content = f:read("*all")
+						f:close()
+
+						loadstring(content)()
+					end
+				end)
+
+				if not staus then
+					k_log("[AUTOEXEC] error executing script :: \"" .. path .. "\"\n" .. tostring(err))
+				end
+			end
+		end
+	end
+
+	kmf.before_start_ability = function(name, template, u)
+		for filter, handler in pairs(kmf.vars.before_start_ability_filters) do
+			if string.find(name, filter) then
+				template = handler(name, template, u)
+			end
+		end
+
+		return template
+	end
+
+	kmf.vars.before_start_ability_filters["^helltroll_%S+_foot_aoe$"] = function(name, template, u)
+		local is_right_foot = string.find(name, "right")
+		local temp = table.deep_clone(template)
+		local rot = Unit.local_rotation(u, 0)
+		local offset = Quaternion.rotate(rot, Vector3(is_right_foot and 1 or -1, 1.5 ,0))
+
+		temp.play_effect = {
+			effect = "blast_fire",
+			offset = {
+				offset.x,
+				offset.y,
+				0.5
+			}
+		}
+
+		return temp
+	end
+
+	kmf.late_initialization_done = false
+
+	kmf.late_initialization = function()
+		if kmf.late_initialization_done then
+			return
+		end
+
+		kmf.try_register_dofile()
+
+		if not EventDelegate._old_init then
+			EventDelegate._old_init = EventDelegate.init
+		end
+		EventDelegate.init = function(self)
+			kmf.event_delegate = self
+
+			return EventDelegate._old_init(self)
+		end
+
+		kmf.init_custom_magics()
+		kmf.runtime_bug_fixes()
+		kmf.kbd_watcher_set_kbd_mapping()
+		kmf.hotbar_disable_mod_patch()
+		kmf.balance_patches()
+		kmf.pvp_patches()
+		kmf.prepare_unlocks()
+		kmf.add_host_mod_warning_patch()
+
+		for k, v in pairs(kmf.bugfixes) do
+			kmf_print("kmf.late_initialization()", "running bugfix :: " .. k)
+			v()
+		end
+
+		kmf.execute_autoexec_scripts()
+		kmf.register_custom_magics()
+
+		kmf.vars.ui_context = require("scripts/game/ui2/ui_context")
+
+		kmf.late_initialization_done = true
+
+		PlayerColors[-2] = {
+			60,
+			27,
+			90
+		}
+
+		kmf.misc_convenience()
+
+		BreakableSystemSettings.small_wood_animal.gib_units = {
+			"content/units/npc/general_gibs/general_gibs" -- to fix crash squirrel
+		}
+	end
+
+	kmf.check_hotbar_disable_change = function()
+		local mod_status = kmf.check_mod_enabled("remove magick hud") or false
+
+		if kmf.vars.remove_magick_hud_status ~= mod_status then
+			kmf.vars.remove_magick_hud_status = mod_status
+			kmf.update_magick_cds()
+
+			local h = 1440
+			local w = 2560
+			local act_w, act_h = Application.resolution()
+			local w_coef = act_w / w
+			local h_coef = act_h / h
+
+			if mod_status then
+				PlayerFrameLayout.passes[2] = {
+					texture = "black_bg_tiled",
+					name = "texture_tiled",
+					color = {100, 0, 0, 0},
+					size = {460 * w_coef, 165 * h_coef}
+				}
+			else
+				PlayerFrameLayout.passes[2] = {
+					texture = "hud_bg_plate",
+					name = "texture",
+					offset = {0, -12, 0}
+				}
+			end
+
+			if kmf.hud_manager then
+				for u, _ in pairs(kmf.hud_manager.unit_to_gui_index) do
+					kmf.hud_manager:remove_player_hud(u)
+
+					kmf.task_scheduler.add(function()
+						for global_player_id, init_data in pairs(kmf.hud_manager.player_hud_init_data) do
+							kmf.hud_manager:add_player_hud(init_data.u, init_data.magicks, init_data.magick_ext, init_data.is_local_player, init_data.local_player_id, global_player_id)
+						end
+					end)
+				end
+			end
+		end
+	end
+
+	kmf.render_mov_conv = function()
+		local sz = kmf.vars.movement_convenience.screen_scale / 8
+		local x = kmf.vars.movement_convenience.orig_x - (sz / 2)
+		local y = kmf.vars.movement_convenience.orig_y - (sz / 2)
+
+		Gui.bitmap(
+			kmf.vars.ui_context.ui_renderer.gui,
+			kmf.vars.movement_convenience.bg_tex,
+			Vector3(x, y, 0),
+			Vector2(sz, sz),
+			Color(96, 0, 0, 0)
+		)
+
+		sz = kmf.vars.movement_convenience.screen_scale / 60
+		x = kmf.vars.movement_convenience.orig_x - (sz / 2)
+		y = kmf.vars.movement_convenience.orig_y - (sz / 2)
+
+		for _, texture in pairs(kmf.vars.movement_convenience.fg_texs) do
+			Gui.bitmap(
+				kmf.vars.ui_context.ui_renderer.gui,
+				texture,
+				Vector3(x, y, 0),
+				Vector2(sz, sz),
+				Color(64, 255, 255, 255)
+			)
+		end
+	end
+
+	kmf.update_magick_cds = function()
+		if kmf.vars.funprove_enabled then
+			if kmf.const.magicks_cooldown then
+				for k, v in pairs(MagicksSettings) do
+					if type(MagicksSettings[k]) == "table" and MagicksSettings[k].cooldown then
+						MagicksSettings[k].cooldown = kmf.const.magicks_cooldown[k] or 15
+					end
+				end
+			end
+		else
+			if kmf.const.orig_magick_cds then
+				for k, v in pairs(MagicksSettings) do
+					if type(MagicksSettings[k]) == "table" and MagicksSettings[k].cooldown then
+						MagicksSettings[k].cooldown = kmf.const.orig_magick_cds[k] or 3
+					end
+				end
+			end
+		end
+	end
+
+	kmf.check_funprove_change = function()
+		local status = kmf.check_mod_enabled("balance fun-provements")
+		local status_changed = kmf.vars.funprove_enabled ~= status
+		kmf.vars.funprove_enabled = status
+		kmf.vars.experimental_balance = kmf.check_mod_enabled("experimental balance")
+
+		if status_changed then
+			kmf.update_magick_cds()
+		end
+
+		-- fun-balance :: changing the spell settings
+		-- fun-balance :: buff poison slowdown
+		-- fun-balance :: nerf lightning damage multiplier
+		-- fun-balance :: buff poison max dot damage
+		-- fun-balance :: buff fire max dot damage and nerf burning levels
+		if status then
+			SpellSettings.status_poisoned_speed_factor = 0.625
+			SpellSettings.lightning_mult_on_wet = 2
+			SpellSettings.status_poisoned_max_damage = 667
+			SpellSettings.status_burn_level_2_start = 100
+			SpellSettings.status_burn_level_3_start = 220
+			SpellSettings.status_burn_max_dps = 667
+			SpellSettings.dragon_strike_damage_tick_interval = 0.1
+			SpellSettings.dragon_strike_spawn_interval = 0.02
+			SpellSettings.highland_breeze_damage_tick_interval = 0.075
+			SpellSettings.abuse_a_scroll_lightning_strike_damage = 5000
+			AccessoryTemplates.human_skeleton_magick.sword.inventory_type = "weapon_cheese_slicer"
+			SpellSettings.shield_self_decay_rate = 0.05
+			SpellSettings.shield_self_decay = 285
+			SpellSettings.elemental_wall_lightning_reflect_time = 0.1
+			SpellSettings.elemental_wall_lightning_reflect_damage = 10
+		else
+			SpellSettings.status_poisoned_speed_factor = 0.75
+			SpellSettings.lightning_mult_on_wet = 3
+			SpellSettings.status_poisoned_max_damage = 333
+			SpellSettings.status_burn_level_2_start = 60
+			SpellSettings.status_burn_level_3_start = 100
+			SpellSettings.status_burn_max_dps = 333
+			SpellSettings.dragon_strike_damage_tick_interval = 0.33
+			SpellSettings.dragon_strike_spawn_interval = 0.05
+			SpellSettings.highland_breeze_damage_tick_interval = 0.33
+			SpellSettings.abuse_a_scroll_lightning_strike_damage = 2000
+			AccessoryTemplates.human_skeleton_magick.sword.inventory_type = "npc_wpn_skeleton_magick_sword_00"
+			SpellSettings.shield_self_decay_rate = 0.1
+			SpellSettings.shield_self_decay = 35
+			SpellSettings.elemental_wall_lightning_reflect_time = 2
+			SpellSettings.elemental_wall_lightning_reflect_damage = 40
+		end
+
+		if status or kmf.vars.pvp_gamemode then
+			DamageNumberSettings.ttl_healing = 0.45
+			DamageNumberSettings.ttl_damage_direct = 0.45
+			DamageNumberSettings.ttl_status = 0.45
+			DamageNumberSettings.min_font_size = 18
+			DamageNumberSettings.max_font_size = 24
+			DamageNumberSettings.dissapear_time = 1
+			DamageNumberSettings.dissapear_time_animated = 1
+			DamageNumberSettings.font_size_step = 150
+			DamageNumberSettings.animate_category = {
+				damage_direct = true,
+				healing = true,
+				damage_direct_high = true
+			}
+			DamageNumberSettings.direct_damage_threshold.threshold = 1000
+		else
+			DamageNumberSettings.ttl_healing = 2
+			DamageNumberSettings.ttl_damage_direct = 2
+			DamageNumberSettings.ttl_status = 1
+			DamageNumberSettings.min_font_size = 22
+			DamageNumberSettings.max_font_size = 32
+			DamageNumberSettings.dissapear_time = 1
+			DamageNumberSettings.dissapear_time_animated = 2
+			DamageNumberSettings.font_size_step = 200
+			DamageNumberSettings.animate_category = {
+				damage_direct = false,
+				healing = true,
+				damage_direct_high = true
+			}
+			DamageNumberSettings.direct_damage_threshold.threshold = 3600
+		end
+	end
+
+	kmf.destroy_gamepad_aiming = function()
+		if kmf.vars.gamepad_aiming then
+			local move_unit = kmf.vars.gamepad_aiming.move_unit
+			local click_unit = kmf.vars.gamepad_aiming.click_unit
+			kmf.vars.gamepad_aiming = nil
+
+			if kmf.unit_spawner then
+				if move_unit and Unit.alive(move_unit) then
+					kmf.unit_spawner:mark_for_deletion(move_unit)
+				end
+				if click_unit and Unit.alive(click_unit) then
+					kmf.unit_spawner:mark_for_deletion(click_unit)
+				end
+			end
+		end
+	end
+
+	kmf.setup_gamepad_aiming = function()
+		if kmf.unit_spawner and kmf.world_proxy then
+			local gamepad_aiming = {}
+
+			gamepad_aiming.raycast_callback = function(hits)
+				if not hits then
+					return
+				end
+
+				local lowest_z = 1000000
+				local position
+
+				for _, hit in pairs(hits) do
+					if hit[1] then
+						local z = Vector3.z(hit[1])
+
+						if z < lowest_z then
+							position = hit[1]
+						end
+					end
+				end
+
+				if not position then
+					return
+				end
+
+				local state = kmf.vars.gamepad_aiming
+
+				state.aim_pos = {
+					x = Vector3.x(position),
+					y = Vector3.y(position),
+					z = Vector3.z(position)
+				}
+
+				if state.move_unit and Unit.alive(state.move_unit) then
+					Unit.set_local_position(state.move_unit, 0, position)
+				end
+				if state.click_unit and Unit.alive(state.click_unit) then
+					Unit.set_local_position(state.click_unit, 0, position)
+				end
+			end
+
+			local raycast_callback = function(any_hit, position, distance, normal, actor)
+				if kmf.vars.gamepad_aiming then
+					kmf.vars.gamepad_aiming.raycast_callback(any_hit, position, distance, normal, actor)
+				end
+			end
+
+			gamepad_aiming.raycaster = PhysicsWorld.make_raycast(kmf.world_proxy:physics_world(), raycast_callback, "all", "types", "statics", "collision_filter", "static_query")
+
+			local move_unit = kmf.unit_spawner:spawn_unit_local(GameSettings.move_to_unit, Vector3(-100, -100, -100), Quaternion.identity())
+			local click_unit = kmf.unit_spawner:spawn_unit_local(GameSettings.move_to_unit_click, Vector3(-100, -100, -100), Quaternion.identity())
+			local raw_w, raw_h = Application.resolution()
+
+			gamepad_aiming.move_unit = move_unit
+			gamepad_aiming.click_unit = click_unit
+			gamepad_aiming.sreen_pos = {
+				x = raw_w / 2,
+				y = raw_h / 2
+			}
+			gamepad_aiming.prev_time = os.clock()
+
+			local mu_mesh = Unit.mesh(move_unit, "g_body")
+			local mu_material = Mesh.material(mu_mesh, 0)
+			local cu_mesh = Unit.mesh(click_unit, "g_body")
+			local cu_material = Mesh.material(cu_mesh, 0)
+
+			Material.set_vector3(mu_material, "color_tint", Vector3(0.11, 0.22, 0.33))
+			Material.set_vector3(cu_material, "color_tint", Vector3(0.22, 0.11, 0.33))
+			Material.set_vector3(mu_material, "scale", Vector3(1.5, 1.5, 2))
+			Material.set_vector3(cu_material, "scale", Vector3(1.5, 1.5, 2))
+
+			kmf.vars.gamepad_aiming = gamepad_aiming
+		end
+	end
+
+	kmf.find_active_gamepad = function()
+		local status, err = pcall(function()
+			if Pad1 and Pad1.active() then
+				return Pad1
+			end
+			if Pad2 and Pad2.active() then
+				return Pad2
+			end
+			if Pad3 and Pad3.active() then
+				return Pad3
+			end
+			if Pad4 and Pad4.active() then
+				return Pad4
+			end
+			if Pad5 and Pad5.active() then
+				return Pad5
+			end
+			if Pad6 and Pad6.active() then
+				return Pad6
+			end
+			if Pad7 and Pad7.active() then
+				return Pad7
+			end
+			if Pad8 and Pad8.active() then
+				return Pad8
+			end
+			if Pad9 and Pad9.active() then
+				return Pad9
+			end
+		end)
+
+		if status then
+			return err
+		else
+			return nil
+		end
+	end
+
+	kmf.update_gamepad_aiming = function()
+		local state = kmf.vars.gamepad_aiming
+
+		if state then
+			local time = os.clock()
+			local dt = time - state.prev_time
+			state.prev_time = time
+
+			if state.move_unit and Unit.alive(state.move_unit) then
+				local current_rot = Unit.local_rotation(state.move_unit, 0)
+				local rot_amount = Quaternion(Vector3.up(), math.degrees_to_radians(90) * dt)
+
+				Unit.set_local_rotation(state.move_unit, 0, Quaternion.multiply(current_rot, rot_amount))
+			end
+			if state.click_unit and Unit.alive(state.click_unit) then
+				local perdiod = time / 2;
+				local scaling = math.abs(perdiod - math.round(perdiod))
+				local scale = 1.9 - scaling * 1.5;
+				local mesh = Unit.mesh(state.click_unit, "g_body")
+				local material = Mesh.material(mesh, 0)
+
+				Material.set_vector3(material, "scale", Vector3(scale, scale, 2))
+			end
+
+			if kmf.frame_camera and state.raycaster then
+				local x, y = state.sreen_pos.x, state.sreen_pos.y
+
+				local pos_1 = Camera.screen_to_world(kmf.frame_camera.camera, Vector3(x, 0 , y))
+				local pos_2 = Camera.screen_to_world(kmf.frame_camera.camera, Vector3(x, 1 , y))
+				local dir = Vector3.normalize(pos_2 - pos_1)
+
+				state.raycaster:cast(pos_1, dir, 100)
+			end
+
+			if kmf.world_proxy and kmf.check_mod_hotkey_status("gamepad aiming") then
+				local pad = kmf.find_active_gamepad()
+				if pad then
+					local axis_state = pad.axis(Pad1.axis_index("right"), Pad1.RAW, 3)
+
+
+					local pecent_change = 3 * dt
+					local raw_w, raw_h = Application.resolution()
+
+					local w_change = raw_w * pecent_change * Vector3.x(axis_state)
+					w_change = (w_change > 0 and w_change < 1) and 1 or w_change
+					w_change = (w_change < 0 and w_change > -1) and -1 or w_change
+
+					local h_change = raw_h * pecent_change * Vector3.y(axis_state)
+					h_change = (h_change > 0 and h_change < 1) and 1 or h_change
+					h_change = (h_change < 0 and h_change > -1) and -1 or h_change
+
+					local new_x = state.sreen_pos.x + w_change
+					new_x = new_x > raw_w and raw_w or new_x
+					new_x = new_x < 0 and 0 or new_x
+
+					local new_y = state.sreen_pos.y + h_change
+					new_y = new_y > raw_h and raw_h or new_y
+					new_y = new_y < 0 and 0 or new_y
+
+					state.sreen_pos.x = new_x
+					state.sreen_pos.y = new_y
+				end
+			end
+		end
+	end
+
+	kmf.on_render = function()
+		kmf.frame_camera = nil
+		pcall(function()
+			kmf.frame_camera = WorldManager:camera("players")
+		end)
+
+		kmf.this_frame_beam_query_done = false
+		kmf.this_frame_ice_gatling_query_done = false
+		kmf.vars.bugfix_enabled = kmf.check_mod_enabled("optional bug fixes")
+		kmf.vars.input_queue_enabled = kmf.check_mod_enabled("input queue convenience")
+
+		kmf.task_scheduler.try_run_next_task()
+
+		for _, on_render_func in pairs(kmf.vars.on_render_handlers) do
+			on_render_func()
+		end
+
+		kmf.check_hotbar_disable_change()
+		kmf.check_funprove_change()
+
+		if kmf.vars.movement_convenience.enabled then
+			kmf.render_mov_conv()
+		end
+
+		kmf.update_gamepad_aiming()
+	end
+
+	kmf.try_init_kbd_watcher()
+
+	kmf.pvp_resurrect_all_teams = function()
+		kmf.pvp_resurrect_team("player")
+		kmf.pvp_resurrect_team("evil")
+	end
+
+	kmf.pvp_resurrect_team = function(team)
+		if not kmf.entity_manager then
+			return
+		end
+
+		local players, players_n = kmf.entity_manager:get_entities("player")
+
+		for i = 1, players_n, 1 do
+			if players[i].unit then
+				local unit_faction
+				local unit_faction_ext = EntityAux.extension(players[i].unit, "faction")
+
+				unit_faction = unit_faction_ext and unit_faction_ext.internal.faction or "player"
+
+				if team == unit_faction then
+					kmf.network:send_resurrect(players[i].unit, 0, 1)
+				end
+			end
+		end
+	end
+
+	WorldManager.camera = function (self, viewport_name)
+		if not self.viewports[viewport_name] then
+			return nil
+		end
+
+		return self.viewports[viewport_name]:camera()
+	end
+
+	kmf.const.me_peer = Steam.user_id()
+end
+
+kmf.add_mod_to_manager = function(name, settings, can_host_sync)
+	local config_string = "[" .. name .. "]\n"
+
+	for setting_name, setting_default in pairs(settings or {}) do
+		config_string = config_string .. setting_name .. "=" .. setting_default .. "\n"
+	end
+
+	kmf.const.default_mod_config = (kmf.const.default_mod_config or "") .. config_string
+	kmf.settings[name] = {enabled = false, options = {}}
+
+	if can_host_sync then
+		local sync_mods = kmf.const.sync_mods or {}
+
+		sync_mods[#sync_mods + 1] = name
+		kmf.const.sync_mods = sync_mods
+	end
+end
+
+kmf.update_mod_manager_config = function()
+	local ffi = kmf.mod_settings_manager.ffi
+	local ffi_mod_config_str = ffi.new("char[?]", (#(kmf.const.default_mod_config)) + 1)
+
+	ffi.copy(ffi_mod_config_str, kmf.const.default_mod_config)
+
+	kmf.mod_settings_manager.c_mod_mngr.update_config_file(ffi_mod_config_str)
+	kmf.mod_settings_manager.counter = 0
+end
+
+
+kmf.add_mod_to_manager("become spectator button")
+kmf.add_mod_to_manager("change equipment in-game")
+kmf.add_mod_to_manager("input queue convenience")
+kmf.add_mod_to_manager("optional bug fixes", nil, true)
+kmf.add_mod_to_manager("balance fun-provements", nil, true)
+kmf.add_mod_to_manager("equipment re-balance", nil, true)
+kmf.add_mod_to_manager("experimental balance", nil, true)
+kmf.add_mod_to_manager("remove magick hud", nil, true)
+kmf.add_mod_to_manager("movement convenience", {
+	["keyboard hotkey"] = "alt"
+}, true)
+kmf.add_mod_to_manager("gamepad aiming", {
+	["gamepad hotkey"] = "L2"
+}, true)
+
+
+kmf.update_mod_manager_config()
+
+
+kmf.check_available_kmf_version()
+kmf.kmf_version = 83
+print("kmf loaded, version " .. kmf.kmf_version)
+
+return
