# Universal Bash Configuration

> A modular Bash setup for Linux with **productivity tools**, **Git**, **Docker**, **network diagnostics**, and **system debugging**.

![Bash](https://img.shields.io/badge/shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)
![Linux](https://img.shields.io/badge/platform-Linux-FCC624?logo=linux&logoColor=black)
![License](https://img.shields.io/badge/license-MIT-blue)

---

## Features

| Area | Included |
|:---|:---|
| **Shell** | History, Readline, XDG directories, editor detection |
| **Navigation** | `..`, `...`, `up`, `mkcd`, Git root navigation |
| **Files** | Metadata, archives, backups, compression, checksums, HTTP server |
| **Search** | `fzf`, `fd`, `ripgrep` with fallbacks |
| **Networking** | Ports, DNS, routes, gateway, TCP and HTTP checks |
| **Debugging** | `strace`, `lsof`, `tcpdump`, process inspection |
| **System** | CPU, RAM, storage, mounts, hardware and diagnostics |
| **Services** | `systemctl` / `journalctl` helpers |
| **Docker** | Containers, logs, shell access, stats and cleanup guidance |
| **Git** | Repository, branch, remote and status helpers |
| **JSON** | Pretty-printing and validation with `jq` |
| **Prompt** | Optional `fastfetch`, `starship`, `zoxide` |

---

## Structure

```text
bashrc/
├── .bashrc
├── bashrc.d/
│   ├── aliases.bash
│   ├── functions.bash
│   ├── git.bash
│   ├── docker.bash
│   └── optional-tools.bash
├── install.sh
├── README.md
└── LICENSE
```

The root `.bashrc` is only the **bootstrap**. Feature code lives in `bashrc.d/`.

The modules are loaded in a fixed order, so functionality does not depend on wildcard or filesystem ordering.

---

## Installation

Clone or copy the project and run:

```bash
chmod +x install.sh
./install.sh
```

The installer provides a small terminal menu and automatically detects the Linux distribution family from `/etc/os-release`.

### Profiles

| Profile | Contents |
|:---|:---|
| **Core** | Base shell configuration and common Linux utilities |
| **Recommended** | Core + modern CLI, Git, JSON and Python tools |
| **Full** | Recommended + debugging, networking, hardware monitoring and Docker |
| **Config only** | Configuration only; no package installation |

> [!IMPORTANT]
> Before replacing an existing `~/.bashrc`, the installer automatically creates a timestamped backup.

Example:

```text
~/.bashrc.backup-20261006-173500
```

---

## Supported distributions

| Family | Examples | Package manager |
|:---|:---|:---|
| **Debian** | Debian, Ubuntu, Linux Mint, Pop!_OS, Kali | `apt` |
| **Fedora** | Fedora, RHEL, Rocky, AlmaLinux, CentOS | `dnf` |
| **Arch** | Arch Linux, Manjaro, EndeavourOS, Garuda | `pacman` |

The installer maps the distribution to a package-manager family rather than depending on a single distribution name.

> [!NOTE]
> The configuration itself does not depend on the installer. You can copy `.bashrc` and `bashrc.d/` manually to another Linux system.

---

## First commands to run

After installation:

```bash
source ~/.bashrc
bashhelp
bashcheck
bashrc_status
```

`bashcheck` verifies core commands and installed modules. `bashrc_status` verifies the installed module files.

---

## Useful examples

### Navigation

```bash
up 3
mkcd ~/projects/test
croot
```

### Files

```bash
fileinfo image.iso
findfile '.conf' ~/.config
findtext 'TODO' .
extract archive.tar.gz
compress project
backup important.conf
serve 8000
```

### Networking

```bash
localips
gateway
routeinfo 1.1.1.1
ports
portcheck localhost 25565
dns example.com
dnsrecord example.com MX
dnscheck example.com
httpcheck https://example.com
netcheck 1.1.1.1
```

### Processes and debugging

```bash
proc ssh
pidinfo 1234
proctree
portprocess 25565
connections
tracefiles ls
tracenet curl https://example.com
```

### System

```bash
cpu
mem
diskfree
diskusage ~
big ~/Downloads
mounts
hardware
errors
diagnose
```

### systemd

```bash
failed
svc ssh
jerrors
jerrors-prev
journalgrep 'failed'
```

### Docker

```bash
dps
dpsa
dlog my-container
dlogf my-container
dexec my-container
dstats
dspace
drestart my-container
dprune
```

> [!WARNING]
> Commands such as `dclean`, `docker system prune`, `lsof`, and `tcpdump` can have significant effects or require elevated privileges. Review destructive cleanup commands before running them.

### Git

```bash
gitwhere
gitsummary
gitlast 10
gituntracked
gitremote
gitignored
```

### JSON

```bash
json data.json
cat data.json | jsonpipe
jsoncheck data.json
```

---

## Optional tools

The shell remains usable when these programs are missing. Functions are **not silently removed**; they instead report the dependency when called.

| Tool | Purpose |
|:---|:---|
| `eza` | Modern directory listing |
| `bat` / `batcat` | Syntax-highlighted file viewer |
| `fd` / `fdfind` | Fast file discovery |
| `fzf` | Interactive fuzzy selection |
| `rg` | Fast recursive search |
| `jq` | JSON processing |
| `zoxide` | Smarter directory navigation |
| `starship` | Shell prompt |
| `fastfetch` | System summary on shell startup |
| `lsof` | Open files and sockets |
| `strace` | System-call tracing |
| `tcpdump` | Packet capture |
| `dig` / `nslookup` | DNS diagnostics |
| `nc` | TCP port testing |
| `docker` | Container management |
| `git` | Version control |
| `systemctl` / `journalctl` | Service and journal diagnostics |

On Debian-family systems, the configuration automatically supports the common binary-name differences:

```text
bat  → batcat
fd   → fdfind
```

---

## Package groups

### Required

```text
bash
bash-completion
coreutils
findutils
grep
sed
gawk
tar
gzip
bzip2
xz
util-linux
procps
iproute2
hostname
ping utilities
```

### Helpful

```text
curl
wget
less
file
unzip
7zip
tree
fzf
ripgrep
bat
fd / fdfind
zoxide
jq
git
python3
```

### Add-ons

```text
eza
starship
fastfetch
lsof
strace
tcpdump
psmisc
netcat
DNS utilities
traceroute
mtr
sysstat
htop
btop
iotop
pciutils
usbutils
lshw
Docker
```

Exact package names are distribution-specific; `install.sh` maps them automatically for the supported families. For example, Debian stable currently provides `docker.io`, Arch provides `docker`, and Fedora provides the Moby Engine package used by the installer. citeturn672129search12turn672129search5turn996332search3

---

## Function reference

<details>
<summary><strong>Navigation & files</strong></summary>

| Command | Description |
|:---|:---|
| `up N` | Move up N directories |
| `mkcd DIR` | Create and enter a directory |
| `croot` | Enter the current Git repository root |
| `fileinfo` | Show file metadata |
| `findfile` | Find files/directories by name |
| `fdall` | Find files with `fd`/`fdfind` fallback |
| `findtext` | Search file contents |
| `extract` | Extract common archives |
| `compress` | Create a `.tar.gz` archive |
| `backup` | Create a timestamped backup |
| `serve` | Start a simple Python HTTP server |
| `checksum` | Calculate common checksums |

</details>

<details>
<summary><strong>Networking & debugging</strong></summary>

| Command | Description |
|:---|:---|
| `netinfo` | Network interfaces, routes and DNS |
| `gateway` | Show the default gateway |
| `routeinfo` | Show the route to a host |
| `ports` | Show listening sockets |
| `portcheck` | Test a TCP port |
| `dnscheck` | Quick DNS resolution test |
| `httpcheck` | Show HTTP timing data |
| `proc` | Search running processes |
| `pidinfo` | Inspect a PID |
| `procenv` | Inspect a process environment |
| `portprocess` | Find the process bound to a port |
| `tracefiles` | Trace file syscalls |
| `tracenet` | Trace network syscalls |
| `sniff` | Capture traffic with `tcpdump` |

</details>

<details>
<summary><strong>System & services</strong></summary>

| Command | Description |
|:---|:---|
| `cpu` | CPU information |
| `mem` | RAM usage |
| `diskfree` | Filesystem usage |
| `diskusage` | Directory sizes |
| `big` | Largest files |
| `mounts` | Mounted filesystems |
| `hardware` | Hardware summary |
| `errors` | Kernel + journal warnings/errors |
| `diagnose` | Full diagnostic report |
| `failed` | Failed systemd units |
| `svc` | Service status |
| `jerrors` | Current boot errors |
| `journalgrep` | Search the journal |

</details>

<details>
<summary><strong>Git & Docker</strong></summary>

| Command | Description |
|:---|:---|
| `gitwhere` | Repository location + branch + status |
| `gitsummary` | Compact repository summary |
| `gitlast` | Recent commits |
| `gituntracked` | Untracked files |
| `dps` | Running containers |
| `dpsa` | All containers |
| `dlog` / `dlogf` | Container logs |
| `dexec` | Open a shell/command in a container |
| `dstats` | Container resource usage |
| `dspace` | Docker disk usage |
| `drestart` | Restart containers |
| `dprune` | Show cleanup commands |

</details>

---

## Module loading

The main `.bashrc` loads these files explicitly:

```text
aliases.bash
functions.bash
git.bash
docker.bash
optional-tools.bash
```

This is intentional. A predictable load order is easier to debug than a generic `*.bash` wildcard when modules depend on shared helpers.

---

## Troubleshooting

### Syntax check

```bash
bash -n ~/.bashrc
bash -n ~/.bashrc.d/*.bash
```

### Configuration check

```bash
bashcheck
bashrc_status
```

### Command availability

```bash
command -v fzf
command -v rg
command -v bat || command -v batcat
command -v fd || command -v fdfind
command -v docker
```

### Inspect a command

```bash
cmdinfo docker
whichall bash
```

### Reload configuration

```bash
reload
```

### Restore the previous configuration

List backups:

```bash
ls -la ~/.bashrc.backup-*
```

Restore one:

```bash
cp ~/.bashrc.backup-YYYYMMDD-HHMMSS ~/.bashrc
```

Then open a new shell.

---

## Design principles

> **Portable · Modular · Optional · Safe · Debug-friendly · Reversible**

- **Portable:** no hard-coded username, hostname or personal paths.
- **Modular:** functionality is split into focused files.
- **Optional:** missing tools do not break shell startup.
- **Safe:** destructive commands are not silently redefined.
- **Debug-friendly:** common Linux, network, service, Git and container problems have dedicated helpers.
- **Reversible:** the installer creates a `.bashrc` backup before replacing the file.

---

## License

MIT — see [`LICENSE`](LICENSE).
