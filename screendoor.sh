#!/bin/bash


# Latest version of this software is available for download at:  http://github.com/write2david/screendoor/blob/master/screendoor.sh
#      Or for easy wget'ing:  www.tinyurl.com/get-screendoor
#
# Git Access:  git://github.com/write2david/screendoor.git
#
# Git Web Access: http://github.com/write2david/screendoor
#
# README (including installation instructions) for this software is available on Git Web Access site (above)...
#      ...and also at:  http://github.com/write2david/screendoor/raw/master/README



# Great Bash help / howto page:
# http://www.panix.com/~elflord/unix/bash-tute.html



# OVERVIEW OF HOW SCREENDOOR WORKS:
#
# When this script is called by shell login files (which includes every time screen starts), then there are two scenarios:
# (Option #1) If the parent process of this script is "screen" then we just connect to the already-created window.
#
# (Option #2) Otherwise, we create a Screen window, which creates a shell within that window -- a shell which will then call Screendoor again, and so this second instance of Screendoor just dumps to that new shell (Option #1, above).
#       Option #2 looks like:
#             User Login ->
#             Shell startup script ->
#             Run Screendoor (setup Screendoor session and two windows: Cornerstone and new window) ->
#             That new window prompts a new shell ->
#             Shell startup script (which prompts running this file, now going down to this section) ->
#             Screendoor connects to new window.
#
#
# NOTES
#
# Often, sleep commands (to delay 1/5 of a second) are inserted because the screen commands often "return" *immediately* AND there is another screen command immediately following which depends on the the first sleep command *completing*.  So, we want to make sure it completes (even a screen command as simple as setting a title can return immediately, and if the next command references a window with that title, that next command may not work because the "set title" command returned immediately without having yet set the title).




# FIRST, TEST FOR INTERACTIVE SHELL
#      ...AND EXIT SCREENDOOR IF NOT INTERACTIVE.
#
#    -- No need for screen if the user won't be interacting with the shell.
#    -- This also prevents screen from running when it would confuse another program (like scp) that doesn't use an interactive shell.
#    -- For more info, see:
#            http://theory.uwinnipeg.ca/localfiles/infofiles/bash/bashref_54.html)
#            http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_01_02.html#sect_01_02_02_03
#
# NOTE: When running screendoor.sh directly from the command line, the test for interactive shell and for the $SHELL variable always test "non-interactive" and ______   because it is being run as a script.  When screendoor.sh is run as being sourced from .bash_login (for example) then the interactive shell tests positive.


         if [[ $- != *i* ]] ; then
         # Shell is non-interactive.  Be done now!
         return
         # use 'return', not 'exit', since we just want to prevent execution of further code in this script, not exit the non-interactive shell and thus mess up the program that needed it / spawned it   (like scp or WinSCP). 
         fi
         # So now continue if the shell is interactive... 



# SECOND, CHECK FOR DUMB TERMINAL LOGIN
#      ...AND EXIT SCREENDOOR IF IT'S A DUMB-Y
#
# This checks to see if something like WinSCP is logging in.
# WinSCP definitely doesn't like it when GNU Screen runs while WinSCP is trying to log in.
#
case ${TERM} in
        dumb)
	return     ;;
	esac




# THIRD, CLEAR OUT OLD, DEAD SCREEN SESSIONS
#      ...like those that were leftover when the computer unexpectantly loses power.
#      Screendoor (well, GNU Screen itself, actually) won't start right if a dead, old session is leftover with the same session name.
screen -wipe > /dev/null 



# FOURTH, START MAIN SCREEN SESSION, NAMED "Screendoor"
#        ...if not already started.
#
	if [[ "`screen -ls | grep Screendoor`" != *Screendoor* ]]; then
   # That is, if there is no screen session named "Screendoor", then...
	# we will setup our main screen session (named "Screendoor") with "Cornerstone" window
	#
	#
	# We don't want the "Cornerstone" window to be a shell, since that would trigger the shell login files (like .bashrc and .bash_login), which would then call Screendoor again. So, when setting up the initial window, run "sleep" (instead of specifying nothing, because specifying nothing = "run bash".
	# 
	#
	# First, start session "Screendoor."
	# From the GNU Screen manpage: "-d -m" means "Start screen in 'detached' mode. This creates a new session but doesn't attach to  it.  This  is  useful for  system startup scripts."
	
echo 'Starting GNU Screen session named "Screendoor"...'
# Create new session named "Screendoor" with the first window titled "NewWindow"
	# It will be renamed to "Cornerstone" in the line afterward, but we don't want to immediately name it that way
		# because then it will be the default name for new windows, so that if we later do "Ctrl-A c" to create a new window, it will create it named "Cornerstone".  We don't want all new windows to be named "Cornerstone," only just this fist one.
	screen -S Screendoor -d -m -t NewWindow sleep 99999999999d
	
# Rename the window title...	
	sleep 0.2 && screen -S Screendoor -p0 -X title Cornerstone
	
# Write a message on the Cornerstone window using the "stuff" screen command
# \015 is octal ASCII code for carriage return.
	# Need to use 'eval' so that the text \015 isn't printed literally
	# \015 is also referenced in the INPUT TRANSLATION section of the screen man page
	sleep 0.2 && screen -S Screendoor -p Cornerstone -X eval 'stuff "   [ This window holds open the central Screendoor session. ] \015"'
	
# Set the session as "multiuser"
	sleep 0.2 && screen -S Screendoor -X multiuser on
	
# Make this first window as "read-only" (requires the "multiuser" setting of the previous line)
	sleep 0.2 && screen -S Screendoor -X aclchg \* -w 0

fi



# FIFTH, SETUP AN IF/ELSE SCENARIO...
#	IF this script was called by GNU Screen, then everything is setup already. Basically just dump to a command line.
#	ELSE this script was not called by GNU Screen, then setup a new Screen window.



# We want to start screen on all shell prompts, not just all logins.
# This way we can connect to even xterm tabs in XFCE.
# But if we start screen on all  prompts, then we'll run into this problem:
#     ...when screen starts, it auto-starts a prompt (of course) and so
#     this prompt will then auto-start screen according to this script.
# So, we want to prevent screen from starting if the prompt
#       was itself started by screen.
# And then, after screen is closed, there's auto-logout from the prompt,
#       so that you don't have to type "exit" again.
# 
# This next line finds out if the command (-o command) that initiated
#       the current bash session (-p $PPID) was "screen."   If it IS screen,
#       then name the window and dump to a prompt.  If it's not, then start
#       screen; screen will then spawn a shell which will call this file again, which will determine that
#       screen IS now the command that started bash, and so it won't load
#       Screen again.
# Inspired by:
#       http://forums.whirlpool.net.au/forum-replies-archive.cfm/324661.html





#  This next line will check to see if parent process equals (note the colon) "SCREEN"
#  If it does, that means that screen has called this file via the shell login files,
#		or directly by screen via "Ctrl-A c"



if expr "$(ps --no-headers -o command -p $PPID)" : SCREEN >/dev/null



then


	# If the new screen window was created with a new SSH/login screen or new xterm tab,
		# then it will have created a window that is already named.
	# But if the new screen window was created with "Ctrl-A c" then it will be named
		# the default "NewWindow".
	# Either way, rename it to the date and time.  We don't need the milliseconds anymore
		# since we don't need an absolutely unique window name.

	screen -X title "`date +%m/%d\ @\ %I:%M%p`"

	echo 'Starting a new window in GNU Screen...'
	echo


	# What this optional section does: grab the first three logins (most recent)
	# produced by the "last" command. The first one is the current one,
	# the second one is also the current one (since logging in starts 
	# bash (next-most-recent login entry) and bash starts screen 
	# (most-recent login entry)). So, display the third one.
	#
	# Any recent reboot results in extra lines to the output of the
	# "last" command. So, we need to get rid of the lines that say
	# "reboot" or else the first time you login after a reboot it may
	# list "reboot" as the "Last login"

	#echo "Last login:"  &&  last | grep -v reboot | head -n 3 | tail -n 1  &&  echo
	#echo "Current/active logins:"  &&  last | grep still | sed 's/still\ logged\ in//g'  &&  echo 
	

	MAIL=$HOME/.maildir
	export MAIL
	
	
	# Display the Message of the Day by echoing the content of /etc/motd
	echo "MOTD: `cat /etc/motd`"  &&  echo 

	
	# Display mail headers
	echo "Your current mail..."  &&  mail -H  &&  echo


	# If the ~/screen.xDISPLAY.txt exists, use it.
		# It may not exist if this file is called w/"Ctrl-A c"
		# See note below, which explains the creation of ~/screen.xDISPLAY.txt file. 
	if [ -f ~/screen.xDISPLAY.txt ]
		then
		export DISPLAY=`cat ~/screen.xDISPLAY.txt`
		#echo "(Your X-windows \$DISPLAY variable now is...  $DISPLAY)"
		fi
		
	
	# A test: Try uncommenting next line, and then run Xming and then...
		# See if xMing runs Terminal/Firefox/Gramps.
		# Try using xMing to run Terminal, open a new tab in Terminal and run mousepad
		# Do "Ctrl-A c" in Terminal and run mousepad.
		# If all is good during this time the next line is uncommented, then leave it uncommented.
	#rm -f ~/screen.xDISPLAY.txt


	# Screendoor is written in bash, so at this point we are leaving the user in a bash shell.  Bash may not be the user's default login shell.  So, replace (using exec) the bash session (we still stay inside this screen window) with the default login shell.

	# Need to add test for default login shell, for now we just assume zsh:
	exec zsh

	# Work on detecting user's default login shell, and executing that.
	# A srart:
	# grep -e `id -un`:x:`id -u`:`id -g` /etc/passwd
	# Even better, because the above assumes shadow passwords ("x") and maybe not everyone has them:
	# grep -e `id -un` /etc/passwd | grep `id -u`:`id -g`

	# Use the above and then pull out (suing awk?) the last field of the line, which is the path to the default shell


	# Here is some related input from the /etc/screenrc file:
		# shell:  Default process started in screen's windows.
		# Makes it possible to use a different shell inside screen
		# than is set as the default login shell.
		# If begins with a '-' character, the shell will be started as a login shell.
		# shell                 zsh
		# shell                 bash
		# shell                 ksh
		#        shell -$SHELL



else


# NOW CREATE NEW SCREEN WINDOW IF THIS SCRIPT IS CALLED BY ANYTHING OTHER THAN "Ctrl-A c"

# Got a problem where doing X-forwarding (like X-ming or over SSH) doesn't result in the new screen window having
# the $DISPLAY property set (when "X-forwarding" is enabled in a SSH connection, SSH itself sets $DISPLAY in the initial
# bash shell, but when that bash shell creates/connects to a new screen window,
# the shell in that new screen window doesn't have the $DISPLAY variable set).
# So, while we are still in the initial shell, we will write the $DISPLAY variable to a file, and
# then read it from within the new window's shell.
# Use "-n" (makes echo remove the linefeed/newline/carriage-return) on the "echo" because you will be reading this file later in order to name a screen window, and you don't want to try to name a window based on two lines instead of one.

echo -n "`echo $DISPLAY`" > ~/screen.xDISPLAY.txt


# In case two logins happen during the same minute or second, milliseconds is also used in naming the windows, in order to make sure each window name is unique (needed for the section of code that writes/recalls the window title).  Later, the milliseconds part of the window title will be removed, after the uniqueness becomes unneeded.

	# Dump the date/time to a file -- it will be used as the name of the screen window.
	# Use milliseconds to ensure unique name since we will need to specify a unique name for subsequent commands, especially if this script is executed twice in the same second. 
	echo -n "`date +%m/%d\ @\ %I:%M%p\ \ \ \(%N\)`" > ~/screen.uniqueID.txt
	#
	# Use "-X" to send a command which then immediately returns.  The command is: on the central "Screendoor" session, create a new window named [content of screen.uniqueID.txt]:
	screen -S Screendoor -X screen -t "`cat ~/screen.uniqueID.txt`"
	#
	# Sleep to make sure everything catches up:
	sleep 0.2
	#
	# Creating the new window caused all the other Screen instances to move ahead to the next window, so move them all back:
	screen -S Screendoor -X prev
	#
	# Sleep to make sure everything catches up:
	sleep 0.2
	#
	# Use "-x" to attached to the window named [content of screen.uniqueID.txt]:
	# Remember that though we are attaching here, we have already created the new window, which itself has already called this script and goes through the "Creating new GNU Screen window" section near the top.
	# Now we actually connect to the new window.  We can add "exec" so that this bash script dies and we are just left with the new window.
	exec screen -S Screendoor -x -p "`cat ~/screen.uniqueID.txt && rm -f ~/screen.uniqueID.txt`"

	# Regarding the preceding line: We are now connected to the new Screen window, so we don't need the file that tells us how to name that window.
        # We're putting the "rm" command at the last possible place.  Doing so earlier would create problems since it is needed later (that is, here).  Doing so later means it wouldn't happen until this part returns (which it doesn't yet, see section below about "above command is held up at...").  Doing so in top section means it would be deleted when new window is created (which sounds good) but it's still actually needed when this section *attaches* to the new window.
	        # Use "-f" on rm b/c using > /dev/null doesn't work
		     # Kill output of the rm command since if the window was created with "Ctrl-A c" then there is not going to be a screen.uniqueID.txt file, and any output would mess up our specification of the window name.
fi



#seems like sometimes another "exit" is needed:
exit






# PROBLEM/WORKAROUND: the problem with running screen plainly that
# 	when you then run "startx"  you are
# running it w/in screen, and so then when you run "xterm" in X-windows it
# won't be
# able to produce new screen sessions (it returns immediately for some reason).
# Since it's running from w/in screen, then the "screen" command doesn't create
# a new session, it just creates a new window); all you can do is
# specify a screen session to connect to. To get around this, specify that the
# "screen" command MUST create a new session (using  "-m"), even if running w/in# a screen session.
