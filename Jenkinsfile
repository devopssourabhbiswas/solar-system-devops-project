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
        DOCKER_IMAGE_NAME = 'agentsourabh/solar-system-app'
        GITOPS_REPO = 'https://github.com/devopssourabhbiswas/solar-system-devops-project-gitops-repo.git'
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
                        unstash 'solar-project-node_modules'
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
                        script {
                            def auditResult = sh(
                                script: 'npm audit --audit-level=critical',
                                returnStatus: true
                            )
                            if (auditResult != 0) {
                                unstable('NPM audit found vulnerabilities')
                            }
                        }
                    }
                }
            }
        }

        stage('Unit Testing') {
            steps {
                unstash 'solar-project-node_modules'
                sh 'npm test'
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

        stage('Git Leaks Scan') {
            steps {
                echo 'Running Git Leaks Scan...'
                sh 'gitleaks version'
                script {
                    def gitleaksResult = sh(
                        script: 'gitleaks detect --source . --no-banner --report-path=gitleaks-report.json',
                        returnStatus: true
                    )
                    if (gitleaksResult != 0) {
                        error('Git Leaks found secrets in the repository!')
                    }
                }
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
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    env.SHORT_COMMIT = env.GIT_COMMIT.take(7)
                    dockerImage = docker.build("${DOCKER_IMAGE_NAME}:${env.BRANCH_NAME}-${env.SHORT_COMMIT}")
                    
                    // Verify image was built
                    if (!dockerImage) {
                        error("Docker image build failed")
                    }
                }
            }
        }

        stage('Trivy Docker Image Scan') {
            steps {
                script {
                    String shortCommit = env.GIT_COMMIT.take(7)
                    def imageName = "${DOCKER_IMAGE_NAME}:${env.BRANCH_NAME}-${shortCommit}"

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
                        // For PR branches, push dev-latest
                        if (env.BRANCH_NAME.startsWith("PR")) {
                            sh "docker tag ${DOCKER_IMAGE_NAME}:${env.BRANCH_NAME}-${env.SHORT_COMMIT} ${DOCKER_IMAGE_NAME}:dev-latest"
                            dockerImage.push('dev-latest')
                        }
                        // For main branch, push prod-latest
                        else if (env.BRANCH_NAME == "main") {
                            sh "docker tag ${DOCKER_IMAGE_NAME}:${env.BRANCH_NAME}-${env.SHORT_COMMIT} ${DOCKER_IMAGE_NAME}:prod-latest"
                            dockerImage.push('prod-latest')
                        }
                        // Always push the branch-commit tag
                        dockerImage.push("${env.BRANCH_NAME}-${env.SHORT_COMMIT}")
                    }
                }
            }
        }

        stage('Publish Reports to AWS S3') {
            when { expression { return env.BRANCH_NAME.startsWith("PR") } }
            steps {
                withAWS(credentials: 'aws-jenkins-report-user-cred', region: 'ap-south-1') {
                    echo 'Publishing Reports to AWS S3'
                    script {
                        def trivyReport = "trivy-${env.BRANCH_NAME}-${env.BUILD_ID}.json"
                        def reportsDir = "reports-${env.BUILD_ID}"

                        sh """
                            set -e
                            ls -ltr
                            mkdir -p ${reportsDir}
                            cp -rf coverage/lcov-report ${reportsDir}/
                            cp gitleaks-report.json ${reportsDir}/
                            cp ${trivyReport} ${reportsDir}/ || echo "Trivy report not found"
                            cp test-results.xml ${reportsDir}/ || echo "Test results not found"
                            ls -ltr ${reportsDir}/
                        """
                        
                        s3Upload(
                            workingDir: "${reportsDir}",
                            includePathPattern: '**/*',
                            bucket: 'solar-system-jenkins-reports-bucket-devops-sb',
                            path: "jenkins-${BUILD_ID}/"
                        )
                    }
                }
            }
        }

        // Start of CD stages for GitOps repo update and PR raise

        stage('Update GitOps Repo - Dev') {
            when {
                expression { return env.BRANCH_NAME.startsWith("PR") }
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-creds-for-gitops-repo',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_PASSWORD'
                    )
                ]) {
                    sh '''
                        set -e
                        
                        # Clean up any existing gitops-repo directory
                        rm -rf gitops-repo
                        
                        # Clone the GitOps repository
                        git clone ${GITOPS_REPO} gitops-repo
                        cd gitops-repo
                        
                        # Create feature branch
                        git checkout -b feature-${BUILD_ID}
                        
                        # Update the image tag in values file
                        yq e -i '.image.tag = "dev-latest"' helm-charts/solar-project/values-dev.yaml
                        
                        # Configure git
                        git config user.name "jenkins"
                        git config user.email "jenkins@example.com"
                        
                        # Commit changes
                        git add .
                        git commit -m "Update image tag to dev-latest (build ${BUILD_ID})"
                        
                        # Push using credentials
                        git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/devopssourabhbiswas/solar-system-devops-project-gitops-repo.git feature-${BUILD_ID}
                    '''
                }
            }
        }

        stage('Raise PR for Dev') {
            when { expression { return env.BRANCH_NAME.startsWith("PR") } }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-creds-for-gitops-repo',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_PASSWORD'
                    )
                ]) {
                    sh '''
                        set -e
                        cd gitops-repo
                        
                        # Authenticate with GitHub CLI
                        echo "${GITHUB_TOKEN}" | gh auth login --with-token
                        
                        # Create pull request
                        gh pr create \
                            --title "Deploy build ${BUILD_ID} to dev" \
                            --body "Update dev environment to dev-latest (build ${BUILD_ID})" \
                            --base main \
                            --head feature-${BUILD_ID} || echo "PR may already exist"
                    '''
                }
            }
        }

        stage('Update GitOps Repo - Prod') {
            when {
                expression { return env.BRANCH_NAME == "main" }
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-creds-for-gitops-repo',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_PASSWORD'
                    )
                ]) {
                    sh '''
                        set -e
                        
                        # Clean up any existing gitops-repo directory
                        rm -rf gitops-repo
                        
                        # Clone the GitOps repository
                        git clone ${GITOPS_REPO} gitops-repo
                        cd gitops-repo
                        
                        # Create production branch
                        git checkout -b prod-build-${BUILD_NUMBER}
                        
                        # Update the image tag in values file
                        yq e -i '.image.tag = "prod-latest"' helm-charts/solar-project/values-prod.yaml
                        
                        # Configure git
                        git config user.name "jenkins"
                        git config user.email "jenkins@example.com"
                        
                        # Commit changes
                        git add .
                        git commit -m "Promote to prod-latest (build ${BUILD_NUMBER})"
                        
                        # Push using credentials
                        git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/devopssourabhbiswas/solar-system-devops-project-gitops-repo.git prod-build-${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('Raise PR for Prod') {
            when {
                expression { return env.BRANCH_NAME == "main" }
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-creds-for-gitops-repo',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_PASSWORD'
                    )
                ]) {
                    sh '''
                        set -e
                        cd gitops-repo
                        
                        # Authenticate with GitHub CLI
                        echo "${GITHUB_TOKEN}" | gh auth login --with-token
                        
                        # Create pull request
                        gh pr create \
                            --title "Promote to prod-latest (build ${BUILD_NUMBER})" \
                            --body "Update prod environment to prod-latest (build ${BUILD_NUMBER})" \
                            --base main \
                            --head prod-build-${BUILD_NUMBER} || echo "PR may already exist"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Send Slack notification
                slackNotification(currentBuild.result)
                
                // Archive artifacts if they exist
                if (fileExists('gitleaks-report.json')) {
                    archiveArtifacts artifacts: 'gitleaks-report.json', onlyIfSuccessful: false
                }
                
                if (fileExists('test-results.xml')) {
                    archiveArtifacts artifacts: 'test-results.xml'
                    junit allowEmptyResults: true, testResults: 'test-results.xml'
                }
                
                // Archive Trivy reports
                def trivyJsonFiles = sh(script: 'ls trivy-*.json 2>/dev/null || true', returnStdout: true).trim()
                if (trivyJsonFiles) {
                    archiveArtifacts artifacts: 'trivy-*.json', onlyIfSuccessful: false
                    
                    // Convert Trivy JSON to JUnit XML
                    sh '''
                        for file in trivy-*.json; do
                            if [ -f "$file" ]; then
                                trivy convert --format template \
                                    --template "/usr/local/share/trivy/templates/junit.tpl" \
                                    --output "${file%.json}.xml" "$file" || true
                            fi
                        done
                    '''
                }
                
                // Archive Trivy HTML and XML reports
                def trivyReports = sh(script: 'ls trivy-*.{html,xml} 2>/dev/null || true', returnStdout: true).trim()
                if (trivyReports) {
                    archiveArtifacts artifacts: 'trivy-*.html,trivy-*.xml', onlyIfSuccessful: false
                }
                
                // Publish HTML coverage report
                if (fileExists('coverage/lcov-report/index.html')) {
                    publishHTML(
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'coverage/lcov-report',
                        reportFiles: 'index.html',
                        reportName: 'Code Coverage HTML Report'
                    )
                }
                
                // Clean up workspace
                sh 'rm -rf gitops-repo || true'
            }
        }
        
        success {
            echo 'Pipeline succeeded!'
        }
        
        failure {
            echo 'Pipeline failed. Check reports and logs for details.'
        }
        
        unstable {
            echo 'Pipeline completed with warnings. Review test results and security scans.'
        }
    }
}