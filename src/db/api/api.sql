CREATE SCHEMA api;
SET search_path = api, public;

-- Load endpoints
\ir tasks.sql
\ir reorder_tasks.sql
