-- Defines /rpc/reorder_tasks
-- ordering is a mapping from task_id -> new ordering
-- e.g. {1: 4, 2: 3} would move task1 to position 4 and task2 to position 3
CREATE OR REPLACE FUNCTION api.reorder_tasks(ordering jsonb)
RETURNS void AS $$
    BEGIN
        WITH orderings AS (
            SELECT * FROM jsonb_to_recordset(ordering)
                AS x(task_id int, ordering int)
        )
        UPDATE models.tasks AS t
            SET ordering = o.ordering
        FROM orderings AS o
        WHERE o.task_id = t.id;
    END;
$$ LANGUAGE plpgsql;
