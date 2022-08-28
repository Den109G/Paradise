/obj/effect/proc_holder/spell/genetic
	name = "Genetic"
	desc = "This spell inflicts a set of mutations and disabilities upon the target."

	var/list/mutations = list() //mutation strings
	var/duration = 100 //deciseconds
	/*
		Disabilities
			1st bit - ?
			2nd bit - ?
			3rd bit - ?
			4th bit - ?
			5th bit - ?
			6th bit - ?
	*/

/obj/effect/proc_holder/spell/genetic/cast(list/targets, mob/user = usr)

	for(var/mob/living/target in targets)
		for(var/x in mutations)
			target.mutations.Add(x)
		target.update_mutations()	//update target's mutation overlays
		var/mob/living/carbon/human/H = target
		if(ishuman(target))
			H.update_body()
		spawn(duration)
			target.mutations.Remove(mutations)
			target.update_mutations()
			if(ishuman(target))
				H.update_body()

	return
