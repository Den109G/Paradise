/// List with doom screens
GLOBAL_LIST_EMPTY(doom_screens)


/proc/clear_transition(mob/player)
	if(player && GLOB.doom_screens["[player]"])
		var/screen = GLOB.doom_screens["[player]"]
		qdel(screen)
		return

	//no player? or their screen? nuke every screen to exist
	QDEL_LAZYLIST(GLOB.doom_screens)
	message_admins("Okay, something went horribly wrong. D-double O-M just was cleared without player.") //snitch to admins that adminbus is happening

/mob/proc/force_doom()
	return doom_transition(src)

/atom/movable/screen/transition
	name = "DOOM"
	screen_loc = ui_holomap

/datum/hud
	var/atom/movable/screen/transition/transition

/datum/hud/New(mob/owner)
	. = ..()

	transition = new /atom/movable/screen/transition()
	transition.name = "Let this secret stay between you and me, k?"
	transition.icon = null //SStitle shoud be our image
	transition.mouse_opacity = MOUSE_OPACITY_ICON

#define SOMETHING_WENT_WRONG "SUCCESS_LEBUG"
#define SOMETHING_WENT_RIGHT "SUCCESS_NO_BUG"


/proc/doom_transition(mob/player)
	if(!player || !ismob(player)) //question every arg, even for one-day joke
		return SOMETHING_WENT_WRONG

	var/icon/image_to_use = get_screen_for_transition()
	player.hud_used.transition.appearance = image_to_use
	player.client.screen |= player.hud_used.transition

	var/obj/item/card/emag_broken/debug_thingy = new /obj/item/card/emag_broken()
	debug_thingy.forceMove(get_turf(player))
	debug_thingy.add_overlay(image_to_use)

	GLOB.doom_screens["[player]"] = image_to_use
	return SOMETHING_WENT_RIGHT

#undef SOMETHING_WENT_WRONG
#undef SOMETHING_WENT_RIGHT

/proc/get_screen_for_transition()
	//fix me
	var/icon_url = SStitle.image_for_screen
	return icon_url

	/* is not working cause its stores assets like "asset.ID.geef", which is not working
	made a clutch in SStitle for a april fools day
	var/title_screen = SStitle.current_title_screen.screen_image
	var/image_url = SSassets.transport.get_asset_url(asset_cache_item = title_screen)
	return new /mutable_appearance(image_url)
	*/
