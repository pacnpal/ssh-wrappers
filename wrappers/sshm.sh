# sshm — multiplex: first connection opens a master, subsequent connections
# to the same host:port:user reuse it for ~instant attach. Master persists
# 10 minutes after the last client exits.
sshm() {
    ssh -o ControlMaster=auto \
        -o ControlPath="$HOME/.ssh/cm-%r@%h:%p" \
        -o ControlPersist=10m \
        "$@"
}
