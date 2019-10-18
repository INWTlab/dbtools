// url: https://github.com/INWT/inwt-templates/blob/master/jenkins/r-ci.Jenkinsfile

pipeline {
  agent none
  options { disableConcurrentBuilds() }
  environment {
    CUR_PROJ = 'dbtools'
    CUR_PKG = 'dbtools'
    CUR_PKG_FOLDER = '.'
    INWT_REPO = 'inwt-vmdocker1.inwt.de:8081'
  }
  stages {
    stage('Testing with R') {
      agent { label 'test' }
      environment {
        TMP_SUFFIX = """${sh(returnStdout: true, script: 'echo `cat /dev/urandom | tr -dc \'a-z\' | fold -w 6 | head -n 1`')}"""
      }
      steps {
        sh '''
        # launch mysql test database
        docker stop mysql-test-database || :
        docker build -t mysql-test-database inst/db/mysql && docker run --name mysql-test-database -p 3301:3306 -d --rm mysql-test-database

        # launch mariadb test database
        docker stop mariadb-test-database || :
        docker build -t mariadb-test-database inst/db/mariadb && docker run --name mariadb-test-database -p 3302:3306 -d --rm mariadb-test-database
        sleep 15s

        # perform check
        docker build --pull -t tmp-$CUR_PROJ-$TMP_SUFFIX .
        docker run --rm --network host tmp-$CUR_PROJ-$TMP_SUFFIX check
        docker rmi tmp-$CUR_PROJ-$TMP_SUFFIX

        # stop test databases
        docker stop mysql-test-database || :
        docker stop mariadb-test-database || :
        '''
      }
    }
  }
}
