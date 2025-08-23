-- 1. Switch from master to the database containing the table
use PortfolioProject


-- 2. file overview
Select * From Top_100_UK_youtube_channels


-- 3. Select only the important data
Select NOMBRE, total_subscribers, total_views, total_videos
from Top_100_UK_youtube_channels


-- 4. Extract the channel names
	-- use charindex() to find the location of @
	select CHARINDEX('@',NOMBRE,1) from Top_100_UK_youtube_channels

	-- use substring() to extract the channel name
	select SUBSTRING(NOMBRE,1,CHARINDEX('@',NOMBRE,1)-2) from Top_100_UK_youtube_channels

	-- use CAST() to change to string
	Select CAST(SUBSTRING(NOMBRE,1,CHARINDEX('@',NOMBRE,1)-2) as varchar(100)) as Channel_Name,
	total_subscribers,
	total_videos,
	total_views
	from Top_100_UK_youtube_channels


-- 5. Create a view for next step 
CREATE VIEW view_1_Top_100_UK_youtube_channels AS
	Select CAST(SUBSTRING(NOMBRE,1,CHARINDEX('@',NOMBRE,1)-2) as varchar(100)) as Channel_Name,
		total_subscribers,
		total_videos,
		total_views
	from Top_100_UK_youtube_channels


-- 6. Test the dataset
	/* guidelines to test out the dataset

	There should be 100 entries (row count)
	There should be 4 fields (column count)
	Channel name must be string ; while total_subscribers, total_videos, total_views must be integers (data type check)
	There must be no duplicate entries

	*/

	-- row count test
	Select COUNT(*) AS row_count 
	FROM view_1_Top_100_UK_youtube_channels

	-- column count test
	SELECT * 
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'view_1_Top_100_UK_youtube_channels'

	OR

	SELECT COUNT(*) AS column_count 
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'view_1_Top_100_UK_youtube_channels'

	-- data type test
	SELECT COLUMN_NAME, DATA_TYPE 
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'view_1_Top_100_UK_youtube_channels'

	-- duplicate test
	SELECT Channel_Name, COUNT(Channel_Name) 
	FROM view_1_Top_100_UK_youtube_channels
	GROUP BY Channel_Name
	HAVING COUNT(Channel_Name) >1


-- 7. Load dataset to Power BI