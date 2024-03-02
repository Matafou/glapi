# glapi
Gitlab API from bash (based on jq).

# Dependencies:

You need to have the `jq` bash library installed on your system

# How to execute glapi?

## USING ENVIRONMENT VARIABLES

GLAPITOKEN should contain your gitlab token

GLAPISERVER shoud contain the http(s) address of the gitlab server.

then you can do:

```bash
glapi.sh command
```


## USING the `glapi` alias:
### First define the alias!
```bash
alias glapi='GLAPITOKEN=yourtoken GLAPISERVER=serveraddress/api/v4 glapi.sh'
```

This part can be done using the glapi-env.sh script, for instance like this
```bash
eval $(~/src/glapi/glapi-env.sh -v4 "XYZKLKFZELMFJSDL" "https://gitlab...."
```
(-v4 is currently the supported version of gitlab api. v3 may still work)

Note that this way you don't need to add `~/src/glapi/` to your path
provided that gmapi-env.sh is in the same directory thant the other
glapi script


### Then use glapi:
```bash
glapi command
```

# How to use glapi?

The three script `glapi-groups.sh` `glapi-users.sh` `glapi-utils.sh`
can be called directly or via `glapi` (or `glapi.sh` if you did not
define the alias above).

For instance:

```
glapi users -group foo
```

will call `glapi-users.sh -group foo`, which displays all the users of group foo.

To display the help of a command, use the `-h` option:
```
glapi users -h
```

# EXAMPLES

```
glapi users search -group foo
glapi users search -name foo
```

# bash completion

Add this to you .bashrc to have command and sub-command completion.:

```
function _complete_glapi (){

    local suggestions=
    if [[ ("$COMP_CWORD" == 2 ) && ("${COMP_WORDS[1]}" == "groups" ) ]];
    then
        suggestions=($(compgen -W "$(glapi groups -list)" -- "${COMP_WORDS[2]}"))
    elif [[ ("$COMP_CWORD" == 2 ) && ("${COMP_WORDS[1]}" == "users" ) ]];
    then
        suggestions=($(compgen -W "$(glapi users -list)" -- "${COMP_WORDS[2]}"))
    elif [[ ("$COMP_CWORD" == 2 ) && ("${COMP_WORDS[1]}" == "projects" ) ]];
    then
        suggestions=($(compgen -W "$(glapi projects -list)" -- "${COMP_WORDS[2]}"))
    elif [[ ("$COMP_CWORD" == 1 ) ]];
    then
        suggestions=($(compgen -W "$(glapi -list)" -- "${COMP_WORDS[1]}"))
    else
        return
    fi
    COMPREPLY=("${suggestions[@]}")
}

complete -F _complete_glapi  glapi
```
