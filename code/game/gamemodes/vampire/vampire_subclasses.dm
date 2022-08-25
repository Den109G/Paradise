/datum/vampire_subclass
	/// The subclass' name. Used for blackbox logging.
	var/name = "yell at coderbus"
	/// A list of powers that a vampire unlocks. The value of the list entry is equal to the blood total required for the vampire to unlock it.
	var/list/standard_powers
	/// A list of the powers a vampire unlocks when it reaches full power.
	var/list/fully_powered_abilities
	/// Whether or not a vampire heals more based on damage taken.
	var/improved_rejuv_healing = FALSE
	/// maximun number of thralls a vampire may have at a time. incremented as they grow stronger, up to a cap at full power.
	var/thrall_cap = 1
	var/full_power_overide = FALSE

/datum/vampire_subclass/proc/add_subclass_ability(datum/vampire/vamp)
	for(var/thing in standard_powers)
		if(vamp.bloodtotal >= standard_powers[thing])
			vamp.add_ability(thing)

/datum/vampire_subclass/proc/add_full_power_abilities(datum/vampire/vamp)
	for(var/thing in fully_powered_abilities)
		vamp.add_ability(thing)

/datum/vampire_subclass/umbrae
	name = "umbrae"
	standard_powers = list(/obj/effect/proc_holder/spell/self/vampire/cloak = 150,
							/obj/effect/proc_holder/spell/targeted/click/shadow_snare = 250,
							/obj/effect/proc_holder/spell/targeted/click/dark_passage = 400,
							/obj/effect/proc_holder/spell/aoe_turf/vamp_extinguish = 600)
	fully_powered_abilities = list(/datum/vampire_passive/full,
								/obj/effect/proc_holder/spell/self/vampire/eternal_darkness,
								/datum/vampire_passive/xray)

/datum/vampire_subclass/hemomancer
	name = "hemomancer"
	standard_powers = list(/obj/effect/proc_holder/spell/self/vampire/vamp_claws = 150,
							/obj/effect/proc_holder/spell/targeted/click/blood_tendrils = 250,
							/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/blood_pool = 400,
							/obj/effect/proc_holder/spell/blood_eruption = 600)
	fully_powered_abilities = list(/datum/vampire_passive/full,
								/obj/effect/proc_holder/spell/self/vampire/blood_spill)

/datum/vampire_subclass/gargantua
	name = "gargantua"
	standard_powers = list(/obj/effect/proc_holder/spell/self/vampire/blood_swell = 150,
							/obj/effect/proc_holder/spell/self/vampire/blood_rush = 250,
							/datum/vampire_passive/blood_swell_upgrade = 400,
							/obj/effect/proc_holder/spell/self/vampire/overwhelming_force = 600)
	fully_powered_abilities = list(/datum/vampire_passive/full,
								/obj/effect/proc_holder/spell/targeted/click/charge)
	improved_rejuv_healing = TRUE
/datum/vampire_subclass/dantalion
	name = "dantalion"
	standard_powers = list(/obj/effect/proc_holder/spell/vampire/targetted/enthrall = 150,
						/obj/effect/proc_holder/spell/vampire/thrall_commune = 150,
						/obj/effect/proc_holder/spell/vampire/pacify = 250,
						/obj/effect/proc_holder/spell/vampire/self/decoy = 400,
						/datum/vampire_passive/increment_thrall_cap = 400,
						/obj/effect/proc_holder/spell/vampire/rally_thralls = 600,
						/datum/vampire_passive/increment_thrall_cap/two = 600)
	fully_powered_abilities = list(/datum/vampire_passive/full,
									/obj/effect/proc_holder/spell/vampire/hysteria,
									/datum/vampire_passive/increment_thrall_cap/three)

/datum/vampire_subclass/ancient
	name = "ancient"
	standard_powers = list(/obj/effect/proc_holder/spell/self/vampire/vamp_claws,
							/obj/effect/proc_holder/spell/vampire/targetted/enthrall,
							/obj/effect/proc_holder/spell/vampire/thrall_commune,
							/obj/effect/proc_holder/spell/self/vampire/blood_swell,
							/obj/effect/proc_holder/spell/self/vampire/cloak,
							/obj/effect/proc_holder/spell/targeted/click/blood_tendrils,
							/obj/effect/proc_holder/spell/self/vampire/blood_rush,
							/obj/effect/proc_holder/spell/targeted/click/shadow_snare,
							/obj/effect/proc_holder/spell/vampire/pacify,
							/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/blood_pool,
							/datum/vampire_passive/blood_swell_upgrade,
							/obj/effect/proc_holder/spell/targeted/click/dark_passage,
							/obj/effect/proc_holder/spell/vampire/self/decoy,
							/obj/effect/proc_holder/spell/blood_eruption,
							/obj/effect/proc_holder/spell/self/vampire/overwhelming_force,
							/obj/effect/proc_holder/spell/aoe_turf/vamp_extinguish,
							/obj/effect/proc_holder/spell/vampire/rally_thralls,
							/obj/effect/proc_holder/spell/targeted/raise_vampires,
							/datum/vampire_passive/full,
							/obj/effect/proc_holder/spell/self/vampire/blood_spill,
							/obj/effect/proc_holder/spell/targeted/click/charge,
							/obj/effect/proc_holder/spell/self/vampire/eternal_darkness,
							/obj/effect/proc_holder/spell/vampire/hysteria,
							/datum/vampire_passive/xray)
	improved_rejuv_healing = TRUE
	thrall_cap = 150 // can thrall high pop