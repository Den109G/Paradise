/**
 * We want to relay the zmovement to the buckled atom when possible
 * and only run what we can't have on buckled.zMove() or buckled.can_z_move() here.
 * This way we can avoid esoteric bugs, copypasta and inconsistencies.
 */
/mob/living/zMove(dir, turf/target, z_move_flags = ZMOVE_FLIGHT_FLAGS)
	if(buckled)
		if(buckled.currently_z_moving)
			return FALSE
		if(!(z_move_flags & ZMOVE_ALLOW_BUCKLED))
			buckled.unbuckle_mob(src, force = TRUE, can_fall = FALSE)
		else
			if(!target)
				target = can_z_move(dir, get_turf(src), null, z_move_flags, src)
				if(!target)
					return FALSE
			return buckled.zMove(dir, target, z_move_flags) // Return value is a loc.
	return ..()

/mob/living/can_z_move(direction, turf/start, turf/destination, z_move_flags = ZMOVE_FLIGHT_FLAGS, mob/living/rider)
	if(z_move_flags & ZMOVE_INCAPACITATED_CHECKS && incapacitated())
		if(z_move_flags & ZMOVE_FEEDBACK)
			to_chat(rider || src, "<span class='warning'>[rider ? src : "You"] can't do that right now!</span>")
		return FALSE
	if(!buckled || !(z_move_flags & ZMOVE_ALLOW_BUCKLED))
		if(!(z_move_flags & ZMOVE_FALL_CHECKS) && incorporeal_move && (!rider || rider.incorporeal_move))
			//An incorporeal mob will ignore obstacles unless it's a potential fall (it'd suck hard) or is carrying corporeal mobs.
			//Coupled with flying/floating, this allows the mob to move up and down freely.
			//By itself, it only allows the mob to move down.
			z_move_flags |= ZMOVE_IGNORE_OBSTACLES
		return ..()
	if(!(z_move_flags & ZMOVE_CAN_FLY_CHECKS) && !buckled.anchored) // may be issues with vehicles...
		return buckled.can_z_move(direction, start, destination, z_move_flags, src)
	if(z_move_flags & ZMOVE_FEEDBACK)
		to_chat(src, "<span class='notice'>Unbuckle from [buckled] first.<span>")
	return FALSE

/mob/set_currently_z_moving(value)
	if(buckled)
		return buckled.set_currently_z_moving(value)
	return ..()

///Checks if the user is incapacitated or on cooldown.
/mob/living/proc/can_look_up()
	return !(incapacitated(TRUE))

/**
 * look_up Changes the perspective of the mob to any openspace turf above the mob
 *
 * This also checks if an openspace turf is above the mob before looking up or resets the perspective if already looking up
 *
 */
/mob/living/proc/look_up()
	if(client.perspective != MOB_PERSPECTIVE) //We are already looking up.
		stop_look_up()
	if(!can_look_up())
		return
	changeNext_move(CLICK_CD_LOOK_UP_DOWN)
	RegisterSignal(src, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(stop_look_up), override = TRUE) //We stop looking up if we move.
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(start_look_up), override = TRUE) //We start looking again after we move.
	start_look_up()

/mob/living/proc/start_look_up()
	SIGNAL_HANDLER
	var/turf/ceiling = get_step_multiz(src, UP)
	if(!ceiling) //We are at the highest z-level.
		end_look_up() // Why would you look from highest? cancel trying.
		if (prob(0.1))
			to_chat(src, span_warning("You gaze out into the infinite vastness of deep space, for a moment, you have the impulse to continue travelling, out there, out into the deep beyond, before your conciousness reasserts itself and you decide to stay within travelling distance of the station."))
			return
		to_chat(src, span_warning("There's nothing interesting up there."))
		return
	else if(!ceiling.transparent_floor) //There is no turf we can look through above us
		var/turf/front_hole = get_step(ceiling, dir)
		if(front_hole.transparent_floor)
			ceiling = front_hole
		else
			for(var/turf/checkhole in RANGE_TURFS(1, ceiling))
				if(checkhole.transparent_floor)
					ceiling = checkhole
					break
		if(!ceiling.transparent_floor)
			to_chat(src, span_warning("You can't see through the floor above you."))
			return

	reset_perspective(ceiling)

/mob/living/proc/stop_look_up()
	SIGNAL_HANDLER
	reset_perspective()

/mob/living/proc/end_look_up()
	stop_look_up()
	UnregisterSignal(src, COMSIG_MOVABLE_PRE_MOVE)
	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)

/**
 * look_down Changes the perspective of the mob to any openspace turf below the mob
 *
 * This also checks if an openspace turf is below the mob before looking down or resets the perspective if already looking up
 *
 */
/mob/living/proc/look_down()
	if(client.perspective != MOB_PERSPECTIVE) //We are already looking down.
		stop_look_down()
	if(!can_look_up()) //if we cant look up, we cant look down.
		return
	changeNext_move(CLICK_CD_LOOK_UP_DOWN)
	RegisterSignal(src, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(stop_look_down), override = TRUE) //We stop looking down if we move.
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(start_look_down), override = TRUE) //We start looking again after we move.
	start_look_down()

/mob/living/proc/start_look_down()
	SIGNAL_HANDLER
	var/turf/floor = get_turf(src)
	var/turf/lower_level = get_step_multiz(floor, DOWN)
	if(!lower_level) //We are at the lowest z-level.
		to_chat(src, span_warning("You can't see through the floor below you."))
		end_look_down() // Looking to the bottom, no need to try.
		return
	else if(!floor.transparent_floor) //There is no turf we can look through below us
		var/turf/front_hole = get_step(floor, dir)
		if(front_hole.transparent_floor)
			floor = front_hole
			lower_level = get_step_multiz(front_hole, DOWN)
		else
			// Try to find a hole near us
			for(var/turf/checkhole in RANGE_TURFS(1, floor))
				if(checkhole.transparent_floor)
					floor = checkhole
					lower_level = get_step_multiz(checkhole, DOWN)
					break
		if(!floor.transparent_floor)
			to_chat(src, span_warning("You can't see through the floor below you."))
			return

	reset_perspective(lower_level)

/mob/living/proc/stop_look_down()
	SIGNAL_HANDLER
	reset_perspective()

/mob/living/proc/end_look_down()
	stop_look_down()
	UnregisterSignal(src, COMSIG_MOVABLE_PRE_MOVE)
	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)


/mob/living/verb/lookup()
	set name = "Look Up"
	set category = "IC"

	if(client.perspective != MOB_PERSPECTIVE)
		end_look_up()
	else
		look_up()

/mob/living/verb/lookdown()
	set name = "Look Down"
	set category = "IC"

	if(client.perspective != MOB_PERSPECTIVE)
		end_look_down()
	else
		look_down()
