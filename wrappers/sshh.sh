# sshh — show what ssh-wrappers are installed, what each does, and an
# example. `sshh <name>` for one wrapper, `sshh` for everything.
sshh() {
    _sshh_data='sshp|auth|force password auth (disable pubkey)|sshp user@host
sshi|auth|use only explicit identities (IdentitiesOnly=yes)|sshi -i ~/.ssh/work_ed25519 user@host
ssha|auth|forward your local ssh-agent (-A) — trusted hosts only|ssha bastion
sshcp|auth|ssh-copy-id without pubkey auth (skip MaxAuthTries burn)|sshcp user@host
sshq|trust|quick — skip host key checks (ephemeral hosts)|sshq ec2-user@10.0.0.42
sshk|conn|keepalive — do not drop on idle|sshk prod-host
sshm|conn|multiplex — instant subsequent reconnects|sshm work-bastion
ssht|i/o|force a TTY (sudo, htop, vim over ssh)|ssht user@host sudo systemctl restart x
sshc|i/o|compression (-C) for slow links and text streams|sshc host '\''tail -f build.log'\''
sshv|debug|verbose (-vvv) — see auth attempts and KEX|sshv user@host
sshh|meta|this help (run `sshh <name>` for detail)|sshh sshp'

    _sshh_b= _sshh_a= _sshh_g= _sshh_m= _sshh_r=
    if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
        _sshh_b=$(tput bold) _sshh_a=$(tput setaf 4) _sshh_g=$(tput setaf 2)
        _sshh_m=$(tput setaf 8) _sshh_r=$(tput sgr0)
    fi

    # Detail mode: sshh <name> [<name>...]
    if [ "$#" -gt 0 ]; then
        for _q in "$@"; do
            _line=$(printf '%s\n' "$_sshh_data" | awk -F '|' -v n="$_q" '$1==n {print; exit}')
            if [ -z "$_line" ]; then
                printf 'sshh: not a wrapper: %s (try: sshh)\n' "$_q" >&2
                continue
            fi
            _name=$(printf '%s' "$_line" | awk -F '|' '{print $1}')
            _cat=$(printf '%s' "$_line" | awk -F '|' '{print $2}')
            _desc=$(printf '%s' "$_line" | awk -F '|' '{print $3}')
            _ex=$(printf '%s' "$_line" | awk -F '|' '{print $4}')
            _status="${_sshh_m}not installed${_sshh_r}"
            if command -v "$_name" >/dev/null 2>&1; then
                _status="${_sshh_g}installed${_sshh_r}"
            fi
            printf '%s%s%s  %s[%s]%s  %s\n' \
                "$_sshh_b$_sshh_a" "$_name" "$_sshh_r" \
                "$_sshh_m" "$_cat" "$_sshh_r" "$_desc"
            printf '  status:   %s\n' "$_status"
            printf '  example:  %s%s%s\n' "$_sshh_m" "$_ex" "$_sshh_r"
            printf '  docs:     https://pacnpal.github.io/ssh-wrappers/docs/%s.md\n\n' "$_name"
        done
        unset _q _line _name _cat _desc _ex _status
        unset _sshh_data _sshh_b _sshh_a _sshh_g _sshh_m _sshh_r
        return
    fi

    # Overview mode
    printf '%sssh-wrappers%s  %ssmall POSIX shell wrappers around %sssh%s%s\n' \
        "$_sshh_b$_sshh_a" "$_sshh_r" \
        "$_sshh_m" "$_sshh_r$_sshh_m" "$_sshh_r" "$_sshh_m$_sshh_r"
    printf '%shttps://pacnpal.github.io/ssh-wrappers/%s\n\n' "$_sshh_m" "$_sshh_r"

    _yes=0; _no=0
    while IFS='|' read -r _w _cat _desc _ex; do
        [ -z "$_w" ] && continue
        if command -v "$_w" >/dev/null 2>&1; then
            _yes=$((_yes + 1))
            _mark="${_sshh_g}✓${_sshh_r}"
        else
            _no=$((_no + 1))
            _mark="${_sshh_m}·${_sshh_r}"
        fi
        printf '  %s  %s%-5s%s  %s%-8s%s  %s\n' \
            "$_mark" \
            "$_sshh_b" "$_w" "$_sshh_r" \
            "$_sshh_m" "[$_cat]" "$_sshh_r" \
            "$_desc"
    done <<EOSSHH
$_sshh_data
EOSSHH

    printf '\n  %s%d installed · %d not installed%s\n' "$_sshh_m" "$_yes" "$_no" "$_sshh_r"
    printf '\n%sDetail:%s     %ssshh <name>%s         e.g. %ssshh sshp%s\n' \
        "$_sshh_b" "$_sshh_r" "$_sshh_a" "$_sshh_r" "$_sshh_a" "$_sshh_r"
    if [ "$_no" -gt 0 ]; then
        printf '%sInstall more:%s curl -fsSL https://pacnpal.github.io/ssh-wrappers/install.sh | sh -s -- --force\n' \
            "$_sshh_b" "$_sshh_r"
    fi
    printf '%sUninstall:%s    curl -fsSL https://pacnpal.github.io/ssh-wrappers/install.sh | sh -s -- --uninstall\n' \
        "$_sshh_b" "$_sshh_r"

    unset _w _cat _desc _ex _yes _no _mark
    unset _sshh_data _sshh_b _sshh_a _sshh_g _sshh_m _sshh_r
}
