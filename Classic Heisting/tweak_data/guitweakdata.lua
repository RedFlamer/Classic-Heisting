Hooks:PostHook(GuiTweakData, "init", "restore_init", function(self, tweak_data)
	self.crime_net.sidebar = {
		{
			name_id = "menu_cn_shortcuts",
			icon = "sidebar_expand",
			show_name_while_collapsed = false,
			callback = "clbk_toggle_sidebar"
		},
		{
			visible_callback = "clbk_visible_multiplayer",
			btn_macro = "menu_toggle_filters",
			callback = "clbk_crimenet_filters",
			name_id = "menu_cn_filters_sidebar",
			icon = "sidebar_filters"
		},
		{
			item_class = "CrimeNetSidebarSeparator"
		},
		{
			name_id = "menu_cn_premium_buy",
			icon = "sidebar_broker",
			callback = "clbk_contract_broker"
		},
		{
			item_class = "CrimeNetSidebarSeparator"
		},
		{
			name_id = "menu_cn_casino",
			icon = "sidebar_casino",
			callback = "clbk_offshore_payday"
		},
		{
			name_id = "menu_cn_contact_info",
			icon = "sidebar_codex",
			callback = "clbk_contact_database"
		},
		{
			item_class = "CrimeNetSidebarSeparator"
		}
	}
end)