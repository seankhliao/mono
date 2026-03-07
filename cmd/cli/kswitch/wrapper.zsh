function kswitch() {
    # get a temporary file
    local evalFile=$(mktemp)
    command kswitch "${1}" -eval-file "${evalFile}" "${@:2}"
    # exec any commands we get
    eval "$(<"${evalFile}")"
    rm "${evalFile}"
}
