module Lexers
import ..Tokens
import ..Tokens: Token, Kind, ERROR, is_error

include("utilities.jl")

struct StringState
    triplestr::Bool
    raw::Bool
    delim::Char
    paren_depth::Int
end

mutable struct Lexer{IO_t<:IO}
    io::IO_t
    io_start_pos::Int
    token_start_row::Int
    token_start_col::Int
    token_startpos::Int

    current_row::Int
    current_col::Int
    current_pos::Int

    last_token::Kind
    string_states::Vector{StringState}
    charstore::IOBuffer
    chars::Tuple{Char,Char,Char,Char}
    charspos::Tuple{Int,Int,Int,Int}
    errored::Bool
end


function Lexer(io::IO)
    c1, p1 = ' ', position(io)

    if eof(io)
        c2, p2 = EOF_CHAR, p1
        c3, p3 = EOF_CHAR, p1
        c4, p4 = EOF_CHAR, p1
    else
        c2, p2 = read(io, Char), position(io)

        if eof(io)
            c3, p3 = EOF_CHAR, p1
            c4, p4 = EOF_CHAR, p1
        else
            c3, p3 = read(io, Char), position(io)
            if eof(io)
                c4, p4 = EOF_CHAR, p1
            else
                c4, p4 = read(io, Char), position(io)
            end
        end
    end
    Lexer(
        io,
        position(io),
        1, 1,
        position(io),
        1, 1,
        position(io),
        ERROR,
        Vector{StringState}(),
        IOBuffer(),
        (c1, c2, c3, c4),
        (p1, p2, p3, p4),
        false)
end

Lexer(str::AbstractString) = Lexer(IOBuffer(str))


"""
    tokenize(x)

Returns an `Iterable` containing the tokenized input. Can be reverted by e.g.
`join(untokenize.(tokenize(x)))`.
"""
tokenize(x) = Lexer(x)

# Iterator interface
Base.IteratorSize(::Type{<:Lexer}) = Base.SizeUnknown()
Base.IteratorEltype(::Type{<:Lexer}) = Base.HasEltype()
Base.eltype(::Type{<:Lexer}) = Token


function Base.iterate(l::Lexer)
    seekstart(l)
    l.token_startpos = position(l)
    l.token_start_row = 1
    l.token_start_col = 1

    l.current_row = 1
    l.current_col = 1
    l.current_pos = l.io_start_pos
    t = next_token(l)
    return t, t.kind == Tokens.EOF
end

function Base.iterate(l::Lexer, isdone::Any)
    isdone && return nothing
    t = next_token(l)
    return t, t.kind == Tokens.EOF
end

function Base.show(io::IO, l::Lexer)
    print(io, typeof(l), " at position: ", position(l))
end

"""
    startpos(l::Lexer)

Return the latest `Token`'s starting position.
"""
startpos(l::Lexer) = l.token_startpos

"""
    startpos!(l::Lexer, i::Integer)

Set a new starting position.
"""
startpos!(l::Lexer, i::Integer) = l.token_startpos = i

Base.seekstart(l::Lexer) = seek(l.io, l.io_start_pos)

"""
    seek2startpos!(l::Lexer)

Sets the lexer's current position to the beginning of the latest `Token`.
"""
seek2startpos!(l::Lexer) = seek(l, startpos(l))

"""
    peekchar(l::Lexer)

Returns the next character without changing the lexer's state.
"""
peekchar(l::Lexer) = l.chars[2]

"""
dpeekchar(l::Lexer)

Returns the next two characters without changing the lexer's state.
"""
dpeekchar(l::Lexer) = l.chars[2], l.chars[3]

"""
peekchar3(l::Lexer)

Returns the next three characters without changing the lexer's state.
"""
peekchar3(l::Lexer) = l.chars[2], l.chars[3], l.chars[4]

"""
    position(l::Lexer)

Returns the current position.
"""
Base.position(l::Lexer) = l.charspos[1]

"""
    eof(l::Lexer)

Determine whether the end of the lexer's underlying buffer has been reached.
"""# Base.position(l::Lexer) = Base.position(l.io)
eof(l::Lexer) = eof(l.io)

Base.seek(l::Lexer, pos) = seek(l.io, pos)

"""
    start_token!(l::Lexer)

Updates the lexer's state such that the next  `Token` will start at the current
position.
"""
function start_token!(l::Lexer)
    l.token_startpos = l.charspos[1]
    l.token_start_row = l.current_row
    l.token_start_col = l.current_col
end

"""
    readchar(l::Lexer)

Returns the next character and increments the current position.
"""
function readchar end


function readchar(l::Lexer)
    c = readchar(l.io)
    l.chars = (l.chars[2], l.chars[3], l.chars[4], c)
    l.charspos = (l.charspos[2], l.charspos[3], l.charspos[4], position(l.io))
    return l.chars[1]
end

"""
    accept(l::Lexer, f::Union{Function, Char, Vector{Char}, String})

Consumes the next character `c` if either `f::Function(c)` returns true, `c == f`
for `c::Char` or `c in f` otherwise. Returns `true` if a character has been
consumed and `false` otherwise.
"""
@inline function accept(l::Lexer, f::Union{Function,Char,Vector{Char},String})
    c = peekchar(l)
    if isa(f, Function)
        ok = f(c)
    elseif isa(f, Char)
        ok = c == f
    else
        ok = c in f
    end
    ok && readchar(l)
    return ok
end

"""
    accept_batch(l::Lexer, f)

Consumes all following characters until `accept(l, f)` is `false`.
"""
@inline function accept_batch(l::Lexer, f)
    ok = false
    while accept(l, f)
        ok = true
    end
    return ok
end

"""
    emit(l::Lexer, kind::Kind)

Returns a `Token` of kind `kind` with contents `str` and starts a new `Token`.
"""
function emit(l::Lexer, kind::Kind)
    tok = Token(kind, startpos(l), position(l) - 1)

    l.last_token = kind
    return tok
end

"""
    emit_error(l::Lexer, err::Kind=Tokens.ERROR)

Returns an `ERROR` token with error `err` and starts a new `Token`.
"""
function emit_error(l::Lexer, err::Kind=ERROR)
    l.errored = true
    @assert is_error(err)
    return emit(l, err)
end


"""
    next_token(l::Lexer)

Returns the next `Token`.
"""
function next_token(l::Lexer, start=true)
    start && start_token!(l)
    if !isempty(l.string_states)
        lex_string_chunk(l)
    else
        _next_token(l, readchar(l))
    end
end

@assert length(instances(Kind)) == 100 "Make sure to come back to `_next_token` wheever `Kind` changes"
function _next_token(l::Lexer, c)
    if eof(c)
        return emit(l, Tokens.EOF)
    elseif isspace(c)
        return lex_space(l, c)
    elseif c == '#'
        return lex_comment(l, c)
    elseif c == '='
        return emit(l, Tokens.EQ)
    elseif c == '\'' || c == '"'
        return lex_string(l, c)
    elseif is_bare_key_start_cahr(c)
        return lex_bare_key(l, c)
    else
        return emit(l, Tokens.NONE)
    end
end

function lex_space(l::Lexer, c)
    k = Tokens.SPACE
    while true
        if c == '\n'
            k = Tokens.NEWLINE
        end
        pc = peekchar(l)

        if !isspace(pc)
            # End the token at `c` if the following character isn't a space
            break
        end

        if k == Tokens.NEWLINE && pc == '\n'
            # Each newline is a token by itself.
            break
        end
        c = readchar(l)
    end
    return emit(l, k)
end

function lex_comment(l::Lexer, c)
    while true
        pc = peekchar(l)
        if pc == '\n' || eof(pc)
            return emit(l, Tokens.COMMENT)
        end
        readchar(l)
    end
end

function lex_string(l::Lexer, c)
    is_multiline_string = dpeekchar(l) == (c, c)
    if is_multiline_string
        readchar(l)
        readchar(l)

        while true
            tc = peekchar3(l)
            if tc == (c, c, c)
                readchar(l)
                readchar(l)
                readchar(l)
                return emit(l, c == '"' ? Tokens.MULTILINE_BASIC_STRING : Tokens.MULTILINE_LITERAL_STRING)
            end
            readchar(l)
        end
    end

    while true
        pc = peekchar(l)

        if pc == c
            readchar(l)
            return emit(l, c == '"' ? Tokens.BASIC_STRING : Tokens.LITERAL_STRING)
        end
        readchar(l)
    end
end

function lex_bare_key(l::Lexer, c)
    while true
        pc = peekchar(l)
        if isspace(pc) || pc == '='
            return emit(l, Tokens.BARE_KEY)
        end
        readchar(l)
    end
end
end # module
