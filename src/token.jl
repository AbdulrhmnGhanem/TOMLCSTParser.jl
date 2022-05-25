include("token_kinds.jl")

struct Token
    kind::Kind
    startByte::Int
    endByte::Int
end
