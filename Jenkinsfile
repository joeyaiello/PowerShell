node {
  // JenkinsFile Groovy-based PipeLine workflow for Jenkins-CI
  // Documentation:  https://jenkins.io/doc/pipeline/

  wrap([$class: 'AnsiColorBuildWrapper']){
    stage('Checkout'){
	    checkout scm 
    }
    stage('GetPsBins'){
      bat 'powershell.exe -c .\\tools\\Jenkins.ps1 -Download' 
    }
    stage('Docker'){
      bat 'docker create -i --name PoshCore_%BUILD_ID% -h PoshCore microsoft/windowsservercore:10.0.14300.1030 cmd'
      bat 'docker cp "%LOCALAPPDATA%\\Microsoft\\dotnet" PoshCore_%BUILD_ID%:"%LOCALAPPDATA%\\Microsoft\\dotnet"'
      bat 'docker cp "C:\\Program Files\\PowerShell" PoshCore_%BUILD_ID%:"C:\\PowerShell"'
	    bat 'docker cp . PoshCore_%BUILD_ID%:"C:\\PowerShell"'
	    bat 'docker start PoshCore_%BUILD_ID%'
    }
    stage('Execution'){
      try {
	      bat 'docker exec PoshCore_%BUILD_ID% C:\\PowerShell\\powershell.exe -NonInteractive -c "$PsVersionTable;$ErrorActionPreference=\'Stop\';cd C:\\PowerShell;.\\Tools\\Jenkins.ps1 -UpdateTools"'
	      bat 'docker exec PoshCore_%BUILD_ID% C:\\PowerShell\\powershell.exe -NonInteractive-c "$PsVersionTable;$ErrorActionPreference=\'Stop\';cd C:\\PowerShell;.\\Tools\\Jenkins.ps1 -Test"'
      } catch (e) { // if any exception occurs, mark the build as failed
        currentBuild.result = 'FAILURE'
        throw e
      } finally {
        bat 'docker stop PoshCore_%BUILD_ID%' 
	      archive 'PowerShell/**'
  	    bat 'docker rm PoshCore_%BUILD_ID%'
      }
    }
  }
}