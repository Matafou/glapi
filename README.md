# glapi
Gitlab API from bash (based on jq)

# How to execute glapi?

## USING ENVIRONMENT VARIABLES

GLAPITOKEN should contain your gitlab token

GLAPISERVER shoud contain the http(s) address of the gitlab server.

then you can do:

```bash
glapi.sh <command>
```

## USING the `glapi` alias:
### First define the alias!
```bash
alias glapi="'GLAPITOKEN=<yourtoken> GLAPISERVER=<serveraddress> glapi.sh'"
```

This part can be done using the glapi-env.sh script, for instance like this
```bash
eval $(~/src/glapi/glapi-env.sh -v3 "XYZKLKFZELMFJSDL" "https://gitlab...."
```
Note that this way you don't need to add `~/src/glapi/` to your path
provided that gmapi-env.sh is in the same directory thant the other
glapi script


### Then use glapi:
```bash
glapi <command>
```


