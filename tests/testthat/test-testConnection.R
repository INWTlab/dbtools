context("Test connections")

test_that("testConnection", {

  workingConnection <- Credentials(drv = RSQLite::SQLite, dbname = ":memory:")
  testthat::expect_true(testConnection(workingConnection, function(...) NULL))

  nonWorkingConnection <- Credentials(drv = RMySQL::MySQL, dbname = "Nirvana")
  testthat::expect_false(testConnection(nonWorkingConnection, function(...) NULL))

  nonWorkingConnectionList <- Credentials(drv = RMySQL::MySQL, dbname = c("Nirvana", "Walhalla"))
  testthat::expect_false(testConnection(nonWorkingConnectionList, loggerSuppress))

  testthat::expect_match(
    testthat::evaluate_promise(
      testConnection(nonWorkingConnectionList))$output, "FAILED")

})
