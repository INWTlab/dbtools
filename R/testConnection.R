#' testConnection
#'
#' @param x (Credentials | CredentialsList)
#' @param logging (logical)
#' @param ... arguments passed to \link{sendQuery}
#'
#' @export
#' @rdname testConncection
testConnection(x, logging = TRUE, ...) %g% standardGeneric("testConnection")

#' @export
#' @rdname testConncection
testConnection(x ~ Credentials, logging, ...) %m% {

  logger <- function(x, status) {
    futile.logger::flog.info(paste(x, status, collapse = " -> "))
  }

  out <- try(sendQuery(x, "SELECT 1 AS `test`;", ...), silent = TRUE)

  if (logging) {
    if(inherits(out, "try-error")) {
      logger(as.character(x), "FAILED")
    } else {
      logger(as.character(x), "OK")
    }
  }

  invisible(!inherits(out, "try-error"))

}

#' @export
#' @rdname testConncection
testConnection(x ~ CredentialsList, logging, ...) %m% {
  invisible(vapply(x, testConnection, logical(1), logging = logging, ...) %>% all)
}
