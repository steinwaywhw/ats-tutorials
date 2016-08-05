




extern fun hello (): string
implement hello () = "world"

implement main0 () = () where {
	val _ = println! (hello ())
}