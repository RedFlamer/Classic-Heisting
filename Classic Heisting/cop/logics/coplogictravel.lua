function CopLogicTravel.queued_update(data)
	local unit = data.unit
	local my_data = data.internal_data
	local objective = data.objective
	local t = TimerManager:game():time()
	data.t = t
	local delay = CopLogicTravel._upd_enemy_detection(data)
	if data.internal_data ~= my_data then
		return
	end
	if my_data.has_old_action then
		CopLogicAttack._upd_stop_old_action(data, my_data)
	elseif my_data.advancing then
		if my_data.announce_t and t > my_data.announce_t then
			CopLogicTravel._try_anounce(data, my_data)
		end
	elseif my_data.processing_advance_path or my_data.processing_coarse_path or my_data.cover_leave_t or my_data.advance_path then
	elseif objective and (objective.nav_seg or objective.type == "follow") then
		if my_data.coarse_path then
			local coarse_path = my_data.coarse_path
			local cur_index = my_data.coarse_path_index
			local total_nav_points = #coarse_path
			if cur_index == total_nav_points then
				objective.in_place = true
				if objective.type == "investigate_area" or objective.type == "free" then
					if not objective.action_duration then
						managers.groupai:state():on_objective_complete(unit, objective)
						return
					end
				elseif objective.type == "defend_area" then
					if objective.grp_objective and objective.grp_objective.type == "retire" then
						data.unit:brain():set_active(false)
						data.unit:base():set_slot(data.unit, 0)
						return
					else
						managers.groupai:state():on_defend_travel_end(unit, objective)
					end
				end
				CopLogicTravel.on_new_objective(data)
				return
			else
				local start_pathing = CopLogicTravel.chk_group_ready_to_move(data, my_data)
				if start_pathing then
					local to_pos
					if cur_index == total_nav_points - 1 then
						local new_occupation = CopLogicTravel._determine_destination_occupation(data, objective)
						if new_occupation then
							if new_occupation.type == "guard" then
								local guard_door = new_occupation.door
								local guard_pos = CopLogicTravel._get_pos_accross_door(guard_door, objective.nav_seg)
								if guard_pos then
									local reservation = CopLogicTravel._reserve_pos_along_vec(guard_door.center, guard_pos)
									if reservation then
										data.brain:set_pos_rsrv("path", reservation)
										local guard_object = {
											type = "door",
											door = guard_door,
											from_seg = new_occupation.from_seg
										}
										objective.guard_obj = guard_object
										to_pos = reservation.pos
									end
								end
							elseif new_occupation.type == "defend" then
								if new_occupation.cover then
									to_pos = new_occupation.cover[1][1]
									if data.char_tweak.wall_fwd_offset then
										to_pos = CopLogicTravel.apply_wall_offset_to_cover(data, my_data, new_occupation.cover[1], data.char_tweak.wall_fwd_offset)
									end
									managers.navigation:reserve_cover(new_occupation.cover[1], data.pos_rsrv_id)
									my_data.moving_to_cover = new_occupation.cover
								elseif new_occupation.pos then
									to_pos = new_occupation.pos
									data.brain:add_pos_rsrv("path", {
										position = mvector3.copy(to_pos),
										radius = 30
									})
								end
							else
								to_pos = new_occupation.pos
								if to_pos then
									data.brain:add_pos_rsrv("path", {
										position = mvector3.copy(to_pos),
										radius = 30
									})
								end
							end
						end
						if not to_pos then
							to_pos = managers.navigation:find_random_position_in_segment(objective.nav_seg)
							to_pos = CopLogicTravel._get_pos_on_wall(to_pos)
							data.brain:add_pos_rsrv("path", {
								position = mvector3.copy(to_pos),
								radius = 30
							})
						end
					else
						local end_pos = coarse_path[cur_index + 1][2]
						local cover = CopLogicTravel._find_cover(data, coarse_path[cur_index + 1][1])
						if cover then
							managers.navigation:reserve_cover(cover, data.pos_rsrv_id)
							my_data.moving_to_cover = {cover}
							to_pos = cover[1]
						else
							to_pos = managers.navigation:find_random_position_in_segment(coarse_path[cur_index + 1][1])
							my_data.moving_to_cover = nil
						end
					end
					my_data.advance_path_search_id = tostring(unit:key()) .. "advance"
					my_data.processing_advance_path = true
					local nav_segs = CopLogicTravel._get_allowed_travel_nav_segs(data, my_data, to_pos)
					unit:brain():search_for_path(my_data.advance_path_search_id, to_pos, nil, nil, nav_segs)
				end
			end
		else
			local search_id = tostring(unit:key()) .. "coarse"
			local verify_clbk
			if not my_data.coarse_search_failed then
				verify_clbk = callback(CopLogicTravel, CopLogicTravel, "_investigate_coarse_path_verify_clbk")
			end
			local nav_seg
			if objective.follow_unit then
				nav_seg = objective.follow_unit:movement():nav_tracker():nav_segment()
			else
				nav_seg = objective.nav_seg
			end
			if unit:brain():search_for_coarse_path(search_id, nav_seg, verify_clbk) then
				my_data.coarse_path_search_id = search_id
				my_data.processing_coarse_path = true
			end
		end
	else
		CopLogicBase._exit(data.unit, "idle")
		return
	end
	if my_data.processing_advance_path or my_data.processing_coarse_path then
		CopLogicTravel._upd_pathing(data, my_data)
		if data.internal_data ~= my_data then
			return
		end
	end
	if my_data.advancing then
	elseif my_data.cover_leave_t then
		if not my_data.turning and not unit:movement():chk_action_forbidden("walk") and not data.unit:anim_data().reload then
			if t > my_data.cover_leave_t then
				my_data.cover_leave_t = nil
			elseif data.attention_obj and data.attention_obj.reaction >= AIAttentionObject.REACT_SCARED and (not my_data.best_cover or not my_data.best_cover[4]) and not unit:anim_data().crouch and (not data.char_tweak.allowed_poses or data.char_tweak.allowed_poses.crouch) then
				CopLogicAttack._chk_request_action_crouch(data)
			end
		end
	elseif my_data.advance_path and not data.unit:movement():chk_action_forbidden("walk") then
		local haste
		if objective and objective.haste then
			haste = objective.haste
		elseif data.unit:movement():cool() then
			haste = "walk"
		else
			haste = "run"
		end
		local pose
		if not data.char_tweak.crouch_move then
			pose = "stand"
		elseif data.char_tweak.allowed_poses and not data.char_tweak.allowed_poses.stand then
			pose = "crouch"
		else
			pose = data.is_suppressed and "crouch" or objective and objective.pose or "stand"
		end
		if not unit:anim_data()[pose] then
			CopLogicAttack["_chk_request_action_" .. pose](data)
		end
		local end_rot
		if my_data.coarse_path_index == #my_data.coarse_path - 1 then
			end_rot = objective and objective.rot
		end
		local no_strafe
		CopLogicTravel._chk_request_action_walk_to_advance_pos(data, my_data, haste, end_rot, no_strafe)
	end
	CopLogicTravel.queue_update(data, my_data, delay)
end

function CopLogicTravel._update_cover(ignore_this, data)
	local my_data = data.internal_data
	CopLogicBase.on_delayed_clbk(my_data, my_data.cover_update_task_key)
	local cover_release_dis = 100
	local nearest_cover = my_data.nearest_cover
	local best_cover = my_data.best_cover
	local m_pos = data.m_pos
	if not my_data.in_cover and nearest_cover and cover_release_dis < mvector3.distance(nearest_cover[1][1], m_pos) then
		managers.navigation:release_cover(nearest_cover[1])
		my_data.nearest_cover = nil
		nearest_cover = nil
	end
	if best_cover and cover_release_dis < mvector3.distance(best_cover[1][1], m_pos) then
		managers.navigation:release_cover(best_cover[1])
		my_data.best_cover = nil
		best_cover = nil
	end
	if nearest_cover or best_cover then
		CopLogicBase.add_delayed_clbk(my_data, my_data.cover_update_task_key, callback(CopLogicTravel, CopLogicTravel, "_update_cover", data), data.t + 1)
	end
end

function CopLogicTravel.action_complete_clbk(data, action)
	local my_data = data.internal_data
	local action_type = action:type()
	if action_type == "walk" then
		if action:expired() and not my_data.starting_advance_action and my_data.coarse_path_index and not my_data.has_old_action and my_data.advancing then
			my_data.coarse_path_index = my_data.coarse_path_index + 1
			if my_data.coarse_path_index > #my_data.coarse_path then
				debug_pause_unit(data.unit, "[CopLogicTravel.action_complete_clbk] invalid coarse path index increment", inspect(my_data.coarse_path), my_data.coarse_path_index)
				my_data.coarse_path_index = my_data.coarse_path_index - 1
			end
		end
		my_data.advancing = nil
		if my_data.moving_to_cover then
			if action:expired() then
				if my_data.best_cover then
					managers.navigation:release_cover(my_data.best_cover[1])
				end
				my_data.best_cover = my_data.moving_to_cover
				CopLogicBase.chk_cancel_delayed_clbk(my_data, my_data.cover_update_task_key)
				local high_ray = CopLogicTravel._chk_cover_height(data, my_data.best_cover[1], data.visibility_slotmask)
				my_data.best_cover[4] = high_ray
				my_data.in_cover = true
				local cover_wait_time
				if not my_data.cover_wait_time then
					cover_wait_time = {0.7, 0.8}
				end
				my_data.cover_leave_t = data.t + cover_wait_time[1] + cover_wait_time[2] * math.random()
			else
				managers.navigation:release_cover(my_data.moving_to_cover[1])
				if my_data.best_cover then
					local dis = mvector3.distance(my_data.best_cover[1][1], data.unit:movement():m_pos())
					if dis > 100 then
						managers.navigation:release_cover(my_data.best_cover[1])
						my_data.best_cover = nil
					end
				end
			end
			my_data.moving_to_cover = nil
		elseif my_data.best_cover then
			local dis = mvector3.distance(my_data.best_cover[1][1], data.unit:movement():m_pos())
			if dis > 100 then
				managers.navigation:release_cover(my_data.best_cover[1])
				my_data.best_cover = nil
			end
		end
	elseif action_type == "turn" then
		data.internal_data.turning = nil
	elseif action_type == "shoot" then
		data.internal_data.shooting = nil
	elseif action_type == "dodge" then
		local objective = data.objective
		local allow_trans, obj_failed = CopLogicBase.is_obstructed(data, objective, nil, nil)
		if allow_trans then
			local wanted_state = data.logic._get_logic_state_from_reaction(data)
			if wanted_state and wanted_state ~= data.name and obj_failed then
				if data.unit:in_slot(managers.slot:get_mask("enemies")) or data.unit:in_slot(17) then
					managers.groupai:state():on_objective_failed(data.unit, data.objective)
				elseif data.unit:in_slot(managers.slot:get_mask("criminals")) then
					managers.groupai:state():on_criminal_objective_failed(data.unit, data.objective, false)
				end
				if my_data == data.internal_data then
					debug_pause_unit(data.unit, "[CopLogicTravel.action_complete_clbk] exiting without discarding objective", data.unit, inspect(data.objective))
					CopLogicBase._exit(data.unit, wanted_state)
				end
			end
		end
	end
end

function CopLogicTravel._determine_destination_occupation(data, objective)
	local occupation
	if objective.type == "investigate_area" then
		if objective.guard_obj then
			occupation = managers.groupai:state():verify_occupation_in_area(objective) or objective.guard_obj
			occupation.type = "guard"
		else
			occupation = managers.groupai:state():find_occupation_in_area(objective.nav_seg)
		end
	elseif objective.type == "defend_area" then
		if objective.cover then
			occupation = {
				type = "defend",
				seg = objective.nav_seg,
				cover = objective.cover,
				radius = objective.radius
			}
		elseif objective.pos then
			occupation = {
				type = "defend",
				seg = objective.nav_seg,
				pos = objective.pos,
				radius = objective.radius
			}
		else
			local near_pos = objective.follow_unit and objective.follow_unit:movement():nav_tracker():field_position()
			local cover = CopLogicTravel._find_cover(data, objective.nav_seg, near_pos)
			if cover then
				local cover_entry = {cover}
				occupation = {
					type = "defend",
					seg = objective.nav_seg,
					cover = cover_entry,
					radius = objective.radius
				}
			else
				near_pos = CopLogicTravel._get_pos_on_wall(managers.navigation._nav_segments[objective.nav_seg].pos, 700)
				occupation = {
					type = "defend",
					seg = objective.nav_seg,
					pos = near_pos,
					radius = objective.radius
				}
			end
		end
	elseif objective.type == "act" then
		occupation = {
			type = "act",
			seg = objective.nav_seg,
			pos = objective.pos
		}
	elseif objective.type == "follow" then
		local follow_pos, follow_nav_seg
		local follow_unit_objective = objective.follow_unit:brain() and objective.follow_unit:brain():objective()
		if not follow_unit_objective or follow_unit_objective.in_place or not follow_unit_objective.nav_seg then
			follow_pos = objective.follow_unit:movement():m_pos()
			follow_nav_seg = objective.follow_unit:movement():nav_tracker():nav_segment()
		else
			follow_pos = follow_unit_objective.pos or objective.follow_unit:movement():m_pos()
			follow_nav_seg = follow_unit_objective.nav_seg
		end
		local distance = objective.distance and math.lerp(objective.distance * 0.5, objective.distance, math.random()) or 700
		local to_pos = CopLogicTravel._get_pos_on_wall(follow_pos, distance)
		occupation = {
			type = "defend",
			nav_seg = follow_nav_seg,
			pos = to_pos
		}
	else
		occupation = {
			seg = objective.nav_seg,
			pos = objective.pos
		}
	end
	return occupation
end

function CopLogicTravel.chk_group_ready_to_move(data, my_data)
	local my_objective = data.objective
	if not my_objective.grp_objective then
		return true
	end
	local my_dis = mvector3.distance_sq(my_objective.area.pos, data.m_pos)
	if my_dis > 4000000 then
		return true
	end
	my_dis = my_dis * 1.15 * 1.15
	for u_key, u_data in pairs(data.group.units) do
		if u_key ~= data.key then
			local his_objective = u_data.unit:brain():objective()
			if his_objective and his_objective.grp_objective == my_objective.grp_objective and not his_objective.in_place then
				local his_dis = mvector3.distance_sq(his_objective.area.pos, u_data.m_pos)
				if my_dis < his_dis then
					return false
				end
			end
		end
	end
	return true
end