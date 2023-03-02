#!/bin/bash

BINDIRECTORY=$(cd `dirname $0` && pwd)

API_VERSION="noversion"
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -v3)
        API_VERSION=3
        shift # past argument
        ;;
    -v4)
        API_VERSION=4
        shift # past argument
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


TOKEN=$1
URL=$2
if [ "$API_VERSION" = "3" ];
then URL="$2/api/v3"; # FIXME, remove trialing '/' to URL
else
    if [ "$API_VERSION" = "4" ];
    then URL="$2/api/v4"; # FIXME, remove trialing '/' to URL
    else
        echo "No API version specified, exiting." 1>&2 
        exit 1
    fi
fi

# No quotes here so that $1 and $2 get evaluated
echo alias glapi="'GLAPITOKEN=$TOKEN GLAPISERVER=$URL PATH=$BINDIRECTORY:$PATH glapi.sh'"

