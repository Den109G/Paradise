/obj/item/melee/butterfly
	var/active = 0
	var/force_on = 20 //force when active
	var/backstab_damage = 20
	var/throwforce_on = 20
	var/faction_bonus_force = 0 //Bonus force dealt against certain factions
	var/list/nemesis_factions //Any mob with a faction that exists in this list will take bonus damage/effects
	stealthy_audio = TRUE //Most of these are antag weps so we dont want them to be /too/ overt.
	w_class = WEIGHT_CLASS_SMALL
	force = 5
	var/w_class_on = WEIGHT_CLASS_BULKY
	var/backstab_cooldown = 0
	var/icon_state_on = "telebaton_1"
	var/icons_state_off = "telebaton_0"
	var/icon_off = null
	var/list/attack_verb_on = list("attacked", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	hitsound = null // Probably more appropriate than the previous hitsound. -- Dave
	usesound = 'sound/weapons/blade_sheath.ogg'
	max_integrity = 200
	armor = list("melee" = 0, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 100, "acid" = 30)
	resistance_flags = FIRE_PROOF
	toolspeed = 1
	var/datum/action/item_action/chameleon/change/chameleon_action

/obj/item/melee/butterfly/Initialize(mapload)
	. = ..()
	chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item
	chameleon_action.chameleon_name = "item"
	chameleon_action.chameleon_blacklist = typecacheof(list(/obj/item))
	chameleon_action.initialize_disguises()

/obj/item/melee/butterfly/attack_self(mob/living/carbon/user)
	if((CLUMSY in user.mutations) && prob(50))
		to_chat(user, "<span class='warning'>You accidentally cut yourself with [src], like a doofus!</span>")
		user.take_organ_damage(5,5)
	active = !active
	if(active)
		force += force_on
		throwforce = throwforce_on
		icons_state_off = icon_state
		icon_off = icon
		icon_state = icon_state_on
		hitsound = 'sound/weapons/bladeslice.ogg'
		throw_speed = 4
		if(attack_verb_on.len)
			attack_verb = attack_verb_on
		w_class = w_class_on
		playsound(user, usesound, 15, 1, 0, 50) //changed it from 50% volume to 35% because deafness
		to_chat(user, "<span class='notice'>[src] is now extended.</span>")
	else
		force = initial(force)
		throwforce = initial(throwforce)
		hitsound = initial(hitsound)
		throw_speed = initial(throw_speed)
		if(attack_verb_on.len)
			attack_verb = list()
		icon_state = icons_state_off
		icon = icon_off
		w_class = initial(w_class)
		playsound(user, 'sound/weapons/saberoff.ogg', 35, 1)  //changed it from 50% volume to 35% because deafness
		set_light(0)
		to_chat(user, "<span class='notice'>[src] can now be concealed.</span>")
	if(istype(user,/mob/living/carbon/human))
		var/mob/living/carbon/human/H = user
		H.update_inv_l_hand()
		H.update_inv_r_hand()
	add_fingerprint(user)
	return

/obj/item/melee/butterfly/attack(mob/living/M, mob/living/user, def_zone)
	var/extra_force_applied = FALSE
	if(active && user.dir == M.dir && !M.incapacitated(TRUE) && user != M && backstab_cooldown <= world.time)
		backstab_cooldown = (world.time + 6 SECONDS)
		force += backstab_damage
		extra_force_applied = TRUE
		M.Weaken(1)
		M.adjustStaminaLoss(40)
		add_attack_logs(user, M, "Backstabbed with [src]", ATKLOG_ALL)
		M.visible_message("<span class='warning'>[user] stabs [M] in the back!</span>", "<span class='userdanger'>[user] stabs you in the back! The energy blade makes you collapse in pain!</span>")
		playsound(loc, hitsound, 5, TRUE, ignore_walls = FALSE, falloff_distance = 0)
	else
		playsound(loc, hitsound, 5, TRUE, ignore_walls = FALSE, falloff_distance = 0)
	. = ..()
	if(extra_force_applied)
		force -= backstab_damage
