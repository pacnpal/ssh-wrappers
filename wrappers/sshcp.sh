# sshcp — push a key with ssh-copy-id but skip pubkey auth so the
# agent's loaded keys don't burn through MaxAuthTries before the
# password prompt. The whole reason you're running ssh-copy-id is that
# you don't have a key on the remote yet — offering ones it won't
# accept just wastes attempts.
sshcp() {
    ssh-copy-id -o PubkeyAuthentication=no "$@"
}
