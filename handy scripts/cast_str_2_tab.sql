CREATE OR REPLACE TYPE   "VARCHAR2_5_TAB" as table of varchar2(2048)
/

CREATE OR REPLACE FUNCTION F_CAST_STR_2_TAB
------------------------
(
   p_str   IN     VARCHAR2
   ,p_delim IN     CHAR default ','
) RETURN VARCHAR2_5_TAB
as
   p_arr   VARCHAR2_5_TAB;
  c_sp CONSTANT CHAR(1) := ' ';  -- space char
  deststr VARCHAR2(255);   -- capture next token
  nextpos NUMBER(5) := 1;
  i NUMBER(5) := 0;  -- array offset

  -- returns the next token (or NULL) from a delimited string of values
  -- handles leading and embedded NULLs, e.g., ',ab,,c'
  -- NOTE: a test must be made for trailing NULLs (delimiter at end of string)

  PROCEDURE tokenize(
      p_data  IN     VARCHAR2
     ,p_delim IN     CHAR
     ,p_start IN OUT NUMBER
     ,p_dest     OUT VARCHAR2)
  IS

    Lnext NUMBER(5);

  BEGIN
    Lnext := INSTR(p_data, p_delim, p_start);  -- look for delimiter
    IF (Lnext > 0) THEN  -- found token
      p_dest := SUBSTR(p_data, p_start, Lnext - p_start);
      p_start := Lnext + 1;  -- start past end of token
    ELSE  -- delimiter not found
      p_dest := SUBSTR(p_data, p_start, LENGTH(p_data) - p_start + 1);   -- last token
      p_start := LENGTH(p_data) + 1;
    END IF;  -- found token
  END tokenize;

  -- converts a single space to NULL
  -- otherwise returns the original string
  FUNCTION sp2null(p_str IN VARCHAR2)
  RETURN VARCHAR2
  IS
  BEGIN
    IF (p_str = c_sp) THEN  -- treat single space as NULL
      RETURN (NULL);
    ELSE
      RETURN (p_str);
    END IF;
  END sp2null;

BEGIN  -- parse
  p_arr := varchar2_5_tab();
  p_arr.DELETE;  -- remove any previous entries
  p_arr.extend;  -- remove any previous entries
  tokenize(p_str, p_delim, nextpos, deststr);  -- initialize first parse
  begin
  WHILE (nextpos <= LENGTH(p_str)) LOOP  -- populate array
    i := i + 1;  -- starts from 1
    p_arr(i) := sp2null(deststr);
    p_arr.extend;
    tokenize (p_str, p_delim, nextpos, deststr);
  END LOOP;  -- populate array
  exception
  when others then null;
  end ;
  i := i + 1;  -- store last token
  p_arr(i) := sp2null(deststr);
  IF (SUBSTR(p_str, LENGTH(p_str), 1) = p_delim) then  -- store trailing null
    i := i + 1;  -- store last token
    p_arr.extend;
    p_arr(i) := NULL;
  END IF;
  RETURN p_arr;
end;
/



/*
****usage****

select column_value from table (F_CAST_STR_2_TAB('1,2,3,4,5'))

*****************/