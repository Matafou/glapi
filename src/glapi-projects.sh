#!/bin/bash
BINDIRECTORY=$(cd `dirname $0` && pwd)

DRYRUN=
VERBOSE=""

PRINTNAMES=
PRINTIDS=
PAGES=9

ADDPROJECT=
FORKPROJECT=
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
PROTECTEDBRANCH=

USAGE="
SYNTAX:
  [GLAPITOKEN=<token> GLAPISERVER=<url>] glapi-projects.sh [options] command
ALTERNATE SYNTAX (see glapi-env.sh to use this second syntax):
  glapi projects [options] command


COMMANDS:
- create <projname> <projgroupID>       create a project
- fork <initialprojid> <projname> <projgroupID>       create a project by forking another
- adduser <userID> <exact project name>      add a user to a project
- adduserbyname <username> <exact project name>      add a user to a project by its username
- search <options for search>           search projects
- searchid <options for search>         Implies -exact. Search projects and
                                        display its id.
- listmembers <options for search>      search a project and list it members
                                        project must be unique
- protectedbranch -id <project id>      list protected branches of project id (id mandatory)
- help                                  show help

OPTIONS:
  -h or --help             show help
  -v                       verbose mode
  -n                       dry run, show the curl query, do not execute it.
                           NOT APPLICABLE TO SEARCH command.

OPTIONS FOR SEARCH:
  -group <name>  search often needs the groupe name otherwise some
  -name <name>
  -id <id>
  -exact the search will be an exact search instead of regexp case
         insensitive matching.

EXAMPLE:
  # obtain all project whose name matches fip1_tp3, and then filter
  # those created in 2019 sept.

glapi projects search -name \"fip1_tp3\"  | jq -r '. | select(.created_at | test(\"2016\";\"i\")) | .name'
# fork project 302 into group 525
glapi projects fork 302 testproj 525
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
    fork) # todo: faire du projectgroupid un arg optionnel
        FORKPROJECT=yes
        shift
        PROJECTID="$1"
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
    protectedbranch)
        PROTECTEDBRANCH=yes
        shift
        ;;
    -list) # bash_complete-friendly list of command names
        echo "create fork adduser adduserbyname search searchid listmembers protectedbranch help"
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
    callcurl -X POST "$GLAPISERVER/projects/:id/fork?name=$PROJ_NAME&namespace_id=$GROUPID"
}

# fork an existing project of id $1 inside group having groupID $3
# (numerical id) the name is $2, and it is also the path of the forked
# project afterward. It seemshowever that the fork is first done with
# the path of the original projet and then repathed, this may give
# errors (path already taken) if there already exists a project with
# this path.
function forkProject () {
    INITIALPROJ_NAME=$1
    PROJ_NAME=$2
    GROUPID=$3
    # 2>&1 | grep "Status:"
    callcurl -X POST "$GLAPISERVER/projects/$INITIALPROJ_NAME/fork?name=$PROJ_NAME&namespace_id=$GROUPID&path=$PROJ_NAME"
}

# level 30 = developper
function addMemberToProjectById () {
    USERID="$1"
    PROJECTNAME="$2"
    PROJECTID=$(DRYRUN="" findProjectId $PROJECTNAME)
    callcurl --request POST --data "user_id=$USERID&access_level=30" "$GLAPISERVER/projects/$PROJECTID/members" 2>&1
}

function addMemberToProjectByUsername () {
    THEUSERNAME="$1"
    PROJECTNAME="$2"
    # cancel dryrun just for this search, so that we get a good id
    THEUSERID=$(DRYRUN="" findUserIdByUsername $1)
    addMemberToProjectById $THEUSERID $PROJECTNAME
}

function listMembers () {
    PROJECTID="$1"
    callcurlsilent "$GLAPISERVER/projects/$PROJECTID/members" 2>&1
}

function listMembersByName () {
    PROJECTNAME="$1"
    PROJECTID=$(DRYRUN="" findProjectId $PROJECTNAME)
    listMembers $PROJECTID
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

if [ "$FORKPROJECT" != "" ] ;
then
    forkProject $PROJECTID $PROJECTNAME $PROJECTGROUPID ;
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
    addMemberToProjectByUsername $USERNAME $PROJECTNAME ;
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
        echo $(DRYRUN="" findProjectId $PROJECTNAME)
        exit;
    else
        >&2 echo empty project name
        exit 0
    fi
fi

# Needs exact name
if [ "$LISTMEMBERS" != "" ] ;
then
    if [ "$PROJECTNAME" != "" ] ;
    then
        echo $(listMembersByName $PROJECTNAME)
        exit;
    else
        if [ "$PROJECTID" != "" ] ;
        then
            echo $(listMembers $PROJECTID)
            exit 0;
        else
            >&2 echo empty project name
            exit 1
        fi
    fi
fi

if [ "$PROTECTEDBRANCH" != "" ] 
then
    if [ "$PROJECTNAME" != "" ] ;
    then
        >&2 echo "protectedbranch needs a projetc id"
        exit 1
    else
        if [ "$PROJECTID" != "" ] ;
        then
            listProtectedBranch $PROJECTID
        else
            >&2 echo empty project name
            exit 1
        fi
    fi
fi


# when asking for the decription of a group, all projects of the group
# are displayed, there is no page/per_page flag.
# TODO, determine what to do when too much names/ids are given.
if [ "$SEARCH" != "" ] ;
then
    if [ "$PROJECTID" != "" ] ;
    then
        callcurlsilent $GLAPISERVER/projects/$PROJECTID | jq -r '.'
        exit
    fi
    if [ "$GROUPNAME" = "" -a "$PROJECTNAME" = "" -a "$PROJECTID" = "" ] ;
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
                | jq  --arg PROJECTNAME "$PROJECTNAME" '.[] | select(.name | test($PROJECTNAME;"i")?)';
            exit
        fi
    fi
fi

echo

