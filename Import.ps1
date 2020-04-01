ClientId: 2f4c7565-3685-41d5-b92e-cdfcb3b7f2e3
        IdHostName: identity-au.perspectiveilm.com
        ApiHostName: datagovernor-dev-spa.azurewebsites.net
        AgentHostName: PerDev-DG21.bizdata.local
      shell: pwsh
      run: |
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $ClientId = $env:ClientId;
        $IdHostName= $env:IdHostName;
            
        $TokenRequestBody = @{
            "grant_type"    = "client_credentials";
            "client_id"     = $ClientId;
            "client_secret" = $ClientId;
            "scope"         = "webApi"
        };
        $AccessToken = ((Invoke-WebRequest -Uri "https://$IdHostName/connect/token" -Method Post -Body $TokenRequestBody).Content | ConvertFrom-Json).access_token;
            
        $ArtifactOutputDir = (Get-ChildItem $env:SYSTEM_DEFAULTWORKINGDIRECTORY)[0].FullName
        $ApiHostName = $env:ApiHost;
        $BaseUrl = "https://$env:ApiHostName/api/v1/";
        $AgentHostname = $env:AgentHostName;
            
        function Upload-Zip ($ZipLocation) {
            $AccessHeaders = @{"Authorization" = "bearer $AccessToken" }
            
            $ZipUploadUrl = $BaseUrl + "Import/Zip?agentHostName=$AgentHostName";
            
            try {
                $Response = Invoke-RestMethod $ZipUploadUrl -Method 'POST' -Headers $AccessHeaders -InFile $ZipLocation -ContentType "application/zip";
                Write-Output $Response;
            }
            catch {
                $Exception = $_.Exception;
                $ErrorMessage = $Exception.Message;
                if ($null -ne $Exception.Response) { 
                    $Stream = $Exception.Response.GetResponseStream();
                    $ContentReader = New-Object System.IO.StreamReader -ArgumentList $Stream;
                    $ErrorMessage = $ContentReader.ReadToEnd()
                }
                throw $ErrorMessage;
            }
        }
        
        $ZipPath = "tenant.zip";
        Remove-Item $ZipPath -ErrorAction Ignore;
        [System.IO.Compression.ZipFile]::CreateFromDirectory($ArtifactOutputDir, $ZipPath, 0, $false);  
        Upload-Zip -ZipLocation $ZipPath;