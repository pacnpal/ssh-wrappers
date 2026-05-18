# ssha — forward your local ssh-agent to the remote host so commands
# there (e.g. `git push`) can use your local keys without copying them.
# Only do this on hosts you trust — agent forwarding lets root on the
# remote impersonate you to anywhere your keys can reach.
ssha() {
    ssh -A "$@"
}
