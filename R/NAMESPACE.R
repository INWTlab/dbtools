#' @import aoos
#' @import assertthat
#' @import methods
#' @importFrom RMySQL dbClearResult dbConnect dbDisconnect dbFetch
#' dbHasCompleted dbListResults dbMoreResults dbNextResult dbSendQuery
#' dbWriteTable
#' @importFrom dplyr bind_rows
#' @importFrom futile.logger flog.error
#' @importFrom magrittr %>%
NULL


globalVariables(".")
