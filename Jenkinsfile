pipeline {
    agent {
        label "windows-ci"
    }
    stages {
        stage('checkout') {
            steps {
                git 'https://github.com/brave-experiments/browser-comparison-toolkit.git'

                powershell """
                        \$ErrorActionPreference = "Stop"
                        # Set-PSDebug -Trace 2
                        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
                        Stop-Process -Name "Brave*" -Force
                        Write-Host "wget https://brave-browser-downloads.s3.brave.com/latest/BraveBrowserSetup.exe"
                        wget "https://brave-browser-downloads.s3.brave.com/latest/BraveBrowserSetup.exe" -OutFile "BraveBrowserSetup.exe"
                        Start-Sleep -Second 10
                        Start-Process "BraveBrowserSetup.exe"
                        Start-Sleep -Second 10
                        ./memory-bench.ps1 Brave five
                        Stop-Process -Name "Brave*" -Force
                    """
                
                benchmark altInputSchema: '''{
                    "type": "object",
                    "properties": {
                        "scenarios": {
                            "type": "array",
                            "items": {
                                "type": "object",
                                "properties": {
                                    "test": { "type": "name" },
                                    "runs": { 
                                        "type": "array",
                                        "items": {
                                            "type": "value"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }''', altInputSchemaLocation: '', inputLocation: '*.json', schemaSelection: 'customSchema', truncateStrings: true
            }
        }
    }
}