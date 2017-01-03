autoload -U add-zsh-hook
autoload -Uz vcs_info

setopt promptsubst

__color_cyan="%{$fg[cyan]%}"
__color_green="%{$fg_bold[green]%}"
__color_grey="%{$fg_bold[black]%}"
__color_red="%{$fg[red]%}"
__color_reset="%{${reset_color}%}"
__color_white="%{$fg[white]%}"
__color_yellow="%{$fg[yellow]%}"

zstyle ':vcs_info:*' enable git svn
zstyle ':vcs_info:git*:*' get-revision true
zstyle ':vcs_info:git*:*' check-for-changes true
zstyle ':vcs_info:git*:*' stagedstr "${__color_green}S${__color_grey}"
zstyle ':vcs_info:git*:*' unstagedstr "${__color_red}U${__color_grey}"
zstyle ':vcs_info:git*+set-message:*' hooks git-st git-stash git-username

zstyle ':vcs_info:git*' formats "(%s) %12.12i %c%u %b%m" # hash changes branch misc
zstyle ':vcs_info:git*' actionformats "(%s|${__color_white}%a${__color_grey}) %12.12i %c%u %b%m"

add-zsh-hook precmd theme_precmd

# Show remote ref name and number of commits ahead-of or behind
function +vi-git-st() {
    local ahead behind remote
    local -a gitstatus

    # Are we on a remote-tracking branch?
    remote=${$(git rev-parse --verify ${hook_com[branch]}@{upstream} \
        --symbolic-full-name --abbrev-ref 2>/dev/null)}

    if [[ -n ${remote} ]] ; then
        ahead=$(git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l | sed -e 's/^[[:blank:]]*//')
        (( $ahead )) && gitstatus+=( "${__color_green}+${ahead}${__color_grey}" )

        behind=$(git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l | sed -e 's/^[[:blank:]]*//')
        (( $behind )) && gitstatus+=( "${__color_red}-${behind}${__color_grey}" )

        hook_com[branch]="${hook_com[branch]} [${remote} ${(j:/:)gitstatus}]"
    fi
}

# Show count of stashed changes
function +vi-git-stash() {
    local -a stashes

    if [[ -s ${hook_com[base]}/.git/refs/stash ]] ; then
        stashes=$(git stash list 2>/dev/null | wc -l | sed -e 's/^[[:blank:]]*//')
        hook_com[misc]+=" (${stashes} stashed)"
    fi
}

# Show local git user.name
function +vi-git-username() {
    local -a username

    username=$(git config --local --get user.name | sed -e 's/\(.\{40\}\).*/\1.../')
    hook_com[misc]+=" ($username)"
}

function _get-docker-prompt() {
    local docker_prompt
    docker_prompt=$DOCKER_HOST
    [[ "${docker_prompt}x" == "x" ]] && docker_prompt="unset"
    echo -n "${__color_cyan}🐳  ${docker_prompt} ${__color_reset}"
}

function _get-node-prompt() {
    local node_prompt npm_prompt
    node_prompt=$(node -v 2>/dev/null)
    npm_prompt="v$(\npm -v 2>/dev/null)"
    [[ "${node_prompt}x" == "x" ]] && node_prompt="none"
    [[ "${npm_prompt}x" == "vx" ]] && npm_prompt="none"
    echo -n "${__color_green}⬢ ${node_prompt} ${__color_yellow}npm ${npm_prompt} ${__color_reset}"
}

function setprompt() {
    unsetopt shwordsplit
    local -a lines infoline
    local x i filler i_width

    ### First, assemble the top line
    # Current dir; show in yellow if not writable
    [[ -w $PWD ]] && infoline+=( ${__color_green} ) || infoline+=( ${__color_yellow} )
    infoline+=( "(${PWD/#$HOME/~})${__color_reset} " )

    if [[ $ENABLE_DOCKER_PROMPT == 'true' ]]; then
        infoline+=( "$(_get-docker-prompt)" )
    fi

    if [[ $ENABLE_NODE_PROMPT == 'true' ]]; then
        infoline+=( "$(_get-node-prompt)" )
    fi

    # Username & host
    infoline+=( "(%n)" )
    [[ -n $SSH_CLIENT ]] && infoline+=( "@%m" )

    i_width=${(S)infoline//\%\{*\%\}} # search-and-replace color escapes
    i_width=${#${(%)i_width}} # expand all escapes and count the chars

    filler="${__color_grey}${(l:$(( $COLUMNS - $i_width ))::-:)}${__color_reset}"
    infoline[2]=( "${infoline[2]}${filler} " )

    ### Now, assemble all prompt lines
    lines+=( ${(j::)infoline} )
    [[ -n ${vcs_info_msg_0_} ]] && lines+=( "${__color_grey}${vcs_info_msg_0_}${__color_reset}" )
    lines+=( "%(1j.${__color_grey}%j${__color_reset} .)%(0?.${__color_white}.${__color_red})%#${__color_reset} " )

    ### Finally, set the prompt
    PROMPT=${(F)lines}
}


theme_precmd () {
    vcs_info
    setprompt
}
