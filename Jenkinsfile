pipeline {
    agent any

    tools {
        nodejs 'NodeJS 22.19.0'
        snyk 'snyk latest'
    }

    environment {
        MONGO_URI = credentials('Solar-mongoatlas-db-uri')
        MONGO_USERNAME = credentials('Solar-mongoatlas-db-username')
        MONGO_PASSWORD = credentials('Solar-mongoatlas-db-password')
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
                            severity: 'critical',
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

        stage('Code Coverage') {
            steps {
                echo 'Running Code Coverage...'
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    sh 'npm run coverage'
                }
            }
        }

        stage('Unit Testing') {
            steps {
                sh 'npm test'
            }
        }

        stage('Install Gitleaks') {
            steps {
                echo 'Installing Gitleaks...'
                sh '''
                  npm install -g gitleaks
                  export PATH=$PATH:$(npm bin -g)
                  gitleaks version
                   '''
                }
        }

        stage('Git Leaks Scan') {
            steps {
                echo 'Running Git Leaks Scan...'
                sh 'npx gitleaks detect --source . --no-banner --report=gitleaks-report.json'
                echo 'Git Leaks Scan completed.'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'gitleaks-report.json', onlyIfSuccessful: false
            archiveArtifacts artifacts: 'test-results.xml'
            junit allowEmptyResults: true, testResults: 'test-results.xml'
            publishHTML(
                allowMissing: true,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'coverage/lcov-report',
                reportFiles: 'index.html',
                reportName: 'Code Coverage HTML Report'
            )
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed. Check reports.'
        }
    }
}
