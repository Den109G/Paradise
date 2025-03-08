/// List with doom screens
GLOBAL_LIST_EMPTY(doom_screens)


/proc/clear_transition()
	QDEL_LAZYLIST(GLOB.doom_screens)

/mob/proc/force_doom()
	doom_transition(src)

/atom/movable/screen/transition
	name = "language menu"
	icon = 'icons/mob/screen_midnight.dmi'
	icon_state = "talk_wheel"
	screen_loc = ui_holomap

/datum/hud
	var/atom/movable/screen/transition/transition

/datum/hud/New(mob/owner)
	. = ..()

	transition = new /atom/movable/screen/transition()
	transition.name = "Let this secret stay between you and me, k?"
	transition.icon = null //SStitle shoud be our image
	transition.mouse_opacity = MOUSE_OPACITY_ICON

/proc/doom_transition(mob/player)
	if(!player || !ismob(player)) //question every arg, even for one-day joke
		return

	if(!GLOB.doom_screens) //prepare for every adminbus that can happend
		GLOB.doom_screens = list()
		message_admins("Doom transition was called after round started. It can cause dizziness and lots of ahelps from me, you know!")

	var/url_to_pic = get_screen_for_transition()
	var/mutable_appearance/image_to_use = mutable_appearance(url_to_pic)
	var/obj/item/debug_thingy = new /obj/item/card/emag_broken()
	debug_thingy.name = "[image_to_use]"
	debug_thingy.forceMove(get_turf(player))
	debug_thingy.appearance = image_to_use

/proc/get_screen_for_transition()
	var/title_screen = SStitle.current_title_screen.screen_image
	var/image_url = SSassets.transport.get_asset_url(asset_cache_item = title_screen)
	return image_url
