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
    stage('Launch MariaDB test databases') {
      steps {
        sh '''
        docker stop test-mariadb-database || :
        docker build -t mariadb-test inst/db/mariadb && docker run --name mariadb-test -p 3302:3306 -d --rm mariadb-test
        sleep 15s
        '''
      }
    }
    stage('Testing with R') {
      agent { label 'test' }
      when { not { branch 'depl' } }
      environment {
        TMP_SUFFIX = """${sh(returnStdout: true, script: 'echo `cat /dev/urandom | tr -dc \'a-z\' | fold -w 6 | head -n 1`')}"""
      }
      steps {
        sh '''
        docker build --pull -t tmp-$CUR_PROJ-$TMP_SUFFIX .
        docker run --rm --network host tmp-$CUR_PROJ-$TMP_SUFFIX check
        docker rmi tmp-$CUR_PROJ-$TMP_SUFFIX
        '''
      }
    }
    stage('Deploy R-package') {
      agent { label 'eh2' }
      when { branch 'master' }
      steps {
        sh '''
        rm -vf *.tar.gz
        docker pull inwt/r-batch:latest
        docker run --rm --network host -v $PWD:/app --user `id -u`:`id -g` inwt/r-batch:latest R CMD build $CUR_PKG_FOLDER
        PKG_VERSION=`grep -E '^Version:[ \t]*[0-9.]{3,10}' $CUR_PKG_FOLDER/DESCRIPTION | awk '{print $2}'`
        PKG_FILE="${CUR_PKG}_${PKG_VERSION}.tar.gz"
        docker run --rm -v $PWD:/app -v /var/www/html/r-repo:/var/www/html/r-repo inwt/r-batch:latest R -e "drat::insertPackage('$PKG_FILE', '/var/www/html/r-repo'); drat::archivePackages(repopath = '/var/www/html/r-repo')"
        '''
      }
    }
  }
  post {
    always {
      script {
        if (env.BRANCH_NAME != 'master' && env.BRANCH_NAME != 'depl') {
          emailext (
            attachLog: true,
            body: "Build of job ${env.JOB_NAME} (No. ${env.BUILD_NUMBER}) has completed\n\nBuild status: ${currentBuild.currentResult}\n\n${env.BUILD_URL}\n\nSee attached log file for more details of the build process.",
            recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']],
            subject: "Jenkins Build ${currentBuild.currentResult}: Job ${env.JOB_NAME}"
          )
        }
      }
    }
    failure {
      script {
        if (env.BRANCH_NAME == 'master' || env.BRANCH_NAME == 'depl') {
          emailext (
            attachLog: true,
            body: "Build of job ${env.JOB_NAME} (No. ${env.BUILD_NUMBER}) has completed\n\nBuild status: ${currentBuild.currentResult}\n\n${env.BUILD_URL}\n\nSee attached log file for more details of the build process.",
            to: "${env.EMAIL}",
            subject: "Jenkins Build ${currentBuild.currentResult}: Job ${env.JOB_NAME}"
          )
        }
      }
    }
  }
}
