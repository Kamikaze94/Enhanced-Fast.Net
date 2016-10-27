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
		["lib/managers/crimenetmanager"] = "lua/Reconnect.lua",
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
		dofile( ModPath .. file )
	end
end


if Hooks then
	Hooks:Add("LocalizationManagerPostInit", "FastNet_Localization", function(loc)
		loc:add_localized_strings({
			["fast_net_title"] = "Fast.net",
			["fast_net_help"] = "Log into Fast.net and join others faster than light.",
			["fast_net_friends_title"] = "Fast.net Friends",
			["menu_button_reconnect"] = "Reconnect",
			["fastnet_settings_name"] = "Fast.net Settings",
			["fastnet_settings_help"] = "Configuration of Fast.net",
			["fastnet_friends_menu_title"] = "Show 'Fast.net Friends'",
			["fastnet_friends_menu_desc"] = "Show seperate 'Fast.net Friends' menu.",
			["fastnet_save_filter_title"] = "Save Filters",
			["fastnet_save_filter_desc"] = "Save your filter settings and restore them the next time.",
			["fastnet_show_reconnect_title"] = "Show Reconnect",
			["fastnet_show_reconnect_desc"] = "Show a reconnect button in Crime.net and Fast.net",
		})
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
