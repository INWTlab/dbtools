#' Re-try the call to a function
#'
#' Tries to call \code{fun}. If the call results in an error, the error is
#' logged and after some time it is tried again.
#'
#' @param fun a function
#' @param ... arguments passed to \code{fun}
#' @param tries number of tries
#' @param intSleep interval in seconds between tries
#' @param errorLogging a function which is called in case of an error with
#'   \code{errorLogging(<try-error>, ...)}
#'
#' @examples
#' ## Something that will fail every once in a while:
#' reTry(
#'   function() if (runif(1) > 0.5) stop(),
#'   tries = 2,
#'   intSleep = 1
#' )
#'
#' ## Disable logging
#' noErrorLogging <- function(x, ...) NULL
#' reTry(
#'   function() stop(),
#'   errorLogging = noErrorLogging
#' )
#'
#' @export
reTry <- function(fun, ..., tries = 1, intSleep = 0, errorLogging = flog.error) {
  out <- NULL
  for (i in 1:tries) {
    if (i > 1) Sys.sleep(intSleep)
    out <- try(fun(...), silent = TRUE)
    if (inherits(out, "try-error")) errorLogging(out, ...)
    else break
  }
  out
}
