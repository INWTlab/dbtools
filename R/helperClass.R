#' Helper-Class: Argument List
#'
#' Class to be used as argument in \code{do.call}. Inherits from list.
#'
#' @export
list : ArgList() %type% .Object

#' Helper-Class: Single Query
#'
#' Class which represents a single query
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
