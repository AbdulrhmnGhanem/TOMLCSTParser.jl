const EOF_CHAR = typemax(Char)

eof(io::IO) = Base.eof(io)
eof(c::Char) = c === EOF_CHAR

readchar(io::IO) = eof(io) ? EOF_CHAR : read(io, Char)
