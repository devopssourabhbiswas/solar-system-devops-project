pipeline {
    agent any
    tools {
        nodejs 'NodeJS 22.19.0'
        snyk 'snyk latest'
    }

    stages {
        stage('VM Node Version on Agent') {
            steps {
                sh 'node -v'
                sh 'npm install -g npm@latest'
                sh 'npm -v'
                sh 'npm install -g snyk@latest'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
            }
        }

        stage('Dependency Scanning') {
            parallel {
                stage('Snyk Security Scan') {
                    steps {
                        sh 'snyk test'
                    }
                }

                stage('Snyk Scan Test') {
                    steps {
                        echo 'Testing...'
                        snykSecurity(
                            snykInstallation: 'snyk latest',
                            snykTokenId: 'devopsourabhbiswas-organization-token',  
                        )
                    }
                }

                stage('NPM Dependency Audit') {
                    steps {
                        sh 'npm audit --audit-level=critical; echo $?'
                    }
                }

                stage('OWASP Dependency Check with Quality Gates') {
                    steps {
                        // Run OWASP Dependency Check
                        dependencyCheck additionalArguments: '''
                --scan ./
                --out ./
                --format \'ALL\'
                --prettyPrint
            ''', odcInstallation: 'OWASP DEPENDENCY CHECK 12.0.0'
                        // Publish Dependency Check Report with Quality Gates Critical = 1 means 99%
                        // Set stopBuild to true to fail the build if critical vulnerabilities are found
                        dependencyCheckPublisher pattern: 'dependency-check-report.xml',
                    stopBuild: true,
                    unstableTotalCritical: 1
                        // Publish HTML Report
                        publishHTML(
                        [allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        icon: '',
                        keepAll: true,
                        reportDir: './',
                        reportFiles: 'index.html',
                        reportName: 'OWASP Dependency Check HTML Report',
                        reportTitles: '',
                        useWrapperFileDirectly: true])

                        // JUnit Test Report
                        junit allowEmptyResults: true,
                        keepProperties: true,
                        stdioRetention: 'ALL',
                        testResults: 'OWASP-dependency-check-junit.xml'
                    }
                }
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
