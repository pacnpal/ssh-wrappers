# sshk — keepalive: send a probe every 30s, drop after 4 missed probes.
# Stops "client_loop: send disconnect: Broken pipe" on idle sessions.
sshk() {
    ssh -o ServerAliveInterval=30 \
        -o ServerAliveCountMax=4 \
        -o TCPKeepAlive=yes \
        "$@"
}
