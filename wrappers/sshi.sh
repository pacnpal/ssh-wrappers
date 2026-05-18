# sshi — use only explicitly configured identities (IdentitiesOnly=yes)
sshi() {
    ssh -o IdentitiesOnly=yes "$@"
}
