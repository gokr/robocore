export PGPASSWORD="robocore"
export PGUSER="robocore"
pg_dump -Fc robocore > $1
