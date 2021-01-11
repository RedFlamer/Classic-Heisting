local NOT_WIN_32 = SystemInfo:platform() ~= Idstring("WIN32")
local WIDTH_MULTIPLIER = NOT_WIN_32 and 0.6 or 0.6
local CONSOLE_PAGE_ADJUSTMENT = NOT_WIN_32 and 0 or 0
local TOP_ADJUSTMENT = NOT_WIN_32 and 50 or 60
local NUM_TREES_PER_PAGE = 4

local function make_fine_text(text)
	local x, y, w, h = text:text_rect()

	text:set_size(w, h)
	text:set_position(math.round(text:x()), math.round(text:y()))
end

function SkillTreeSkillItem:init(skill_id, tier_panel, num_skills, i, tree, tier, w, h, skill_refresh_skills)
	SkillTreeSkillItem.super.init(self)

	self._skill_id = skill_id
	self._tree = tree
	self._tier = tier
	local skill_panel = tier_panel:panel({
		name = skill_id,
		w = w,
		h = h
	})
	self._skill_panel = skill_panel
	self._skill_refresh_skills = skill_refresh_skills
	local skill = tweak_data.skilltree.skills[skill_id]
	self._skill_name = managers.localization:text(skill.name_id)
	local texture_rect_x = skill.icon_xy and skill.icon_xy[1] or 0
	local texture_rect_y = skill.icon_xy and skill.icon_xy[2] or 0
	self._base_size = h - 10
	local state_image = skill_panel:bitmap({
		texture = "guis/textures/pd2/skilltree/icons_atlas",
		name = "state_image",
		layer = 1,
		texture_rect = {
			texture_rect_x * 64,
			texture_rect_y * 64,
			64,
			64
		},
		color = tweak_data.screen_colors.item_stage_3
	})

	state_image:set_size(self._base_size, self._base_size)
	state_image:set_blend_mode("add")

	local skill_text = skill_panel:text({
		word_wrap = true,
		name = "skill_text",
		vertical = "center",
		wrap = true,
		align = "left",
		blend_mode = "add",
		text = "",
		layer = 3,
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size,
		color = tweak_data.screen_colors.text,
		x = self._base_size + 10,
		w = skill_panel:w() - self._base_size - 10
	})

	state_image:set_x(5)
	state_image:set_center_y(skill_panel:h() / 2)

	self._inside_panel = skill_panel:panel({
		w = w - 10,
		h = h - 10
	})

	self._inside_panel:set_center(skill_panel:w() / 2, skill_panel:h() / 2)

	local cx = tier_panel:w() / num_skills
	skill_panel:set_x((i - 1) * w)

	self._box = BoxGuiObject:new(skill_panel, {
		sides = {
			2,
			2,
			2,
			2
		}
	})

	self._box:hide()

	local state_indicator = skill_panel:bitmap({
		texture = "guis/textures/pd2/skilltree/ace",
		name = "state_indicator",
		alpha = 0,
		layer = 0,
		color = Color.white:with_alpha(1)
	})

	state_indicator:set_size(state_image:w() * 2, state_image:h() * 2)
	state_indicator:set_blend_mode("add")
	state_indicator:set_rotation(360)
	state_indicator:set_center(state_image:center())
end

function SkillTreePage:init(tree, data, parent_panel, fullscreen_panel, tree_tab_h, skill_prerequisites)
	self._items = {}
	self._selected_item = nil
	self._tree = tree
	local tree_panel = parent_panel:panel({
		y = 0,
		visible = false,
		name = tostring(tree),
		w = math.round(parent_panel:w() * WIDTH_MULTIPLIER)
	})
	self._tree_panel = tree_panel
	self._bg_image = fullscreen_panel:bitmap({
		name = "bg_image",
		blend_mode = "add",
		layer = 1,
		texture = data.background_texture,
		w = fullscreen_panel:w(),
		h = fullscreen_panel:h()
	})

	self._bg_image:set_alpha(0.6)

	local aspect = fullscreen_panel:w() / fullscreen_panel:h()
	local texture_width = self._bg_image:texture_width()
	local texture_height = self._bg_image:texture_height()
	local sw = math.max(texture_width, texture_height * aspect)
	local sh = math.max(texture_height, texture_width / aspect)
	local dw = texture_width / sw
	local dh = texture_height / sh

	self._bg_image:set_size(dw * fullscreen_panel:w(), dh * fullscreen_panel:h())
	self._bg_image:set_right(fullscreen_panel:w())
	self._bg_image:set_center_y(fullscreen_panel:h() / 2)

	local panel_h = 0
	local h = (parent_panel:h() - tree_tab_h - TOP_ADJUSTMENT) / (8 - CONSOLE_PAGE_ADJUSTMENT)
	for i = 1, 7 do
		local color = Color.black
		local rect = tree_panel:rect({
			h = 2,
			blend_mode = "add",
			name = "rect" .. i,
			color = color
		})

		rect:set_bottom(tree_panel:h() - (i - CONSOLE_PAGE_ADJUSTMENT) * h)

		if true or i == 1 then
			rect:set_alpha(0)
			rect:hide()
		end
	end

	local tier_panels = tree_panel:panel({
		name = "tier_panels"
	})
	if data.skill then
		local tier_panel = tier_panels:panel({
			name = "tier_panel0",
			h = h
		})
		tier_panel:set_bottom(tree_panel:child("rect1"):top())
		local item = SkillTreeUnlockItem:new(data.skill, tier_panel, tree, tier_panel:w() / 3, h)
		table.insert(self._items, item)
		item:refresh(false)
	end
	for tier, tier_data in ipairs(data.tiers) do
		local unlocked = managers.skilltree:tier_unlocked(tree, tier)
		local tier_panel = tier_panels:panel({
			name = "tier_panel" .. tier,
			h = h
		})
		local num_skills = #tier_data

		tier_panel:set_bottom(tree_panel:child("rect" .. tostring(tier + 1)):top())

		local base_size = h
		local base_w = tier_panel:w() / math.max(#tier_data, 1)

		for i, skill_id in ipairs(tier_data) do
			local item = SkillTreeSkillItem:new(skill_id, tier_panel, num_skills, i, tree, tier, base_w, base_size, skill_prerequisites[skill_id])

			table.insert(self._items, item)
			item:refresh(not unlocked)
		end

		local tier_string = tostring(tier)
		local debug_text = tier_panel:text({
			word_wrap = false,
			name = "debug_text",
			wrap = false,
			align = "right",
			vertical = "bottom",
			blend_mode = "add",
			rotation = 360,
			layer = 2,
			text = tier_string,
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size,
			h = tweak_data.menu.pd2_small_font_size,
			color = tweak_data.screen_colors.item_stage_3
		})

		debug_text:set_world_bottom(tree_panel:child("rect" .. tostring(tier + 1)):world_top() + 2)

		local _, _, tw, _ = debug_text:text_rect()

		debug_text:move(tw * 2, 0)

		local lock_image = tier_panel:bitmap({
			texture = "guis/textures/pd2/skilltree/padlock",
			name = "lock",
			layer = 3,
			w = tweak_data.menu.pd2_small_font_size,
			h = tweak_data.menu.pd2_small_font_size,
			color = tweak_data.screen_colors.item_stage_3
		})

		lock_image:set_blend_mode("add")
		lock_image:set_rotation(360)
		lock_image:set_world_position(debug_text:world_right(), debug_text:world_y() - 2)
		lock_image:set_visible(false)

		local add_infamy_glow = false

		if managers.experience:current_rank() > 0 then
			local tree_name = tweak_data.skilltree.trees[tree].skill

			for infamy, item in pairs(tweak_data.infamy.items) do
				if managers.infamy:owned(infamy) then
					local skilltree = item.upgrades and item.upgrades.skilltree

					if skilltree then
						local tree = skilltree.tree
						local trees = skilltree.trees

						if tree and tree == tree_name or trees and table.contains(trees, tree_name) then
							add_infamy_glow = true

							break
						end
					end
				end
			end
		end

		local cost_string = (managers.skilltree:tier_cost(tree, tier) < 10 and "0" or "") .. tostring(managers.skilltree:tier_cost(tree, tier))
		local cost_text = tier_panel:text({
			word_wrap = false,
			name = "cost_text",
			wrap = false,
			align = "left",
			vertical = "bottom",
			blend_mode = "add",
			rotation = 360,
			layer = 2,
			text = cost_string,
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size,
			h = tweak_data.menu.pd2_small_font_size,
			color = tweak_data.screen_colors.item_stage_3
		})
		local x, y, w, h = cost_text:text_rect()

		cost_text:set_size(w, h)
		cost_text:set_world_bottom(tree_panel:child("rect" .. tostring(tier + 1)):world_top() + 2)
		cost_text:set_x(debug_text:right() + tw * 3)

		if add_infamy_glow then
			local glow = tier_panel:bitmap({
				texture = "guis/textures/pd2/crimenet_marker_glow",
				name = "cost_glow",
				h = 56,
				blend_mode = "add",
				w = 56,
				rotation = 360,
				color = tweak_data.screen_colors.button_stage_3
			})

			local function anim_pulse_glow(o)
				local t = 0
				local dt = 0

				while true do
					dt = coroutine.yield()
					t = (t + dt * 0.5) % 1

					o:set_alpha((math.sin(t * 180) * 0.5 + 0.5) * 0.8)
				end
			end

			glow:set_center(cost_text:center())
			glow:animate(anim_pulse_glow)
		end

		local color = unlocked and tweak_data.screen_colors.item_stage_1 or tweak_data.screen_colors.item_stage_2

		debug_text:set_color(color)
		cost_text:set_color(color)

		if not unlocked then
			-- Nothing
		end
	end

	local ps = managers.skilltree:points_spent(self._tree)
	local max_points = 1

	for _, tier in ipairs(tweak_data.skilltree.trees[self._tree].tiers) do
		for _, skill in ipairs(tier) do
			for to_unlock, _ in ipairs(tweak_data.skilltree.skills[skill]) do
				max_points = max_points + managers.skilltree:get_skill_points(skill, to_unlock)
			end
		end
	end

	local prev_tier_p = 0
	local next_tier_p = max_points
	local ct = 0

	for i = 1, 6 do
		local tier_unlocks = managers.skilltree:tier_cost(self._tree, i)

		if ps < tier_unlocks then
			next_tier_p = tier_unlocks

			break
		end

		ct = i
		prev_tier_p = tier_unlocks
	end

	local diff_p = next_tier_p - prev_tier_p
	local diff_ps = ps - prev_tier_p
	local dh = self._tree_panel:child("rect2"):bottom()
	local prev_tier_object = self._tree_panel:child("rect" .. tostring(ct + 1))
	local next_tier_object = self._tree_panel:child("rect" .. tostring(ct + 2))
	local prev_tier_y = prev_tier_object and prev_tier_object:top() or 0
	local next_tier_y = next_tier_object and next_tier_object:top() or 0

	if not next_tier_object then
		next_tier_object = self._tree_panel:child("rect" .. tostring(ct))
		next_tier_y = next_tier_object and next_tier_object:top() or 0
		next_tier_y = 2 * prev_tier_y - next_tier_y
	end

	if ct > 0 then
		dh = math.max(2, tier_panels:child("tier_panel1"):world_bottom() - math.lerp(prev_tier_y, next_tier_y, diff_ps / diff_p))
	else
		dh = 0
	end

	local points_spent_panel = tree_panel:panel({
		w = 4,
		name = "points_spent_panel",
		h = dh
	})
	self._points_spent_line = BoxGuiObject:new(points_spent_panel, {
		sides = {
			2,
			2,
			0,
			0
		}
	})

	self._points_spent_line:set_clipping(dh == 0)
	points_spent_panel:set_world_center_x(tier_panels:child("tier_panel1"):child("lock"):world_center())
	points_spent_panel:set_world_bottom(tier_panels:child("tier_panel1"):world_bottom())

	for i, item in ipairs(self._items) do
		item:link(i, self._items)
	end
end

function SkillTreePage:on_points_spent()
	local points_spent_panel = self._tree_panel:child("points_spent_panel")
	local tier_panels = self._tree_panel:child("tier_panels")
	local ps = managers.skilltree:points_spent(self._tree)
	local max_points = 1

	for _, tier in ipairs(tweak_data.skilltree.trees[self._tree].tiers) do
		for _, skill in ipairs(tier) do
			for to_unlock, _ in ipairs(tweak_data.skilltree.skills[skill]) do
				max_points = max_points + managers.skilltree:get_skill_points(skill, to_unlock)
			end
		end
	end

	local prev_tier_p = 0
	local next_tier_p = max_points
	local ct = 0

	for i = 1, 6 do
		local tier_unlocks = managers.skilltree:tier_cost(self._tree, i)

		if ps < tier_unlocks then
			next_tier_p = tier_unlocks

			break
		end

		ct = i
		prev_tier_p = tier_unlocks
	end

	local diff_p = next_tier_p - prev_tier_p
	local diff_ps = ps - prev_tier_p
	local dh = self._tree_panel:child("rect2"):bottom()
	local prev_tier_object = self._tree_panel:child("rect" .. tostring(ct + 1))
	local next_tier_object = self._tree_panel:child("rect" .. tostring(ct + 2))
	local prev_tier_y = prev_tier_object and prev_tier_object:top() or 0
	local next_tier_y = next_tier_object and next_tier_object:top() or 0

	if not next_tier_object then
		next_tier_object = self._tree_panel:child("rect" .. tostring(ct))
		next_tier_y = next_tier_object and next_tier_object:top() or 0
		next_tier_y = 2 * prev_tier_y - next_tier_y
	end

	if ct > 0 then
		dh = math.max(2, tier_panels:child("tier_panel1"):world_bottom() - math.lerp(prev_tier_y, next_tier_y, diff_ps / diff_p))
	else
		dh = 0
	end

	points_spent_panel:set_h(dh)
	self._points_spent_line:create_sides(points_spent_panel, {
		sides = {
			2,
			2,
			2,
			2
		}
	})
	self._points_spent_line:set_clipping(dh == 0)
	points_spent_panel:set_world_center_x(tier_panels:child("tier_panel1"):child("lock"):world_center())
	points_spent_panel:set_world_bottom(tier_panels:child("tier_panel1"):world_bottom())
end

Hooks:PreHook(SkillTreeGui, "_update_borders", "perks", function(self)
	local tree_tabs_panel = self._skill_tree_panel:child("tree_tabs_panel")
	local spec_tabs_panel = self._specialization_panel:child("spec_tabs_panel")
	tree_tabs_panel:set_y(TOP_ADJUSTMENT + 1)
	spec_tabs_panel:set_y(TOP_ADJUSTMENT + 1)
end)