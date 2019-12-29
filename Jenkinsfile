// url: https://github.com/INWT/inwt-templates/blob/master/jenkins/r-ci.Jenkinsfile

pipeline {
  agent { label 'docker1' }
  options { disableConcurrentBuilds() }
  environment {
    CUR_PROJ = 'dbtools'
    CUR_PKG = 'dbtools'
    CUR_PKG_FOLDER = '.'
    INWT_REPO = 'inwt-vmdocker1.inwt.de:8081'
    TMP_SUFFIX = """${sh(returnStdout: true, script: 'echo `cat /dev/urandom | tr -dc \'a-z\' | fold -w 6 | head -n 1`')}"""
  }
  stages {
    stage('Launch mysql test database') {
      steps {
        sh '''
          docker stop mysql-test-database || :
          docker rm mysql-test-database || :
          docker build -t mysql-test-database -f inst/db/mysql/Dockerfile . && docker run --name mysql-test-database -p 3301:3306 -d mysql-test-database --default-authentication-plugin=mysql_native_password --local-infile
          sleep 15s
          docker logs mysql-test-database
        '''
      }
    }
    stage('Launch mariadb test database') {
      steps {
        sh '''
          docker stop mariadb-test-database || :
          docker rm mariadb-test-database || :
          docker build -t mariadb-test-database -f inst/db/mariadb/Dockerfile . && docker run --name mariadb-test-database -p 3302:3306 -d mariadb-test-database
          sleep 15s
          docker logs mariadb-test-database
        '''
      }
    }
    stage('Testing with R') {
      steps {
        sh '''
          docker build --pull -t tmp-$CUR_PROJ-$TMP_SUFFIX .
          docker run --rm --network host tmp-$CUR_PROJ-$TMP_SUFFIX check
        '''
      }
    }
  }
  post {
  always {
    sh '''
      docker rmi tmp-$CUR_PROJ-$TMP_SUFFIX || :
      docker stop mysql-test-database || :
      docker rm mysql-test-database || :
      docker stop mariadb-test-database || :
      docker rm mariadb-test-database || :
    '''
    }
  }
}
