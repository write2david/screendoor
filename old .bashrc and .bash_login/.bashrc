#!/bin/bash
# Show current directory or current running program in X-windows terminal window
# From http://mg.pov.lt/blog/bash-prompt.html  // added this to enable screen shell:   |screen*
# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*|screen*)
    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'

    # Show the currently running command in the terminal title:
    # http://www.davidpashley.com/articles/xterm-titles-with-bash.html
    show_command_in_title_bar()
    {
        case "$BASH_COMMAND" in
            *\033]0*)
                # The command is trying to set the title bar as well;
                # this is most likely the execution of $PROMPT_COMMAND.
                # In any case nested escapes confuse the terminal, so don't
                # output them.
                ;;
            *)
                echo -ne "\033]0;${USER}@${HOSTNAME}: ${BASH_COMMAND}\007"
                ;;
        esac
    }
    trap show_command_in_title_bar DEBUG
    ;;
*)
    ;;
esac
#
#
#
#
# This file is for non-login shells!   (like new tabs in the Terminal window in XFCE)
#
#
# SCP will not work if bashrc runs.
# http://www.openssh.com/faq.html#2.9
# (linked to from tinyurl.com/bashrc-ssh-issue )
# So, terminate this file if this is a non-interactive session.
# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.   (taken from /etc/bash/bashrc)
	if [[ $- != *i* ]] ; then
	        # Shell is non-interactive.  Be done now!
	        return
		fi
# If screen is started normally then it will load bash which will
#	load .bash_login, which shows the MOTD, etc.
#  But .bashrc is usually run when opening a next xterm tab,
#	so no need for all that.
# So, we need to start screen AND tell it to run the bash command
#	with "--noprofile" so that it won't run .bash_login.
#
#
# This checks to see if something like WinSCP is logging in.  WinSCP definitely doesn't like it when SCREEN runs while it's logging in.
case ${TERM} in
        dumb)
	return     ;;
	esac
#
# Start screen
# We want to start screen on all bash prompts, not just all logins.
# This way we can connect to even xterm tabs in XFCE.
# But if we start screen on all bash prompts, then we'll run into this problem:
#     ...when screen starts, it auto-starts a bash prompt (of course) and so
#     this bash prompt will then auto-start screen according to this script.
# So, we want to prevent screen from starting if the bash prompt
#	was itself started by screen
# And then, after screen is closed, there's auto-logout from the bash prompt,
#       so that you don't have to type "exit" again.
#
# This next line finds out if the command (-o command) that initiated
#	the current bash session (-p $PPID) was "screen."   If it IS screen,
#	then let the user know screen is running.  If it's not, then start
#	screen; screen will then reload this file, which will determine that
#	screen IS now the command that started bash, and so it won't load
#	Screen again.
# Inspired by:
#	http://forums.whirlpool.net.au/forum-replies-archive.cfm/324661.html
#
if expr "$(ps --no-headers -o command -p $PPID)" : SCREEN >/dev/null
then
	# Seems like this part of "then"  (before "else") is never called anymore?
	screen -X at NewWindow title "`date +%m/%d\ @\ %I:%M%p\ \ \ \ \ \(%N\)`"
	clear
        echo ""
        MAIL=$HOME/.maildir
	export MAIL
	cat /etc/motd
        echo ""
        echo "Last login:"
        # What this next line does: grab the first three logins (most recent)
        # produced by the "last" command. The first one is the current one,
        # the second one is also the current one (since logging in starts
        # bash (next-most-recent login entry) and bash starts screen
        # (most-recent login entry)). So, display the third one.
        # Any recent reboot results in extra lines to the output of the
        # "last" command. So, we need to get rid of the lines that say
        # "reboot" or else the first time you login after a reboot it may
        # list "reboot" as the "Last login"
        last | grep -v reboot | head -n 3 | tail -n 1
        echo
        echo "Current/active logins:"
        last | grep still | sed 's/still\ logged\ in//g'
        echo ""
	echo "Message from .bashrc: You are w/in GNU Screen."
	echo ""
else

	echo "Now starting GNU Screen from .bashrc..."
#
#
#
# Got a problem where doing X-forwarding (like X-ming or over SSH) doesn't result in the new screen window having the $DISPLAY property set (it's in the initial bash shell, but when that bash shell connects to a new screen window, the bash shell in that new screen window doesn't have the $DISPLAY variable set).  So, while we are still in the initial bash shell, we will write the $DISPLAY variable to a file, and then read it from within the new window's bash shell.
# Note that the reason this exists is that $DISPLAY is automatically set when you login over SSH with X-forwarding enabled.   .bash_login uses this next line:
echo -n "`echo $DISPLAY`" > ~/screen.xDISPLAY.txt
#
#
#
# PROBLEM/WORKAOURND: the problem with running screen plainly that when you then run "startx"  you are
# running it w/in screen, and so when you run "xterm" in X-windows it won't be
# able to produce new screen sessions (returns immediately for some reason.
# Since it's running from w/in screen, then the "screen" command doesn't create
# a new session, it just creates a new window); all you can do is
# specify a screen session to connect to. To get around this, specify that the
# "screen" command MUST create a new session (using  "-m"), even if running w/in a screen
# session. 
#
# This next line makes sure screen won't run .bash_profile as it likes to do
# Also, this is different than using the semi colon as .bash_profile does...
#	Because with the semicolon, Xming won't stay connected; it logs in, runs screen, and immediately exits.  So, whatever program Xming was supposed to run (like Terminal or Firefox or GRAMPS), it never stays up.
#
#
#
# Use "-n" on the "echo" because you will be reading this file later in the commadn to name a screen window, and you don't want to try to name a window based on two lines instead of one.
# Added in sleep commands b/c otherwise if screen returns too soon, sometimes the next command runs b4 screen is ready, then screen freezes up and you can get to a prompt only if you press Ctrl-Z.
#
echo -n "`date +%m/%d\ @\ %I:%M%p\ \ \ \(%N\)`" > ~/screen.uniqueID.txt && screen -S main -X screen -t "`cat ~/screen.uniqueID.txt`" && sleep 0.2 && screen -S main -X prev && sleep 0.2 && screen -S main -x -p "`cat ~/screen.uniqueID.txt`" && exit
#
fi
