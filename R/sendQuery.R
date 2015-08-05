#' Send query to database and fetch result
#'
#' This functions sends a query to a database and fetches the result.
#'
#' @param db a database
#' @param query a query
#' @param ... arguments passed to \code{reTry}
#'
#' @rdname sendQuery
#' @export
sendQuery <- function(db, query, ...) UseMethod("sendQuery")

#' @rdname sendQuery
#' @export
sendQuery.DBCredentials <- function(db, query, ...) {

  query <- as.character(query)
  db <- as.list(db)

  doRbind <- function(x) {
    if (inherits(x[[1]], "data.frame")) x %>% rbind_all %>% as.data.frame
    else x
  }

  iterQuery <- function(query, ...) {
    lapply(query, function(q) reTry(sendQuery, db = db, query = q, ...)) %>% doRbind
  }

  iterQuery(query, ...)

}

#' @rdname sendQuery
#' @export
sendQuery.list <- function(db, query, ...) {
  # db: is a list
  # query: is a character vector of queries

  on.exit({
    if(exists("con")) {
      dbDisconnect(con)
    }
  })

  con <- do.call(dbConnect, db)
  downloadedData <- sendQuery(con, query)

  downloadedData

}

#' @export
#' @rdname sendQuery
sendQuery.DBIConnection <- function(db, query, ...) {
  # db: is a connection
  # query: is a character of length 1

  res <- dbSendQuery(db, query)
  dat <- fetchFirstResult(res)
  dat

}

#' @export
#' @rdname sendQuery
sendQuery.MySQLConnection <- function(db, query, ...) {

  dbSendQuery <- function(...) {
    suppressWarnings( RMySQL::dbSendQuery(...) )
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
    wrngs <- sendQuery(con, "SHOW WARNINGS;")
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

