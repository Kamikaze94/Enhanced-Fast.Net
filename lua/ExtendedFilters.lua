local requiredScript = string.lower(RequiredScript)

local function apply_lobby_filter(diff_filter)
	if diff_filter > 8 then
		managers.network.matchmake:add_lobby_filter("difficulty", diff_filter - 6, "equalto_or_greater_than")
	end
end

local function fix_preset_difficulties(presets)
	for _, preset in pairs(presets or {}) do
		if preset.difficulty_id > 8 then
			local min_difficulty = preset.difficulty_id - 6
			preset.difficulty_id = math.round(min_difficulty + math.rand(8 - min_difficulty))
			preset.difficulty = tweak_data:index_to_difficulty(preset.difficulty_id)
		end
	end
end

if requiredScript == "lib/managers/menumanager" then

	local modify_filter_node_actual = MenuCrimeNetFiltersInitiator.modify_node
	local choice_difficulty_filter_original = MenuCallbackHandler.choice_difficulty_filter

	local server_count = {10, 20, 30, 40, 50, 60, 70}
	local difficulties = {"menu_any", "menu_difficulty_normal", "menu_difficulty_hard", "menu_difficulty_very_hard", "menu_difficulty_overkill", "menu_difficulty_easy_wish", "menu_difficulty_apocalypse", "menu_difficulty_sm_wish", "menu_difficulty_hard", "menu_difficulty_very_hard", "menu_difficulty_overkill", "menu_difficulty_easy_wish", "menu_difficulty_apocalypse"}

	function MenuCrimeNetFiltersInitiator:modify_node(original_node, ...)
		local res = modify_filter_node_actual(self, original_node, ...)
		if server_count ~= nil then
			local max_lobbies = original_node:item("max_lobbies_filter")
			if max_lobbies ~= nil then
				max_lobbies:clear_options()
				for __, count in ipairs(server_count) do
					max_lobbies:add_option(CoreMenuItemOption.ItemOption:new({
						_meta = "option",
						text_id = tostring(count),
						value = count,
						localize = false
					}))
				end
				max_lobbies:_show_options(nil)
			end
		end

		if difficulties ~= nil then
			local diff_filter = original_node:item("difficulty_filter")
			if diff_filter ~= nil then
				diff_filter:clear_options()
				for k, v in ipairs(difficulties) do
					diff_filter:add_option(CoreMenuItemOption.ItemOption:new({
						_meta = "option",
						text_id = managers.localization:text(v) .. (k > 8 and " +" or ""),
						value = k == 1 and -1 or k,
						localize = false
					}))
				end
				diff_filter:_show_options(nil)
				local matchmake_filters = managers.network.matchmake:lobby_filters()
				if matchmake_filters and matchmake_filters.difficulty then
					diff_filter:set_value(matchmake_filters.difficulty.value + (matchmake_filters.difficulty.comparision_type == "equal" and 0 or 6))
				end
			end
		end

		return res
	end

	function MenuCallbackHandler:choice_difficulty_filter(item, ...)
		choice_difficulty_filter_original(self, item, ...)
		apply_lobby_filter(item:value())
	end

elseif requiredScript == "lib/network/matchmaking/networkmatchmakingsteam" then

	local load_user_filters_original = NetworkMatchMakingSTEAM.load_user_filters

	function NetworkMatchMakingSTEAM:load_user_filters(...)
		load_user_filters_original(self, ...)
		apply_lobby_filter(managers.user:get_setting("crimenet_filter_difficulty"))
	end

elseif requiredScript == "lib/managers/crimenetmanager" then

	local _setup_original = CrimeNetManager._setup
	local update_difficulty_filter_original = CrimeNetManager.update_difficulty_filter

	function CrimeNetManager:_setup(...)
		_setup_original(self, ...)
		fix_preset_difficulties(self._presets)
	end

	function CrimeNetManager:update_difficulty_filter(...)
		update_difficulty_filter_original(self, ...)
		fix_preset_difficulties(self._presets)
	end

end