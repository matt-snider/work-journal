-- API defintion for /tasks
CREATE VIEW tasks AS
    SELECT
        t.*,
        coalesce(
            json_agg(json_build_object('id', n.id, 'content', n.content))
                FILTER (WHERE n.id IS NOT NULL),
            json_build_array()
        ) AS notes
    FROM models.tasks t
        LEFT JOIN models.notes n
        ON t.id = n.task_id
    GROUP BY t.id
    ORDER BY t.id;


CREATE FUNCTION insert_task()
    RETURNS trigger AS $$
    DECLARE
        task_id bigint;
        result record;
    BEGIN
        -- Insert task record
        INSERT INTO models.tasks (description, is_complete)
        VALUES (new.description, false)
        RETURNING id INTO task_id;

        -- Insert any notes
        INSERT INTO models.notes (content, task_id)
            SELECT *, task_id AS task_id
            FROM json_to_recordset(new.notes) AS x(content text);

        -- Use our view to return the result
        -- including new id and notes
        SELECT * INTO result FROM api.tasks WHERE id = task_id;
        RETURN result;
    END;
    $$ LANGUAGE plpgsql;


CREATE FUNCTION update_task()
    RETURNS trigger AS $$
    DECLARE
        note json;
        result record;
    BEGIN
        UPDATE models.tasks
            SET description = new.description
              , is_complete = new.is_complete
            WHERE id = new.id;

        FOR note IN SELECT * FROM json_array_elements(new.notes)
        LOOP
            IF (note -> 'id') IS NOT NULL THEN
                UPDATE models.notes
                    SET content = note ->> 'content'
                    WHERE id = (note ->> 'id')::int
                        AND task_id = new.id;
            ELSE
                INSERT INTO models.notes (content, task_id)
                    VALUES (note ->> 'content', new.id);
            END IF;
        END LOOP;

        -- Use our view to return the result
        -- including new id and notes
        SELECT * INTO result FROM api.tasks WHERE id = new.id;
        RETURN result;
    END;
    $$ LANGUAGE plpgsql;


CREATE FUNCTION delete_task()
    RETURNS trigger AS $$
    BEGIN
        -- Delete associated notes
        DELETE FROM models.notes
            WHERE task_id = old.id;

        -- Delete the task
        DELETE FROM models.tasks
            WHERE id = old.id;
        RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;


CREATE TRIGGER tasks_view_insert_trigger
    INSTEAD OF INSERT
    ON tasks
    FOR EACH ROW
    EXECUTE PROCEDURE insert_task();


CREATE TRIGGER tasks_view_update_trigger
    INSTEAD OF UPDATE
    ON tasks
    FOR EACH ROW
    EXECUTE PROCEDURE update_task();


CREATE TRIGGER tasks_view_delete_trigger
    INSTEAD OF DELETE
    ON tasks
    FOR EACH ROW
    EXECUTE PROCEDURE delete_task();
