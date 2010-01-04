#!/bin/bash
#
#
# Latest version is available for download at:  http://github.com/write2david/screendoor/blob/master/screendoor.sh
#
# Git: http://github.com/write2david/screendoor
#
# Why? http://tech.thedesignhut.net/gnu-screen
#
#
#
# Great Bash help / howto page:
# http://www.panix.com/~elflord/unix/bash-tute.html
#
# NOTE:
# This file gets run every time a shell starts (which includes every time screen starts)
# So, if screen is already running (that is, if the parent process of this script is "screen" -- the line above tests this), then we just connect to the already-created window
# Login -> shell startup script -> run screendoor (setup Cornerstone and new window) -> [start screen] -> prompts new shell -> shell startup script (which prompts running this file, now going down to this section) -> screendoor connects to new window

# When running screendoor.sh directly from the command line, the test for interactive shell and for the $SHELL variable always test "non-interactive" and ______   because it is being run as a script.  When screendoor.sh is run as being sourced from .bash_login (for example) then the interactive shell tests positive.
#
#
# First, test for an interactive shell, and exit if not interactive.
#    -- No need for screen if the user won't be interacting with the shell.
#    -- This also prevents screen from running when it would confuse another program (like scp) that doesn't use an interactive shell.
#    -- For more info, see:
#            http://theory.uwinnipeg.ca/localfiles/infofiles/bash/bashref_54.html)
#            http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_01_02.html#sect_01_02_02_03

         if [[ $- != *i* ]] ; then
         # Shell is non-interactive.  Be done now!
         return   # use 'return', not 'exit', since we just want to prevent execution of further code in this script, not exit the non-interactive shell and thus mess up the program that needed it / spawned it 
         fi

# This checks to see if something like WinSCP is logging in.  WinSCP definitely doesn't like it when SCREEN runs while it's logging in.
case ${TERM} in
        dumb)
	return     ;;
	esac
#
#
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
#       then let the user know screen is running.  If it's not, then start
#       screen; screen will then reload this file, which will determine that
#       screen IS now the command that started bash, and so it won't load
#       Screen again.
# Inspired by:
#       http://forums.whirlpool.net.au/forum-replies-archive.cfm/324661.html
#
#
#  This next line will check to see if parent process equals (see the colon) "SCREEN"
#  If it does, that means that screen has called this file via the shell login files,
#		or via "Ctrl-A c"
#
if expr "$(ps --no-headers -o command -p $PPID)" : SCREEN >/dev/null
then
	# If the new screen window was created with a new SSH/login screen or new xterm tab, then it will have created
		# a window that is already properly-named (bottom part of file does this, we have cycled through it already).
	# If the new screen window was created with "Ctrl-A c" then it will be named the default (see below) "New Window"
		# in which case we need to rename it here:
   screen -X at NewWindow title "`date +%m/%d\ @\ %I:%M%p\ \ \ \ \ \(%N\)`"
# We are now in the new (properly-named) screen window, so we don't need the file that tells us how to name the window.  Kill output of the rm command since if created with "Ctrl-A c" then there is not going to be a screen.uniqueID.txt file
        rm -f ~/screen.uniqueID.txt
	# Use "-f" on rm b/c using > /dev/null doesn't work
	#
	clear # does this line do anything?
	echo 'Starting GNU Screen new window...'
	# Can do this? rm ~/screen.xDISPLAY.txt
	# Try it, then run xMing, and if it works, then do the rm line
	#
	#echo "Last login:"
	# What this next line does: grab the first three logins (most recent)
	# produced by the "last" command. The first one is the current one,
	# the second one is also the current one (since logging in starts 
	# bash (next-most-recent login entry) and bash starts screen 
	# (most-recent login entry)). So, display the third one.
	#
	# Any recent reboot results in extra lines to the output of the
	# "last" command. So, we need to get rid of the lines that say
	# "reboot" or else the first time you login after a reboot it may
	# list "reboot" as the "Last login"
	#last | grep -v reboot | head -n 3 | tail -n 1	
	#echo 
	#echo "Current/active logins:"
	#last | grep still | sed 's/still\ logged\ in//g'
	#echo ""
	MAIL=$HOME/.maildir
	export MAIL
	#
	echo ""
	# Display the Message of the Day by echo'ing the result of evaluating the command to "cat" /etc/motd
	echo "MOTD: `cat /etc/motd`"
	echo ""
	echo "Your current mail..."
	mail -H
	#echo "Message from screendoor.sh: You are w/in GNU Screen.   (Shift-PgUp for SSH errors)"
	# See note below, which mentions these lines.
	export DISPLAY=`cat ~/screen.xDISPLAY.txt`
	#echo "      (Your x-windows \$DISPLAY now is...  $DISPLAY)"
	# Ended up commenting out the next line b/c in an XTERM, when using "Ctrl-A c" to create screen windows there was no ~/screen.xDISPLAY.txt files so the DISPLAY variable was not set in that session, not good for starting Xwindows applications.  So, no removal of the file, it is overwritten whenever needed, and new windows can just use whatever the last variable was set to in this file.
	#rm -f ~/screen.xDISPLAY.txt
	zsh && exit
else
#
#
#
# HERE BEGINS THE MAIN WORK OF THIS SCRIPT
#
# Clear old screen sessions (like those that were leftover when the computer was last shutdown)
	#  (Do not do "exec" before this "screen" command since it will cancel the rest of this script)
screen -wipe > /dev/null 
#
#
#
# start main session if not already started:
#(Do not do "exec" before this next"screen" command since for some reason it won't do anything.)
	if [[ "`screen -ls | grep main`" != *main* ]]; then    #if there is no screen session named "main", then...
	#
	# Setup main screen session with "Cornerstone" window
	# We don't want the "Cornerstone" window to be a bash shell, since that would trigger .bashrc and .bash_login.  
	# So, when setting up the initial session, run sleep (instead of specifying nothing)
	#(specifying nothing = run bash).
	# 
	#  Big multi-line command, using "\" to do multi-line and "&&" to string commands together. 
	#
	#  Start session "main."  From screen man page for the command "-d -m": "Start screen in 'detached' mode. This creates a new session but doesn't attach to  it.  This  is  useful for  system startup scripts."  Name the first window "Cornerstone."
	echo 'Starting GNU Screen session "main"...'
	# Create new session anmed "main" with the first window titled "NewWindow"
		# It will be renamed to "Cornerstone" in the line afterward, but we don't want to immediate name it that way
			# because then if we do "Ctrl-A c" to create a new window, it will create it named "Cornerstone" (which would be the default)
	screen -S main -d -m -t NewWindow sleep 99999999999d && \
	# Rename the window title...	
	screen -S main -p0 -X title Cornerstone && \
	# Give a message using stuff (015 = newline?):
	sleep 0.2 && screen -S main -p0 -X eval 'stuff "This a read-only window in order to hold open this main screen session. \015"'&& \
	# Set the session as "multiuser"
	sleep 0.2 && screen -S main -X multiuser on && \
	# Make this window read-only
	sleep 0.2 && screen -S main -X aclchg \* -w 0
	fi
#
#
#
#
# Got a problem where doing X-forwarding (like X-ming or over SSH) doesn't result in the new screen window having the $DISPLAY property set (it's in the initial bash shell, but when that bash shell connects to a new screen window, the  shell in that new screen window doesn't have the $DISPLAY variable set).  So, while we are still in the initial  shell, we will write the $DISPLAY variable to a file, and then read it from within the new window's shell.
# Note that the reason this exists is that $DISPLAY is automatically set when you login over SSH with X-forwarding enabled.
echo -n "`echo $DISPLAY`" > ~/screen.xDISPLAY.txt
#
#
# Use "-n" on the "echo" because you will be reading this file later in the command to name a screen window, and you don't want to try to name a window based on two lines instead of one.
#
#
#  Big multi-line command, using "\" to do multi-line and "&&" to string commands together.
	# dump the date/time to a file, will be used to name the screen window.
	echo -n "`date +%m/%d\ @\ %I:%M%p\ \ \ \(%N\)`" > ~/screen.uniqueID.txt && \
	# Use "-X" to send a command and then immediately return.  The command is: create a new window on "main" session named [content from file]:
	screen -S main -X screen -t "`cat ~/screen.uniqueID.txt`" && \
	# sleep to make sure everything catches up:
	sleep 0.2 && \
	# Creating the new window caused all the other screens to move ahead one, so move them all back:
	screen -S main -X prev && \
	# Sleep to make sure everything catches up:
	sleep 0.2 && \
	# Use "-x" to attached to the window named [content from file]:
	screen -S main -x -p "`cat ~/screen.uniqueID.txt`" && \

	# Exit the shell that called this script.  Now only the new screen window (and the shell that IT prompted) are running (?)
	exit
#	The above command is held up at the step of connecting to the new window (which creates a new shell).  When it finishes (user types "exit") then the "&& exit" comes in, saying clear the screen and exit out of screendoor
#
#
# PROBLEM/WORKAROUND: the problem with running screen plainly that
# 	when you then run "startx"  you are
# running it w/in screen, and so then when you run "xterm" in X-windows it
# won't be
# able to produce new screen sessions (it returns immediately for some reason).
# Since it's running from w/in screen, then the "screen" command doesn't create
# a new session, it just creates a new window); all you can do is
# specify a screen session to connect to. To get around this, specify that the
# "screen" command MUST create a new session (using  "-m"), even if running w/in# a screen session.
#
fi
#seems like sometimes another "exit" is needed:
exit
