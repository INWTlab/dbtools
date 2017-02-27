#' @import methods
#' @importFrom aoos %g% %m% %type%
#' @importFrom assertthat assert_that %has_attr% "on_failure<-" is.scalar
#' @importFrom dat flatmap
#' @importFrom DBI dbClearResult dbConnect dbDisconnect dbFetch dbHasCompleted
#' dbListResults dbSendQuery dbWriteTable
#' @importFrom RMySQL dbMoreResults dbNextResult
#' @importFrom data.table fwrite
#' @importFrom dplyr bind_rows
#' @importFrom futile.logger flog.error
#' @importFrom magrittr %>%
#' @importFrom templates tmpl
NULL

globalVariables(".")

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
