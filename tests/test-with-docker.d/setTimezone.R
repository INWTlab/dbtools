testTimezone <- function(db = "mysql", drv = MySQL) {
  cred <- Credentials(
    drv = drv,
    user = "testUser",
    password = "3WBUT7My996BLVoTZHo3",
    dbname = "testSchema",
    host = "127.0.0.1",
    port = if (db == "mysql") 3301 else 3302
  )

  sendQuery(cred, "drop table if exists tz;")
  sendQuery(cred, "create table tz (id int not null, time datetime not null, primary key (id));")

  time <- '2020-01-01 12:00:00'
  timeBerlin <- as.POSIXct(time, tz = "Europe/Berlin")
  timeUTC <- as.POSIXct(time, tz = "UTC")

  sendQuery(cred, Query("insert into tz values (1, '{{ time }}');", time = time))
  resBerlin <- sendQuery(cred, "select time from tz where id = 1;", tz = "Europe/Berlin")$time
  resUTC <- sendQuery(cred, "select time from tz where id = 1;", tz = "UTC")$time

  # compare seconds since 1970-01-01 00:00:00
  expect_equal(as.numeric(resBerlin), as.numeric(timeBerlin))
  expect_equal(as.numeric(resUTC), as.numeric(timeUTC))
}

TEST("sendData for MariaDB", {
  testSendData("maria", drv = MariaDB)
})
