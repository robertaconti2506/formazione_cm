pipeline {
	agent {
		label 'step5-agent'
	}

	stages {
		stage('Build image') {
			steps {
				sh '''
					docker build -f roles/step5/files/Dockerfile -t 192.168.56.112:5002/step5-docker:${BUILD_NUMBER} . 
				'''
			}
		}

		stage('Push image') {
			steps {
				sh '''
					docker push 192.168.56.112:5002/step5-docker:${BUILD_NUMBER}
				'''
			}
		}

	}
}
