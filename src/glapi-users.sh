#!/bin/bash

BINDIRECTORY=$(cd `dirname $0` && pwd)

# This variable is known and used by callcurl and callcurlsilent it is
# not used for any other purpose.
DRYRUN=

VERBOSE=""
ADDUSER=
SEARCH=
SEARCHBYNAME=
SEARCHBYID=
PRINTNAMES=
PRINTUNAMES=
PRINTIDS=
GROUP=""
PAGES=9
USERNAME=
USERID=
EXACTNAME=

USAGE="
SYNTAX:
[GLAPITOKEN=<token> GLAPISERVER=<url>] glapi-users.sh command
glapi users command
(see glapi-env.sh to use this second syntax)

COMMANDS:
- add <username> <userlogin> <usermail> <passwd>
- search <options for search>

OPTIONS:
  -h show help
  -v verbose mode
  -n dry run, show the curl query, do not execute it. NOT APPLICABLE
     TO SEARCH command

OPTIONS FOR SEARCH:
  -name <name>
  -id <id>
  -exact the search will be an exact search instead of regexp case
         insensitive matching.
"


POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    add)
        ADDUSER=yes
        shift
        USERNAME="$1"
        shift
        USERLOGIN="$1"
        shift
        USERMAIL="$1"
        shift
        PASSWD="$1"
        shift
        ;;
    search)
        SEARCH=yes
        shift
        ;;
    *) # not a command, we delay interpretation.
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
esac
done

if [ "$SEARCH" != "" -a "$ADDUSER" != "" ];
then
    echo Cannot deal with two commands!
    echo "$USAGE"
    exit;
fi

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
    -group)
        GROUP="$2"
        shift # past argument
        shift # past value
        ;;
    -name)
        USERNAME="$2";
        shift
        shift
        ;;
    -id)
        USERID="$2";
        shift
        shift
        ;;
    # TODO:
    -login)
        USERLOGIN="$2";
        shift
        shift
        ;;
    -exact)
        EXACTNAME=yes
        shift
        ;;
    -names)
        PRINTNAMES=yes
        shift # past argument
        ;;
    -logins)
        PRINTUNAMES=yes
        shift # past argument
        ;;
    -ids)
        PRINTIDS=yes
        shift # past argument
        ;;
    -v)
        VERBOSE=yes
        shift # past argument
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

# Here we should have shifted the arguments that should not be passed to curl
OTHEROPTIONS=$*
# TODO: check for unkniwn option

. $BINDIRECTORY/glapi-utils.sh


# requête pour lister les utilisateur + ajout d'un saut de ligne entre
# chaque utilisateur donc on peut faire grep dessus, de préférence en
# mettant tout en minuscule avant pour éviter de rater des
# utilisateurs.
# TODO: calculer les nombre de pages nécessaire
# FIXME: gitlab v3 ne retourne pas de bon header quand on fait
# curl --head  --header "PRIVATE-TOKEN: $GLAPITOKEN" "$GLAPISERVER/users?per_page=100&page=1
# donc pour l'instant on fait 9 pages et ça suffit largement
# (septembre 2019 il t a 400 utilisateurs et des poussières.

function showuserpage () {
    PAGE=$1
    callcurlsilent "$GLAPISERVER/users?per_page=100&page=$PAGE"
}

function showuserfromgrouppage () {
    PAGE=$2
    THEGROUP=$1
    callcurlsilent "$GLAPISERVER/groups/$THEGROUP/members?per_page=100&page=$PAGE" | jq '.'
}

function addUtilisateur () {
    NAME=$1
    LOGIN=$2
    MAIL=$3
    PASSWD=$4
    # Ajout de l'utilisateur
    callcurlsilent --request POST "$GLAPISERVER/users?email=$MAIL&username=$LOGIN&password=$PASSWD&name=$NAME"
}


function iterpages () {
    PAGE=$1
    COMMAND=showuserpage
    for i in $(seq 1 $PAGE); do
        $COMMAND $i
        echo
        # TODO: is there duplicates?
    done  | jq -s "flatten"
}

function itergroupepages () {
    PAGE=$1
    GROUP=$2
    COMMAND=showuserfromgrouppage
    for i in $(seq 1 $PAGE); do
        $COMMAND $GROUP $i
        echo
        # TODO: is there duplicates?
    done  | jq -s "flatten"
}


if VERBOSE=$VERBOSE GLAPITOKEN=$GLAPITOKEN GLAPISERVER=$GLAPISERVER glapi-testserver.sh ;
then echo -n;
else exit $?;
fi 


# glapi users add command
if [ "$ADDUSER" != "" ];
then
    addUtilisateur $USERNAME $USERLOGIN $USERMAIL $PASSWD;
    exit
fi

if [ "$SEARCH" = "yes" ];
   # defaut glapi users command: list users, we iterate on pages
then
    if [ "$USERNAME" != "" ];
    then
        if [ "$EXACTNAME" = "yes" ];
           then
               iterpages $PAGES | jq --arg USERNAME \
                                     "$USERNAME" '.[] | select(.name==$USERNAME)';
        else # regexp case insensitive
            iterpages $PAGES | jq --arg USERNAME \
                                  "$USERNAME" '.[] | select(.name | test($USERNAME;"i"))';
        fi
    else if [ "$USERID" != "" ];
         then # --argjson here --arg build a string
             iterpages $PAGES | jq --argjson USERID $USERID '.[] | select(.id==$USERID)';
             
         else if [ "$GROUP" = "" ];
              then 
                  COMMAND=iterpages
              else
                  COMMAND="showuserfromgrouppage $GROUP"
              fi
              $COMMAND $PAGES
              exit 0;
         fi
    fi
else
    echo no command found
    echo $USAGE
    exit 1
fi

