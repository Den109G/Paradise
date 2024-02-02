/turf
	icon = 'icons/turf/floors.dmi'
	level = 1
	luminosity = 1

	vis_flags = VIS_INHERIT_ID|VIS_INHERIT_PLANE	// Important for interaction with and visualization of openspace.

	var/intact = TRUE
	var/turf/baseturf = /turf/baseturf_bottom
	var/slowdown = 0 //negative for faster, positive for slower
	// It's a check that determines if the turf is transparent to reveal the stuff(pipes, safe, cables and e.t.c.) without looking on intact
	var/transparent_floor = TURF_NONTRANSPARENT

	var/real_layer = TURF_LAYER
	layer = MAP_EDITOR_TURF_LAYER

	///Properties for open tiles (/floor)
	/// All the gas vars, on the turf, are meant to be utilized for initializing a gas datum and setting its first gas values; the turf vars are never further modified at runtime; it is never directly used for calculations by the atmospherics system.
	var/oxygen = 0
	var/carbon_dioxide = 0
	var/nitrogen = 0
	var/toxins = 0
	var/sleeping_agent = 0
	var/agent_b = 0

	//Properties for airtight tiles (/wall)
	var/thermal_conductivity = 0.05
	var/heat_capacity = 1

	//Properties for both
	var/temperature = T20C

	//If set TRUE, won't init gas_mixture/air and shouldn't interact with atmos.
	var/blocks_air = FALSE
	// If this turf should initialize atmos adjacent turfs or not
	// Optimization, not for setting outside of initialize
	var/init_air = TRUE

	var/datum/pathnode/PNode = null //associated PathNode in the A* algorithm

	flags = 0

	var/image/obscured	//camerachunks

	var/changing_turf = FALSE

	var/list/blueprint_data //for the station blueprints, images of objects eg: pipes

	var/footstep = null
	var/barefootstep = null
	var/clawfootstep = null
	var/heavyfootstep = null

	/// How pathing algorithm will check if this turf is passable by itself (not including content checks). By default it's just density check.
	/// WARNING: Currently to use a density shortcircuiting this does not support dense turfs with special allow through function
	var/pathing_pass_method = TURF_PATHING_PASS_DENSITY


/turf/Initialize(mapload)
	SHOULD_CALL_PARENT(FALSE)
	if(initialized)
		stack_trace("Warning: [src]([type]) initialized multiple times!")
	initialized = TRUE

	if(layer == MAP_EDITOR_TURF_LAYER)
		layer = real_layer


	// by default, vis_contents is inherited from the turf that was here before
	vis_contents.Cut()

	levelupdate()
	if(smooth)
		queue_smooth(src)
	visibilityChanged()

	for(var/atom/movable/AM in src)
		Entered(AM)

	var/area/A = loc
	if(!IS_DYNAMIC_LIGHTING(src) && IS_DYNAMIC_LIGHTING(A))
		add_overlay(/obj/effect/fullbright)

	if(light_power && light_range)
		update_light()

	var/turf/T = GET_TURF_ABOVE(src)
	if(T)
		T.multiz_turf_new(src, DOWN)
		SEND_SIGNAL(T, COMSIG_TURF_MULTIZ_NEW, src, DOWN)
	T = GET_TURF_BELOW(src)
	if(T)
		T.multiz_turf_new(src, UP)
		SEND_SIGNAL(T, COMSIG_TURF_MULTIZ_NEW, src, UP)


	if(opacity)
		has_opaque_atom = TRUE

	return INITIALIZE_HINT_NORMAL

/turf/Destroy(force)
	. = QDEL_HINT_IWILLGC
	if(!changing_turf)
		stack_trace("Incorrect turf deletion")
	changing_turf = FALSE

	var/turf/V = GET_TURF_ABOVE(src)
	V?.multiz_turf_del(src, DOWN)
	V = GET_TURF_BELOW(src)
	V?.multiz_turf_del(src, UP)

	if(force)
		..()
		//this will completely wipe turf state
		var/turf/B = new world.turf(src)
		for(var/A in B.contents)
			qdel(A)
		return
	// Adds the adjacent turfs to the current atmos processing
	for(var/direction in GLOB.cardinal)
		if(atmos_adjacent_turfs & direction)
			var/turf/simulated/T = get_step(src, direction)
			if(istype(T))
				SSair.add_to_active(T)
	SSair.remove_from_active(src)
	visibilityChanged()
	QDEL_LIST(blueprint_data)
	initialized = FALSE
	..()

/turf/attack_hand(mob/user as mob)
	SEND_SIGNAL(src, COMSIG_ATOM_ATTACK_HAND, user)
	user.Move_Pulled(src)

/turf/ex_act(severity)
	return FALSE

/turf/rpd_act(mob/user, obj/item/rpd/our_rpd) //This is the default turf behaviour for the RPD; override it as required
	if(our_rpd.mode == RPD_ATMOS_MODE)
		our_rpd.create_atmos_pipe(user, src)
	else if(our_rpd.mode == RPD_DISPOSALS_MODE)
		for(var/obj/machinery/door/airlock/A in src)
			if(A.density)
				to_chat(user, span_warning("That type of pipe won't fit under [A]!"))
				return
		our_rpd.create_disposals_pipe(user, src)
	else if(our_rpd.mode == RPD_ROTATE_MODE)
		our_rpd.rotate_all_pipes(user, src)
	else if(our_rpd.mode == RPD_FLIP_MODE)
		our_rpd.flip_all_pipes(user, src)
	else if(our_rpd.mode == RPD_DELETE_MODE)
		our_rpd.delete_all_pipes(user, src)

/turf/bullet_act(obj/item/projectile/Proj)
	if(istype(Proj, /obj/item/projectile/beam/pulse))
		src.ex_act(2)
	..()
	return FALSE

/turf/bullet_act(obj/item/projectile/Proj)
	if(istype(Proj, /obj/item/projectile/bullet/gyro))
		explosion(src, -1, 0, 2, cause = Proj)
	..()
	return FALSE


/turf/Enter(atom/movable/mover, atom/oldloc)
	if(!mover)
		return TRUE

	// First, make sure it can leave its square
	if(isturf(mover.loc))
		// Nothing but border objects stop you from leaving a tile, only one loop is needed
		for(var/obj/obstacle in mover.loc)
			if(!obstacle.CheckExit(mover, src) && obstacle != mover && obstacle != oldloc)
				mover.Bump(obstacle, TRUE)
				return FALSE

	var/list/large_dense = list()
	//Next, check objects to block entry that are on the border
	for(var/atom/movable/border_obstacle in src)
		if(border_obstacle.flags & ON_BORDER)
			if(!border_obstacle.CanPass(mover, mover.loc, 1) && border_obstacle != oldloc)
				mover.Bump(border_obstacle, TRUE)
				return FALSE
		else
			large_dense += border_obstacle

	//Then, check the turf itself
	if(!CanPass(mover, src))
		mover.Bump(src, TRUE)
		return FALSE

	//Finally, check objects/mobs to block entry that are not on the border
	var/atom/movable/tompost_bump
	var/top_layer = 0
	for(var/atom/movable/obstacle in large_dense)
		if(!obstacle.CanPass(mover, mover.loc, 1) && obstacle != oldloc)
			if(obstacle.layer > top_layer)
				tompost_bump = obstacle
				top_layer = obstacle.layer	//Probably separate variable is a better solution, but its good for now.
	if(tompost_bump)
		mover.Bump(tompost_bump, TRUE)
		return FALSE

	return TRUE //Nothing found to block so return success!


/turf/Entered(atom/movable/M, atom/OL, ignoreRest = FALSE)
	..()
	if(ismob(M))
		var/mob/O = M
		if(!O.lastarea)
			O.lastarea = get_area(O.loc)

	// If an opaque movable atom moves around we need to potentially update visibility.
	if(M.opacity)
		has_opaque_atom = TRUE // Make sure to do this before reconsider_lights(), incase we're on instant updates. Guaranteed to be on in this case.
		reconsider_lights()

/turf/proc/levelupdate()
	for(var/obj/O in src)
		if(O.level == 1 && O.initialized) // Only do this if the object has initialized
			O.hide(src.intact)

// override for space turfs, since they should never hide anything
/turf/space/levelupdate()
	for(var/obj/O in src)
		if(O.level == 1 && O.initialized)
			O.hide(FALSE)

// Removes all signs of lattice on the pos of the turf -Donkieyo
/turf/proc/RemoveLattice()
	var/obj/structure/lattice/L = locate(/obj/structure/lattice, src)
	if(L && L.initialized)
		qdel(L)

/turf/proc/dismantle_wall(devastated = FALSE, explode = FALSE)
	return

/turf/proc/TerraformTurf(path, defer_change = FALSE, keep_icon = TRUE, ignore_air = FALSE)
	return ChangeTurf(path, defer_change, keep_icon, ignore_air)

//Creates a new turf
/turf/proc/ChangeTurf(path, defer_change = FALSE, keep_icon = TRUE, ignore_air = FALSE, copy_existing_baseturf = TRUE)
	switch(path)
		if(null)
			return
		if(/turf/baseturf_bottom)
			path = check_level_trait(z, ZTRAIT_BASETURF) || /turf/space
			if (!ispath(path))
				path = text2path(path)
				if (!ispath(path))
					warning("Z-level [z] has invalid baseturf '[check_level_trait(z, ZTRAIT_BASETURF)]'")
					path = /turf/space
	if(!GLOB.use_preloader && path == type) // Don't no-op if the map loader requires it to be reconstructed
		return src

	set_light(0)
	var/old_opacity = opacity
	var/old_dynamic_lighting = dynamic_lighting
	var/old_affecting_lights = affecting_lights
	var/old_lighting_object = lighting_object
	var/old_blueprint_data = blueprint_data
	var/old_obscured = obscured
	var/old_corners = corners
	var/old_type = type

	BeforeChange()

	var/old_baseturf = baseturf
	changing_turf = TRUE
	qdel(src)	//Just get the side effects and call Destroy
	var/turf/W = new path(src)
	if(copy_existing_baseturf)
		W.baseturf = old_baseturf

	if(!defer_change)
		W.AfterChange(ignore_air, oldType = old_type)
	W.blueprint_data = old_blueprint_data

	recalc_atom_opacity()

	if(SSlighting.initialized)
		recalc_atom_opacity()
		lighting_object = old_lighting_object
		affecting_lights = old_affecting_lights
		corners = old_corners
		if(old_opacity != opacity || dynamic_lighting != old_dynamic_lighting)
			reconsider_lights()

		if(dynamic_lighting != old_dynamic_lighting)
			if(IS_DYNAMIC_LIGHTING(src))
				lighting_build_overlay()
			else
				lighting_clear_overlay()

		for(var/turf/space/S in RANGE_TURFS(1, src)) //RANGE_TURFS is in code\__HELPERS\game.dm
			S.update_starlight()

	obscured = old_obscured

	return W

/turf/proc/BeforeChange()
	return

/turf/proc/is_safe()
	return FALSE

// I'm including `ignore_air` because BYOND lacks positional-only arguments
/turf/proc/AfterChange(ignore_air = FALSE, keep_cabling = FALSE, oldType = null) //called after a turf has been replaced in ChangeTurf()
	levelupdate()
	CalculateAdjacentTurfs()

	if(SSair && !ignore_air)
		SSair.add_to_active(src)

	//update firedoor adjacency
	var/list/turfs_to_check = get_adjacent_open_turfs(src) | src
	for(var/I in turfs_to_check)
		var/turf/T = I
		for(var/obj/machinery/door/firedoor/FD in T)
			FD.CalculateAffectingAreas()

	if(!keep_cabling && !can_have_cabling())
		for(var/obj/structure/cable/C in contents)
			qdel(C)

/turf/proc/ReplaceWithLattice()
	ChangeTurf(baseturf)
	new /obj/structure/lattice(locate(x, y, z))

/turf/proc/remove_plating(mob/user)
	return

/turf/proc/kill_creatures(mob/U = null)//Will kill people/creatures and damage mechs./N
//Useful to batch-add creatures to the list.
	for(var/mob/living/M in src)
		if(M == U)
			continue//Will not harm U. Since null != M, can be excluded to kill everyone.
		INVOKE_ASYNC(M, TYPE_PROC_REF(/mob, gib))
	for(var/obj/mecha/M in src)//Mecha are not gibbed but are damaged.
		INVOKE_ASYNC(M, TYPE_PROC_REF(/obj/mecha, take_damage), 100, "brute")

/turf/proc/Bless()
	flags |= NOJAUNT

// Defined here to avoid runtimes
/turf/proc/MakeDry(wet_setting = TURF_WET_WATER)
	return

/turf/proc/burn_down()
	return

/////////////////////////////////////////////////////////////////////////
// Navigation procs
// Used for A-star pathfinding
////////////////////////////////////////////////////////////////////////

///////////////////////////
//Cardinal only movements
///////////////////////////

// Returns the surrounding cardinal turfs with open links
// Including through doors openable with the ID
/turf/proc/CardinalTurfsWithAccess(var/obj/item/card/id/ID)
	var/list/L = new()
	var/turf/simulated/T

	for(var/dir in GLOB.cardinal)
		T = get_step(src, dir)
		if(istype(T) && !T.density)
			if(!LinkBlockedWithAccess(src, T, ID))
				L.Add(T)
	return L

// Returns the surrounding cardinal turfs with open links
// Don't check for ID, doors passable only if open
/turf/proc/CardinalTurfs()
	var/list/L = new()
	var/turf/simulated/T

	for(var/dir in GLOB.cardinal)
		T = get_step(src, dir)
		if(istype(T) && !T.density)
			if(!CanAtmosPass(T, FALSE))
				L.Add(T)
	return L

///////////////////////////
//All directions movements
///////////////////////////

// Returns the surrounding simulated turfs with open links
// Including through doors openable with the ID
/turf/proc/AdjacentTurfsWithAccess(obj/item/card/id/ID = null, list/closed)//check access if one is passed
	var/list/L = new()
	var/turf/simulated/T
	for(var/dir in GLOB.alldirs2) //arbitrarily ordered list to favor non-diagonal moves in case of ties
		T = get_step(src, dir)
		if(T in closed) //turf already proceeded in A*
			continue
		if(istype(T) && !T.density)
			if(!LinkBlockedWithAccess(src, T, ID))
				L.Add(T)
	return L

//Idem, but don't check for ID and goes through open doors
/turf/proc/AdjacentTurfs(list/closed)
	var/list/L = new()
	var/turf/simulated/T
	for(var/dir in GLOB.alldirs2) //arbitrarily ordered list to favor non-diagonal moves in case of ties
		T = get_step(src, dir)
		if(T in closed) //turf already proceeded by A*
			continue
		if(istype(T) && !T.density)
			if(!CanAtmosPass(T, FALSE))
				L.Add(T)
	return L

// check for all turfs, including space ones
/turf/proc/AdjacentTurfsSpace(obj/item/card/id/ID = null, list/closed)//check access if one is passed
	var/list/L = new()
	var/turf/T
	for(var/dir in GLOB.alldirs2) //arbitrarily ordered list to favor non-diagonal moves in case of ties
		T = get_step(src, dir)
		if(T in closed) //turf already proceeded by A*
			continue
		if(istype(T) && !T.density)
			if(!ID)
				if(!CanAtmosPass(T, FALSE))
					L.Add(T)
			else
				if(!LinkBlockedWithAccess(src, T, ID))
					L.Add(T)
	return L

//////////////////////////////
//Distance procs
//////////////////////////////

//Distance associates with all directions movement
/turf/proc/Distance(turf/T)
	return get_dist(src, T)

//  This Distance proc assumes that only cardinal movement is
//  possible. It results in more efficient (CPU-wise) pathing
//  for bots and anything else that only moves in cardinal dirs.
/turf/proc/Distance_cardinal(turf/T)
	if(!src || !T)
		return 0
	return abs(src.x - T.x) + abs(src.y - T.y)

////////////////////////////////////////////////////

/turf/acid_act(acidpwr, acid_volume)
	. = TRUE
	var/acid_type = /obj/effect/acid
	if(acidpwr >= 200) //alien acid power
		acid_type = /obj/effect/acid/alien
	var/has_acid_effect = FALSE
	for(var/obj/O in src)
		if(intact && O.level == 1) //hidden under the floor
			continue
		if(istype(O, acid_type))
			var/obj/effect/acid/A = O
			A.acid_level = min(A.level + acid_volume * acidpwr, 12000)//capping acid level to limit power of the acid
			has_acid_effect = 1
			continue
		O.acid_act(acidpwr, acid_volume)
	if(!has_acid_effect)
		new acid_type(src, acidpwr, acid_volume)

/turf/proc/acid_melt()
	return

/turf/handle_fall(mob/faller, forced)
	faller.lying = pick(90, 270)
	if(!forced)
		return
	if(faller.has_gravity())
		playsound(src, "bodyfall", 50, TRUE)

/turf/singularity_act()
	if(intact)
		for(var/obj/O in contents) //this is for deleting things like wires contained in the turf
			if(O.level != 1)
				continue
			if(O.invisibility == INVISIBILITY_MAXIMUM)
				O.singularity_act()
	ChangeTurf(baseturf)
	return 2

/turf/proc/visibilityChanged()
	if(SSticker)
		GLOB.cameranet.updateVisibility(src)

/turf/attackby(obj/item/I, mob/user, params)
	SEND_SIGNAL(src, COMSIG_PARENT_ATTACKBY, I, user, params)
	if(can_lay_cable())
		if(istype(I, /obj/item/stack/cable_coil))
			var/obj/item/stack/cable_coil/C = I
			for(var/obj/structure/cable/LC in src)
				if(LC.d1 == 0 || LC.d2 == 0)
					LC.attackby(C, user)
					return
			C.place_turf(src, user)
			return TRUE
		else if(istype(I, /obj/item/twohanded/rcl))
			var/obj/item/twohanded/rcl/R = I
			if(R.loaded)
				for(var/obj/structure/cable/LC in src)
					if(LC.d1 == 0 || LC.d2 == 0)
						LC.attackby(R, user)
						return
				R.loaded.place_turf(src, user)
				R.is_empty(user)

	return FALSE

/turf/proc/can_have_cabling()
	return TRUE

/turf/proc/can_lay_cable()
	return can_have_cabling() & !intact


/turf/proc/get_smooth_underlay_icon(mutable_appearance/underlay_appearance, turf/asking_turf, adjacency_dir)
	underlay_appearance.icon = icon
	underlay_appearance.icon_state = icon_state
	underlay_appearance.dir = adjacency_dir
	return TRUE

/turf/proc/add_blueprints(atom/movable/AM)
	var/image/I = new
	I.plane = GAME_PLANE
	I.layer = OBJ_LAYER
	I.appearance = AM.appearance
	I.appearance_flags = RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
	I.loc = src
	I.setDir(AM.dir)
	I.alpha = 128
	LAZYADD(blueprint_data, I)

/turf/proc/add_blueprints_preround(atom/movable/AM)
	if(!SSticker || SSticker.current_state != GAME_STATE_PLAYING)
		add_blueprints(AM)

/turf/proc/empty(turf_type = /turf/space)
	// Remove all atoms except observers, landmarks, docking ports, and (un)`simulated` atoms (lighting overlays)
	var/turf/T0 = src
	for(var/X in T0.GetAllContents())
		var/atom/A = X
		if(!A.simulated)
			continue
		if(istype(A, /mob/dead))
			continue
		if(istype(A, /obj/effect/landmark))
			continue
		if(istype(A, /obj/docking_port))
			continue
		qdel(A, force = TRUE)

	T0.ChangeTurf(turf_type)

	SSair.remove_from_active(T0)
	T0.CalculateAdjacentTurfs()
	SSair.add_to_active(T0, TRUE)

/turf/AllowDrop()
	return TRUE

//The zpass procs exist to be overriden, not directly called
//use can_z_pass for that
///If we'd allow anything to travel into us
/turf/proc/zPassIn(direction)
	return FALSE

///If we'd allow anything to travel out of us
/turf/proc/zPassOut(direction)
	return FALSE

//direction is direction of travel of air
/turf/proc/zAirIn(direction, turf/source)
	return FALSE

//direction is direction of travel of air
/turf/proc/zAirOut(direction, turf/source)
	return FALSE

/turf/proc/multiz_turf_del(turf/T, dir)
	SEND_SIGNAL(src, COMSIG_TURF_MULTIZ_DEL, T, dir)

/turf/proc/multiz_turf_new(turf/T, dir)
	SEND_SIGNAL(src, COMSIG_TURF_MULTIZ_NEW, T, dir)

///Called each time the target falls down a z level possibly making their trajectory come to a halt. see __DEFINES/movement.dm.
/turf/proc/zImpact(atom/movable/falling, levels = 1, turf/prev_turf, flags = NONE)
	var/list/falling_movables = falling.get_z_move_affected()
	var/list/falling_mov_names
	for(var/atom/movable/falling_mov as anything in falling_movables)
		falling_mov_names += falling_mov.name
	for(var/i in contents)
		var/atom/thing = i
		flags |= thing.intercept_zImpact(falling_movables, levels)
		if(flags & FALL_STOP_INTERCEPTING)
			break
	if(prev_turf && !(flags & FALL_NO_MESSAGE))
		for(var/mov_name in falling_mov_names)
			prev_turf.visible_message(span_danger("[mov_name] falls through [prev_turf]!"))
	if(!(flags & FALL_INTERCEPTED) && zFall(falling, levels + 1)) // Can we fall down? If so return false
		return FALSE
	for(var/atom/movable/falling_mov as anything in falling_movables)
		if(!(flags & FALL_RETAIN_PULL))
			falling_mov.stop_pulling()
		if(!(flags & FALL_INTERCEPTED))
			falling_mov.onZImpact(src, levels)
		if(falling_mov.pulledby && (falling_mov.z != falling_mov.pulledby.z || get_dist(falling_mov, falling_mov.pulledby) > 1))
			falling_mov.pulledby.stop_pulling()
	return TRUE

/// Precipitates a movable (plus whatever buckled to it) to lower z levels if possible and then calls zImpact()
/turf/proc/zFall(atom/movable/falling, levels = 1, force = FALSE, falling_from_move = FALSE)
	var/turf/target = get_step_multiz(src, DOWN)
	if(!target)
		return FALSE
	var/isliving = isliving(falling)
	if(!isliving && !isobj(falling))
		return FALSE
	var/atom/movable/living_buckled
	if(isliving)
		var/mob/living/falling_living = falling
		//relay this mess to whatever the mob is buckled to.
		if(falling_living.buckled)
			living_buckled = falling
			falling = falling_living.buckled
	if(!falling_from_move && falling.currently_z_moving)
		return FALSE
	if(!force && !falling.can_z_move(DOWN, src, target, ZMOVE_FALL_FLAGS))
		falling.set_currently_z_moving(FALSE, TRUE)
		living_buckled?.set_currently_z_moving(FALSE, TRUE)
		return FALSE

	// So it doesn't trigger other zFall calls. Cleared on zMove.
	falling.set_currently_z_moving(CURRENTLY_Z_FALLING)
	living_buckled?.set_currently_z_moving(CURRENTLY_Z_FALLING)

	falling.zMove(null, target, ZMOVE_CHECK_PULLEDBY)
	target.zImpact(falling, levels, src)
	return TRUE


/**
 * Returns adjacent turfs to this turf that are reachable, in all cardinal directions
 *
 * Arguments:
 * * caller: The movable, if one exists, being used for mobility checks to see what tiles it can reach
 * * ID: An ID card that decides if we can gain access to doors that would otherwise block a turf
 * * simulated_only: Do we only worry about turfs with simulated atmos, most notably things that aren't space?
 * * no_id: When true, doors with public access will count as impassible
*/
/turf/proc/reachableAdjacentTurfs(caller, ID, simulated_only, no_id = FALSE)
	var/static/space_type_cache = typecacheof(/turf/space)
	. = list()

	for(var/iter_dir in GLOB.cardinal)
		var/turf/turf_to_check = get_step(src, iter_dir)
		if(!turf_to_check || (simulated_only && space_type_cache[turf_to_check.type]))
			continue
		if(turf_to_check.density || LinkBlockedWithAccess(turf_to_check, caller, ID, no_id = no_id))
			continue
		. += turf_to_check


/**
 * Makes an image of up to 20 things on a turf + the turf.
 */
/turf/proc/photograph(limit = 20)
	var/image/I = new()
	I.add_overlay(src)
	for(var/V in contents)
		var/atom/A = V
		if(A.invisibility)
			continue
		I.add_overlay(A)
		if(limit)
			limit--
		else
			return I
	return I


/turf/hit_by_thrown_carbon(mob/living/carbon/human/C, datum/thrownthing/throwingdatum, damage, mob_hurt, self_hurt)
	if(mob_hurt || !density)
		return
	playsound(src, 'sound/weapons/punch1.ogg', 35, TRUE)
	C.visible_message(span_danger("[C] slams into [src]!"),
					span_userdanger("You slam into [src]!"))
	C.take_organ_damage(damage)
	C.Weaken(3 SECONDS)

