module Tokens
export Token

include("token_kinds.jl")

struct Token
    kind::Kind
    startbyte::Int
    endbyte::Int
end

function kind(t::Token)
    k = t.kind
    is_key(k) && return KEY
    is_value(k) && return VALUE
    is_error(k) && return Err
    return k
end

exactkind(t::Token) = t.kind


startbyte(t::Token) = t.startbyte
endbyte(t::Token) = t.endbyte


function untokenize(t::Token, str::String)
    String(codeunits(str)[1 .+ (t.startbyte:t.endbyte)])
end

function Base.show(io::IO, t::Token)
    print(io, rpad(string(startbyte(t), "-", endbyte(t)), 11, " "))
    print(io, rpad(kind(t), 15, " "))
end
end # module
