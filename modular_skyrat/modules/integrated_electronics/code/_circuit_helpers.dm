/proc/strtohex(str)
	if(!istext(str)||!str)
		return
	var/r
	var/c
	for(var/i = 1 to length(str))
		c= text2ascii(str,i)
		r+= num2hex(c, 2)
	return r
