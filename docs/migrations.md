# Running Migrations

http.sh supports running arbitrary migrations, for example to migrate notORM
schemas. Files are read from `${cfg[namespace]}/migrations/` and executed in
lexicographical order. After a migration has been run, it will be added to
`storage/migrations.dat` along with a timestamp of when it ran.

Migration names must be in the format of `<UNIX timestamp>_<name>.sh` and
unique within an application.

On first startup of the application, the current time is saved and all future
migrations listed _after_ the initial timestamp are automatically run on
application start restart.

