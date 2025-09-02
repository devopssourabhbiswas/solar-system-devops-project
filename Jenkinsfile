pipeline {
    agent any
    stages {
        stage('VM Node Version') {
            steps {
                 sh '''
      export PATH="$HOME/.fnm:$PATH"
      eval "$(fnm env)"
      fnm use 22.19.0
      node -v
      npm -v
    '''
            }
        }
        stage('Build') {
            steps {
                echo 'Building...'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing...'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying...'
            }
        }
    }
    post {
        always {
            echo 'This will always run after the stages.'
        }
        success {
            echo 'This will run only if the pipeline succeeds.'
        }
        failure {
            echo 'This will run only if the pipeline fails.'
        }
    }
}