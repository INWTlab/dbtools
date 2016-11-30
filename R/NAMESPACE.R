#' @import aoos
#' @import assertthat
#' @import methods
#' @importFrom DBI dbClearResult dbConnect dbDisconnect dbFetch dbHasCompleted
#' dbListResults dbSendQuery dbWriteTable
#' @importFrom RMySQL dbMoreResults dbNextResult
#' @importFrom dplyr bind_rows
#' @importFrom futile.logger flog.error
#' @importFrom magrittr %>%
#' @importFrom readr write_delim
NULL


globalVariables(".")

#' @importFrom RMySQL MySQL
#' @export
RMySQL::MySQL

#' @importFrom RSQLite SQLite
#' @export
RSQLite::SQLite
