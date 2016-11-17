#' SQL Query Objects
#'
#' Data types to represent SQL queries. It should not be necessary to use
#' SingleQuery and SingleQueryList interactively. \code{query} is the generic
#' user interface to generate SQL queries and is based on text parsing.
#'
#' @rdname queries
#'
#' @details
#'
#' \code{SingleQuery} inherits from \code{character} and represents a single
#' query.
#'
#' \code{SingleQueryList} inherits from \code{list} and represents a list of
#' single queries. It can be constructed with a list of character values.
#'
#' @export
Query <- function(.x, ...) {

  query <- queryRead(.x)
  query <- queryEvalTemplate(query, ...)
  
  queryConst(query)

}

queryRead(x) %g% x

queryRead(x ~ connection) %m% {
  query <- readLines(x)
  query <- sub("^#", "", query)
  query <- query[query != ""]               
  query <- paste(query, collapse = "\n")
  query <- unlist(strsplit(query, ";"))
  query <- paste0(query, ";")
  query <- sub("^\\n+", "", query)
  query
}

queryEvalTemplate(x, ...) %g% x

queryEvalTemplate(x ~ list, ...) %m% {
  x <- lapply(x, as.character)
  x <- lapply(x, templates::tmpl, ...)
  x <- lapply(x, as.character)
  x
}

queryEvalTemplate(x ~ character, ...) %m% {
  queryEvalTemplate(as.list(x), ...)
}

queryConst <- function(x) {
  if (length(x) == 1) SingleQuery(x[[1]])
  else SingleQueryList(as.list(x))
} 

#' @exportClass SingleQuery
character : SingleQuery() %type% {
  assert_that(
    is.scalar(.Object),
    length(unlist(strsplit(.Object, ";"))) == 1,
    grepl(";$", .Object)
  )
  .Object
}

#' @exportClass SingleQueryList
list : SingleQueryList() %type% {
  S3Part(.Object) <- Map(SingleQuery, .Object)
  .Object
}

show(object ~ SingleQuery) %m% {
  cat("Query:\n", S3Part(object, TRUE), "\n\n", sep = "")
  invisible(object)
}

show(object ~ SingleQueryList) %m% {
  lapply(object, show)
  invisible(object)
}

## TODO: Some helpful assertions for 
