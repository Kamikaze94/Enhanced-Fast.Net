if not _G.FastNet then
	_G.FastNet = {}
	FastNet.mod_path = ModPath
	FastNet.save_path = SavePath .. "FastNet.txt"
	FastNet.fastnetmenu = "play_STEAM_online"
	FastNet.keybinds_menu = "base_keybinds_menu"
	FastNet.settings = {
		save_filter = true,
		filter = "",
		show_reconnect = true,
		last_lobby_id = nil
	}
end

FastNet.hook_files = {
	["lib/managers/menu/renderers/menunodetablegui"] = "FastNetLua/MenuNodeTableGui.lua",
	["lib/managers/menu/nodes/menunodeserverlist"] = "FastNetLua/MenuNodeServerList.lua",
	["lib/managers/menu/menunodegui"] = "FastNetLua/MenuNodeGui.lua",
	["lib/managers/menumanager"] = "FastNetLua/MenuManager.lua",
	["lib/network/matchmaking/networkmatchmakingsteam"] = "Scripts.lua",
	["lib/managers/menu/crimenetfiltersgui"] = "Scripts.lua",
	["lib/managers/menu/menucomponentmanager"] = "Scripts.lua",
	["lib/network/base/hostnetworksession"] = "Scripts.lua",
	["lib/managers/crimenetmanager"] = "Scripts.lua"
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
	if FastNet.hook_files[requiredScript] then
		dofile( ModPath .. FastNet.hook_files[requiredScript] )
	end
end


if Hooks then
	Hooks:Add("LocalizationManagerPostInit", "FastNet_Localization", function(loc)
		loc:add_localized_strings({
			["fast_net_title"] = "Fast.net",
			["fast_net_help"] = "Log into Fast.net and join others faster than light.",
			["menu_button_reconnect"] = "Reconnect",
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
			local params = {
				name = "fast_net",
				text_id = "fast_net_title",
				help_id = "fast_net_help",
				callback = "find_online_games",
				next_node = FastNet.fastnetmenu,
			}
			local new_item = parent_menu:create_item(data, params)
			parent_menu:add_item(new_item)
			local element = table.remove(parent_menu._items, table.maxn(parent_menu._items))
			table.insert( parent_menu._items, menu_position, element )
		end
	end)
end
