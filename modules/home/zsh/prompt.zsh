autoload -Uz vcs_info add-zsh-hook

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' unstagedstr '%F{003}!'
zstyle ':vcs_info:*' stagedstr '%F{002}+'
zstyle ':vcs_info:git:*' formats '%B%m%c%u%{%f%%b%} %F{008}%b'
zstyle ':vcs_info:git:*' actionformats '%B%m%c%u%{%%b%} %F{008}%b %f(%a)'
zstyle ':vcs_info:git:*' actionformats '%B%F{001}%a%{%%b%} %F{008}%b%f%c%u%m'

zstyle ':vcs_info:git*+set-message:*' hooks git-status git-ahead-behind

+vi-git-status() {
    local gitstatus=$(git status --porcelain)
    if [[ $? -eq 0 ]]; then
        local status_indicators=""

        [[ $gitstatus =~ '\?\?' ]] && status_indicators+='%F{009}?'
        [[ $gitstatus =~ '^D|^.D' ]] && status_indicators+='%F{161}'
        [[ $gitstatus =~ '^R' ]] && status_indicators+='%F{002}»'

        if [[ -z $hook_com[staged] && -z $hook_com[unstaged] && -z $status_indicators ]]; then
            hook_com[misc]='%F{002}✓%f'
        else
            hook_com[misc]="$status_indicators"
        fi
    fi
}

+vi-git-ahead-behind() {
    local -a gitstatus
    gitstatus=($(git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null))
    
    if [[ $? -eq 0 ]]; then
        local ahead=${gitstatus[1]}
        local behind=${gitstatus[2]}
        
        if [[ $ahead -gt 0 ]] && [[ $behind -gt 0 ]]; then
            hook_com[misc]+='%F{013}⇕%f'
        elif [[ $ahead -gt 0 ]]; then
            hook_com[misc]+='%F{012}⇡%f'
        elif [[ $behind -gt 0 ]]; then
            hook_com[misc]+='%F{011}⇣%f'
        fi
    fi
}

add-zsh-hook precmd vcs_info

add-zsh-hook chpwd -U () {
    print -Pn "\033]0;%~\a"
}
print -Pn "\033]0;%~\a"

P_USER="%F{magenta}%n%f@%F{magenta}%m%f"
P_PATH="%~"
P_STATUS="%(0?.%F{green}.%F{red})"
P_JOBS="%(1j.*.)"

setopt promptsubst
PROMPT="${P_USER}%B %b${P_PATH} ${P_STATUS}${P_JOBS}❭%f "
RPROMPT='${vcs_info_msg_0_}'
