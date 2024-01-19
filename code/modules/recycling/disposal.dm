// Disposal bin
// Holds items for disposal into pipe system
// Draws air from turf, gradually charges internal reservoir
// Once full (~1 atm), uses air resv to flush items into the pipes
// Automatically recharges air (unless off), will flush when ready if pre-set
// Can hold items and human size things, no other draggables
// Toilets are a type of disposal bin for small objects only and work on magic. By magic, I mean torque rotation
#define SEND_PRESSURE 0.05*ONE_ATMOSPHERE
#define UNSCREWED -1
#define OFF 0
#define SCREWED 1
#define CHARGING 1
#define CHARGED 2

/obj/machinery/disposal
	name = "disposal unit"
	desc = "A pneumatic waste disposal unit."
	icon = 'icons/obj/pipes_and_stuff/not_atmos/disposal.dmi'
	icon_state = "disposal"
	anchored = 1
	density = 1
	on_blueprints = TRUE
	armor = list("melee" = 25, "bullet" = 10, "laser" = 10, "energy" = 100, "bomb" = 0, "bio" = 100, "rad" = 100, "fire" = 90, "acid" = 30)
	max_integrity = 200
	resistance_flags = FIRE_PROOF
	var/datum/gas_mixture/air_contents	// internal reservoir
	var/mode = CHARGING	// item mode 0=off 1=charging 2=charged
	var/flush = FALSE	// true if flush handle is pulled
	var/obj/structure/disposalpipe/trunk/trunk = null // the attached pipe trunk
	var/flushing = FALSE	// true if flushing in progress
	var/flush_every_ticks = 30 //Every 30 ticks it will look whether it is ready to flush
	var/flush_count = 0 //this var adds 1 once per tick. When it reaches flush_every_ticks it resets and tries to flush.
	var/last_sound = 0
	var/deconstructs_to = PIPE_DISPOSALS_BIN
	var/storage_slots = 50 //The number of storage slots in this container.
	var/max_combined_w_class = 50 //The sum of the w_classes of all the items in this storage item.
	active_power_usage = 600
	idle_power_usage = 100


// create a new disposal
// find the attached trunk (if present)
/obj/machinery/disposal/New()
	..()
	trunk_check()
	//gas.volume = 1.05 * CELLSTANDARD
	update()

/obj/machinery/disposal/proc/trunk_check()
	var/obj/structure/disposalpipe/trunk/T = locate() in loc
	if(!T)
		mode = OFF
		flush = FALSE
	else
		mode = initial(mode)
		flush = initial(flush)
		T.nicely_link_to_other_stuff(src)

//When the disposalsoutlet is forcefully moved. Due to meteorshot (not the recall spell)
/obj/machinery/disposal/Moved(atom/OldLoc, Dir)
	. = ..()
	eject()
	var/ptype = istype(src, /obj/machinery/disposal/deliveryChute) ? PIPE_DISPOSALS_CHUTE : PIPE_DISPOSALS_BIN //Check what disposaltype it is
	var/turf/T = OldLoc
	if(T.intact)
		var/turf/simulated/floor/F = T
		F.remove_tile(null,TRUE,TRUE)
		T.visible_message("<span class='warning'>The floortile is ripped from the floor!</span>", "<span class='warning'>You hear a loud bang!</span>")
	if(trunk)
		trunk.remove_trunk_links()
	var/obj/structure/disposalconstruct/C = new (loc)
	transfer_fingerprints_to(C)
	C.ptype = ptype
	C.update()
	C.anchored = 0
	C.density = 1
	if(!QDELING(src))
		qdel(src)

/obj/machinery/disposal/Destroy()
	eject()
	if(trunk)
		trunk.remove_trunk_links()
	return ..()

/obj/machinery/disposal/singularity_pull(S, current_size)
	..()
	if(current_size >= STAGE_FIVE)
		deconstruct()

/obj/machinery/disposal/Initialize()
	// this will get a copy of the air turf and take a SEND PRESSURE amount of air from it
	..()
	var/atom/L = loc
	var/datum/gas_mixture/env = new
	env.copy_from(L.return_air())
	var/datum/gas_mixture/removed = env.remove(SEND_PRESSURE + 1)
	air_contents = new
	air_contents.merge(removed)
	trunk_check()

//This proc returns TRUE if the item can be picked up and FALSE if it can't.
//Set the stop_messages to stop it from printing messages
/obj/machinery/disposal/proc/can_be_inserted(obj/item/W, stop_messages = FALSE)
	if(!istype(W) || (W.flags & ABSTRACT)) //Not an item
		return

	if(loc == W)
		return FALSE //Means the item is already in the storage item
	if(contents.len >= storage_slots)
		if(!stop_messages)
			to_chat(usr, "<span class='warning'>[W] won't fit in [src], make some space!</span>")
		return FALSE //Storage item is full

	var/sum_w_class = W.w_class
	for(var/obj/item/I in contents)
		sum_w_class += I.w_class //Adds up the combined w_classes which will be in the storage item if the item is added to it.

	if(sum_w_class > max_combined_w_class)
		if(!stop_messages)
			to_chat(usr, "<span class='notice'>[src] is full, make some space.</span>")
		return FALSE

	if(W.flags & NODROP) //SHOULD be handled in unEquip, but better safe than sorry.
		to_chat(usr, "<span class='notice'>\the [W] is stuck to your hand, you can't put it in \the [src]</span>")
		return FALSE

	return TRUE

// attack by item places it in to disposal
/obj/machinery/disposal/attackby(var/obj/item/I, var/mob/user, params)
	if(stat & BROKEN || !I || !user)
		return

	if(istype(I, /obj/item/melee/energy/blade))
		to_chat(user, "You can't place that item inside the disposal unit.")
		return

	if(istype(I, /obj/item/storage))
		var/obj/item/storage/S = I
		if((S.allow_quick_empty || S.allow_quick_gather) && S.contents.len)
			add_fingerprint(user)
			S.hide_from(user)
			for(var/obj/item/O in S.contents)
				if(!can_be_inserted(O))
					break
				S.remove_from_storage(O, src)
				O.add_hiddenprint(user)
			if(!S.contents.len)
				user.visible_message("[user] empties \the [S] into \the [src].", "You empty \the [S] into \the [src].")
			else
				user.visible_message("[user] dumped some items from \the [S] into \the [src].", "You dumped some items \the [S] into \the [src].")
			S.update_icon() // For content-sensitive icons
			update()
			return

	var/obj/item/grab/G = I
	if(istype(G))	// handle grabbed mob
		if(ismob(G.affecting))
			var/mob/GM = G.affecting
			for(var/mob/V in viewers(usr))
				V.show_message("[usr] starts putting [GM.name] into the disposal.", 3)
			if(do_after(usr, 20, target = GM))
				add_fingerprint(user)
				GM.forceMove(src)
				for(var/mob/C in viewers(src))
					C.show_message("<span class='warning'>[GM.name] has been placed in the [src] by [user].</span>", 3)
				qdel(G)
				add_attack_logs(usr, GM, "Disposal'ed")
		return

	if(!I)
		return

	if(!can_be_inserted(I))
		return
	if(!user.drop_transfer_item_to_loc(I, src))
		return

	add_fingerprint(user)
	to_chat(user, "You place \the [I] into the [src].")
	for(var/mob/M in viewers(src))
		if(M == user)
			continue
		M.show_message("[user.name] places \the [I] into the [src].", 3)

	update()




/obj/machinery/disposal/screwdriver_act(mob/user, obj/item/I)
	if(mode > OFF) // It's on
		return
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = I.tool_volume))
		return
	if(contents.len > 0)
		to_chat(user, "Eject the items first!")
		return
	if(mode == OFF) // It's off but still not unscrewed
		mode = UNSCREWED // Set it to doubleoff l0l
	else if(mode == UNSCREWED)
		mode = OFF
	to_chat(user, "You [mode ? "unfasten": "fasten"] the screws around the power connection.")

/obj/machinery/disposal/welder_act(mob/user, obj/item/I)
	. = TRUE
	if(mode != UNSCREWED)
		return
	if(contents.len > 0)
		to_chat(user, "Eject the items first!")
		return
	if(!I.tool_use_check(user, 0))
		return
	WELDER_ATTEMPT_FLOOR_SLICE_MESSAGE
	if(I.use_tool(src, user, 20, volume = I.tool_volume))
		WELDER_FLOOR_SLICE_SUCCESS_MESSAGE
		var/obj/structure/disposalconstruct/C = new (src.loc)
		C.ptype = deconstructs_to
		C.update()
		C.anchored = 1
		C.density = 1
		qdel(src)

// mouse drop another mob or self
//
/obj/machinery/disposal/MouseDrop_T(mob/living/target, mob/living/user)
	if(!istype(target) || target.buckled || target.has_buckled_mobs() || get_dist(user, src) > 1 || get_dist(user, target) > 1 || user.stat || istype(user, /mob/living/silicon/ai))
		return
	if(isanimal(user) && target != user) return //animals cannot put mobs other than themselves into disposal
	src.add_fingerprint(user)
	var/target_loc = target.loc
	var/msg
	for(var/mob/V in viewers(usr))
		if(target == user && !user.stat && !user.IsWeakened() && !user.IsStunned() && !user.IsParalyzed())
			V.show_message("[usr] starts climbing into the disposal.", 3)
		if(target != user && !user.restrained() && !user.stat && !user.IsWeakened() && !user.IsStunned() && !user.IsParalyzed())
			if(target.anchored) return
			V.show_message("[usr] starts stuffing [target.name] into the disposal.", 3)
	if(!do_after(usr, 20, target = target))
		return
	if(QDELETED(src) || target_loc != target.loc)
		return
	if(target == user && !user.stat && !user.IsWeakened() && !user.IsStunned() && !user.IsParalyzed())	// if drop self, then climbed in
											// must be awake, not stunned or whatever
		msg = "[user.name] climbs into [src]."
		to_chat(user, "You climb into [src].")
	else if(target != user && !user.restrained() && !user.stat && !user.IsWeakened() && !user.IsStunned() && !user.IsParalyzed())
		msg = "[user.name] stuffs [target.name] into [src]!"
		to_chat(user, "You stuff [target.name] into [src]!")
		if(!iscarbon(user))
			target.LAssailant = null
		else
			target.LAssailant = user
		add_attack_logs(user, target, "Disposal'ed")
	else
		return
	target.forceMove(src)

	for(var/mob/C in viewers(src))
		if(C == user)
			continue
		C.show_message(msg, 3)

	update()
	return

// attempt to move while inside
/obj/machinery/disposal/relaymove(mob/user as mob)
	if(user.stat || src.flushing)
		return
	src.go_out(user)
	return

// leave the disposal
/obj/machinery/disposal/proc/go_out(mob/user)
	if(user)
		user.forceMove(loc)
	update()

// ai as human but can't flush
/obj/machinery/disposal/attack_ai(mob/user as mob)
	src.add_hiddenprint(user)
	ui_interact(user)

/obj/machinery/disposal/attack_ghost(mob/user as mob)
	ui_interact(user)

// human interact with machine
/obj/machinery/disposal/attack_hand(mob/user as mob)
	if(..(user))
		return 1

	if(stat & BROKEN)
		return

	if(user && user.loc == src)
		to_chat(usr, "<span class='warning'>You cannot reach the controls from inside.</span>")
		return

	// Clumsy folks can only flush it.
	if(user.IsAdvancedToolUser())
		ui_interact(user)
	else
		flush = !flush
		update()
	return

/obj/machinery/disposal/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = FALSE, datum/tgui/master_ui = null, datum/ui_state/state = GLOB.default_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "DisposalBin", name, 300, 250, master_ui, state)
		ui.open()


/obj/machinery/disposal/ui_data(mob/user)
	var/list/data = list()

	data["isAI"] = isAI(user)
	data["flushing"] = flush
	data["mode"] = mode
	data["pressure"] = round(clamp(100* air_contents.return_pressure() / (SEND_PRESSURE), 0, 100),1)

	return data

/obj/machinery/disposal/ui_act(action, params)
	if(..())
		return
	if(usr.loc == src)
		to_chat(usr, "<span class='warning'>You cannot reach the controls from inside.</span>")
		return

	if(mode == UNSCREWED && action != "eject") // If the mode is -1, only allow ejection
		to_chat(usr, "<span class='warning'>The disposal units power is disabled.</span>")
		return

	if(stat & BROKEN)
		return

	src.add_fingerprint(usr)

	if(src.flushing)
		return

	if(istype(src.loc, /turf))
		if(action == "pumpOn")
			mode = CHARGING
			update()
		if(action == "pumpOff")
			mode = OFF
			update()

		if(!issilicon(usr))
			if(action == "engageHandle")
				flush = TRUE
				update()
			if(action == "disengageHandle")
				flush = FALSE
				update()

			if(action == "eject")
				eject()

	return TRUE

// eject the contents of the disposal unit
/obj/machinery/disposal/proc/eject()
	for(var/atom/movable/AM in src)
		AM.forceMove(loc)
		AM.pipe_eject(0)
	update()

// update the icon & overlays to reflect mode & status
/obj/machinery/disposal/proc/update()
	overlays.Cut()
	if(stat & BROKEN)
		icon_state = "disposal-broken"
		mode = OFF
		flush = FALSE
		return

	// flush handle
	if(flush)
		overlays += image('icons/obj/pipes_and_stuff/not_atmos/disposal.dmi', "dispover-handle")

	// only handle is shown if no power
	if(stat & NOPOWER || mode == -1)
		return

	// 	check for items in disposal - occupied light
	if(contents.len > 0)
		overlays += image('icons/obj/pipes_and_stuff/not_atmos/disposal.dmi', "dispover-full")

	// charging and ready light
	if(mode == CHARGING)
		overlays += image('icons/obj/pipes_and_stuff/not_atmos/disposal.dmi', "dispover-charge")
	else if(mode == CHARGED)
		overlays += image('icons/obj/pipes_and_stuff/not_atmos/disposal.dmi', "dispover-ready")

// timed process
// charge the gas reservoir and perform flush if ready
/obj/machinery/disposal/process()
	use_power = NO_POWER_USE
	if(stat & BROKEN)			// nothing can happen if broken
		return

	flush_count++
	if( flush_count >= flush_every_ticks )
		if( contents.len )
			if(mode == CHARGED)
				spawn(0)
					flush()
		flush_count = 0

	src.updateDialog()

	if(flush && air_contents.return_pressure() >= SEND_PRESSURE )	// flush can happen even without power
		flush()

	if(stat & NOPOWER)			// won't charge if no power
		return

	use_power = IDLE_POWER_USE

	if(mode != CHARGING)		// if off or ready, no need to charge
		return

	// otherwise charge
	use_power = ACTIVE_POWER_USE

	var/atom/L = loc						// recharging from loc turf

	var/datum/gas_mixture/env = L.return_air()
	var/pressure_delta = (SEND_PRESSURE*1.01) - air_contents.return_pressure()

	if(env.temperature > 0)
		var/transfer_moles = 0.1 * pressure_delta*air_contents.volume/(env.temperature * R_IDEAL_GAS_EQUATION)

		//Actually transfer the gas
		var/datum/gas_mixture/removed = env.remove(transfer_moles)
		air_contents.merge(removed)
		air_update_turf()


	// if full enough, switch to ready mode
	if(air_contents.return_pressure() >= SEND_PRESSURE)
		mode = CHARGED
		update()
	return

// perform a flush
/obj/machinery/disposal/proc/flush()
	flushing = TRUE
	flush_animation()
	var/obj/structure/disposalholder/H = new()	// virtual holder object which actually
												// travels through the pipes.
	manage_wrapping(H)
	sleep(10)
	if(last_sound < world.time + 1)
		playsound(src, 'sound/machines/disposalflush.ogg', 50, 0, 0)
		last_sound = world.time
	sleep(5) // wait for animation to finish
	H.init(src)	// copy the contents of disposer to holder
	air_contents = new() // The holder just took our gas; replace it
	H.start(src) // start the holder processing movement
	flushing = FALSE
	// now reset disposal state
	flush = FALSE
	if(mode == CHARGED)	// if was ready,
		mode = CHARGING	// switch to charging
	update()
	return

/obj/machinery/disposal/proc/flush_animation()
	flick("[icon_state]-flush", src)

/obj/machinery/disposal/proc/manage_wrapping(obj/structure/disposalholder/H)
	var/wrap_check = FALSE
	//Hacky test to get drones to mail themselves through disposals.
	for(var/mob/living/silicon/robot/drone/D in src)
		wrap_check = TRUE
	for(var/mob/living/silicon/robot/syndicate/saboteur/R in src)
		wrap_check = TRUE
	for(var/obj/item/smallDelivery/O in src)
		wrap_check = TRUE
	if(wrap_check == TRUE)
		H.tomail = 1

// called when area power changes
/obj/machinery/disposal/power_change()
	..()	// do default setting/reset of stat NOPOWER bit
	update()	// update icon
	return


// called when holder is expelled from a disposal
// should usually only occur if the pipe network is modified
/obj/machinery/disposal/proc/expel(var/obj/structure/disposalholder/H)

	var/turf/target
	playsound(src, 'sound/machines/hiss.ogg', 50, 0, 0)
	if(H) // Somehow, someone managed to flush a window which broke mid-transit and caused the disposal to go in an infinite loop trying to expel null, hopefully this fixes it
		for(var/atom/movable/AM in H)
			target = get_offset_target_turf(src.loc, rand(5)-rand(5), rand(5)-rand(5))

			AM.forceMove(loc)
			AM.pipe_eject(0)
			if(!istype(AM, /mob/living/silicon/robot/drone) && !istype(AM, /mob/living/silicon/robot/syndicate/saboteur)) //Poor drones kept smashing windows and taking system damage being fired out of disposals. ~Z
				spawn(1)
					if(AM)
						AM.throw_at(target, 5, 1)

		H.vent_gas(loc)
		qdel(H)

/obj/machinery/disposal/CanPass(atom/movable/mover, turf/target, height=0)
	if(istype(mover,/obj/item) && mover.throwing)
		var/obj/item/I = mover
		if(istype(I, /obj/item/projectile))
			return
		if(prob(75) && can_be_inserted(I, TRUE))
			I.forceMove(src)
			for(var/mob/M in viewers(src))
				M.show_message("\the [I] lands in \the [src].", 3)
			update()
		else
			for(var/mob/M in viewers(src))
				M.show_message("\the [I] bounces off of \the [src]'s rim!.", 3)
		return 0
	else
		return ..(mover, target, height)


/obj/machinery/disposal/singularity_pull(S, current_size)
	if(current_size >= STAGE_FIVE)
		qdel(src)

/obj/machinery/disposal/get_remote_view_fullscreens(mob/user)
	if(user.stat == DEAD || !(user.sight & (SEEOBJS|SEEMOBS)))
		user.overlay_fullscreen("remote_view", /obj/screen/fullscreen/impaired, 2)

/obj/machinery/disposal/force_eject_occupant(mob/target)
	target.forceMove(get_turf(src))

/obj/machinery/disposal/deliveryChute
	name = "Delivery chute"
	desc = "A chute for big and small packages alike!"
	density = 1
	icon_state = "intake"
	deconstructs_to = PIPE_DISPOSALS_CHUTE
	var/to_waste = TRUE

/obj/machinery/disposal/deliveryChute/New()
	..()
	spawn(5)
		trunk = locate() in src.loc
		if(trunk)
			trunk.linked = src	// link the pipe trunk to self

/obj/machinery/disposal/deliveryChute/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/destTagger))
		add_fingerprint(user)
		to_waste = !to_waste
		playsound(src.loc, 'sound/machines/twobeep.ogg', 100, 1)
		to_chat(user, "<span class='notice'>The chute is now set to [to_waste ? "waste" : "cargo"] disposals.</span>")
		return
	. = ..()

/obj/machinery/disposal/deliveryChute/examine(mob/user)
	. = ..()
	. += "<span class='notice'>The chute is set to [to_waste ? "waste" : "cargo"] disposals.</span>"
	. += "<span class='info'>Use a destination tagger to change the disposal destination.</span>"

/obj/machinery/disposal/deliveryChute/interact()
	return

/obj/machinery/disposal/deliveryChute/update()
	return

/obj/machinery/disposal/deliveryChute/Bumped(atom/movable/moving_atom) //Go straight into the chute
	..()

	if(istype(moving_atom, /obj/item/projectile) || istype(moving_atom, /obj/effect))  return
	switch(dir)
		if(NORTH)
			if(moving_atom.loc.y != src.loc.y+1) return
		if(EAST)
			if(moving_atom.loc.x != src.loc.x+1) return
		if(SOUTH)
			if(moving_atom.loc.y != src.loc.y-1) return
		if(WEST)
			if(moving_atom.loc.x != src.loc.x-1) return

	if(istype(moving_atom, /obj))
		var/obj/O = moving_atom
		O.loc = src
	else if(istype(moving_atom, /mob))
		var/mob/M = moving_atom
		M.loc = src
	if(mode != OFF)
		flush()

/obj/machinery/disposal/deliveryChute/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	if(istype(AM, /obj/item/projectile))
		return ..() //chutes won't eat bullets
	if(dir == reverse_direction(throwingdatum.init_dir))
		return
	..()

/obj/machinery/disposal/deliveryChute/flush_animation()
	flick("intake-closing", src)

/obj/machinery/disposal/deliveryChute/manage_wrapping(obj/structure/disposalholder/H)
	var/wrap_check = FALSE
	for(var/obj/structure/bigDelivery/O in src)
		wrap_check = TRUE
		if(O.sortTag == 0)
			O.sortTag = 1
	for(var/obj/item/smallDelivery/O in src)
		wrap_check = TRUE
		if(O.sortTag == 0)
			O.sortTag = 1
	for(var/obj/item/shippingPackage/O in src)
		wrap_check = TRUE
		if(!O.sealed || O.sortTag == 0)		//unsealed or untagged shipping packages will default to disposals
			O.sortTag = 1
	if(wrap_check == TRUE)
		H.tomail = 1
	if(wrap_check == FALSE && to_waste)
		H.destinationTag = 1

#undef SEND_PRESSURE
#undef UNSCREWED
#undef OFF
#undef SCREWED
#undef CHARGING
#undef CHARGED
