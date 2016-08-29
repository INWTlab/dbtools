##' SQL Query Objects
##'
##' Data types to represent SQL queries. It should not be necessary to use
##' SingleQuery and SingleQueryList interactively. \code{query} is the generic
##' user interface to generate SQL queries and is based on text parsing.
##'
##' @rdname queries
##'
##' @details
##' \code{SingleQuery} inherits from \code{character} and represents a single
##' query.
##'
##' \code{SingleQueryList} inherits from \code{list} and represents a list of
##' single queries. It can be constructed with a list of character values.
##'
##' @export
character : SingleQuery() %type% {
  assert_that(
    is.scalar(.Object),
    length(unlist(strsplit(.Object, ";"))) == 1,
    grepl(";$", .Object)
  )
  .Object
}

##' @export
##' @rdname queries
##'
##' @export
list : SingleQueryList() %type% {
  S3Part(.Object) <- Map(SingleQuery, .Object)
  .Object
}

##' @export
##' @rdname queries
Query <- function(...) {
  ## TODO: implement this
  templates::template(...)
}

## TODO: Some helpful assertions for 
