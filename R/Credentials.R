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
#' @examples
#' Credentials(drv = RSQLite::SQLite, dbname = ":memory:")
#' Credentials(drv = RSQLite::SQLite, dbname = c(":memory:", ":memory:"))
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
  args <- list(...)
  if (any(sapply(args, length) > 1)) {
    new("CredentialsList", c(list(...), list(drv = drv)))
  } else {
    new("Credentials", drv = drv, list(...))
  }
}

#' @export
#' @rdname Credentials
as.list.Credentials <- function(x, ...) {
  c(S3Part(x, TRUE), drv = x@drv())
}

#' @export
#' @rdname Credentials
as.character.Credentials <- function(x, ...) {
  passphrases <- grepl("^(pswd|pwd|pass|password)$", names(x))
  if (any(passphrases)) x[passphrases] <- "****"
  as.character.default(x)
}

show(object ~ Credentials) %m% {
  cat('An object of class "Credentials"\n', sep = "")
  cat('drv:', class(object@drv()), "\n", sep = "")
  cat(paste0(names(object), ": ", as.character(object)), sep = "\n")
  invisible(object)
}


#' @export
#' @rdname Credentials
list : CredentialsList() %type% {

  # Validate input:
  has_valid_lengths <- function(.Object) {
    lengths <- unlist(lapply(.Object, length))
    validLengths <- c(min(lengths), max(lengths))
    all(lengths %in% validLengths)
  }

  on_failure(has_valid_lengths) <- function(call, env) {
    paste0("Don't know how to devide these arguments into distinct Credentials.
           This error can occur when the arguments have different lengths.")
  }

  # Helper function
  makeCredList <- function(.Object) {
    if (is.function(.Object$drv)) .Object$drv <- list(.Object$drv)
    maxLength <- max(unlist(lapply(.Object, length)))
    wideList <- lapply(.Object, . %>% rep(length.out = maxLength))
    spreadOutList <- lapply(1:maxLength, . %>% lapply(X = wideList, `[[`, i = .))
    lapply(spreadOutList, . %>% do.call(what = Credentials, args = .))
  }

  # Init:
  assert_that(has_valid_lengths(.Object))
  S3Part(.Object) <- makeCredList(.Object)
  .Object

}

#' @export
#' @rdname Credentials
#' @details \code{CredentialsList} can be used to construct a list of Credential
#'   objects. The advantage is, that all arguments can be vectors. Elements of
#'   length one are replicated to match the appropriate number of credentials.
#'   This is usefull whenever you run the same query on multiple databases where
#'   they only differ in the port but else expect the same credentials.
CredentialsList <- function(...) {
  new("CredentialsList", list(...))
}
