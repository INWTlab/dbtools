FROM inwt/r-batch:3.6.0

ADD . .

RUN installPackage
