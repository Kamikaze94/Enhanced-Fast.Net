function MenuCallbackHandler:_find_online_games(friends_only)
	friends_only = friends_only or Global.game_settings.search_friends_only
	if self:is_win32() then
		local function f(info)
			print("info in function")
			print(inspect(info))
			managers.network.matchmake:search_lobby_done()
			managers.menu:active_menu().logic:refresh_node(FastNet.fastnetmenu, true, info, friends_only)
		end
		managers.network.matchmake:register_callback("search_lobby", f)
		managers.network.matchmake:set_lobby_return_count(100)
		managers.menu:show_retrieving_servers_dialog()
		managers.network.matchmake:search_lobby(friends_only)
		local usrs_f = function(success, amount)
			print("usrs_f", success, amount)
			if success then
				local stack = managers.menu:active_menu().renderer._node_gui_stack
				local node_gui = stack[#stack]
				if node_gui.set_mini_info then
					node_gui:set_mini_info(managers.localization:text("menu_players_online", {COUNT = amount}))
				end
			end
		end
		Steam:sa_handler():concurrent_users_callback(usrs_f)
		Steam:sa_handler():get_concurrent_users()
	end
	if self:is_ps3() or self:is_ps4() then
		if #PSN:get_world_list() == 0 then
			return
		end
		local function f(info_list)
			print("info_list in function")
			print(inspect(info_list))
			managers.network.matchmake:search_lobby_done()
			managers.menu:active_menu().logic:refresh_node("play_online", true, info_list, friends_only)
		end
		managers.network.matchmake:register_callback("search_lobby", f)
		managers.network.matchmake:start_search_lobbys(friends_only)
	end
end

function MenuSTEAMHostBrowser:refresh_node(node, info, friends_only)
	local new_node = node
	if not info then
		managers.menu:add_back_button(new_node)
		return new_node
	end
	local room_list = info.room_list
	local attribute_list = info.attribute_list
	local dead_list = {}
	for _, item in ipairs(node:items()) do
		if not item:parameters().back and not item:parameters().filter and not item:parameters().pd2_corner then
			dead_list[item:parameters().room_id] = true
		end
	end
	for i, room in ipairs(room_list) do
		local name_str = tostring(room.owner_name)
		local attributes_numbers = attribute_list[i].numbers
		if managers.network.matchmake:is_server_ok(friends_only, room.owner_id, attributes_numbers) then
			dead_list[room.room_id] = nil
			local host_name = name_str
			local level_index, job_index = managers.network.matchmake:_split_attribute_number(attributes_numbers[1], 1000)
			local level_id = tweak_data.levels:get_level_name_from_index(level_index)
			local name_id = level_id and tweak_data.levels[level_id] and tweak_data.levels[level_id].name_id
			local level_name = name_id and managers.localization:text(name_id) or "CONTRACTLESS"
			local job_id = tweak_data.narrative:get_job_name_from_index(math.floor(job_index))
			local job_name = job_id and tweak_data.narrative.jobs[job_id] and managers.localization:text(tweak_data.narrative.jobs[job_id].name_id) or "CONTRACTLESS"
			local job_days = job_id and (tweak_data.narrative.jobs[job_id].job_wrapper and  table.maxn(tweak_data.narrative.jobs[tweak_data.narrative.jobs[job_id].job_wrapper[1]].chain) or table.maxn(tweak_data.narrative.jobs[job_id].chain)) or 1
			local is_pro = job_id and (tweak_data.narrative.jobs[job_id].professional and tweak_data.narrative.jobs[job_id].professional or false) or false
			local difficulties = {
				"easy",
				"normal",
				"hard",
				"very_hard",
				"overkill",
				"apocalypse"
			}
			local difficulty = difficulties[attributes_numbers[2]] or "error"
			local difficulty_num = attributes_numbers[2]
			local state_string_id = tweak_data:index_to_server_state(attributes_numbers[4])
			local state_name = state_string_id and managers.localization:text("menu_lobby_server_state_" .. state_string_id) or "blah"
			--local display_job = job_name .. ((level_name ~= job_name and job_days ~= 1)and " (" .. level_name .. ")" or "") 
			local display_job = job_name .. ((level_name ~= job_name and job_name ~= "CONTRACTLESS" and level_name ~= "CONTRACTLESS") and " (" .. level_name .. ")" or "") 
			local state = attributes_numbers[4]
			local num_plrs = attributes_numbers[5]
			local is_friend = false
			if Steam:logged_on() and Steam:friends() then
				for _, friend in ipairs(Steam:friends()) do
					if friend:id() == room.owner_id then
						is_friend = true
					end
				end
			end
			local item = new_node:item(room.room_id)
            local job_plan = attributes_numbers[10]
			if not item and not (state  ~= 1 and not tweak_data.narrative.jobs[job_id]) then
				local params = {
					name = room.room_id,
					text_id = name_str,
					room_id = room.room_id,
					columns = {
						utf8.to_upper(host_name),
						utf8.to_upper(display_job),
						utf8.to_upper(state_name),
						tostring(num_plrs) .. "/4 ",
                        job_plan == 1 and "" or job_plan == 2 and ""
					},
					pro = is_pro,
					days = job_days,
					level_name = job_id,
					real_level_name = display_job,
					level_id = level_id,
					state_name = state_name,
					difficulty = difficulty,
                    job_plan = job_plan,
					difficulty_num = difficulty_num or 2,
					host_name = host_name,
					state = state,
					num_plrs = num_plrs,
					friend = is_friend,
					callback = "connect_to_lobby",
					localize = "false"
				}
				local new_item = new_node:create_item({ type = "ItemServerColumn" }, params)
				new_node:add_item(new_item)
				
			elseif not (state  ~= 1 and not tweak_data.narrative.jobs[job_id]) then
				if item:parameters().real_level_name ~= display_job then
					item:parameters().columns[2] = utf8.to_upper(display_job)
					item:parameters().level_name = job_id
					item:parameters().level_id = level_id
					item:parameters().real_level_name = display_job
				end
				if item:parameters().state ~= state then
					item:parameters().columns[3] = state_name
					item:parameters().state = state
					item:parameters().state_name = state_name
				end
				if item:parameters().difficulty ~= difficulty then
					item:parameters().difficulty = difficulty
				end
                if item:parameters().job_plan ~= job_plan then
					item:parameters().job_plan = job_plan
				end
				if item:parameters().room_id ~= room.room_id then
					item:parameters().room_id = room.room_id
				end
				if item:parameters().num_plrs ~= num_plrs then
					item:parameters().num_plrs = num_plrs
					item:parameters().columns[4] = tostring(num_plrs) .. "/4 "
				end
				if item:parameters().friend ~= is_friend then
					item:parameters().friend = is_friend
				end
			elseif item then
				new_node:delete_item(room.room_id)
			end
		end
	end
	for name, _ in pairs(dead_list) do
		new_node:delete_item(name)
	end
	managers.menu:add_back_button(new_node)
	return new_node
end

local modify_filter_node_actual = MenuCrimeNetFiltersInitiator.modify_node
local clbk_choice_difficulty_filter = MenuCallbackHandler.choice_difficulty_filter
local server_count = {10, 20, 30, 40, 50, 60, 70}
local difficulties = {"menu_all", "menu_difficulty_normal", "menu_difficulty_hard", "menu_difficulty_very_hard", "menu_difficulty_overkill", "menu_difficulty_apocalypse", "menu_difficulty_hard", "menu_difficulty_very_hard", "menu_difficulty_overkill"}

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
					text_id = managers.localization:text(v) .. (k > 6 and " +" or ""),
					value = k,
					localize = false
				}))
			end
			diff_filter:_show_options(nil)
			local matchmake_filters = managers.network.matchmake:lobby_filters()
			if matchmake_filters and matchmake_filters.difficulty then 
				diff_filter:set_value(matchmake_filters.difficulty.value + (matchmake_filters.difficulty.comparision_type == "equal" and 0 or 4))
			end
		end
	end
	return res
end

function MenuCallbackHandler:choice_difficulty_filter(item)
	local diff_filter = item:value()
	clbk_choice_difficulty_filter(self, item)
	local comp = "equal"
	if diff_filter > 6 then
		comp = "equalto_or_greater_than"
		diff_filter = diff_filter - 4
	elseif diff_filter <= 1 then
		diff_filter = -1
	end
	managers.network.matchmake:add_lobby_filter("difficulty", diff_filter, comp)
end