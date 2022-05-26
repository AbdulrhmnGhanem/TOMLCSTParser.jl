using Test
include("../src/TOMLCSTParser.jl")

using .TOMLCSTParser: Tokens as T, tokenize


@testset "tokenize comments" begin
    str = """
    # This is a comment follwed by a new line and an empt line!

          # This is  comment with leading tabs and spaces!
    # This is a comment followed by EOF!"""

    tokenized_str = tokenize(str)

    kinds = [T.COMMENT, T.NEWLINE, T.NEWLINE, T.COMMENT, T.NEWLINE, T.COMMENT, T.EOF]
    for (i, n) in enumerate(tokenized_str)
        @test T.kind(n) == kinds[i]
    end
end

@testset "tokenize bare keys" begin
    bare_keys = """
    bareKey  = # comment
    bare-key = 
    bare_key    = 
    1234="""
    tokenized_bare_keys = tokenize(bare_keys)

    kinds = [T.BARE_KEY, T.SPACE, T.EQ, T.SPACE, T.COMMENT, T.NEWLINE,
        T.BARE_KEY, T.SPACE, T.EQ, T.NEWLINE,
        T.BARE_KEY, T.SPACE, T.EQ, T.NEWLINE,
        T.BARE_KEY, T.EQ, T.EOF]
    for (i, n) in enumerate(tokenized_bare_keys)
        @test T.kind(n) == kinds[i]
    end
end
