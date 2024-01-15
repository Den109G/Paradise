/turf/simulated/openspace
	name = "open space"
	desc = "Watch your step!"
	icon = 'icons/turf/space.dmi'
	icon_state = "openspace"
	baseturf = /turf/simulated/openspace
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	pathing_pass_method = TURF_PATHING_PASS_PROC
	var/can_cover_up = TRUE
	var/can_build_on = TRUE

/turf/simulated/openspace/airless
	temperature = TCMB
	oxygen = 0
	nitrogen = 0

/turf/simulated/openspace/airless/planetary
	planetary_atmos = TRUE
