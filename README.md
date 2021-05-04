# Cross Architecture Warrior Container

Reboot of the Warrior Container:

Differences:
* Works on x64 arch, arm6, arm7, arm64
* Updated dependencies
* Pipeline ensures latest dependencies


## Systemd Unit

Note, once a day this will restart and re-pull the image.

```ini
[Unit]
Description=ArchiveTeam Warrior
After=docker.service
Requires=docker.service

[Service]
RuntimeMaxSec=1d
TimeoutStartSec=0
Restart=always
ExecStartPre=-/usr/bin/docker stop %n
ExecStartPre=-/usr/bin/docker rm %n
ExecStartPre=/usr/bin/docker pull ghcr.io/purplebooth/warrior-dockerfile:latest
ExecStart=/usr/bin/docker run --pull always --rm --env DOWNLOADER=your_name_here --env SELECTED_PROJECT=auto --publish 8001:8001 --name %n ghcr.io/purplebooth/warrior-dockerfile:latest

[Install]
WantedBy=multi-user.target
```

## Config

This now works for Raspberry Pi like it did for other platforms.

| ENV                  | JSON key             | Example           | Default |
|----------------------|----------------------|-------------------|---------|
| DOWNLOADER           | downloader           |                   |         |
| HTTP_PASSWORD        | http_password        |                   |         |
| HTTP_USERNAME        | http_username        |                   |         |
| SELECTED_PROJECT     | selected_project     | `auto`, `tumblr`  |         |
| WARRIOR_ID           | warrior_id           |                   |         |
| CONCURRENT_ITEMS     | concurrent_items     |                   | `3`     |

