function repos() {
    # get a temporary file
    local evalFile=$(mktemp)
    command repos -eval-file "${evalFile}" "$@"
    # exec any commands we get
    eval "$(<"${evalFile}")"
    rm "${evalFile}"
}
