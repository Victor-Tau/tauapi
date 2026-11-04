#!/usr/bin/env bash
# Read-only host preflight: OS, resources, ports, DNS, permissions, egress.
# Usage: preflight.sh            (no root needed; uses sudo -n where available)
# Exit codes: 0 all required checks ok, 1 one or more required checks failed.
set -uo pipefail
DOMAIN=api.victor-tau.xyz
fail=0
ok()   { printf '  [ok]   %s\n' "$*"; }
warn() { printf '  [warn] %s\n' "$*"; }
bad()  { printf '  [FAIL] %s\n' "$*"; fail=1; }

echo "== system"
. /etc/os-release; [[ $VERSION_ID == 24.04 ]] && ok "$PRETTY_NAME" || warn "$PRETTY_NAME (target is 24.04)"
ok "arch $(uname -m), cpus $(nproc)"
mem=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo); swap=$(awk '/SwapTotal/{print int($2/1024)}' /proc/meminfo)
(( mem >= 3500 )) && ok "RAM ${mem} MiB, swap ${swap} MiB" || warn "RAM ${mem} MiB (<4 GiB planning baseline), swap ${swap} MiB"
avail=$(df --output=avail -BG / | tail -1 | tr -dc 0-9); (( avail >= 10 )) && ok "disk free ${avail}G" || bad "disk free ${avail}G"
ok "inodes used $(df --output=ipcent / | tail -1 | tr -d ' ')"
timedatectl show -p NTPSynchronized --value 2>/dev/null | grep -qx yes && ok "NTP synchronized" || warn "NTP not (yet) synchronized"

echo "== access"
ok "user $(id -un) groups $(id -Gn)"
sudo -n true 2>/dev/null && ok "passwordless sudo" || warn "sudo requires a password (use SUDO_ASKPASS)"
id -nG | grep -qw docker && warn "user is in docker group (root-equivalent)" || ok "user not in docker group"

echo "== ports"
for p in 22 80 443 3001 3002 5432 6379 8443; do
  l=$(ss -Htln "( sport = :$p )" | awk '{print $4}' | sort -u | tr '\n' ' ')
  [[ -n $l ]] && echo "  :$p -> $l" || echo "  :$p free"
done
ss -Htln | awk '{print $4}' | grep -E '^(0\.0\.0\.0|\[::\]):(3001|3002|5432|6379)$' && bad "backend/DB port bound publicly" || ok "no public backend/DB bindings"

echo "== dns / reachability"
a=$(dig +short A $DOMAIN | tr '\n' ' '); aaaa=$(dig +short AAAA $DOMAIN | tr '\n' ' ')
pub=$(curl -4 -s --max-time 5 https://ifconfig.me || true)
[[ -n $a ]] && ok "A $a" || bad "no A record"
[[ -n $aaaa ]] && warn "AAAA $aaaa (must be verified)" || ok "no AAAA record"
[[ " $a " == *" $pub "* ]] && ok "A matches public egress $pub" || warn "A ($a) != egress ($pub): CDN/NAT?"
c=$(curl -s -o /dev/null -w '%{http_code}' --max-time 8 http://$DOMAIN/.well-known/acme-challenge/preflight-probe); ok "http ACME path -> $c (404 expected without file)"

echo "== egress"
for u in https://github.com https://proxy.golang.org https://registry.npmjs.org https://registry-1.docker.io/v2/ https://acme-v02.api.letsencrypt.org/directory; do
  c=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$u"); [[ $c =~ ^(200|301|302|401)$ ]] && ok "$u $c" || bad "$u $c"
done

echo "== software"
for b in docker certbot git jq rsync python3; do command -v $b >/dev/null && ok "$b $($b --version 2>&1 | head -1 | cut -c1-60)" || warn "$b missing"; done
command -v nginx >/dev/null && ok "nginx $(nginx -v 2>&1 | cut -d/ -f2)" || warn "nginx missing"
exit $fail
