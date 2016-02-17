_G.Reconnect = _G.Reconnect or {}
local lobby_id = nil
local C = LuaModManager.Constants
LuaModManager.Constants._keybinds_menu_id = "base_keybinds_menu"
local keybinds_menu_id = C._keybinds_menu_id
function Reconnect:Save()
	FastNet.settings.last_lobby_id = lobby_id
	FastNet:Save()
end

function Reconnect:Load()
	FastNet:Load()
	lobby_id = FastNet.settings.last_lobby_id or nil
end

function Reconnect:reconnect()
	Reconnect:Load()
	if lobby_id then
		managers.network.matchmake:join_server(lobby_id)
	else
		managers.menu:show_failed_joining_dialog()
	end
end

Reconnect:Load()
Hooks:Add("MenuManager_Base_SetupModOptionsMenu", "ReconnectOptions", function( menu_manager, nodes )
		MenuHelper:NewMenu( keybinds_menu_id )
end)
Hooks:Add("MenuManager_Base_PopulateModOptionsMenu", "ReconnectOptions", function( menu_manager, nodes )
		local key = LuaModManager:GetPlayerKeybind("Reconnect_key") or "f1"
		MenuHelper:AddKeybinding({
			id = "Reconnect_key",
			title = "Reconnect key",
			connection_name = "Reconnect_key",
			button = key,
			binding = key,
			menu_id = keybinds_menu_id,
			localized = false,
		})
end)

if RequiredScript == "lib/managers/crimenetmanager" then

	Hooks:PostHook(CrimeNetGui, "init", "reinit", function(self, ws, fullscreeen_ws, node)
			if not FastNet.settings.show_reconnect or node:parameters().no_servers then return end
			key = LuaModManager:GetPlayerKeybind("Reconnect_key") or "f1"
			local reconnect_button = self._panel:text({
				name = "reconnect_button",
				text = string.upper("["..key.."] "..managers.localization:text("menu_button_reconnect")),
				font_size = tweak_data.menu.pd2_small_font_size,
				font = tweak_data.menu.pd2_small_font,
				color = tweak_data.screen_colors.button_stage_3,
				layer = 40,
				blend_mode = "add"
			})
			self:make_fine_text(reconnect_button)
			reconnect_button:set_right(self._panel:w() - 10)
			reconnect_button:set_top(40)
			self._fullscreen_ws:connect_keyboard(Input:keyboard())  
			self._fullscreen_panel:key_press(callback(self, self, "key_press"))    
	end)

	function CrimeNetGui:key_press(o, k)
		key = LuaModManager:GetPlayerKeybind("Reconnect_key") or "f1"
		if k == Idstring(key) and self._panel:child("reconnect_button") then
			Reconnect:reconnect()
		end
	end
	Hooks:PostHook(CrimeNetGui, "mouse_moved", "mouse_move", function(self, o, x, y)
		if self._panel:child("reconnect_button") then
			if self._panel:child("reconnect_button"):inside(x, y) then
				if not self._reconnect_highlighted then
					self._reconnect_highlighted = true
					self._panel:child("reconnect_button"):set_color(tweak_data.screen_colors.button_stage_2)
					managers.menu_component:post_event("highlight")
				end
			elseif self._reconnect_highlighted then
				self._reconnect_highlighted = false
				self._panel:child("reconnect_button"):set_color(tweak_data.screen_colors.button_stage_3)
			end
		end
	end)

	Hooks:PostHook(CrimeNetGui, "mouse_pressed", "mouse_presse", function(self, o, button, x, y)
		if self._panel:child("reconnect_button") and self._panel:child("reconnect_button"):inside(x, y) then
			Reconnect:reconnect()    
			return
		end
	end)
elseif string.lower(RequiredScript) == "lib/managers/menu/crimenetfiltersgui" then
	local filter_close_cbk = CrimeNetFiltersGui.close
	function CrimeNetFiltersGui:close()
		filter_close_cbk(self)
		managers.network.matchmake:save_persistent_settings()
		managers.network.matchmake:search_lobby(Global.game_settings.search_friends_only)
	end
elseif RequiredScript == "lib/network/matchmaking/networkmatchmakingsteam" then
	function NetworkMatchMakingSTEAM:join_server_with_check(room_id, is_invite)
		managers.menu:show_joining_lobby_dialog()
		local lobby = Steam:lobby(room_id)
		local empty = function()
		end
		local function f()
			print("NetworkMatchMakingSTEAM:join_server_with_check f")
			lobby:setup_callback(empty)
			local attributes = self:_lobby_to_numbers(lobby)
			if NetworkMatchMakingSTEAM._BUILD_SEARCH_INTEREST_KEY then
				local ikey = lobby:key_value(NetworkMatchMakingSTEAM._BUILD_SEARCH_INTEREST_KEY)
				if ikey == "value_missing" or ikey == "value_pending" then
					print("Wrong version!!")
					managers.system_menu:close("join_server")
					managers.menu:show_failed_joining_dialog()
					return
				end
			end
			print(inspect(attributes))
			local server_ok, ok_error = self:is_server_ok(nil, room_id, attributes, is_invite)
			if server_ok then
				self:join_server(room_id, true)
				lobby_id = room_id
				Reconnect:Save()
				log("Saving(Room ID = "..lobby_id..")")
			else
				managers.system_menu:close("join_server")
				if ok_error == 1 then
					managers.menu:show_game_started_dialog()
				elseif ok_error == 2 then
					managers.menu:show_game_permission_changed_dialog()
				elseif ok_error == 3 then
					managers.menu:show_too_low_level()
				elseif ok_error == 4 then
					managers.menu:show_does_not_own_heist()
				end
				self:search_lobby(self:search_friends_only())
			end
		end
		lobby:setup_callback(f)
		if lobby:key_value("state") == "value_pending" then
			print("NetworkMatchMakingSTEAM:join_server_with_check value_pending")
			lobby:request_data()
		else
			f()
		end
	end
		
	--Persistent Filter Settings
	local init_cbk = NetworkMatchMakingSTEAM.init
	function NetworkMatchMakingSTEAM:init()
		init_cbk(self)
		self:_load_persistent_settings()
	end
	function NetworkMatchMakingSTEAM:save_persistent_settings()
		if not FastNet.settings.save_filter then return end
		local f = "friends_only=" .. tostring(self._search_friends_only or false) .. ", max_lobbies=" .. tostring(self._lobby_return_count) .. ", distance=" .. tostring(self._distance_filter)
		for k, v in pairs(self._lobby_filters) do
			f = f .. ", " .. (tostring(k) .. "=" .. tostring(self._lobby_filters[k].value))
		end
		FastNet.settings.filter = f
		FastNet:Save()
		--managers.network.matchmake:search_lobby(managers.network.matchmake:search_friends_only())
	end

	function NetworkMatchMakingSTEAM:_load_persistent_settings()
		if not FastNet.settings.save_filter then return end
		FastNet:Load()
		s = FastNet.settings.filter or ""
		for key, val in string.gmatch(s, "([%w_]+)=([%w_]+)") do
			if key and val then
				if key == "friends_only" then
					local friends_only = val  == "true" and true or false
					Global.game_settings.search_friends_only = friends_only
					self._search_friends_only = friends_only
				elseif key == "max_lobbies" then
					self:set_lobby_return_count(tonumber(val))
				elseif key == "distance" then
					self:set_distance_filter(tonumber(val))
				else
					self:add_lobby_filter(key, tonumber(val), "equal")
				end
			end
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/menucomponentmanager" then
	function MenuComponentManager:crimenet_enabled()
		if self._crimenet_gui then
			return self._crimenet_gui:enabled()
		else
			return true
		end
	end
end
--[[if string.lower(RequiredScript) == "lib/managers/menumanager" then
	local crimenetfilters_addfilter = MenuSTEAMHostBrowser.add_filter
	function MenuSTEAMHostBrowser:add_filter(node)
		crimenetfilters_addfilter(self, node)
		
		local params = {
			name = "difficulty_filter",
			text_id = "menu_diff_filter",
			help_id = "menu_diff_filter_help",
			visible_callback = "is_pc_controller",
			callback = "choice_difficulty_filter",
			filter = true
		}
		local data_node = {
			type = "MenuItemMultiChoice",
			{
				_meta = "option",
				text_id = "menu_all",
				value = 0
			},
			{
				_meta = "option",
				text_id = "menu_difficulty_easy",
				value = 1
			},
			{
				_meta = "option",
				text_id = "menu_difficulty_normal",
				value = 2
			},
			{
				_meta = "option",
				text_id = "menu_difficulty_hard",
				value = 3
			},
			{
				_meta = "option",
				text_id = "menu_difficulty_overkill",
				value = 4
			}
		}
		if managers.experience:current_level() >= 145 then
			table.insert(data_node, {
				_meta = "option",
				text_id = "menu_difficulty_overkill_145",
				value = 5
			})
		end
		table.insert(data_node, 
			{
				_meta = "option",
				text_id = "menu_difficulty_easy_plus",
				value = 1
			},
			{
				_meta = "option",
				text_id = "menu_difficulty_normal_plus",
				value = 2
			},
			{
				_meta = "option",
				text_id = "menu_difficulty_hard_plus",
				value = 3
			},
			{
				_meta = "option",
				text_id = "menu_difficulty_overkill_plus",
				value = 4
			}
		)
		local new_item = node:create_item(data_node, params)
		new_item:set_value(managers.network.matchmake:difficulty_filter())
		node:item("difficulty_filter") = new_item
	end

	local clbk_choice_difficulty_filter = MenuCallbackHandler.choice_difficulty_filter
	function MenuCallbackHandler:choice_difficulty_filter(item)
		local diff_filter = item:value()
		clbk_choice_difficulty_filter(self, item)
		if item:value() > 5 then
			managers.network.matchmake:add_lobby_filter("difficulty", diff_filter % 5, "equal"to_or_greater_than)
		else
			managers.network.matchmake:add_lobby_filter("difficulty", diff_filter, "equal")
		end
	end
end]]