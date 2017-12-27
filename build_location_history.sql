

CREATE TABLE [dbo].[location_history](
	[location_id] [int] NOT NULL,
	[relationship_type] [varchar](50) NULL,
	[domain_id] [varchar](50) NOT NULL,
	[entity_id] [int] NOT NULL,
	[start_date] [date] NULL,
	[end_date] [date] NULL
)
;


ALTER TABLE location_history ADD CONSTRAINT fpk_location_history_location FOREIGN KEY (location_id) REFERENCES location (location_id);



