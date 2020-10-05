#' @import methods
#' @importFrom DBI dbClearResult
#' @importFrom DBI dbConnect
#' @importFrom DBI dbDisconnect
#' @importFrom DBI dbFetch
#' @importFrom DBI dbHasCompleted
#' @importFrom DBI dbSendQuery
#' @importFrom DBI dbWriteTable
#' @importFrom assertthat assert_that
#' @importFrom assertthat %has_attr%
#' @importFrom assertthat "on_failure<-"
#' @importFrom assertthat is.scalar
#' @importFrom data.table as.data.table
#' @importFrom data.table fwrite
#' @importFrom futile.logger flog.error
#' @importFrom futile.logger flog.info
#' @importFrom templates tmpl
#' @importFrom utils capture.output
NULL

#' @importFrom RMariaDB MariaDB
#' @export
RMariaDB::MariaDB

#' @importFrom RMySQL MySQL
#' @export
RMySQL::MySQL

#' @importFrom RMySQL CLIENT_SSL
#' @export
RMySQL::CLIENT_SSL

# We import the link to the C interface for executing queries from RMySQL
# We need this to avoid S4 dispatch and S4 inits which cause performance
# problems. This is dangerous because we rely on implementation detail from
# RMySQL, but currently the best I can think of...
RMySQLExec <- function() eval(parse(text = "RMySQL:::RS_MySQL_exec"))

#' @importFrom RSQLite SQLite
#' @export
RSQLite::SQLite

local({
  # This sets all connection types for S4-dispatch
  types <- c(
    "file", "url", "gzfile", "bzfile", "unz", "pipe",
    "fifo", "sockconn", "terminal", "textConnection",
    "gzcon"
  )

  Map(function(a, b) setOldClass(c(a, b)), types, "connection")

})
