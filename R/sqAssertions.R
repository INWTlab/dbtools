#' SQ Assertions and Formats
#'
#' These functions can be used to format and check the input of queries.
#'
#' @param x (ANY) input
#' @param pattern (character) a regular expression used in \link{grepl}
#' @param negate (logical) if TRUE then an error is thrown if at least one of
#'   the elements in x match pattern. If FALSE all elements in x must match the
#'   pattern.
#' @param assert (function) an assertion fuction
#' @param with (character)
#' 
#' @rdname sqAssertions
#' @export
#'
#' @examples
#' # Will format and check:
#' sqInStrs(letters[1:2])
#' sqInNums(1:2)
#' sqNames(letters[1:2])
#' sqNames("a")
#'
#' # Only check:
#' sqNum(1)
#' sqNums(1:2)
#' sqChar("a")
#' sqChars(letters[1:2])
sqPattern <- function(x, pattern, negate = TRUE) {

  matchesPattern <- function(x, pattern, negate) {
    reducer <- if (negate) any else all
    res <- reducer(grepl(pattern, x))
    if (negate) !res
    else res
  }

  on_failure(matchesPattern) <- function(call, env) {
    paste0(
      "Sanity check failed. Input contains illegal character.\n",
      env$x, "\nshould ", if(env$negate) "not" else "", "match\n", env$pattern
    )   
  }

  assert_that(matchesPattern(x, pattern, negate))
  x
  
}

#' @rdname sqAssertions
#' @export
sqChar <- function(x) {
  stopifnot(length(x) == 1)
  sqChars(x)
}

#' @rdname sqAssertions
#' @export
sqChars <- function(x) {
  punct <- "[\\!\\`\\$\\*\\+\\.\\?\\[\\^\\{\\|\\(\\\\]"
  pattern <- paste0("[ \n\t]|[0-9]|", punct)
  sqPattern(x, pattern, TRUE)  
}

#' @rdname sqAssertions
#' @export
sqNum <- function(x) {
  stopifnot(length(x) == 1)
  sqNums(x)
}

#' @rdname sqAssertions
#' @export
sqNums <- function(x) {
  punct <- "[\\!\\`\\$\\*\\+\\?\\[\\^\\{\\|\\(\\\\]" # allows "."
  pattern <- paste0("[ \n\t]|[a-z]|[A-Z]|", punct)
  sqPattern(x, pattern, TRUE)
} 

#' @rdname sqAssertions
#' @export
sqParan <- function(x, assert = identity) {
  paste0("(", sqComma(x, assert), ")")
}

#' @rdname sqAssertions
#' @export
sqComma <- function(x, assert = identity) {
  paste0(assert(x), collapse = ", ")
}

#' @rdname sqAssertions
#' @export
sqEsc <- function(x, assert = identity, with = "`") {
  sqComma(paste0(with, assert(x), with))
}

#' @rdname sqAssertions
#' @export
sqName <- function(x) {
  sqEsc(x, sqChar)
}

#' @rdname sqAssertions
#' @export
sqNames <- function(x) {
  sqEsc(x, sqChars)
}

#' @rdname sqAssertions
#' @export
sqInNums <- function(x) {
  sqParan(x, sqNums)
}

#' @rdname sqAssertions
#' @export
sqInStrs <- function(x) {
  sqParan(x, function(x) sqEsc(x, sqChars, "\""))
}
