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
    callcurl "$GLAPISERVER/users" --head 2<&1 | grep --quiet "Status\: 200 OK"
    echo "$?"
}

function showshortlog () {
    callcurl "$GLAPISERVER/users" --head 2<&1  | grep "Status\\|PRIVATE-TOKEN\\|http\\|host\\|Could not resolve"
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

if [ $RETCODE = "0" ];
then
    if [ "$VERBOSE" = "yes" ];
    then 
        echo server and credentials seem OK;
        echo GLAPITOKEN = $GLAPITOKEN >&2 
        echo GLAPISERVER = $GLAPISERVER >&2 
    fi
    exit 0;
else
    echo Ops! server and/or credentials seem wrong: >&2 
    echo GLAPITOKEN = $GLAPITOKEN >&2 
    echo GLAPISERVER = $GLAPISERVER >&2 
    showshortlog 1>&2 
    exit $RETCODE
fi


