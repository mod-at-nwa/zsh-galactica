# role file - to be sourced from a zsh shell function
# role definition
# role: script-maker
# Purpose: create a script from a skeletal file
#          or edit a file using ChatGPT's new edit feature


# Function definitions

gedit() {
    _galactica_edit $@
}

_galactica_edit() {
    # _galactica_edit [options] -p <project> -f <file> -i <instruction-file> 
    echo "gedit called..."

    local options_tally=0
    while getopts ":p:f:i:h" opt; do
        case "${opt}" in
            h)
                echo "usage: gedit [options] -p <project> -f <file> -i <instruction-file>"
                echo "     : check 'galactica-help' for more information."
                return 0
                ;;
            p)
                # set the project name
                echo "setting project name to $OPTARG"
                options_tally=$((options_tally+1))
                project=${OPTARG}
                ;;
            f)
                echo "setting file name to $OPTARG"
                options_tally=$((options_tally+2))
                file=${OPTARG}
                ;;
            i)
                echo "setting instruction file name to $OPTARG"
                options_tally=$((options_tally+4))
                instruction_file=${OPTARG}
                ;;
            :)
                echo "Error: -${OPTARG} requires an argument."
                return 1
                ;;
            *)
                echo "Error: unknown option -${OPTARG}"
                return 1
                ;;
        esac
    done

    # check if the options tally is 7
    if [ $options_tally -ne 7 ]; then
        echo "Error: incorrect number of options."
        echo "usage: gedit [options] -p <project> -f <file> -i <instruction-file>"
        echo "     : check 'galactica-help' for more information."
        return 1
    fi
    
    # set the cwd to the main project directory
    cd $GALACTICA_ROLE_OPTIONS["DIR"]
    # cd $GALACTICA_SM_PROJECT_DIR
    echo "the GALACTICA PROJECT DIR IS $GALACTICA_ROLE_OPTIONS["DIR"]"
    echo "project is $project"
    echo "file is $file"
    echo "instruction file is $instruction_file"

    # set an environment variable named ROLE_SUFFIX to the project value
    ROLE_SUFFIX=$project
    export ROLE_SUFFIX

    # full project directory path, a combination of the project directory and the project name
    project_dir=$GALACTICA_ROLE_OPTIONS["DIR"]/$project

    # if the project directory doesn't exist, create it
    if [ ! -d $project_dir ]; then
        echo "$0:: Creating project directory: $project"
        # try to create a directory
        # if it fails, send a message to stderr and
        # return an error
        mkdir $project_dir || { echo "$0:: Failed to create project directory: $project" >&2; return 1; }
        echo "$0:: Project directory created: $project"
    else
        echo "$0:: Project directory exists: $project"
    fi


    # set the cwd to the project directory
    cd $project_dir

    # if the cwd is the project directory, echo "success"
    local current_dir=$(pwd)
    if [[ $current_dir == $project_dir ]]; then
        echo "$0:: Project directory set to: $(pwd)"
    else
        echo "$0:: Failed to set project directory to: $project_dir"
        return 1
    fi

    # if check if the file exists
    if [ ! -f $file ]; then
        echo "$0:: File does not exist: $file"
        return 1
    fi

    # check if the instruction file exists
    if [ ! -f $instruction_file ]; then
        echo "$0:: Instruction file does not exist: $instruction_file"
        return 1
    fi

    # append a backup copy of the file and the instruction file
    # in a tar, gzipped. Progression can be viewed with this.
    echo "$0:: Creating backup of $file and $instruction_file in $file.tar.gz"
    tar -Azvf $file.tar.gz $file $instruction_file

    ################################################### INSTRUCTION PROCESSING
    echo "$0:: Using instruction file: $instruction_file"
    # cat $instruction_file | sed 's/^/    /'
    # load the instruction file into a variable, replacing newlines with \n
    local instruction=$( awk '{printf "%s\\n", $0}' $instruction_file )
    instruction=${instruction:gs/\'/\\\'/}
    instruction=${instruction:gs/\"/\\\"/}
    instruction=$(echo "$instruction" | sed ':a;N;$!ba;s/\n/\\n/g')
    instruction=${instruction:gs/\\/\\\\/}

    ################################################# FILE CONTENTS PROCESSING
    local file_contents
    # load the file into a variable, replacing newlines with \n
    read -r -d '' file_contents < $file

    # escape single quotes
    file_contents=${file_contents:gs/\'/\\\'/}

    # escape double quotes
    file_contents=${file_contents:gs/\"/\\\"/}

    # replace newlines with '\n'
    file_contents=$(echo "$file_contents" | sed ':a;N;$!ba;s/\n/\\n/g')

    # escape backslashes
    file_contents=${file_contents:gs/\\/\\\\/}

    # build the api call
    local api_call="{"
    api_call+="\"model\": \"code-davinci-edit-001\"," # the model to use
    api_call+="\"input\": \"$file_contents\"," # the file contents
    api_call+="\"instruction\": \"$instruction\"," # the instruction
    api_call+="\"temperature\": 0.84," # the temperature
    api_call+="\"top_p\": 1" # the top_p
    api_call+="}" # the bottom_p - no shade, no tea

    curl https://api.openai.com/v1/edits \
       -H "Content-Type: application/json" \
       -H "Authorization: Bearer $OPENAI_API_KEY" \
       -d "$(echo $api_call | jq)" | jq -r '.choices[0].text' > $file.s-m

}

#######################
# onload stuff:
# role options
# global variable to hold the role options
builtin typeset -Agx GALACTICA_ROLE_OPTIONS
GALACTICA_ROLE_OPTIONS["CHAT"]=0
GALACTICA_ROLE_OPTIONS["COMPLETION"]=0
GALACTICA_ROLE_OPTIONS["TITLE"]="Script-Maker"
GALACTICA_ROLE_OPTIONS["DIR"]="$HOME/Projects"

# global variable of project directory location
# builtin typeset -gx GALACTICA_SM_PROJECT_DIR="$HOME/Projects/"

# unload stuff:
script-maker-role-unload() {
    # cleanup
    unset -f script-maker-role-help
    unset -f script-maker-role-unload
    unset -f gedit
    unset -f _galactica_edit
    unset GALACTICA_ROLE_OPTIONS
    unset ROLE_SUFFIX
    return 0
}

# script-maker help, appended when galactica-help is called.
script-maker-role-help() {

    local ROLE=${GALACTICA_ROLE_OPTIONS["TITLE"]}

    # store the length of the $ROLE variable
    local role_length=${#ROLE}
    # fill a variable with role_length spaces
    # local spaces=$(printf "%-${role_length}s" " ")
    local spaces="            "

    # make an array to contain many strings
    local role_lines

    # add lines to the array
    role_lines+="CURRENT ROLE:: $ROLE\n"
    role_lines+="$spaces :   The script-maker role allows you to quickly create and edit files.\n"
    role_lines+="$spaces : \n"
    role_lines+="$spaces :   Usage:\n"
    role_lines+="$spaces :     ${fg[green]}gedit${reset_color} [ -h ] -p <project> -f <file> -i <instruction-file>\n"
    role_lines+="$spaces :   \n"
    role_lines+="$spaces :   -p <project> is the name of the project directory to create or use\n"
    role_lines+="$spaces :   -f <file> is the name of the file to create or edit\n"
    role_lines+="$spaces :   -i <instruction-file> is the name of the file containing the instructions for the file\n"
    role_lines+="$spaces :   \n"
    role_lines+="$spaces :   instructions should be written in plain language\n"
    role_lines+="$spaces :   examples: minify this script\n"
    role_lines+="$spaces :   examples: write a script to monitor a file, passed in arg1\n"
    role_lines+="$spaces :   examples: add comments to this code\n"
    role_lines+="$spaces :   \n"
    role_lines+="$spaces :   the instruction file will be modified to include relevant additions\n"
    # for each line in the array, print it with the role_length spaces
    for line in "${role_lines[@]}"; do
        echo "$line"
    done
    return 0
}

