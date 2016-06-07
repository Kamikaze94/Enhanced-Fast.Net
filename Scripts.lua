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
			FastNet:reconnect()
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
			FastNet:reconnect()    
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
		
	--Persistent Filter Settings
	local init_cbk = NetworkMatchMakingSTEAM.init
	function NetworkMatchMakingSTEAM:init()
		init_cbk(self)
		self:_load_persistent_settings()
	end
	function NetworkMatchMakingSTEAM:save_persistent_settings()
		if not FastNet.settings.save_filter then return end
		local f = "friends_only=" .. tostring(Global.game_settings.search_friends_only or false) .. ", max_lobbies=" .. tostring(self._lobby_return_count) .. ", distance=" .. tostring(self._distance_filter)
		for k, v in pairs(self._lobby_filters) do
			if tostring(k) == "difficulty" then
				f = f .. ", " .. (tostring(k) .. "=" .. tostring(self._lobby_filters[k].value + (self._lobby_filters[k].comparision_type == "equal" and 0 or 4)))
			else
				f = f .. ", " .. (tostring(k) .. "=" .. tostring(self._lobby_filters[k].value))
			end
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
					local friends_only = FastNet.settings.show_friends_menu and false or val  == "true" and true or false
					Global.game_settings.search_friends_only = friends_only
					self._search_friends_only = friends_only
				elseif key == "appropriate_jobs" then
					local appropriate_jobs = val  == "true" and true or false
					Global.game_settings.search_appropriate_jobs = appropriate_jobs
					self._search_appropriate_jobs = appropriate_jobs
				elseif key == "max_lobbies" then
					self:set_lobby_return_count(tonumber(val))
				elseif key == "distance" then
					self:set_distance_filter(tonumber(val))
				elseif key == "difficulty" then
					local comp = "equal"
					if tonumber(val) > 6 then
						comp = "equalto_or_greater_than"
						val = tonumber(val) - 4
					end
					self:add_lobby_filter(key, tonumber(val), comp)
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
elseif string.lower(RequiredScript) == "lib/network/base/hostnetworksession" then
	local chk_server_joinable_state_actual = HostNetworkSession.chk_server_joinable_state
	function HostNetworkSession:chk_server_joinable_state(...)
		chk_server_joinable_state_actual(self, ...)

		if Global.load_start_menu_lobby and MenuCallbackHandler ~= nil then
			MenuCallbackHandler:update_matchmake_attributes()
			MenuCallbackHandler:_on_host_setting_updated()
		end
	end
end