/obj/item/integrated_circuit/reagent
	category_text = "Reagent"
	var/volume = 0
	var/reagent_flags
	resistance_flags = UNACIDABLE

/obj/item/integrated_circuit/reagent/Initialize()
	. = ..()
	if(volume)
		create_reagents(volume, reagent_flags)

/obj/item/integrated_circuit/reagent/smoke
	name = "smoke generator"
	desc = "Unlike most electronics, creating smoke is completely intentional."
	icon_state = "smoke"
	extended_desc = "This smoke generator creates clouds of smoke on command.  It can also hold liquids inside, which will go \
	into the smoke clouds when activated.  The reagents are consumed when smoke is made."
	reagent_flags = OPENCONTAINER
	complexity = 20
	cooldown_per_use = 30 SECONDS
	inputs = list()
	outputs = list("volume used" = IC_PINTYPE_NUMBER,"self reference" = IC_PINTYPE_REF)
	activators = list("create smoke" = IC_PINTYPE_PULSE_IN,"on smoked" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	volume = 100
	power_draw_per_use = 20

/obj/item/integrated_circuit/reagent/smoke/on_reagent_change()
	set_pin_data(IC_OUTPUT, 1, reagents.total_volume)
	push_data()


/obj/item/integrated_circuit/reagent/smoke/interact(mob/user)
	set_pin_data(IC_OUTPUT, 2, WEAKREF(src))
	push_data()
	..()

/obj/item/integrated_circuit/reagent/smoke/do_work()
	playsound(src, 'sound/effects/smoke.ogg', 50, 1, -3)
	var/datum/effect_system/smoke_spread/chem/smoke_system = new()
	smoke_system.set_up(reagents, 10, 0, get_turf(src))
	spawn(0)
		for(var/i = 1 to 8)
			smoke_system.start()
		reagents.clear_reagents()
	activate_pin(2)

/obj/item/integrated_circuit/reagent/injector
	name = "integrated hypo-injector"
	desc = "This scary looking thing is able to pump liquids into whatever it's pointed at."
	icon_state = "injector"
	extended_desc = "This autoinjector can push reagents into another container or someone else outside of the machine.  The target \
	must be adjacent to the machine, and if it is a person, they cannot be wearing thick clothing. A negative amount makes the injector draw out reagents."
	reagent_flags = OPENCONTAINER
	complexity = 20
	cooldown_per_use = 6 SECONDS
	inputs = list("target" = IC_PINTYPE_REF, "injection amount" = IC_PINTYPE_NUMBER)
	inputs_default = list("2" = 5)
	outputs = list("volume used" = IC_PINTYPE_NUMBER,"self reference" = IC_PINTYPE_REF)
	activators = list("inject" = IC_PINTYPE_PULSE_IN, "on injected" = IC_PINTYPE_PULSE_OUT, "on fail" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	volume = 30
	power_draw_per_use = 15
	var/direc = 1
	var/transfer_amount = 10
	/// needed for delayed drawing of blood
	var/busy = FALSE

/obj/item/integrated_circuit/reagent/injector/interact(mob/user)
	set_pin_data(IC_OUTPUT, 2, WEAKREF(src))
	push_data()
	..()


/obj/item/integrated_circuit/reagent/injector/on_reagent_change()
	set_pin_data(IC_OUTPUT, 1, reagents.total_volume)
	push_data()

/obj/item/integrated_circuit/reagent/injector/on_data_written()
	var/new_amount = get_pin_data(IC_INPUT, 2)
	if(new_amount < 0)
		new_amount = -new_amount
		direc = 0
	else
		direc = 1
	if(isnum(new_amount))
		new_amount = clamp(new_amount, 0, volume)
		transfer_amount = new_amount


/obj/item/integrated_circuit/reagent/injector/proc/injection_check(atom/target)
	if(busy)
		return FALSE
	if(get_dist(src, target) > 1 || z != target.z) // Too far
		return FALSE
	if(!target.reagents)
		return FALSE

	if(isliving(target))
		var/mob/living/living_target = target
		if(!living_target.try_inject(src, injection_flags = INJECT_TRY_SHOW_ERROR_MESSAGE))
			return FALSE

	return TRUE

/obj/item/integrated_circuit/reagent/injector/do_work()
	set waitfor = FALSE // Don't sleep in a proc that is called by a processor without this set, otherwise it'll delay the entire thing
	var/atom/movable/AM = get_pin_data_as_type(IC_INPUT, 1, /atom/movable)
	if(!istype(AM)) //Invalid input
		activate_pin(3)
		return

	if(direc == 1)

		if(!istype(AM)) //Invalid input
			activate_pin(3)
			return
		if(!reagents.total_volume) // Empty
			activate_pin(3)
			return
		if(!injection_check(AM))
			activate_pin(3)
			return
		if(isliving(AM))
			var/mob/living/L = AM
			var/turf/T = get_turf(AM)
			T.visible_message("<span class='warning'>[src] is trying to inject [L]!</span>")
			sleep(3 SECONDS)
			if(!injection_check(AM))
				activate_pin(3)
				return
			var/contained = reagents.get_reagents()
			reagents.trans_to(L, transfer_amount, transfered_by = src, methods = INJECT)
			to_chat(AM, "<span class='notice'>You feel a tiny prick!</span>")
			visible_message("<span class='warning'>[src] injects [L]!</span>")
		else
			reagents.trans_to(AM, transfer_amount)
	else

		if(reagents.total_volume >= volume) // Full
			activate_pin(3)
			return
		var/obj/target = AM
		if(!target.reagents)
			activate_pin(3)
			return
		var/turf/TS = get_turf(src)
		var/turf/TT = get_turf(AM)
		if(!injection_check(AM))
			activate_pin(3)
			return
		var/tramount = clamp(min(transfer_amount, reagents.maximum_volume - reagents.total_volume), 0, reagents.maximum_volume)
		if(isliving(target))
			var/mob/living/living_target = target
			target.visible_message("<span class='danger'>[src] is trying to take a blood sample from [target]!</span>", \
							"<span class='userdanger'>[src] is trying to take a blood sample from you!</span>")
			busy = TRUE
			sleep(3 SECONDS) // yeah i'm using sleep here fucking sue me
			busy = FALSE
			if(!injection_check(AM))
				activate_pin(3)
				return
			if(reagents.total_volume >= reagents.maximum_volume)
				activate_pin(3)
				return
			if(living_target.transfer_blood_to(src, tramount))
				src.visible_message("<span class='notice'>[src] takes a blood sample from [living_target].</span>")
			else
				activate_pin(3)
				return

		else //if not mob
			if(!target.reagents.total_volume)
				visible_message( "<span class='notice'>[src]: [target] is empty.</span>")
				activate_pin(3)
				return
			target.reagents.trans_to(src, tramount)
	activate_pin(2)

/obj/item/integrated_circuit/reagent/pump
	name = "reagent pump"
	desc = "Moves liquids safely inside a machine, or even nearby it."
	icon_state = "reagent_pump"
	extended_desc = "This is a pump, which will move liquids from the source ref to the target ref.  The third pin determines \
	how much liquid is moved per pulse, between 0 and 50.  The pump can move reagents to any open container inside the machine, or \
	outside the machine if it is next to the machine.  Note that this cannot be used on entities."
	reagent_flags = OPENCONTAINER
	complexity = 8
	inputs = list("source" = IC_PINTYPE_REF, "target" = IC_PINTYPE_REF, "injection amount" = IC_PINTYPE_NUMBER)
	inputs_default = list("3" = 5)
	outputs = list()
	activators = list("transfer reagents" = IC_PINTYPE_PULSE_IN, "on transfer" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	var/transfer_amount = 10
	var/direc = 1
	power_draw_per_use = 10

/obj/item/integrated_circuit/reagent/pump/on_data_written()
	var/new_amount = get_pin_data(IC_INPUT, 3)
	if(new_amount < 0)
		new_amount = -new_amount
		direc = 0
	else
		direc = 1
	if(isnum(new_amount))
		new_amount = clamp(new_amount, 0, 50)
		transfer_amount = new_amount

/obj/item/integrated_circuit/reagent/pump/do_work()
	var/atom/movable/source = get_pin_data_as_type(IC_INPUT, 1, /atom/movable)
	var/atom/movable/target = get_pin_data_as_type(IC_INPUT, 2, /atom/movable)

	if(!istype(source) || !istype(target)) //Invalid input
		return
	var/turf/T = get_turf(src)
	var/turf/TS = get_turf(source)
	var/turf/TT = get_turf(target)
	if(TS.Adjacent(T) && TT.Adjacent(T))
		if(!source.reagents || !target.reagents)
			return
		if(ismob(source) || ismob(target))
			return
		if(!source.is_open_container() || !target.is_open_container())
			return
		if(direc)
			if(!target.reagents.get_free_space())
				return
			source.reagents.trans_to(target, transfer_amount)
		else
			if(!source.reagents.get_free_space())
				return
			target.reagents.trans_to(source, transfer_amount)
		activate_pin(2)

/obj/item/integrated_circuit/reagent/storage
	name = "reagent storage"
	desc = "Stores liquid inside, and away from electrical components.  Can store up to 60u."
	icon_state = "reagent_storage"
	extended_desc = "This is effectively an internal beaker."
	reagent_flags = OPENCONTAINER
	complexity = 4
	inputs = list()
	outputs = list("volume used" = IC_PINTYPE_NUMBER,"self reference" = IC_PINTYPE_REF)
	activators = list()
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	volume = 60


/obj/item/integrated_circuit/reagent/storage/interact(mob/user)
	set_pin_data(IC_OUTPUT, 2, WEAKREF(src))
	push_data()
	..()

/obj/item/integrated_circuit/reagent/storage/on_reagent_change()
	set_pin_data(IC_OUTPUT, 1, reagents.total_volume)
	push_data()

/obj/item/integrated_circuit/reagent/storage/cryo
	name = "cryo reagent storage"
	desc = "Stores liquid inside, and away from electrical components.  Can store up to 60u.  This will also suppress reactions."
	icon_state = "reagent_storage_cryo"
	extended_desc = "This is effectively an internal cryo beaker."
	reagent_flags = OPENCONTAINER | NO_REACT
	complexity = 8
	spawn_flags = IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/reagent/storage/big
	name = "big reagent storage"
	desc = "Stores liquid inside, and away from electrical components.  Can store up to 180u."
	icon_state = "reagent_storage_big"
	extended_desc = "This is effectively an internal beaker."
	reagent_flags = OPENCONTAINER
	complexity = 16
	volume = 180
	spawn_flags = IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/reagent/storage/scan
	name = "reagent scanner"
	desc = "Stores liquid inside, and away from electrical components.  Can store up to 60u.  On pulse this beaker will send list of contained reagents."
	icon_state = "reagent_scan"
	extended_desc = "Mostly useful for reagent filter."
	reagent_flags = OPENCONTAINER
	complexity = 8
	outputs = list("volume used" = IC_PINTYPE_NUMBER,"self reference" = IC_PINTYPE_REF,"list of reagents" = IC_PINTYPE_LIST)
	activators = list("scan" = IC_PINTYPE_PULSE_IN)
	spawn_flags = IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/reagent/storage/scan/do_work()
	var/cont[0]
	for(var/datum/reagent/RE in reagents.reagent_list)
		cont += RE.type
	set_pin_data(IC_OUTPUT, 3, cont)
	push_data()


/obj/item/integrated_circuit/reagent/filter
	name = "reagent filter"
	desc = "Filtering liquids by list of desired or unwanted reagents."
	icon_state = "reagent_filter"
	extended_desc = "This is a filter which will move liquids from the source ref to the target ref. \
	It will move all reagents, except list, given in fourth pin if amount value is positive.\
	Or it will move only desired reagents if amount is negative, The third pin determines \
	how much reagent is moved per pulse, between 0 and 50. Amount is given for each separate reagent."
	reagent_flags = OPENCONTAINER
	complexity = 8
	inputs = list("source" = IC_PINTYPE_REF, "target" = IC_PINTYPE_REF, "injection amount" = IC_PINTYPE_NUMBER, "list of reagents" = IC_PINTYPE_LIST)
	inputs_default = list("3" = 5)
	outputs = list()
	activators = list("transfer reagents" = IC_PINTYPE_PULSE_IN, "on transfer" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	var/transfer_amount = 10
	var/direc = 1
	power_draw_per_use = 10

/obj/item/integrated_circuit/reagent/filter/on_data_written()
	var/new_amount = get_pin_data(IC_INPUT, 3)
	if(new_amount < 0)
		new_amount = -new_amount
		direc = 0
	else
		direc = 1
	if(isnum(new_amount))
		new_amount = clamp(new_amount, 0, 50)
		transfer_amount = new_amount

/obj/item/integrated_circuit/reagent/filter/do_work()
	var/atom/movable/source = get_pin_data_as_type(IC_INPUT, 1, /atom/movable)
	var/atom/movable/target = get_pin_data_as_type(IC_INPUT, 2, /atom/movable)
	var/list/demand = get_pin_data(IC_INPUT, 4)
	if(!istype(source) || !istype(target)) //Invalid input
		return
	var/turf/T = get_turf(src)
	if(source.Adjacent(T) && target.Adjacent(T))
		if(!source.reagents || !target.reagents)
			return
		if(ismob(source) || ismob(target))
			return
		if(!source.is_open_container() || !target.is_open_container())
			return
		if(!target.reagents.get_free_space())
			return
		for(var/datum/reagent/G in source.reagents.reagent_list)
			if (!direc)
				if(G.type in demand)
					source.reagents.trans_id_to(target, G.type, transfer_amount)
			else
				if(!(G.type in demand))
					source.reagents.trans_id_to(target, G.type, transfer_amount)
		activate_pin(2)
		push_data()



