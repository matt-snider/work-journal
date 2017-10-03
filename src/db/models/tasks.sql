CREATE TABLE tasks (
    id           SERIAL   PRIMARY KEY,
    description  TEXT     NOT NULL,
    is_complete  BOOLEAN  DEFAULT FALSE,
    ordering     INT      NOT NULL,
    day          DATE     NOT NULL,
    notes        JSONB,

    CONSTRAINT valid_ordering
        UNIQUE (ordering, day)
        DEFERRABLE
);
