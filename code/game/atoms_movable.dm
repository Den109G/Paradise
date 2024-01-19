/atom/movable
	layer = 3
	appearance_flags = TILE_BOUND
	glide_size = 8 // Default, adjusted when mobs move based on their movement delays
	var/last_move = null
	var/anchored = 0
	var/move_resist = MOVE_RESIST_DEFAULT
	var/move_force = MOVE_FORCE_DEFAULT
	var/pull_force = PULL_FORCE_DEFAULT
	// var/elevation = 2    - not used anywhere
	var/move_speed = 10
	var/l_move_time = 1
	var/datum/thrownthing/throwing = null
	var/throw_speed = 2 //How many tiles to move per ds when being thrown. Float values are fully supported
	var/throw_range = 7
	var/no_spin = 0
	var/no_spin_thrown = 0
	var/moved_recently = 0
	var/mob/pulledby = null
	var/atom/movable/pulling
	var/throwforce = 0
	var/canmove = 1
	var/pull_push_speed_modifier = 1

	var/inertia_dir = 0
	var/atom/inertia_last_loc
	var/inertia_moving = 0
	var/inertia_next_move = 0
	var/inertia_move_delay = 5

	var/moving_diagonally = 0 //0: not doing a diagonal move. 1 and 2: doing the first/second step of the diagonal move
	var/list/client_mobs_in_contents

	/// Either FALSE, [EMISSIVE_BLOCK_GENERIC], or [EMISSIVE_BLOCK_UNIQUE]
	var/blocks_emissive = FALSE
	///Internal holder for emissive blocker object, do not use directly use blocks_emissive
	var/atom/movable/emissive_blocker/em_block
	/// Icon state for thought bubbles. Normally set by mobs.
	var/thought_bubble_image = "thought_bubble"

	///is the mob currently ascending or descending through z levels?
	var/currently_z_moving

/atom/movable/attempt_init(loc, ...)
	var/turf/T = get_turf(src)
	if(T && SSatoms.initialized != INITIALIZATION_INSSATOMS && GLOB.space_manager.is_zlevel_dirty(T.z))
		GLOB.space_manager.postpone_init(T.z, src)
		return
	. = ..()


/atom/movable/Initialize(mapload)
	. = ..()
	switch(blocks_emissive)
		if(EMISSIVE_BLOCK_GENERIC)
			var/mutable_appearance/gen_emissive_blocker = mutable_appearance(icon, icon_state, plane = EMISSIVE_PLANE, alpha = src.alpha)
			gen_emissive_blocker.color = EM_BLOCK_COLOR
			gen_emissive_blocker.dir = dir
			gen_emissive_blocker.appearance_flags |= appearance_flags
			AddComponent(/datum/component/emissive_blocker, gen_emissive_blocker)
		if(EMISSIVE_BLOCK_UNIQUE)
			render_target = ref(src)
			em_block = new(src, render_target)
			add_overlay(list(em_block))


/atom/movable/Destroy()
	unbuckle_all_mobs(force = TRUE)

	. = ..()
	if(loc)
		loc.handle_atom_del(src)
	for(var/atom/movable/AM in contents)
		qdel(AM)
	LAZYCLEARLIST(client_mobs_in_contents)
	forceMove(null)
	if(pulledby)
		pulledby.stop_pulling()
	if(orbiting)
		stop_orbit()


/atom/movable/proc/update_emissive_block()
	if(!em_block && !QDELETED(src))
		render_target = ref(src)
		em_block = new(src, render_target)
	add_overlay(list(em_block))


//Returns an atom's power cell, if it has one. Overload for individual items.
/atom/movable/proc/get_cell()
	return

//Handles special effects on teleporting. Overload for some items if you want to do so.
/atom/movable/proc/on_teleported()
	return


/atom/movable/proc/start_pulling(atom/movable/AM, force = pull_force, show_message = FALSE)
	var/mob/mob_target = AM
	if(ismob(mob_target) && mob_target.buckled)
		AM = mob_target.buckled

	if(QDELETED(AM) || QDELETED(src))
		return FALSE
	if(!(AM.can_be_pulled(src, force, show_message)))
		return FALSE

	if(pulling && AM == pulling && src == AM.pulledby)	// are we trying to pull something we are already pulling?
		return FALSE

	var/atom/movable/previous_puller = null
	if(AM.pulledby)
		previous_puller = AM.pulledby
		previous_puller.stop_pulling() // an object can't be pulled by two mobs at once.

	pulling = AM
	AM.pulledby = src

	mob_target = ismob(AM) ? AM : (AM.buckled_mobs && length(AM.buckled_mobs)) ? AM.buckled_mobs[1] : null
	if(mob_target)
		if(previous_puller)
			add_attack_logs(AM, previous_puller, "pulled from", ATKLOG_ALMOSTALL)
			if(show_message)
				visible_message(span_danger("[src] перехватил[genderize_ru(gender,"","а","о","и")] [mob_target] у [previous_puller]."))
		else
			add_attack_logs(src, mob_target, "pulls", ATKLOG_ALMOSTALL)
			if(show_message)
				visible_message(span_warning("[src] схватил[genderize_ru(gender,"","а","о","и")] [mob_target]!"))
		mob_target.LAssailant = iscarbon(src) ? src : null

	return TRUE


/atom/movable/proc/stop_pulling()
	if(pulling)
		pulling.pulledby = null
		var/mob/living/ex_pulled = pulling
		pulling = null
		pulledby = null
		if(isliving(ex_pulled))
			var/mob/living/L = ex_pulled
			L.update_canmove()// mob gets up if it was lyng down in a chokehold

/**
 * Checks if the pulling and pulledby should be stopped because they're out of reach.
 * If z_allowed is TRUE, the z level of the pulling will be ignored.This is to allow things to be dragged up and down stairs.
 */
/atom/movable/proc/check_pulling(only_pulling = FALSE, z_allowed = FALSE)
	if(pulling)
		if(get_dist(src, pulling) > 1 || (z != pulling.z && !z_allowed))
			stop_pulling()
		else if(!isturf(loc))
			stop_pulling()
		else if(pulling && !isturf(pulling.loc) && pulling.loc != loc) //to be removed once all code that changes an object's loc uses forceMove().
			log_debug("[src]'s pull on [pulling] wasn't broken despite [pulling] being in [pulling.loc]. Pull stopped manually.")
			stop_pulling()
		else if(pulling.anchored || pulling.move_resist > move_force)
			stop_pulling()
	if(!only_pulling && pulledby && moving_diagonally != FIRST_DIAG_STEP && (get_dist(src, pulledby) > 1 || z != pulledby.z)) //separated from our puller and not in the middle of a diagonal move.
		pulledby.stop_pulling()

/atom/movable/proc/can_be_pulled(atom/movable/user, force, show_message = FALSE)
	if(src == user || !isturf(loc))
		return FALSE
	if(anchored || move_resist == INFINITY)
		if(show_message)
			to_chat(user, span_warning("Похоже, [src.name] прикрепл[genderize_ru(src.gender,"ён","ена","ено","ены")] к полу!"))
		return FALSE
	if(throwing)
		return FALSE
	if(force < (move_resist * MOVE_FORCE_PULL_RATIO))
		if(show_message)
			to_chat(user, span_warning("[src.name] слишком тяжелый!"))
		return FALSE
	return TRUE

// Used in shuttle movement and AI eye stuff.
// Primarily used to notify objects being moved by a shuttle/bluespace fuckup.
/atom/movable/proc/setLoc(var/T, var/teleported=0)
	loc = T


/atom/movable/Move(atom/newloc, direct = NONE, movetime)
	if(!loc || !newloc)
		return FALSE

	var/atom/oldloc = loc

	if(loc != newloc)
		if(movetime > 0)
			glide_for(movetime)

		if(!(direct & (direct - 1))) //Cardinal move
			. = ..(newloc, direct) // don't pass up movetime

		else //Diagonal move, split it into cardinal moves
			moving_diagonally = FIRST_DIAG_STEP
			var/first_step_dir
			// The `&& moving_diagonally` checks are so that a forceMove taking
			// place due to a Crossed, Bumped, etc. call will interrupt
			// the second half of the diagonal movement, or the second attempt
			// at a first half if the cardinal Move() fails because we hit something.
			if(direct & NORTH)
				if(direct & EAST)
					if(Move(get_step(src,  NORTH),  NORTH) && moving_diagonally)
						first_step_dir = NORTH
						moving_diagonally = SECOND_DIAG_STEP
						. = Move(get_step(src,  EAST),  EAST)
					else if(moving_diagonally && Move(get_step(src,  EAST),  EAST))
						first_step_dir = EAST
						moving_diagonally = SECOND_DIAG_STEP
						. = Move(get_step(src,  NORTH),  NORTH)

				else if(direct & WEST)
					if(Move(get_step(src,  NORTH),  NORTH) && moving_diagonally)
						first_step_dir = NORTH
						moving_diagonally = SECOND_DIAG_STEP
						. = Move(get_step(src,  WEST),  WEST)
					else if(moving_diagonally && Move(get_step(src,  WEST),  WEST))
						first_step_dir = WEST
						moving_diagonally = SECOND_DIAG_STEP
						. = Move(get_step(src,  NORTH),  NORTH)

			else if(direct & SOUTH)
				if(direct & EAST)
					if(Move(get_step(src,  SOUTH),  SOUTH) && moving_diagonally)
						first_step_dir = SOUTH
						moving_diagonally = SECOND_DIAG_STEP
						. = Move(get_step(src,  EAST),  EAST)
					else if(moving_diagonally && Move(get_step(src,  EAST),  EAST))
						first_step_dir = EAST
						moving_diagonally = SECOND_DIAG_STEP
						. = Move(get_step(src,  SOUTH),  SOUTH)

				else if(direct & WEST)
					if(Move(get_step(src,  SOUTH),  SOUTH) && moving_diagonally)
						first_step_dir = SOUTH
						moving_diagonally = SECOND_DIAG_STEP
						. = Move(get_step(src,  WEST),  WEST)
					else if(moving_diagonally && Move(get_step(src,  WEST),  WEST))
						first_step_dir = WEST
						moving_diagonally = SECOND_DIAG_STEP
						. = Move(get_step(src,  SOUTH),  SOUTH)

			if(moving_diagonally == SECOND_DIAG_STEP)
				if(!.)
					setDir(first_step_dir)
				else if(!inertia_moving)
					inertia_next_move = world.time + inertia_move_delay
					newtonian_move(direct)
			moving_diagonally = NONE
			return

	if(!loc || (loc == oldloc && oldloc != newloc))
		last_move = 0
		set_currently_z_moving(FALSE, TRUE)
		return

	if(.)
		Moved(oldloc, direct, FALSE)

	last_move = direct
	move_speed = world.time - l_move_time
	l_move_time = world.time

	if(. && has_buckled_mobs() && !handle_buckled_mob_movement(loc, direct, movetime)) //movement failed due to buckled mob
		. = FALSE

	if(currently_z_moving)
		if(. && loc == newloc)
			var/turf/pitfall = get_turf(src)
			pitfall.zFall(src, falling_from_move = TRUE)
		else
			set_currently_z_moving(FALSE, TRUE)

// Called after a successful Move(). By this point, we've already moved
/atom/movable/proc/Moved(atom/OldLoc, Dir, Forced = FALSE)

	if(!inertia_moving)
		inertia_next_move = world.time + inertia_move_delay
		newtonian_move(Dir)
	if(length(client_mobs_in_contents))
		update_parallax_contents()

	SEND_SIGNAL(src, COMSIG_MOVABLE_MOVED, OldLoc, Dir, Forced)

	var/datum/light_source/L
	var/thing
	for (thing in light_sources) // Cycle through the light sources on this atom and tell them to update.
		L = thing
		L.source_atom.update_light()
	return TRUE

// Change glide size for the duration of one movement
/atom/movable/proc/glide_for(movetime)
	if(movetime)
		glide_size = world.icon_size/max(DS2TICKS(movetime), 1)
//		spawn(movetime)
//			glide_size = initial(glide_size)
//	else
//		glide_size = initial(glide_size)

// Previously known as HasEntered()
// This is automatically called when something enters your square
/atom/movable/Crossed(atom/movable/AM, oldloc)
	SEND_SIGNAL(src, COMSIG_MOVABLE_CROSSED, AM)
	SEND_SIGNAL(AM, COMSIG_CROSSED_MOVABLE, src)

/atom/movable/Uncrossed(atom/movable/AM)
	SEND_SIGNAL(src, COMSIG_MOVABLE_UNCROSSED, AM)

/atom/movable/Bump(atom/A, yes) //the "yes" arg is to differentiate our Bump proc from byond's, without it every Bump() call would become a double Bump().
	if(A && yes)
		SEND_SIGNAL(src, COMSIG_MOVABLE_BUMP, A)
		if(throwing)
			throwing.finalize(A)
			. = TRUE
			if(QDELETED(A))
				return
		A.Bumped(src)

/// Sets the currently_z_moving variable to a new value. Used to allow some zMovement sources to have precedence over others.
/atom/movable/proc/set_currently_z_moving(new_z_moving_value, forced = FALSE)
	if(forced)
		currently_z_moving = new_z_moving_value
		return TRUE
	var/old_z_moving_value = currently_z_moving
	currently_z_moving = max(currently_z_moving, new_z_moving_value)
	return (currently_z_moving > old_z_moving_value)

/atom/movable/proc/forceMove(atom/destination)
	var/turf/old_loc = loc
	var/area/old_area = get_area(src)
	var/area/new_area = get_area(destination)
	loc = destination
	moving_diagonally = 0

	if(old_loc)
		old_loc.Exited(src, destination)
		for(var/atom/movable/AM in old_loc)
			AM.Uncrossed(src)

	if(old_area && (new_area != old_area))
		old_area.Exited(src)

	if(destination)
		destination.Entered(src)
		for(var/atom/movable/AM in destination)
			if(AM == src)
				continue
			AM.Crossed(src, old_loc)

		if(new_area && (old_area != new_area))
			new_area.Entered(src)

		var/turf/oldturf = get_turf(old_loc)
		var/turf/destturf = get_turf(destination)
		var/old_z = (oldturf ? oldturf.z : null)
		var/dest_z = (destturf ? destturf.z : null)
		if(old_z != dest_z)
			onTransitZ(old_z, dest_z)

	Moved(old_loc, NONE, TRUE)

	return 1


/atom/movable/proc/move_to_null_space()

	var/atom/old_loc = loc
	var/is_multi_tile = bound_width > world.icon_size || bound_height > world.icon_size

	if(old_loc)
		loc = null
		var/area/old_area = get_area(old_loc)
		if(is_multi_tile && isturf(old_loc))
			for(var/atom/old_loc_multi as anything in locs)
				old_loc_multi.Exited(src, NONE)
		else
			old_loc.Exited(src, NONE)

		if(old_area)
			old_area.Exited(src, NONE)

	Moved(old_loc, NONE, TRUE)

/atom/movable/proc/onZImpact(turf/impacted_turf, levels, impact_flags = TRUE)
	SHOULD_CALL_PARENT(TRUE)
	if(!(impact_flags & ZIMPACT_NO_MESSAGE))
		visible_message(span_danger("[src] crashes into [impacted_turf]!"), span_userdanger("You crash into [impacted_turf]!"))
	if(!(impact_flags & ZIMPACT_NO_SPIN))
		INVOKE_ASYNC(src, PROC_REF(SpinAnimation), 5, 2)
	SEND_SIGNAL(src, COMSIG_ATOM_ON_Z_IMPACT, impacted_turf, levels)

	stack_trace("[currently_z_moving], [levels]")
	return TRUE

/*
 * The core multi-z movement proc. Used to move a movable through z levels.
 * If target is null, it'll be determined by the can_z_move proc, which can potentially return null if
 * conditions aren't met (see z_move_flags defines in __DEFINES/movement.dm for info) or if dir isn't set.
 * Bear in mind you don't need to set both target and dir when calling this proc, but at least one or two.
 * This will set the currently_z_moving to CURRENTLY_Z_MOVING_GENERIC if unset, and then clear it after
 * Forcemove().
 *
 *
 * Args:
 * * dir: the direction to go, UP or DOWN, only relevant if target is null.
 * * target: The target turf to move the src to. Set by can_z_move() if null.
 * * z_move_flags: bitflags used for various checks in both this proc and can_z_move(). See __DEFINES/movement.dm.
 */
/atom/movable/proc/zMove(dir, turf/target, z_move_flags = ZMOVE_FLIGHT_FLAGS)
	if(!target)
		target = can_z_move(dir, get_turf(src), null, z_move_flags)
		if(!target)
			set_currently_z_moving(FALSE, TRUE)
			return FALSE

	var/list/moving_movs = get_z_move_affected(z_move_flags)

	for(var/atom/movable/movable as anything in moving_movs)
		movable.currently_z_moving = currently_z_moving || CURRENTLY_Z_MOVING_GENERIC
		movable.forceMove(target)
		movable.set_currently_z_moving(FALSE, TRUE)
	// This is run after ALL movables have been moved, so pulls don't get broken unless they are actually out of range.
	if(z_move_flags & ZMOVE_CHECK_PULLS)
		for(var/atom/movable/moved_mov as anything in moving_movs)
			if(z_move_flags & ZMOVE_CHECK_PULLEDBY && moved_mov.pulledby && (moved_mov.z != moved_mov.pulledby.z || get_dist(moved_mov, moved_mov.pulledby) > 1))
				moved_mov.pulledby.stop_pulling()
			if(z_move_flags & ZMOVE_CHECK_PULLING)
				moved_mov.check_pulling(TRUE)
	return TRUE

/// Returns a list of movables that should also be affected when src moves through zlevels, and src.
/atom/movable/proc/get_z_move_affected(z_move_flags)
	. = list(src)
	if(buckled_mobs)
		. |= buckled_mobs
	if(!(z_move_flags & ZMOVE_INCLUDE_PULLED))
		return
	for(var/mob/living/buckled as anything in buckled_mobs)
		if(buckled.pulling)
			. |= buckled.pulling
	if(pulling)
		. |= pulling

/**
 * Checks if the destination turf is elegible for z movement from the start turf to a given direction and returns it if so.
 * Args:
 * * direction: the direction to go, UP or DOWN, only relevant if target is null.
 * * start: Each destination has a starting point on the other end. This is it. Most of the times the location of the source.
 * * z_move_flags: bitflags used for various checks. See __DEFINES/movement.dm.
 * * rider: A living mob in control of the movable. Only non-null when a mob is riding a vehicle through z-levels.
 */
/atom/movable/proc/can_z_move(direction, turf/start, turf/destination, z_move_flags = ZMOVE_FLIGHT_FLAGS, mob/living/rider)
	if(!start)
		start = get_turf(src)
		if(!start)
			return FALSE
	if(!direction)
		if(!destination)
			return FALSE
		direction = get_dir_multiz(start, destination)
	if(direction != UP && direction != DOWN)
		return FALSE
	if(!destination)
		destination = get_step_multiz(start, direction)
		if(!destination)
			if(z_move_flags & ZMOVE_FEEDBACK)
				to_chat(rider || src, "<span class='warning'>There's nowhere to go in that direction!</span>")
			return FALSE
	var/mob/living/L = src
	var/flyoting = FALSE
	if(istype(L))
		flyoting = L.flying || L.floating // One is from /mob, the OTHER goes from /mob/living. WTF
	if(z_move_flags & ZMOVE_FALL_CHECKS && (throwing || flyoting || !has_gravity(start)))
		return FALSE
	if(z_move_flags & ZMOVE_CAN_FLY_CHECKS && flyoting && has_gravity(start))
		if(z_move_flags & ZMOVE_FEEDBACK)
			if(rider)
				to_chat(rider, "<span class='notice'>[src] is is not capable of flight.<span>")
			else
				to_chat(src, "<span class='notice'>You are not Superman.<span>")
		return FALSE
	if((!(z_move_flags & ZMOVE_IGNORE_OBSTACLES) && !(start.zPassOut(direction) && destination.zPassIn(direction))) || (!(z_move_flags & ZMOVE_ALLOW_ANCHORED) && anchored))
		if(z_move_flags & ZMOVE_FEEDBACK)
			to_chat(rider || src, "<span class='warning'>You couldn't move there!</span>")
		return FALSE
	return destination //used by some child types checks and zMove()

/atom/movable/proc/onTransitZ(old_z,new_z)
	for(var/item in src) // Notify contents of Z-transition. This can be overridden if we know the items contents do not care.
		var/atom/movable/AM = item
		AM.onTransitZ(old_z,new_z)
	SEND_SIGNAL(src, COMSIG_MOVABLE_Z_CHANGED)

/mob/living/forceMove(atom/destination)
	if(buckled)
		addtimer(CALLBACK(src, PROC_REF(check_buckled)), 1, TIMER_UNIQUE)
	if(has_buckled_mobs())
		for(var/m in buckled_mobs)
			var/mob/living/buckled_mob = m
			addtimer(CALLBACK(buckled_mob, PROC_REF(check_buckled)), 1, TIMER_UNIQUE)
	if(pulling && !currently_z_moving)
		addtimer(CALLBACK(src, PROC_REF(check_pull)), 1, TIMER_UNIQUE)
	. = ..()
	if(client)
		reset_perspective(destination)
	update_canmove() //if the mob was asleep inside a container and then got forceMoved out we need to make them fall.

//Called whenever an object moves and by mobs when they attempt to move themselves through space
//And when an object or action applies a force on src, see newtonian_move() below
//Return 0 to have src start/keep drifting in a no-grav area and 1 to stop/not start drifting
//Mobs should return 1 if they should be able to move of their own volition, see client/Move() in mob_movement.dm
//movement_dir == 0 when stopping or any dir when trying to move
/atom/movable/proc/Process_Spacemove(var/movement_dir = 0)
	if(has_gravity())
		return 1

	if(pulledby && !pulledby.pulling)
		return 1

	if(throwing)
		return 1

	if(locate(/obj/structure/lattice) in range(1, get_turf(src))) //Not realistic but makes pushing things in space easier
		return 1

	return 0

/atom/movable/proc/newtonian_move(direction) //Only moves the object if it's under no gravity
	if(!loc || Process_Spacemove(0))
		inertia_dir = 0
		return 0

	inertia_dir = direction
	if(!direction)
		return 1

	inertia_last_loc = loc
	SSspacedrift.processing[src] = src
	return 1


//called when src is thrown into hit_atom
/atom/movable/proc/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	set waitfor = FALSE
	SEND_SIGNAL(src, COMSIG_MOVABLE_IMPACT, hit_atom, throwingdatum)
	if(!QDELETED(hit_atom))
		return hit_atom.hitby(src, throwingdatum = throwingdatum)


/// called after an items throw is ended.
/atom/movable/proc/end_throw()
	return


/atom/movable/hitby(atom/movable/AM, skipcatch, hitpush = TRUE, blocked, datum/thrownthing/throwingdatum)
	if(!anchored && hitpush && (!throwingdatum || (throwingdatum.force >= (move_resist * MOVE_FORCE_PUSH_RATIO))))
		step(src, AM.dir)
	..()


/atom/movable/proc/throw_at(atom/target, range, speed, mob/thrower, spin = TRUE, diagonals_first = FALSE, datum/callback/callback, force = INFINITY, dodgeable = TRUE)
	if(!target || (flags & NODROP) || speed <= 0)
		return FALSE

	if(pulledby)
		pulledby.stop_pulling()

	// They are moving! Wouldn't it be cool if we calculated their momentum and added it to the throw?
	if(istype(thrower) && thrower.last_move && thrower.client && thrower.client.move_delay >= world.time + world.tick_lag * 2)
		var/user_momentum = thrower.movement_delay()
		if(!user_momentum) // no movement_delay, this means they move once per byond tick, let's calculate from that instead
			user_momentum = world.tick_lag

		user_momentum = 1 / user_momentum // convert from ds to the tiles per ds that throw_at uses

		if(get_dir(thrower, target) & last_move)
			user_momentum = user_momentum // basically a noop, but needed
		else if(get_dir(target, thrower) & last_move)
			user_momentum = -user_momentum // we are moving away from the target, lets slowdown the throw accordingly
		else
			user_momentum = 0

		if(user_momentum)
			// first lets add that momentum to range
			range *= (user_momentum / speed) + 1
			//then lets add it to speed
			speed += user_momentum
			if(speed <= 0)
				return //no throw speed, the user was moving too fast.

	var/datum/thrownthing/TT = new()
	TT.thrownthing = src
	TT.target = target
	TT.target_turf = get_turf(target)
	TT.init_dir = get_dir(src, target)
	TT.maxrange = range
	TT.speed = speed
	TT.thrower = thrower
	TT.diagonals_first = diagonals_first
	TT.callback = callback
	TT.dodgeable = dodgeable

	var/dist_x = abs(target.x - src.x)
	var/dist_y = abs(target.y - src.y)
	var/dx = (target.x > src.x) ? EAST : WEST
	var/dy = (target.y > src.y) ? NORTH : SOUTH

	if(dist_x == dist_y)
		TT.pure_diagonal = 1

	else if(dist_x <= dist_y)
		var/olddist_x = dist_x
		var/olddx = dx
		dist_x = dist_y
		dist_y = olddist_x
		dx = dy
		dy = olddx
	TT.dist_x = dist_x
	TT.dist_y = dist_y
	TT.dx = dx
	TT.dy = dy
	TT.diagonal_error = dist_x / 2 - dist_y
	TT.start_time = world.time

	if(pulledby)
		pulledby.stop_pulling()

	throwing = TT
	if(spin && !no_spin && !no_spin_thrown)
		SpinAnimation(5, 1)

	SEND_SIGNAL(src, COMSIG_MOVABLE_POST_THROW, TT, spin)
	SSthrowing.processing[src] = TT
	TT.tick()

	return TRUE


//Overlays
/atom/movable/overlay
	var/atom/master = null
	anchored = TRUE
	simulated = FALSE

/atom/movable/overlay/New()
	. = ..()
	verbs.Cut()
	return

/atom/movable/overlay/attackby(a, b, c)
	if(master)
		return master.attackby(a, b, c)

/atom/movable/overlay/attack_hand(a, b, c)
	if(master)
		return master.attack_hand(a, b, c)

/atom/movable/proc/handle_buckled_mob_movement(newloc,direct,movetime)
	for(var/m in buckled_mobs)
		var/mob/living/buckled_mob = m
		buckled_mob.glide_size = glide_size
		if(!buckled_mob.Move(newloc, direct, movetime))
			forceMove(buckled_mob.loc)
			last_move = buckled_mob.last_move
			inertia_dir = last_move
			buckled_mob.inertia_dir = last_move
			return 0
	return 1

/atom/movable/proc/force_pushed(atom/movable/pusher, force = MOVE_FORCE_DEFAULT, direction)
	return FALSE

/atom/movable/proc/force_push(atom/movable/AM, force = move_force, direction, silent = FALSE)
	. = AM.force_pushed(src, force, direction)
	if(!silent && .)
		visible_message("<span class='warning'>[src] сильно толка[pluralize_ru(src.gender,"ет","ют")] [AM]!</span>", "<span class='warning'>Вы сильно толкаете [AM]!</span>")

/atom/movable/proc/move_crush(atom/movable/AM, force = move_force, direction, silent = FALSE)
	. = AM.move_crushed(src, force, direction)
	if(!silent && .)
		visible_message("<span class='danger'>[src] сокруша[pluralize_ru(src.gender,"ет","ют")] [AM]!</span>", "<span class='danger'>Вы сокрушили [AM]!</span>")

/atom/movable/proc/move_crushed(atom/movable/pusher, force = MOVE_FORCE_DEFAULT, direction)
	return FALSE

/atom/movable/CanPass(atom/movable/mover, turf/target, height=1.5)
	if(istype(mover) && mover.checkpass(PASS_OTHER_THINGS))
		return TRUE
	if(mover in buckled_mobs)
		return 1
	return ..()

/atom/movable/proc/get_spacemove_backup()
	var/atom/movable/dense_object_backup
	for(var/A in orange(1, get_turf(src)))
		if(isarea(A))
			continue
		else if(isturf(A))
			var/turf/turf = A
			if(!turf.density)
				continue
			return turf
		else
			var/atom/movable/AM = A
			if(!AM.CanPass(src) || AM.density)
				if(AM.anchored)
					return AM
				dense_object_backup = AM
				break
	. = dense_object_backup

/atom/movable/proc/transfer_prints_to(atom/movable/target = null, overwrite = FALSE)
	if(!target)
		return
	if(overwrite)
		target.fingerprints = fingerprints
		target.fingerprintshidden = fingerprintshidden
	else
		target.fingerprints += fingerprints
		target.fingerprintshidden += fingerprintshidden
	target.fingerprintslast = fingerprintslast

/atom/movable/proc/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!no_effect && (visual_effect_icon || used_item))
		do_item_attack_animation(A, visual_effect_icon, used_item)

	if(A == src)
		return //don't do an animation if attacking self
	var/pixel_x_diff = 0
	var/pixel_y_diff = 0

	var/direction = get_dir(src, A)
	if(direction & NORTH)
		pixel_y_diff = 8
	else if(direction & SOUTH)
		pixel_y_diff = -8

	if(direction & EAST)
		pixel_x_diff = 8
	else if(direction & WEST)
		pixel_x_diff = -8

	animate(src, pixel_x = pixel_x + pixel_x_diff, pixel_y = pixel_y + pixel_y_diff, time = 2)
	animate(pixel_x = pixel_x - pixel_x_diff, pixel_y = pixel_y - pixel_y_diff, time = 2)

/atom/movable/proc/do_item_attack_animation(atom/A, visual_effect_icon, obj/item/used_item)
	var/image/I
	if(visual_effect_icon)
		I = image('icons/effects/effects.dmi', A, visual_effect_icon, A.layer + 0.1)
	else if(used_item)
		I = image(icon = used_item, loc = A, layer = A.layer + 0.1)
		I.plane = GAME_PLANE

		// Scale the icon.
		I.transform *= 0.75
		// The icon should not rotate.
		I.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA

		// Set the direction of the icon animation.
		var/direction = get_dir(src, A)
		if(direction & NORTH)
			I.pixel_y = -16
		else if(direction & SOUTH)
			I.pixel_y = 16

		if(direction & EAST)
			I.pixel_x = -16
		else if(direction & WEST)
			I.pixel_x = 16

		if(!direction) // Attacked self?!
			I.pixel_z = 16

	if(!I)
		return

	// Who can see the attack?
	var/list/viewing = list()
	for(var/mob/M in viewers(A))
		if(M.client && M.client.prefs.toggles2 & PREFTOGGLE_2_ITEMATTACK)
			viewing |= M.client

	flick_overlay(I, viewing, 5) // 5 ticks/half a second

	// And animate the attack!
	var/t_color = "#ffffff"
	if(ismob(src) &&  ismob(A) && (!used_item))
		var/mob/M = src
		t_color = M.a_intent == INTENT_HARM ? "#ff0000" : "#ffffff"
	animate(I, alpha = 175, pixel_x = 0, pixel_y = 0, pixel_z = 0, time = 3, color = t_color)

/atom/movable/proc/portal_destroyed(obj/effect/portal/P)
	return

/atom/movable/proc/decompile_act(obj/item/matter_decompiler/C, mob/user) // For drones to decompile mobs and objs. See drone for an example.
	return FALSE

/atom/movable/proc/get_pull_push_speed_modifier(var/current_delay)
	return pull_push_speed_modifier
