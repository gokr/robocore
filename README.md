# RoboCORE

RoboCORE is a combined Discord and Telegram bot that serves the [cVault.finance](https://cvault.finance) CORE crypto community and it's [CORE crypt currency](https://coinmarketcap.com/currencies/cvault-finance/). This community is active on both Telegram and Discord and this bot has functionality to track transactions and price changes etc on the Ethereum network.

# Dart
At the moment RoboCORE runs in the Dart VM (not native compiled) and it uses the non-nullable "experiment" (Nyxx uses it and well, time to bite the bullet anyway). At the moment RoboCORE runs fine in Dart 2.9.3-1 on Ubuntu.

# Config
RoboCORE uses `robocore.yaml` placed in the home directory of the user running RoboCORE. You can find a sample file.


# PostgreSQL
We use PostgreSQL's apt repository to stay on track of updates of PostgreSQL:

Create the file `/etc/apt/sources.list.d/pgdg.list' and add a line for the repository

        deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main

Import the repository signing key, and update the package lists

        wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
        sudo apt-get update

Then we can install PostgreSQL:

        sudo apt install postgresql postgresql-client

# Database

Run:

        sudo su postgres
        psql -c "create database robocore;"
        psql -c "create user robocore;alter user robocore with password 'robocore';grant all on database robocore to robocore;"
        exit

# As services
Use a systemd service file like this for `robocore`, and one for `roboserver`:

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

## Docker
I don't really like Docker but I decided to use it for Quickchart due to complicated dependencies.

        sudo apt install docker.io
        sudo systemctl start docker
        sudo systemctl enable docker

## QuickChart
We run Quickchart server in Docker, due to making sure dependencies stay solid.

We want to run in systemd so:

        [Unit]
        Description=Quickchart
        After=docker.service
        Requires=docker.service

        [Service]
        TimeoutStartSec=0
        Restart=always
        ExecStartPre=-/usr/bin/docker exec quickchart stop
        ExecStartPre=-/usr/bin/docker rm quickchart
        ExecStartPre=-/usr/bin/docker pull ianw/quickchart:v1.4.3
        ExecStart=/usr/bin/docker run --rm --name quickchart -p 8089:3400  ianw/quickchart:v1.4.3

        [Install]
        WantedBy=default.target

To start the service using systemd:

        sudo systemctl daemon-reload
        sudo systemctl start quickchart
        sudo systemctl status quickchart

Enable the systemd service so that quickchart starts at boot.

        sudo systemctl enable quickchart.service


See

https://quickchart.io/documentation/

https://github.com/typpo/quickchart
