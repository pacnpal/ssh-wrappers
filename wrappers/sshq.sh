# sshq — quiet/quick: skip host key prompts and don't pollute known_hosts.
# Use for ephemeral hosts (cloud VMs, CI runners, lab gear). NOT for prod —
# this disables a real protection against man-in-the-middle attacks.
sshq() {
    ssh -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR \
        "$@"
}
