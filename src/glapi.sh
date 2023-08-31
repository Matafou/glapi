#!/bin/bash

COMMAND=$1
shift

# Having this in your bashrc may be useful
# alias iniglapi='eval $(...glapi/src/glapi-env.sh -v3 YOURTOKEN GITLABURL)'

USAGE="
This script should be used via an alias like this:

alias glapi="'GLAPITOKEN=$TOKEN GLAPISERVER=$URL PATH=$BINDIRECTORY:$PATH glapi.sh'"

Usage of glapi:

glapi -h Show this help
glapi -list Show a list of possible commands (bash complete friendly)
glapi <command> -h  show help for this command
glapi <command> <subcommand>  execute this subcommand of this command

where commands is one of: groups users projects.

"

if [ "$COMMAND" = "-h" ]; then
    echo "$USAGE"
    exit 0
fi

EXCLUDED_COMMANDS="glapi-util\\|glapi-testserver\\|glapi-functions\\|glapi-env"

# Enumerate all commands, i.e. all suffixes of glapi-xxx.sh files,
# exept the utilitary files
function list_commands () {
    DIR="$( dirname ${BASH_SOURCE[0]} )"
    RES=$(ls $DIR | grep "glapi-.*\.sh" | grep -v "$EXCLUDED_COMMANDS" | sed -e "s/glapi-//"| sed -e "s/\.sh//")
    echo $RES
}

if [ "$COMMAND" = "-list" ]; then
    list_commands
    exit 0
fi

function expand-q() {
    for i; do echo ${i@Q}; done;
} 

NEWCOMMAND=glapi-$COMMAND.sh

# We need to requote arguments to build the good command
if [ "$#" -lt 1 ]; then
 quoted_args=""
else
 quoted_args="$(printf " %q" "${@}")"
fi

bash -c "$( dirname "${BASH_SOURCE[0]}" )/$NEWCOMMAND ${quoted_args}"
