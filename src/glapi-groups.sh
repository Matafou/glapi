#!/bin/bash
BINDIRECTORY=$(cd `dirname $0` && pwd)

DRYRUN=
PRINTNAMES=
PRINTUNAMES=
PRINTIDS=
PAGES=9

SEARCH=
SEARCHBYNAME=
SEARCHBYID=
GROUPNAME=
GROUPID=
EXACTNAME=

USAGE="
SYNTAX:
[GLAPITOKEN=<token> GLAPISERVER=<url>] glapi-groups.sh command
glapi groups command
(see glapi-env.sh to use this second syntax)

COMMANDS:

- search <options for search> prints the json description of the
                              corresponding groups

OPTIONS:
  -h show help
  -v verbose mode
  -n dry run, show the curl query, do not execute it. NOT APPLICABLE
     TO SEARCH command

OPTIONS FOR SEARCH:
  -name <name> look for the name <name>
  -id <id>     look fir the id <id>
  -exact the search will be an exact search instead of regexp case
         insensitive matching.
"


POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    search)
        SEARCH=yes
        shift
        ;;
    *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters (i.e.
                          # parameters that were not recognized by the
                          # previous code.)

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -pages)
        PAGES="$2"
        shift # past argument
        shift # past value
        ;;
    -name)
        GROUPNAME="$2";
        shift
        shift
        ;;
    -id)
        GROUPID="$2";
        shift
        shift
        ;;
    -exact)
        EXACTNAME=yes
        shift
        ;;
    -n)
        DRYRUN=yes
        shift # past argument
        ;;
    -h)
        echo "$USAGE"
        exit
    ;;
    -*)
        echo unknown option "$key"
        exit 1;;
    *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters (i.e.
                          # parameters that were not recognized by the
                          # previous code.)


OTHEROPTIONS=$*

. $BINDIRECTORY/glapi-utils.sh

# TODO: calculer les nombre de pages nécessaire
# FIXME: gitlab v3 ne retourne pas de bon header quand on fait
# curl --head  --header "PRIVATE-TOKEN: $GLAPITOKEN" "$GLAPISERVER/users?per_page=100&page=1
# donc pour l'instant on fait 9 pages et ça suffit largement
# (septembre 2019 il t a 400 utilisateurs et des poussières.

function showgrouppage () {
    PAGE=$1
    callcurlsilent "$GLAPISERVER/groups?per_page=100&page=$PAGE"
}

function iterpages () {
    PAGE=$1
    COMMAND=showgrouppage
    for i in $(seq 1 $PAGE); do
        $COMMAND $i
        echo
        # we remove duplicates coming from reaching the last page
    done | jq -s "flatten"    
}



if glapi-testserver.sh ;
then echo -n;
else exit $?;
fi 

if [ "$SEARCH" = "yes" ];
then
    if [ "$GROUPNAME" != "" ];
    then
        if [ "$EXACTNAME" = "yes" ];
        then
            iterpages $PAGES | jq --arg GROUPNAME \
                                  "$GROUPNAME" '.[] | select(.name==$GROUPNAME)';
        else # regexp case insensitive
            iterpages $PAGES | jq --arg GROUPNAME "$GROUPNAME" '.[] | select(.name | test($GROUPNAME;"i"))';
        fi
    else
        if [ "$GROUPID" != "" ];
        then iterpages $PAGES | jq --argjson GROUPID $GROUPID '.[] | select(.id==$GROUPID)';
        fi
    fi
    exit 0;
fi

if [ "$PRINTUNAMES" = "yes" ] ;
   iterpages $PAGES
fi


echo
