testSendQuery <- function(db = "mysql", version = "latest") {

  cred <- CREDENTIALS(
    drv = if (db == "mysql") MySQL else MariaDB,
    port = if (db == "mysql") 3301 else 3302
  )

  dat <- sendQuery(cred, "SELECT 1 AS x;")

  expect_equal(nrow(dat), 1)
  expect_equal(ncol(dat), 1)
  expect_equal(names(dat), "x")
  expect_true(all(dat$x == 1))
  expect_is(dat, "data.frame")


  dat <- sendQuery(cred, rep("SELECT 1;", 2))

  expect_equal(nrow(dat), 2)
  expect_equal(ncol(dat), 1)
  expect_true(all(dat$"1" == 1))


  dat <- sendQuery(cred, sapply(1:2, dummyQuery, const = 2))

  expect_equal(nrow(dat), 2)
  expect_equal(ncol(dat), 1)
  expect_equal(names(dat), "x")
  expect_true(all(dat$x == 3:4))


  expect_error(
    sendQuery(
      cred,
      "SELECT * FRM Tabelle;",
      errorLogging = noErrorLogging
    )
  )

  expect_error(
    sendQuery(
      cred,
      "SELECT 1 FRM Tabelle;",
      tries = 2,
      intSleep = 1,
      errorLogging = noErrorLogging
    )
  )
}
