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
      steps {
        sh '''
        docker stop test-mariadb-database || :
        docker build -t mariadb-test inst/db/mariadb && docker run --name mariadb-test -p 3302:3306 -d --rm mariadb-test
        sleep 15s

        docker build --pull -t tmp-$CUR_PROJ-$TMP_SUFFIX .
        docker run --rm --network host tmp-$CUR_PROJ-$TMP_SUFFIX check
        docker rmi tmp-$CUR_PROJ-$TMP_SUFFIX
        '''
      }
    }
  }
}
