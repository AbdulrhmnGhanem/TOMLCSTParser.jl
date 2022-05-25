@enum(Kind::Int16,
    NONE,       # Placeholder; never emitted by lexer
    EOF,        # EOF
    WHITESPACE, # '  or \t'
#! format: off
    # See TOML specification https://toml.io/en/v1.0.0
    COMMENT,  # # comment
    EQ,       # =
    PLUS,     # +
    MINUS,    # -

    begin_keys,
        BARE_KEY,    # key = ... , bare_key = ..., bare-key = ..., and 1234 = ...
        QUOTED_KEY,  # "127.0.0.1" =..., "character encoding" = ..., "ʎǝʞ" = ..., 'quoted "value"' = ...
        DOTTED_KEY,  # physical.color = ..., site."google.com" = ...
    end_keys,

    begin_delimiters,
        LSQUARE,        # [
        RSQUARE,        # ]
        DOUBLE_LBRACE,  # [[
        DOUBLE_RPRACE,  # ]]
        LBRACE,         # {
        RBRACE,         # }
        QUOTE,          # '
        DQUOTE,         # " (double quote)
        TRIPLE_DQUOTE,  # """
        TRIPLE_QUOTE,   # '''
        BACKSLASH,      # \
    end_delimiters,

    begin_values,
        begin_string,
            BASIC_STRING,             # "..."
            MULTILINE_BASIC_STRING,   # """..."""
            LITERAL_STRING,           # '...'
            MULTILINE_LITERAL_STRING, # '''...'''
        end_string,
        begin_integer,
            INTEGER,  # 1, +1, -0, 1_000, 1_2_3_4
            HEX,      # 0xDEADBEEF
            OCT,      # 0o01234567
            BIN,      # 0b11010110
        end_integer,
       
        begin_float,
            FLOAT, # +1.0, 5e+22, 6.626e-34
            INF,
            NAN,
        end_float,
       
        begin_boolean,
            TRUE, FALSE,
        end_boolean,
       
        begin_datetime,
            OFFSET_DATETIME,  # 1979-05-27T07:32:00Z, 1979-05-27T00:32:00-07:00, 1979-05-27T00:32:00.999999-07:00, 1979-05-27 07:32:00Z
            LOCAL_DATETIME,   # 1979-05-27T07:32:00, 1979-05-27T00:32:00.999999
            LOCAL_DATE,       # 1979-05-27
            LOCAL_TIME,       # 07:32:00, 00:32:00.999999
        end_datetime,
    end_values,

    begin_syntax,
        begin_array,
            ARRAY,            # integers = [ 1, 2, 3 ], numbers = [ 0.1, 0.2, 0.5, 1, 2, 5 ]
            ARRAY_OF_TABLES,  # [[products]]    |  [[products]]
                              # name = "Hammer" |
                              # sku = 738594937 |
        end_array,
        bggin_table,
            TABLE,         # [KEY]
            INLINE_TABLE,  # name = { first = "Tom", last = "Preston-Werner" }, point = { x = 1, y = 2 }, animal = { type.name = "pug" }
        end_table,
    end_syntax,
#! format: on
)