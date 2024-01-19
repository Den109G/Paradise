#define MULTIZ_PIPE_UP 1 ///Defines for determining which way a multiz disposal element should travel
#define MULTIZ_PIPE_DOWN 2 ///Defines for determining which way a multiz disposal element should travel


/obj/structure/disposalpipe/trunk/multiz
	name = "Disposal trunk that goes up"
	icon_state = "pipe-up"
	var/multiz_dir = MULTIZ_PIPE_UP ///Set the multiz direction of your trunk. 1 = up, 2 = down

/obj/structure/disposalpipe/trunk/multiz/down
	name = "Disposal trunk that goes down"
	icon_state = "pipe-down"
	multiz_dir = MULTIZ_PIPE_DOWN

/obj/structure/disposalpipe/trunk/multiz/transfer(obj/structure/disposalholder/H)
	if(H.dir == DOWN)		//Since we're a trunk, you can still place a chute / bin over us. If theyve entered from there, treat this as a normal trunk
		return ..()
	//If we for some reason do not have a multiz dir, just like, use the default logic
	if(!multiz_dir)
		return ..()

	var/turf/target = get_turf(src)
	if(multiz_dir == MULTIZ_PIPE_UP)
		target = GET_TURF_ABOVE(get_turf(src)) //Get the turf above us
	if(multiz_dir == MULTIZ_PIPE_DOWN)
		target = GET_TURF_BELOW(get_turf(src))
	if(!target)
		return //Nothing located.

	var/obj/structure/disposalpipe/trunk/multiz/pipe = locate(/obj/structure/disposalpipe/trunk/multiz) in target
	if(pipe)
		var/obj/structure/disposalholder/destination = new(pipe) //For future reference, the disposal holder is the thing that carries mobs
		destination.merge(H) //This takes the contents of H (Our disposal holder that's travelling into us) and puts them into the destination holder
		destination.active = TRUE //Active allows it to process and move
		destination.setDir(DOWN) //This tells the trunk above us NOT to loop it back down to us, or else you get an infinite loop
		destination.move()
		return null //Which removes the disposalholder

	// Returning null without expelling holder makes the holder expell itself
	return null

#undef MULTIZ_PIPE_UP
#undef MULTIZ_PIPE_DOWN
