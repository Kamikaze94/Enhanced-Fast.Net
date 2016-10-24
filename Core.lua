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
end

FastNet.hook_files = {
	["lib/managers/menu/renderers/menunodetablegui"] = "lua/FastNet.lua",
	["lib/managers/menu/nodes/menunodeserverlist"] = "lua/FastNet.lua",
	["lib/managers/menu/menunodegui"] = "lua/FastNet.lua",
	["lib/managers/menumanager"] = "lua/FastNet.lua",
	["lib/network/matchmaking/networkmatchmakingsteam"] = { "lua/Reconnect.lua", "lua/FastNet.lua" },
	["lib/managers/menu/menucomponentmanager"] = "lua/Reconnect.lua",
	["lib/network/base/hostnetworksession"] = "lua/Reconnect.lua",
	["lib/managers/crimenetmanager"] = "lua/Reconnect.lua",
	["lib/managers/menu/crimenetfiltersgui"] = "lua/Reconnect.lua",
}

if not FastNet.setup then	
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
	FastNet.setup = true
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
	 
	Hooks:Add("MenuManagerBuildCustomMenus", "Base_BuildFastNetMenu", function( menu_manager, nodes )
		local key = LuaModManager:GetPlayerKeybind("Reconnect_key") or "f1"
		MenuHelper:AddKeybinding({
			id = "Reconnect_key",
			title = "Reconnect Key",
			connection_name = "Reconnect_key",
			button = key,
			binding = key,
			menu_id = FastNet.keybinds_menu,
			localized = false,
		})
		
		local filter_node = nodes["crimenet_filters"]
		if filter_node then	
			
		end
		
		local arugements = {
			_meta = "node",
		    --align_line = 0.5,
		    back_callback = "stop_multiplayer",
		    gui_class = "MenuNodeTableGui",
		    menu_components = "",
		    modifier = "MenuSTEAMHostBrowser",
		    name = FastNet.fastnetmenu,
		    refresh = "MenuSTEAMHostBrowser",
		    stencil_align = "right",
		    stencil_image = "bg_creategame",
		    topic_id = "menu_play_online",
		    type = "MenuNodeServerList",
		    update = "MenuSTEAMHostBrowser",
			scene_state = "standard"
		}
		local type = "MenuNodeServerList"
		if type then
			node_class = CoreSerialize.string_to_classtable(type)
		end
		nodes[FastNet.fastnetmenu] = node_class:new(arugements)
		
		local callback_handler = CoreSerialize.string_to_classtable("MenuCallbackHandler")
		nodes[FastNet.fastnetmenu]:set_callback_handler(callback_handler:new())

		if nodes.main then
			local parent_menu = nodes.main
			local menu_position = 1
			for k, v in pairs( parent_menu._items ) do
				if "crimenet" == v["_parameters"]["name"] then
					menu_position = k + 1
					break
				end
			end
			
			local data = {
				type = "CoreMenuItem.Item",
			}
			
			if FastNet.settings.show_friends_menu then
				local params = {
					name = "fast_net_friends",
					text_id = "fast_net_friends_title",
					--help_id = "fast_net_help",
					callback = "find_online_games_with_friends",
					next_node = FastNet.fastnetmenu,
				}
				local new_item = parent_menu:create_item(data, params)
				parent_menu:add_item(new_item)
				local element = table.remove(parent_menu._items, table.maxn(parent_menu._items))
				table.insert( parent_menu._items, menu_position, element )
			end
			
			local params = {
				name = "fast_net",
				text_id = "fast_net_title",
				--help_id = "fast_net_help",
				callback = "find_online_games",
				next_node = FastNet.fastnetmenu,
			}
			local new_item = parent_menu:create_item(data, params)
			parent_menu:add_item(new_item)
			local element = table.remove(parent_menu._items, table.maxn(parent_menu._items))
			table.insert( parent_menu._items, menu_position, element )
		end
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
