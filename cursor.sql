declare @Group nvarchar(50);

declare c CURSOR  LOCAL READ_ONLY for
SELECT sGroup FROM base01db..SProdGroups WHERE (sProject = 'C1V') AND (iEnabled = 1);

-- =======================================================
open c
FETCH NEXT FROM c into @Group;

WHILE @@FETCH_STATUS = 0
begin
	select  'AREA' + @Group + '_EN_S%';
	select * FROM base01db..SProdTags WHERE iEnabled=1 and (sTAG LIKE 'AREA' + @Group + '_EN_S%');
	FETCH NEXT FROM c INTO @Group
end

CLOSE c;
DEALLOCATE c;
-- =======================================================
