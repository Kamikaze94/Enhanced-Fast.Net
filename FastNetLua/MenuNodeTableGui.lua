log("MenuNodeTableGui")

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
	if self._fastnet_enabled == nil then
		self._fastnet_enabled = true
	end
	
	local bg = HUDBGBox_create(self.safe_rect_panel, { w = self.safe_rect_panel:w() - self._info_bg_rect:w() - tweak_data.menu.info_padding, h = self.safe_rect_panel:h()})
	bg:set_left(self._info_bg_rect:right() + tweak_data.menu.info_padding)
	HUDBGBox_create(self.safe_rect_panel, { w = self._info_bg_rect:w(),	h = self._info_bg_rect:h() - tweak_data.menu.info_padding})
	local safe_rect_pixels = self:_scaled_size()
	
	local font_size = tweak_data.menu.pd2_small_font_size
	self._server_title = self.safe_rect_panel:text({
		name = "server_title",
		text = utf8.to_upper(managers.localization:text("menu_lobby_server_title")):sub(0, -2) .. ": ",
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
		text = utf8.to_upper(managers.localization:text("menu_lobby_server_state_title")) .. " ",
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
		text = utf8.to_upper(managers.localization:text("menu_lobby_campaign_title")) .. " ",
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
		text = utf8.to_upper(managers.localization:text("menu_lobby_difficulty_title")) .. " ",
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
		text = utf8.to_upper(managers.localization:text("menu_preferred_plan")) .. ": ",
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
		text = utf8.to_upper(managers.localization:text("cn_menu_contract_length"):sub(10, -1)) .. ":  ",
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
	
	local _, _, w, _ = self._days_title:text_rect()
	self._days_title:set_x(tweak_data.menu.info_padding)
	self._days_title:set_y(2 * tweak_data.menu.info_padding + 5 * offset)
	self._days_title:set_w(w)
	
	
	local buttons = self.safe_rect_panel:panel({
		x = 0,
		y = self._info_bg_rect:h(),
		w = self._info_bg_rect:w(),
		h = self.safe_rect_panel:h() - self._info_bg_rect:h()
	})
	
	self._mini_info_text = buttons:text({
		x = buttons:w() - tweak_data.menu.info_padding * 12,
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
		wrap = true,
		word_wrap = true
	})
	
	self._sidejobs_button = buttons:text({
		x = tweak_data.menu.info_padding + 22,
		y = (tweak_data.menu.pd2_small_font_size + 4) * 1,
		h = tweak_data.menu.pd2_small_font_size + 2,
		align = "left",
		halign = "top",
		vertical = "top",
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size + 2,
		color = tweak_data.screen_colors.button_stage_3,
		layer = self.layers.items,
		text = managers.localization:text("menu_cn_challenge"):upper(),
		wrap = true,
		word_wrap = true
	})
	self._casino_button = buttons:text({
		x = tweak_data.menu.info_padding + 22,
		y = (tweak_data.menu.pd2_small_font_size + 4) * 2,
		h = tweak_data.menu.pd2_small_font_size + 2,
		align = "left",
		halign = "top",
		vertical = "top",
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size + 2,
		color = tweak_data.screen_colors.button_stage_3, --tweak_data.menu.default_disabled_text_color,
		layer = self.layers.items,
		text = managers.localization:text("menu_cn_casino"):upper(),
		wrap = true,
		word_wrap = true
	})
	self._filter_button = buttons:text({
		x = tweak_data.menu.info_padding + 1,
		y = (tweak_data.menu.pd2_small_font_size + 4) * 3,
		h = tweak_data.menu.pd2_small_font_size + 2,
		align = "left",
		halign = "top",
		vertical = "top",
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size + 2,
		color = tweak_data.screen_colors.button_stage_3,
		layer = self.layers.items,
		text = managers.localization:text("menu_cn_filter", {BTN_Y = managers.localization:btn_macro("menu_toggle_filters", true)}):upper(),
		wrap = true,
		word_wrap = true
	})
	self._refresh_button = buttons:text({
		x = tweak_data.menu.info_padding,
		y = (tweak_data.menu.pd2_small_font_size + 4) * 4,
		h = tweak_data.menu.pd2_small_font_size + 2,
		align = "left",
		halign = "top",
		vertical = "top",
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size + 2,
		color = tweak_data.screen_colors.button_stage_3,
		layer = self.layers.items,
		text = managers.localization:text("menu_legend_update", {BTN_UPDATE = managers.localization:btn_macro("menu_update", true)}),
		wrap = true,
		word_wrap = true
	})
	self._host_button = buttons:text({
		x = buttons:w()/ 2 + tweak_data.menu.info_padding,
		y = tweak_data.menu.pd2_large_font_size + 4,
		h = tweak_data.menu.pd2_large_font_size - 8,
		align = "left",
		halign = "top",
		vertical = "top",
		font = tweak_data.menu.pd2_large_font,
		font_size = tweak_data.menu.pd2_large_font_size - 8,
		color = tweak_data.screen_colors.button_stage_3,
		layer = self.layers.items,
		text = managers.localization:text("menu_cn_premium_buy_desc"):upper(),
		wrap = true,
		word_wrap = true
	})
	
	if FastNet.settings.show_reconnect then
		self._reconnect_button = buttons:text({
			x = buttons:w()/ 2 + tweak_data.menu.info_padding,
			y = (tweak_data.menu.pd2_small_font_size + 4) * 4,
			h = tweak_data.menu.pd2_small_font_size + 2,
			align = "left",
			halign = "top",
			vertical = "top",
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size + 2,
			color = tweak_data.screen_colors.button_stage_3,
			layer = self.layers.items,
			text = ("[" .. (LuaModManager:GetPlayerKeybind("Reconnect_key") or "f1") .."] " .. managers.localization:text("menu_button_reconnect")):upper(),
			wrap = true,
			word_wrap = false
		})
		local _, _, w, _ = self._reconnect_button:text_rect()
		self._reconnect_button:set_w(w+5)
		self._reconnect_button:set_x(buttons:w() - w - tweak_data.menu.info_padding)
		self._reconnect_button:set_y(self._host_button:y() + self._host_button:h() + 4)
	end
	
	HUDBGBox_create(buttons, { w = buttons:w(),	h = buttons:h()})
	local _, _, w, _ = self._sidejobs_button:text_rect()
	self._sidejobs_button:set_w(w)
	local _, _, w, _ = self._casino_button:text_rect()
	self._casino_button:set_w(w)
	local _, _, w, _ = self._filter_button:text_rect()
	self._filter_button:set_w(w)
	local _, _, w, _ = self._refresh_button:text_rect()
	self._refresh_button:set_w(w)
	local _, _, w, _ = self._host_button:text_rect()
	self._host_button:set_w(w)
	self._host_button:set_x(buttons:w() - w - tweak_data.menu.info_padding)
	
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
			local text = row_item.gui_panel:text({
				font_size = tweak_data.menu.server_list_font_size,
				x = row_item.position.x,
				y = 0,
				align = data.align,
				halign = data.align,
				vertical = "center",
				font = row_item.font,
				font_size = math.round(row_item.font_size * 0.77),
				color = (i == 2 and row_item.item:parameters().pro and tweak_data.screen_colors.pro_color or i == 1 and row_item.item:parameters().friend and tweak_data.screen_colors.friend_color or row_item.color),
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
		local difficulty_stars = row_item.item:parameters().difficulty_num
		local start_difficulty = 3
		local num_difficulties = 6
		local spacing = 14
		row_item.difficulty_icons = {}
		for i = start_difficulty, difficulty_stars do
			local skull = row_item.gui_panel:bitmap({
				texture = i == num_difficulties and "guis/textures/pd2/risklevel_deathwish_blackscreen" or "guis/textures/pd2/risklevel_blackscreen",
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
		
		
		
		local level_id = row_item.item:parameters().level_id
		local days = row_item.item:parameters().days
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
			text = utf8.to_upper(row_item.item:parameters().real_level_name) .. " ",
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
			text = utf8.to_upper(managers.localization:text("menu_difficulty_" .. row_item.item:parameters().difficulty)),
			font = tweak_data.menu.pd2_small_font,
			color = tweak_data.hud.prime_color,
			font_size = font_size,
			align = "left",
			vertical = "center",
			w = 256,
			h = font_size,
			layer = 1
		})
        
		row_item.job_plan_text = row_item.gui_info_panel:text({
			name = "job_plan_text",
			text = utf8.to_upper(managers.localization:text("menu_" .. (row_item.item:parameters().job_plan == 1 and "plan_loud" or row_item.item:parameters().job_plan == 2 and "plan_stealth" or "any"))),
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
			text = utf8.to_upper(days),
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
	row_item.difficulty_text:set_w(row_item.gui_info_panel:w())
	row_item.difficulty_text:set_position(math.round(row_item.difficulty_text:x()), math.round(row_item.difficulty_text:y()))
	
	row_item.job_plan_text:set_lefttop(self._job_plan_title:righttop())
	row_item.job_plan_text:set_w(row_item.gui_info_panel:w())
	row_item.job_plan_text:set_position(math.round(row_item.job_plan_text:x()), math.round(row_item.job_plan_text:y()))
    
	local _, _, _, h = row_item.heist_name:text_rect()
	local w = row_item.gui_info_panel:w()
	row_item.heist_name:set_height(h)
	row_item.heist_name:set_w(w - tweak_data.menu.info_padding )
	row_item.heist_briefing:set_w(w - tweak_data.menu.info_padding * 2 )
	row_item.heist_briefing:set_shape(row_item.heist_briefing:text_rect())
	row_item.heist_briefing:set_x(tweak_data.menu.info_padding)
	row_item.heist_briefing:set_y(4 * tweak_data.menu.info_padding + offset * 6)
	row_item.heist_briefing:set_position(math.round(row_item.heist_briefing:x()), math.round(row_item.heist_briefing:y()))
	row_item.heist_briefing:set_h(math.round(tweak_data.menu.pd2_small_font_size * 15.5))
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
			Reconnect:reconnect()
			return true
		elseif self._host_button:inside(x, y) then
			--node:parameters().scene_state = "standard"
			managers.menu:open_node("crimenet_contract_special", {})
			managers.menu_component:disable_crimenet()
			return true
		elseif self._sidejobs_button:inside(x, y) then
			managers.menu:open_node("crimenet_contract_challenge", {})
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
	if managers.menu_component and not managers.menu_component:crimenet_enabled() then return end
	
	local reconnect_key = LuaModManager:GetPlayerKeybind("Reconnect_key") or "f1"
	local type = managers.controller:get_default_wrapper_type()
	local filter_key = managers.controller:get_settings(type):get_connection("menu_toggle_filters"):get_input_name_list()[1] or "f"
	if self._reconnect_button and k == Idstring(reconnect_key) then
	    Reconnect:reconnect()
	elseif k == Idstring(filter_key) and self._filter_button then
		managers.menu:open_node("crimenet_filters", {})
	end
	
	if managers.menu_component then
		managers.menu_component:disable_crimenet()
	end
end

function MenuNodeTableGui:mouse_moved(o, x, y)
	local inside = false
	if self._reconnect_button then
		if self._reconnect_button:inside(x, y) then
			if not self._reconnect_highlighted then
				self._reconnect_highlighted = true
				self._reconnect_button:set_color(tweak_data.screen_colors.button_stage_2)
				managers.menu_component:post_event("highlight")
			end
			inside = true
		else
			self._reconnect_button:set_color(tweak_data.screen_colors.button_stage_3)
			self._reconnect_highlighted = false
		end
	end
	
	if self._host_button:inside(x, y) then
		if not self._host_highlighted then
			self._host_highlighted = true
			self._host_button:set_color(tweak_data.screen_colors.button_stage_2)
			managers.menu_component:post_event("highlight")
		end
		inside = true
	else
		self._host_button:set_color(tweak_data.screen_colors.button_stage_3)
		self._host_highlighted = false
	end
	
	if self._sidejobs_button:inside(x, y) then
		if not self._sidejobs_highlighted then
			self._sidejobs_highlighted = true
			self._sidejobs_button:set_color(tweak_data.screen_colors.button_stage_2)
			managers.menu_component:post_event("highlight")
		end
		inside = true
	else
		self._sidejobs_button:set_color(tweak_data.screen_colors.button_stage_3)
		self._sidejobs_highlighted = false
	end
	
	if self._casino_button:inside(x, y) then
		if not self._casino_highlighted then
			self._casino_highlighted = true
			self._casino_button:set_color(tweak_data.screen_colors.button_stage_2)
			managers.menu_component:post_event("highlight")
		end
		inside = true
	else
		self._casino_button:set_color(tweak_data.screen_colors.button_stage_3)
		self._casino_highlighted = false
	end
	
	if self._filter_button:inside(x, y) then
		if not self._filter_highlighted then
			self._filter_highlighted = true
			self._filter_button:set_color(tweak_data.screen_colors.button_stage_2)
			managers.menu_component:post_event("highlight")
		end
		inside = true
	else
		self._filter_button:set_color(tweak_data.screen_colors.button_stage_3)
		self._filter_highlighted = false
	end
	
	if self._refresh_button:inside(x, y) then
		if not self._refresh_highlighted then
			self._refresh_highlighted = true
			self._refresh_button:set_color(tweak_data.screen_colors.button_stage_2)
			managers.menu_component:post_event("highlight")
		end
		inside = true
	else
		self._refresh_button:set_color(tweak_data.screen_colors.button_stage_3)
		self._refresh_highlighted = false
	end
	
	inside = inside or self._mini_info_text:inside(x, y)
	--self._mouse_over = inside
	return inside, inside and "link"
end

