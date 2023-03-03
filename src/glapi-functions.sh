#!/bin/bash

# This function centralises glapi + jq functions to get informations
# from gitlab. Queries for modifying gitlab (add user or project etc)
# are dispatched in dedicated glapi-xxx.sh files.

# This file is only a library of functions, and is loaded by other
# files in glapi.

BINDIRECTORY=$(cd `dirname $0` && pwd)

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
    # >&2 echo "callcurlsilent \"$GLAPISERVER/users?per_page=100&page=$PAGE\""
    callcurlsilent "$GLAPISERVER/users?per_page=100&page=$PAGE"    
}


function showuserfromgrouppage () {
    PAGE=$2
    THEGROUP=$1
    # >&2 echo "callcurlsilent \"$GLAPISERVER/groups/$THEGROUP/members?per_page=100&page=$PAGE\""
    
    callcurlsilent "$GLAPISERVER/groups/$THEGROUP/members?per_page=100&page=$PAGE" | jq '.'
}


function showgroupspage () {
    PAGE=$1
    callcurlsilent "$GLAPISERVER/groups?per_page=100&page=$PAGE"
}


function listProjectsInGroup () {
    if [ -z $1 ];
    then
        >&2 echo I need a group name
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


function listProtectedBranch () {
    PROJECTID=$1
    callcurlsilent "$GLAPISERVER/projects/${PROJECTID}/protected_branches"
}

# Iter sur la liste de tous lesutilisateurs (dans la limite du nombre
# de $PAGE pages de 100 users)
function iterpages () {
    PAGE=$1
    COMMAND=showuserpage
    for i in $(seq 1 $PAGE); do
        $COMMAND $i
        # >&2 echo "$COMMAND $i"
        # TODO: is there duplicates?
    done  | jq -s "flatten"
}

# iter dans la liste des utilisateur d'un groupe
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

# iter dans la liste des groupes
function itergroupspages () {
    PAGE=$1
    COMMAND=showgroupspage
    for i in $(seq 1 $PAGE); do
        $COMMAND $i
        echo
        # we remove duplicates coming from reaching the last page
    done | jq -s "flatten"    
}

# iter dans la liste des projet
function iterprojectsspages () {
    PAGE=$1
    COMMAND=showprojectspage
    for i in $(seq 1 $PAGE); do
        $COMMAND $i
        echo
        # we remove duplicates coming from reaching the last page
    done | jq -s "flatten"    
}

# generic version
# TODO: replace all previous iterxxx by this one.
# this calls a command $1 times (with incremented page number)
# it recieves an array of group descriptions
function iterate () {
    PAGE="$1"
    shift
    COMMAND="$*" #all arguments but the first (shifted)
    for i in $(seq 1 $PAGE); do
        $COMMAND $i
        # echo " "
        # we flatten the different pages FIXME; there are repetitions
        # (only when listing groups, not users)
    done | jq -c -s 'flatten'
}

# looks for the user id of username $1. The username must be the exact
# username (not the "name". FIXME: This is also defined in
# glapi-users.sh, which is bad.
function findUserIdByUsername () {
    # $1: username
    # result: userid 
    iterpages $PAGES | jq --arg USERNAME $1 '.[] | select(.username==$USERNAME)' | jq '.id'
}

# looks for the user id of name $1. The username must be the exact username, i.e. the login.
# FIXME: This is also defined in glapi-users.sh, which is bad.

function findUserIdByName () {
    # $1: username
    # result: userid 
    iterpages $PAGES | jq --arg USERNAME $1 '.[] | select(.name==$USERNAME)' | jq '.id'
}

# looks for the user id of username $1. The username must be exact.
# FIXME: This is also defined in glapi-users.sh, which is bad.
function findGroupId () {
    # $1: group name
    # result: groupid 
    itergroupspages $PAGES | jq --arg GROUPNAME $1 '.[] | select(.name==$GROUPNAME)' | jq '.id'
}



# looks for the project of name exactly $1 and return its id. The name must be exact.
function findProjectId () {
    # $1: project name
    # result: projectid 
    # more than 2000 projects already, PAGES is not accurate
    iterate 20 listProjectsInAll \
        | jq --arg PROJECTNAME "$PROJECTNAME" '.[] | select(.name==$PROJECTNAME)' | jq '.id'
}
