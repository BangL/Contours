-- vanilla only shows the grenade contour for the thrower (setting throwable_contours), we want it on all pickups.
-- also applies the configured range and opacity to the pickup materials.
for _, class in ipairs({ AmmoPickupInteractionExt, HealthPickupInteractionExt, GrenadePickupInteractionExt }) do
	function class:set_contour(color, opacity)
		class.super.set_contour(self, color, opacity)
		BangLContours:ApplyVariables(self, opacity)
	end
end
