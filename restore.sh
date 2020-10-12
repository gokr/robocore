export PGPASSWORD="robocore"
export PGUSER="robocore"
pg_restore -c -d robocore $1
