context("Credentials")

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

test_that("Extract credentials from CredentialsList", {
  credList <- dbtools::Credentials(drv = dbtools::SQLite, user = 1:2)

  testthat::expect_is(
    credList[1],
    "CredentialsList"
  )

  testthat::expect_identical(
    credList[TRUE],
    credList
  )

  testthat::expect_identical(
    credList[1:2],
    credList
  )
})

test_that("Credentials from URL", {
  # MySQL
  creds <- CredentialsFromURL("dbtools::MySQL://testUser:3WBUT7My996BLVoTZHo3@127.0.0.1:33001/testSchema")
  expect_equal(creds$dbname, "testSchema")
  expect_equal(creds$user, "testUser")
  expect_equal(creds$password, "3WBUT7My996BLVoTZHo3")
  expect_equal(creds$host, "127.0.0.1")
  expect_equal(creds$port, 33001)

  # SQLite -- File
  creds <- CredentialsFromURL("RSQLite::SQLite://example.db")
  expect_equal(creds$dbname, "example.db")
  # SQLite -- Memory
  creds <- CredentialsFromURL("RSQLite::SQLite://memory")
  expect_equal(creds$dbname, ":memory:")
})
