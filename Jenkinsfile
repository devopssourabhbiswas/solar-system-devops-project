pipeline {
    agent any

    tools {
        nodejs 'NodeJS 22.19.0'
        snyk 'snyk latest'
    }

    environment {
        NVD_KEY = credentials('NVD_API_KEY')
    }

    stages {
        stage('VM Node Version on Agent') {
            steps {
                sh 'node -v'
                sh 'npm install -g npm@latest'
                sh 'npm -v'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
            }
        }

        stage('Dependency Scanning') {
            parallel {
                stage('Snyk Scan Test') {
                    steps {
                        echo 'Running Snyk Scan...'
                        snykSecurity(
                            snykInstallation: 'snyk latest',
                            snykTokenId: 'devopsourabhbiswas-organization-token',
                        )
                    }
                }

                stage('NPM Dependency Audit') {
                    steps {
                        echo 'Running npm audit...'
                        sh '''
                          npm audit --audit-level=critical || true
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished. Cleaning up...'
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed. Check reports.'
        }
    }
}
