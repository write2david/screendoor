#!/bin/bash
#
#
#
# Start screen
#
# This line comes from .bashrc, probably not needed here, but just in case:
         if [[ $- != *i* ]] ; then
         # Shell is non-interactive.  Be done now!
         exit
         fi

# This checks to see if something like WinSCP is logging in.  WinSCP definitely doesn't like it when SCREEN runs while it's logging in.
case ${TERM} in
        dumb)
	exit     ;;
	esac
#
# We want to start screen on all bash prompts, not just all logins.
# This way we can connect to even xterm tabs in XFCE.
# But if we start screen on all bash prompts, then we'll run into this problem:
#     ...when screen starts, it auto-starts a bash prompt (of course) and so
#     this bash prompt will then auto-start screen according to this script.
# So, we want to prevent screen from starting if the bash prompt
#       was itself started by screen.
# And then, after screen is closed, there's auto-logout from the bash prompt,
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
if expr "$(ps --no-headers -o command -p $PPID)" : SCREEN >/dev/null
then
	screen -X at NewWindow title "`date +%m/%d\ @\ %I:%M%p\ \ \ \ \ \(%N\)`"
	clear
	#echo ""
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
	cat /etc/motd
	echo ""
	echo "Your current mail..."
	mail -H
	#echo "Message from .bash_login: You are w/in GNU Screen.   (Shift-PgUp for SSH errors)"
	# See note below, which mentions these lines.
	export DISPLAY=`cat ~/screen.xDISPLAY.txt`
	#echo "      (Your x-windows \$DISPLAY now is...  $DISPLAY)"
	# Ended up commenting out the next line b/c in an XTERM, when using "Ctrl-A c" to create screen windows there was no ~/screen.xDISPLAY.txt files so the DISPLAY variable was not set in that session, not good for starting Xwindows applications.  So, no removal of the file, it is overwritten whenever needed, and new windows can just use whatever the last variable was set to in this file.
	#rm -f ~/screen.xDISPLAY.txt
	echo ""
	zsh && exit
else
#
#
#
#
# Clear old screen sessions (like those that were leftover when the computer was last shutdown)
	#  Do not do "exec" before this "screen" command since for some reason it won't do anything.
screen -wipe > /dev/null 
#
#
echo "Starting GNU Screen from .bash_login..."
#
# start main session if not already:
#
	if [[ "`screen -ls | grep main`" != *main* ]]; then
	#  Do not do "exec" before this next"screen" command since for some reason it won't do anything.
	#
	# Setup main screen session with "Cornerstone" window
	# We don't want the "Cornerstone" window to be a bash shell, since that would trigger .bashrc and .bash_login.  
	# So, when setting up the initial session, run sleep instead of specifying nothing
	#(specifying nothing = run bash).
	#  
	# Adding in "sleep" between the screen commands to make sure screen has enough time to return, to prevent freeze-ups
	screen -S main -d -m -t NewWindow sleep 99999999999d && sleep 0.2 && screen -S main -p0 -X title Cornerstone && sleep 0.2 && screen -S main -p0 -X eval 'stuff "This a read-only window in order to hold open this main screen session. \015"' && sleep 0.2 && screen -S main -X multiuser on && sleep 0.2 && screen -S main -X aclchg \* -w 0
	fi
#
#
#
#
# Got a problem where doing X-forwarding (like X-ming or over SSH) doesn't result in the new screen window having the $DISPLAY property set (it's in the initial bash shell, but when that bash shell connects to a new screen window, the bash shell in that new screen window doesn't have the $DISPLAY variable set).  So, while we are still in the initial bash shell, we will write the $DISPLAY variable to a file, and then read it from within the new window's bash shell.
# Note that the reason this exists is that $DISPLAY is automatically set when you login over SSH with X-forwarding enabled.
echo -n "`echo $DISPLAY`" > ~/screen.xDISPLAY.txt
#
#
# Use "-n" on the "echo" because you will be reading this file later in the commadn to name a screen window, and you don't want to try to name a window based on two lines instead of one.
#
# ADDING IN SLEEP COMMANDS TO GIVE SCREEN A CHANCE TO CATCH UP WITHOUT FREEZING
echo -n "`date +%m/%d\ @\ %I:%M%p\ \ \ \(%N\)`" > ~/screen.uniqueID.txt && screen -S main -X screen -t "`cat ~/screen.uniqueID.txt`" && sleep 0.2 && screen -S main -X prev && sleep 0.2 && screen -S main -x -p "`cat ~/screen.uniqueID.txt`" && clear && exit
# Above line does this: put the date in a file, create a new screen window with a name based on the date in the file, creating the new window pushes all the instances of screen to the next window so bring them all back to the previous, then connect to the new screen window we just made.
#
# Below this is all OLD:
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
