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
