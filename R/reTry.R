#' Re-try the call to a function
#'
#' Tries to call \code{fun}. If the call results in an error, the error is
#' logged and after some time it is tried again. If the final try results in an
#' error the function throws an error. Otherwise th result of fun is returned.
#'
#' @param fun (function) a function
#' @param ... arguments passed to \code{fun}
#' @param tries (numeric > 0) number of tries
#' @param intSleep (numeric >= 0) interval in seconds between tries
#' @param errorLogging (function) a function which is called in case of an error with
#'   \code{errorLogging(<try-error>, ...)}
#'
#' @examples
#' ## Something that will fail every once in a while:
#' try(reTry(
#'   function() if (runif(1) > 0.5) stop(),
#'   tries = 2,
#'   intSleep = 1
#' ))
#'
#' ## Disable logging
#' noErrorLogging <- function(x, ...) NULL
#' try(reTry(
#'   function() stop(),
#'   errorLogging = noErrorLogging
#' ))
#'
#' @export
reTry <- function(fun, ..., tries = 1, intSleep = 0, errorLogging = flog.error) {

  assert_that(
    is.function(fun),
    is.function(errorLogging),
    is.numeric(tries),
    is.numeric(intSleep)
  )

  out <- NULL

  for (i in 1:tries) {
    if (i > 1) Sys.sleep(intSleep)
    out <- try(fun(...), silent = TRUE)
    if (inherits(out, "try-error")) errorLogging(out, ...)
    else break
  }

  if (inherits(out, "try-error")) stop(out)
  else out

}
