if not _G.FastNet then
	_G.FastNet = {}
	FastNet.mod_path = ModPath
	FastNet.save_path = SavePath .. "FastNet.txt"
	FastNet.fastnetmenu = "play_STEAM_online"
	FastNet.keybinds_menu = "base_keybinds_menu"
	FastNet.settings = {
		show_friends_menu 	= true,		--Show seperate FastNet Friends Menu
		show_reconnect 		= true,		--Show reconnect Button
		last_lobby_id = nil
	}

	FastNet.hook_files = {
		["lib/managers/menu/renderers/menunodetablegui"] = "lua/FastNet.lua",
		["lib/managers/menu/nodes/menunodeserverlist"] = "lua/FastNet.lua",
		["lib/managers/menu/menunodegui"] = "lua/FastNet.lua",
		["lib/managers/menumanager"] = { "lua/FastNet.lua", "lua/ExtendedFilters.lua" },
		["lib/network/matchmaking/networkmatchmakingsteam"] = { "lua/Reconnect.lua", "lua/ExtendedFilters.lua" },
		["lib/managers/menu/menucomponentmanager"] = "lua/Reconnect.lua",
		["lib/network/base/hostnetworksession"] = "lua/Reconnect.lua",
		["lib/managers/crimenetmanager"] = { "lua/Reconnect.lua", "lua/ExtendedFilters.lua" },
		["lib/managers/menu/crimenetfiltersgui"] = "lua/Reconnect.lua",
	}
	
	function FastNet:Load()
		local file = io.open(self.save_path, "r")
		if file then
			for k, v in pairs(json.decode(file:read("*all"))) do
				self.settings[k] = v
			end
			file:close()
		end
	end

	function FastNet:Save()
		local file = io.open(self.save_path, "w+")
		if file then
			file:write(json.encode(self.settings))
			file:close()
		end
	end
	
	function FastNet:reconnect()
		FastNet:Load()
		local lobby_id = FastNet.settings.last_lobby_id or nil
		if lobby_id then
			managers.network.matchmake:join_server(lobby_id)
		else
			managers.menu:show_failed_joining_dialog()
		end
	end
	
	FastNet:Load()
end

if RequiredScript then
	local requiredScript = RequiredScript:lower()
	local hook_files = FastNet.hook_files[requiredScript]
	if type(hook_files) == "string" then
		hook_files = { hook_files }
	end
	for i, file in ipairs(hook_files) do
		dofile( FastNet.mod_path .. file )
	end
end


if Hooks then
	Hooks:Add("LocalizationManagerPostInit", "FastNet_Localization", function(loc)
		local loc_path = FastNet.mod_path .. "loc/"
		if file.DirectoryExists( loc_path ) then
			local custom_lang
			if _G.PD2KR then
				custom_lang = "korean"
			else
				for _, mod in pairs(BLT and BLT.Mods:Mods() or {}) do
					if mod:GetName() == "ChnMod (Patch)" and mod:IsEnabled() then
						custom_lang = "chinese"
						break
					end
				end
			end
			if custom_lang then
				loc:load_localization_file(string.format("%s%s.json", loc_path, custom_lang))
			else
				for _, filename in pairs(file.GetFiles(loc_path)) do
					local str = filename:match('^(.*).json$')
					if str and Idstring(str) and Idstring(str):key() == SystemInfo:language():key() then
						loc:load_localization_file(loc_path .. filename)
						break
					end
				end
			end
			loc:load_localization_file(loc_path .. "english.json", false)
		else
			log("[Fast.NET] Error: Localization folder seems to be missing!")
		end
	end)
	 
	Hooks:Add("MenuManagerSetupCustomMenus", "FastNetSetupMenu", function( menu_manager, nodes )
		MenuHelper:NewMenu( FastNet.fastnetmenu )
		MenuHelper:NewMenu( FastNet.keybinds_menu )
	end)
	
	Hooks:Add("MenuManagerInitialize", "MenuManagerInitialize_FastNet", function(menu_manager)
		MenuCallbackHandler.FastNet_Save = function(self, item)
			FastNet:Save()
		end
		
		MenuCallbackHandler.clbk_change_fastnet_setting = function(self, item)
			local value
			if item._type == "toggle" then
				value = (item:value() == "on")
			else
				value = item:value()
			end
			local name = item:parameters().name
			if name then
				FastNet.settings[name] = value
			end
		end
		
		MenuHelper:LoadFromJsonFile(FastNet.mod_path .. "settings.json", FastNet, FastNet.settings)
	end)
end
