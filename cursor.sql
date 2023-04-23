declare @Group nvarchar(50);

declare c CURSOR  LOCAL READ_ONLY for
SELECT sGroup FROM base02db..SProdGroups WHERE (sProject = 'AREA_C1V') AND (iEnabled = 1);

-- =======================================================
open c
FETCH NEXT FROM c into @Group;

WHILE @@FETCH_STATUS = 0
begin
	select  'MSXC1' + @Group + '_EN_S%';
	select * FROM base02db..SProdTags WHERE iEnabled=1 and (sPoint LIKE 'MSXC1' + @Group + '_EN_S%');
	FETCH NEXT FROM c INTO @Group
end

CLOSE c;
DEALLOCATE c;
-- =======================================================
