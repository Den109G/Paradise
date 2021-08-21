//Regular syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate
	name = "red space helmet"
	desc = "Top secret Spess Helmet."
	icon_state = "syndicate"
	item_state = "syndicate"
	desc = "Has a tag on it: Totally not property of a hostile corporation, honest!"
	armor = list(MELEE = 40, BULLET = 50, LASER = 30, ENERGY = 15, BOMB = 30, BIO = 30, RAD = 30, FIRE = 80, ACID = 85)
	sprite_sheets = list(
		"Grey" = 'icons/mob/species/grey/helmet.dmi',
		"Tajaran" = 'icons/mob/species/tajaran/helmet.dmi',
		"Unathi" = 'icons/mob/species/unathi/helmet.dmi',
		"Vulpkanin" = 'icons/mob/species/vulpkanin/helmet.dmi',
		"Vox" = 'icons/mob/species/vox/helmet.dmi')


/obj/item/clothing/suit/space/syndicate
	name = "red space suit"
	icon_state = "syndicate"
	item_state = "space_suit_syndicate"
	desc = "Has a tag on it: Totally not property of a hostile corporation, honest!"
	w_class = WEIGHT_CLASS_NORMAL
	allowed = list(/obj/item/gun,/obj/item/ammo_box,/obj/item/ammo_casing,/obj/item/melee/baton,/obj/item/melee/energy/sword/saber,/obj/item/restraints/handcuffs,/obj/item/tank/internals)
	armor = list(MELEE = 40, BULLET = 50, LASER = 30, ENERGY = 15, BOMB = 30, BIO = 30, RAD = 30, FIRE = 80, ACID = 85)
	sprite_sheets = list(
		"Tajaran" = 'icons/mob/species/tajaran/suit.dmi',
		"Unathi" = 'icons/mob/species/unathi/suit.dmi',
		"Vulpkanin" = 'icons/mob/species/vulpkanin/suit.dmi',
		"Vox" = 'icons/mob/species/vox/suit.dmi')


//Green syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/green
	name = "green space helmet"
	icon_state = "syndicate-helm-green"
	item_state = "syndicate-helm-green"

/obj/item/clothing/suit/space/syndicate/green
	name = "green space suit"
	icon_state = "syndicate-green"
	item_state = "syndicate-green"


//Dark green syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/green/dark
	name = "dark green space helmet"
	icon_state = "syndicate-helm-green-dark"
	item_state = "syndicate-helm-green-dark"

/obj/item/clothing/suit/space/syndicate/green/dark
	name = "dark green space suit"
	icon_state = "syndicate-green-dark"
	item_state = "syndicate-green-dark"


//Orange syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/orange
	name = "orange space helmet"
	icon_state = "syndicate-helm-orange"
	item_state = "syndicate-helm-orange"

/obj/item/clothing/suit/space/syndicate/orange
	name = "orange space suit"
	icon_state = "syndicate-orange"
	item_state = "syndicate-orange"


//Blue syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/blue
	name = "blue space helmet"
	icon_state = "syndicate-helm-blue"
	item_state = "syndicate-helm-blue"

/obj/item/clothing/suit/space/syndicate/blue
	name = "blue space suit"
	icon_state = "syndicate-blue"
	item_state = "syndicate-blue"


//Black syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/black
	name = "black space helmet"
	icon_state = "syndicate-helm-black"
	item_state = "syndicate-helm-black"

/obj/item/clothing/head/helmet/space/syndicate/black/strike
	name = "Syndicate Strike Team commando helmet"
	desc = "A heavily armored black helmet that is only given to high-ranking Syndicate operatives."
	armor = list(melee = 80, bullet = 80, laser = 50, energy = 50, bomb = 100, bio = 100, rad = 100, fire = 100, acid = 100) //Matches DS gear.
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	resistance_flags = ACID_PROOF

/obj/item/clothing/suit/space/syndicate/black
	name = "black space suit"
	icon_state = "syndicate-black"
	item_state = "syndicate-black"

/obj/item/clothing/suit/space/syndicate/black/strike
	name = "Syndicate Strike Team commando space suit"
	desc = "A heavily armored, black space suit that is only given to high-ranking Syndicate operatives."
	armor = list(melee = 80, bullet = 80, laser = 50, energy = 50, bomb = 100, bio = 100, rad = 100, fire = 100, acid = 100) //Matches DS gear.
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	resistance_flags = ACID_PROOF

//Black-green syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/black/green
	name = "black space helmet"
	icon_state = "syndicate-helm-black-green"
	item_state = "syndicate-helm-black-green"

/obj/item/clothing/suit/space/syndicate/black/green
	name = "black and green space suit"
	icon_state = "syndicate-black-green"
	item_state = "syndicate-black-green"


//Black-blue syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/black/blue
	name = "black space helmet"
	icon_state = "syndicate-helm-black-blue"
	item_state = "syndicate-helm-black-blue"

/obj/item/clothing/suit/space/syndicate/black/blue
	name = "black and blue space suit"
	icon_state = "syndicate-black-blue"
	item_state = "syndicate-black-blue"


//Black medical syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/black/med
	name = "black space helmet"
	icon_state = "syndicate-helm-black-med"
	item_state = "syndicate-helm-black"

/obj/item/clothing/suit/space/syndicate/black/med
	name = "green space suit"
	icon_state = "syndicate-black-med"
	item_state = "syndicate-black"


//Black-orange syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/black/orange
	name = "black space helmet"
	icon_state = "syndicate-helm-black-orange"
	item_state = "syndicate-helm-black"

/obj/item/clothing/suit/space/syndicate/black/orange
	name = "black and orange space suit"
	icon_state = "syndicate-black-orange"
	item_state = "syndicate-black"


//Black-red syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/black/red
	name = "black space helmet"
	icon_state = "syndicate-helm-black-red"
	item_state = "syndicate-helm-black-red"

/obj/item/clothing/head/helmet/space/syndicate/black/red/strike
	name = "Syndicate Strike Team leader helmet"
	desc = "A heavily armored, black and red space helmet that is only given to elite Syndicate operatives, it looks particularly menacing."
	armor = list(melee = 80, bullet = 80, laser = 50, energy = 50, bomb = 100, bio = 100, rad = 100, fire = 100, acid = 100) //Matches DS gear.
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	resistance_flags = ACID_PROOF

/obj/item/clothing/suit/space/syndicate/black/red
	name = "black and red space suit"
	icon_state = "syndicate-black-red"
	item_state = "syndicate-black-red"

/obj/item/clothing/suit/space/syndicate/black/red/strike
	name = "Syndicate Strike Team leader space suit"
	desc = "A heavily armored, black and red space suit that is only given to elite Syndicate operatives, it looks particularly menacing."
	armor = list(melee = 80, bullet = 80, laser = 50, energy = 50, bomb = 100, bio = 100, rad = 100, fire = 100, acid = 100) //Matches DS gear.
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	resistance_flags = ACID_PROOF


//Black with yellow/red engineering syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/black/engie
	name = "black space helmet"
	icon_state = "syndicate-helm-black-engie"
	item_state = "syndicate-helm-black"

/obj/item/clothing/suit/space/syndicate/black/engie
	name = "black engineering space suit"
	icon_state = "syndicate-black-engie"
	item_state = "syndicate-black"

/obj/item/clothing/head/helmet/space/syndicate/contractor
	name = "contractor helmet"
	desc = "A specialised black and gold helmet that's more compact than its standard Syndicate counterpart. Can be ultra-compressed into even the tightest of spaces."
	w_class = WEIGHT_CLASS_SMALL
	icon_state = "syndicate-helm-contractor"
	item_state = "syndicate-helm-contractor"

/obj/item/clothing/suit/space/syndicate/contractor
	name = "contractor space suit"
	desc = "A specialised black and gold space suit that's quicker, and more compact than its standard Syndicate counterpart. Can be ultra-compressed into even the tightest of spaces."
	slowdown = 1
	w_class = WEIGHT_CLASS_SMALL
	icon_state = "syndicate-contractor"
	item_state = "syndicate-contractor"
