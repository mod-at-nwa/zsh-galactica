# role file - to be sourced from a zsh shell function
# role definition
# role: quick-cli
# Purpose: give single shot commands to accomplish a task

_galactica_role_hub() {
    # role variables for GPT
    # for code
    local model="text-davinci-003"
    # for text
    # local model="text-davinci-edit-001"
    
    
    local content_instruction="Complete using the least amount of zsh and ubuntu commands. "
        content_instruction+="IMPORTANT: use plaintext, no markdown, no quotes, no code blocks. "
        content_instruction+="IMPORTANT: use commands without scripts, unless absolutely necessary. "
        # content_instruction+="What zshell commands will accomplish the input?"
    
    # user content: all information on the command line is passed as the user input
    local content_input=$@
    
    # If there are any quotes or double quotes, escape them
    content_input=$(echo $content_input | sed 's/\"/\\\"/g')
    
    # add the input to the instruction
    content_instruction+=$content_input
    
    # terminate the instruction
    content_instruction+=" [insert]"
    
    # Assemble the hodge for podging
    local gpt_parameters="{";
    gpt_parameters+="\"model\": \"$model\",";
    gpt_parameters+="\"prompt\": \"$content_instruction\",";
    gpt_parameters+="\"suffix\": \"\",";
    gpt_parameters+="\"temperature\": 0,";
    gpt_parameters+="\"max_tokens\": 128,";
    gpt_parameters+="\"top_p\": 1,";
    gpt_parameters+="\"frequency_penalty\": 0,";
    gpt_parameters+="\"presence_penalty\": 0";
    gpt_parameters+="}";
    
    # dump the parameters to a file
    echo $gpt_parameters >> $tmp_file
    
    # insert a message on the line beneath the current one
    BUFFER="$@; Fetching response from GPT..."

    ## call GPT
    curl https://api.openai.com/v1/completions \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -d "$gpt_parameters" \
      -o $tmp_file.out \
      -s > /dev/null & pid=$!
    
    spin='⠋⠙⠚⠞⠖⠦⠴⠲⠳⠓'
    
    # put the cursor below the current line
    echo -e "\n"

    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(((i + 1) % 10))
        print "\033[1A\033[K$fg[magenta]\r${spin:$i:1} $fg[white] Processing..."
        # printf "\033[1A\033[K$fg[magenta]\r${spin:$i:1}"
        sleep .1
    done
    # printf "\r$fg[green]✓ ${reset_color}Ding!          "
    print "\033[1A\033[K\r$fg[green]✓ ${reset_color}Ding!          "

}

gchat() {
    echo "quick-cli.role:: type the plain language command, then press the hotkey to send it to GPT"
    echo "                 and have it replaced with a zshell command."
    return 0
}

# onload stuff:
builtin typeset -Agx GALACTICA_ROLE_OPTIONS
GALACTICA_ROLE_OPTIONS["CHAT"]=0
GALACTICA_ROLE_OPTIONS["COMPLETION"]=1
GALACTICA_ROLE_OPTIONS["TITLE"]="quick-cli"


# unload stuff:
quick-cli-role-unload() {
    # unset -f gchat
    unset -f _galactica_role_hub
    unset -f quick-cli-role-help
    unset -f quick-cli-role-unload
    unset GALACTICA_ROLE_OPTIONS
    unset -f gchat
    return 0
}

# quick-cli help, appended when galactica-help is called.
quick-cli-role-help() {
    echo "Completion: quick-cli role"
    echo "  The quick-cli role allows you to quickly complete a command line."
    echo "  Usage:"
    echo "    user@${fg[red]}host${reset_color}:~ $ ${fg[green]}what is my ip address;${reset_color} ^G^G"
    echo ""
    return 0
}
