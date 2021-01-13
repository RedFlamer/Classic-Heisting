local mvec3_dir = mvector3.direction
local mvec3_dot = mvector3.dot
local mvec3_dis = mvector3.distance
local t_ins = table.insert
local t_rem = table.remove
local t_fv = table.find_value
local tmp_vec1 = Vector3()
local world_g = World

function EnemyManager:_update_queued_tasks(t, dt)
	local out_of_buffer = nil

	if managers.groupai:state():whisper_mode() then
		local all_tasks_no_t = self._queued_tasks_no_t

		if all_tasks_no_t and #all_tasks_no_t > 0 then
			local max_nr_loops = #all_tasks_no_t
			local i = 0

			while i < max_nr_loops do
				self:_execute_queued_task_no_t(1)

				i = i + 1
			end
		end

		local all_tasks = self._queued_tasks

		if #all_tasks > 0 then
			local max_nr_loops = #all_tasks
			local i = 0

			while i < max_nr_loops do
				if all_tasks[1].t < t then
					self:_execute_queued_task(1)

					i = i + 1
				else
					break
				end
			end
		end
	else
		self._queue_buffer = self._queue_buffer + dt
		local tick_rate = tweak_data.group_ai.ai_tick_rate

		if tick_rate <= self._queue_buffer then
			local all_tasks_no_t = self._queued_tasks_no_t

			if all_tasks_no_t and #all_tasks_no_t > 0 then
				local max_nr_loops = #all_tasks_no_t
				local i = 0

				while i < max_nr_loops do
					self:_execute_queued_task_no_t(1)

					self._queue_buffer = self._queue_buffer - tick_rate

					if self._queue_buffer <= 0 then
						out_of_buffer = true

						break
					else
						i = i + 1
					end
				end
			end

			local all_tasks = self._queued_tasks

			if #all_tasks > 0 then
				local max_nr_loops = #all_tasks
				local i = 0

				while i < max_nr_loops do
					if all_tasks[1].t < t then
						self:_execute_queued_task(1)

						self._queue_buffer = self._queue_buffer - tick_rate

						if self._queue_buffer <= 0 then
							out_of_buffer = true

							break
						else
							i = i + 1
						end
					else
						break
					end
				end
			end
		else
			out_of_buffer = true
		end

		if #self._queued_tasks == 0 then
			if not self._queued_tasks_no_t or #self._queued_tasks_no_t == 0 then
				self._queue_buffer = 0
			end
		end
	end

	if not out_of_buffer and not self._queued_task_executed then
		local i_asap_task, asap_task_t = nil

		for i_task, task_data in ipairs(self._queued_tasks) do
			if task_data.asap then
				if not asap_task_t or task_data.t < asap_task_t then
					i_asap_task = i_task
					asap_task_t = task_data.t
				end
			end
		end

		if i_asap_task then
			self:_execute_queued_task(i_asap_task)
		end
	end

	local all_clbks = self._delayed_clbks

	if all_clbks[1] and all_clbks[1][2] < t then
		local clbk = t_rem(all_clbks, 1)[3]

		clbk()
	end
end

function EnemyManager:_execute_queued_task_no_t(i)
	local task = t_rem(self._queued_tasks_no_t, i)
	self._queued_task_executed = true

	if task.v_cb then
		task.v_cb(task.id)
	end

	task.clbk(task.data)
end

function EnemyManager:_update_gfx_lod()
	if not self._gfx_lod_data.enabled or not managers.navigation:is_data_ready() then
		return
	end

	local player = managers.player:player_unit()
	local pl_tracker, cam_pos, cam_fwd = nil

	if player then
		pl_tracker = player:movement():nav_tracker()
		cam_pos = player:movement():m_head_pos()
		cam_fwd = player:camera():forward()
	elseif managers.viewport:get_current_camera() then
		cam_pos = managers.viewport:get_current_camera_position()
		cam_fwd = managers.viewport:get_current_camera_rotation():y()
	end

	if not cam_fwd then
		return
	end

	local entries = self._gfx_lod_data.entries
	local units = entries.units
	local states = entries.states
	local move_ext = entries.move_ext
	local trackers = entries.trackers
	local com = entries.com
	local chk_vis_func = pl_tracker and pl_tracker.check_visibility
	local unit_occluded = Unit.occluded
	local occ_skip_units = managers.occlusion._skip_occlusion
	local world_in_view_with_options = world_g.in_view_with_options

	for i, state in ipairs(states) do
		if not state and alive(units[i]) then
			local visible = nil

			if occ_skip_units[units[i]:key()] then
				visible = true
			elseif not unit_occluded(units[i]) then
				if not pl_tracker or chk_vis_func(pl_tracker, trackers[i]) then
					visible = true
				end
			end

			if visible and world_in_view_with_options(world_g, com[i], 0, 110, 18000) then
				states[i] = 1

				units[i]:base():set_visibility_state(1)
			end
		end
	end

	if #states > 0 then
		local anim_lod = managers.user:get_setting("video_animation_lod")
		local nr_lod_1 = self._nr_i_lod[anim_lod][1]
		local nr_lod_2 = self._nr_i_lod[anim_lod][2]
		local nr_lod_total = nr_lod_1 + nr_lod_2
		local imp_i_list = self._gfx_lod_data.prio_i
		local imp_wgt_list = self._gfx_lod_data.prio_weights
		local nr_entries = #states
		local i = self._gfx_lod_data.next_chk_prio_i

		if nr_entries < i then
			i = 1
		end

		local start_i = i

		repeat
			if states[i] and alive(units[i]) then
				local not_visible = nil

				if not occ_skip_units[units[i]:key()] then
					if unit_occluded(units[i]) or pl_tracker and not chk_vis_func(pl_tracker, trackers[i]) then
						not_visible = true
					end
				end

				if not_visible then
					states[i] = false

					units[i]:base():set_visibility_state(false)
					self:_remove_i_from_lod_prio(i, anim_lod)

					self._gfx_lod_data.next_chk_prio_i = i + 1

					break
				elseif not world_in_view_with_options(world_g, com[i], 0, 120, 18000) then
					states[i] = false

					units[i]:base():set_visibility_state(false)
					self:_remove_i_from_lod_prio(i, anim_lod)

					self._gfx_lod_data.next_chk_prio_i = i + 1

					break
				else
					local my_wgt = mvec3_dir(tmp_vec1, cam_pos, com[i])
					local dot = mvec3_dot(tmp_vec1, cam_fwd)
					local previous_prio = nil

					for prio, i_entry in ipairs(imp_i_list) do
						if i == i_entry then
							previous_prio = prio

							break
						end
					end

					my_wgt = my_wgt * my_wgt * (1 - dot)
					local i_wgt = #imp_wgt_list

					while i_wgt > 0 do
						if previous_prio ~= i_wgt and imp_wgt_list[i_wgt] <= my_wgt then
							break
						end

						i_wgt = i_wgt - 1
					end

					if not previous_prio or i_wgt <= previous_prio then
						i_wgt = i_wgt + 1
					end

					if i_wgt ~= previous_prio then
						if previous_prio then
							t_rem(imp_i_list, previous_prio)
							t_rem(imp_wgt_list, previous_prio)

							if previous_prio <= nr_lod_1 and nr_lod_1 < i_wgt and nr_lod_1 <= #imp_i_list then
								local promote_i = imp_i_list[nr_lod_1]
								states[promote_i] = 1

								units[promote_i]:base():set_visibility_state(1)
							elseif nr_lod_1 < previous_prio and i_wgt <= nr_lod_1 then
								local denote_i = imp_i_list[nr_lod_1]
								states[denote_i] = 2

								units[denote_i]:base():set_visibility_state(2)
							end
						elseif i_wgt <= nr_lod_total and #imp_i_list == nr_lod_total then
							local kick_i = imp_i_list[nr_lod_total]
							states[kick_i] = 3

							units[kick_i]:base():set_visibility_state(3)
							t_rem(imp_wgt_list)
							t_rem(imp_i_list)
						end

						local lod_stage = nil

						if i_wgt <= nr_lod_total then
							t_ins(imp_wgt_list, i_wgt, my_wgt)
							t_ins(imp_i_list, i_wgt, i)

							if i_wgt <= nr_lod_1 then
								lod_stage = 1
							else
								lod_stage = 2
							end
						else
							lod_stage = 3

							self:_remove_i_from_lod_prio(i, anim_lod)
						end

						if states[i] ~= lod_stage then
							states[i] = lod_stage

							units[i]:base():set_visibility_state(lod_stage)
						end
					end

					self._gfx_lod_data.next_chk_prio_i = i + 1

					break
				end
			end

			if i == nr_entries then
				i = 1
			else
				i = i + 1
			end
		until i == start_i
	end
end

function EnemyManager:set_gfx_lod_enabled(state)
	if state then
		self._gfx_lod_data.enabled = state
	elseif self._gfx_lod_data.enabled then
		self._gfx_lod_data.enabled = state
		local entries = self._gfx_lod_data.entries
		local units = entries.units
		local states = entries.states

		for i, lod_stage in ipairs(states) do
			if not lod_stage or lod_stage ~= 1 then
				if alive(units[i]) then
					states[i] = 1

					units[i]:base():set_visibility_state(1)
				end
			end
		end
	end
end

function EnemyManager:chk_any_unit_in_slotmask_visible(slotmask, cam_pos, cam_nav_tracker)
	if self._gfx_lod_data.enabled and managers.navigation:is_data_ready() then
		local entries = self._gfx_lod_data.entries
		local units = entries.units
		local states = entries.states
		local trackers = entries.trackers
		local move_exts = entries.move_ext
		local com = entries.com
		local chk_vis_func = cam_nav_tracker and cam_nav_tracker.check_visibility
		local unit_occluded = Unit.occluded
		local occ_skip_units = managers.occlusion._skip_occlusion
		local vis_slotmask = managers.slot:get_mask("AI_visibility")

		for i, state in ipairs(states) do
			if alive(units[i]) then
				local unit = units[i]

				if unit:in_slot(slotmask) then
					local proceed = nil

					if occ_skip_units[unit:key()] then
						proceed = true
					elseif not unit_occluded(unit) then
						if not cam_nav_tracker or chk_vis_func(cam_nav_tracker, trackers[i]) then
							proceed = true
						end
					end

					if proceed then
						local distance = mvec3_dis(cam_pos, com[i])

						if distance < 300 then
							return true
						elseif distance < 2000 then
							local u_m_head_pos = move_exts[i]:m_head_pos()
							local ray = world_g:raycast("ray", cam_pos, u_m_head_pos, "slot_mask", vis_slotmask, "report")

							if not ray then
								return true
							else
								ray = world_g:raycast("ray", cam_pos, com[i], "slot_mask", vis_slotmask, "report")

								if not ray then
									return true
								end
							end
						end
					end
				end
			end
		end
	end
end

function EnemyManager:queue_task(id, task_clbk, data, execute_t, verification_clbk, asap)
	local task_data = {
		clbk = task_clbk,
		id = id,
		data = data,
		t = execute_t,
		v_cb = verification_clbk,
		asap = asap
	}

	if not execute_t and #self._queued_tasks < 1 and not self._queued_task_executed then
		t_ins(self._queued_tasks, task_data)

		self:_execute_queued_task(1)
	elseif not execute_t then
		self._queued_tasks_no_t = self._queued_tasks_no_t or {}

		t_ins(self._queued_tasks_no_t, task_data)
	else
		local all_tasks = self._queued_tasks
		local i = #all_tasks

		while i > 0 and execute_t < all_tasks[i].t do
			i = i - 1
		end

		t_ins(all_tasks, i + 1, task_data)
	end
end

function EnemyManager:update_queue_task(id, task_clbk, data, execute_t, verification_clbk, asap)
	local task_had_no_t = false
	local task_data, _ = t_fv(self._queued_tasks, function (td)
		return td.id == id
	end)

	if not task_data and self._queued_tasks_no_t then
		task_data, _ = t_fv(self._queued_tasks_no_t, function (td)
			return td.id == id
		end)

		if task_data then
			task_had_no_t = true
		end
	end

	if task_data then
		local needs_moving = task_data.t == nil and execute_t and true or task_data.t and execute_t == nil and true

		task_data.clbk = task_clbk or task_data.clbk
		task_data.data = data or task_data.data
		task_data.t = execute_t or task_data.t
		task_data.v_cb = verification_clbk or task_data.v_cb
		task_data.asap = asap or task_data.asap

		if needs_moving then
			self:unqueue_task(id, task_had_no_t)
			self:queue_task(id, task_data.clbk, task_data.data, task_data.t, task_data.v_cb, task_data.asap)
		end
	end
end

function EnemyManager:unqueue_task(id, check_no_t)
	local tasks = self._queued_tasks

	if check_no_t then
		if not self._queued_tasks_no_t then
			--debug_pause("[EnemyManager:unqueue_task] task", id, "was not queued!!!")

			return
		end

		tasks = self._queued_tasks_no_t
	end

	local i = #tasks

	while i > 0 do
		if tasks[i].id == id then
			t_rem(tasks, i)

			return
		end

		i = i - 1
	end

	if check_no_t == nil then
		self:unqueue_task(id, true)
	end

	--debug_pause("[EnemyManager:unqueue_task] task", id, "was not queued!!!")
end