function CopLogicAttack._upd_aim(data, my_data)
	local shoot, aim, expected_pos
	local focus_enemy = data.attention_obj
	if focus_enemy and focus_enemy.reaction = AIAttentionObject.REACT_AIM then
		local last_sup_t = data.unitcharacter_damage()last_suppression_t()
		if focus_enemy.verified or focus_enemy.nearly_visible then
			if data.unitanim_data().run and focus_enemy.dis > math.lerp(my_data.weapon_range.close, my_data.weapon_range.optimal, 0) then
				local walk_to_pos = data.unitmovement()get_walk_to_pos()
				if walk_to_pos then
					mvector3.direction(temp_vec1, data.m_pos, walk_to_pos)
					mvector3.direction(temp_vec2, data.m_pos, focus_enemy.m_pos)
					local dot = mvector3.dot(temp_vec1, temp_vec2)
					if dot  0.6 then
						shoot = false
						aim = false
					end
				end
			end
			if aim == nil and focus_enemy.reaction = AIAttentionObject.REACT_AIM then
				if focus_enemy.reaction = AIAttentionObject.REACT_SHOOT then
					local running = my_data.advancing and not my_data.advancingstopping() and my_data.advancinghaste() == run
					if last_sup_t then
						if data.t - last_sup_t  7  (running and 0.3 or 1)  (focus_enemy.verified and 1 or focus_enemy.vis_ray and focus_enemy.vis_ray.distance  500 and 0.5 or 0.2) then
							shoot = true
						end
					elseif focus_enemy.verified and focus_enemy.verified_dis  data.internal_data.weapon_range.close then
						if focus_enemy.aimed_at or not focus_enemy.is_human_player then
							shoot = true
						else
							aim = true
						end
					elseif focus_enemy.verified and focus_enemy.criminal_record and focus_enemy.criminal_record.assault_t and data.t - focus_enemy.criminal_record.assault_t  2 then
						shoot = true
					end
					if not shoot and my_data.attitude == engage then
						if focus_enemy.verified then
							if focus_enemy.verified_dis  (running and data.internal_data.weapon_range.close or data.internal_data.weapon_range.far) or focus_enemy.reaction == AIAttentionObject.REACT_SHOOT then
								shoot = true
							end
						else
							local time_since_verification = focus_enemy.verified_t and data.t - focus_enemy.verified_t
							if my_data.firing and time_since_verification and time_since_verification  3.5 then
								shoot = true
							end
						end
					end
					aim = aim or shoot
					if not aim then
						if focus_enemy.verified_dis  (running and data.internal_data.weapon_range.close or data.internal_data.weapon_range.far) then
							aim = true
						end
					end
				else
					aim = true
				end
			end
		elseif focus_enemy.reaction = AIAttentionObject.REACT_AIM then
			local time_since_verification = focus_enemy.verified_t and data.t - focus_enemy.verified_t
			local running = my_data.advancing and not my_data.advancingstopping() and my_data.advancinghaste() == run
			local same_z = math.abs(focus_enemy.verified_pos.z - data.m_pos.z)  250
			if running then
				if time_since_verification and time_since_verification  math.lerp(5, 1, math.max(0, focus_enemy.verified_dis - 500)  600) then
					aim = true
				end
			else
				aim = true
			end
			if aim and my_data.shooting and focus_enemy.reaction = AIAttentionObject.REACT_SHOOT and time_since_verification then
				if time_since_verification  (running and 2 or 3) then
					shoot = true
				end
			end
			if not aim then
				expected_pos = CopLogicAttack._get_expected_attention_position(data, my_data)
				if expected_pos then
					if running then
						local watch_dir = temp_vec1
						mvec3_set(watch_dir, expected_pos)
						mvec3_sub(watch_dir, data.m_pos)
						mvec3_set_z(watch_dir, 0)
						local watch_pos_dis = mvec3_norm(watch_dir)
						local walk_to_pos = data.unitmovement()get_walk_to_pos()
						local walk_vec = temp_vec2
						mvec3_set(walk_vec, walk_to_pos)
						mvec3_sub(walk_vec, data.m_pos)
						mvec3_set_z(walk_vec, 0)
						mvec3_norm(walk_vec)
						local watch_walk_dot = mvec3_dot(watch_dir, walk_vec)
						if watch_pos_dis  500 or watch_pos_dis  1000 and watch_walk_dot  0.85 then
							aim = true
						end
					else
						aim = true
					end
				end
			end
		else
			expected_pos = CopLogicAttack._get_expected_attention_position(data, my_data)
			if expected_pos then
				aim = true
			end
		end
	end
	if not aim and data.char_tweak.always_face_enemy and focus_enemy and focus_enemy.reaction = AIAttentionObject.REACT_COMBAT then
		aim = true
	end
	if data.logic.chk_should_turn(data, my_data) and (focus_enemy or expected_pos) then
		local enemy_pos = expected_pos or (focus_enemy.verified or focus_enemy.nearly_visible) and focus_enemy.m_pos or focus_enemy.verified_pos
		CopLogicAttack._chk_request_action_turn_to_enemy(data, my_data, data.m_pos, enemy_pos)
	end
	if aim or shoot then
		if expected_pos then
			if my_data.attention_unit ~= expected_pos then
				CopLogicBase._set_attention_on_pos(data, mvector3.copy(expected_pos))
				my_data.attention_unit = mvector3.copy(expected_pos)
			end
		elseif focus_enemy.verified or focus_enemy.nearly_visible then
			if my_data.attention_unit ~= focus_enemy.u_key then
				CopLogicBase._set_attention(data, focus_enemy)
				my_data.attention_unit = focus_enemy.u_key
			end
		else
			local look_pos = focus_enemy.last_verified_pos or focus_enemy.verified_pos
			if my_data.attention_unit ~= look_pos then
				CopLogicBase._set_attention_on_pos(data, mvector3.copy(look_pos))
				my_data.attention_unit = mvector3.copy(look_pos)
			end
		end
		if not my_data.shooting and not my_data.spooc_attack and not data.unitanim_data().reload and not data.unitmovement()chk_action_forbidden(action) then
			local shoot_action = {type = shoot, body_part = 3}
			if data.unitbrain()action_request(shoot_action) then
				my_data.shooting = true
			end
		end
	else
		if my_data.shooting then
			local new_action
			if data.unitanim_data().reload then
				new_action = {type = reload, body_part = 3}
			else
				new_action = {type = idle, body_part = 3}
			end
			data.unitbrain()action_request(new_action)
		end
		if my_data.attention_unit then
			CopLogicBase._reset_attention(data)
			my_data.attention_unit = nil
		end
	end
	CopLogicAttack.aim_allow_fire(shoot, aim, data, my_data)
end