<p align="left">
  <a href="README.md"><img src="assets/logo.svg" width="48" alt="ssh-wrappers" align="left" style="margin-right:14px"></a>
</p>

# `sshq` — quiet/quick (skip host key checks)

```sh
sshq() {
    ssh -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR \
        "$@"
}
```

## What it does

Three options, working together:

- `StrictHostKeyChecking=no` — accept the server's host key without prompting.
- `UserKnownHostsFile=/dev/null` — don't write the key to `~/.ssh/known_hosts`, and don't notice if it changes next time.
- `LogLevel=ERROR` — silence the `Warning: Permanently added 'X' to the list of known hosts` notice and the `Warning: Identity file ... not accessible` chatter.

The combined effect: connect to a brand-new host without any prompts, banners, or `known_hosts` pollution.

## When to use it

- Spinning up cloud VMs (EC2, GCE, fly.io, hetzner, droplets) where the host key is generated fresh each time.
- CI runners and ephemeral build hosts.
- Lab gear, switches, IPMI / iDRAC / iLO consoles whose keys rotate or aren't worth tracking.
- Test rigs, containers, vagrant boxes, anywhere the host's identity is genuinely meaningless to your threat model.

## Security tradeoff (read this)

`sshq` **disables a real protection against man-in-the-middle attacks.** The whole point of host key verification is to detect when something is impersonating the host you think you're connecting to. With `sshq`, you get no warning if the server's identity has changed — you just connect.

Don't use `sshq` for:

- Production servers you connect to repeatedly.
- Anything that handles credentials, customer data, or production state.
- Networks you don't trust (public Wi-Fi, untrusted upstreams).

Use plain `ssh` (or `sshi`) for those, and let host key verification do its job.

## Usage

```sh
sshq ec2-user@$(terraform output -raw bastion_ip)
sshq -i ~/.ssh/lab_ed25519 root@switch.lab
sshq runner@ci-host 'tail -f /var/log/build.log'
```

## Notes

- If you find yourself wanting `sshq` behavior for a whole IP range, prefer per-host config in `~/.ssh/config`:

  ```sshconfig
  Host 10.42.* lab-* *.ec2.internal
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null
      LogLevel ERROR
  ```

  That's safer because it scopes the relaxation to known-ephemeral hosts, instead of you having to remember which `ssh` invocation gets the relaxed treatment.

- `StrictHostKeyChecking=accept-new` (modern OpenSSH) is a middle ground: accept a key on first sight without prompting, but still detect changes afterward. If you only want to skip the first-connect prompt, that's a better default than `sshq`.
