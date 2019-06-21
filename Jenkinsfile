// Template Jenkinsfile for R CI/CD Tasks
// url: https://github.com/INWT/inwt-templates/blob/master/jenkins/r-ci.Jenkinsfile
// Author: Sebastian Warnholz

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
                TMP_SUFFIX = """${sh(returnStdout: true, script: 'echo `cat /dev/urandom | tr -dc \'a-zA-Z\' | fold -w 6 | head -n 1`')}"""
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
                R -e "drat::insertPackage('`echo $CUR_PKG`_`grep -E '^Version:[ \t]*[0-9.]{3,10}' $CUR_PKG_FOLDER/DESCRIPTION | awk '{print $2}'`.tar.gz', '/var/www/html/r-repo'); drat::archivePackages(repopath = '/var/www/html/r-repo')"
                '''

            }

        }

    }

}
