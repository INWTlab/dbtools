library("dbtools")
library("testthat")

TEST <- function(topic, expr, envir = parent.frame()) {
  cat(paste0(topic, ":"))
  res <- try(
    eval(match.call()$expr, envir = new.env(parent = envir))
  )
  if (inherits(res, "try-error")) {
    stop(topic, ": -- F A I L E D --")
  } else {
    cat("OK\n")
  }
}

cat("Testing:\n")

sink("check.out")
RUN_TESTS <- function() {
  system("bash start-db.sh")
  on.exit(system("bash stop-db.sh"))
  testFiles <- list.files("test-with-docker.d", full.names = TRUE)
  for (file in testFiles) source(file, new.env())
}

RUN_TESTS()
