context("CredentialsList")

test_that("Construction of CredentialsList works", {
  CL1 <- CredentialsList(
    drv = MySQL,
    username = "root",
    dbname = "test",
    port = 1
  )

  CL2 <- Credentials(
    drv = MySQL,
    username = c("root", "user"),
    dbname = "test",
    port = 1:2
  )

  expect_equal(CL1[[1]], CL2[[1]])
  expect_equal(length(CL2), 2)
  expect_error(CredentialsList(
    drv = MySQL,
    dbname = c("t1", "t2"),
    username = paste0("user", 1:3)
  ))

})

test_that("Password are suppressed in print", {

  cred <- Credentials(
    drv = MySQL,
    username = "user",
    password = "1234",
    dbname = "..."
  )

  testthat::expect_output(print(cred), "\\*\\*\\*\\*")
  testthat::expect_equal(as.character(cred), c("user", "****", "..."))

})

