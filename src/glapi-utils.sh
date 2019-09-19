#!/bin/bash

# This is to be sourced only, it contains useful functino for glapi commands.


function callcurl () {
    if [ "$VERBOSE" = "yes" -o "$DRYRUN" != "" ] ;
    then
        echo -n "curl -v --header \"PRIVATE-TOKEN: $GLAPITOKEN\""
        # Putting quotes around arguments, so that the command can be copy pasted
        for t in $*; do echo -n " \"$t\""; done
        echo
        # echo "curl -v --header \"PRIVATE-TOKEN: $GLAPITOKEN\" $*" ;
    fi
    if [ "$DRYRUN" = "" ] ;    
    then curl -v --header "PRIVATE-TOKEN: $GLAPITOKEN" $*
    fi
}

function callcurlsilent () {
    if [ "$VERBOSE" = "yes" ]  || [ "$DRYRUN" != "" ] ;
    then
        echo -n "curl -s --header \"PRIVATE-TOKEN: $GLAPITOKEN\""
        for t in $*; do echo -n " \"$t\""; done
        echo;
    fi
    if [ "$DRYRUN" = "" ] ;    
    then curl -s --header "PRIVATE-TOKEN: $GLAPITOKEN" $*
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


# I would like jq to print itself when DRYRIN is set (instead of
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
