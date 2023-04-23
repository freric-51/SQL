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

use base02db
go
BACKUP log base02db WITH truncate_only;
go
DBCC shrinkfile(BASE02_Log, TRUNCATEONLY);
go
DBCC SHRINKDATABASE(base02db, NOTRUNCATE);
go
DBCC SHRINKDATABASE(base02db, TRUNCATEONLY);
go

use base03db
go
BACKUP log base03db WITH truncate_only;
go
DBCC shrinkfile(BASE03_LOG, TRUNCATEONLY);
go
DBCC SHRINKDATABASE(base03db, NOTRUNCATE);
go
DBCC SHRINKDATABASE(base03db, TRUNCATEONLY);
go

use base02db
go
TRUNCATE TABLE EventsData;
go
TRUNCATE TABLE Log_Errors;
go
TRUNCATE TABLE Verify_History;
go
TRUNCATE TABLE Userudit;
go
TRUNCATE TABLE Screen_Usage;
go
