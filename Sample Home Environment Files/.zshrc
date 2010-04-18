# Latest version available for download at:
#    http://github.com/write2david/screendoor/raw/master/Sample%20Home%20Environment%20Files/.zshrc
#
#    Or, for easy wget'ing:  www.tinyurl.com/get-screendoor-zshrc
#
# Git: http://github.com/write2david/screendoor


# Info on zsh startup files: http://zsh.sourceforge.net/Guide/zshguide02.html


watch=( all )
WATCHFMT='At %T on %W, %n has %a %l from %M.'
LOGCHECK=10
# More info on the above 3 lines:   man zshparam  /  search for "watch"
# Enables you to see recent logins by typing:  log


precmd() {

# this section comes from http://pthree.org/2008/11/23/727/
# check if jobs are executing
# must put in the chpwd() so that runs before each new command prompt

   if [[ $(jobs | wc -l) -gt 0 ]]; then
       echo "You have jobs running."
	# put this notification in RPROMPT instead of an echo
else
	# Do nothing   
   fi
  }


# if uncommenting the next section, the "precmd()" will override the above precms()
# note that this next section probably conflicts with a .bash_login section that sets the terminal title

#  Show command in title bar  (from http://www.davidpashley.com/articles/xterm-titles-with-bash.html)
# if [ "$SHELL" = '/bin/zsh' ]
# then
#    case $TERM in
#         rxvt|*term*|screen)
#         precmd() { print -Pn "\e]0;%m:%~\a" }
#         preexec () { print -Pn "\e]0;$1\a" }
#         ;;
#    esac
# fi



zstyle ':completion::complete:*' use-cache 1

# Richard Harding
# PyOhio Sample zshrc
# for more zsh links check out: http://delicious.com/deuce868/zsh
# and the Apress book: From Bash to Z Shell

# -----------------------------------------------
#
# Set up the Environment
# -----------------------------------------------

EDITOR=vim
FIGNORE='.o:.out:~'
MAIL=$HOME/.maildir
MAILPATH=$HOME/.maildir
MAILCHECK=60
SHELL=/bin/zsh

# The next line is temporary, see note on about line 231 of screendoor.sh
export DISPLAY=`cat ~/screen.xDISPLAY.txt`

# colored filename/directory completion
# Attribute codes:
# 00 none  01 bold  04 underscore  05 blink  07 reverse  08 concealed
# Text color codes:
# 30 black  31 red  32 green  33 yellow  34 blue  35 magenta  36 cyan  37 white
# Background color codes:
# 40 black  41 red  42 green  43 yellow  44 blue  45 magenta  46 cyan  47 white
LS_COLORS='no=0:fi=0:di=1;34:ln=1;36:pi=40;33:so=1;35:do=1;35:bd=40;33;1:cd=40;33;1:or=40;31;1:ex=1;32:*.tar=1;31:*.tgz=1;31:*.arj=1;31:*.taz=1;31:*.lzh=1;31:*.zip=1;31:*.rar=1;31:*.z=1;31:*.Z=1;31:*.gz=1;31:*.bz2=1;31:*.tbz2=1;31:*.deb=1;31:*.pdf=1;31:*.jpg=1;35:*.jpeg=1;35:*.gif=1;35:*.bmp=1;35:*.pbm=1;35:*.pgm=1;35:*.ppm=1;35:*.pnm=1;35:*.tga=1;35:*.xbm=1;35:*.xpm=1;35:*.tif=1;35:*.tiff=1;35:*.png=1;35:*.mpg=1;35:*.mpeg=1;35:*.mov=1;35:*.avi=1;35:*.wmv=1;35:*.ogg=1;35:*.mp3=1;35:*.mpc=1;35:*.wav=1;35:*.au=1;35:*.swp=1;30:*.pl=36:*.c=36:*.cc=36:*.h=36:*.core=1;33;41:*.gpg=1;33:'
ZLS_COLORS="$LS_COLORS"

COLORTERM=yes
PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin

# history saves 50,000 in it if we want to open it
# only the last 1000 are part of backward searching
HISTFILE=~/.zshhistory
HISTSIZE=1000
SAVEHIST=50000


# we like the calculator built into the shell
autoload -U zcalc

export TERM EDITOR PAGER RSYNC_RSH CVSROOT FIGNORE DISPLAY NNTPSERVER COLORTERM PATH HISTFILE HISTSIZE SAVEHIST

# output colored grep
export GREP_OPTIONS='--color=auto' 
export GREP_COLOR='7;31'

[[ -n "${key[Delete]}"  ]]  && bindkey  "${key[Delete]}"  delete-char
[[ -n "${key[Home]}"    ]]  && bindkey  "${key[Home]}"    beginning-of-line
[[ -n "${key[End]}"     ]]  && bindkey  "${key[End]}"     end-of-line
[[ -n "${key[Insert]}"  ]]  && bindkey  "${key[Insert]}"  overwrite-mode
[[ -n "${key[Delete]}"  ]]  && bindkey  "${key[Delete]}"  delete-char
[[ -n "${key[Up]}"      ]]  && bindkey  "${key[Up]}"      up-line-or-history
[[ -n "${key[Down]}"    ]]  && bindkey  "${key[Down]}"    down-line-or-history
[[ -n "${key[Left]}"    ]]  && bindkey  "${key[Left]}"    backward-char
[[ -n "${key[Right]}"   ]]  && bindkey  "${key[Right]}"   forward-char
bindkey "\e[1~" beginning-of-line
bindkey "\e[5~" beginning-of-history
bindkey "\e[6~" end-of-history
bindkey "\e[7~" beginning-of-line
bindkey "\e[8~" end-of-line
bindkey "\e[H" beginning-of-line
bindkey "\e[F" end-of-line
bindkey "\eOH" beginning-of-line
bindkey "\eOF" end-of-line
bindkey "\eOd" backward-word
bindkey "\eOc" forward-word

#delete key
bindkey "\e[3~" delete-char

#insert key
#bindkey "\e[2~" quoted-insert
bindkey '\e[2~' overwrite-mode

# setup backspace correctly
stty erase `tput kbs`

#home
bindkey '\e[1~' beginning-of-line

#end
bindkey '\e[4~' end-of-line

# Ctrl-R for reverse history search
bindkey '^R' history-incremental-search-backward

# Ctrl-T for forward history search
bindkey '^T' history-incremental-search-forward

# -----------------------------------------------
# Prompt Setup
# -----------------------------------------------
setopt promptsubst

# A few things from zsh post-emerge message
# The compinit function is what loads the tab-completion system by defining a shell function for every utility that zsh is able to tab-complete.
# By using autoload, you can optimize zsh by telling it to defer reading the definition of the function until it's actually used, which speeds up the zsh startup time and reduces memory usage.
autoload -U compinit
compinit

autoload -U promptinit
promptinit
prompt gentoo
# The 'gentoo' prompt uses:  /usr/share/zsh/4.3.9/functions/Prompts/prompt_gentoo_setup
# to view other prompts use: prompt <tab> 

#Basic right-hand prompt:
RPROMPT='Exit status of last command: %?'

# Basic right-hand prompt WITH COLORS:
# (first color directive sets color, second one unsets it)
#RPROMPT=$'%{\e[1;31m%}Exit status of last command: %? {\e1;00m%}'


autoload -U zrecompile

# -----------------------------------------------
# Zsh keybindings
# -----------------------------------------------

# complete on a space character
bindkey ' ' magic-space

# allow editing of the text on the current command line with v (cmd mode)
# autoload -U edit-command-line
# zle -N edit-command-line
# bindkey -M vicmd v edit-command-line


# vi style command line editing
# bindkey -v
# map jj as the esc key for vim mode
# bindkey "jj" vi-cmd-mode


# case-insensitive tab completion for filenames (useful on Mac OS X)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '-- %B%d%b --'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}



# -----------------------------------------------
# Setup
# -----------------------------------------------
setopt \
	no_beep \
	correct \
	auto_list \
	complete_in_word \
	auto_pushd \
	pushd_ignoredups \
	complete_aliases \
	extended_glob \
	hist_ignore_all_dups \
	SHARE_HISTORY \
	EXTENDED_HISTORY \
	HIST_IGNORE_ALL_DUPS \
	HISTVERIFY \
	nohup \
	nonomatch
	# the nonomatch is needed for when running commands that have a double-hyphen, like: /usr/bin/mysqldump --user=root --password=xxx --host=127.0.0.1 --all-databases 
#	zle

#  The "nohup" option means that background jobs will not be hung up (nohup = no-hang-up) when you exit out of the zsh shell.  For info on the nohup option above see http://zsh.sourceforge.net/FAQ/zshfaq03.html#l35 | http://www.quantprinciple.com/invest/index.php/docs/tipsandtricks/unix/jobcontrol/   |   http://en.wikipedia.org/wiki/Nohup

unsetopt EQUALS


# -----------------------------------------------
# Shell Aliases
# -----------------------------------------------

## Command Aliases
alias whatshell='echo You are in zsh.'
alias c='clear'
alias ls='ls --color=auto -F'
alias zrc='vim ~/.zshrc'
alias hist='history -rd'
alias zc='zcalc'
alias zrel='exec zsh'  #reload zsh (to reload .zshrc)

## Pipe Aliases (Global)
alias -g L='|less'
alias -g G='|grep'
alias -g T='|tail'
alias -g H='|head'
alias -g W='|wc -l'
alias -g S='|sort'

# directory aliases
# use like: ls ~src OR ~src OR du -h ~src
src=~/src
