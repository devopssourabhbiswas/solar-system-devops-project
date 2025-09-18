@Library('jenkins-shared-library') _

pipeline {
    agent any

    tools {
        nodejs 'NodeJS 22.19.0'
        snyk 'snyk latest'
    }

    environment {
        MONGO_URI      = credentials('Solar-mongoatlas-db-uri')
        MONGO_USERNAME = credentials('Solar-mongoatlas-db-username')
        MONGO_PASSWORD = credentials('Solar-mongoatlas-db-password')
        SONAR_TOKEN    = credentials('SonarQube-Token')
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
                cache(
                    caches: [
                    arbitraryFileCache(
                    cacheName: 'npm-dependency-cache',
                    cacheValidityDecidingFile: 'package-lock.json',
                    excludes: '',
                    includes: '**/*',
                    path: 'node_modules')],
                    defaultBranch: 'main',
                    maxCacheSize: 550) {
                        sh 'npm ci'
                        stash includes: 'node_modules/**', name: 'solar-project-node_modules'
                    }
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
                            snykTokenId: 'devopsourabhbiswas-organization-token'
                        )
                    }
                }

                stage('NPM Dependency Audit') {
                    steps {
                        unstash 'solar-project-node_modules'
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
                    unstash 'solar-project-node_modules'
                    sh 'npm run coverage'
                }
            }
        }

        stage('Unit Testing') {
            steps {
                unstash 'solar-project-node_modules'
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

        stage('Build Docker Image') {
            steps {
                sh 'printenv'
                script {
                    env.SHORT_COMMIT = env.GIT_COMMIT.take(7)
                    dockerImage = docker.build("solar-system-app:${env.BRANCH_NAME}-${env.SHORT_COMMIT}")
                }
            }
        }

        stage('Trivy Docker Image Scan') {
            steps {
            script {
            String shortCommit = env.GIT_COMMIT.take(7)
            def imageName = "solar-system-app:${env.BRANCH_NAME}-${shortCommit}"

            // Run Trivy scan
            TrivyScan.Trivy_Docker_Image_Scan(imageName)

            // Convert report to HTML + JUnit
            def reportFile = "trivy-${env.BRANCH_NAME}-${env.BUILD_ID}.json"
            TrivyScan.reportsConverter(reportFile)
                   }
            }
        }

        stage('Push Docker Image to Docker Hub') {
            steps {
                withDockerRegistry(
                    credentialsId: 'dockercred_for_agentsourabh',
                    url: 'https://index.docker.io/v1/') {
                    script {
                        dockerImage.push()       // pushes the image with the exact tag built
                        dockerImage.push('latest') // also pushes an additional 'latest' tag
                    }
                    }
            }
        }

        stage('Publish Reports to AWS S3') {
            when { expression { return env.BRANCH_NAME.startsWith("PR") } }
            steps {
                withAWS(credentials: 'aws-jenkins-report-user-cred', region: 'ap-south-1') {
                    echo 'Publish Reports to AWS S3'
                    script {
                        def trivyReport = "trivy-${env.BRANCH_NAME}-${env.BUILD_ID}.json"
                        def reportsDir = "reports-${env.BUILD_ID}"
                        
                    sh '''
                      ls -ltr
                      mkdir -p ${reportsDir}
                      cp -rf coverage/lcov-report ${reportsDir}/
                      cp gitleaks-report.json ${reportsDir}/
                      cp ${trivyReport} ${reportsDir}/
                      cp test-results.xml ${reportsDir}/
                      ls -ltr ${reportsDir}/
                    '''
                    s3Upload(
                      workingDir: "${reportsDir}",
                      includePathPattern: '**/*',
                      bucket: 'solar-system-jenkins-reports-bucket-devops-sb',
                      path: "jenkins-$BUILD_ID/"
                    )
                }
            }
          }
        }
    }
    post {
        always {
            slackNotification(currentBuild.result)
            archiveArtifacts artifacts: 'gitleaks-report.json', onlyIfSuccessful: false
            archiveArtifacts artifacts: 'test-results.xml'
            junit allowEmptyResults: true, testResults: 'test-results.xml'
            archiveArtifacts artifacts: '*.json', onlyIfSuccessful: false
            archiveArtifacts artifacts: "trivy-*.{html,xml}", onlyIfSuccessful: false

            // Convert JSON to HTML and JUnit XML formats
            sh '''
            trivy convert --format template \
              --template "/usr/local/share/trivy/templates/junit.tpl" \
              --output trivy-image-critical.xml trivy-image-critical.json
            '''

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
