# sshp — force password authentication (disable pubkey for one connection)
sshp() {
    ssh -o PubkeyAuthentication=no "$@"
}
