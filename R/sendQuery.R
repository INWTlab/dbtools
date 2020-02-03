#' Send query to database and fetch result
#'
#' This functions sends a query to a database and fetches the result.
#'
#' @param db one in: \cr (\link{Credentials}) the credentials to get a
#'   connection to a database.  \cr (DBIConnection)
#'   \link[DBI]{DBIConnection-class} \cr (MySQLConnection)
#'   \link[RMySQL]{MySQLConnection-class}
#' @param query one in: \cr (character, length >= 1) a query \cr (SingleQuery |
#'   SingleQeuryList) \link{SingleQuery-class} is mostly used internally.
#' @param ... one in: \cr for signature (Credentials, character |
#'   SingleQueryList) arguments are passed to \code{reTry} \cr for signature
#'   (CredentialsList) arguments are passed to the (Credentials) method, so
#'   implicitly to reTry \cr else ignored
#' @param applyFun (function) something like lapply or mclapply
#' @param simplify (logical(1)) whether to simplify results. See details.
#' @param encoding (character | NULL) the encoding used in a \code{SET NAMES}
#'   statement. Currently only implemented for MySQL connections. The
#'   default is 'utf8'. Use \code{NULL} if you do not want to set the encoding.
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
sendQuery(db ~ CredentialsList, query ~ SingleQueryList, ...,
          applyFun = lapply, simplify = TRUE) %m% {

  insideOut <- function(x) {
    if (isNestedList(x)) {
      do.call(mapply, c(FUN = list, x, SIMPLIFY = FALSE, recursive = FALSE))
    } else {
      x
    }
  }

  isNestedList <- function(x) {
    is.list(x) && all(unlist(lapply(x, is, class2 = "list")))
  }

  res <- applyFun(db, sendQuery, query = query, ..., simplify = FALSE)
  res <- insideOut(res)
  simplifyIfPossible(res, skipBindRows = !simplify)

}


#' @rdname sendQuery
#' @export
sendQuery(db ~ Credentials | CredentialsList, query ~ character, ...) %m% {
  sendQuery(db, SingleQueryList(as.list(query)), ...)
}

#' @rdname sendQuery
#' @export
sendQuery(db ~ Credentials, query ~ SingleQueryList, ..., simplify = TRUE) %m% {
  # db: is a list
  # query: is a single query

  downloadedData <- reTry(..., fun = function(...) {

    on.exit({
      if (exists("con")) {
        dbDisconnect(con)
      }
    })

    con <- do.call(dbConnect, as.list(db))
    lapply(query, sendQuery, db = con, ...)

  })

  simplifyIfPossible(downloadedData, skipBindRows = !simplify)

}

#' @export
#' @rdname sendQuery
sendQuery(db ~ DBIConnection, query ~ SingleQuery, ...) %m% {
  # db: is a connection
  # query: is a character of length 1

  res <- dbSendQuery(db, query)
  fetchResult(res)

}

#' @export
#' @rdname sendQuery
sendQuery(db ~ MySQLConnection, query ~ SingleQuery, ..., encoding = "utf8mb4") %m% {
  # db: is a MySQL connection
  # query: is a character of length 1
  .sendQuery(db, query, ..., encoding = encoding)
}

#' @export
#' @rdname sendQuery
sendQuery(db ~ MariaDBConnection, query ~ SingleQuery, ..., encoding = "utf8mb4", tz = "Europe/Berlin") %m% {
  # db: is a MySQL connection
  # query: is a character of length 1
  dat <- .sendQuery(db, query, ..., encoding = encoding)
  dat <- fixTimezone(dat, tz = tz)
}

.sendQuery <- function(db, query, ..., encoding) {
  setNamesEncoding(db, encoding)
  dat <- sendQueryDb(db, query)
  checkForWarnings(db)
  dat
}

simplifyIfPossible <- function(x, skipCase4 = FALSE, skipBindRows = FALSE) {

  # skipCase4 (logical) case 4 can lead (however unlikely) to an infinite
  # recursion. This parameter is used so this can never happen.

  # Cases:
  # 1. Single Credentials + SingleQuery: list[df] -> df
  # 2. Single Credentials + Multiple Queries: list[dfs] -> df (same as case 3) | list[dfs]
  # 3. Multiple Credentials + Single Query: list[dfs] -> df
  # 4. Multiple Credentials + Multiple Queries: list[lists[dfs]] -> df | list[dfs]

  allEqual <- function(x) {
    all(unlist(lapply(x, function(y) all(y == x[[1]]))))
  }

  haveEqualNames <- function(x) {
    allEqual(lapply(x, names))
  }

  allDataFrames <- function(x) {
    all(unlist(lapply(x, is, class2 = "data.frame")))
  }

  allLists <- function(x) {
    all(unlist(lapply(x, is, class2 = "list")))
  }

  isCase1 <- function(x) isCase2(x) && (length(x) == 1)
  isCase2 <- function(x) is.list(x) && allDataFrames(x)
  isCase3 <- function(x) !skipBindRows && isCase2(x) && haveEqualNames(x)
  isCase4 <- function(x) !skipBindRows && !skipCase4 && is.list(x) && allLists(x)

  if (isCase4(x)) {
    simplifyIfPossible(lapply(x, simplifyIfPossible, TRUE), TRUE)
  } else if (isCase1(x)) {
    x[[1]]
  } else if (isCase3(x)) {
    do.call("rbind", x)
  } else {
    x
  }

}

sendQueryDb <- function(...) {
  res <- suppressWarnings(dbSendQuery(...))
  fetchResult(res)
}

fetchResult <- function(res) {
  # Helper used in sendQuery methods.
  on.exit(dbClearResult(res))
  if (!dbHasCompleted(res))
    as.data.table(dbFetch(res, n = -1))
  else NULL
}

setNamesEncoding <- function(con, encoding) {
  if (is.null(encoding)) return(NULL)
  sendQueryDb(con, paste0("SET NAMES '", encoding, "';"))
}

checkForWarnings <- function(con) {
  res <- sendQueryDb(con, "SHOW WARNINGS;")
  if (!is.null(res) && nrow(res) > 0) {
    warn <- formatWarnings(res)
    warning(warn)
  }
}

formatWarnings <- function(dat) {
  dat <- capture.output(dat)
  dat <- paste(dat, collapse = "\n")
  dat
}

fixTimezone <- function(dat, tz) {
  timeFields <- unlist(lapply(dat, inherits, what = "POSIXct"))
  if (length(timeFields) == 0) return(dat)

  lapply(names(dat)[timeFields], function(n) {
    dat[, get(n)] <<- forceTZ(dat[, get(n)], tz = tz)
  })
  dat
}

forceTZ <- function(x, tz) {
  attr(x, "tzone") <- "UTC"
  x <- as.character(x)
  as.POSIXct(x, tz = tz)
}
