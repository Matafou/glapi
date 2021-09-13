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

ADDTOGROUP=
USERID=

USAGE="
SYNTAX:
[GLAPITOKEN=<token> GLAPISERVER=<url>] glapi-groups.sh [options] command
SIMPLER SYNTAX:
glapi groups [options] command
(see glapi-env.sh to use this second syntax)

COMMANDS:

- search <options for search> prints the json description of the
                              corresponding groups
- searchid <id> -name \"name\"  prints the id of the group named exactly
                              \"name\"  
- adduser <id> -name \"groupname\" adds user with id <id> in group <groupname>
- adduserbyname <userlogin> -name <groupname>   
                             adds user with login name <userlogin> in group
                             <groupname>
- help                       show help

OPTIONS:
  -h or --help show help

OPTIONS FOR SEARCH:
  -name <name> look for the name <name>
  -id <id>     look fir the id <id>
  -exact the search will be an exact search instead of regexp case
         insensitive matching.

EXAMPLES:
   adduserbyname foo -name group_bar
      adds user with login name foo to group named group_bar
"

# TODO: verbose + dryrun
# TODO: ask for confirmation when about to send possibly harmful queries

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    search)
        SEARCH=yes
        shift
        ;;
    searchid)
        SEARCHID=yes
        shift
        ;;
    adduser)
        ADDTOGROUP=yes
        USERID="$2"
        shift
        shift
        ;;
    adduserbyname)
        ADDTOGROUP=yes
        USERNAME="$2"
        shift
        shift
        ;;
    -list) # bash_complete-friendly list of command names
        echo "search searchid adduser adduserbyname help"
        exit 0
        ;;
    -h|--help|help)
        echo "$USAGE"
        exit
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

. $BINDIRECTORY/glapi-functions.sh


function addMemberToGroupById () {
    THEUSERID="$1"
    THEGROUPNAME="$2"
    callcurlsilent --request POST --data "user_id=$THEUSERID&access_level=30" "$GLAPISERVER/groups/$THEGROUPNAME/members" 2>&1
}

function addMemberToGroupByName () {
    THEUSERNAME="$1"
    THEGROUPNAME="$2"
    # cancel dryrun just for this search, so that we get a good id
    USERID=$(DRYRUN="" findUserIdByUsername $1)
    addMemberToGroupById $USERID $THEGROUPNAME
}



if glapi-testserver.sh ;
then echo -n;
else exit $?;
fi 

if [ "$SEARCHID" = "yes" ];
then
    if [ "$GROUPNAME" != "" ];
    then
        echo $(findGroupId $GROUPNAME)
    else
        echo empty group name
        exit 0;
    fi
fi

if [ "$SEARCH" = "yes" ];
then
    if [ "$GROUPNAME" != "" ];
    then
        if [ "$EXACTNAME" = "yes" ];
        then
            itergroupspages $PAGES | jq --arg GROUPNAME \
                                  "$GROUPNAME" '.[] | select(.name==$GROUPNAME)';
        else # regexp case insensitive
            itergroupspages $PAGES | jq --arg GROUPNAME "$GROUPNAME" '.[] | select(.name | test($GROUPNAME;"i"))';
        fi
    else
        if [ "$GROUPID" != "" ];
        then itergroupspages $PAGES | jq --argjson GROUPID $GROUPID '.[] | select(.id==$GROUPID)';
        fi
    fi
    exit 0;
fi

if [ "$PRINTUNAMES" = "yes" ] ;
then
   iterpages $PAGES
   exit 0
else echo ;
fi

if [ "$ADDTOGROUP" = "yes" ] ;
then
    if [ "$GROUPNAME" != "" ];
    then
        if [[ "$USERID" == "" && "$USERNAME" != "" ]]
        then
            USERID=$(DRYRUN="" findUserIdByUsername $USERNAME)
        fi
        echo -n "About to add user $USERNAME (id=[$USERID]) in group $GROUPNAME with access level 30. "
        if confirm ;
        then addMemberToGroupById $USERID $GROUPNAME
        else 
            echo aborting
            exit;
        fi
    else
        if [ "$GROUPID" == "" ];
        then
           echo ERROR: empty group name or ID
           exit 1
        else
            echo "About to add user $USERID in group $GROUPID with access level 30. "
            echo "adding by group ID is not yet implemented. Use -name <the exact name of the group> instead."
            exit 1
        fi
    fi
fi
echo

