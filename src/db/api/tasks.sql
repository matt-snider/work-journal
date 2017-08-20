-- API defintion for /tasks
CREATE VIEW tasks AS
    SELECT
        t.*,
        json_agg(json_build_object('id', n.id, 'content', n.content))
            FILTER (WHERE n.id IS NOT NULL)
            AS notes
    FROM models.tasks t LEFT JOIN models.notes n
        ON t.id = n.task_id
    GROUP BY t.id;
