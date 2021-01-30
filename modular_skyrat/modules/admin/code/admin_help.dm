/datum/admin_help
	var/handler

//Let the initiator know their ahelp is being handled
/datum/admin_help/proc/HandleIssue(key_name = key_name_admin(usr))
	if(state != AHELP_ACTIVE)
		return

	//SKYRAT EDIT ADDITION BEGIN - ADMIN
	if(handler && handler != usr.ckey)
		var/response = alert(usr, "This ticket is already being handled by [handler]. Do you want to continue?", "Ticket already assigned", "Yes", "No")
		if(!response || response == "No")
			return
	//SKYRAT EDIT ADDITION END

	var/msg = "<span class ='adminhelp'>Your ticket is now being handled by [usr?.client?.holder?.fakekey? usr.client.holder.fakekey : "an administrator"]! Please wait while they type their response and/or gather relevant information.</span>"

	if(initiator)
		to_chat(initiator, msg)

	SSblackbox.record_feedback("tally", "ahelp_stats", 1, "handling")
	msg = "Ticket [TicketHref("#[id]")] is being handled by [key_name]"
	message_admins(msg)
	log_admin_private(msg)
	AddInteraction("Being handled by [key_name]")

	handler = "[usr.ckey]"

// Personal tickets for players
/datum/admin_help_tickets/proc/BrowserPlayerTickets()
	var/list/dat = list("<html><head><meta http-equiv='Content-Type' content='text/html; charset=UTF-8'><title>My Tickets</title></head>")
	dat += "<A href='?_src_=holder;[HrefToken()];my_ahelp_tickets=\"TRUE\"'>Refresh</A><br><br>"
	var/player_ticket_id = 1
	for(var/I in usr.client.tickets)
		var/datum/admin_help/AH = I
		dat += "<span class='adminnotice'><span class='adminhelp'>Ticket #[player_ticket_id]</span>: <A href='?_src_=holder;[HrefToken()];ahelp_player=[REF(AH)];ahelp_action=player_ticket'>[AH.initiator_key_name]: [AH.name]</A></span><br>"
		player_ticket_id += 1

	usr << browse(dat.Join(), "window=playertickets;size=600x480")

// Personal tickets for players
/datum/admin_help/proc/PlayerTicketPanel()
	var/list/dat = list("<html><head><meta http-equiv='Content-Type' content='text/html; charset=UTF-8'><title>Player Ticket</title></head>")
	var/ref_src = "[REF(src)]"
	dat += "<b>State: "
	switch(state)
		if(AHELP_ACTIVE)
			dat += "<font color='red'>OPEN</font>"
		if(AHELP_RESOLVED)
			dat += "<font color='green'>RESOLVED</font>"
		if(AHELP_CLOSED)
			dat += "CLOSED"
		else
			dat += "UNKNOWN"
	dat += "</b>[FOURSPACES][PlayerTicketHref("Refresh", ref_src)]"
	dat += "<br><br>Opened at: [GAMETIMESTAMP("hh:mm:ss", closed_at)] (Approx [DisplayTimeText(world.time - opened_at)] ago)"
	if(closed_at)
		dat += "<br>Closed at: [GAMETIMESTAMP("hh:mm:ss", closed_at)] (Approx [DisplayTimeText(world.time - closed_at)] ago)"
	dat += "<br><br>"
	dat += "<br><b>Log:</b><br><br>"
	for(var/I in _interactions_user)
		dat += "[I]<br>"

	usr << browse(dat.Join(), "window=ahelp[id];size=620x480")
