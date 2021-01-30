// The admin_help.dm in this focus is mostly for the datum, this for more general verbs and procs

// Show the user ticket panel
/client/verb/viewtickets()
	set category = "Admin"
	set name = "View Personal Tickets"

	GLOB.ahelp_tickets.BrowserPlayerTickets()

