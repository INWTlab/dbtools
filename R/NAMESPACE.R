#' @import aoos
#' @import assertthat
#' @import methods
#' @importFrom RMySQL dbConnect dbDisconnect dbSendQuery dbClearResult dbHasCompleted dbListResults dbMoreResults dbNextResult dbFetch
#' @importFrom dplyr bind_rows
#' @importFrom futile.logger flog.error
#' @importFrom magrittr %>%
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
