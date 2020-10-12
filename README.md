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

Run `setup.sh` to create a database and a user.

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
