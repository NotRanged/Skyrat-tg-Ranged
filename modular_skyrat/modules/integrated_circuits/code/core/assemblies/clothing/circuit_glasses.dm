// Glasses.
/obj/item/clothing/glasses/circuitry
	name = "electronic goggles"
	desc = "It's a wearable case for electronics. This one is a pair of goggles, with wiring sticking out. \
	Could this augment your vision? \
	Control-shift-click on this with an item in hand to use it on the integrated circuit." // Sadly it won't, or at least not yet.
	icon_state = "circuitry"
	item_state = "night" // The on-mob sprite would be identical anyways.

/obj/item/clothing/glasses/circuitry/Initialize()
	setup_integrated_circuit(/obj/item/device/electronic_assembly/clothing/small)
	return ..()

/obj/item/clothing/glasses/circuitry/examine(mob/user)
	. = ..()
	if(integrated_circuit)
		. += integrated_circuit.examine(user)

/obj/item/clothing/glasses/circuitry/emp_act(severity)
	if(integrated_circuit)
		integrated_circuit.emp_act(severity)
	..()

/obj/item/clothing/glasses/circuitry/CtrlShiftClick(mob/user)
	var/turf/T = get_turf(src)
	if(!T.AdjacentQuick(user)) // So people aren't messing with these from across the room
		return FALSE
	var/obj/item/I = user.get_active_hand() // ctrl-shift-click doesn't give us the item, we have to fetch it
	return integrated_circuit.attackby(I, user)

/obj/item/clothing/glasses/circuitry/attack_self(mob/user)
	if(integrated_circuit)
		if(integrated_circuit.opened)
			integrated_circuit.attack_self(user)
		else
			action_circuit.do_work()
	else
		..()

/obj/item/clothing/glasses/circuitry/Destroy()
	if(integrated_circuit)
		integrated_circuit.clothing = null
		action_circuit = null // Will get deleted by qdel-ing the integrated_circuit assembly.
		qdel(integrated_circuit)
	return ..()
