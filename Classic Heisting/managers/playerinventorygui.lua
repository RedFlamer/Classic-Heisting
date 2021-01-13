local IS_WIN_32 = SystemInfo:platform() == Idstring("WIN32")
local NOT_WIN_32 = not IS_WIN_32
local TOP_ADJUSTMENT = NOT_WIN_32 and 50 or 55
local BOT_ADJUSTMENT = NOT_WIN_32 and 40 or 60

local function make_fine_text(text)
	local x, y, w, h = text:text_rect()

	text:set_size(w, h)
	text:set_position(math.round(text:x()), math.round(text:y()))
end

function PlayerInventoryGui:set_skilltree_stats(panel, data) return end
PlayerInventoryGui._update_info_skilltree = function(self, name)
	local text_string = ""
	text_string = text_string .. managers.localization:text("menu_st_skill_switch_set", {skill_switch = managers.skilltree:get_skill_switch_name(managers.skilltree:get_selected_skill_switch(), true)}) .. "\n "
	local tree_to_string_id = {mastermind = "st_menu_mastermind", enforcer = "st_menu_enforcer", technician = "st_menu_technician", ghost = "st_menu_ghost", hoxton = "st_menu_hoxton_pack"}
	text_string = text_string .. "\n"
	for i,tree in ipairs({"mastermind", "enforcer", "technician", "ghost", "hoxton"}) do
		local points, progress, num_skills = managers.skilltree:get_tree_progress_new(tree)
		points = string.format("%02d", points)
		text_string = text_string .. managers.localization:to_upper_text("menu_profession_progress", {profession = managers.localization:to_upper_text(tree_to_string_id[tree]), progress = points, num_skills = num_skills}) .. "\n"
	end
	self:set_info_text(text_string)
end

function PlayerInventoryGui:init(ws, fullscreen_ws, node)
	self._ws = ws
	self._fullscreen_ws = fullscreen_ws
	self._node = node
	self._panel = self._ws:panel():panel()
	self._fullscreen_panel = self._fullscreen_ws:panel():panel()
	self._show_all_panel = self._ws:panel():panel({
		visible = false,
		w = self._ws:panel():w() * 0.75,
		h = tweak_data.menu.pd2_medium_font_size
	})

	self._show_all_panel:set_righttop(self._ws:panel():w(), 0)

	local show_all_text = self._show_all_panel:text({
		blend_mode = "add",
		text = managers.localization:to_upper_text(managers.menu:is_pc_controller() and "menu_show_all" or "menu_legend_show_all", {
			BTN_X = managers.localization:btn_macro("menu_toggle_voice_message")
		}),
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size
	})

	make_fine_text(show_all_text)
	show_all_text:set_right(self._show_all_panel:w())
	show_all_text:set_center_y(self._show_all_panel:h() / 2)

	if not managers.menu:is_pc_controller() then
		self._show_all_panel:set_bottom(self._ws:panel():h())
	end

	show_all_text:set_world_position(math.round(show_all_text:world_x()), math.round(show_all_text:world_y()))

	self._boxes = {}
	self._boxes_by_name = {}
	self._boxes_by_layer = {}
	self._mod_boxes = {}
	self._max_layer = 1
	self._data = node:parameters().menu_component_data or {
		selected_box = "character"
	}
	self._node:parameters().menu_component_data = self._data
	self._input_focus = 1

	WalletGuiObject.set_wallet(self._panel)

	local y = TOP_ADJUSTMENT
	local title_string = "menu_player_inventory"
	local title_text = self._panel:text({
		name = "title",
		layer = 1,
		text = managers.localization:to_upper_text(title_string),
		font = tweak_data.menu.pd2_large_font,
		font_size = tweak_data.menu.pd2_large_font_size,
		color = tweak_data.screen_colors.text
	})

	make_fine_text(title_text)

	local back_button = self._panel:text({
		vertical = "bottom",
		name = "back_button",
		align = "right",
		layer = 1,
		text = managers.localization:to_upper_text("menu_back"),
		font = tweak_data.menu.pd2_large_font,
		font_size = tweak_data.menu.pd2_large_font_size,
		color = tweak_data.screen_colors.button_stage_3
	})

	make_fine_text(back_button)
	back_button:set_right(self._panel:w())
	back_button:set_bottom(self._panel:h())
	back_button:set_visible(managers.menu:is_pc_controller())

	if MenuBackdropGUI then
		local massive_font = tweak_data.menu.pd2_massive_font
		local massive_font_size = tweak_data.menu.pd2_massive_font_size
		local bg_text = self._fullscreen_panel:text({
			vertical = "top",
			h = 90,
			align = "left",
			alpha = 0.4,
			text = title_text:text(),
			font = massive_font,
			font_size = massive_font_size,
			color = tweak_data.screen_colors.button_stage_3
		})
		local x, y = managers.gui_data:safe_to_full_16_9(title_text:world_x(), title_text:world_center_y())

		bg_text:set_world_left(x)
		bg_text:set_world_center_y(y)
		bg_text:move(-13, 9)
		MenuBackdropGUI.animate_bg_text(self, bg_text)

		if managers.menu:is_pc_controller() then
			local bg_back = self._fullscreen_panel:text({
				name = "back_button",
				vertical = "bottom",
				h = 90,
				alpha = 0.4,
				align = "right",
				layer = 0,
				text = back_button:text(),
				font = massive_font,
				font_size = massive_font_size,
				color = tweak_data.screen_colors.button_stage_3
			})
			local x, y = managers.gui_data:safe_to_full_16_9(back_button:world_right(), back_button:world_center_y())

			bg_back:set_world_right(x)
			bg_back:set_world_center_y(y)
			bg_back:move(13, -9)
			MenuBackdropGUI.animate_bg_text(self, bg_back)
		end
	end

	local padding_x = 10
	local padding_y = 0
	local x = self._panel:w() - 500
	local y = TOP_ADJUSTMENT + tweak_data.menu.pd2_small_font_size
	local width = self._panel:w() - x
	local height = 540
	local combined_width = width - padding_x * 2
	local combined_height = height - padding_y * 3
	local box_width = combined_width / 3
	local box_height = combined_height / 4
	local player_loadout_data = managers.blackmarket:player_loadout_data()
	local primary_box = self:create_box({
		name = "primary",
		bg_blend_mode = "normal",
		w = box_width,
		h = box_height,
		unselected_text = managers.localization:to_upper_text("bm_menu_primaries"),
		text = player_loadout_data.primary.info_text,
		image = player_loadout_data.primary.item_texture,
		bg_image = player_loadout_data.primary.item_bg_texture,
		text_selected_color = player_loadout_data.primary.info_text_color,
		use_background = player_loadout_data.primary.item_bg_texture and true or false,
		akimbo_gui_data = player_loadout_data.primary.akimbo_gui_data,
		select_anim = select_anim,
		unselect_anim = unselect_anim,
		bg_color = Color.white:with_alpha(0.75),
		clbks = {
			left = callback(self, self, "open_primary_menu"),
			right = callback(self, self, "preview_primary"),
			up = callback(self, self, "previous_primary"),
			down = callback(self, self, "next_primary")
		}
	})
	local secondary_box = self:create_box({
		name = "secondary",
		bg_blend_mode = "normal",
		w = box_width,
		h = box_height,
		unselected_text = managers.localization:to_upper_text("bm_menu_secondaries"),
		text = player_loadout_data.secondary.info_text,
		image = player_loadout_data.secondary.item_texture,
		bg_image = player_loadout_data.secondary.item_bg_texture,
		text_selected_color = player_loadout_data.secondary.info_text_color,
		use_background = player_loadout_data.secondary.item_bg_texture and true or false,
		akimbo_gui_data = player_loadout_data.secondary.akimbo_gui_data,
		select_anim = select_anim,
		unselect_anim = unselect_anim,
		bg_color = Color.white:with_alpha(0.75),
		clbks = {
			left = callback(self, self, "open_secondary_menu"),
			right = callback(self, self, "preview_secondary"),
			up = callback(self, self, "previous_secondary"),
			down = callback(self, self, "next_secondary")
		}
	})
	local melee_box = self:create_box({
		name = "melee",
		bg_blend_mode = "normal",
		w = box_width,
		h = box_height,
		unselected_text = managers.localization:to_upper_text("bm_menu_melee_weapons"),
		text = player_loadout_data.melee_weapon.info_text,
		image = player_loadout_data.melee_weapon.item_texture,
		dual_image = not player_loadout_data.melee_weapon.item_texture and {
			player_loadout_data.melee_weapon.dual_texture_1,
			player_loadout_data.melee_weapon.dual_texture_2
		},
		select_anim = select_anim,
		unselect_anim = unselect_anim,
		bg_color = Color.black:with_alpha(0.05),
		clbks = {
			left = callback(self, self, "open_melee_menu"),
			right = callback(self, self, "preview_melee"),
			up = callback(self, self, "previous_melee"),
			down = callback(self, self, "next_melee")
		}
	})
	local throwable_box = self:create_box({
		name = "throwable",
		bg_blend_mode = "normal",
		w = box_width,
		h = box_height,
		unselected_text = managers.localization:to_upper_text("bm_menu_grenades"),
		text = player_loadout_data.grenade.info_text,
		image = player_loadout_data.grenade.item_texture,
		select_anim = select_anim,
		unselect_anim = unselect_anim,
		bg_color = Color.black:with_alpha(0.05),
		clbks = {
			left = callback(self, self, "open_throwable_menu"),
			right = callback(self, self, "preview_throwable"),
			up = callback(self, self, "previous_throwable"),
			down = callback(self, self, "next_throwable")
		}
	})
	local armor_box = self:create_box({
		name = "armor",
		redirect_box = "outfit_armor",
		can_select = false,
		bg_blend_mode = "normal",
		w = box_width,
		h = box_height,
		unselected_text = managers.localization:to_upper_text("bm_menu_armors"),
		select_anim = select_anim,
		unselect_anim = unselect_anim,
		bg_color = Color.black:with_alpha(0.05),
		clbks = {
			create = callback(self, self, "create_outfit_box")
		},
		data = player_loadout_data.outfit
	})
	local deployable_box = self:create_box({
		name = "deployable",
		redirect_box = "deployable_primary",
		can_select = false,
		bg_blend_mode = "normal",
		w = box_width,
		h = box_height,
		unselected_text = managers.localization:to_upper_text("bm_menu_deployables"),
		select_anim = select_anim,
		unselect_anim = unselect_anim,
		bg_color = Color.black:with_alpha(0.05),
		clbks = {
			create = callback(self, self, "create_deployable_box")
		},
		data = player_loadout_data.deployable
	})
	local mask_box = self:create_box({
		name = "mask",
		bg_blend_mode = "normal",
		w = box_width,
		h = box_height,
		unselected_text = managers.localization:to_upper_text("bm_menu_masks"),
		text = player_loadout_data.mask.info_text,
		image = player_loadout_data.mask.item_texture,
		select_anim = select_anim,
		unselect_anim = unselect_anim,
		bg_color = Color.black:with_alpha(0.05),
		clbks = {
			left = callback(self, self, "open_mask_menu"),
			right = callback(self, self, "preview_mask"),
			up = callback(self, self, "previous_mask"),
			down = callback(self, self, "next_mask")
		}
	})
	local character_box = self:create_box({
		name = "character",
		bg_blend_mode = "normal",
		w = box_width,
		h = box_height,
		unselected_text = managers.localization:to_upper_text("menu_preferred_character"),
		text = player_loadout_data.character.info_text,
		image = player_loadout_data.character.item_texture,
		alpha = managers.network:session() and 0.2 or 1,
		select_anim = select_anim,
		unselect_anim = unselect_anim,
		bg_color = Color.black:with_alpha(0.05),
		clbks = managers.network:session() and {
			right = false
		} or {
			right = false,
			left = callback(self, self, "open_character_menu"),
			up = callback(self, self, "previous_character"),
			down = callback(self, self, "next_character")
		}
	})
	local infamy_box = self:create_box({
		name = "infamy",
		bg_blend_mode = "normal",
		w = box_width,
		h = box_height,
		unselected_text = managers.localization:to_upper_text("menu_infamytree"),
		text = managers.localization:to_upper_text("menu_infamytree"),
		alpha = managers.network:session() and 0.2 or 1,
		select_anim = select_anim,
		unselect_anim = unselect_anim,
		bg_color = Color.black:with_alpha(0.05),
		clbks = managers.network:session() and {
			right = false
		} or {
			down = false,
			up = false,
			right = false,
			left = callback(self, self, "open_infamy_menu")
		}
	})
	local crew_box = self:create_box({
		image = "guis/dlcs/mom/textures/pd2/crewmanagement_icon",
		name = "infamy",
		bg_blend_mode = "normal",
		w = box_width,
		h = box_height,
		unselected_text = managers.localization:to_upper_text("menu_crew_management"),
		text = managers.localization:to_upper_text("menu_crew_management"),
		select_anim = select_anim,
		unselect_anim = unselect_anim,
		bg_color = Color.black:with_alpha(0.05),
		clbks = {
			down = false,
			up = false,
			right = false,
			left = callback(self, self, "open_crew_menu")
		}
	})
	local skill_box = self:create_box({
		image = false,
		name = "skilltree",
		bg_blend_mode = "normal",
		w = box_width,
		h = box_height,
		unselected_text = managers.localization:to_upper_text("menu_st_skilltree"),
		text = managers.localization:text("menu_st_skill_switch_set", {
			skill_switch = managers.skilltree:get_skill_switch_name(managers.skilltree:get_selected_skill_switch(), true)
		}),
		select_anim = select_anim,
		unselect_anim = unselect_anim,
		bg_color = Color.black:with_alpha(0.05),
		clbks = {
			right = false,
			left = callback(self, self, "open_skilltree_menu"),
			up = callback(self, self, "previous_skilltree"),
			down = callback(self, self, "next_skilltree")
		}
	})
	local texture_rect_x = 0
	local texture_rect_y = 0
	local current_specialization = managers.skilltree:get_specialization_value("current_specialization")
	local specialization_data = tweak_data.skilltree.specializations[current_specialization]
	local specialization_text = specialization_data and managers.localization:text(specialization_data.name_id) or " "
	local guis_catalog = "guis/"

	if specialization_data then
		local current_tier = managers.skilltree:get_specialization_value(current_specialization, "tiers", "current_tier")
		local max_tier = managers.skilltree:get_specialization_value(current_specialization, "tiers", "max_tier")
		local tier_data = specialization_data[max_tier]

		if tier_data then
			texture_rect_x = tier_data.icon_xy and tier_data.icon_xy[1] or 0
			texture_rect_y = tier_data.icon_xy and tier_data.icon_xy[2] or 0

			if tier_data.texture_bundle_folder then
				guis_catalog = guis_catalog .. "dlcs/" .. tostring(tier_data.texture_bundle_folder) .. "/"
			end

			specialization_text = specialization_text .. " (" .. tostring(current_tier) .. "/" .. tostring(max_tier) .. ")"
		end
	end

	local icon_atlas_texture = guis_catalog .. "textures/pd2/specialization/icons_atlas"
	local specialization_box = self:create_box({
		name = "skilltree",
		bg_blend_mode = "normal",
		image_size_mul = 0.8,
		w = 0,
		h = 0,
		unselected_text = managers.localization:to_upper_text("menu_specialization"),
		text = specialization_text,
		image = icon_atlas_texture,
		image_rect = {
			texture_rect_x * 64,
			texture_rect_y * 64,
			64,
			64
		},
		select_anim = select_anim,
		unselect_anim = unselect_anim,
		bg_color = Color.black:with_alpha(0.05),
		clbks = {
			right = false,
			left = callback(self, self, "open_specialization_menu"),
			up = callback(self, self, "previous_specialization"),
			down = callback(self, self, "next_specialization")
		}
	})
	local box_matrix = {
		{
			"character",
			"primary",
			"skilltree"
		},
		{
			"mask",
			"secondary",
			"infamy"
		},
		{
			"armor",
			"throwable"
		},
		{
			"deployable",
			"melee"
		}
	}

	self:sort_boxes_by_matrix(box_matrix)

	local character_panel = self._panel:panel({
		name = "character_panel"
	})
	local weapons_panel = self._panel:panel({
		name = "weapons_panel"
	})
	local eqpt_skills_panel = self._panel:panel({
		name = "eqpt_skills_panel"
	})

	local function get_matrix_column_boxes(column)
		local boxes = {}

		for _, row in ipairs(box_matrix) do
			if row[column] and self._boxes_by_name[row[column]] then
				table.insert(boxes, self._boxes_by_name[row[column]])
			end
		end

		return boxes
	end

	for i, column_panel in ipairs({
		character_panel,
		weapons_panel,
		eqpt_skills_panel
	}) do
		local boxes = get_matrix_column_boxes(i)

		if #boxes > 0 then
			local first = boxes[1].panel
			local last = boxes[#boxes].panel

			column_panel:set_shape(first:left(), first:top(), box_width, last:bottom() - first:top())
		end
	end

	character_panel:rect({
		alpha = 0.4,
		color = Color.black
	})
	weapons_panel:rect({
		alpha = 0.4,
		color = Color.black
	})
	eqpt_skills_panel:rect({
		alpha = 0.4,
		color = Color.black
	})

	local column_one_box_panel = self._panel:panel({
		name = "column_one_box_panel"
	})

	column_one_box_panel:set_shape(character_panel:shape())

	local column_two_box_panel = self._panel:panel({
		name = "column_two_box_panel"
	})

	column_two_box_panel:set_shape(weapons_panel:shape())

	local column_three_box_panel = self._panel:panel({
		name = "column_three_box_panel"
	})

	column_three_box_panel:set_shape(eqpt_skills_panel:shape())

	self._column_one_box = BoxGuiObject:new(column_one_box_panel, {
		sides = {
			1,
			1,
			2,
			2
		}
	})
	self._column_two_box = BoxGuiObject:new(column_two_box_panel, {
		sides = {
			1,
			1,
			2,
			2
		}
	})
	self._column_three_box = BoxGuiObject:new(column_three_box_panel, {
		sides = {
			1,
			1,
			2,
			2
		}
	})
	local character_text = self._panel:text({
		name = "character_text",
		blend_mode = "add",
		text = managers.localization:to_upper_text("menu_player_column_one_title"),
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size,
		color = tweak_data.screen_colors.text
	})
	local weapons_text = self._panel:text({
		name = "weapons_text",
		blend_mode = "add",
		text = managers.localization:to_upper_text("menu_player_column_two_title"),
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size,
		color = tweak_data.screen_colors.text
	})
	local eqpt_skills_text = self._panel:text({
		name = "eqpt_skills_text",
		blend_mode = "add",
		text = managers.localization:to_upper_text("menu_player_column_three_title"),
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size,
		color = tweak_data.screen_colors.text
	})

	make_fine_text(character_text)
	make_fine_text(weapons_text)
	make_fine_text(eqpt_skills_text)
	character_text:set_rightbottom(character_panel:right(), character_panel:top())
	weapons_text:set_rightbottom(weapons_panel:right(), weapons_panel:top())
	eqpt_skills_text:set_rightbottom(eqpt_skills_panel:right(), eqpt_skills_panel:top())

	local alias_text = self._panel:text({
		name = "alias_text",
		blend_mode = "add",
		x = 2,
		y = TOP_ADJUSTMENT,
		text = tostring(managers.network.account:username() or managers.blackmarket:get_preferred_character_real_name()),
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size,
		color = tweak_data.screen_colors.text
	})

	make_fine_text(alias_text)

	local player_panel = self._panel:panel({
		name = "player_panel",
		h = 290,
		w = 320,
		x = 0,
		y = TOP_ADJUSTMENT + tweak_data.menu.pd2_small_font_size
	})
	self._player_panel = player_panel

	self._player_panel:rect({
		alpha = 0.4,
		layer = -100,
		color = Color.black
	})

	self._player_box_panel = self._panel:panel({
		name = "player_box_panel"
	})

	self._player_box_panel:set_shape(player_panel:shape())

	self._player_box = BoxGuiObject:new(self._player_box_panel, {
		sides = {
			1,
			1,
			2,
			1
		}
	})
	local next_level_data = managers.experience:next_level_data() or {}
	local player_level = managers.experience:current_level()
	local player_rank = managers.experience:current_rank()
	local is_infamous = player_rank > 0
	local size = 96
	local player_level_panel = player_panel:panel({
		name = "player_level_panel",
		y = 10,
		x = 10,
		w = size,
		h = size
	})

	player_level_panel:bitmap({
		texture = "guis/textures/pd2/endscreen/exp_ring",
		alpha = 0.4,
		texture_rect = {
			16,
			16,
			224,
			224
		},
		w = size,
		h = size,
		color = Color.white
	})
	player_level_panel:bitmap({
		texture = "guis/textures/pd2/endscreen/exp_ring",
		layer = 1,
		blend_mode = "add",
		render_template = "VertexColorTexturedRadial",
		texture_rect = {
			16,
			16,
			224,
			224
		},
		color = Color((next_level_data.current_points or 1) / (next_level_data.points or 1), 1, 1),
		w = size,
		h = size
	})
	player_level_panel:text({
		vertical = "center",
		align = "center",
		text = tostring(player_level),
		font = tweak_data.menu.pd2_medium_font,
		font_size = tweak_data.menu.pd2_medium_font_size
	})

	local detection_panel = player_panel:panel({
		name = "detection_panel",
		x = 0,
		layer = 0,
		y = player_level_panel:top(),
		w = size - tweak_data.menu.pd2_small_font_size * 2,
		h = size - tweak_data.menu.pd2_small_font_size * 2
	})
	local detection_ring_left_bg = detection_panel:bitmap({
		blend_mode = "add",
		name = "detection_left_bg",
		alpha = 0.2,
		texture = "guis/textures/pd2/blackmarket/inv_detection_meter",
		layer = 0,
		w = detection_panel:w(),
		h = detection_panel:h()
	})
	local detection_ring_right_bg = detection_panel:bitmap({
		blend_mode = "add",
		name = "detection_right_bg",
		alpha = 0.2,
		texture = "guis/textures/pd2/blackmarket/inv_detection_meter",
		layer = 0,
		w = detection_panel:w(),
		h = detection_panel:h()
	})

	detection_ring_right_bg:set_texture_rect(64, 0, -64, 64)

	local detection_ring_left = detection_panel:bitmap({
		texture = "guis/textures/pd2/blackmarket/inv_detection_meter",
		name = "detection_left",
		alpha = 0.5,
		blend_mode = "add",
		render_template = "VertexColorTexturedRadial",
		layer = 1,
		w = detection_panel:w(),
		h = detection_panel:h()
	})
	local detection_ring_right = detection_panel:bitmap({
		texture = "guis/textures/pd2/blackmarket/inv_detection_meter",
		name = "detection_right",
		alpha = 0.5,
		blend_mode = "add",
		render_template = "VertexColorTexturedRadial",
		layer = 1,
		w = detection_panel:w(),
		h = detection_panel:h()
	})

	detection_ring_right:set_texture_rect(64, 0, -64, 64)

	local detection_ring_left2 = detection_panel:bitmap({
		texture = "guis/textures/pd2/blackmarket/inv_detection_meter",
		name = "detection_left2",
		alpha = 0.5,
		blend_mode = "add",
		render_template = "VertexColorTexturedRadial",
		layer = 1,
		w = detection_panel:w(),
		h = detection_panel:h()
	})
	local detection_ring_right2 = detection_panel:bitmap({
		texture = "guis/textures/pd2/blackmarket/inv_detection_meter",
		name = "detection_right2",
		alpha = 0.5,
		blend_mode = "add",
		render_template = "VertexColorTexturedRadial",
		layer = 1,
		w = detection_panel:w(),
		h = detection_panel:h()
	})

	detection_ring_right2:set_texture_rect(64, 0, -64, 64)

	local detection_value = detection_panel:text({
		alpha = 1,
		name = "detection_value",
		h = 64,
		text = "",
		w = 64,
		blend_mode = "add",
		visible = true,
		font = tweak_data.menu.pd2_medium_font,
		font_size = tweak_data.menu.pd2_medium_font_size
	})
	local detection_text = player_panel:text({
		name = "detection_text",
		alpha = 1,
		visible = true,
		blend_mode = "add",
		y = player_level_panel:top(),
		text = managers.localization:to_upper_text("bm_menu_stats_detection"),
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size
	})

	make_fine_text(detection_text)
	detection_text:set_right(player_panel:w() - 10)
	detection_panel:set_center_x(detection_text:center_x())
	detection_panel:set_right(math.min(detection_panel:right(), detection_text:right()))
	detection_panel:set_top(detection_text:bottom() + 5)

	self._player_stats_panel = player_panel:panel({
		name = "player_stats_panel",
		x = 10,
		h = 160,
		w = player_panel:w() - 20
	})

	self._player_stats_panel:set_bottom(player_panel:h() - 10)
	self:setup_player_stats(self._player_stats_panel)

	local info_panel = self._panel:panel({
		name = "info_panel",
		x = 0,
		y = player_panel:bottom() + 10,
		w = player_panel:w(),
		h = self._panel:h() - player_panel:top() - BOT_ADJUSTMENT - player_panel:h() - 10
	})

	BoxGuiObject:new(info_panel, {
		sides = {
			1,
			1,
			1,
			1
		}
	})
	info_panel:rect({
		alpha = 0.4,
		layer = -100,
		color = Color.black
	})

	local info_content_panel = info_panel:panel({
		layer = 1
	})

	info_content_panel:grow(-20, -20)
	info_content_panel:move(10, 10)

	self._info_text = info_content_panel:text({
		text = "",
		wrap = true,
		word_wrap = true,
		blend_mode = "add",
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size,
		color = tweak_data.screen_colors.text
	})
	self._info_panel = info_content_panel:panel({
		layer = 1
	})

	self:set_info_text("")

	self._legends_panel = self._panel:panel({
		name = "legends_panel",
		w = self._panel:w() * 0.75,
		h = tweak_data.menu.pd2_medium_font_size
	})
	self._legends = {}

	if managers.menu:is_pc_controller() then
		self._legends_panel:set_righttop(self._panel:w(), 0)

		if not managers.menu:is_steam_controller() then
			local panel = self._legends_panel:panel({
				visible = false,
				name = "select"
			})
			local icon = panel:bitmap({
				texture = "guis/textures/pd2/mouse_buttons",
				name = "icon",
				h = 23,
				blend_mode = "add",
				w = 17,
				texture_rect = {
					1,
					1,
					17,
					23
				}
			})
			local text = panel:text({
				blend_mode = "add",
				text = managers.localization:to_upper_text("menu_mouse_select"),
				font = tweak_data.menu.pd2_small_font,
				font_size = tweak_data.menu.pd2_small_font_size,
				color = tweak_data.screen_colors.text
			})

			make_fine_text(text)
			text:set_left(icon:right() + 2)
			text:set_center_y(icon:center_y())
			panel:set_w(text:right())

			self._legends.select = panel
			local panel = self._legends_panel:panel({
				visible = false,
				name = "preview"
			})
			local icon = panel:bitmap({
				texture = "guis/textures/pd2/mouse_buttons",
				name = "icon",
				h = 23,
				blend_mode = "add",
				w = 17,
				texture_rect = {
					18,
					1,
					17,
					23
				}
			})
			local text = panel:text({
				blend_mode = "add",
				text = managers.localization:to_upper_text("menu_mouse_preview"),
				font = tweak_data.menu.pd2_small_font,
				font_size = tweak_data.menu.pd2_small_font_size,
				color = tweak_data.screen_colors.text
			})

			make_fine_text(text)
			text:set_left(icon:right() + 2)
			text:set_center_y(icon:center_y())
			panel:set_w(text:right())

			self._legends.preview = panel
			local panel = self._legends_panel:panel({
				visible = false,
				name = "switch"
			})
			local icon = panel:bitmap({
				texture = "guis/textures/pd2/mouse_buttons",
				name = "icon",
				h = 23,
				blend_mode = "add",
				w = 17,
				texture_rect = {
					35,
					1,
					17,
					23
				}
			})
			local text = panel:text({
				blend_mode = "add",
				text = managers.localization:to_upper_text("menu_mouse_switch"),
				font = tweak_data.menu.pd2_small_font,
				font_size = tweak_data.menu.pd2_small_font_size,
				color = tweak_data.screen_colors.text
			})

			make_fine_text(text)
			text:set_left(icon:right() + 2)
			text:set_center_y(icon:center_y())
			panel:set_w(text:right())

			self._legends.switch = panel
		else
			local panel = self._legends_panel:panel({
				visible = false,
				name = "select"
			})
			local text = panel:text({
				blend_mode = "add",
				text = managers.localization:steam_btn("grip_l") .. " " .. managers.localization:to_upper_text("menu_mouse_select"),
				font = tweak_data.menu.pd2_small_font,
				font_size = tweak_data.menu.pd2_small_font_size,
				color = tweak_data.screen_colors.text
			})

			make_fine_text(text)
			text:set_center_y(panel:h() / 2)
			panel:set_w(text:right())

			self._legends.select = panel
			local panel = self._legends_panel:panel({
				visible = false,
				name = "preview"
			})
			local text = panel:text({
				blend_mode = "add",
				text = managers.localization:steam_btn("grip_r") .. " " .. managers.localization:to_upper_text("menu_mouse_preview"),
				font = tweak_data.menu.pd2_small_font,
				font_size = tweak_data.menu.pd2_small_font_size,
				color = tweak_data.screen_colors.text
			})

			make_fine_text(text)
			text:set_center_y(panel:h() / 2)
			panel:set_w(text:right())

			self._legends.preview = panel
			local panel = self._legends_panel:panel({
				visible = false,
				name = "switch"
			})
			local text = panel:text({
				blend_mode = "add",
				text = managers.localization:btn_macro("previous_page") .. managers.localization:btn_macro("next_page") .. " " .. managers.localization:to_upper_text("menu_mouse_switch"),
				font = tweak_data.menu.pd2_small_font,
				font_size = tweak_data.menu.pd2_small_font_size,
				color = tweak_data.screen_colors.text
			})

			make_fine_text(text)
			text:set_center_y(panel:h() / 2)
			panel:set_w(text:right())

			self._legends.switch = panel
		end

		local panel = self._legends_panel:panel({
			visible = false,
			name = "hide_all"
		})
		local text = panel:text({
			blend_mode = "add",
			text = managers.localization:to_upper_text("menu_hide_all", {
				BTN_X = managers.localization:btn_macro("menu_toggle_voice_message")
			}),
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size,
			color = tweak_data.screen_colors.text
		})

		make_fine_text(text)
		text:set_center_y(panel:h() / 2)
		panel:set_w(text:right())

		self._legends.hide_all = panel
	else
		self._legends_panel:set_righttop(self._panel:w(), 0)
		self._legends_panel:text({
			text = "",
			name = "text",
			vertical = "bottom",
			align = "right",
			blend_mode = "add",
			halign = "right",
			valign = "bottom",
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size,
			color = tweak_data.screen_colors.text
		})
	end

	self._text_buttons = {}
	local alias_show_button, alias_hide_button, column_one_show_button, column_one_hide_button, column_two_show_button, column_two_hide_button, column_three_show_button, column_three_hide_button = nil

	local function alias_hide_func()
		if alive(alias_show_button) then
			alias_show_button:hide()
		end

		if alive(alias_hide_button) then
			alias_hide_button:show()
		end

		if alive(self._player_panel) then
			self._player_panel:hide()
		end

		if alive(self._player_box_panel) then
			self._player_box:create_sides(self._player_box_panel, {
				sides = {
					0,
					0,
					2,
					0
				}
			})
		end

		if alive(info_panel) then
			info_panel:hide()
		end
	end

	local function alias_show_func()
		if alive(alias_show_button) then
			alias_show_button:show()
		end

		if alive(alias_hide_button) then
			alias_hide_button:hide()
		end

		if alive(self._player_panel) then
			self._player_panel:show()
		end

		if alive(self._player_box_panel) then
			self._player_box:create_sides(self._player_box_panel, {
				sides = {
					1,
					1,
					2,
					1
				}
			})
		end

		if alive(info_panel) then
			info_panel:show()
		end
	end

	local function column_one_hide_func()
		if alive(column_one_show_button) then
			column_one_show_button:hide()
		end

		if alive(column_one_hide_button) then
			column_one_hide_button:show()
		end

		if alive(character_panel) then
			character_panel:hide()
		end

		if alive(column_one_box_panel) then
			self._column_one_box:create_sides(column_one_box_panel, {
				sides = {
					0,
					0,
					2,
					0
				}
			})
		end

		local box = nil

		for _, boxes in ipairs(box_matrix) do
			box = boxes[1] and self._boxes_by_name[boxes[1]]

			if box then
				box.panel:hide()
			end
		end
	end

	local function column_one_show_func()
		if alive(column_one_show_button) then
			column_one_show_button:show()
		end

		if alive(column_one_hide_button) then
			column_one_hide_button:hide()
		end

		if alive(character_panel) then
			character_panel:show()
		end

		if alive(column_one_box_panel) then
			self._column_one_box:create_sides(column_one_box_panel, {
				sides = {
					1,
					1,
					2,
					1
				}
			})
		end

		local box = nil

		for _, boxes in ipairs(box_matrix) do
			box = boxes[1] and self._boxes_by_name[boxes[1]]

			if box then
				box.panel:show()
			end
		end
	end

	local function column_two_hide_func()
		if alive(column_two_show_button) then
			column_two_show_button:hide()
		end

		if alive(column_two_hide_button) then
			column_two_hide_button:show()
		end

		if alive(weapons_panel) then
			weapons_panel:hide()
		end

		if alive(column_two_box_panel) then
			self._column_two_box:create_sides(column_two_box_panel, {
				sides = {
					0,
					0,
					2,
					0
				}
			})
		end

		local box = nil

		for _, boxes in ipairs(box_matrix) do
			box = boxes[2] and self._boxes_by_name[boxes[2]]

			if box then
				box.panel:hide()
			end
		end

		for _, box in ipairs(self._boxes_by_layer[2]) do
			box.panel:hide()
		end
	end

	local function column_two_show_func()
		if alive(column_two_show_button) then
			column_two_show_button:show()
		end

		if alive(column_two_hide_button) then
			column_two_hide_button:hide()
		end

		if alive(weapons_panel) then
			weapons_panel:show()
		end

		if alive(column_two_box_panel) then
			self._column_two_box:create_sides(column_two_box_panel, {
				sides = {
					1,
					1,
					2,
					1
				}
			})
		end

		local box = nil

		for _, boxes in ipairs(box_matrix) do
			box = boxes[2] and self._boxes_by_name[boxes[2]]

			if box then
				box.panel:show()
			end
		end

		for _, box in ipairs(self._boxes_by_layer[2]) do
			box.panel:show()
		end
	end

	local function column_three_hide_func()
		if alive(column_three_show_button) then
			column_three_show_button:hide()
		end

		if alive(column_three_hide_button) then
			column_three_hide_button:show()
		end

		if alive(eqpt_skills_panel) then
			eqpt_skills_panel:hide()
		end

		if alive(column_three_box_panel) then
			self._column_three_box:create_sides(column_three_box_panel, {
				sides = {
					0,
					0,
					2,
					0
				}
			})
		end

		local box = nil

		for _, boxes in ipairs(box_matrix) do
			box = boxes[3] and self._boxes_by_name[boxes[3]]

			if box then
				box.panel:hide()
			end
		end

		for _, box in ipairs(self._boxes_by_layer[3]) do
			if alive(box.panel) then
				box.panel:hide()
			end
		end
	end

	local function column_three_show_func()
		if alive(column_three_show_button) then
			column_three_show_button:show()
		end

		if alive(column_three_hide_button) then
			column_three_hide_button:hide()
		end

		if alive(eqpt_skills_panel) then
			eqpt_skills_panel:show()
		end

		if alive(column_three_box_panel) then
			self._column_three_box:create_sides(column_three_box_panel, {
				sides = {
					1,
					1,
					2,
					1
				}
			})
		end

		local box = nil

		for _, boxes in ipairs(box_matrix) do
			box = boxes[3] and self._boxes_by_name[boxes[3]]

			if box then
				box.panel:show()
			end
		end

		for _, box in ipairs(self._boxes_by_layer[3]) do
			if alive(box.panel) then
				box.panel:show()
			end
		end
	end

	self._show_hide_data = {
		panels = {
			self._player_panel,
			character_panel,
			weapons_panel,
			eqpt_skills_panel
		},
		show_funcs = {
			alias_show_func,
			column_one_show_func,
			column_two_show_func,
			column_three_show_func
		},
		hide_funcs = {
			alias_hide_func,
			column_one_hide_func,
			column_two_hide_func,
			column_three_hide_func
		}
	}

	if managers.menu:is_pc_controller() then
		local show_string = managers.localization:to_upper_text("menu_button_hide")
		local hide_string = managers.localization:to_upper_text("menu_button_show")
		alias_show_button = self:create_text_button({
			alpha = 0.1,
			left = alias_text:right() + 2,
			top = alias_text:top(),
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size,
			text = show_string,
			clbk = alias_hide_func
		})
		alias_hide_button = self:create_text_button({
			disabled = true,
			left = alias_show_button:left(),
			top = alias_show_button:top(),
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size,
			text = hide_string,
			clbk = alias_show_func
		})
		column_one_show_button = self:create_text_button({
			alpha = 0.1,
			right = character_text:left() - 2,
			top = character_text:top(),
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size,
			text = show_string,
			clbk = column_one_hide_func
		})
		column_one_hide_button = self:create_text_button({
			disabled = true,
			right = column_one_show_button:right(),
			top = column_one_show_button:top(),
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size,
			text = hide_string,
			clbk = column_one_show_func
		})
		column_two_show_button = self:create_text_button({
			alpha = 0.1,
			right = weapons_text:left() - 2,
			top = weapons_text:top(),
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size,
			text = show_string,
			clbk = column_two_hide_func
		})
		column_two_hide_button = self:create_text_button({
			disabled = true,
			right = column_two_show_button:right(),
			top = column_two_show_button:top(),
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size,
			text = hide_string,
			clbk = column_two_show_func
		})
		column_three_show_button = self:create_text_button({
			alpha = 0.1,
			right = eqpt_skills_text:left() - 2,
			top = eqpt_skills_text:top(),
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size,
			text = show_string,
			clbk = column_three_hide_func
		})
		column_three_hide_button = self:create_text_button({
			disabled = true,
			right = column_three_show_button:right(),
			top = column_three_show_button:top(),
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size,
			text = hide_string,
			clbk = column_three_show_func
		})
		local alias_big_panel = self._panel:panel({
			name = "alias_big_panel"
		})

		alias_big_panel:set_w(self._player_panel:w())
		alias_big_panel:set_x(self._player_panel:x())

		local column_one_big_panel = self._panel:panel({
			name = "column_one_big_panel"
		})

		column_one_big_panel:set_w(character_panel:w())
		column_one_big_panel:set_x(character_panel:x())

		local column_two_big_panel = self._panel:panel({
			name = "column_two_big_panel"
		})

		column_two_big_panel:set_w(weapons_panel:w())
		column_two_big_panel:set_x(weapons_panel:x())

		local column_three_big_panel = self._panel:panel({
			name = "column_three_big_panel"
		})

		column_three_big_panel:set_w(eqpt_skills_panel:w())
		column_three_big_panel:set_x(eqpt_skills_panel:x())

		self._change_alpha_table = {
			{
				panel = alias_big_panel,
				button = alias_show_button
			},
			{
				panel = column_one_big_panel,
				button = column_one_show_button
			},
			{
				panel = column_two_big_panel,
				button = column_two_show_button
			},
			{
				panel = column_three_big_panel,
				button = column_three_show_button
			}
		}
	end

	self._multi_profile_item = MultiProfileItemGui:new(self._ws, self._panel)

	self:_round_everything()
	self:_update_selected_box(true)
	self:update_detection()
	self:_update_player_stats()
	self:_update_mod_boxes()

	local deployable_secondary = self._boxes_by_name.deployable_secondary

	if deployable_secondary then
		deployable_secondary.links = self._boxes_by_name.deployable.links
	end

	local outfit_player_style = self._boxes_by_name.outfit_player_style

	if outfit_player_style then
		outfit_player_style.links = self._boxes_by_name.armor.links
	end
end