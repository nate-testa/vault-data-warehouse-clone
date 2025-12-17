-- ================================================================================================= 
-- Author:		Dinesh Bobbili
-- Create Date: <Create Date, , >
-- Description: Function to clean the html text to clean text
-- ---------------------------------------------------------------------------------------------------
-- Change date 				|Author						|	Change Description
-- ---------------------------------------------------------------------------------------------------
-- 12/17/25					Dinesh Bobbili				1. Created this Function
-- ================================================================================================= 
CREATE OR ALTER FUNCTION edw_core.fn_strip_html
(
    @input NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @output   NVARCHAR(MAX);
    DECLARE @start    INT;
    DECLARE @end      INT;

    -- For removing repeated characters
    DECLARE @pos      INT;
    DECLARE @runLen   INT;

    IF @input IS NULL
        RETURN NULL;

    SET @output = @input;

    ----------------------------------------------------------------------
    -- 0. Ensure adjacent tags leave space when removed
    --    e.g. </span></div><div><span> -> </span> </div> <div> <span>
    ----------------------------------------------------------------------
    SET @output = REPLACE(@output, '><', '> <');

    ----------------------------------------------------------------------
    -- 0.1 Treat explicit <br> variants as separators (space)
    ----------------------------------------------------------------------
    SET @output = REPLACE(@output, '<br>',  ' ');
    SET @output = REPLACE(@output, '<br/>', ' ');
    SET @output = REPLACE(@output, '<br />',' ');

    ----------------------------------------------------------------------
    -- 1. Remove all remaining HTML tags: anything between '<' and '>'
    ----------------------------------------------------------------------
    SET @start = CHARINDEX('<', @output);

    WHILE @start > 0
    BEGIN
        SET @end = CHARINDEX('>', @output, @start + 1);

        -- Safety: if no closing '>', stop
        IF @end = 0 BREAK;

        -- Remove the tag including angle brackets
        SET @output = STUFF(@output, @start, @end - @start + 1, '');

        -- Look for next tag starting at or after current position
        SET @start = CHARINDEX('<', @output, @start);
    END;

    ----------------------------------------------------------------------
    -- 2. Normalize common HTML entities & whitespace
    ----------------------------------------------------------------------
    SET @output = REPLACE(@output, '&nbsp;', ' ');

    SET @output = REPLACE(@output, CHAR(13), ' ');  -- CR
    SET @output = REPLACE(@output, CHAR(10), ' ');  -- LF
    SET @output = REPLACE(@output, CHAR(9),  ' ');  -- TAB

    ----------------------------------------------------------------------
    -- 2.5 Remove contiguous runs of '-' or '*' of length >= 2
    ----------------------------------------------------------------------

    -- Remove runs of hyphens (--- or longer)
    SET @pos = PATINDEX('%--%', @output);
    WHILE @pos > 0
    BEGIN
        SET @runLen = 2;
        WHILE (@pos + @runLen <= LEN(@output)
               AND SUBSTRING(@output, @pos + @runLen, 1) = '-')
        BEGIN
            SET @runLen = @runLen + 1;
        END;

        -- Remove the entire run
        SET @output = STUFF(@output, @pos, @runLen, '');

        -- Look for next run
        SET @pos = PATINDEX('%--%', @output);
    END;

    -- Remove runs of asterisks (*** or longer)
    SET @pos = PATINDEX('%**%', @output);
    WHILE @pos > 0
    BEGIN
        SET @runLen = 2;
        WHILE (@pos + @runLen <= LEN(@output)
               AND SUBSTRING(@output, @pos + @runLen, 1) = '*')
        BEGIN
            SET @runLen = @runLen + 1;
        END;

        -- Remove the entire run
        SET @output = STUFF(@output, @pos, @runLen, '');

        -- Look for next run
        SET @pos = PATINDEX('%**%', @output);
    END;

    ----------------------------------------------------------------------
    -- 3. Collapse multiple spaces into a single space
    ----------------------------------------------------------------------
    WHILE CHARINDEX('  ', @output) > 0
    BEGIN
        SET @output = REPLACE(@output, '  ', ' ');
    END;

    ----------------------------------------------------------------------
    -- 4. Trim leading/trailing spaces
    ----------------------------------------------------------------------
    SET @output = LTRIM(RTRIM(@output));

    RETURN @output;
END;
GO