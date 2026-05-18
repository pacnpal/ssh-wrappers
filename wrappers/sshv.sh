# sshv — verbose debug (-vvv). Use when ssh isn't connecting and you
# need to see auth method offers, key matching, kex/cipher negotiation.
sshv() {
    ssh -vvv "$@"
}
