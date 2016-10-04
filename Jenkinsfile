node {
  // JenkinsFile Groovy-based PipeLine workflow for Jenkins-CI
  // Documentation:  https://jenkins.io/doc/pipeline/
  
  
	stage('Checkout'){
		checkout scm
  }
  stage('Download'){
	  bat 'powershell.exe -c .\\tools\\Jenkins.ps1 -Download'
	}	
  stage('SpinUpContainer'){
	  bat 'docker create -i --name PoshCore_%BUILD_ID% -h PoshCore microsoft/windowsservercore:10.0.14300.1030 cmd'
	  bat 'docker cp "C:\\Program Files\\PowerShell" PoshCore_%BUILD_ID%:"C:\\PowerShell"'
	  bat 'docker cp "%WORKSPACE%\\Tools" PoshCore_%BUILD_ID%:"C:\\PowerShell\\Tools"'
	  bat 'docker cp "%WORKSPACE%\\Test" PoshCore_%BUILD_ID%:"C:\\PowerShell\\Test"'
	  bat 'docker start PoshCore_%BUILD_ID%'
  }
	stage('UpdateTools'){
		bat 'docker exec PoshCore_%BUILD_ID% powershell.exe -c "C:\\PowerShell\\Tools\\Jenkins.ps1 -UpdateTools"'
  }
	stage('Test'){
		bat 'docker exec PoshCore_%BUILD_ID% powershell.exe -c "C:\\PowerShell\\Tools\\Jenkins.ps1 -Test"'
  }
  stage('StopContainer'){
    bat 'docker stop PoshCore_%BUILD_ID%'
  }
	stage('Archive'){
		archive 'PowerShell/**'
		bat 'docker rm PoshCore_%BUILD_ID%'
  }
}
