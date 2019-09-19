#!/bin/bash

BINDIRECTORY=$(cd `dirname $0` && pwd)

V3=
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -v3)
        V3=yes
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
if [ "$V3" = "yes" ];
then URL="$2/api/v3"; # FIXME, remove trialing '/' to URL
fi

# No quotes here so that $1 and $2 get evaluated
echo alias glapi="'GLAPITOKEN=$TOKEN GLAPISERVER=$URL PATH=$BINDIRECTORY:$PATH glapi.sh'"

