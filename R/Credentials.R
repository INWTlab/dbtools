#' Credentials Class
#'
#' Use this function to store your database credentials.
#'
#' @param ... named arguments which can be passed to \link[DBI]{dbConnect}
#' @param drv (function) a driver. Will be called and passed to \link[DBI]{dbConnect}
#' @param x (Credentials) an instance
#'
#' @rdname Credentials
#'
#' @export
list : Credentials(drv ~ "function") %type% {
  assert_that(
    .Object %has_attr% "names",
    all(names(.Object) != "")
  )
  .Object
}

#' @export
#' @rdname Credentials
Credentials <- function(drv, ...) {
  new("Credentials", drv = drv, list(...))
}

#' @export
#' @rdname Credentials
as.list.Credentials <- function(x, ...) {
  c(S3Part(x, TRUE), drv = x@drv())
}

show(object ~ Credentials) %m% {
  cat('An object of class "Credentials"\n')
  lapply(names(object), function(n) cat(n, ": ", object[[n]], "\n"))
}
