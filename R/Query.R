#' SQL Query Objects
#'
#' Data types to represent SQL queries. It should not be necessary to use
#' SingleQuery and SingleQueryList interactively. \code{Query} is the generic
#' user interface to generate SQL queries and is based on text parsing.
#'
#' @param .x (character | connection) A character or connection containing a
#'   query.
#' @param ... Parameters to be substituted in .x
#' @param .data (list)
#' @param .envir (environment) Should be left with the default. Sets the
#'   environment in which to evaluate code chunks in queries.
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
#' @examples
#' query1 <- "SELECT {{ varName }} FROM {{ tableName }} WHERE primaryKey = {{ id }};"
#' query2 <- "SHOW TABLES;"
#'
#' Query(query1, varName = "someVar", tableName = "someTable", .data = list(id = 1:2))
#'
#' tmpFile <- tempfile()
#' writeLines(c(query1, query2), tmpFile)
#' Query(file(tmpFile))
#' @export
Query <- function(.x, ..., .data = NULL, .envir = parent.frame()) {

  query <- queryRead(.x)
  query <- queryEvalTemplate(query, .data, .envir = .envir, ...)

  queryConst(query)

}

queryRead(x) %g% x

queryRead(x ~ connection) %m% {
  on.exit(close(x))

  query <- readLines(x)
  query <- query[query != ""]
  query <- paste(query, collapse = "\n")
  query <- unlist(strsplit(query, ";"))
  query <- paste0(query, ";")
  query <- sub("^\\n+", "", query)
  query

}

queryEvalTemplate(x, .data, ...) %g% x

queryEvalTemplate(x ~ list, .data ~ NULL, ...) %m% {
  x <- lapply(x, as.character)
  x <- lapply(x, tmpl, ...)
  x <- lapply(x, as.character)
  x
}

queryEvalTemplate(x ~ character, .data ~ ANY, ...) %m% {
  queryEvalTemplate(as.list(x), .data, ...)
}

queryEvalTemplate(x ~ list, .data ~ data.frame, ...) %m% {
  queryEvalTemplate(x, as.list(.data), ...)
}

queryEvalTemplate(x ~ list, .data ~ list, ...) %m% {

  localQueryEval <- function(...) {
    do.call(
      queryEvalTemplate,
      c(list(x = x, .data = NULL), fixedDots, ...)
    )
  }

  fixedDots <- list(...)

  do.call(Map, c(list(f = localQueryEval), .data))

}

queryConst <- function(x) {
  if (length(x) == 1) SingleQuery(x[[1]])
  else SingleQueryList(as.list(x))
}

#' @exportClass SingleQuery
#' @rdname queries
character : SingleQuery() %type% {
  assert_that(
    is.scalar(.Object),
    length(unlist(strsplit(.Object, ";"))) == 1,

    grepl(";$", .Object)
  )
  .Object
}

#' @exportClass SingleQueryList
#' @rdname queries
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
