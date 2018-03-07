#' @import methods
#' @importFrom DBI dbClearResult
#' @importFrom DBI dbConnect
#' @importFrom DBI dbDisconnect
#' @importFrom DBI dbFetch
#' @importFrom DBI dbHasCompleted
#' @importFrom DBI dbSendQuery
#' @importFrom DBI dbWriteTable
#' @importFrom aoos %g%
#' @importFrom aoos %m%
#' @importFrom aoos %type%
#' @importFrom assertthat assert_that
#' @importFrom assertthat %has_attr%
#' @importFrom assertthat "on_failure<-"
#' @importFrom assertthat is.scalar
#' @importFrom dat flatmap
#' @importFrom data.table fwrite
#' @importFrom futile.logger flog.error
#' @importFrom futile.logger flog.info
#' @importFrom templates tmpl
#' @importFrom tibble as_data_frame
#' @importFrom utils capture.output
NULL

#' @importFrom RMariaDB MariaDB
#' @export
RMariaDB::MariaDB

#' @importFrom RMySQL MySQL
#' @export
RMySQL::MySQL

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
