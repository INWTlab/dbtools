testSendData <- function(db = "mysql") {

  cred <- Credentials(
    drv = if (db == "mysql") MySQL else MariaDB,
    user = "testUser",
    password = "3WBUT7My996BLVoTZHo3",
    dbname = "testSchema",
    host = "127.0.0.1",
    port = if (db == "mysql") 3301 else 3302
  )

  # prepare data
  data(mtcars, envir = environment())
  mtcars$model <- row.names(mtcars)
  mtcars <- mtcars[c(length(mtcars), 1:(length(mtcars) - 1))]
  row.names(mtcars) <- NULL

  # send data to database
  expect_true(sendData(cred, mtcars))

  # retrieve data
  res <- sendQuery(cred, "SELECT * FROM `mtcars`;")

  # prepare mtcars for test
  dat <- mtcars[order(mtcars$model), ]
  row.names(dat) <- NULL
  dat <- data.table::as.data.table(dat)

  # objects should be equal
  expect_identical(res, dat)

  # mode: insert
  expect_warning(
    sendData(cred, mtcars, mode = "insert"),
    regexp = "Duplicate entry"
  )

  # mode: replace
  sendData(cred, mtcars[1, ], table = "mtcars", mode = "truncate")
  expect_true(sendData(cred, mtcars, mode = "replace"))
  res <- sendQuery(cred, "SELECT * FROM `mtcars`;")
  expect_identical(nrow(res), 32L)

  # mode: update
  sendData(cred, mtcars[1, ], table = "mtcars", mode = "truncate")
  expect_true(sendData(cred, mtcars, table = "mtcars", mode = "update"))
  mtcars2 <- mtcars[1, ]
  mtcars2$mpg <- mtcars2$mpg + 1
  expect_true(
    sendData(
      cred,
      mtcars2[c("model", "mpg")],
      table = "mtcars",
      mode = "update"
    )
  )
  res <- sendQuery(cred, "SELECT * FROM `mtcars`;")
  expect_identical(nrow(res), 32L)
  expect_identical(
    as.data.frame(res[res$model == mtcars2$model[1], ]),
    mtcars2[1, ]
  )
  mtcars2[1, "carb"] <- NA_real_
  expect_true(
    sendData(
      cred,
      mtcars2[1, c("model", "mpg", "carb")],
      table = "mtcars",
      mode = "update"
    )
  )
  res <- sendQuery(cred, "SELECT * FROM `mtcars`;")
  expect_identical(nrow(res), 32L)
  expect_identical(
    as.data.frame(res[res$model == mtcars2$model[1], ]),
    mtcars2[1, ]
  )

  # mode: truncate
  sendData(cred, mtcars[1:5, ], table = "mtcars", mode = "truncate")
  res <- sendQuery(cred, "SELECT * FROM `mtcars`;")
  expect_identical(nrow(res), 5L)

  # field order
  expect_true(
    sendData(
      cred,
      mtcars[rev(names(mtcars))],
      table = "mtcars",
      mode = "truncate"
    )
  )

  # datetime fields
  sendQuery(cred, "CREATE TABLE `dtm` (
    `dtm` DATETIME NOT NULL);"
  )

  expect_silent(
    sendData(cred, data.frame(dtm = Sys.time()), table = "dtm")
  )

  # NaN
  sendQuery(cred, "CREATE TABLE `nan` (
    `nan` INT NULL);"
  )

  expect_silent(
    sendData(cred, data.frame(nan = NaN), table = "nan")
  )

  # errors
  expect_error(
    sendData(
      cred,
      mtcars,
      mode = "wrong spelling",
      errorLogging = noErrorLogging
    )
  )

}

TEST("sendData for MySQL", {
  testSendData("mysql")
})

TEST("sendData for MariaDB", {
  testSendData("mariadb")
})
