-- ================================================================================================= 
-- Description: Function to InitCap text
-- -------------------------------------------------------------------------------------------------
-- Change date 				|Author						|	Change Description
-- -------------------------------------------------------------------------------------------------
-- 01/05/26					Yunus				        1. Created this Function
-- 01/08/26					Architha Gudimalla	        2. Updated to return null, if input is null
-- ================================================================================================= 
CREATE OR ALTER FUNCTION [edw_core].[fn_init_cap] (@in VARCHAR(MAX))
RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE 
        @result VARCHAR(MAX) = '',
        @i INT = 1,
        @len INT = LEN(@in),
        @make_capital BIT = 1,
        @char CHAR(1),
        @prevChar CHAR(1),
        @nextChar CHAR(1),
        @isOrdinal BIT = 0;

    -- Convert input string to lowercase initially
    SET @in = LOWER(@in);

    WHILE @i <= @len
    BEGIN
        SET @char = SUBSTRING(@in, @i, 1);
        SET @prevChar = IIF(@i = 1, ' ', SUBSTRING(@in, @i - 1, 1));
        SET @nextChar = IIF(@i = @len, ' ', SUBSTRING(@in, @i + 1, 1));
  
        IF @make_capital = 1 AND @char LIKE '[a-z]'
        BEGIN
            IF @prevChar LIKE '[0-9]' AND 
               (
                SUBSTRING(@in, @i, 2) IN ('st', 'nd', 'rd', 'th'))
            BEGIN
                SET @result += SUBSTRING(@in, @i, 2); 
                SET @i = @i + 1;
            END
            ELSE
            BEGIN              
                SET @result += UPPER(@char);
                SET @make_capital = 0;
            END
        END
        ELSE
        BEGIN          
            SET @result += @char;
        END
       
        IF @char IN (' ', '-', '''')
        BEGIN
            SET @make_capital = 1;
        END

        SET @i = @i + 1;
    END

    -- Handle special cases (e.g., Mc, LLC)
    SET @result = REPLACE(@result, 'Mc ', 'Mc');
    SET @result = REPLACE(@result, 'Mc' + LOWER(SUBSTRING(@result, CHARINDEX('Mc', @result) + 2, 1)),
                                   'Mc' + UPPER(SUBSTRING(@result, CHARINDEX('Mc', @result) + 2, 1)));

    SET @result = REPLACE(@result, ' llc', ' LLC');
    SET @result = REPLACE(@result, ' III', ' III');
    SET @result = REPLACE(@result, ' II', ' II');
    SET @result = REPLACE(@result, ' SW ',' SW ');
    SET @result = REPLACE(@result, ' NE ',' NE ');
    SET @result = REPLACE(@result, ' SE ',' SE ');
    SET @result = REPLACE(@result, ' NW ', ' NW ');
	IF @in is null 
        BEGIN
            SET @result = null;
        END
    RETURN @result;
END;