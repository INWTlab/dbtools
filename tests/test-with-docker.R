library("dbtools")

TEST <- function(topic, expr, envir = parent.frame()) {
  cat(paste0(topic, ":"))
  res <- try(
    eval(match.call()$expr, envir = new.env(parent = envir))
  )
  if (inherits(res, "try-error")) stop(topic, ": -- F A I L E D --")
  else cat("OK\n")
}

cat("Testing:\n")

testFiles <- list.files("test-with-docker.d", full.names = TRUE)
for (file in testFiles) source(file, new.env())
