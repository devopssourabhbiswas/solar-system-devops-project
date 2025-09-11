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

                stage('OWASP Dependency Check with Quality Gates') {
                    steps {
                        echo 'Running OWASP Dependency Check...'
                        dependencyCheck additionalArguments: """
                            --scan ./
                            --out ./dependency-check-report
                            --format ALL
                            --prettyPrint
                            --nvdApiKey ${NVD_KEY}
                        """, odcInstallation: 'OWASP DEPENDENCY CHECK 12.0.0'
                            // Publish Dependency Check Report with Quality Gates Critical = 1 means 99%
                            // Set stopBuild to true to fail the build if critical vulnerabilities are found
                        dependencyCheckPublisher(
                            pattern: 'dependency-check-report/dependency-check-report.xml',
                            stopBuild: true,
                            unstableTotalCritical: 1
                        )
                        // Publish HTML reports
                        publishHTML(
                            [allowMissing: true,
                            alwaysLinkToLastBuild: true,
                            keepAll: true,
                            reportDir: 'dependency-check-report',
                            reportFiles: 'index.html',
                            reportName: 'OWASP Dependency Check HTML Report']
                        )
                        // JUnit Test Report
                        junit(
                            allowEmptyResults: true,
                            testResults: 'dependency-check-report/OWASP-dependency-check-junit.xml'
                        )
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
