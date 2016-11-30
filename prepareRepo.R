library(dbtools)
knitr::knit("README.Rmd", "README.md")
file.remove(c("example.db", "example1.db"))
