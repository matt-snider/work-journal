-- API defintion for /tasks
CREATE VIEW tasks AS
    SELECT * FROM models.tasks
    ORDER BY day, ordering;


CREATE FUNCTION save_task()
    RETURNS trigger AS $$
    DECLARE
        is_notes_valid BOOLEAN;
        new_id INT;
        max_ordering INT;
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

        -- Update if it doesn't exist, otherwise insert
        IF new.id IS NOT NULL THEN
            UPDATE models.tasks
               SET description = new.description,
                   is_complete = new.is_complete,
                   ordering = new.ordering,
                   day = new.day,
                   notes = new.notes
            WHERE id = new.id;
            new_id = new.id;
        ELSE
            SELECT coalesce(max(ordering), 0)
            FROM models.tasks
            WHERE day = new.day
            INTO max_ordering;

            INSERT INTO models.tasks (description, is_complete, ordering, notes, day)
                VALUES (new.description, new.is_complete, max_ordering + 1, new.notes, new.day)
                RETURNING id INTO new_id;
        END IF;
        SELECT * INTO result FROM api.tasks WHERE id = new_id;
        RETURN result;
    END;
    $$ LANGUAGE plpgsql;


CREATE TRIGGER tasks_view_save_trigger
    INSTEAD OF INSERT OR UPDATE
    ON tasks
    FOR EACH ROW
    EXECUTE PROCEDURE save_task();
