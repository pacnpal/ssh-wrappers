# sshc — enable compression. Worth it on slow / high-latency links and
# for transferring lots of text (logs, stdout from remote builds).
# Wasteful on fast LANs and for already-compressed data.
sshc() {
    ssh -C "$@"
}
