# Robocore

A Discord bot! Bot token needs to be in a file called `bot-token.txt`. Run with `./robocore` ;)

# Dart
At the moment RoboCORE runs in the Dart VM (not native compiled) and it uses non-nullable experiment (Nyxx uses it and well, time to bite the bullet anyway). At the moment RoboCORE runs fine in Dart 2.9.3-1 on Ubuntu.

# Config
RoboCORE uses `robocore.yaml` placed in the home directory of the user running RoboCORE. You can find a sample file.

# As a service
Use a systemd service file like this:

    [Unit]
    Description=RoboCORE
    After=network.target

    [Service]
    User=robocore
    WorkingDirectory=/home/robocore/robocore
    ExecStart=/home/robocore/robocore/robocore
    LimitNOFILE=500000
    KillMode=mixed
    KillSignal=SIGTERM
    Restart=always
    RestartSec=2s
    NoNewPrivileges=yes
    StandardOutput=syslog+console
    StandardError=syslog+console

    [Install]
    WantedBy=multi-user.target