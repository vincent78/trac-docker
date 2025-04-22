# Trac docker image

This repo contains containerized [Trac](https://trac.edgewall.org) issue tracking system.

## Components

There are few main files:

- `Dockerfile`
- `docker-compose.yml` (for local run in pair with postgres)
- `docker-entrypoint.sh` (entrypoint to run on container start)
- `requirements-container.txt` (additional pip modules to install)
- `scripts/manage.py` (checks connect with database on container start)

## Setting environment variables

Settings applying in [`docker-entrypoint.sh`](/docker-entrypoint.sh)
on container start.

| Name                  | Description                | Default value       |
|-----------------------|----------------------------|---------------------|
| `TRAC_PROJECT_NAME`   | Name of the Trac project   | `default`           |
| `TRAC_DB_STRING`      | Database connection string | `sqlite:db/trac.db` |
| `TRAC_ADMIN_PASSWORD` | Administrator's password   | `""`                |

Parameters will be written in  `trac.ini` file.

Full list of available parameters can be found in
[trac documentation](https://trac.edgewall.org/wiki/TracIni).

All settings can be set by specifying environment variables like so:

`TRAC_CONFIG_<SECTION_NAME>__<PARAMETER_NAME>=<value>`

For dash separated sections feel free to use variable
`TRAC_SECTION_DASH_SEPARATOR_<SECTION_NAME>`, e. g.:

```env
TRAC_CONFIG_HEADER_LOGO__HEIGHT=100
TRAC_CONFIG_ACCOUNT_MANAGER__PASSWORD_STORE=LDAPStore
TRAC_SECTION_DASH_SEPARATOR_ACCOUNT_MANAGER=true
```

File `trac.ini` will be rendered as:

```ini
[header_logo]
height = 100

[account-manager]
password_store = LDAPStore
```

You can also use custom `trac.ini` file mounted to `conf.d/trac.ini`:

```plain
$ docker build -t trac-custom .
$ docker run -d -p 8000:8000 \
  -v $PWD/my-trac-settings.ini:/trac-projects/default/conf.d/trac.ini \
  trac-custom:latest
```

## Limitations

- Only one superuser
- Only `postgres` and `sqlite` can be used as database engines
