#!/bin/bash

COMMAND=$1
shift

if [ "$COMMAND" = "-h" ]; then
    echo HELP TODO
    exit 0
fi

function expand-q() {
    for i; do echo ${i@Q}; done;
} 

# if [ "$COMMAND" = "env" ]; then
#     glapi-env.sh $*
# fi

NEWCOMMAND=glapi-$COMMAND.sh

# We need to requote arguments to build the good command
if [ "$#" -lt 1 ]; then
 quoted_args=""
else
 quoted_args="$(printf " %q" "${@}")"
fi

bash -c "$( dirname "${BASH_SOURCE[0]}" )/$NEWCOMMAND ${quoted_args}"


# echo exec $NEWCOMMAND $*
