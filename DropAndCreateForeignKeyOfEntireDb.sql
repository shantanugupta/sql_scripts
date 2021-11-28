DROP TABLE IF EXISTS #t;
GO

SELECT 
	f.name
	--, f.object_id
	, f.parent_object_id
	, tp.name as parent_table_name
	, f.referenced_object_id
	, tf.name as referenced_table_name
	--, f.key_index_id 
	--, CONCAT('ALTER TABLE ', tp.name ,' DROP CONSTRAINT ', f.name) as drop_fk
	--, CONCAT('ALTER TABLE ', tp.name ,' ADD CONSTRAINT ', f.name ,' FOREIGN KEY (ChildColumn) REFERENCES ', tf.name ,'(ParentColumn);') as existing_constraint_name
	--, CONCAT('ALTER TABLE ', tp.name ,' ADD CONSTRAINT FK_', tf.name ,'_ChildColumn FOREIGN KEY (ChildColumn) REFERENCES ', tf.name ,'(ParentColumn);') as create_fk
	--, fc.parent_object_id
	--, fc.parent_column_id
	--, fc.referenced_object_id
	--, fc.referenced_column_id
	--, fc.constraint_column_id
	--, COL_NAME(f.parent_object_id, fc.constraint_column_id) as constraint_column_name
	, COL_NAME(f.parent_object_id, fc.parent_column_id) as parent_column_name
	, COL_NAME(f.referenced_object_id, fc.referenced_column_id) as referenced_column_name
	, ROW_NUMBER() OVER (PARTITION BY f.name ORDER BY fc.parent_column_id) AS Rno
INTO #t
from sys.foreign_keys f
join sys.tables tp on f.parent_object_id = tp.object_id 
join sys.tables tf on f.referenced_object_id = tf.object_id 
join sys.foreign_key_columns fc on fc.constraint_object_id = f.object_id
--WHERE tp.name IN ('Parent','Child', 'ItemConsumed')


;with cte
as(
	SELECT 
		 o.name
		 , o.parent_table_name
		 , o.referenced_table_name
		 , o.parent_object_id
		 , o.referenced_object_id
		,stuff((select CONCAT(',', r.referenced_column_name)
				FROM #t r 
				WHERE r.name = o.name for xml path('')),1,1,'') AS referenced_columns
		,stuff((select CONCAT(',', r.parent_column_name)
				FROM #t r 
				WHERE r.name = o.name for xml path('')),1,1,'') AS parent_columns
		--, referenced_column_name, parent_column_name 
	FROM #t o 
	group by o.name, o.parent_table_name, o.referenced_table_name, o.parent_object_id, o.referenced_object_id
)
select 
		  name
		, CONCAT('FK_', c.referenced_table_name ,'_', REPLACE(referenced_columns, ',', '__')) AS new_name
		, parent_table_name
		, referenced_table_name
		--, parent_object_id
		--, referenced_object_id
		, referenced_columns
		, parent_columns
		, CONCAT('ALTER TABLE ', c.parent_table_name ,' DROP CONSTRAINT ', c.name, ';') as drop_fk
		, CONCAT('ALTER TABLE ', c.parent_table_name ,' ADD CONSTRAINT ', c.name ,' FOREIGN KEY (', c.parent_columns ,') REFERENCES ', c.referenced_table_name ,'(', c.referenced_columns,');') as existing_constraint_name
		, CONCAT('ALTER TABLE ', c.parent_table_name 
					,' ADD CONSTRAINT FK_', c.referenced_table_name ,'_', REPLACE(referenced_columns, ',', '__') ,' FOREIGN KEY (', c.parent_columns ,') REFERENCES '
					, c.referenced_table_name ,'(', c.referenced_columns ,');') as create_fk
		
from cte c
