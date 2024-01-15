#define STAIR_TERMINATOR_AUTOMATIC 0
#define STAIR_TERMINATOR_NO 1
#define STAIR_TERMINATOR_YES 2

// dir determines the direction of travel to go upwards
// stairs require /turf/simulated/openspace as the tile above them to work, unless your stairs have 'force_open_above' set to TRUE
// multiple stair objects can be chained together; the Z level transition will happen on the final stair object in the chain

/obj/structure/stairs
	name = "stairs"
	icon = 'icons/obj/stairs.dmi'
	icon_state = "stairs"
	anchored = TRUE
	move_resist = INFINITY

	var/force_open_above = FALSE // replaces the turf above this stair obj with /turf/simulated/openspace
	var/terminator_mode = STAIR_TERMINATOR_AUTOMATIC
	var/turf/listeningTo

/obj/structure/stairs/north
	dir = NORTH

/obj/structure/stairs/south
	dir = SOUTH

/obj/structure/stairs/east
	dir = EAST

/obj/structure/stairs/west
	dir = WEST

/obj/structure/stairs/wood
	icon_state = "stairs_wood"
