GLOBAL_LIST_INIT(all_integrated_circuits, list())

/proc/initialize_integrated_circuits_list()
	for(var/thing in typesof(/obj/item/integrated_circuit))
		GLOB.all_integrated_circuits += new thing()

/obj/item/integrated_circuit
	name = "integrated circuit"
	desc = "It's a tiny chip!  This one doesn't seem to do much, however."
	icon = 'modular_skyrat/modules/integrated_circuits/icons/obj/integrated_electronicselectronic_components.dmi'
	icon_state = "template"
	w_class = ITEMSIZE_TINY
	var/obj/item/device/electronic_assembly/assembly = null // Reference to the assembly holding this circuit, if any.
	var/extended_desc = null
	var/list/inputs = list()
	var/list/inputs_default = list()			// Assoc list which will fill a pin with data upon creation.  e.g. "2" = 0 will set input pin 2 to equal 0 instead of null.
	var/list/outputs = list()
	var/list/outputs_default = list()		// Ditto, for output.
	var/list/activators = list()
	var/next_use = 0 //Uses world.time
	var/complexity = 1 				//This acts as a limitation on building machines, more resource-intensive components cost more 'space'.
	var/size = null					//This acts as a limitation on building machines, bigger components cost more 'space'. -1 for size 0
	var/cooldown_per_use = 1 SECONDS // Circuits are limited in how many times they can be work()'d by this variable.
	var/power_draw_per_use = 0 		// How much power is drawn when work()'d.
	var/power_draw_idle = 0			// How much power is drawn when doing nothing.
	var/spawn_flags = null			// Used for world initializing, see the #defines above.
	var/category_text = "NO CATEGORY THIS IS A BUG"	// To show up on circuit printer, and perhaps other places.
	var/removable = TRUE 			// Determines if a circuit is removable from the assembly.
	var/displayed_name = ""
	var/allow_multitool = 1			// Allows additional multitool functionality