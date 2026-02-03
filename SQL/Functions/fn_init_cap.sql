-- ================================================================================================= 
-- Description: Function to InitCap text
-- -------------------------------------------------------------------------------------------------
-- Change date    |  Author                                |  Change Description
-- -------------------------------------------------------------------------------------------------
-- 01/05/26          Yunus                                  1. Created this Function
-- 01/08/26          Architha Gudimalla       2. Updated to return null, if input is null
-- 01/30/26          Architha Gudimalla       3. Updated after further testing
-- 02/03/26          Architha Gudimalla       4. Added more exceptions
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
        @isOrdinal BIT = 0,
    @fullWord VARCHAR(2000);

  IF  @in is null
  BEGIN
    return @in;
  END

 set @in = replace(@in, '  ',' ');
 
    SELECT @in = REPLACE(@in, '.','. ')
      WHERE @in LIKE '%.%' and @in not LIKE '%. %'; 
 
    SELECT @in =  SUBSTRING(@in, 3, LEN(@in)) 
      WHERE @in LIKE '  %' 
 
    SELECT @in =  SUBSTRING(@in, 2, LEN(@in)) 
      WHERE @in LIKE ' %' 

  IF EXISTS 
  (
    SELECT  1
      where
     @in COLLATE Latin1_General_BIN LIKE '%[a-z][A-Z]%' 
    and @in not like '%LLC%' 
    and @in not like '%LLP%' 
  )
  BEGIN
    return @in;
  END
  IF EXISTS 
  (
    SELECT  1
      where
        @in like '% den %' or  @in like '% der %' or  @in like '% van %' or  @in like '% CIC' or  @in like '% &%' or @in like '%LLC%' or @in like '% lc%' or @in like '%LLP%' or @in like '%LTD%' or @in like '%TRUST%' or @in like '% inc%' or @in like '% limited%' or @in like '% partner%' 
  ) 
  BEGIN
    return @in;
  END
  IF EXISTS 
  (
    SELECT  1
      where
        @in COLLATE Latin1_General_CS_AS like '% De %' or  @in COLLATE Latin1_General_CS_AS like '% de %' or
        @in COLLATE Latin1_General_CS_AS like '% la %' or  @in COLLATE Latin1_General_CS_AS like '% La %'
  ) 
  BEGIN
    return @in;
  END
  IF EXISTS 
  (
    SELECT  1
      where
  --checks if the first word in the name is all caps
  LEFT(@in, CHARINDEX(' ', @in + ' ') - 1) COLLATE Latin1_General_CS_AS =  UPPER(LEFT(@in, CHARINDEX(' ', @in + ' ') - 1)) COLLATE Latin1_General_CS_AS
  and
  --checks if the entire name is not all caps
  @in COLLATE Latin1_General_CS_AS <> UPPER(@in) COLLATE Latin1_General_CS_AS
  ) 
  BEGIN
    return @in;
  END
  /*
  IF (PATINDEX('%[A-Za-z].[A-Za-z]%', @in) > 0)
  BEGIN
    return upper(@in);
  END
  */
    -- Convert input string to lowercase initially
    SET @in = LOWER(@in);
  SET @fullWord = '';
    WHILE @i <= @len
    BEGIN
        SET @char = SUBSTRING(@in, @i, 1);
    SET @fullWord = @fullWord + @char;
        SET @prevChar = IIF(@i = 1, ' ', SUBSTRING(@in, @i - 1, 1));
        SET @nextChar = IIF(@i = @len, ' ', SUBSTRING(@in, @i + 1, 1));
        IF @make_capital = 1 AND @char LIKE '[a-z]'
        BEGIN
            IF @prevChar LIKE '[0-9]' AND
               (
                SUBSTRING(@in, @i, 2) IN ('st', 'nd', 'rd', 'th')
        )
            BEGIN
                SET @result += SUBSTRING(@in, @i, 2); 
                SET @i = @i + 1;
            END
      ELSE IF ( @make_capital = 1 AND @char LIKE '[a-z]' AND @nextChar = '.' )
      BEGIN
        SET @result += upper(SUBSTRING(@in, @i, 2)); 
        SET @i = @i + 1;
      END
    ELSE IF @make_capital = 1 AND @prevChar IN ('''', '’') AND (@nextChar = ' ' or @i=@len)
    BEGIN
      SET @result += @char;
            SET @make_capital = 0;
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
        IF @char IN (' ', '-', '''', '’')
        BEGIN
            SET @make_capital = 1;
     /* IF @fullWord IN ('I','II','III','IV','V','VI','VII','VIII','IX','X','XI')
      BEGIN      
      SET @result = REPLACE(@result, @fullWord, UPPER(@fullWord))
      END
    */
      SET @fullWord = ''
        END
        SET @i = @i + 1;
    END
  IF @fullWord IN ('I','II','III','IV','V','VI','VII','VIII','IX','X','XI')
  BEGIN
    SET @result = REPLACE(@result, @fullWord, UPPER(@fullWord))
  END
    -- Handle special cases (e.g., Mc, LLC)
    SET @result = REPLACE(@result, ' Mc', ' Mc');
    SELECT @result = REPLACE(@result, ' Mc' + LOWER(SUBSTRING(@result, CHARINDEX(' Mc', @result) + 2, 1)), 
  ' Mc' + UPPER(SUBSTRING(@result, CHARINDEX(' Mc', @result) + 2, 1)))
  WHERE @result LIKE 'mc%';
    SET @result = REPLACE(@result, ' llc', ' LLC');
  SET @result = REPLACE(@result, ' pllc', ' PLLC');
  SET @result = REPLACE(@result, ' lp', ' LP');
  SET @result = REPLACE(@result, ' ltd', ' LTD')
    SET @result = REPLACE(REPLACE(@result, ' II', ' II'), ' III', ' III'); 
    --SET @result = REPLACE(@result, ' II', ' II');
    SET @result = REPLACE(@result, ' SW ',' SW ');
    SELECT @result = REPLACE(@result, ' SW',' SW')
      WHERE @result LIKE '% SW';
    SET @result = REPLACE(@result, ' SE ',' SE ');
    SELECT @result = REPLACE(@result, ' SE',' SE')
      WHERE @result LIKE '% SE';
    SET @result = REPLACE(@result, ' NE ',' NE ');
    SELECT @result = REPLACE(@result, ' NE',' NE')
      WHERE @result LIKE '% NE';
    SET @result = REPLACE(@result, ' NW ', ' NW ');
    SELECT @result = REPLACE(@result, ' NW', ' NW')
      WHERE @result LIKE '% NW';
  SELECT @result = REPLACE(@result, ' TWP', ' TWP')
      WHERE @result LIKE '% TWP';
  SELECT @result = REPLACE(@result, ' RM ', ' RM ')
      WHERE @result LIKE '% RM %';
  SELECT @result = REPLACE(@result, ' GR ', ' GR ')
      WHERE @result LIKE '% GR %';
  SELECT @result = REPLACE(@result, ' Odonnell', ' Odonnell')
      WHERE @result LIKE '% Odonnell%';
  SELECT @result = REPLACE(@result, ' NJ', ' NJ')
      WHERE @result LIKE '% NJ%';
  SELECT @result = REPLACE(@result, '-by-the-Sea', '-by-the-Sea')
      WHERE @result LIKE '%-by-the-Sea';
  SELECT @result = REPLACE(@result, ' by the Sea', ' by the Sea')
      WHERE @result LIKE '% by the Sea';
  SELECT @result = REPLACE(@result, '-on-', '-on-')
      WHERE @result LIKE '%-on-%';
  SELECT @result = REPLACE(@result, 'Mckinley', 'McKinley')
      WHERE @result LIKE '%McKinley';
  SELECT @result = REPLACE(@result, 'Mccallan', 'McCallan')
      WHERE @result LIKE '%Mccallan';
  SELECT @result = REPLACE(@result, 'Mcglinchey', 'McGlinchey')
      WHERE @result LIKE '%Mcglinchey';
  SELECT @result = REPLACE(@result, 'Mccann', 'McCann')
      WHERE @result LIKE '%Mccann';
  SELECT @result = REPLACE(@result, 'Mchenry', 'McHenry')
      WHERE @result LIKE '%Mchenry';
  SELECT @result = REPLACE(@result, 'Mckenna', 'McKenna')
      WHERE @result LIKE '%Mckenna';  
  SELECT @result = REPLACE(@result, 'Ocallahan', 'OCallahan')
      WHERE @result LIKE '%Ocallahan';  
  SELECT @result = REPLACE(@result, 'Oconnor', 'OConnor')
      WHERE @result LIKE '%Oconnor';  
  SELECT @result = REPLACE(@result, 'Oconnell', 'OConnell')
      WHERE @result LIKE '%Oconnell';    

  SELECT @result = REPLACE(@result, ' US ', ' US ')
      WHERE @result LIKE '% US %';  
  SET @result = REPLACE(@result, ' and ', ' and ')
  SET @result = REPLACE(@result, ' the ', ' the ')
  SET @result = REPLACE(@result, ' of ', ' of ')
  IF @in is null 
        BEGIN
            SET @result = null;
        END
    RETURN @result;
END;     