ZCOMPDUMP="$ZSH_CACHE_DIR/compdump"

# Load and initialise the completion system.
#
# `compinit -C` skips the scan for new completion functions, which is what makes
# startup fast -- but on its own it means completions installed after the dump
# was written stay invisible forever. Do the full scan once a day and take the
# fast path the rest of the time: the glob matches only when the dump is missing
# or older than 24h.
# The explicit `touch` matters: compinit only rewrites the dump when the set of
# completions actually changed, so after the first full run the file keeps its
# old mtime, stays >24h old forever, and every subsequent shell takes the slow
# path. Touching it restarts the clock whether or not the contents changed.
autoload -Uz compinit
if [[ -n ${ZCOMPDUMP}(#qN.mh-24) ]]; then
  compinit -C -i -d ${ZCOMPDUMP}
else
  compinit -i -d ${ZCOMPDUMP}
  command touch ${ZCOMPDUMP}
fi

{
  # compile compdump file in the background
  local zcompdump=$ZCOMPDUMP
  if [[ -s ${zcompdump} && ( ! -s ${zcompdump}.zwc || ${zcompdump} -nt ${zcompdump}.zwc) ]]; then
    zcompile ${zcompdump}
  fi
  unset zcompdump
} &!

# Options
setopt complete_in_word    # Complete from both ends of a word.
setopt always_to_end       # Move cursor to the end of a completed word.
setopt path_dirs           # Perform path search even on command names with slashes.
setopt auto_menu           # Show completion menu on a successive tab press.
setopt auto_list           # Automatically list choices on ambiguous completion.
setopt auto_param_slash    # If completed parameter is a directory, add a trailing slash.
unsetopt menu_complete     # Do not autoselect the first completion entry.
unsetopt flow_control      # Disable start/stop characters in shell editor.

# group matches and describe.
# fzf-tab renders the menu itself and requires the builtin one to be disabled.
zstyle ':completion:*' menu no
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Fuzzy match mistyped completions.
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

# Increase the number of errors based on the length of the typed word. But make
# sure to cap (at 7) the max-errors to avoid hanging.
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'

# Don't complete unavailable commands.
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

# completion sorting
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# Directories
# Prefer the system's dircolors database over a hand-maintained LS_COLORS: it
# covers far more file types and stays in sync with the coreutils version.
if (( $+commands[dircolors] )); then
  eval "$(dircolors -b)"
else
  export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=36;01:cd=33;01:su=31;40;07:sg=36;40;07:tw=32;40;07:ow=33;40;07:'
fi
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'expand'
zstyle ':completion:*' squeeze-slashes true

# History
zstyle ':completion:*:history-words' stop yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' list false

# Environmental Variables
zstyle ':completion::*:(-command-|export):*' fake-parameters ${${${_comps[(I)-value-*]#*,}%%,*}:#-*-}

# Populate hostname completion. But allow ignoring custom entries from static
# */etc/hosts* which might be uninteresting.
zstyle -e ':completion:*:hosts' hosts 'reply=(
  ${=${=${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) 2> /dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
  ${=${(f)"$(cat /etc/hosts(|)(N) <<(ypcat hosts 2> /dev/null))"}%%(\#${_etc_host_ignores:+|${(j:|:)~_etc_host_ignores}})*}
  ${=${${${${(@M)${(f)"$(cat ~/.ssh/config 2> /dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
)'

# Don't complete uninteresting users...
zstyle ':completion:*:*:*:users' ignored-patterns \
  adm amanda apache avahi beaglidx bin cacti canna clamav daemon \
  dbus distcache dovecot fax ftp games gdm gkrellmd gopher \
  hacluster haldaemon halt hsqldb ident junkbust ldap lp mail \
  mailman mailnull mldonkey mysql nagios \
  named netdump news nfsnobody nobody nscd ntp nut nx openvpn \
  operator pcap postfix postgres privoxy pulse pvm quagga radvd \
  rpc rpcuser rpm shutdown squid sshd sync uucp vcsa xfs mpd git colord \
  usbmux polkitd uuidd 'systemd-*' '_*'

# Ignore multiple entries.
zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
zstyle ':completion:*:rm:*' file-patterns '*:all-files'

# Kill
zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,command -w'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*' insert-ids single

# Man
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

# Media Players
zstyle ':completion:*:*:mpv:*' file-patterns '*.(wav|mp3|flac|ogg|mp4|avi|mkv|webm):media\ files *(-/):directories'

# Text Editor
zstyle ':completion:*:(nano|vim|nvim|v):*' ignored-patterns '*.(wav|mp3|flac|ogg|mp4|avi|mkv|webm|iso|dmg|so|o|a|bin|exe|dll|pcap|7z|zip|tar|gz|bz2|rar|deb|pkg|gzip|pdf|mobi|epub|png|jpeg|jpg|gif)'

# SSH/SCP/RSYNC
zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

# Enable caching
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "$ZSH_CACHE_DIR"

# Automatically find new executables in $PATH
zstyle ':completion:*' rehash true

# ===== fzf-tab
# Only consulted when the plugin is loaded (init.zsh sources it after compinit).
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:*' fzf-min-height 15

# Preview directory contents when completing a path
if (( $+commands[eza] )); then
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --level=2 --color=always --icons=always $realpath'
  zstyle ':fzf-tab:complete:z:*'  fzf-preview 'eza --tree --level=2 --color=always --icons=always $realpath'
  zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --tree --level=2 --color=always --icons=always $realpath'
fi

# Preview the environment for export/unset, and processes for kill
zstyle ':fzf-tab:complete:(export|unset):*' fzf-preview 'echo ${(P)word}'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
  'ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:3:wrap

# Preview systemd units
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'