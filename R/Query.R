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
#' @param checkSemicolon (logical) Should be left with the default. Set to
#'   false only in case you want to allow for semicolons within the query.
#' @param keepComments (logical) In most cases it is safe(er) to remove comments
#'   from a query. When you want to keep them set the argument to \code{TRUE}.
#'   This only applies when \code{.x} is a file.
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
Query <- function(.x, ..., .data = NULL, .envir = parent.frame(),
                  checkSemicolon = TRUE, keepComments = FALSE) {

  query <- queryRead(.x, keepComments)
  query <- queryEvalTemplate(query, .data, .envir = .envir, ...)

  queryConst(query, checkSemicolon = checkSemicolon)

}

setGeneric("queryRead", function(x, ...) x)

setMethod("queryRead", "connection", function(x, keepComments, ...) {

  on.exit(close(x))

  query <- readLines(x)
  query <- if (keepComments) query else sub("(-- .*)|(#.*)", "", query)
  query <- query[query != ""]
  query <- paste(query, collapse = "\n")
  query <- if (keepComments) query else gsub("(\\\n)?/\\*.*?\\*/", "", query)
  query <- unlist(strsplit(query, ";"))
  query <- paste0(query, ";")
  query <- sub("^\\n+", "", query)
  query

})

setGeneric("queryEvalTemplate", function(x, .data, ...) x)

setMethod("queryEvalTemplate", c(x = "list", .data = NULL), function(x, .data, ...) {
  x <- lapply(x, as.character)
  x <- lapply(x, tmpl, ...)
  x <- lapply(x, as.character)
  x
})

setMethod("queryEvalTemplate", c(x = "character", .data = "ANY"), function(x, .data, ...) {
  queryEvalTemplate(as.list(x), .data, ...)
})

setMethod("queryEvalTemplate", c(x = "list", .data = "data.frame"), function(x, .data, ...) {
  queryEvalTemplate(x, as.list(.data), ...)
})

setMethod("queryEvalTemplate", c(x = "list", .data = "list"), function(x, .data, ...) {

  localQueryEval <- function(...) {
    do.call(
      queryEvalTemplate,
      c(list(x = x, .data = NULL), fixedDots, ...)
    )
  }

  fixedDots <- list(...)

  do.call(Map, c(list(f = localQueryEval), .data))

})

queryConst <- function(x, checkSemicolon) {
  if (length(x) == 1) SingleQuery(x[[1]], checkSemicolon = checkSemicolon)
  else SingleQueryList(as.list(x), checkSemicolon = checkSemicolon)
}

#' @exportClass SingleQuery
#' @rdname queries
setClass("SingleQuery", slots = c(checkSemicolon = "logical"), contains = "character")

setMethod("initialize", "SingleQuery", function(.Object, checkSemicolon, ...) {
  .Object <- callNextMethod()
  assert_that(
    is.scalar(.Object),
    grepl(";$", .Object),
    if (.Object@checkSemicolon)
      length(unlist(strsplit(.Object, ";"))) == 1 else TRUE
  )
  .Object
})

SingleQuery <- function(..., checkSemicolon = TRUE) new(
  'SingleQuery', checkSemicolon = checkSemicolon, ...
)

#' @exportClass SingleQueryList
#' @rdname queries
setClass("SingleQueryList", slots = c(checkSemicolon = "logical"), contains = "list")

setMethod("initialize", "SingleQueryList", function(.Object, checkSemicolon, ...) {
  .Object <- callNextMethod()
  S3Part(.Object) <- lapply(.Object, SingleQuery, checkSemicolon = .Object@checkSemicolon)
  .Object
})

SingleQueryList <- function(..., checkSemicolon = TRUE) new(
  'SingleQueryList', checkSemicolon = checkSemicolon, ...
)

setMethod("show", "SingleQuery", function(object) {
  cat("Query:\n", S3Part(object, TRUE), "\n\n", sep = "")
  invisible(object)
})

setMethod("show", "SingleQueryList", function(object) {
  lapply(object, show)
  invisible(object)
})
