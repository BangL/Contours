_G.BangLContours = _G.BangLContours or {}
local C = BangLContours

C._data_path = SavePath .. "BangLContours.json"
C.settings = {}

-- tweaks: interaction tweak_data ids that use the preset
C.CATEGORIES = {
	{
		id = "ammo",
		preset = "pickup_ammo",
		title = "Ammo",
		default = { 0, 0.64, 0.1 },
		tweaks = { "ammo_bag", "ammo_bag_small", "ammo_bag_big" },
	},
	{
		id = "health",
		preset = "pickup_health",
		title = "Health",
		default = { 1, 0.39, 0 },
		tweaks = { "health_bag", "health_bag_small", "health_bag_big" },
	},
	{
		id = "grenade",
		preset = "pickup_grenade",
		title = "Grenades",
		default = { 0, 0.5, 1 },
		tweaks = { "grenade_pickup_new" },
	},
	{
		id = "crowbar",
		preset = "pickup_crowbar",
		title = "Crowbar",
		default = { 1, 1, 1 },
		tweaks = { "gen_pku_crowbar" },
	},
	{
		id = "dogtags",
		preset = "pickup_dogtags",
		title = "Dog Tags",
		default = { 1, 1, 1 },
		tweaks = { "press_take_dogtags", "hold_take_dogtags" },
	},
	{
		id = "greed",
		preset = "pickup_greed",
		title = "Small Loot",
		default = { 1, 1, 1 },
		tweaks = { "press_take_loot", "press_take_loot_tight", "hold_take_loot" },
	},
}

C._tweaks = {}
for _, cat in ipairs(C.CATEGORIES) do
	for _, tweak in ipairs(cat.tweaks) do
		C._tweaks[tweak] = cat.id
	end
end

function C:Reset()
	self.settings = {}
	for _, cat in ipairs(self.CATEGORIES) do
		self.settings[cat.id] = {
			enabled = true,
			range = 10, -- meters
			opacity = 0.5,
			r = cat.default[1],
			g = cat.default[2],
			b = cat.default[3],
		}
	end
end

function C:Load()
	self:Reset()
	local file = io.open(self._data_path, "r")
	if file then
		local data = json.decode(file:read("*all"))
		file:close()
		if type(data) == "table" then
			for id, s in pairs(self.settings) do
				if type(data[id]) == "table" then
					for k in pairs(s) do
						if data[id][k] ~= nil then
							s[k] = data[id][k]
						end
					end
				end
			end
		end
	end
end

function C:Save()
	local file = io.open(self._data_path, "w+")
	if file then
		file:write(json.encode(self.settings))
		file:close()
	end
end

function C:Color(id)
	local s = self.settings[id]
	return Color(s.r, s.g, s.b)
end

function C:Apply(td)
	if not td or not td.contour or not td.interaction then
		return
	end

	for _, cat in ipairs(self.CATEGORIES) do
		local s = self.settings[cat.id]

		if not td.contour[cat.preset] then
			td.contour[cat.preset] = deep_clone(td.contour.deployable)
		end
		td.contour[cat.preset].standard_color = Vector3(s.r, s.g, s.b)

		for _, tweak in ipairs(cat.tweaks) do
			local t = td.interaction[tweak]
			if t then
				t.contour = cat.preset
				t.no_contour = not s.enabled or nil
			end
		end
	end
end

-- opacity: the value vanilla passed to set_contour (nil = derive from the active state)
function C:ApplyVariables(interaction, opacity)
	local id = self._tweaks[interaction.tweak_data]
	if not id then
		return
	end

	local s = self.settings[id]
	opacity = opacity or interaction._active and 1 or 0

	for _, m in ipairs(interaction._materials or {}) do
		m:set_variable(Idstring("contour_distance"), s.range * 100)
		if s.enabled then
			m:set_variable(Idstring("contour_opacity"), opacity * s.opacity)
		end
	end
end

-- applies the settings and re-sets the contour of already spawned pickups
function C:Refresh()
	self:Apply(tweak_data)

	for _, unit in ipairs(World:find_units_quick("all")) do
		local interaction = alive(unit) and unit:interaction()
		local id = interaction and self._tweaks[interaction.tweak_data]
		if id then
			if self.settings[id].enabled then
				interaction:set_active(interaction._active, false)
			else
				-- no_contour makes set_contour return early, so hide the outline directly
				for _, m in ipairs(interaction._materials or {}) do
					m:set_variable(Idstring("contour_opacity"), 0)
				end
			end
		end
	end
end

C:Load()

-- tweak_data is already instantiated at the end of tweakdata.lua, before this hook runs
C:Apply(tweak_data)

local init_original = TweakData.init
function TweakData:init(...)
	init_original(self, ...)
	C:Apply(self)
end
