local requiredScript = string.lower(RequiredScript)

if requiredScript == "lib/managers/menumanager" then
	
	Hooks:Add("MenuManagerBuildCustomMenus", "FastNet_MenuManager_BuildFastNetMenu", function( menu_manager, nodes )		
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

		node_class = CoreSerialize.string_to_classtable(arugements.type)
		if node_class then
			nodes[FastNet.fastnetmenu] = node_class:new(arugements)

			local callback_handler = CoreSerialize.string_to_classtable("MenuCallbackHandler")
			if callback_handler then
				nodes[FastNet.fastnetmenu]:set_callback_handler(callback_handler:new())
			end
		end

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
					help_id = "fast_net_help",
					callback = "play_online_game find_online_games_with_friends",
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
				help_id = "fast_net_help",
				callback = "play_online_game find_online_games",
				next_node = FastNet.fastnetmenu,
			}
			local new_item = parent_menu:create_item(data, params)
			parent_menu:add_item(new_item)
			local element = table.remove(parent_menu._items, table.maxn(parent_menu._items))
			table.insert( parent_menu._items, menu_position, element )
		end
	end)

	function MenuCallbackHandler:_find_online_games(friends_only)
		friends_only = friends_only or not FastNet.settings.show_friends_menu and Global.game_settings.search_friends_only
		if self:is_win32() then
			local function f(info)
				print("info in function")
				print(inspect(info))
				managers.network.matchmake:search_lobby_done()
				managers.menu:active_menu().logic:refresh_node(FastNet.fastnetmenu, true, info, friends_only)
			end
			managers.network.matchmake:register_callback("search_lobby", f)
			managers.menu:show_retrieving_servers_dialog()
			managers.network.matchmake:search_lobby(friends_only)
			local usrs_f = function(success, amount)
				print("usrs_f", success, amount)
				if success then
					local stack = managers.menu:active_menu().renderer._node_gui_stack
					local node_gui = stack[#stack]
					local is_FastNet = (managers.menu:active_menu().logic:selected_node():parameters().name == FastNet.fastnetmenu)
					if is_FastNet and node_gui.set_mini_info then
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

	function MenuCallbackHandler:setup_join_cs_manager(item, ...)
		local params = item:parameters()
		if params.is_crime_spree then
			managers.crime_spree:join_server(params)
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
		
		local friends_list = Steam:logged_on() and Steam:friends() or {}
		for i, room in ipairs(room_list) do
			if managers.network.matchmake:is_server_ok(friends_only, room.owner_id, attribute_list[i], nil) then
				local host_name = tostring(room.owner_name) --.. " [" .. (room.owner_level or "N/A") .. "]" -- Infamy isn't given here...
				local attributes_numbers = attribute_list[i].numbers
				local attributes_mutators = attribute_list[i].mutators
				if attributes_numbers then
					dead_list[room.room_id] = nil
					local level_index, job_index = managers.network.matchmake:_split_attribute_number(attributes_numbers[1], 1000)
					local level_id = tweak_data.levels:get_level_name_from_index(level_index)
					local name_id = level_id and tweak_data.levels[level_id] and tweak_data.levels[level_id].name_id
					local level_name = name_id and managers.localization:text(name_id) or "CONTRACTLESS"
					local job_id = tweak_data.narrative:get_job_name_from_index(math.floor(job_index))
					local job_name = job_id and tweak_data.narrative.jobs[job_id] and managers.localization:text(tweak_data.narrative.jobs[job_id].name_id) or "CONTRACTLESS"
					local job_days = job_id and (tweak_data.narrative.jobs[job_id].job_wrapper and  table.maxn(tweak_data.narrative.jobs[tweak_data.narrative.jobs[job_id].job_wrapper[1]].chain) or table.maxn(tweak_data.narrative.jobs[job_id].chain)) or 1
					local is_pro = job_id and (tweak_data.narrative.jobs[job_id].professional and tweak_data.narrative.jobs[job_id].professional or false) or false
					local difficulty_num = attributes_numbers[2]
					local difficulty = tweak_data:index_to_difficulty(difficulty_num) or "error"
					local is_one_down = (tonumber(attribute_list[i].one_down) or 0) == 1
					local state_string_id = tweak_data:index_to_server_state(attributes_numbers[4])
					local state_name = state_string_id and managers.localization:text("menu_lobby_server_state_" .. state_string_id) or "UNKNOWN"
					local display_job = job_name .. ((job_name ~= level_name and job_name ~= "CONTRACTLESS" and level_name ~= "CONTRACTLESS" and job_days > 1) and " (" .. level_name .. ")" or "") 
					local state = attributes_numbers[4]
					local num_plrs = attributes_numbers[5]
					local kick_option = attributes_numbers[8]
					local kick_suffix = {[1] = "server", [2] = "vote", [0] = "disabled"}
					local kick_option_name = "menu_kick_" .. (kick_suffix[kick_option] or "error")
					local job_plan = attributes_numbers[10]
					local job_plan_suffix = {"plan_loud", "plan_stealth"}
					local job_plan_name = "menu_" .. (job_plan_suffix[job_plan] or "any")
					local attribute_crimespree = attribute_list[i].crime_spree
					local is_crime_spree = attribute_crimespree and 0 <= attribute_crimespree
					local crime_spree_mission = attribute_list[i].crime_spree_mission
					local crime_spree_mission_name = "CONTRACTLESS"
					if crime_spree_mission then
						local mission_data = managers.crime_spree:get_mission(crime_spree_mission)
						if mission_data then
							local tweak = tweak_data.levels[mission_data.level.level_id]
							crime_spree_mission_name = managers.localization:text(tweak and tweak.name_id or "UNKNOWN")
						end
					end
					local is_friend = false
					for _, friend in ipairs(friends_list) do
						if friend:id() == room.owner_id then
							is_friend = true
						end
					end
					local item = new_node:item(room.room_id)
					if not item and not (state  ~= 1 and not tweak_data.narrative.jobs[job_id]) then
						local params = {
							name = room.room_id,
							text_id = name_str,
							room_id = room.room_id,
							owner_id = room.owner_id,
							columns = {
								utf8.to_upper(host_name),
								utf8.to_upper(is_crime_spree and crime_spree_mission_name or display_job),
								utf8.to_upper(state_name),
								tostring(num_plrs) .. "/4 ",
								(job_plan == 1 and utf8.char(57364) or job_plan == 2 and utf8.char(57363) or "")
							},
							pro = is_pro,
							days = job_days,
							level_name = job_id,
							real_level_name = display_job,
							level_id = level_id,
							state_name = state_name,
							difficulty = difficulty,
							job_plan = job_plan,
							job_plan_name = job_plan_name,
							difficulty_num = difficulty_num or 2,
							is_one_down = is_one_down,
							host_name = host_name,
							state = state,
							num_plrs = num_plrs,
							kick_option = kick_option,
							kick_option_name = kick_option_name,
							friend = is_friend,
							is_crime_spree = is_crime_spree,
							crime_spree = attribute_crimespree,
							crime_spree_mission = crime_spree_mission,
							crime_spree_mission_name = crime_spree_mission_name,
							mutators = attributes_mutators,
							callback = "setup_join_cs_manager connect_to_lobby",
							localize = false,
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
						if item:parameters().difficulty_num ~= difficulty_num then
							item:parameters().difficulty_num = difficulty_num
						end
						if item:parameters().is_one_down ~= is_one_down then
							item:parameters().is_one_down = is_one_down
						end
						if item:parameters().job_plan ~= job_plan then
							item:parameters().job_plan = job_plan
							item:parameters().job_plan_name = job_plan_name
							item:parameters().columns[5] = (job_plan == 1 and utf8.char(57364) or job_plan == 2 and utf8.char(57363) or "")
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
						if item:parameters().kick_option ~= kick_option then
							item:parameters().kick_option = kick_option
							item:parameters().kick_option_name = kick_option_name
						end
						if item:parameters().mutators ~= attributes_mutators then
							item:parameters().mutators = attributes_mutators
						end
						if item:parameters().crime_spree ~= attribute_crimespree then
							item:parameters().is_crime_spree = is_crime_spree
							item:parameters().crime_spree = attribute_crimespree
						end
						if item:parameters().crime_spree_mission ~= crime_spree_mission then
							item:parameters().crime_spree_mission = crime_spree_mission
							item:parameters().crime_spree_mission_name = crime_spree_mission_name
						end
					elseif item then
						new_node:delete_item(room.room_id)
					end
				end
			end
		end
		
		for name, _ in pairs(dead_list) do
			new_node:delete_item(name)
		end
		
		table.sort(new_node:items(), function (a, b) 
			local a_diff = (a:parameters().is_crime_spree and a:parameters().crime_spree or a:parameters().difficulty_num or 2) + (a:parameters().is_one_down and 0.5 or 0)
			local b_diff = (b:parameters().is_crime_spree and b:parameters().crime_spree or b:parameters().difficulty_num or 2) + (b:parameters().is_one_down and 0.5 or 0)
			local lower_difficulty 	= (a_diff < b_diff)
			local equal_difficulty 	= (a_diff == b_diff)
			local less_players 		= (a:parameters().num_plrs or 0) < (b:parameters().num_plrs or 0)
			return lower_difficulty or (equal_difficulty and less_players) or false
		end)
		
		managers.menu:add_back_button(new_node)
		return new_node
	end

elseif requiredScript == "lib/managers/menu/menunodegui" then

	CloneClass(MenuNodeGui)

	function MenuNodeGui._highlight_row_item(self, row_item, mouse_over)
		self.orig._highlight_row_item(self, row_item, mouse_over)
		if row_item then
			if row_item.type == "server_column" then
				local item_params = row_item.item:parameters()
				for i, gui in ipairs(row_item.gui_columns) do
					if i == 1 and item_params.friend then 
						gui:set_color(tweak_data.screen_colors.friend_color)
					elseif i == 2 and item_params.pro then
						gui:set_color(tweak_data.screen_colors.pro_color)
					elseif item_params.is_crime_spree then
						--gui:set_color(tweak_data.screen_colors.crime_spree_risk)
					elseif item_params.mutators then
						gui:set_color(tweak_data.screen_colors.mutators_color_text)
					else
						gui:set_color(row_item.color)
					end
					gui:set_font(Idstring(row_item.font))
				end
				if row_item.difficulty_icons then
					for i, gui in pairs(row_item.difficulty_icons) do
						if item_params.mutators then
							gui:set_color(Color.white)
						elseif item_params.is_crime_spree then
							gui:set_color(tweak_data.screen_colors.pro_color)
						else
							gui:set_color(row_item.color)
						end
					end
				end
				if row_item.one_down_icon then
					row_item.one_down_icon:set_color(tweak_data.screen_colors.pro_color)
				end
				row_item.gui_info_panel:set_visible(true)
			end
		end
	end

	function MenuNodeGui._fade_row_item(self, row_item)
		self.orig._fade_row_item(self, row_item)
		if row_item then
			if row_item.type == "server_column" then
				local item_params = row_item.item:parameters()
				for i, gui in ipairs(row_item.gui_columns) do
					if i == 1 and item_params.friend then 
						gui:set_color(tweak_data.screen_colors.friend_color)
					elseif i == 2 and item_params.pro then 
						gui:set_color(tweak_data.screen_colors.pro_color)
					elseif item_params.mutators then
						gui:set_color(tweak_data.screen_colors.mutators_color)
					else
						gui:set_color(row_item.color)
					end
					gui:set_font(Idstring(row_item.font))
				end
				if row_item.difficulty_icons then
					for i, gui in pairs(row_item.difficulty_icons) do
						if item_params.is_crime_spree then
							gui:set_color(tweak_data.screen_colors.crime_spree_risk)
						else
							gui:set_color(tweak_data.screen_colors.risk)
						end
					end
				end
				if row_item.one_down_icon then
					row_item.one_down_icon:set_color(tweak_data.screen_colors.one_down)
				end
				row_item.gui_info_panel:set_visible(false)
			end
		end
	end

	function MenuNodeGui._create_legends(self, node)
		self.orig._create_legends(self, node)
		local is_pc = managers.menu:is_pc_controller()
		local has_pc_legend = false
		local visible_callback_name, visible_callback
		local t_text = ""
		for i, legend in pairs(node:legends()) do
			visible_callback_name = legend.visible_callback
			visible_callback = nil
			if visible_callback_name then
				visible_callback = callback(node.callback_handler, node.callback_handler, visible_callback_name)
			end
			if (not is_pc or legend.pc) and (not visible_callback or visible_callback(self)) then
				has_pc_legend = has_pc_legend or legend.pc
				local spacing = i > 1 and "  |  " or ""
				t_text = t_text .. spacing .. managers.localization:to_upper_text(legend.string_id, {
					BTN_UPDATE = managers.localization:btn_macro("menu_update") or managers.localization:get_default_macro("BTN_Y"),
					BTN_BACK = managers.localization:btn_macro("back")
				})
			end
		end
		local text = self._legends_panel:child(0)
		text:set_text(t_text)
		local _, _, w, h = text:text_rect()
		text:set_size(w, h)
		self:_layout_legends()
	end

elseif requiredScript == "lib/managers/menu/renderers/menunodetablegui" then

	function HUDBGBox_create(panel, params, config)
		local box_panel = panel:panel(params)
		local color = config and config.color
		local bg_color = config and config.bg_color or Color(1, 0, 0, 0)
		local blend_mode = config and config.blend_mode
		box_panel:rect({
			name = "bg",
			halign = "grow",
			valign = "grow",
			blend_mode = "normal",
			alpha = 0.6,
			color = bg_color,
			layer = -1
		})
		local left_top = box_panel:bitmap({
			name = "left_top",
			halign = "left",
			valign = "top",
			name = "left_top",
			color = color,
			blend_mode = blend_mode,
			visible = true,
			layer = 0,
			texture = "guis/textures/pd2/hud_corner",
			x = 0,
			y = 0
		})
		local left_bottom = box_panel:bitmap({
			name = "left_bottom",
			halign = "left",
			valign = "bottom",
			color = color,
			rotation = -90,
			name = "left_bottom",
			blend_mode = blend_mode,
			visible = true,
			layer = 0,
			texture = "guis/textures/pd2/hud_corner",
			x = 0,
			y = 0
		})
		left_bottom:set_bottom(box_panel:h())
		local right_top = box_panel:bitmap({
			name = "right_top",
			halign = "right",
			valign = "top",
			color = color,
			rotation = 90,
			name = "right_top",
			blend_mode = blend_mode,
			visible = true,
			layer = 0,
			texture = "guis/textures/pd2/hud_corner",
			x = 0,
			y = 0
		})
		right_top:set_right(box_panel:w())
		local right_bottom = box_panel:bitmap({
			name = "right_bottom",
			halign = "right",
			valign = "bottom",
			color = color,
			rotation = 180,
			name = "right_bottom",
			blend_mode = blend_mode,
			visible = true,
			layer = 0,
			texture = "guis/textures/pd2/hud_corner",
			x = 0,
			y = 0
		})
		right_bottom:set_right(box_panel:w())
		right_bottom:set_bottom(box_panel:h())
		return box_panel
	end

	function MenuNodeTableGui:_setup_panels(node)
		MenuNodeTableGui.super._setup_panels(self, node)
		
		local bg = HUDBGBox_create(self.safe_rect_panel, { w = self.safe_rect_panel:w() - self._info_bg_rect:w() - tweak_data.menu.info_padding, h = self.safe_rect_panel:h()})
		bg:set_left(self._info_bg_rect:right() + tweak_data.menu.info_padding)
		HUDBGBox_create(self.safe_rect_panel, { w = self._info_bg_rect:w(),	h = self._info_bg_rect:h() - tweak_data.menu.info_padding})
		local safe_rect_pixels = self:_scaled_size()
		
		local font_size = tweak_data.menu.pd2_small_font_size
		self._server_title = self.safe_rect_panel:text({
			name = "server_title",
			text = managers.localization:to_upper_text("menu_lobby_server_title"):sub(0, -2) .. ": ",
			font = tweak_data.menu.pd2_small_font,
			font_size = font_size,
			align = "left",
			vertical = "center",
			w = 256,
			h = font_size,
			layer = 1
		})
		self._server_info_title = self.safe_rect_panel:text({
			name = "server_info_title",
			text = managers.localization:to_upper_text("menu_lobby_server_state_title") .. " ",
			font = self.font,
			font_size = font_size,
			align = "left",
			vertical = "center",
			w = 256,
			h = font_size,
			layer = 1
		})
		self._level_title = self.safe_rect_panel:text({
			name = "level_title",
			text = managers.localization:to_upper_text("menu_lobby_campaign_title") .. " ",
			font = tweak_data.menu.pd2_small_font,
			font_size = font_size,
			align = "left",
			vertical = "center",
			w = 256,
			h = font_size,
			layer = 1
		})
		self._difficulty_title = self.safe_rect_panel:text({
			name = "difficulty_title",
			text = managers.localization:to_upper_text("menu_lobby_difficulty_title") .. " ",
			font = tweak_data.menu.pd2_small_font,
			font_size = font_size,
			align = "left",
			vertical = "center",
			w = 256,
			h = font_size,
			layer = 1
		})
		self._job_plan_title = self.safe_rect_panel:text({
			name = "job_plan_title",
			text = managers.localization:to_upper_text("menu_preferred_plan") .. ": ",
			font = tweak_data.menu.pd2_small_font,
			font_size = font_size,
			align = "left",
			vertical = "center",
			w = 256,
			h = font_size,
			layer = 1
		})
		self._days_title = self.safe_rect_panel:text({
			name = "days_title",
			text = managers.localization:to_upper_text("cn_menu_contract_length"):sub(10, -1) .. ":  ",
			font = tweak_data.menu.pd2_small_font,
			font_size = font_size,
			align = "left",
			vertical = "center",
			w = 256,
			h = font_size,
			layer = 1
		})
		self._kick_title = self.safe_rect_panel:text({
			name = "kick_title",
			text = managers.localization:to_upper_text("menu_kicking_allowed_option") .. ":  ",
			font = tweak_data.menu.pd2_small_font,
			font_size = font_size,
			align = "left",
			vertical = "center",
			w = 256,
			h = font_size,
			layer = 1
		})
		
		local offset = 22 * tweak_data.scale.lobby_info_offset_multiplier
		local _, _, w, _ = self._server_title:text_rect()
		self._server_title:set_x(tweak_data.menu.info_padding)
		self._server_title:set_y(2 * tweak_data.menu.info_padding)
		self._server_title:set_w(w)
		
		local _, _, w, _ = self._server_info_title:text_rect()
		self._server_info_title:set_x(tweak_data.menu.info_padding)
		self._server_info_title:set_y(2 * tweak_data.menu.info_padding + offset)
		self._server_info_title:set_w(w)
		
		local _, _, w, _ = self._level_title:text_rect()
		self._level_title:set_x(tweak_data.menu.info_padding)
		self._level_title:set_y(2 * tweak_data.menu.info_padding + 2 * offset)
		self._level_title:set_w(w)
		
		local _, _, w, _ = self._difficulty_title:text_rect()
		self._difficulty_title:set_x(tweak_data.menu.info_padding)
		self._difficulty_title:set_y(2 * tweak_data.menu.info_padding + 3 * offset)
		self._difficulty_title:set_w(w)
		
		local _, _, w, _ = self._job_plan_title:text_rect()
		self._job_plan_title:set_x(tweak_data.menu.info_padding)
		self._job_plan_title:set_y(2 * tweak_data.menu.info_padding + 4 * offset)
		self._job_plan_title:set_w(w)
		
		local _, _, w, _ = self._kick_title:text_rect()
		self._kick_title:set_x(tweak_data.menu.info_padding)
		self._kick_title:set_y(2 * tweak_data.menu.info_padding + 5 * offset)
		self._kick_title:set_w(w)
		
		local _, _, w, _ = self._days_title:text_rect()
		self._days_title:set_x(tweak_data.menu.info_padding)
		self._days_title:set_y(2 * tweak_data.menu.info_padding + 6 * offset)
		self._days_title:set_w(w)
		
		
		
		self._button_panel = self.safe_rect_panel:panel({
			name = "button_panel",
			x = 0,
			y = self._info_bg_rect:h(),
			w = self._info_bg_rect:w(),
			h = self.safe_rect_panel:h() - self._info_bg_rect:h()
		})

		
		self._mini_info_text = self._button_panel:text({
			name = "players_online_text",
			x = self._button_panel:w() - tweak_data.menu.info_padding * 12,
			y = tweak_data.menu.info_padding,
			w = tweak_data.menu.info_padding * 11,
			h = 35,
			align = "left",
			halign = "top",
			vertical = "top",
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size + 2,
			color = Color.white,
			layer = self.layers.items,
			text = "",
		})
		
		self._safehouse_button = self._button_panel:text({
			name = "safehouse_btn",
			x = tweak_data.menu.info_padding + 22,
			y = tweak_data.menu.info_padding,
			h = tweak_data.menu.pd2_small_font_size + 2,
			align = "left",
			halign = "top",
			vertical = "top",
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size + 2,
			color = tweak_data.screen_colors.button_stage_3,
			layer = self.layers.items,
			text = managers.localization:text("menu_cn_chill"):upper(),
		})
		self._casino_button = self._button_panel:text({
			name = "casino_btn",
			x = tweak_data.menu.info_padding + 22,
			y = self._safehouse_button:bottom() + 1,
			h = tweak_data.menu.pd2_small_font_size + 2,
			align = "left",
			halign = "top",
			vertical = "top",
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size + 2,
			color = tweak_data.screen_colors.button_stage_3, --tweak_data.menu.default_disabled_text_color,
			layer = self.layers.items,
			text = managers.localization:text("menu_cn_casino"):upper(),
		})
		self._filter_button = self._button_panel:text({
			name = "filter_btn",
			x = tweak_data.menu.info_padding + 1,
			y = self._casino_button:bottom() + 1,
			h = tweak_data.menu.pd2_small_font_size + 2,
			align = "left",
			halign = "top",
			vertical = "top",
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size + 2,
			color = tweak_data.screen_colors.button_stage_3,
			layer = self.layers.items,
			text = managers.localization:text("menu_cn_filter", {BTN_Y = managers.localization:btn_macro("menu_toggle_filters", true)}):upper(),
		})
		self._refresh_button = self._button_panel:text({
			name = "refresh_btn",
			x = tweak_data.menu.info_padding,
			y = self._filter_button:bottom() + 1,
			h = tweak_data.menu.pd2_small_font_size + 2,
			align = "left",
			halign = "top",
			vertical = "top",
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size + 2,
			color = tweak_data.screen_colors.button_stage_3,
			layer = self.layers.items,
			text = managers.localization:text("menu_legend_update", {BTN_UPDATE = managers.localization:btn_macro("menu_update", true)}),
		})
		self._host_button = self._button_panel:text({
			name = "host_btn",
			x = self._button_panel:w()/ 2 + tweak_data.menu.info_padding,
			y = tweak_data.menu.pd2_large_font_size * 0.75,
			h = tweak_data.menu.pd2_large_font_size - 12,
			align = "left",
			halign = "top",
			vertical = "top",
			font = tweak_data.menu.pd2_large_font,
			font_size = tweak_data.menu.pd2_large_font_size - 12,
			color = tweak_data.screen_colors.button_stage_3,
			layer = self.layers.items,
			text = managers.localization:text("menu_cn_premium_buy_desc"):upper(),
		})
		self._crimespree_button = self._button_panel:text({
			name = "crimespree_btn",
			x = self._button_panel:w()/ 2 + tweak_data.menu.info_padding,
			y = tweak_data.menu.pd2_large_font_size * 1.5,
			w = 100,
			h = tweak_data.menu.pd2_large_font_size - 14,
			align = "right",
			halign = "top",
			vertical = "top",
			font = tweak_data.menu.pd2_large_font,
			font_size = tweak_data.menu.pd2_large_font_size - 14,
			color = tweak_data.screen_colors.button_stage_3,
			layer = self.layers.items,
			text = "",
			visible = managers.crime_spree:unlocked(),
		})
		if managers.crime_spree and managers.crime_spree:in_progress() then
			local level = managers.localization:text("menu_cs_level", {level = managers.experience:cash_string(managers.crime_spree:spree_level(), "")})
			local contine_text = string.format("%s (", managers.localization:text("cn_crime_spree_continue"))
			self._crimespree_button:set_text(string.format("%s%s)", contine_text, level):upper())
			self._crimespree_button:set_range_color(contine_text:len(), contine_text:len() + level:len() - 2, tweak_data.screen_colors.crime_spree_risk)
		else
			self._crimespree_button:set_text(managers.localization:text("cn_crime_spree_start"):upper())
		end
		local _, _, w, _ = self._crimespree_button:text_rect()
		self._crimespree_button:set_w(w)
		self._crimespree_button:set_x(self._button_panel:w() - w - tweak_data.menu.info_padding)

		self._holdout_button = self._button_panel:text({
			name = "holdout_btn",
			x = self._button_panel:w()/ 2 + tweak_data.menu.info_padding,
			y = self._crimespree_button:bottom() + 2,
			w = 100,
			h = tweak_data.menu.pd2_large_font_size - 14,
			align = "right",
			halign = "top",
			vertical = "top",
			font = tweak_data.menu.pd2_large_font,
			font_size = tweak_data.menu.pd2_large_font_size - 14,
			color = tweak_data.screen_colors.button_stage_3,
			layer = self.layers.items,
			text = managers.localization:text("menu_cn_skirmish"):upper(),
			visible = managers.skirmish:is_unlocked(),
		})
		local _, _, w, _ = self._holdout_button:text_rect()
		self._holdout_button:set_w(w)
		self._holdout_button:set_x(self._button_panel:w() - w - tweak_data.menu.info_padding)

		if FastNet.settings.show_reconnect then
			self._reconnect_button = self._button_panel:text({
				name = "reconnect_btn",
				x = tweak_data.menu.info_padding - 4,
				y = self._refresh_button:bottom() + 1,
				h = tweak_data.menu.pd2_small_font_size + 2,
				align = "left",
				halign = "top",
				vertical = "top",
				font = tweak_data.menu.pd2_small_font,
				font_size = tweak_data.menu.pd2_small_font_size + 2,
				color = tweak_data.screen_colors.button_stage_3,
				layer = self.layers.items,
				text = ("[" .. (BLT.Keybinds:get_keybind("Reconnect_key") or "f1") .."] " .. managers.localization:text("menu_button_reconnect")):upper(),
			})
			local _, _, w, _ = self._reconnect_button:text_rect()
			self._reconnect_button:set_w(w+5)
			--self._reconnect_button:set_x(self._button_panel:w() - w - tweak_data.menu.info_padding)
			--self._reconnect_button:set_y(self._refresh_button:y())

		end
		
		HUDBGBox_create(self._button_panel, { w = self._button_panel:w(),	h = self._button_panel:h()})
		local _, _, w, _ = self._safehouse_button:text_rect()
		self._safehouse_button:set_w(w)
		local _, _, w, _ = self._casino_button:text_rect()
		self._casino_button:set_w(w)
		local _, _, w, _ = self._filter_button:text_rect()
		self._filter_button:set_w(w)
		local _, _, w, _ = self._refresh_button:text_rect()
		self._refresh_button:set_w(w)
		local _, _, w, _ = self._host_button:text_rect()
		self._host_button:set_w(w)
		self._host_button:set_x(self._button_panel:w() - w - tweak_data.menu.info_padding)

		
		self.ws:connect_keyboard(Input:keyboard())  
		self.safe_rect_panel:key_press(callback(self, self, "key_press"))
	end

	function MenuNodeTableGui:set_mini_info(text)
		self._mini_info_text:set_text(text)
	end

	function MenuNodeTableGui:_create_menu_item(row_item)
		if row_item.type == "column" then
			local columns = row_item.node:columns()
			local total_proportions = row_item.node:parameters().total_proportions
			row_item.gui_panel = self.item_panel:panel({
				x = self:_right_align(),
				w = self.item_panel:w()
			})
			row_item.gui_columns = {}
			local x = 0
			for i, data in ipairs(columns) do
				local text = row_item.gui_panel:text({
					font_size = self.font_size,
					x = row_item.position.x,
					y = 0,
					align = data.align,
					halign = data.align,
					vertical = "center",
					font = row_item.font,
					color = row_item.color,
					layer = self.layers.items,
					text = row_item.item:parameters().columns[i]
				})
				row_item.gui_columns[i] = text
				local _, _, w, h = text:text_rect()
				text:set_h(h)
				local w = data.proportions / total_proportions * row_item.gui_panel:w()
				text:set_w(w)
				text:set_x(x)
				x = x + w
			end
			local x, y, w, h = row_item.gui_columns[1]:text_rect()
			row_item.gui_panel:set_height(h)
		elseif row_item.type == "server_column" then
			--row_item.font = tweak_data.menu.pd2_medium_font_id
			local columns = row_item.node:columns()
			local total_proportions = row_item.node:parameters().total_proportions
			local safe_rect = self:_scaled_size()
			local xl_pad = 80
			row_item.gui_panel = self.item_panel:panel({
				x = safe_rect.width / 2 - xl_pad,
				w = safe_rect.width / 2 + xl_pad - tweak_data.menu.info_padding
			})
			row_item.gui_columns = {}
			local x = 0
			for i, data in ipairs(columns) do
				local color = row_item.color
				if i == 1 and row_item.item:parameters().friend then
					color = tweak_data.screen_colors.friend_color
				elseif i == 2 and row_item.item:parameters().pro then
					color = tweak_data.screen_colors.pro_color
				elseif row_item.item:parameters().mutators then
					color = tweak_data.screen_colors.mutators_color
				end
				
				local text = row_item.gui_panel:text({
					font_size = tweak_data.menu.server_list_font_size,
					x = row_item.position.x,
					y = 0,
					align = data.align,
					halign = data.align,
					vertical = "center",
					font = row_item.font,
					font_size = math.round(row_item.font_size * 0.77),
					color = color,
					layer = self.layers.items,
					text = row_item.item:parameters().columns[i]
				})
				row_item.gui_columns[i] = text
				local _, _, w, h = text:text_rect()
				text:set_h(h)
				local w = data.proportions / total_proportions * row_item.gui_panel:w()
				text:set_w(w + (i == 2 and 10 or 0))
				text:set_x(x)
				x = x + w
			end
			local x, y, w, h = row_item.gui_columns[1]:text_rect()
			row_item.gui_panel:set_height(h)	
			
			local x = row_item.gui_columns[2]:right()
			local y = 0
			row_item.difficulty_icons = {}
			if row_item.item:parameters().is_crime_spree then
				local spree_level = row_item.gui_panel:text({
					font_size = tweak_data.menu.server_list_font_size,
					x = x,
					y = y,
					w = 60,
					h = h,
					align = "right",
					halign = "center",
					vertical = "center",
					font = row_item.font,
					font_size = math.round(row_item.font_size * 0.77),
					color = tweak_data.screen_colors.crime_spree_risk,
					layer = self.layers.items,
					text = managers.experience:cash_string(tonumber(row_item.item:parameters().crime_spree), "") .. managers.localization:get_default_macro("BTN_SPREE_TICKET"),
				})
				table.insert(row_item.difficulty_icons, spree_level)
			else
				local difficulty_stars = row_item.item:parameters().difficulty_num
				local start_difficulty = 3
				local num_difficulties = 6
				local spacing = 14
				for i = start_difficulty, difficulty_stars do
					local difficulty_id = tweak_data:index_to_difficulty(i)
					local skull_texture = difficulty_id and tweak_data.gui.blackscreen_risk_textures[difficulty_id] or "guis/textures/pd2/risklevel_blackscreen"
					local skull = row_item.gui_panel:bitmap({
						texture = skull_texture,
						x = x,
						y = y,
						w = h,
						h = h,
						--blend_mode = "add",
						layer = self.layers.items,
						color = tweak_data.screen_colors.risk
					})
					x = x + (spacing)
					row_item.difficulty_icons[i] = skull
					--num_stars = num_stars + 1
					--skull:set_center_y(row_item.gui_columns[2]:center_y())
				end
				if row_item.item:parameters().is_one_down then
					row_item.one_down_icon = row_item.gui_panel:bitmap({
						texture = "guis/textures/pd2/cn_mini_onedown",
						x = x,
						y = y,
						w = h,
						h = h,
						--blend_mode = "add",
						layer = self.layers.items,
						color = tweak_data.screen_colors.one_down,
					})
				end
			end
			
			
			
			local level_id = row_item.item:parameters().level_id
			local mutators = row_item.item:parameters().mutators or {}
			local mutators_list = {}
			local mutators_text = ""
			if mutators then
				managers.mutators:set_crimenet_lobby_data(mutators)
				for mutator_id, mutator_data in pairs(mutators) do
					local mutator = managers.mutators:get_mutator_from_id(mutator_id)
					if mutator then
						table.insert(mutators_list, mutator:name()) 
					end
				end
				managers.mutators:set_crimenet_lobby_data(nil)
				table.sort(mutators_list, function(a, b) 
					return a < b
				end)
				for i, mutator in ipairs(mutators_list) do
					mutators_text = string.format("%s%s", mutators_text, (mutator .. (i < #mutators_list and "\n" or "")))
				end
			end
			
			row_item.gui_info_panel = self.safe_rect_panel:panel({
				visible = false,
				layer = self.layers.items,
				x = 0,
				y = 0,
				w = self:_left_align(),
				h = self._item_panel_parent:h()
			})
			row_item.heist_name = row_item.gui_info_panel:text({
				visible = false,
				text = utf8.to_upper(row_item.item:parameters().level_name),
				layer = self.layers.items,
				font = self.font,
				font_size = tweak_data.menu.challenges_font_size,
				color = row_item.color,
				align = "left",
				vertical = "left"
			})
			local briefing_text = level_id and managers.localization:text(tweak_data.levels[level_id].briefing_id) or ""
			row_item.heist_briefing = row_item.gui_info_panel:text({
				visible = true,
				x = 0,
				y = 0,
				align = "left",
				halign = "top",
				vertical = "top",
				font = tweak_data.menu.pd2_small_font,
				font_size = tweak_data.menu.pd2_small_font_size,
				color = Color.white,
				layer = self.layers.items,
				text = briefing_text,
				wrap = true,
				word_wrap = true
			})
			
			local font_size = tweak_data.menu.pd2_small_font_size
			row_item.server_text = row_item.gui_info_panel:text({
				name = "server_text",
				text = utf8.to_upper(row_item.item:parameters().host_name) .. "  ",
				font = tweak_data.menu.pd2_small_font,
				color = tweak_data.hud.prime_color,
				font_size = font_size,
				align = "left",
				vertical = "center",
				w = 256,
				h = font_size,
				layer = 1
			})
			row_item.server_friend_text = row_item.gui_info_panel:text({
				name = "server_friend_text",
				text = utf8.to_upper(row_item.item:parameters().friend and "[FRIEND]" or ""),
				font = tweak_data.menu.pd2_small_font,
				color = tweak_data.screen_colors.friend_color,
				font_size = font_size,
				align = "left",
				vertical = "center",
				w = 256,
				h = font_size,
				layer = 1
			})
			row_item.server_mutators_text = row_item.gui_info_panel:text({
				name = "server_mutators_text",
				text = utf8.to_upper(row_item.item:parameters().mutators and managers.localization:text("fastnet_mutators_tag") or ""),
				font = tweak_data.menu.pd2_small_font,
				color = tweak_data.screen_colors.mutators_color_text,
				font_size = font_size,
				align = "left",
				vertical = "center",
				w = 256,
				h = font_size,
				layer = 1
			})
			
			row_item.crime_spree_text = row_item.gui_info_panel:text({
				name = "crime_spree_text",
				text = utf8.to_upper(row_item.item:parameters().is_crime_spree and "[CRIME SPREE]" or ""),
				font = tweak_data.menu.pd2_small_font,
				color = tweak_data.screen_colors.crime_spree_risk,
				font_size = font_size,
				align = "left",
				vertical = "center",
				w = 256,
				h = font_size,
				layer = 1
			})
			row_item.server_info_text = row_item.gui_info_panel:text({
				name = "server_info_text",
				text = utf8.to_upper(row_item.item:parameters().state_name) .. " " .. tostring(row_item.item:parameters().num_plrs) .. "/4 ",
				font = self.font,
				color = tweak_data.hud.prime_color,
				font_size = font_size,
				align = "left",
				vertical = "center",
				w = 256,
				h = font_size,
				layer = 1
			})
			row_item.level_text = row_item.gui_info_panel:text({
				name = "level_text",
				text = utf8.to_upper(row_item.item:parameters().is_crime_spree and row_item.item:parameters().crime_spree_mission_name or row_item.item:parameters().real_level_name) .. " ",
				font = tweak_data.menu.pd2_small_font,
				color = tweak_data.hud.prime_color,
				font_size = font_size,
				align = "left",
				vertical = "center",
				w = 256,
				h = font_size,
				layer = 1
			})
			
			row_item.level_pro_text = row_item.gui_info_panel:text({
				name = "level_pro_text",
				text = utf8.to_upper(row_item.item:parameters().pro and "PRO JOB" or ""),
				font = tweak_data.menu.pd2_small_font,
				color = tweak_data.screen_colors.pro_color,
				font_size = font_size,
				align = "left",
				vertical = "center",
				w = 256,
				h = font_size,
				layer = 1
			})
			
			row_item.difficulty_text = row_item.gui_info_panel:text({
				name = "difficulty_text",
				text = row_item.item:parameters().is_crime_spree and (managers.experience:cash_string(tonumber(row_item.item:parameters().crime_spree), "") .. managers.localization:get_default_macro("BTN_SPREE_TICKET")) or managers.localization:to_upper_text(tweak_data.difficulty_name_ids[row_item.item:parameters().difficulty]),
				font = tweak_data.menu.pd2_small_font,
				color = tweak_data.hud.prime_color,
				font_size = font_size,
				align = "left",
				vertical = "center",
				w = 256,
				h = font_size,
				layer = 1
			})
			
			row_item.one_down_text = row_item.gui_info_panel:text({
				name = "one_down_text",
				text = managers.localization:to_upper_text("menu_one_down"),
				font = tweak_data.menu.pd2_small_font,
				color = tweak_data.screen_colors.one_down,
				font_size = font_size,
				align = "left",
				vertical = "center",
				w = 256,
				h = font_size,
				layer = 1
			})
			
			row_item.job_plan_text = row_item.gui_info_panel:text({
				name = "job_plan_text",
				text = managers.localization:to_upper_text(row_item.item:parameters().job_plan_name),
				font = tweak_data.menu.pd2_small_font,
				color = tweak_data.hud.prime_color,
				font_size = font_size,
				align = "left",
				vertical = "center",
				w = 256,
				h = font_size,
				layer = 1
			})
			
			row_item.days_text = row_item.gui_info_panel:text({
				name = "days_text",
				text = utf8.to_upper(math.max(row_item.item:parameters().days, 1)),
				font = tweak_data.menu.pd2_small_font,
				color = tweak_data.hud.prime_color,
				font_size = font_size,
				align = "left",
				vertical = "center",
				w = 256,
				h = font_size,
				layer = 1
			})
			row_item.kick_text = row_item.gui_info_panel:text({
				name = "kick_text",
				text = managers.localization:to_upper_text(row_item.item:parameters().kick_option_name),
				font = tweak_data.menu.pd2_small_font,
				color = tweak_data.hud.prime_color,
				font_size = font_size,
				align = "left",
				vertical = "center",
				w = 256,
				h = font_size,
				layer = 1
			})
			row_item.mutators_title = row_item.gui_info_panel:text({
				name = "mutators_title",
				text = managers.localization:to_upper_text("menu_mutators") .. ":  ",
				font = tweak_data.menu.pd2_small_font,
				font_size = font_size,
				align = "left",
				vertical = "center",
				w = 256,
				h = font_size,
				layer = 1
			})
			row_item.mutators_list = row_item.gui_info_panel:text({
				name = "days_text",
				text = utf8.to_upper(mutators_text),
				font = tweak_data.menu.pd2_small_font,
				color = tweak_data.hud.prime_color,
				font_size = font_size,
				align = "left",
				vertical = "center",
				w = 256,
				h = font_size,
				layer = 1
			})
			
			self:_align_server_column(row_item)
			local visible = row_item.item:menu_unselected_visible(self, row_item) and not row_item.item:parameters().back
			row_item.menu_unselected = self.item_panel:bitmap({
				visible = visible,
				texture = "guis/textures/menu_unselected",
				x = 0,
				y = 0,
				layer = -1
			})
			row_item.menu_unselected:set_color(row_item.item:parameters().is_expanded and Color(0.5, 0.5, 0.5) or Color.white)
			row_item.menu_unselected:hide()
		else
			MenuNodeTableGui.super._create_menu_item(self, row_item)
		end
	end
	function MenuNodeTableGui:_align_server_column(row_item)
		local safe_rect = self:_scaled_size()
		--self:_align_item_gui_info_panel(row_item.gui_info_panel)
		row_item.gui_info_panel:set_w(self._info_bg_rect:w())
		row_item.gui_info_panel:set_h(row_item.gui_info_panel:h() - 2*(tweak_data.menu.pd2_small_font_size + 4))
		local font_size = tweak_data.menu.pd2_small_font_size
		local offset = 22 * tweak_data.scale.lobby_info_offset_multiplier
		local _, _, w, _ = row_item.server_text:text_rect()
		row_item.server_text:set_lefttop(self._server_title:righttop())
		row_item.server_text:set_w(w)
		row_item.server_text:set_position(math.round(row_item.server_text:x()), math.round(row_item.server_text:y()))
		
		row_item.server_friend_text:set_lefttop(row_item.server_text:righttop())
		row_item.server_friend_text:set_w(row_item.gui_info_panel:w())
		row_item.server_friend_text:set_position(math.round(row_item.server_friend_text:x()), math.round(row_item.server_friend_text:y()))
		local _, _, w, _ = row_item.server_friend_text:text_rect()
		row_item.server_friend_text:set_w(w)
		
		row_item.server_mutators_text:set_lefttop(row_item.server_friend_text:righttop())
		row_item.server_mutators_text:set_w(row_item.gui_info_panel:w())
		row_item.server_mutators_text:set_position(math.round(row_item.server_mutators_text:x()), math.round(row_item.server_mutators_text:y()))
		local _, _, w, _ = row_item.server_mutators_text:text_rect()
		row_item.server_mutators_text:set_w(w)
		
		row_item.crime_spree_text:set_lefttop(row_item.server_mutators_text:righttop())
		row_item.crime_spree_text:set_w(row_item.gui_info_panel:w())
		row_item.crime_spree_text:set_position(math.round(row_item.crime_spree_text:x()), math.round(row_item.crime_spree_text:y()))
		
		row_item.server_info_text:set_lefttop(self._server_info_title:righttop())
		row_item.server_info_text:set_w(row_item.gui_info_panel:w())
		row_item.server_info_text:set_position(math.round(row_item.server_info_text:x()), math.round(row_item.server_info_text:y()))
		
		local x, y, w, h = row_item.level_text:text_rect()
		row_item.level_text:set_lefttop(self._level_title:righttop())
		row_item.level_text:set_w(w)
		row_item.level_text:set_position(math.round(row_item.level_text:x()), math.round(row_item.level_text:y()))
		
		row_item.level_pro_text:set_lefttop(row_item.level_text:righttop())
		row_item.level_pro_text:set_w(row_item.gui_info_panel:w())
		row_item.level_pro_text:set_position(math.round(row_item.level_pro_text:x()), math.round(row_item.level_pro_text:y()))
		
		row_item.days_text:set_lefttop(self._days_title:righttop())
		row_item.days_text:set_w(row_item.gui_info_panel:w())
		row_item.days_text:set_position(math.round(row_item.days_text:x()), math.round(row_item.days_text:y()))
		
		row_item.difficulty_text:set_lefttop(self._difficulty_title:righttop())
		local _, _, w, _ = row_item.difficulty_text:text_rect()
		row_item.difficulty_text:set_w(w + 8)
		row_item.difficulty_text:set_position(math.round(row_item.difficulty_text:x()), math.round(row_item.difficulty_text:y()))

		row_item.one_down_text:set_lefttop(row_item.difficulty_text:righttop())
		row_item.one_down_text:set_w(row_item.gui_info_panel:w())
		row_item.one_down_text:set_position(math.round(row_item.one_down_text:x()), math.round(row_item.one_down_text:y()))
		row_item.one_down_text:set_visible(row_item.item:parameters().is_one_down or false)
		
		row_item.job_plan_text:set_lefttop(self._job_plan_title:righttop())
		row_item.job_plan_text:set_w(row_item.gui_info_panel:w())
		row_item.job_plan_text:set_position(math.round(row_item.job_plan_text:x()), math.round(row_item.job_plan_text:y()))
		
		row_item.kick_text:set_lefttop(self._kick_title:righttop())
		row_item.kick_text:set_w(row_item.gui_info_panel:w())
		row_item.kick_text:set_position(math.round(row_item.kick_text:x()), math.round(row_item.kick_text:y()))
		
		local mutators_active = row_item.item:parameters().mutators or false
		
		local _, _, w, h = row_item.mutators_list:text_rect()
		row_item.mutators_list:set_w(row_item.gui_info_panel:w())
		row_item.mutators_list:set_h(h)
		row_item.mutators_list:set_bottom(self._info_bg_rect:h() - 2 * tweak_data.menu.info_padding)
		row_item.mutators_list:set_visible(mutators_active)
		
		local _, _, w, _ = row_item.mutators_title:text_rect()
		row_item.mutators_title:set_x(tweak_data.menu.info_padding)
		row_item.mutators_title:set_w(w)
		row_item.mutators_title:set_visible(mutators_active)
		
		row_item.mutators_title:set_top(row_item.mutators_list:top())
		row_item.mutators_list:set_left(row_item.mutators_title:right())
		
		row_item.mutators_title:set_position(math.round(row_item.mutators_title:x()), math.floor(row_item.mutators_title:y()))
		row_item.mutators_list:set_position(math.round(row_item.mutators_list:x()), math.floor(row_item.mutators_list:y()))
		
		local _, _, _, h = row_item.heist_name:text_rect()
		local w = row_item.gui_info_panel:w()
		row_item.heist_name:set_height(h)
		row_item.heist_name:set_w(w - tweak_data.menu.info_padding )
		
		row_item.heist_briefing:set_w(w - tweak_data.menu.info_padding * 2 )
		row_item.heist_briefing:set_shape(row_item.heist_briefing:text_rect())
		row_item.heist_briefing:set_x(tweak_data.menu.info_padding)
		row_item.heist_briefing:set_y(row_item.days_text:bottom() + 2 * tweak_data.menu.info_padding)
		row_item.heist_briefing:set_position(math.round(row_item.heist_briefing:x()), math.round(row_item.heist_briefing:y()))
		row_item.heist_briefing:set_h(math.floor(self._info_bg_rect:h() - (row_item.days_text:bottom() + (row_item.mutators_list:visible() and (row_item.mutators_list:h() + 2 * tweak_data.menu.info_padding) or 0) + 4 * tweak_data.menu.info_padding)))
	end


	function MenuNodeTableGui:mouse_pressed(button, x, y)
		--[[if self.item_panel:inside(x, y) and self._item_panel_parent:inside(x, y) and x > self:_mid_align() then
			if button == Idstring("mouse wheel down") then
				return self:wheel_scroll_start(-1)
			elseif button == Idstring("mouse wheel up") then
				return self:wheel_scroll_start(1)
			end
		end]]--
		MenuNodeTableGui.super.mouse_pressed(self, button, x, y)
		if button == Idstring("0") then
			if self._reconnect_button and self._reconnect_button:inside(x, y) then
				FastNet:reconnect()
				return true
			elseif self._host_button:inside(x, y) then
				--managers.menu:open_node("crimenet_contract_special", {})
				managers.menu:open_node("contract_broker", {})
				managers.menu_component:disable_crimenet()
				return true
			elseif self._crimespree_button:visible() and self._crimespree_button:inside(x, y) then
				managers.menu_component:post_event("menu_enter")
				local node = Global.game_settings.single_player and "crimenet_crime_spree_contract_singleplayer" or "crimenet_crime_spree_contract_host"
				local data = {
					{
						job_id = "crime_spree",
						difficulty = tweak_data.crime_spree.base_difficulty,
						difficulty_id = tweak_data.crime_spree.base_difficulty_index,
						professional = false,
						competitive = false,
						customize_contract = false,
						contract_visuals = {}
					}
				}
				managers.menu:open_node(node, data)
			elseif self._holdout_button:visible() and self._holdout_button:inside(x, y) then
				SkirmishLandingMenuComponent:open_node()
			elseif self._safehouse_button:inside(x, y) then
				managers.menu:open_node("custom_safehouse", {})
				managers.menu_component:disable_crimenet()
				return true
			elseif self._casino_button:inside(x, y) then
				managers.menu:open_node("crimenet_contract_casino", {})
				managers.menu_component:disable_crimenet()
				return true
			elseif self._filter_button:inside(x, y) then
				--managers.menu_component:post_event("menu_enter")
				managers.menu:open_node("crimenet_filters", {})
				managers.menu_component:disable_crimenet()
				return true
			elseif self._refresh_button:inside(x, y) then
				managers.network.matchmake:search_lobby(managers.network.matchmake:search_friends_only())
				return true
			elseif self._mini_info_text:inside(x, y) then
				Steam:overlay_activate("url", "http://store.steampowered.com/stats")
				return true
			end
		end
	end

	function MenuNodeTableGui:key_press(o, k)
		if managers.network and managers.network:session() and not Network:is_server() then return end
		if managers.menu_component and managers.menu_component.crimenet_enabled and not managers.menu_component:crimenet_enabled() then return end

		local reconnect_key = BLT.Keybinds:get_keybind("Reconnect_key") or "f1"
		local type = managers.controller:get_default_wrapper_type()
		local filter_key = managers.controller:get_settings(type):get_connection("menu_toggle_filters"):get_input_name_list()[1] or "f"
		if self._reconnect_button and k == Idstring(reconnect_key) then
			FastNet:reconnect() 
		elseif k == Idstring(filter_key) and self._filter_button then
			managers.menu:open_node("crimenet_filters", {})
		end
		
		if managers.menu_component then
			managers.menu_component:disable_crimenet()
		end
	end

	function MenuNodeTableGui:mouse_moved(o, x, y)
		local over_button = nil
		if self._reconnect_button then
			if not over_button and self._reconnect_button:inside(x, y) then
				over_button = self._reconnect_button
			end
		end
		
		if not over_button and self._host_button:inside(x, y) then
			over_button = self._host_button
		end
		
		if not over_button and self._crimespree_button:visible() and self._crimespree_button:inside(x, y) then
			over_button = self._crimespree_button
		end
		
		if not over_button and self._holdout_button:visible() and self._holdout_button:inside(x, y) then
			over_button = self._holdout_button
		end
		
		if not over_button and self._safehouse_button:inside(x, y) then
			over_button = self._safehouse_button
		end
		
		if not over_button and self._casino_button:inside(x, y) then
			over_button = self._casino_button
		end
		
		if not over_button and self._filter_button:inside(x, y) then
			over_button = self._filter_button
		end
		
		if not over_button and self._refresh_button:inside(x, y) then
			over_button = self._refresh_button
		end
		
		if not (over_button and self._highlighted_button and self._highlighted_button:name() == over_button:name()) then
			if self._highlighted_button then
				self._highlighted_button:set_color(tweak_data.screen_colors.button_stage_3)
			end
			if over_button then
				over_button:set_color(tweak_data.screen_colors.button_stage_2)
				managers.menu_component:post_event("highlight")
			end
			self._highlighted_button = over_button
		end
		
		over_button = over_button or self._mini_info_text:inside(x, y)
		
		local inside_btnpanel = self._button_panel:inside(x, y)

		return inside_btnpanel, over_button and "link" or "arrow"
	end

elseif requiredScript == "lib/managers/menu/nodes/menunodeserverlist" then

	function MenuNodeServerList:_setup_columns()
		self:_add_column({		-- Server Name
			text = string.upper(""),
			proportions = 1.4,
			align = "left"
		})
		self:_add_column({		-- level name
			text = string.upper(""),
			proportions = 1.6,
			align = "right"
		})
		self:_add_column({		-- Difficulty, State name
			text = string.upper(""),
			proportions = 1.4,
			align = "right"
		})
		self:_add_column({		-- Players/Total
			text = string.upper(""),
			proportions = 0.2,
			align = "right"
		})
		self:_add_column({		-- Lobby Plan
			text = string.upper(""),
			proportions = 0.1,
			align = "center"
		})
	end
end
