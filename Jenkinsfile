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
        SONAR_TOKEN = credentials('SonarQube-Token')
        SONAR_SCANNER_HOME = tool 'sonarqube-scanner-7.2.0'
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

        stage('Git Leaks Scan') {
            steps {
                echo 'Running Git Leaks Scan...'
                sh 'gitleaks version'
                sh 'gitleaks detect --source . --no-banner --report-path=gitleaks-report.json'
                echo 'Git Leaks Scan completed.'
            }
        }

        stage('SAST-Analysis-SonarQube') {
            steps {
                    withSonarQubeEnv('sonar-qube-server') {
                        sh '''
                        $SONAR_SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectKey=Solar-System-Project \
                        -Dsonar.sources=app.js \
                        -Dsonar.javascript.lcov.reportPaths=./coverage/lcov.info
                        '''
                    }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
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
