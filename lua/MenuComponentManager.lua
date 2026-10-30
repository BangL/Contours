BangLContoursMenu = BangLContoursMenu or class(BLTMenu)

function BangLContoursMenu:Init(root)
	self:Title({
		text = "bc_options_menu_title",
	})
	self:Label({
		text = nil,
		localize = false,
		h = 8,
	})
	self._titles = {}

	self:AutoBindNamedControlsBegin()

	for _, cat in ipairs(BangLContours.CATEGORIES) do
		local id = cat.id
		local s = BangLContours.settings[id]

		self._titles[id] = self:SubTitle({ text = cat.title, localize = false })
		self:Toggle({
			name = "bc_toggle_" .. id,
			text = "Enabled",
			localize = false,
			desc = "Show an outline on " .. cat.title:lower() .. " pickups.",
			value = s.enabled,
			callback = callback(self, self, "SetEnabled", id),
			auto_select_on_hover = true,
		})
		self:Slider({
			name = "bc_slider_" .. id .. "_range",
			text = "Range (m)",
			localize = false,
			desc = "Distance up to which the outline of " .. cat.title:lower() .. " pickups is visible.",
			value = s.range,
			min = 1,
			max = 100,
			value_format = "%.0f",
			callback = callback(self, self, "SetRange", id),
			auto_select_on_hover = true,
		})
		self:Slider({
			name = "bc_slider_" .. id .. "_opacity",
			text = "Opacity",
			localize = false,
			desc = "Outline opacity of " .. cat.title:lower() .. " pickups.",
			value = s.opacity,
			min = 0,
			max = 1,
			callback = callback(self, self, "SetOpacity", id),
			auto_select_on_hover = true,
		})
		for _, ch in ipairs({ { "r", "Red" }, { "g", "Green" }, { "b", "Blue" } }) do
			self:Slider({
				name = "bc_slider_" .. id .. "_" .. ch[1],
				text = ch[2],
				localize = false,
				desc = "Outline color of " .. cat.title:lower() .. " pickups.",
				value = s[ch[1]],
				min = 0,
				max = 1,
				callback = callback(self, self, "SetColor", { id, ch[1] }),
				auto_select_on_hover = true,
			})
		end
	end

	self._reset_btn = self:LongRoundedButton2({
		name = "bc_options_reset",
		text = "bc_options_reset",
		localize = true,
		callback = callback(self, self, "Reset"),
		ignore_align = true,
		y = 832,
		x = 1472,
		auto_select_on_hover = true,
	})
	self:AutoBindNamedControlsEnd()
end

function BangLContoursMenu:init(...)
	BangLContoursMenu.super.init(self, ...)

	-- color swatches right of the subtitles, after the menu has been aligned
	self._previews = {}
	for id, title in pairs(self._titles) do
		local text = title._object
		local preview = text:parent():rect({
			name = "bc_color_preview_" .. id,
			w = 24,
			h = 24,
			x = text:right() + 12,
			layer = text:layer(),
		})
		preview:set_center_y(text:center_y())
		self._previews[id] = preview
		self:UpdatePreview(id)
	end
end

function BangLContoursMenu:UpdatePreview(id)
	local preview = self._previews and self._previews[id]
	if alive(preview) then
		preview:set_color(BangLContours:Color(id))
	end
end

function BangLContoursMenu:_additional_active_controls()
	return {
		self._reset_btn,
	}
end

function BangLContoursMenu:SetEnabled(id, value, item)
	BangLContours.settings[id].enabled = value and true or false
	BangLContours:Refresh()
	self._needs_save = true
end

function BangLContoursMenu:SetRange(id, value, item)
	BangLContours.settings[id].range = tonumber(value)
	BangLContours:Refresh()
	self._needs_save = true
end

function BangLContoursMenu:SetOpacity(id, value, item)
	BangLContours.settings[id].opacity = tonumber(value)
	BangLContours:Refresh()
	self._needs_save = true
end

function BangLContoursMenu:SetColor(params, value, item)
	local id, channel = params[1], params[2]
	BangLContours.settings[id][channel] = tonumber(value)
	self:UpdatePreview(id)
	BangLContours:Refresh()
	self._needs_save = true
end

function BangLContoursMenu:Reset(value, item)
	QuickMenu:new(
		managers.localization:text("bc_options_reset"),
		managers.localization:text("bc_options_reset_confirm"),
		{
			{
				text = managers.localization:text("dialog_yes"),
				callback = function()
					BangLContours:Reset()
					BangLContours:Refresh()
					self._needs_save = true
					self:ReloadMenu()
				end,
			},
			{
				text = managers.localization:text("dialog_no"),
				is_cancel_button = true,
			},
		},
		true
	)
end

function BangLContoursMenu:Close()
	if self._needs_save then
		BangLContours:Save()
	end
end

Hooks:Add("MenuComponentManagerInitialize", "BangLContoursMenu.MenuComponentManagerInitialize", function(self)
	RaidMenuHelper:CreateMenu({
		name = "bc_options_menu",
		name_id = "bc_options_menu_title",
		inject_list = "blt_options",
		icon = "waypoint_special_aim",
		class = BangLContoursMenu,
	})
end)
