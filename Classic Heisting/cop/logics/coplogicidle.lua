function CopLogicIdle._chk_relocate(data)
	if data.objective and data.objective.type == "follow" then
		if data.is_converted then
			if TeamAILogicIdle._check_should_relocate(data, data.internal_data, data.objective) then
				data.objective.in_place = nil
				CopLogicIdle._exit(data.unit, "travel")
				return true
			end
			return
		end
		local relocate
		local follow_unit = data.objective.follow_unit
		local advance_pos = follow_unit:brain() and follow_unit:brain():is_advancing()
		local follow_unit_pos = advance_pos or data.m_pos
		if data.objective.relocated_to and mvector3.equal(data.objective.relocated_to, follow_unit_pos) then
			return
		end
		if mvector3.distance(follow_unit:movement():m_pos(), follow_unit_pos) > data.objective.distance then
			relocate = true
		end
		if not relocate then
			local ray_params = {
				tracker_from = data.unit:movement():nav_tracker(),
				pos_to = follow_unit_pos
			}
			local ray_res = managers.navigation:raycast(ray_params)
			if ray_res then
				relocate = true
			end
		end
		if relocate then
			data.objective.in_place = nil
			data.objective.nav_seg = follow_unit:movement():nav_tracker():nav_segment()
			data.objective.relocated_to = mvector3.copy(follow_unit_pos)
			CopLogicBase._exit(data.unit, "travel")
			return true
		end
	end
end