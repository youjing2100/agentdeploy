Install-Module -Name Az -AllowClobber -Scope AllUsers

Connect-AzAccount 

$runcmdparameters=@{
        "vstsAccount"="youjinglee";
        "personalAccessToken"="3u3jqbpzn4yjnltgksqeoprajfro3kttmscobeam3wybt2tlo5wa";
        "AgentName"="AgentDeployTest";
        "PoolName"="Azure TestingWeb"
}

Invoke-AzVMRunCommand -ResourceGroupName expansionTesting2 -VMName DataVM4 -ScriptPath "C:\Users\demouser\Desktop\installvstsagent.ps1" -CommandId 'RunPowerShellScript' -Parameter $runcmdparameters -Verbose
