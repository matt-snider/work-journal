-- API defintion for /tasks
CREATE VIEW tasks AS
    SELECT * FROM models.tasks
    ORDER BY id;


CREATE FUNCTION save_task()
    RETURNS trigger AS $$
    DECLARE
        is_notes_valid BOOLEAN;
        result RECORD;
    BEGIN
        -- Ensure notes is just a simple array
        IF jsonb_typeof(new.notes) != 'array' THEN
            RAISE EXCEPTION 'Expected notes to be an array of strings';
        END IF;

        SELECT bool_and(jsonb_typeof(x) = 'string')
            FROM jsonb_array_elements(new.notes) AS x
            INTO is_notes_valid;

        IF NOT is_notes_valid THEN
            RAISE EXCEPTION 'Expected notes to be an array of strings';
        END IF;

        -- Insert record and return
        INSERT INTO models.tasks (description, is_complete, notes)
            VALUES (new.description, new.is_complete, new.notes);
        RETURN new;
    END;
    $$ LANGUAGE plpgsql;


CREATE TRIGGER tasks_view_save_trigger
    INSTEAD OF INSERT OR UPDATE
    ON tasks
    FOR EACH ROW
    EXECUTE PROCEDURE save_task();
