-- Role Definitions
/**
 * api_user
 */
CREATE ROLE api_user NOLOGIN;
GRANT usage ON SCHEMA api TO api_user;
GRANT usage ON SCHEMA models TO api_user;

GRANT select, insert, update, delete
    ON api.tasks
    TO api_user;

GRANT select, insert, update, delete
    ON models.tasks
    TO api_user;

GRANT usage
    ON models.tasks_id_seq
    TO api_user;


-- Owns all views in api schema
ALTER VIEW tasks OWNER TO api_user;

/**
 * anonymous (used when unauthenticated)
 */
CREATE ROLE anonymous NOLOGIN;
GRANT usage ON SCHEMA api TO anonymous;

-- Temporarily let anonymous be an api_user
GRANT api_user to anonymous;

/**
 * authenticator  (switches into other roles)
 */
CREATE ROLE authenticator NOINHERIT;
GRANT anonymous TO authenticator;
GRANT api_user TO authenticator;
