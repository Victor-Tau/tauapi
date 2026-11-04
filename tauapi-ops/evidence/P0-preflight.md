# P0 预检(2026-11-04,UTC)

- 操作系统:Ubuntu 24.04.5 LTS,x86_64,4 vCPU,内存 3.8 GiB,swap 0 → 已添加 4 GiB /swapfile
- 磁盘 /:总计 49G,约 30G 可用;inode 已用 6%
- 用户:tau(uid 1000,sudo 组,sudo 需密码);不在 docker 组
- SSH:0.0.0.0:22 / [::]:22(未改动);UFW 未启用(未修改)
- 开工前端口:80/443/3001/3002 空闲;仅 sshd、systemd-resolved、VS Code server 监听回环地址
- Docker 29.9.3 + Compose v5.7.0 已预装;无容器,无卷
- Nginx:最初未安装 → 通过 apt 安装 nginx 1.24.0;默认站点已替换为维护页/仅 ACME 的引导配置
- 时间:NTP 服务已启用;set-ntp true(检查时同步尚未完成)
- DNS:api.victor-tau.xyz A = 154.94.236.190;AAAA = 无;公网 IPv4 出口 = 154.94.236.190(主机 NAT 10.0.95.2)→ 无 CDN
- IPv6:主机无全局 IPv6 且无 AAAA 记录 → IPv6 不适用
- 公网可达性:http://api.victor-tau.xyz → 200(默认 nginx)随后 503 维护页;ACME 探测 200
- 出站:github.com、proxy.golang.org、registry.npmjs.org、go.dev、registry-1.docker.io、acme-v02.api.letsencrypt.org、bun.sh 均可访问
- 既有数据:本项目之前 /opt 为空,/srv 为空,未安装 DB/Redis → 全新主机,无需隔离
