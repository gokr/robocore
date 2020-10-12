echo "Creating database robocore"
sudo psql -c "create database robocore;" -U postgres
sudo psql -c "create user robocore;alter user robocore with password 'robocore';grant all on database robocore to robocore;" -U postgres
