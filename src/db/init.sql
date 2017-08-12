\echo # Preparing database...

-- Models
\echo # Loading models...
\ir models/models.sql
\echo > Done.
\echo '> Done\n'


-- API
\echo # Loading api...
\ir api/api.sql
\echo '> Done\n'


-- Auth
\echo # Loading auth...
\ir auth/auth.sql
\echo '> Done\n'


\echo '> Done all\n'
