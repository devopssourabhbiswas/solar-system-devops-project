def slackNotification(String buildStatus = 'STARTED') {
    buildStatus = buildStatus ?: 'SUCCESS'


    // Map status to color
def color = buildStatus == 'SUCCESS'  ? '#47ec05' :
            buildStatus == 'UNSTABLE' ? '#d5ee0d' :
            buildStatus == 'FAILURE'  ? '#ec2805' :
            buildStatus == 'ABORTED'  ? '#808080' :
            '#0000ff'  // default (blue)



    // Construct message
    def msg = "${buildStatus}: ${env.JOB_NAME} #${env.BUILD_NUMBER}\n${env.BUILD_URL}"
    def msg2 = "Check the reports at: https://s3.console.aws.amazon.com/s3/buckets/solar-system-jenkins-reports-bucket-devops-sb/jenkins-${BUILD_ID}/"
    slackSend color: color, message: msg + msg2
}

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

        stage('Build Docker Image') {
            steps {
                // Print all available environment variables
                sh 'printenv'
            script {
                String shortCommit = env.GIT_COMMIT.take(7)   // shorten commit SHA
                dockerImage = docker.build("solar-system-app:${BRANCH_NAME}-${shortCommit}")
            }
            }
        }

        stage('Trivy Docker Image Scan') {
            steps {
                echo 'Running Trivy Scan...'
                sh '''
                  trivy image --severity CRITICAL --exit-code 1 --no-progress \
                  --format json -o trivy-image-critical.json \
                  String shortCommit = env.GIT_COMMIT.take(7)   // shorten commit SHA
                  solar-system-app:${BRANCH_NAME}-${shortCommit}
                '''
            }
        }

        stage('Push Docker Image to Docker Hub') {
            steps {
                    withDockerRegistry(credentialsId: 'dockercred_for_agentsourabh',
                    url: 'https://index.docker.io/v1/') {
                        dockerImage.push() //pushes the image with the exact tag you built.
                        dockerImage.push('latest') //also pushes an additional 'latest' tag
                    }
            }
        }

        stage('Publish Reports to AWS S3') {
            when { expression { return env.BRANCH_NAME.startsWith("PR") } }
            steps {
                withAWS(
                    credentials: 'aws-jenkins-report-user-cred',
                    region: 'ap-south-1'
                ) {
                    echo 'Publish Reports to AWS S3'
                    sh '''
                      ls -ltr
                      mkdir reports-$BUILD_ID
                      cp -rf coverage/lcov-report reports-$BUILD_ID/
                      cp gitleaks-report.json reports-$BUILD_ID/
                      cp trivy-image-critical.json reports-$BUILD_ID/
                      cp test-results.xml reports-$BUILD_ID/
                      ls -ltr reports-$BUILD_ID/
                    '''
                    s3Upload(
                      file: "reports-$BUILD_ID",
                      bucket: 'solar-system-jenkins-reports-bucket-devops-sb',
                      path: "jenkins-$BUILD_ID/"
                      )
                }
            }
        }
        

    post {
        always {
            slackNotification(currentBuild.result)
            archiveArtifacts artifacts: 'gitleaks-report.json', onlyIfSuccessful: false
            archiveArtifacts artifacts: 'test-results.xml'
            junit allowEmptyResults: true, testResults: 'test-results.xml'
            archiveArtifacts artifacts: 'trivy-image-critical.json', onlyIfSuccessful: false
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
