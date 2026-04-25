<p align="left">
  <a href="README.md"><img src="assets/logo.svg" width="48" alt="ssh-wrappers" align="left" style="margin-right:14px"></a>
</p>

# `sshc` — compression

```sh
sshc() {
    ssh -C "$@"
}
```

## What it does

Wraps `ssh` with `-C`, which enables zlib compression of the data stream between client and server.

## When to use it

Compression is a tradeoff between bandwidth and CPU. It's a clear win when:

- The link is **slow or high-latency**: cellular tethering, hotel Wi-Fi, transcontinental hops, satellite, VPNs over flaky connections.
- The data is **highly compressible text**: streamed log output (`tail -f`, `journalctl`), remote builds, anything that pipes a lot of stdout.
- You're doing **rsync over ssh** (rsync's `-z` is the same idea, but `sshc` covers the case where you can't pass `-z` to the tool itself).

It's a clear loss when:

- The link is fast (gigabit LAN, VPC peering) — compression CPU exceeds the bandwidth saved.
- The data is already compressed (binaries, video, gzipped tarballs, encrypted blobs) — you pay CPU for ~zero compression.
- You're CPU-constrained on either end (small VMs, embedded gear).

## Usage

```sh
sshc user@host
sshc user@host 'journalctl -fu myapp.service'
sshc user@host 'tar c /var/log/myapp' | tar x
```

For large file transfers specifically, `rsync -avz user@host:src dst` will usually beat `sshc + scp` because rsync compresses *and* avoids re-transferring unchanged blocks.

## Notes

- For per-host opt-in via `~/.ssh/config`:

  ```sshconfig
  Host slow-link.example
      Compression yes
  ```

- Modern OpenSSH only supports zlib (and `zlib@openssh.com`) for compression. There's no choice of algorithm — it's on or off.

- If you're not sure whether compression helps for a given link, `time` it both ways with a representative payload. The answer is workload-specific.

- **Forgot the other wrappers?** Run [`sshh`](sshh.md) for a one-screen summary of what's installed and what each one does.
