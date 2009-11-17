#!/bin/bash
#  From http://www.mail-archive.com/screen-users@gnu.org/msg02683.html

#####
__c=""
__c=" Create and attach to a new GNU Screen session, or co-operatively join a"
__c=" session that already exists, automatically, as each new BASH instance"
__c=" starts. Screen runs in the BASH instance as a normal process, as if the"
__c=" user had typed 'screen ...' at the command prompt. BASH exits upon"
__c=" detaching from or terminating the Screen session."
__c=""
__c=" Prompts the user (with a timeout) to cancel joining Screen, and also to"
__c=" cancel exiting BASH afterwards. In either case, the user drops into the"
__c=" parent BASH instance, in the standard fashion."
__c=""
__c=" Ignores (does not try to join Screen from) any BASH instances that:"
__c=""
__c="  - are non-interactive, OR"
__c="  - are already running under a local Screen session, OR"
__c="  - in which the env var __PORCH_auto_disable equals 'false'."
__c=""
__c=" Choosing to cancel joining Screen (when prompted) will export"
__c=" __PORCH_auto_disable=false for the current and subprocesses, which"
__c=" disables this functionality, entirely."
__c=""


#####
__c=""
__c=" Some convenience functions."
__c=""

function print_to_cancel_join () {
    echo -e -n "\n" \
"[[ Auto-joining GNU Screen session '${1}' in ${2} second(s). Or, PRESS ANY " \
"KEY to cancel and enter BASH session, normally. ]]\n\n" 1>&2
}

function print_join_cancelled () {
    echo -e -n "\n" \
"[[ Cancelled GNU Screen auto-joining on user command. Entering BASH " \
"session, from which sub-shells will NOT auto-join Screen. Run 'export " \
"__PORCH_auto_disable=false', to re-enable this functionality. ]]\n\n" 1>&2
}

function print_to_cancel_exit () {
    echo -e -n "\n" \
"[[ Finished GNU Screen session ${1} (status = ${3}). Exiting shell in ${2} " \
"second(s). Or PRESS ANY KEY to cancel and remain in a normal BASH session. " \
"]]\n\n" 1>&2
}


#####
__c=""
__c=" Set default values for some runtime and session parameters. To"
__c=" override a value, export it from the calling shell, or set it on the"
__c=" command line calling this script.)"
__c=""

__c=" Timeout, in seconds, for the cancel prompts."
export __PORCH_cancel_timeout="${__PORCH_cancel_timeout:=1}"
__c=" Prefix of the Screen session name to join. (Host & user are prepended.)"
export __PORCH_session_name_prefix="${__PORCH_session_name_prefix:=__PORCH}"
__c=" Hostame of the system running the screen session (not the display)."
export __PORCH_session_hostname="${HOSTNAME}"
__c=" Username of the account running the screen session (not the display)."
export __PORCH_session_username="${USER}"
__c=" Enable/disable automatically joining Screen."
export __PORCH_auto_disable="${__PORCH_auto_disable:=false}"
__c=" Extra command-line options for Screen."
export __PORCH_screen_options="${__PORCH_screen_options:=-q}"
__c=" Screen's hardstatus line format."
export __PORCH_screen_hardstatus_fmt="${__PORCH_screen_hardstatus_fmt:=[SCREEN %t%?] %h }"
__c=" Screen's hardstatus line placement."
export __PORCH_screen_hardstatus_loc="${__PORCH_screen_hardstatus_loc:=alwayslastline}"
__c=" Screen's session name."
export __PORCH_screen_session_name="${__PORCH_session_name_prefix}:${__PORCH_session_username}@${__PORCH_session_hostname}"
__c=" Screen's window name."
export __PORCH_screen_window_name="$(date +%Y%m%d_%H%M%S_%N)"


#####
__c=""
__c=" Detect the environment of the current shell. All flags are inheritable"
__c=" by subprocesses. If this BASH instance isn't auto-joined to Screen, no"
__c=" subshell of this instance will auto-join, unless manually set to join."
__c=""

__c=" If already in nested in two (or more) Screen sessions, we shouldn't nest"
__c=" any further. (One level of nesting is permitted, for remote vs. local.)"
export __PORCH_is_session_nested="${__PORCH_is_session_nested:=false}"

__c=" If already in a Screen session, we shouldn't nest, unless an SSH client"
__c=" invoked the shell instance."
export __PORCH_is_session_inscreen="${__PORCH_is_session_inscreen:=false}"
expr match "${TERM}" "\(screen\)" >/dev/null && export __PORCH_is_session_inscreen="true"

__c=" See above, re: SSH clients."
export __PORCH_is_session_sshclient="${__PORCH_is_session_sshclient:=false}"
[ "${SSH_CLIENT}" != "" ] && export __PORCH_is_session_sshclient="true"


####
__c=""
__c=" Determine whether we should join a Screen session or enter the BASH"
__c=" instance, based on the current shell environment that was detected."
__c=""

is_autojoin="true"
if ! echo ${-} | grep i &>/dev/null; then
    __c=" Not checking to auto-join Screen: Non-interactive BASH instance."
    is_autojoin="false"
else
    __c=" Checking to auto-join Screen: Interactive BASH instance."
fi

if ${__PORCH_is_session_inscreen}; then
    __c=" Add the Screen session name to the hardstatus."
    PROMPT_COMMAND="$(echo $PROMPT_COMMAND | sed -r -e 's/\\033_/\\033_${__PORCH_screen_session_name##*:} ] /')"

    if ${__PORCH_is_session_sshclient}; then
        if ${__PORCH_is_session_nested}; then
            __c=" Not auto-joining Screen: Nested in multiple Screen sessions."
            is_autojoin="false"
        else
	        __c=" Auto-joining Screen: In Screen session, but SSH client."
	        __c=" Prevent sub-shells from auto-joining Screen."
	        export __PORCH_is_session_nested="true"; fi
    else
        __c=" Not auto-joining Screen: In Screen session."
        is_autojoin="false"; fi

else if ${__PORCH_is_session_sshclient}; then
    	__c=" Auto-joining Screen: SSH client."
    else
        __c=" Auto-joining Screen: Normal BASH instance."; fi; fi

if ${__PORCH_auto_disable}; then
    __c=" Not auto-joining Screen: Disabled by __PORCH_auto_disable env var."
    is_autojoin="false"; fi


#####
__c=""
__c=" If so directed, auto-join a Screen session."
__c=""

if ${is_autojoin}; then

    __c=" Prompt the user to cancel auto-joining Screen."
    print_to_cancel_join ${__PORCH_screen_session_name} ${__PORCH_cancel_timeout}

    if read -s -n 1 -t ${__PORCH_cancel_timeout}; then
        print_join_cancelled

        __c=" Prevent sub-shells from auto-joining Screen."
        export __PORCH_auto_disable="true"
        __c=" User cancelled auto-joining Screen."
        is_autojoin="false"; fi

else
    __c=" Not auto-joining. Entering a normal BASH instance."; fi

if ${is_autojoin}; then

    __c=" Create a window in an existing Screen session. Fail if none exist."
    if ! /usr/bin/screen ${__PORCH_screen_options} -xRR -S "${__PORCH_screen_session_name}" -X eval "screen -t ${__PORCH_screen_window_name}" "other"; then

        __c=" None exist, yet, so create a new detached Screen session."
        if ! /usr/bin/screen ${__PORCH_screen_options} -dmS "${__PORCH_screen_session_name}" ${__PORCH_screen_options} -t ${__PORCH_screen_window_name}; then
            echo -e "ERROR: Could not create a new, detached Screen session (${?})." 1>&2; fi; fi

    __c=" Co-operatively re-attch to whatever session, existing or newly-created, on the new window we've just created."
    /usr/bin/screen ${__PORCH_screen_options} -xRR -S "${__PORCH_screen_session_name}" -p ${__PORCH_screen_window_name}
    screen_exit_status="${?}"
    if [ "${screen_exit_status}" != "0" ]; then
        echo -e "ERROR: Could not join the Screen session (${screen_exit_status})."; fi

    print_to_cancel_exit ${__PORCH_screen_session_name} ${__PORCH_cancel_timeout} ${screen_exit_status}

    if read -s -n 1 -t ${__PORCH_cancel_timeout}; then
        __c=" User cancelled auto-exiting the BASH instance."
    else
        __c=" Auto-exit the BASH instance."
        exit; fi; fi

#####
#####

