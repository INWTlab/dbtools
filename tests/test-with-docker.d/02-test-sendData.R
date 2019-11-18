TEST("sendData for RMySQL DB", {
  testSendDataDocker("mysql", "5.7")
})

TEST("sendData for RMySQL DB", {
  testSendDataDocker("mariadb", "latest")
})
