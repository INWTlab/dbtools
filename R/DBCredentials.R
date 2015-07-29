#' DBCredentials constructor
#'
#' Funktion can be used to construct a new credentials object

#' @param ... arguments which can be passed to \code{dbConnect}
#'
#' @export
DBCredentials <- function(...) {
  .argList <- list(...)
  as.list <- function() {
    copyOfArgList <- .argList
    copyOfArgList$drv <- .argList$drv()
    copyOfArgList
  }
  retList("DBCredentials")
}

#' @export
as.list.DBCredentials <- function(x, ...) x$as.list()
