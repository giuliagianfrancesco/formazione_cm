def buildAndPushTag(Map args) {
    def defaults = [
        registryUrl: 'http://localhost:5000',
        dockerfileDir: "./",
        dockerfileName: " Dockerfile.${env.so}.j2",
        buildArgs: "",
        pushLatest: false
    ]
    args = defaults + args
    docker.withRegistry(args.registryUrl, args.credentialsId) {
        def image = docker.build("${args.image}:${args.buildTag}", "${args.buildArgs} -f ${args.dockerfileName} ${args.dockerfileDir}")
        image.push(args.buildTag)
        if (args.pushLatest) {
            image.push("latest")
            sh "docker rmi --force ${args.image}:latest"
        }
        sh "docker rmi --force ${args.image}:${args.buildTag}"
        return "${args.image}:${args.buildTag}"
    }
}

pipeline {
    agent any

    environment {
        registry = "localhost:5000"
        dockerImage = 'formazione_cm'
        so = 
    }

    stages {
        stage('Build & Push') {
            steps {
                script {
                    buildAndPushTag(
                        image: "${env.registry}/${env.dockerImage}",
                        buildTag: "${env.BUILD_NUMBER}",
                    )
                }
            }
        }
    }
}
