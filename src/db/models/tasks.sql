CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    is_complete BOOLEAN DEFAULT false
);