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
LISTMEMBERS=
SEARCH=
EXACTNAME=
GROUPID=
GROUPNAME=
PROJECTNAME=
PROJECTID=


USAGE="
SYNTAX:
[GLAPITOKEN=<token> GLAPISERVER=<url>] glapi-projects.sh [options] command
glapi projects [options] command
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
    adduserbyname)
        ADDUSERBYNAME=yes
        shift
        USERNAME="$1"
        shift
        PROJECTNAME="$1"
        shift
        ;;
    search)
        SEARCH=yes
        shift
        ;;
    searchid)
        SEARCHID=yes
        shift
        ;;
    listmembers)
        LISTMEMBERS=yes
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

. $BINDIRECTORY/glapi-functions.sh

# Create a project named $1 inside group having groupID $2 (numerical id)
function createProject () {
    PROJ_NAME=$1
    GROUPID=$2
    # 2>&1 | grep "Status:"
    callcurl -X POST "$GLAPISERVER/projects?name=$PROJ_NAME&namespace_id=$GROUPID"
}

function addMemberToProjectById () {
    USERID="$1"
    PROJECTNAME="$2"
    PROJECTID=$(DRYRUN="" findProjectId $PROJECTNAME)
    callcurl --request POST --data "user_id=$USERID&access_level=40" "$GLAPISERVER/projects/$PROJECTID/members" 2>&1
}

function addMemberToProjectByName () {
    THEUSERNAME="$1"
    PROJECTNAME="$2"
    # cancel dryrun just for this search, so that we get a good id
    THEUSERID=$(DRYRUN="" findUserId $1)
    addMemberToProjectById $THEUSERID $PROJECTNAME
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
    addMemberToProjectById $USERID $PROJECTNAME ;
    exit
fi


# We need a group name if the project is in a group, otherwise the url
# is not correct
if [ "$ADDUSERBYNAME" != "" ] ;
then
    addMemberToProjectByName $USERNAME $PROJECTNAME ;
    exit
fi

if [ "$LISTMEMBERS" != "" -a "$PROJECTID" != "" ] ;
then
    callcurlsilent $GLAPISERVER/projects/$PROJECTID/members
    exit
fi

# Needs exact name
if [ "$SEARCHID" != "" ] ;
then
    if [ "$PROJECTNAME" != "" ] ;
    then
        echo $(findProjectId $PROJECTNAME)
        exit;
    else
        echo empty project name
        exit 0
    fi
fi

# when asking for the decription of a group, all projects of the group
# are displayed, there is no page/per_page flag.

if [ "$SEARCH" != "" ] ;
then
    if [ "$PROJECTID" != "" ] ;
    then
        callcurlsilent $GLAPISERVER/projects/$PROJECTID ;
        exit
    fi

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

