#########################################################################
# zsh-galactica
# plugin for zsh

# grole() calls list_roles function
grole() {
    _galactica_list_roles
}

# Function: _galatica_list_roles()
# Usage: ^G^R
# Purpose: list roles (located in ~/.config/shell_gpt/roles)
_galactica_list_roles() {
    local roles

    # variable to contain location of role files
    local role_dir="$HOME/.config/zsh-galactica/roles"
    export GALACTICA_ROLE_DIR="$role_dir"

    if [[ -n $ZLE_ACTIVE ]]; then
        # zle push-input
        zle push-line
    fi

    # roles are .json files in .config/shell_gpt/roles/
    # list files, remove .json extension
    roles=$(ls -1 $role_dir/*.zsh | sed 's/.*\///' | sed 's/\.zsh//')

    old_role=$ROLE
    # susbtitute periods with dashes
    old_role=${old_role//./-}

    # echo "old role: $old_role"

    # show roles widget; list all roles, highlight currently 
    # selected role, TAB key switches between roles, ENTER key
    # selects the role
    NEWROLE=$(echo $roles | fzf --prompt=" j:  k:  tab:choose  ::SELECT ROLE::" --layout="reverse-list" --no-multi --hscroll-off="2" --bind="tab:select+accept,j:down,k:up" --color="fg:7,bg:0,hl:1,fg+:0,bg+:7,hl+:1" --color="fg+:-1,bg+:-1,hl+:-1" --color="info:4,prompt:4,pointer:4,marker:4,spinner:4,header:4" --border="horizontal" --height="20%" --info="inline:|" --scrollbar="|")

    # if old_role is not the same as $ROLE, then the role has changed
    # call the old_role-unload() function
    if [[ $old_role != $NEWROLE && $old_role != "-" ]]; then
        # if old_role is not empty, then call old_role-unload()
        if [[ -n $old_role ]]; then
            # type -w "${old_role}-unload"
            # returns the format: "${old_role}-unload: function"
            # or: "${old_role}-unload: none"
            # if the function exists, call it
            if [[ $(type -w "${old_role}-unload") = *function* ]]; then
                # call the unload function
                # echo "unloading from galactica plugin"
                ${old_role}-unload
            fi
        fi
    fi

    ROLE=$NEWROLE
    export ROLE
    # source that role - allows for onload functions
    source $role_dir/$ROLE.zsh

    if [[ -n $ZLE_ACTIVE ]]; then
        zle reset-prompt
        zle -R
        zle accept-line

        zle redisplay
    fi
}


# widget to select a role
zle -N _galactica_list_roles{,}

# bind key to open role selection widget
bindkey -M viins "^G^R" "_galactica_list_roles"

##################### / _galactica_list_roles

## If there's something on the command line, complete it
## #### COMMENTED BELOW #####
_galactica_complete_or_chat() {
    # if ROLE is empty or "-", print an error message and return
    if [[ -z $ROLE || $ROLE = "-" ]]; then
        BUFFER="echo \"Must select a role first. Press Ctrl+G, Ctrl+R to select a role.\""
        # move cursor to end of line
        zle end-of-line
        return 1
    fi
    
    #   GALACTICA_ROLE_OPTIONS["CHAT"] = 1/0
    #   GALACTICA_ROLE_OPTIONS["COMPLETION"] = 1/0
     
    # if $#BUFFER is 0, there's nothing on the command line
    if [ $#BUFFER = 0 ]; then
        if [ ${GALACTICA_ROLE_OPTIONS["CHAT"]} -ne 1 ]; then
            BUFFER="echo \"This role does not support chat. Try 'galactica-help' if you're stuck.\" && galactica-help"
            zle end-of-line
            zle accept-line
            return 1
        fi
        # if there's nothing on the command line, switch to chat mode
        BUFFER="gchat"
        zle accept-line
    else
        # GALACTICA_ROLE_OPTIONS exists, let's see if it has a "COMPLETION" key
        if [ $GALACTICA_ROLE_OPTIONS["COMPLETION"] -ne 1 ]; then
          BUFFER="echo \"This role does not support completion. Try 'galactica-help' if you're stuck.\" && galactica-help"
          zle end-of-line
          zle accept-line
          return 1
        fi
        local my_buffer=$BUFFER

        # kill the buffer
        zle kill-buffer

        # define the temporary file name with tty reference
        tmp_file="$(mktemp -p /tmp -t preamble.XXXXXX)"
        export tmp_file

        # get the options and store them in a variable
        # LOCAL_OPTIONS NO_NOTIFY NO_MONITOR
        setopt LOCAL_OPTIONS NO_NOTIFY NO_MONITOR

        # call the galactica role hub, silently, in the background, with 
        # my_buffer as arguments.
        # _galactica_role_hub "$my_buffer" 2>&1 & disown

        # run the role_hub again, this time trap stderr to a file
        _galactica_role_hub "$my_buffer" 2> "$tmp_file.err" & disown

        # while the tmp file doesn't exist, wait
        while [ ! -f "$tmp_file.out" ]; do sleep 0.1; done

        # check if the tmp file contains "finish_reason"
        # if it does, then the program has finished
        while ! grep -q "finish_reason" "$tmp_file.out"; do
            sleep 0.1
        done

        sleep 0.5

        # extract relevant information from the output file
        local suggested_command=$(jq -r '.choices[0].text' "$tmp_file.out")
        
        # unset tmp_file
        unset tmp_file

        # remove the tmp_files
        rm -f "$tmp_file" "$tmp_file.out" "$tmp_file.raw" "$tmp_file.err"
        
        # reset options
        setopt LOCAL_OPTIONS NOTIFY MONITOR

        # reset the prompt
        zle reset-prompt

        # set buffer to suggested command
        BUFFER="$suggested_command"

        # put cursor at the end of the line
        zle end-of-line
    fi
}

# widget to complete or switch to chat mode
zle -N _galactica_complete_or_chat{,}

bindkey -M viins "^G^G" _galactica_complete_or_chat
##################### / _galactica_complete_or_chat

# _galactica_status()
# determine galactica status based on environment variables and
# installed programs
_galactica_status() {
    # retval starts at 0
    local retval=0

    # check if OPENAI_API_KEY environment var is set
    if [[ ! -v OPENAI_API_KEY ]]; then echo "Must set OPENAI_API_KEY to your API key" >&2; retval+=1; fi

    # check if curl is installed
    if [[ ! $+commands[curl] ]]; then echo "Curl must be installed." >&2; retval+=2; fi

    # check if jq is installed
    if [[ ! $+commands[jq] ]]; then echo "jq must be installed." >&2; retval+=4; fi

    # check if p10k is installed
    if [[ ! $+commands[p10k] ]]; then echo "p10k must be installed." >&2; retval+=8; fi

    return retval
}
##################### / _galactica_status


# galactica-help
# display help message and usage examples
galactica-help() {
    echo "Galactica is a oh-my-zshell plugin."
    echo "It allows you to use OpenAI's GPT-3 to complete tasks, depending"
    echo "on the role you select."
    echo ""
    echo "Role Selection"
    echo "  First, select the role you want to use. You can do this by pressing"
    echo "  Ctrl+G, Ctrl+R. This will open a list of available roles. You can"
    echo "  use the arrow keys to navigate the list, and press enter to select."
    echo ""
    # if a role is set, and it isn't "-", then
    # call it's version of the help function
    if [[ -n $ROLE && $ROLE != "-" ]]; then
        # my_role is the ROLE with periods replaced with dashes
        my_role=${ROLE//./-}
        ${my_role}-help
    fi
}

# _galactica_status_cachified()
# determine galactica status, cache values
_galactica_status_cachified() {
    # if the global doesn't exist, create a local one
    if [[ ! -v _galactica_status_cache ]]; then
        local _galactica_status_cache
        _galactica_status_cache=$(_galactica_status)
    fi

    # typeset: make variable global
    typeset -gx _galactica_status_cache

    return $_galactica_status_cache
}

# prompt_galactica_role: for powerlevel10k
prompt_galactica_role() {
    local role_icon_regular="󰚩"
    local role_icon_offline="󱚡"
    local role_icon_confused="󱚟"
    local role_icon_love="󱚥"
    local role_icon_happy="󱜙"
    local role_icon_excited="󱚣"
    local role_icon_angry="󱚝"
    local role_icon_offline="󱚧"

    local mystatus=$(_galactica_status_cachified)
    local gpt_status=0
    local role_base="-"

    # if role is not set, set it to '-'
    [[ -z $ROLE ]] && role_base="-"
    # if role is set, set it to ROLE
    [[ -n $ROLE ]] && role_base="${ROLE}"

    # if ROLE_SUFFIX is set, append it to the end of ROLE
    [[ -n $ROLE_SUFFIX ]] && role_base="${ROLE}::${ROLE_SUFFIX}"

    ############ negative values: offline
    # status is not equal to 0 - this isn't good
    # if role icon isn't set, confusion... (first load)
    if [[ $mystatus -ne 0 && -z $role_icon ]]; then {
        role_icon=$role_icon_confused
        typeset -gx role_icon
        p10k segment -i $role_icon -t $role_base
        return 0
      }
    fi

    # ...otherwise we're just offline...
    if [[ $mystatus -ne 0 ]]; then {
        role_icon=$role_icon_offline
        typeset -gx role_icon
        p10k segment -i $role_icon -t $role_base
        return 0
      }
    fi

    ############ positive values: online
    # mystatus is greater than or equal to 0
    # ((if $ROLE is not set, or if $ROLE is "-")), set the icon to confused
    if [[ -z $ROLE || $ROLE == "-" ]]; then { 
        role_icon=$role_icon_confused
        typeset -gx role_icon
        p10k segment -i $role_icon -t $role_base
        return 0
      }
    fi

    # mystatus is good so far, now check if the role is happy or angry
    if [[ $gpt_status -ne 0 ]]; then {
        role_icon=$role_icon_angry
        typeset -gx role_icon
        p10k segment -i $role_icon -t $role_base
        return 0
      }
    fi

    # if the last command returned 0, set the icon to happy
    if [[ $gpt_status -eq 0 ]]; then { 
        role_icon=$role_icon_happy
        role_icon=$role_icon_excited
        typeset -gx role_icon
        p10k segment -i $role_icon -t $role_base
        return 0
      }
    fi

    # if mystatus is equal to 0, set the icon to regular
    # this is default (fallback)
    if [[ $mystatus -eq 0 ]]; then {
        role_icon=$role_icon_regular
        typeset -gx role_icon
        p10k segment -i $role_icon -t $role_base
        return 0
      }
    fi

    # if role_icon isn't set, set it to confused
    [[ -z $role_icon ]] && role_icon=$role_icon_confused

    p10k segment -i $role_icon -t $role_base
    typeset -gx role_icon
    return 0
}

_galactica_role_sourcer() {
    # if $ROLE is set and not empty, source the file $GALACTICA_ROLE_DIR/$ROLE.zsh
    if [[ -n $ROLE && -f $GALACTICA_ROLE_DIR/$ROLE.zsh ]]; then
        # echo "Attempting to source $GALACTICA_ROLE_DIR/$ROLE.zsh..."
        source $GALACTICA_ROLE_DIR/$ROLE.zsh
    fi
}

# onload stuff:
unset ROLE # clear the role so a proper load can happen
# source the role
_galactica_role_sourcer

