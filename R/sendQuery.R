#' Send query to database and fetch result
#'
#' This functions sends a query to a database and fetches the result.
#'
#' @param db one in:
#'   \cr (\link{Credentials}) the credentials to get a connection to a database.
#'   \cr (DBIConnection) \link[DBI]{DBIConnection-class}
#'   \cr (MySQLConnection) \link[RMySQL]{MySQLConnection-class}
#' @param query one in:
#'   \cr (character, length >= 1) a query
#'   \cr (SingleQuery | SingleQeuryList) \link{SingleQuery-class} is mostly used
#'   internally.
#' @param ... one in:
#'   \cr for signature (Credentials, character | SingleQueryList) arguments are
#'   passed to \code{reTry}
#'   \cr for signature (CredentialsList) arguments are passed to the
#'   (Credentials) method, so implicitly to reTry
#'   \cr else ignored
#'
#' @include helperClass.R
#'
#' @examples
#' ## For an example database:
#' library("RSQLite")
#' con <- dbConnect(SQLite(), "example.db")
#' data(USArrests)
#' dbWriteTable(con, "USArrests", USArrests)
#' dbDisconnect(con)
#'
#' ## Simple Query
#' cred <- Credentials(drv = RSQLite::SQLite, dbname = "example.db")
#' dat <- sendQuery(cred, "SELECT * FROM USArrests;")
#'
#' ## Multiple Similar Queries
#' queryFun <- function(state) {
#'   paste0("SELECT * FROM USArrests WHERE row_names = '", state, "';")
#' }
#'
#' sendQuery(cred, queryFun(dat$row_names))
#'
#' ## For the Paranoid
#' ### be a bit more cautious with connections
#' dat <- sendQuery(
#'   cred,
#'   "SELECT * FROM USArrest;", # wrong name for illustration
#'   tries = 2,
#'   intSleep = 1
#' )
#'
#' @rdname sendQuery
#' @export
sendQuery(db, query, ...) %g% {
  standardGeneric("sendQuery")
}

#' @rdname sendQuery
#' @export
sendQuery(db ~ CredentialsList, query ~ character, ...) %m% {
  # db: is of class 'CredentialsList'
  # query: is probably a character or query
  lapply(db, sendQuery, query = query, ...) %>% doRbind
}


#' @rdname sendQuery
#' @export
sendQuery(db ~ Credentials, query ~ character, ...) %m% {
  # db: is of class 'Credentials' containing db creds
  # query: should be a character vector
  sendQuery(db, SingleQueryList(as.list(query)), ...)
}

#' @rdname sendQuery
#' @export
sendQuery(db ~ Credentials, query ~ SingleQueryList, ...) %m% {
  # db: is a list
  # query: is a single query

  on.exit({
    if (exists("con")) {
      dbDisconnect(con)
    }
  })

  con <- do.call(dbConnect, as.list(db))
  downloadedData <- reTry(
    function(...) lapply(query, . %>% sendQuery(db = con, ...)),
    ...
  )

  downloadedData %>% doRbind

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

doRbind <- function(x) {
  if (inherits(x[[1]], "data.frame")) x %>% bind_rows
  else x
}

fetchFirstResult <- function(res) {
  # Helper used in sendQuery methods.
  on.exit(dbClearResult(res))
  if (!dbHasCompleted(res)) dbFetch(res, n = -1)
  else NULL
}

