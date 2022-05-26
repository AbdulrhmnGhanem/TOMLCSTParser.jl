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

