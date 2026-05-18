# ssht — force a pseudo-terminal. Needed for interactive remote commands
# like sudo, htop, vim when run as `ssh host <cmd>`.
ssht() {
    ssh -t "$@"
}
