//centcomAway areas

/area/awaymission/centcomAway
	name = "XCC-P5831"
	icon_state = "away"
	report_alerts = FALSE
	requires_power = FALSE

/area/awaymission/centcomAway/general
	name = "XCC-P5831"
	ambientsounds = list('sound/ambience/ambigen3.ogg')

/area/awaymission/centcomAway/maint
	name = "XCC-P5831 Maintenance"
	icon_state = "away1"
	ambientsounds = list('sound/ambience/ambisin1.ogg')

/area/awaymission/centcomAway/thunderdome
	name = "XCC-P5831 Thunderdome"
	icon_state = "away2"
	ambientsounds = list('sound/ambience/ambisin2.ogg')

/area/awaymission/centcomAway/cafe
	name = "XCC-P5831 Kitchen Arena"
	icon_state = "away3"
	ambientsounds = list('sound/ambience/ambisin3.ogg')

/area/awaymission/centcomAway/courtroom
	name = "XCC-P5831 Courtroom"
	icon_state = "away4"
	ambientsounds = list('sound/ambience/ambisin4.ogg')

/area/awaymission/centcomAway/hangar
	name = "XCC-P5831 Hangars"
	icon_state = "away4"
	ambientsounds = list('sound/ambience/ambigen5.ogg')

//centcomAway items

/obj/item/paper/pamphlet/ccaInfo
	name = "Visitor Info Pamphlet"
	info = "<b> XCC-P5831 Visitor Information </b><br>\
	Greetings, visitor, to  XCC-P5831! As you may know, this outpost was once \
	used as Nanotrasen's CENTRAL COMMAND STATION, organizing and coordinating company \
	projects across the vastness of space. <br>\
	Since the completion of the much more efficient CC-A5831 on March 8, 2553, XCC-P5831 no longer \
	acts as NT's base of operations but still plays a very important role its corporate affairs; \
	serving as a supply and repair depot, as well as being host to its most important legal proceedings\
	and the thrilling pay-per-view broadcasts of <i>PLASTEEL CHEF</i> and <i>THUNDERDOME LIVE</i>.<br> \
	We hope you enjoy your stay!"

/obj/item/paper/ccaMemo
	name = "Memo to XCC-P5831 QM"
	info = "<b>From: XCC-P5831 Management Office</b><br>\
	<b>To: Rolf Ingram, XCC-P5831 Quartermaster</b><br>\
	Hey, Rolf, once you pack that gateway into the ferry hangar, <i>make absolutely sure</i> \
	to deactivate it! As you may know, SS13 has recently got its network up and running, \
	which means that until we get this gate shipped off to the next colonization staging \
	area, they'll be able to hop straight in here if its hooked up on our end.<br>\
	Obviously, that's something I'd very much rather avoid. Our forensics and medical \
	teams never did figure out what happened that last time... and I can't wrap my head \
	around it myself. Why would a shuttle full of evacuees all snap and beat each other \
	to death the moment they reached safety?<br>\
	- D. Cereza"

/obj/structure/closet/secure_closet/cabinet/haunted
	var/spooky = TRUE //time fucker-y thingy. You know?

/obj/structure/closet/secure_closet/cabinet/haunted/after_open()
	if(!spooky)
		return
	spooky = FALSE
	var/mob/living/carbon/human/thy_criminal = locate(/mob/living/carbon/human) in range(2, src) //will be funny if opener show a "funny" to other players
	if(!thy_criminal || !thy_criminal.client)
		return //okay, who in their mind will open a cabinet with a 357 magnum?
	var/obj/item/newspaper/centcommaway/news = new(loc)
	news.make_up_story(thy_criminal)

/obj/item/newspaper/centcommaway
	desc = parent_type::desc + "These papers are extremely old."

/obj/item/newspaper/centcommaway/proc/make_up_story(var/mob/living/carbon/human/thy_criminal)
	var/consistent_story = pick("Murderer", "Thief", "Prisoner", "Enemie of the Corporation")
	var/datum/feed_message/big_anon = new()
	big_anon.author = "[thy_criminal.real_name]" //it says author, but in news its a killer's name
	big_anon.body = "[consistent_story] from [station_name()]. It klled a few workers on CC. It has wizard-like abilities, but doesn't announce it's spell! Be careful."
	important_message = big_anon
	var/datum/feed_channel/feed = new()
	feed.author = "CentComm Minister of Information"
	feed.channel_name = "Nyx Daily"
	var/datum/feed_message/letter_to_player = new()
	letter_to_player.author ="CentComm Minister of Information"
	letter_to_player.title = "[consistent_story] was found dead on CentComm."
	letter_to_player.body = "Criminal, also known as \"[thy_criminal.real_name]\", former crew member of [station_name()] was went rampage this morning on \
	YOUR station's CC! \
	That's right, criminal without any equipment could teleport and control space of NAS XCC-P5831 around them. \
	That's -- I would say -- IS definition of a wizard if I've seen one, so security killed them to safe humanity.\n \
	Next news: CC-A5831 is still under construction and will have anti-magic barriers in place for these attacks. How do they work? I don't know, I am just PR guy."
	feed.messages = list(letter_to_player)
	news_content += feed
	var/icon/news_photo
	var/datum/data/record/thy_face = find_record("name", thy_criminal.real_name, GLOB.data_core.general)
	if(!thy_face)
		var/face = get_id_photo(thy_criminal)
		news_photo = icon('icons/turf/floors/plating.dmi', "asteroidwarning")
		news_photo.Blend(icon(face, dir = SOUTH), ICON_OVERLAY, 0)
		news_photo.Scale(news_photo.Width() * 3, news_photo.Height() * 3)
	else
		news_photo = icon('icons/effects/64x32.dmi', "records")
		news_photo.Blend(icon(thy_face.fields["photo"], dir = SOUTH), ICON_OVERLAY, 0)
		news_photo.Blend(icon(thy_face.fields["photo"], dir = WEST), ICON_OVERLAY, 32)
		news_photo.Scale(news_photo.Width() * 3, news_photo.Height() * 3)
	big_anon.img = news_photo


GLOBAL_LIST_EMPTY(cutscene_points)

/obj/effect/cutscene_helper //we see in prod how we can dilute shooting with story-telling
	invisibility = INVISIBILITY_ABSTRACT
	var/scene = null

/obj/effect/cutscene_helper/Initialize(mapload)
	. = ..()
	GLOB.cutscene_points += src

/obj/effect/step_trigger/cutscene
	var/scene = null
