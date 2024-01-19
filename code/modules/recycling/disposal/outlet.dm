// the disposal outlet machine

#define UNSCREWED -1
#define SCREWED 1

/obj/structure/disposaloutlet
	name = "disposal outlet"
	desc = "An outlet for the pneumatic disposal system."
	icon = 'icons/obj/pipes_and_stuff/not_atmos/disposal.dmi'
	icon_state = "outlet"
	density = 1
	anchored = 1
	var/active = 0
	var/turf/target	// this will be where the output objects are 'thrown' to.
	var/obj/structure/disposalpipe/trunk/linkedtrunk
	var/mode = SCREWED

/obj/structure/disposaloutlet/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(setup)), 0) // Wait of 0, but this wont actually do anything until the MC is firing

/obj/structure/disposaloutlet/proc/setup()
	target = get_ranged_target_turf(src, dir, 10)
	var/obj/structure/disposalpipe/trunk/T = locate() in get_turf(src)
	if(T)
		T.nicely_link_to_other_stuff(src)

/obj/structure/disposaloutlet/Destroy()
	if(linkedtrunk)
		linkedtrunk.remove_trunk_links()
	expel(FALSE)
	return ..()

// expel the contents of the outlet
/obj/structure/disposaloutlet/proc/expel(animation = TRUE)
	if(animation)
		flick("outlet-open", src)
		playsound(src, 'sound/machines/warning-buzzer.ogg', 50, 0, 0)
		sleep(20)	//wait until correct animation frame
		playsound(src, 'sound/machines/hiss.ogg', 50, 0, 0)
	for(var/atom/movable/AM in contents)
		AM.forceMove(loc)
		AM.pipe_eject(dir)
		if(isdrone(AM) || istype(AM, /mob/living/silicon/robot/syndicate/saboteur)) //Drones keep smashing windows from being fired out of chutes. Bad for the station. ~Z
			return
		spawn(5)
			if(QDELETED(AM))
				return
			AM.throw_at(target, 3, 1)

/obj/structure/disposaloutlet/screwdriver_act(mob/user, obj/item/I)
	. = TRUE
	if(mode == SCREWED)
		mode = UNSCREWED
	else
		mode = SCREWED
	playsound(src.loc, I.usesound, 50, 1)
	to_chat(user, "You [mode == SCREWED ? "attach" : "remove"] the screws around the power connection.")

/obj/structure/disposaloutlet/welder_act(mob/user, obj/item/I)
	. = TRUE
	if(mode != UNSCREWED)
		return
	if(!I.tool_use_check(user, 0))
		return
	WELDER_ATTEMPT_FLOOR_SLICE_MESSAGE
	if(I.use_tool(src, user, 20, volume = I.tool_volume))
		WELDER_FLOOR_SLICE_SUCCESS_MESSAGE
		var/obj/structure/disposalconstruct/C = new (src.loc)
		C.ptype = PIPE_DISPOSALS_OUTLET
		C.update()
		C.anchored = TRUE
		C.density = TRUE
		transfer_fingerprints_to(C)
		qdel(src)

//When the disposalsoutlet is forcefully moved. Due to meteorshot or the recall item spell for instance
/obj/structure/disposaloutlet/Moved(atom/OldLoc, Dir)
	. = ..()
	if(!loc)
		return
	var/turf/T = OldLoc
	if(T.intact)
		var/turf/simulated/floor/F = T
		F.remove_tile(null,TRUE,TRUE)
		T.visible_message("<span class='warning'>The floortile is ripped from the floor!</span>", "<span class='warning'>You hear a loud bang!</span>")
	if(linkedtrunk)
		linkedtrunk.remove_trunk_links()
	var/obj/structure/disposalconstruct/C = new (loc)
	transfer_fingerprints_to(C)
	C.ptype = PIPE_DISPOSALS_OUTLET
	C.update()
	C.anchored = 0
	C.density = 1
	qdel(src)

#undef UNSCREWED
#undef SCREWED
