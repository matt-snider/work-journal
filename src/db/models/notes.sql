CREATE TABLE notes (
    id       SERIAL   PRIMARY KEY,
    content  TEXT     NOT NULL,
    task_id  BIGINT   NOT NULL REFERENCES tasks
);
