--[[Hooks:PostHook(CopActionTase, "on_attention", "sh_on_attention", function (self)
    if self._line_of_fire_slotmask then
        self._line_of_fire_slotmask = self._line_of_fire_slotmask - managers.slot:get_mask("persons")
    end
end)--]]