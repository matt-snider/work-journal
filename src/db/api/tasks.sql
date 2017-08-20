-- API defintion for /tasks
CREATE VIEW tasks AS
    SELECT
        t.*,
        coalesce(
            json_agg(json_build_object('id', n.id, 'content', n.content))
                FILTER (WHERE n.id IS NOT NULL),
            json_build_array()
        ) AS notes
    FROM models.tasks t LEFT JOIN models.notes n
        ON t.id = n.task_id
    GROUP BY t.id;


CREATE OR REPLACE FUNCTION api.insert_task()
    RETURNS trigger AS $$
    DECLARE
        task_id bigint;
        result record;
    BEGIN
        -- Insert task record
        INSERT INTO models.tasks (description, is_complete)
        VALUES (new.description, false)
        RETURNING id INTO task_id;

        -- Use our view to return the result
        -- including new id and notes
        SELECT * INTO result FROM api.tasks WHERE id = task_id;
        RETURN result;
    END;
    $$ LANGUAGE plpgsql;


CREATE TRIGGER tasks_update
    INSTEAD OF INSERT
    ON tasks
    FOR EACH ROW
    EXECUTE PROCEDURE insert_task();
