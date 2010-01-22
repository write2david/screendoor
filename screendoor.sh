#!/bin/bash


# Latest version is available for download at:  http://github.com/write2david/screendoor/blob/master/screendoor.sh
#
# Git: http://github.com/write2david/screendoor
#
# Why? http://tech.thedesignhut.net/gnu-screen



# Great Bash help / howto page:
# http://www.panix.com/~elflord/unix/bash-tute.html




# NOTE:
# This file gets run every time a shell starts (which includes every time screen starts)
# So, if screen is already running (that is, if the parent process of this script is "screen" -- the line above tests this), then we just connect to the already-created window
# Login -> shell startup script -> run screendoor (setup Cornerstone and new window) -> [start screen] -> prompts new shell -> shell startup script (which prompts running this file, now going down to this section) -> screendoor connects to new window
#
# When running screendoor.sh directly from the command line, the test for interactive shell and for the $SHELL variable always test "non-interactive" and ______   because it is being run as a script.  When screendoor.sh is run as being sourced from .bash_login (for example) then the interactive shell tests positive.



# FIRST, TEST FOR INTERACTIVE SHELL
#      ...AND EXIT IF NOT INTERACTIVE.
#
#    -- No need for screen if the user won't be interacting with the shell.
#    -- This also prevents screen from running when it would confuse another program (like scp) that doesn't use an interactive shell.
#    -- For more info, see:
#            http://theory.uwinnipeg.ca/localfiles/infofiles/bash/bashref_54.html)
#            http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_01_02.html#sect_01_02_02_03

         if [[ $- != *i* ]] ; then
         # Shell is non-interactive.  Be done now!
         return   # use 'return', not 'exit', since we just want to prevent execution of further code in this script, not exit the non-interactive shell and thus mess up the program that needed it / spawned it 
         fi



# SECOND, CHECK FOR DUMB TERMINAL LOGIN
#      ...AND EXIT IF NOT INTERACTIVE.
#
# This checks to see if something like WinSCP is logging in.  WinSCP definitely doesn't like it when SCREEN runs while it's logging in.
case ${TERM} in
        dumb)
	return     ;;
	esac




# THIRD, CLEAR OUT OLD, DEAD SCREEN SESSIONS
#      ...like those that were leftover when the computer was unexpectantly shutdown.
screen -wipe > /dev/null 



# FOURTH, START MAIN SCREEN SESSION (NAMED "screendoor")
#        ...if not already started.
#
	if [[ "`screen -ls | grep screendoor`" != *screendoor* ]]; then
		# That is, if there is no screen session named "screendoor", then...
	#
	#
	# Setup main screen session (named "screendoor") with "Cornerstone" window
	# We don't want the "Cornerstone" window to be a bash shell, since that would trigger .bashrc and .bash_login.  
	# So, when setting up the initial session, run sleep (instead of specifying nothing)
	#(specifying nothing = run bash).
	# 
	#  Big multi-line command, using "\" to do multi-line and "&&" to string commands together. 
	#
	#  Start session "screendoor."  From screen man page for the command "-d -m": "Start screen in 'detached' mode. This creates a new session but doesn't attach to  it.  This  is  useful for  system startup scripts."  Name the first window "Cornerstone."
	echo 'Starting GNU Screen session named "screendoor"...'
	# Create new session named "screendoor" with the first window titled "NewWindow"
		# It will be renamed to "Cornerstone" in the line afterward, but we don't want to immediate name it that way
			# because then if we do "Ctrl-A c" to create a new window, it will create it named "Cornerstone" (which would be the default)
	screen -S screendoor -d -m -t NewWindow sleep 99999999999d && \
	# Rename the window title...	
	screen -S screendoor -p0 -X title Cornerstone && \
	# Write s message on the Cornerstone window using the "stuff" screen command
	# \015 is octal ASCII code for carriage return.
		# Need to use 'eval' so that the text \015 isn't printed literally
		# \015 is also referenced in the INPUT TRANSLATION section of the screen man page
	sleep 0.2 && screen -S screendoor -p Cornerstone -X eval 'stuff "This is a read-only window (titled \"Cornerstone\") created in order to hold open this central screen session (named \"screendoor\"). \015"' && \
	# Set the session as "multiuser"
	sleep 0.2 && screen -S screendoor -X multiuser on && \
	# Make this first window as "read-only" (requires the "multiuser" setting of the previous line)
	sleep 0.2 && screen -S screendoor -X aclchg \* -w 0
	fi



# FIFTH, SETUP AN IF/ELSE SCENARIO...
#	IF this script was called by GNU Screen
#	ELSE this scrip was not called by GNU Screen



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
# So, while we are still in the initial  shell, we will write the $DISPLAY variable to a file, and
# then read it from within the new window's shell.
# Use "-n" (makes echo remove the linefeed/newline/carriage-return) on the "echo" because you will be reading this file later in order to name a screen window, and you don't want to try to name a window based on two lines instead of one.

echo -n "`echo $DISPLAY`" > ~/screen.xDISPLAY.txt




#  Big multi-line command, using "\" to do multi-line and "&&" to string commands together...
	#
	# dump the date/time to a file, will be used to name the screen window.
	echo -n "`date +%m/%d\ @\ %I:%M%p\ \ \ \(%N\)`" > ~/screen.uniqueID.txt && \
	#
	# Use "-X" to send a command and then immediately return.  The command is: create a new window on central "screendoor" session named [content from file]:
	screen -S screendoor -X screen -t "`cat ~/screen.uniqueID.txt`" && \
	#
	# sleep to make sure everything catches up:
	sleep 0.2 && \
	#
	# Creating the new window caused all the other screens to move ahead one, so move them all back:
	screen -S screendoor -X prev && \
	#
	# Sleep to make sure everything catches up:
	sleep 0.2 && \
	#
	# Use "-x" to attached to the window named [content from file]:
	# Remember that though we are attaching here, we are already initiated new window, which itself has called this script and goes through the "Creating new GNU Screen window" section near the top.
	# Now we actually connect to the new window.  We can add "exec" so that this bash script dies and we are just left with the new window.
	exec screen -S screendoor -x -p "`cat ~/screen.uniqueID.txt && rm -f ~/screen.uniqueID.txt`"
# We are now in the new (properly-named) screen window, so we don't need the file that tells us how to name the window.  Kill output of the rm command since if created with "Ctrl-A c" then there is not going to be a screen.uniqueID.txt file
        # We're putting the "rm" command at the last possible place.  Doing so earlier would mean that it would be needed later.  Doing so later means it wouldn't happen until this part returns (which it doesn't yet, see section below about "above command is held up at...").  Doing so in top section means it would be deleted when new window is created (which sounds good) but it's still actually needed when this section *attaches* to the new window.
	        # Use "-f" on rm b/c using > /dev/null doesn't work
		 
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
