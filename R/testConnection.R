#' Test a connection
#'
#' Test your conncection to local or remote servers. The function will return a
#' logical of length one invisibly with \code{TRUE} for success and \code{FALSE}
#' if any of the connection attempts fail.
#'
#' @param x (Credentials | CredentialsList) a credentials object.
#' @param logger,status (function) a logger function. Has two arguments, first is
#'   \code{x} second is used to indicate success and failure as
#'   \code{logical(1)}.
#' @param ... arguments passed to \link{sendQuery}
#'
#' @examples
#'
#' workingConnection <- Credentials(drv = SQLite, dbname = ":memory:")
#' testConnection(workingConnection)
#'
#' ## To suppress logging:
#' testConnection(workingConnection, loggerSuppress)
#'
#' @export
#' @rdname testConnection
testConnection(x, logger = loggerConnection, ...) %g% standardGeneric("testConnection")

#' @export
#' @rdname testConnection
testConnection(x ~ Credentials, logger, ...) %m% {

  out <- sendQuery(x, "SELECT 1 AS `test`;", ..., errorLogging = function(...) NULL)
  status <- !inherits(out, "try-error")
  logger(x, status)
  invisible(status)

}

#' @export
#' @rdname testConnection
testConnection(x ~ CredentialsList, logger, ...) %m% {
  invisible(vapply(x, testConnection, logical(1), logger = logger, ...) %>% all)
}

#' @export
#' @rdname testConnection
loggerConnection <- function(x, status) {
  statusString <- if (status) "OK" else "FAILED"
  msgString <- paste(as.character(x), collapse = "--")
  futile.logger::flog.info(paste(msgString, statusString, collapse = " -> "))
}

#' @export
#' @rdname testConnection
loggerSuppress <- function(x, status) {
  invisible(NULL)
}
