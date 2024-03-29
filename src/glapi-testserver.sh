#!/bin/bash

BINDIRECTORY=$(cd `dirname $0` && pwd)

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -v)
        VERBOSE=yes
        shift # past argument
        ;;
    *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
esac
done


# Security, we test is VERBOSE is really set and put it to "" if not.
if [ -z "${VERBOSE+x}" ];
then
    VERBOSE="";
fi

# if [ -z ${VERBOSE+x} ]; then echo "var is unset"; else echo "var is set to '$VERBOSE'"; fi

set -- "${POSITIONAL[@]}" # restore positional parameters (i.e.
                          # parameters that were not recognized by the
                          # previous code.)

. $BINDIRECTORY/glapi-utils.sh


function testserver () {
    # v4 answers "HTTP/1.1 200 OK", whereas v3 answers "Status: 200 OK"
    callcurl "$GLAPISERVER/users" --head 2>&1 | grep --quiet "200 OK\\|HTTP/2 200"
    echo "$?"
}


function showshortlog () {
    callcurl "$GLAPISERVER/users" --head --include 2<&1  | grep "Status\\|PRIVATE-TOKEN\\|http\\|host\\|HTTP\\|Could not resolve"
}


if [ -z $GLAPITOKEN ];
then
    if [ "$VERBOSE" = "yes" ];
    then echo "No token defined, it should be stored in bash variable GLAPITOKEN."
    fi
    exit 1;
fi

if [ -z $GLAPISERVER ];
then    
    if [ "$VERBOSE" = "yes" ];
    then echo "No server url defined, it should be stored in bash variable GLAPISERVER."
    fi
    exit 1;
fi

RETCODE=$(testserver)

if [ "$RETCODE" = "0" ];
then
    if [ "$VERBOSE" = "yes" ];
    then 
        >&2 echo server and credentials seem OK;
        >&2 echo GLAPITOKEN = $GLAPITOKEN >&2 
        >&2 echo GLAPISERVER = $GLAPISERVER >&2 
    fi
    exit 0;
else
    >&2 echo Ops! server and/or credentials seem wrong: >&2 
    >&2 echo GLAPITOKEN = $GLAPITOKEN >&2 
    >&2 echo GLAPISERVER = $GLAPISERVER >&2 
    showshortlog 1>&2 
    exit 1
fi


