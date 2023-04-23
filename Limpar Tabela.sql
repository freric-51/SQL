-- delete in time range of 400 seconds
SET NOCOUNT ON  --Very Important
declare @dt nvarchar(30)
set @dt= {fn NOW()} - 400
WHILE (@dt < {fn NOW()} +1)
BEGIN
	delete base02db..Log_Errors	WHERE (dtDateTime < @dt)
	delete base02db..Screen_Usage	WHERE (dtOpenTime < @dt)

	delete Base01db..ALARM_LOG	WHERE (timestamp < @dt)
	delete Base01db..DATA_LOG	WHERE (timestamp < @dt)
	delete Base01db..EVENT_LOG	WHERE (timestamp < @dt)
	SET @dt = DATEADD(DAY,1,@dt)
end
