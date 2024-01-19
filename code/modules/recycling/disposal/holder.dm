// virtual disposal object
// travels through pipes in lieu of actual items
// contents will be items flushed by the disposal
// this allows the gas flushed to be tracked

/obj/structure/disposalholder
	invisibility = INVISIBILITY_ABSTRACT
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/datum/gas_mixture/gas = null	// gas used to flush, will appear at exit point
	var/active = 0	// true if the holder is moving, otherwise inactive
	dir = 0
	var/count = 1000	//*** can travel 1000 steps before going inactive (in case of loops)
	var/has_fat_guy = 0	// true if contains a fat person
	var/destinationTag = 0 // changes if contains a delivery container
	var/tomail = 0 //changes if contains wrapped package
	var/hasmob = 0 //If it contains a mob

/obj/structure/disposalholder/Destroy()
	QDEL_NULL(gas)
	active = 0
	return ..()

	// initialize a holder from the contents of a disposal unit
/obj/structure/disposalholder/proc/init(var/obj/machinery/disposal/D)
	gas = D.air_contents// transfer gas resv. into holder object

	//Check for any living mobs trigger hasmob.
	//hasmob effects whether the package goes to cargo or its tagged destination.
	for(var/mob/living/M in D)
		if(M && M.stat != 2 && !isdrone(M) && !istype(M, /mob/living/silicon/robot/syndicate/saboteur))
			hasmob = 1

	//Checks 1 contents level deep. This means that players can be sent through disposals...
	//...but it should require a second person to open the package. (i.e. person inside a wrapped locker)
	for(var/obj/O in D)
		if(O.contents)
			for(var/mob/living/M in O.contents)
				if(M && M.stat != 2 && !isdrone(M) && !istype(M, /mob/living/silicon/robot/syndicate/saboteur))
					hasmob = 1

	// now everything inside the disposal gets put into the holder
	// note AM since can contain mobs or objs
	for(var/atom/movable/AM in D)
		AM.forceMove(src)
		SEND_SIGNAL(AM, COMSIG_MOVABLE_DISPOSING, src, D)
		if(istype(AM, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = AM
			if(FAT in H.mutations)		// is a human and fat?
				has_fat_guy = 1			// set flag on holder
		if(istype(AM, /obj/structure/bigDelivery) && !hasmob)
			var/obj/structure/bigDelivery/T = AM
			destinationTag = T.sortTag
		if(istype(AM, /obj/item/smallDelivery) && !hasmob)
			var/obj/item/smallDelivery/T = AM
			destinationTag = T.sortTag
		//Drones can mail themselves through maint.
		if(isdrone(AM))
			var/mob/living/silicon/robot/drone/drone = AM
			destinationTag = drone.mail_destination
		if(istype(AM, /mob/living/silicon/robot/syndicate/saboteur))
			var/mob/living/silicon/robot/syndicate/saboteur/S = AM
			destinationTag = S.mail_destination
		if(istype(AM, /obj/item/shippingPackage) && !hasmob)
			var/obj/item/shippingPackage/sp = AM
			if(sp.sealed)	//only sealed packages get delivered to their intended destination
				destinationTag = sp.sortTag


	// start the movement process
	// argument is the disposal unit the holder started in
/obj/structure/disposalholder/proc/start(var/obj/machinery/disposal/D)
	if(!D.trunk)
		D.expel(src)	// no trunk connected, so expel immediately
		return

	forceMove(D.trunk)
	active = 1
	dir = DOWN
	spawn(1)
		move()		// spawn off the movement process

	return

	// movement process, persists while holder is moving through pipes
/obj/structure/disposalholder/proc/move()
	var/obj/structure/disposalpipe/last
	while(active)
	/*	if(hasmob && prob(3))
			for(var/mob/living/H in src)
				if(!istype(H,/mob/living/silicon/robot/drone)) //Drones use the mailing code to move through the disposal system,
					H.take_overall_damage(20, 0, "Blunt Trauma") */ //horribly maim any living creature jumping down disposals.  c'est la vie

		if(has_fat_guy && prob(2)) // chance of becoming stuck per segment if contains a fat guy
			active = 0
			// find the fat guys
			for(var/mob/living/carbon/human/H in src)

			break
		sleep(1)		// was 1
		var/obj/structure/disposalpipe/curr = loc
		last = curr
		curr = curr.transfer(src)
		if(!curr)
			last.expel(src, loc, dir)

		//
		if(!(count--))
			active = 0
	return



	// find the turf which should contain the next pipe
/obj/structure/disposalholder/proc/nextloc()
	return get_step(loc,dir)

	// find a matching pipe on a turf
/obj/structure/disposalholder/proc/findpipe(var/turf/T)
	if(!T)
		return null

	var/fdir = turn(dir, 180)	// flip the movement direction
	for(var/obj/structure/disposalpipe/P in T)
		if(fdir & P.dpdir)		// find pipe direction mask that matches flipped dir
			return P
	// if no matching pipe, return null
	return null

	// merge two holder objects
	// used when a a holder meets a stuck holder
/obj/structure/disposalholder/proc/merge(var/obj/structure/disposalholder/other)
	for(var/atom/movable/AM in other)
		AM.forceMove(src)		// move everything in other holder to this one
		if(ismob(AM))
			var/mob/M = AM
			M.reset_perspective(src)	// if a client mob, update eye to follow this holder

	if(other.has_fat_guy)
		has_fat_guy = 1
	qdel(other)


	// called when player tries to move while in a pipe
/obj/structure/disposalholder/relaymove(mob/user as mob)
	if(!istype(user,/mob/living))
		return

	var/mob/living/U = user

	if(U.stat || U.last_special <= world.time)
		return

	U.last_special = world.time+100

	if(src.loc)
		for(var/mob/M in hearers(src.loc.loc))
			to_chat(M, "<FONT size=[max(0, 5 - get_dist(src, M))]>CLONG, clong!</FONT>")

	playsound(src.loc, 'sound/effects/clang.ogg', 50, 0, 0)

	// called to vent all gas in holder to a location
/obj/structure/disposalholder/proc/vent_gas(var/atom/location)
	if(location)
		location.assume_air(gas)  // vent all gas to turf
	air_update_turf()
	return
