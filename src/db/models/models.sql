CREATE SCHEMA models;
SET search_path = models, public;

-- Load application models
\ir tasks.sql
