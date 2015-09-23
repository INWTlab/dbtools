#' Helper-Class: Single Query
#'
#' Class which represents a single query or a list of single queries. Mostly
#' used internally.
#'
#' @rdname SingleQuery
#'
#' @details
#' \code{SingleQuery} inherits from \code{character} and represents a single query.
#'
#' \code{SingleQueryList} inherits from \code{list} and represents a list of single queries. It can be constructed with a list of character values.
#'
#' @export
character : SingleQuery() %type% {
  assert_that(
    is.scalar(.Object),
    length(unlist(strsplit(.Object, ";"))) == 1,
    grepl(";$", .Object)
  )
  .Object
}

#' @export
#' @rdname SingleQuery
#'
#' @export
list : SingleQueryList() %type% {
  S3Part(.Object) <- Map(SingleQuery, .Object)
  .Object
}
