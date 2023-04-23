use base01db
go
BACKUP log base01db WITH truncate_only;
go
DBCC shrinkfile(Base01db_Log, TRUNCATEONLY);
go
DBCC SHRINKDATABASE(base01db, NOTRUNCATE);
go
DBCC SHRINKDATABASE(base01db, TRUNCATEONLY);
go

use base01db
go
TRUNCATE TABLE ALARM_LOG;
go
TRUNCATE TABLE DATA_LOG;
go
TRUNCATE TABLE EVENT_LOG;
go
