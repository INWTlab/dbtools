startContainer <- function(db = "mysql", version = "latest") {
  cmd <- paste0(
    'docker run --name test-', db, '-database -p 127.0.0.1:3307:3306 ',
    '-e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=test -d ', db, ':', version,
    if (db == "mysql") {
      ' --default-authentication-plugin=mysql_native_password --local-infile'
    }
  )

  system(cmd, intern = TRUE)
}

stopContainer <- function(db = "mysql") {
  cmd <- paste0(
    'docker kill test-', db, '-database; docker rm -v test-', db, '-database'
  )

  system(cmd, intern = TRUE)
}
