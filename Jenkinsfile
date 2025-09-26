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
        //Start of CI stages
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
                        dockerImage.push('dev-latest') // pushes an 'dev-latest' tag
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

        // Start of CD stages for GitOps repo update and PR raise
        stage('Update Image tags dev-latest') {
            when { expression { return env.BRANCH_NAME.startsWith("PR") } }
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'github-creds-for-gitops-repo',
                    usernameVariable: 'GIT_USERNAME',
                    passwordVariable: 'GIT_PASSWORD')]) {
                    sh '''
            git clone https://github.com/devopssourabhbiswas/solar-system-devops-project-gitops-repo.git
            cd gitops-repo
            git checkout -b feature-${BUILD_ID}
            yq e -i '.image.tag = "dev-latest"' charts/solar-system-helm/values-dev.yaml
            git config user.name "jenkins"
            git config user.email "jenkins@example.com"
            git add .
            git commit -m "Update image tag to ${BUILD_ID}"
            git push origin feature-${BUILD_ID}
            '''}
            }
        }

        stage('Raise PR dev-latest') {
            when { expression { return env.BRANCH_NAME.startsWith("PR") } } // Only for PR branches
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'github-creds-for-gitops-repo',
                    usernameVariable: 'GIT_USERNAME',
                    passwordVariable: 'GIT_PASSWORD')]) {
                    sh '''
                    cd gitops-repo
                    gh auth login --with-token <<< "$GITHUB_TOKEN"
                    echo 'Raising PR for GitOps Repo - Placeholder'
                    gh pr create --title "Deploy build ${BUILD_ID}" \
                                 --body "Update dev environment to dev-latest (build ${BUILD_NUMBER})" \
                                 --base main --head dev-build-feature-${BUILD_ID}
                    '''
                    }}
        }

        stage('Update Image tags to prod-latest') {
            when {
                expression { return env.BRANCH_NAME == "main" } // only after PR merged into main
            }
            steps {
                withDockerRegistry(
                credentialsId: 'dockercred_for_agentsourabh',
                url: 'https://index.docker.io/v1/') {
                    script {
                        docker tag "solar-system-app:${env.BRANCH_NAME}-${env.SHORT_COMMIT}" "solar-system-app:prod-latest" // tagging the image with prod-latest
                        dockerImage.push('prod-latest') // pushes 'prod-latest' tag
                    }
                }
            }
        }

        stage('Update Image tags prod-latest') {
            when {
                expression { return env.BRANCH_NAME == "main" } // only after PR merged into main
            }
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'github-creds-for-gitops-repo',
                    usernameVariable: 'GIT_USERNAME',
                    passwordVariable: 'GIT_PASSWORD')]) {
                    sh '''
            git clone https://github.com/devopssourabhbiswas/solar-system-devops-project-gitops-repo.git
            cd gitops-repo
            git checkout -b prod-build-${BUILD_NUMBER}
            yq e -i '.image.tag = "prod-latest"' charts/solar-system-helm/values-prod.yaml
            git config user.name "jenkins"
            git config user.email "jenkins@example.com"
            git add .
            git commit -m "Promote to prod-latest (build ${BUILD_NUMBER}"
            git push origin prod-build-${BUILD_NUMBER}
            '''}
            }
        }

        stage('Raise PR prod-latest') {
            when {
                expression { return env.BRANCH_NAME == "main" } // only after PR merged into main
            }
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'github-creds-for-gitops-repo',
                    usernameVariable: 'GIT_USERNAME',
                    passwordVariable: 'GIT_PASSWORD')]) {
                    sh '''
                    cd gitops-repo
                    gh auth login --with-token <<< "$GITHUB_TOKEN"
                    echo 'Raising PR for GitOps Repo - Placeholder'
                    gh pr create --title "Promote to prod-latest (build ${BUILD_NUMBER})" \
                                 --body "Update prod environment to prod-latest (build ${BUILD_NUMBER})" \
                                 --base main --head prod-build-${BUILD_NUMBER}
                    '''
                    }}
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
