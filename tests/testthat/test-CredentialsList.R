context("CredentialsList")

test_that("Construction of CredentialsList works", {
  CL1 <- CredentialsList(
    drv = RMySQL::MySQL,
    username = "root",
    dbname = "test",
    port = 1
  )

  CL2 <- Credentials(
    drv = RMySQL::MySQL,
    username = c("root", "user"),
    dbname = "test",
    port = 1:2
  )

  expect_equal(CL1[[1]], CL2[[1]])
  expect_equal(length(CL2), 2)
  expect_error(CredentialsList(
    drv = RMySQL::MySQL,
    dbname = c("t1", "t2"),
    username = paste0("user", 1:3)
  ))
})

