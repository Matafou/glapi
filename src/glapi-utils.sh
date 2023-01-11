#!/bin/bash

# This is to be sourced only, it contains useful functino for glapi commands.

# to call this without really sending the request:
#   DRYRUN=yes addMemberToGroupById $USERID $GROUPNAME
function callcurl () {
    local cmd="curl -v --header \"PRIVATE-TOKEN: $GLAPITOKEN\""
    # Putting quotes around arguments, so that the space-containing
    # args remain as they are + verbose message can be copy-pasted
    for t in $*
    do
        cmd+=" \"$t\""
    done
    if [ "$VERBOSE" = "yes" -o "$DRYRUN" != "" ] ;
    then
        echo "verbose: $cmd"
    fi
    if [ "$DRYRUN" = "" ] ;    
    then
        eval $cmd
    fi
}

function callcurlsilent () {
    local cmd="curl -s --header \"PRIVATE-TOKEN: $GLAPITOKEN\""
    for t in $*
    do
        cmd+=" \"$t\""
    done
    if [ "$VERBOSE" = "yes" -o "$DRYRUN" != "" ] ;
    then
        echo "verbose: $cmd"
    fi
    if [ "$DRYRUN" = "" ] ;    
    then
        eval $cmd
    fi
}

## Functions filtering the json output. 
# auxiliary: remove [ ] enclosing lists, and the puts each member of the list on its own line
function split-lines () {
    $* | sed -e "s/^\[\(.*\)\]$/\1/" | sed -e "s/},{/}\n{/g"
}

#precond: each entry must be on its own line prints only the numeric
# field matching $1 from each line of the output of the command
# described by all other arguments.
function filter-numeric () {
    NUM=$1
    shift
    $*  | grep -o "\"$NUM\":[^,}]*[,}]" | sed -e "s/\"$NUM\":\([^,]*\),/\1/"
}

#precond: each entry must be on its own line prints only the string
# field matching $1 from each line of the output of the command
# described by all other arguments.
function filter-string () {
    STR=$1
    shift
    $*  | grep -o "\"$STR\":[^,}]*[,}]" | sed -e "s/\"$STR\":\"\([^\",]*\)\",/\1/"
}


# $2 should a regular expression which never match a double quote.
# toto: use some json library instead.
function filter-field-string () {
    FLD=$1
    STR=$2
    shift
    shift
    $* | grep -i "\"$FLD\":\"[^\"]*$STR[^\"]*\"[,}]"
}

# using jq library
function filter-field () {
    FLD=$1
    STR=$2
    shift
    shift
    $*  | jq --arg STR $STR --arg FLD $FLD '.[] | select(.env.FLD=="env.STR")'
}



# $2 should a regular expression which never match a double quote.
# toto: use some json library instead.
function filter-field-numeric () {
    FLD=$1
    STR=$2
    shift
    shift
    # exact matching
    $* | grep -i "\"$FLD\":$STR[,}]"
}

# I would like jq to print itself when DRYRUN is set (instead of
# running), but jq is so dependent on the syntax of its arguments that
# I did not manage to define gjq.
function gjq () {
    if [ "$#" -lt 1 ]; then
        quoted_args=""
    else
        quoted_args="$(printf " %q" "${@}")"
    fi
    if [ "$DRYRUN" = "" ] ;
    then jq $*
    else echo jq ${quoted_args} ;
    fi
}

# query user for confirmation. Example of use:
# if confirm ;
#         then echo will do
#         else 
#             echo aborting
#             exit;
#         fi
function confirm () {
    read -p "Are you sure? " -n 1 -r ANSWER
    echo  # (optional) move to a new line
    echo " You answered $ANSWER"
    if [[ $ANSWER =~ ^[Yy]$ ]]
    then
        return 0
    else
        return 1;
    fi
}
