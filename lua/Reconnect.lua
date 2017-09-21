local requiredScript = string.lower(RequiredScript)

if requiredScript == "lib/managers/menumanager" then
	Hooks:Add("MenuManagerBuildCustomMenus", "FastNet_MenuManager_AddReconnectKeybind", function( menu_manager, nodes )
		local key = BLT.Keybinds:get_keybind("Reconnect_key") or "f1"
		MenuHelper:AddKeybinding({
			id = "Reconnect_key",
			title = "Reconnect Key",
			connection_name = "Reconnect_key",
			button = key,
			binding = key,
			menu_id = FastNet.keybinds_menu,
			localized = false,
		})
	end)
elseif requiredScript == "lib/managers/crimenetmanager" then

	Hooks:PostHook(CrimeNetGui, "init", "FastNet_CrimeNetGui_init", function(self, ws, fullscreeen_ws, node)
			if not FastNet.settings.show_reconnect or node:parameters().no_servers then return end
			key = BLT.Keybinds:get_keybind("Reconnect_key") or "f1"
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
		key = BLT.Keybinds:get_keybind("Reconnect_key") or "f1"
		if k == Idstring(key) and self._panel:child("reconnect_button") then
			FastNet:reconnect()
		end
	end
	Hooks:PostHook(CrimeNetGui, "mouse_moved", "FastNet_CrimeNetGui_mouse_move", function(self, o, x, y)
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

	Hooks:PostHook(CrimeNetGui, "mouse_pressed", "FastNet_CrimeNetGui_mouse_pressed", function(self, o, button, x, y)
		if self._panel:child("reconnect_button") and self._panel:child("reconnect_button"):inside(x, y) then
			FastNet:reconnect()    
			return
		end
	end)
elseif requiredScript == "lib/managers/menu/crimenetfiltersgui" then
	local filter_close_cbk = CrimeNetFiltersGui.close

	function CrimeNetFiltersGui:close()
		filter_close_cbk(self)
		managers.network.matchmake:search_lobby(Global.game_settings.search_friends_only)
	end
elseif requiredScript == "lib/network/matchmaking/networkmatchmakingsteam" then
	function NetworkMatchMakingSTEAM:join_server_with_check(room_id, is_invite)
		managers.menu:show_joining_lobby_dialog()
		local lobby = Steam:lobby(room_id)
		local empty = function()
		end
		local function f()
			print("NetworkMatchMakingSTEAM:join_server_with_check f")
			lobby:setup_callback(empty)
			local attributes = { numbers = self:_lobby_to_numbers(lobby), mutators = nil }
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
				FastNet.settings.last_lobby_id = room_id
				FastNet:Save()
				log("[FastNet] Saving(Room ID = "..room_id..")")
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
elseif requiredScript == "lib/managers/menu/menucomponentmanager" then
	function MenuComponentManager:crimenet_enabled()
		if self._crimenet_gui then
			return self._crimenet_gui:enabled()
		else
			return true
		end
	end
elseif requiredScript == "lib/network/base/hostnetworksession" then
	local chk_server_joinable_state_actual = HostNetworkSession.chk_server_joinable_state
	function HostNetworkSession:chk_server_joinable_state(...)
		chk_server_joinable_state_actual(self, ...)

		if Global.load_start_menu_lobby and MenuCallbackHandler ~= nil then
			MenuCallbackHandler:update_matchmake_attributes()
			MenuCallbackHandler:_on_host_setting_updated()
		end
	end
end