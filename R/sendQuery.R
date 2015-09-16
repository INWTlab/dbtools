#' Send query to database and fetch result
#'
#' This functions sends a query to a database and fetches the result.
#'
#' @param db (Credentials) the credentials to get a connection to a database.
#' @param query (character, length >= 1) a query.
#' @param ... arguments passed to \code{reTry}
#'
#' @include helperClass.R
#' @rdname sendQuery
#' @export
sendQuery(db, query, ...) %g% standardGeneric("sendQuery")

#' @rdname sendQuery
#' @export
sendQuery(db ~ Credentials, query ~ character, ...) %m% {
  # db: is of class 'Credentials' containing db creds
  # query: should be a character vector

  query <- as.character(query)
  db <- as.list(db)

  doRbind <- function(x) {
    if (inherits(x[[1]], "data.frame")) x %>% bind_rows
    else x
  }

  iterQuery <- function(query, ...) {
    lapply(query, function(q) reTry(sendQuery, db = ArgList(db), query = SingleQuery(q), ...))
  }

  iterQuery(query, ...) %>% doRbind

}

#' @rdname sendQuery
#' @export
sendQuery(db ~ ArgList, query ~ SingleQuery, ...) %m% {
  # db: is a list
  # query: is a single query

  on.exit({
    if (exists("con")) {
      dbDisconnect(con)
    }
  })

  con <- do.call(dbConnect, db)
  downloadedData <- sendQuery(con, query)

  downloadedData

}

#' @export
#' @rdname sendQuery
sendQuery(db ~ DBIConnection, query ~ SingleQuery, ...) %m% {
  # db: is a connection
  # query: is a character of length 1

  res <- dbSendQuery(db, query)
  fetchFirstResult(res)

}

#' @export
#' @rdname sendQuery
sendQuery(db ~ MySQLConnection, query ~ SingleQuery, ...) %m% {
  # db: is a MySQL connection
  # query: is a character of length 1

  dbSendQuery <- function(...) {
    suppressWarnings(RMySQL::dbSendQuery(...))
  }

  setNamesUtf8 <- function(con) {
    dbSendQuery(con, "SET NAMES 'utf8';")
  }

  dumpRemainingResults <- function(con) {
    while (dbMoreResults(con)) {
      dump <- dbNextResult(con)
      dbClearResult(dump)
    }
  }

  checkForWarnings <- function(con) {
    wrngs <- dbSendQuery(con, "SHOW WARNINGS;") %>% fetchFirstResult
    if (nrow(wrngs) > 0) warning(wrngs)
  }

  setNamesUtf8(db)
  res <- dbSendQuery(db, query)
  dat <- fetchFirstResult(res)
  dumpRemainingResults(db)
  checkForWarnings(db)
  dat

}

fetchFirstResult <- function(res) {
  # Helper used in sendQuery methods.
  on.exit(dbClearResult(res))
  if (!dbHasCompleted(res)) dbFetch(res, n = -1)
  else NULL
}

