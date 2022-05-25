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
        KEY,
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
        VALUE,
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

    begin_error,
        Err,
        # Borrowed from https://github.com/JuliaLang/TOML.jl/blob/057a427116b5874b2e4732485088a42d6ad15689/src/parser.jl#L160
        # Toplevel #
        ErrRedefineTableArray,
        ErrExpectedNewLineKeyValue,
        ErrAddKeyToInlineTable,
        ErrAddArrayToStaticArray,
        ErrArrayTreatedAsDictionary,
        ErrExpectedEndOfTable,
        ErrExpectedEndArrayOfTable,

        # Keys #
        ErrExpectedEqualAfterKey,
        # TODO: Check, are these the same?
        ErrDuplicatedKey,
        ErrKeyAlreadyHasValue,
        ErrInvalidBareKeyCharacter,
        ErrEmptyBareKey,

        # Values #
        ErrUnexpectedEofExpectedValue,
        ErrUnexpectedStartOfValue,
        ErrGenericValueError,

        # Arrays
        ErrExpectedCommaBetweenItemsArray,

        # Inline tables
        ErrExpectedCommaBetweenItemsInlineTable,
        ErrTrailingCommaInlineTable,

        # Numbers
        ErrUnderscoreNotSurroundedByDigits,
        ErrLeadingZeroNotAllowedInteger,
        ErrOverflowError,
        ErrLeadingDot,
        ErrNoTrailingDigitAfterDot,
        ErrTrailingUnderscoreNumber,

        # DateTime
        ErrParsingDateTime,
        ErrOffsetDateNotSupported,

        # Strings
        ErrNewLineInString,
        ErrUnexpectedEndString,
        ErrInvalidEscapeCharacter,
        ErrInvalidUnicodeScalar,
    end_error,
#! format: on
)

is_key(k::Kind) = begin_keys < k < end_keys
is_delimiter(k::Kind) = begin_delimiters < k < end_delimiters
is_value(k::Kind) = begin_values < k < end_values
is_string(k::Kind) = begin_string < k < end_string
is_integer(k::Kind) = begin_integer < k < end_integer
is_float(k::Kind) = begin_float < k < end_float
is_boolean(k::Kind) = begin_boolean < k < end_boolean
is_datetime(k::Kind) = begin_datetime < k < end_datetime
is_error(k::Kind) = begin_error < k < end_error


# Borrowed from https://github.com/JuliaLang/TOML.jl/blob/057a427116b5874b2e4732485088a42d6ad15689/src/parser.jl#L213
const TOKEN_ERROR_DESCRIPTION = Dict(
    ErrTrailingCommaInlineTable => "trailing comma not allowed in inline table",
    ErrExpectedCommaBetweenItemsArray => "expected comma between items in array",
    ErrExpectedCommaBetweenItemsInlineTable => "expected comma between items in inline table",
    ErrExpectedEndArrayOfTable => "expected array of table to end with ']]'",
    ErrInvalidBareKeyCharacter => "invalid bare key character",
    ErrRedefineTableArray => "tried to redefine an existing table as an array",
    ErrDuplicatedKey => "key already defined",
    ErrKeyAlreadyHasValue => "key already has a value",
    ErrEmptyBareKey => "bare key cannot be empty",
    ErrExpectedNewLineKeyValue => "expected newline after key value pair",
    ErrNewLineInString => "newline character in single quoted string",
    ErrUnexpectedEndString => "string literal ened unexpectedly",
    ErrExpectedEndOfTable => "expected end of table ']'",
    ErrAddKeyToInlineTable => "tried to add a new key to an inline table",
    ErrArrayTreatedAsDictionary => "tried to add a key to an array",
    ErrAddArrayToStaticArray => "tried to append to a statically defined array",
    ErrGenericValueError => "failed to parse value",
    ErrLeadingZeroNotAllowedInteger => "leading zero in integer not allowed",
    ErrUnderscoreNotSurroundedByDigits => "underscore is not surrounded by digits",
    ErrUnexpectedStartOfValue => "unexpected start of value",
    ErrOffsetDateNotSupported => "offset date-time is not supported",
    ErrParsingDateTime => "parsing date/time value failed",
    ErrTrailingUnderscoreNumber => "trailing underscore in number",
    ErrLeadingDot => "floats require a leading zero",
    ErrExpectedEqualAfterKey => "expected equal sign after key",
    ErrNoTrailingDigitAfterDot => "expected digit after dot",
    ErrOverflowError => "overflowed when parsing integer",
    ErrInvalidUnicodeScalar => "invalid Unicode scalar",
    ErrInvalidEscapeCharacter => "invalid escape character",
    ErrUnexpectedEofExpectedValue => "unexpected end of file, expected a value"
)

for kind in instances(Kind)
    if is_error(kind)
        @assert haskey(TOKEN_ERROR_DESCRIPTION, kind) "$kind does not have an error message"
    end
end
