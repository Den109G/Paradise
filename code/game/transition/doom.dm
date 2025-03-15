/// List with transition screens
GLOBAL_LIST_EMPTY(transition_screens)


//Doesn't work with every resolution
#define ui_transition "CENTER-7, CENTER-7"

/*
*Clears player's screen (title screen for now) from any transitions
*	player - whose screen we are changing
*if no/wrong player provided - nuke
*/
/proc/clear_transition(mob/player)
	if(player && LAZYFIND(GLOB.transition_screens, "[player]")) //maybe we cleared already?
		var/screen = GLOB.transition_screens["[player]"]
		qdel(screen)
		return TRUE

	//no player? or no screen? nuke every screen to exist, just to be sure
	QDEL_LAZYLIST(GLOB.transition_screens)
	message_admins("Okay, something went horribly wrong. D-double O-M just was cleared without \"player\" arg, \
	it nuked itself.") //snitch to admins that (adminbus) something horribly wrong-est is happening
	return FALSE

/*
* Proc to easily adminbusing this mid game
*/

/mob/proc/force_doom()
	return doom_transition(src)


/atom/movable/screen/transition
	name = "DOOM"
	//icon = null //SStitle shoud be our image
	screen_loc = ui_transition
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = CINEMATIC_LAYER
	plane = SPLASHSCREEN_PLANE

/datum/hud
	var/atom/movable/screen/transition/transition

/datum/hud/New(mob/owner)
	. = ..()

	transition = new /atom/movable/screen/transition()
	transition.name = "Let this secret stay between you and me, m'kay?"


#define TRANSITION_ICON_SIZE 480
#define TRANSITION_RESOLUTION 15
#define TRANSITION_CENTER_X round(TRANSITION_ICON_SIZE / 2)
#define TRANSITION_CENTER_Y round(TRANSITION_ICON_SIZE / 2)

/*
* Copies player's screen (title screen for now) and applies "melting effect"
*	player - whose screen we are changing
*/
/proc/doom_transition(mob/player)
	if(!player || !ismob(player)) //question every arg, even for one-day joke
		return FALSE

	var/image/image_to_use = get_screen_for_transition()
	image_to_use.loc = player.hud_used.transition
	//image_to_use.pixel_x = TRANSITION_CENTER_X
	//image_to_use.pixel_y = TRANSITION_CENTER_Y
	GLOB.transition_screens["[player]"] = image_to_use

	player.client.screen |= player.hud_used.transition
	player.client.images |= image_to_use
	return TRUE

#undef TRANSITION_ICON_SIZE
#undef TRANSITION_RESOLUTION
#undef TRANSITION_CENTER_X
#undef TRANSITION_CENTER_Y

/proc/get_screen_for_transition()
	/* is not working cause its stores assets like "asset.[ID].geef", which server can't find
	made a hack in SStitle for a april fools day, find better solution
	var/title_screen = SStitle.current_title_screen.screen_image
	var/image_url = SSassets.transport.get_asset_url(asset_cache_item = title_screen)
	return new /mutable_appearance(image_url)
	*/
	//fix me
	var/icon_to_use = SStitle.image_for_screen
	return new /image(icon_to_use) //create new image, cause we don't wanna ruin other's experience
