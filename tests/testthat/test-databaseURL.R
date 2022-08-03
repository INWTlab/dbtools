context("databaseURL")

test_that("deparse URL", {
    expectDeparsed <- function(url,
                               driver,
                               username = NA_character_,
                               password = NA_character_,
                               host,
                               port = NA_character_,
                               database = NA_character_) {
        res <- list(
            url = url,
            driver = driver,
            username = username,
            password = password,
            host = host,
            port = port,
            database = database
        )
        testthat::expect_identical(deparseURL(res$url), res)
    }
    expectDeparsed(
        url = "pkg::driver://user:s1cu@r:29281726=)(/&%%$§!\"@data1-ba_se.de:123/database_schema",
        driver = "pkg::driver",
        username = "user",
        password = "s1cu@r:29281726=)(/&%%$§!\"",
        host = "data1-ba_se.de",
        port = "123",
        database = "database_schema"
    )
    expectDeparsed(
        url = "pkg::driver://user:s1cur29281726@data1-ba_se.de:123/database_schema",
        driver = "pkg::driver",
        username = "user",
        password = "s1cur29281726",
        host = "data1-ba_se.de",
        port = "123",
        database = "database_schema"
    )
    expectDeparsed(
        url = "pkg::driver://user:s1cur29281726=)(/&%%$§!\"@data1.base.de:123",
        driver = "pkg::driver",
        username = "user",
        password = "s1cur29281726=)(/&%%$§!\"",
        host = "data1.base.de",
        port = "123"
    )
    expectDeparsed(
        url = "pkg::driver://user:@data1.base.de",
        driver = "pkg::driver",
        username = "user",
        host = "data1.base.de"
    )
    expectDeparsed(
        url = "pkg::driver://:@data1.base.de",
        driver = "pkg::driver",
        host = "data1.base.de"
    )
    expectDeparsed(
        url = "pkg::driver://@data1.base.de",
        driver = "pkg::driver",
        host = "data1.base.de"
    )
    expectDeparsed(
        url = "pkg::driver://user@data1.base.de:/asd",
        driver = "pkg::driver",
        username = "user",
        host = "data1.base.de",
        database = "asd"
    )
    expectDeparsed(
        url = "pkg::driver://@data1.base.de/asd",
        driver = "pkg::driver",
        host = "data1.base.de",
        database = "asd"
    )
    expectDeparsed(
        url = "pkg::driver://data1.base.de/asd",
        driver = "pkg::driver",
        host = "data1.base.de",
        database = "asd"
    )
    expectDeparsed(
        url = "pkg::driver://data1.base.de",
        driver = "pkg::driver",
        host = "data1.base.de"
    )
    expectDeparsed(
        url = "pkg::driver://data1.base.de:1234",
        driver = "pkg::driver",
        host = "data1.base.de",
        port = "1234"
    )
    expectDeparsed(
        url = "pkg::driver://data1.base.de:1234/db",
        driver = "pkg::driver",
        host = "data1.base.de",
        port = "1234",
        database = "db"
    )
    expectDeparsed(
        url = "pkg::driver://domain/user@data1.base.de:1234/db",
        driver = "pkg::driver",
        username = "domain/user",
        host = "data1.base.de",
        port = "1234",
        database = "db"
    )
})
