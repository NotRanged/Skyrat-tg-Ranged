
// The base subtype for assemblies that can be worn. Certain pieces will have more or less capabilities
// E.g. Glasses have less room than something worn over the chest.
// Note that the electronic assembly is INSIDE the object that actually gets worn, in a similar way to implants.

/obj/item/device/electronic_assembly/clothing
	name = "electronic clothing"
	icon_state = "circuitry" // Needs to match the clothing's base icon_state.
	desc = "It's a case, for building machines attached to clothing."
	w_class = ITEMSIZE_SMALL
	max_components = IC_COMPONENTS_BASE
	max_complexity = IC_COMPLEXITY_BASE
	var/obj/item/clothing/clothing = null

/obj/item/device/electronic_assembly/clothing/nano_host()
	return clothing

/obj/item/device/electronic_assembly/clothing/resolve_nano_host()
	return clothing

/obj/item/device/electronic_assembly/clothing/update_icon()
	..()
	clothing.icon_state = icon_state
	// We don't need to update the mob sprite since it won't (and shouldn't) actually get changed.

// This is 'small' relative to the size of regular clothing assemblies.
/obj/item/device/electronic_assembly/clothing/small
	max_components = IC_COMPONENTS_BASE / 2
	max_complexity = IC_COMPLEXITY_BASE / 2
	w_class = ITEMSIZE_TINY

// Ditto.
/obj/item/device/electronic_assembly/clothing/large
	max_components = IC_COMPONENTS_BASE * 2
	max_complexity = IC_COMPLEXITY_BASE * 2
	w_class = ITEMSIZE_NORMAL


/*
// Extra vars for clothing here
*/
/obj/item/clothing/
	var/obj/item/device/electronic_assembly/clothing/integrated_circuit = null
	var/obj/item/integrated_circuit/built_in/action_button/action_circuit = null // This gets pulsed when someone clicks the button on the hud.
	actions_types = list(/datum/action/item_action/toggle_circuit)

// Does most of the repeatative setup.
/obj/item/clothing/proc/setup_integrated_circuit(new_type)
	// Set up the internal circuit holder.
	integrated_circuit = new new_type(src)
	integrated_circuit.clothing = src
	integrated_circuit.name = name

	// Clothing assemblies can be triggered by clicking on the HUD. This allows that to occur.
	action_circuit = new(src.integrated_circuit)
	integrated_circuit.force_add_circuit(action_circuit)
	action_button_name = "Activate [name]"

/datum/action/item_action/toggle_circuit
	name = "Toggle Integrated Circuit"
