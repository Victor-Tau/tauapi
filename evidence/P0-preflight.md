# P0 preflight (2026-11-04, UTC)

- OS: Ubuntu 24.04.5 LTS, x86_64, 4 vCPU, RAM 3.8 GiB, swap 0 → 4 GiB /swapfile added
- Disk /: 49G total, ~30G free; inodes 6% used
- User: tau (uid 1000, sudo group, password sudo); not in docker group
- SSH: 0.0.0.0:22 / [::]:22 (unchanged); UFW inactive (not modified)
- Ports before work: 80/443/3001/3002 free; only sshd, systemd-resolved, VS Code server on loopback
- Docker 29.9.3 + Compose v5.7.0 pre-installed; no containers, no volumes
- Nginx: not installed initially → apt nginx 1.24.0; default site replaced by maintenance/ACME-only bootstrap
- Time: NTP service active; set-ntp true (sync pending at check time)
- DNS: api.victor-tau.xyz A = 154.94.236.190; AAAA = none; public IPv4 egress = 154.94.236.190 (host NAT 10.0.95.2) → no CDN
- IPv6: no global IPv6 on host and no AAAA record → IPv6 not applicable
- Public reachability: http://api.victor-tau.xyz → 200 (default nginx) then 503 maintenance; ACME probe 200
- Egress: github.com, proxy.golang.org, registry.npmjs.org, go.dev, registry-1.docker.io, acme-v02.api.letsencrypt.org, bun.sh all reachable
- Existing data: /opt empty except newapi, /srv empty, no DB/Redis installed → fresh host, nothing to isolate
