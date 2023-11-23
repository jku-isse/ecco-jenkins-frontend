def dockerImage
pipeline {
    agent {label "jenkins"}
    environment {
        HOME = '.'
    }

    stages {
        stage('Preperations') {
            steps {
                script {
                    //set serverRepositories to default
                    sh 'rm -R $WORKSPACE/serverRepositories'
                    sh 'cp -R -p $WORKSPACE/serverRepositories_Original $WORKSPACE/serverRepositories'
                    try {   // files might not be there (if last build did not export the results)
                        
                        //delete old test results
                        sh 'rm -r $WORKSPACE/export/results' 
                        sh 'rm -r $WORKSPACE/export/screenshots'
                        sh 'rm -r $WORKSPACE/export/videos'
                    } catch (e){
                        echo "No export results to delete"
                    }
                }
            }
        }
        
        stage('Pull') {
            steps { //Checking out the repo
                dir('forDocker') {
                    checkout changelog: true,
                    poll: true,
                    scm: [$class: 'GitSCM',
                        branches: [[name: '*/master']],
                        browser: [$class: 'BitbucketWeb', repoUrl: 'https://github.com/MatthiasPreuner/ecco-client.git'],
                        doGenerateSubmoduleConfigurations: false,
                        extensions: [],
                        submoduleCfg: [],
                        userRemoteConfigs: [[credentialsId: 'git', url: 'https://github.com/MatthiasPreuner/ecco-client.git']]]
                }
            }
        }
        
        stage("Create Docker") {
            steps {
                script {
                    dockerImage = docker.build("ecco-frontend:${env.BUILD_ID}")
                }
            }
        }
        
        stage('E2E-Test') {
            steps {
                script {
                    docker.image('bergthalerjku/ecco_backend:latest').withRun('-d=true ' +
                                                                            '-p 8081:8081 ' + 
                                                                            '-v $WORKSPACE/serverRepositories:/media/serverRepositories') {
                                                                                
                        sleep(90)   //wait 1:30 min before the frontend starts
                        
                        //for Manual testing change from http://docker.localhost:8081 to http://localhost:8081
                        dockerImage.inside('--add-host docker.localhost:host-gateway ' + 
                                            '-v $WORKSPACE/export:/home/frontend/export ' +
                                            '--entrypoint= ' +
                                            '-e NODE_ENV=test ' +
                                            '-e REACT_APP_BACKEND_PATH=http://docker.localhost:8081 ' +
                                            //'-e REACT_APP_BACKEND_PATH=http://localhost:8081 ' +
                                            '-p 8080:8080'){
                                                
                            try {
                                sh 'cd /home/frontend/ && npm run parallelRun'
                            } catch(e) {
                                catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {
                                    sh "exit 1"
                                }
                                echo "Some of the tests failed, pls check them"
                            }
                            //store results till next run although tests failed
                            sh 'cp -r /home/frontend/cypress/results/ /home/frontend/export/'
                            sh 'cp -r /home/frontend/cypress/videos/ /home/frontend/export/'
                            sh 'cp -r /home/frontend/cypress/screenshots/ /home/frontend/export/'
                        }
                    }
                }
                publishHTML (target : [
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'export/results',
                    reportFiles: '*.html',
                    reportName: 'E2E-Report',
                    reportTitles: ''])
            }
        }
        stage("Publish") {
            steps {
                input "Publish this image"
                script {
                    withDockerRegistry([credentialsId: "DockerHubCredentials", url:""]) {
                        sh "docker tag ecco-frontend:${env.BUILD_ID} bergthalerjku/ecco_frontend:${env.BUILD_ID}"
                        sh "docker push bergthalerjku/ecco_frontend:${env.BUILD_ID}"
                        
                        sh "docker tag ecco-frontend:${env.BUILD_ID} bergthalerjku/ecco_frontend:latest"
                        sh "docker push bergthalerjku/ecco_frontend:latest"
                    }
                }
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'export/results/*', fingerprint: true
        }
        aborted {
            sh 'docker stop $(docker ps -a -q)'
        }
    }
}
