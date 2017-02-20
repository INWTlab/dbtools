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
#' @param applyFun (function) something like lapply or mclapply
#' @param simplify (logical(1)) whether to simplify results. See details.
#'
#' @details \code{simplify} the default is to simplify results. If you send
#'   multiple queries to one database it is tried to rbind the results - when
#'   you have different column names this can be like a full join. If you send
#'   one query to multiple databases it is tried to rbind the results. If you
#'   send multiple queries to multiple databases, then first the results of the
#'   same query are tried to be rbind, and if possible also the results of each
#'   query. It is considered to be possible iff the names of all data frames
#'   belonging to each query are the same.
#'
#' @return one in:
#' \cr \code{simplify = TRUE} (list | data.frame)
#' \cr \code{simplify = FALSE}: (list) with data frames or nested list of data
#' frames
#' \cr On error: (list) with 'try-catch' objects
#'
#' @include Query.R
#'
#' @examples
#' ## For an example database:
#' library("RSQLite")
#' con <- dbConnect(SQLite(), "example.db")
#' USArrests$State <- rownames(USArrests)
#' dbWriteTable(con, "USArrests", USArrests, row.names = FALSE)
#' dbDisconnect(con)
#'
#' ## Simple Query
#' cred <- Credentials(drv = SQLite, dbname = "example.db")
#' dat <- sendQuery(cred, "SELECT * FROM USArrests;")
#'
#' ## Multiple Similar Queries
#' queryFun <- function(state) {
#'   paste0("SELECT * FROM USArrests WHERE State = '", state, "';")
#' }
#'
#' sendQuery(cred, queryFun(dat$row_names))
#'
#' ## For the Paranoid
#' ### be a bit more cautious with connections
#' dat <- try(sendQuery(
#'   cred,
#'   "SELECT * FROM USArrest;", # wrong name for illustration
#'   tries = 2,
#'   intSleep = 1
#' ))
#'
#' @rdname sendQuery
#' @export
sendQuery(db, query, ...) %g% {
  standardGeneric("sendQuery")
}

#' @rdname sendQuery
#' @export
sendQuery(db ~ CredentialsList|Credentials, query ~ character, ...) %m% {
  # db: either CredentialsList or Credentials
  # query: character
  sendQuery(db, queryConst(query), ...)
}

#' @rdname sendQuery
#' @export
sendQuery(db ~ CredentialsList|Credentials, query ~ SingleQueryList, ..., simplify = TRUE) %m% {
  # db: either CredentialsList or Credentials
  # query: singleQueryList
  lapply(query, sendQuery, db = db, ..., simplify = simplify) %>%
    { simplifyMe(simplify, doRbind)(.) }
}

#' @rdname sendQuery
#' @export
sendQuery(db ~ CredentialsList, query ~ SingleQuery, ..., applyFun = lapply, simplify = TRUE) %m% {
  # db: CredentialsList
  # query: SingleQuery
  applyFun(db, sendQuery, query = query, ..., simplify = FALSE) %>%
  { simplifyMe(simplify, doRbind)(.) }
}

#' @rdname sendQuery
#' @export
sendQuery(db ~ Credentials, query ~ SingleQuery, ...) %m% {
  # db: Credentials
  # query: SingleQuery
  on.exit({
    if (exists("con")) {
      dbDisconnect(con)
    }
  })

  con <- reTry(function(...) do.call(dbConnect, as.list(db)), ...)

  reTry(
    function(...) sendQuery(db = con, query, ...), ...
  )

}

#' @export
#' @rdname sendQuery
sendQuery(db ~ DBIConnection, query ~ SingleQuery, ...) %m% {
  # db: DBIConnection
  # query: SingleQuery
  res <- dbSendQuery(db, query)
  fetchFirstResult(res)

}

#' @export
#' @rdname sendQuery
sendQuery(db ~ MySQLConnection, query ~ SingleQuery, ...) %m% {
  # db: MySQLConnection
  # query: SingleQuery
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

simplifyMe <- function(simplify, fun) {
  function(x) {
    if (simplify) {
      fun(x)
    } else {
      x
    }
  }
}

doRbind <- function(x) {
  # This gets more and more complicated. Basically this is a simplify function.
  # We need some type checking of x, thats what makes this function tricky.
  # Helpers:
  nestedMap <- function(fun, x) do.call(function(...) Map(fun, ...), x)
  sapply <- function(...) unlist(lapply(...))

  check <- function(x, checkFun, ...) {
    if (class(x)[1] == "list") sapply(x, check, checkFun = checkFun, ...)
    else checkFun(x, ...)
  }

  checkDF <- function(x) {
    # x: list
    # Checks if all elements are data frames
    all(check(x, inherits, what = "data.frame"))
  }

  checkNames <- function(x) {
    # x : list
    # Check if all elements have same names as attribute
    compareFun <- function(x, compare) all(compare %in% names(x))
    all(check(x, compareFun, compare = check(x, names)))
  }

  simplifyOutput <- function(x) {
    # x:list

    # reduce to element if list has length equal to 1
    if (length(x) == 1) return(x[[1]])

    # reduce recursively if names of all dfs are equal
    else if (checkNames(x)) return(doRbind(x))

    else return(x)

  }

  if (inherits(x[[1]], "data.frame")) x %>% bind_rows
  else if (checkDF(x)) nestedMap(bind_rows, x) %>% simplifyOutput
  else x

}

fetchFirstResult <- function(res) {
  # Helper used in sendQuery methods.
  on.exit(dbClearResult(res))
  if (!dbHasCompleted(res)) dplyr::as.tbl(dbFetch(res, n = -1))
  else NULL
}

