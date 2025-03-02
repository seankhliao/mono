function kswitch() {
    # get a temporary file
    local evalFile=$(mktemp)
    command kswitch -eval-file "${evalFile}" "$@"
    # exec any commands we get
    eval "$(<"${evalFile}")"
    rm "${evalFile}"
}
