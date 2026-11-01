-- vanilla only shows the grenade contour for the thrower (setting throwable_contours), we want it on all pickups (plus crowbar, dog tags and greed items).
-- also applies the configured range and opacity to the pickup materials.
for _, class in ipairs({
	AmmoPickupInteractionExt,
	HealthPickupInteractionExt,
	GrenadePickupInteractionExt,
	SpecialEquipmentInteractionExt,
	SmallLootInteractionExt,
	GreedItemInteractionExt,
}) do
	function class:set_contour(color, opacity)
		class.super.set_contour(self, color, opacity)
		BangLContours:ApplyVariables(self, opacity)
	end
end
