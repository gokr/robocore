# Robocore

A Discord bot! Bot token needs to be in a file called `bot-token.txt`. Run with `./robocore` ;)

# As a service

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