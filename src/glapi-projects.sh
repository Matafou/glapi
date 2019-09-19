#!/bin/bash
BINDIRECTORY=$(cd `dirname $0` && pwd)

DRYRUN=
VERBOSE=""

PRINTNAMES=
PRINTIDS=
PAGES=9

ADDPROJECT=
PROJECTNAME=

ADDUSER=
USERID=

SEARCH=
EXACTNAME=
GROUPID=
GROUPNAME=
PROJECTNAME=
PROJECTID=


USAGE="
SYNTAX:
[GLAPITOKEN=<token> GLAPISERVER=<url>] glapi-projects.sh command
glapi projects command
(see glapi-env.sh to use this second syntax)

COMMANDS:
- create <projname> <projgroupID>
- adduser <userID> <projectnameID>
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
    create)
        ADDPROJECT=yes
        shift
        PROJECTNAME="$1"
        shift
        PROJECTGROUPID="$1"
        shift
        ;;
    adduser)
        ADDUSER=yes
        shift
        USERID="$1"
        shift
        PROJECTNAME="$1"
        shift
        ;;
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
    -names)
        PRINTNAMES=yes
        shift # past argument
        ;;
    -name)
        PROJECTNAME="$2";
        shift
        shift
        ;;
    -group)
        GROUPNAME="$2";
        shift
        shift
        ;;
    -groupid)
        GROUPID="$2";
        shift
        shift
        ;;
    -id)
        PROJECTID="$2";
        shift
        shift
        ;;
    -exact)
        EXACTNAME=yes
        shift
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


OTHEROPTIONS=$*

. $BINDIRECTORY/glapi-utils.sh

# Create a project named $1 inside group having groupID $2 (numerical id)
function createProject () {
    PROJ_NAME=$1
    GROUPID=$2
    # 2>&1 | grep "Status:"
    callcurl -X POST "$GLAPISERVER/projects?name=$PROJ_NAME&namespace_id=$GROUPID"
}

# this calls a command $1 times (with incremented page number)
# it recieves an array of group descriptions
function iterate () {
    PAGE="$1"
    shift
    COMMAND="$*"
    for i in $(seq 1 $PAGE); do
        $COMMAND $i
        echo
        # we flatten the different pages FIXME; there are repetitions
        # (only when listing groups, not users)
    done | jq -c -s 'flatten'

}

function listProjectsInGroup () {
    if [ -z $1 ];
    then
        echo I need a group name
    else
        GROUP=$1
        PAGE=$2
        # this return the information about the group
        callcurlsilent "$GLAPISERVER/groups/$GROUP"
        # we return the "projects" field only
    fi | jq '.projects'
}


function listProjectsInAll () {
    PAGE=$1
    shift
    callcurlsilent "$GLAPISERVER/projects?page=$PAGE&per_page=100"
}


function addMemberToGroupeById () {
    USERID="$1"
    PROJECTNAME="$2"
    callcurl --request POST --data "user_id=$USERID&access_level=40" "$GLAPISERVER/projects/$PROJECTNAME/members" 2>&1
}



if VERBOSE=$VERBOSE GLAPITOKEN=$GLAPITOKEN GLAPISERVER=$GLAPISERVER glapi-testserver.sh ;
then echo -n;
else exit $?;
fi 



if [ "$ADDPROJECT" != "" ] ;
then
    createProject $PROJECTNAME $PROJECTGROUPID ;
    exit
fi

if [ "$ADDUSER" != "" ] ;
then
    addMemberToGroupeById $USERID $PROJECTNAME ;
    exit
fi

# when asking for the decription of a group, all projects of the group
# are displayed, there is no page/per_page flag.

if [ "$SEARCH" != "" ] ;
then
    if [ "$GROUPNAME" = "" -a "$PROJECTNAME" = "" ] ;
    then
        iterate $PAGES listProjectsInAll
        exit
    fi
    if [ "$GROUPNAME" != "" -a "$PROJECTNAME" != "" ] ;
    then
        listProjectsInGroup $GROUPNAME \
            | jq  --arg PROJECTNAME "$PROJECTNAME" '.[] | select(.name | test($PROJECTNAME;"i"))';
        exit
    fi

    if [ "$GROUPNAME" != "" ] ;
    then
        listProjectsInGroup $GROUPNAME ;
        exit
    fi
    if [ "$PROJECTNAME" != "" ] ;
    then
        if [ "$EXACTNAME" != "" ];
        then
            iterate $PAGES listProjectsInAll \
                | jq --arg PROJECTNAME "$PROJECTNAME" '.[] | select(.name==$PROJECTNAME)'
            exit;
        else # regexp case insensitive
            iterate $PAGES listProjectsInAll \
                | jq  --arg PROJECTNAME "$PROJECTNAME" '.[] | select(.name | test($PROJECTNAME;"i"))';
            exit
        fi
    fi
fi

echo

