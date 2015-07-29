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

  reTry(sendQuery, db = db, query = query, ...)

}

#' @rdname sendQuery
#' @export
sendQuery.list <- function(db, query, ...) {
  # db: is a list
  # query: is a character vector of queries

  prepareForReturn <- function(datList) {
    if(sapply(datList, is.null) %>% any) {
      NULL
    } else {
      datList %>% rbind_all %>% as.data.frame
    }
  }

  on.exit({
    if(exists("con")) {
      dbDisconnect(con)
    }
  })

  con <- do.call(dbConnect, db)
  sendQuery(con, "SET NAMES 'utf8';")
  downloadedData <- lapply(query, sendQuery, db = con)
  downloadedData <- prepareForReturn(downloadedData)

  wrngs <- sendQuery(con, "SHOW WARNINGS;")
  if (nrow(wrngs) > 0) warning(wrngs)

  downloadedData

}

#' @export
#' @rdname sendQuery
sendQuery.default <- function(db, query, ...) {
  # db: is a connection
  # query: is a character of length 1

  stopifnot(inherits(db, "DBIConnection"))

  fetchFirstResult <- function(res) {
    on.exit(dbClearResult(res))
    if (dbHasCompleted(res)) dbFetch(res, n = -1)
    else NULL
  }

  dumpRemainingResults <- function(con) {
    while (dbMoreResults(con)) {
      dump <- dbNextResult(con)
      dbClearResult(dump)
    }
  }

  res <- suppressWarnings(dbSendQuery(db, query))
  dat <- fetchFirstResult(res)
  dumpRemainingResults(db)
  dat

}
