Function Get-CUPIRootAPIURL {
    $env:CUPIRootAPIURL
}

Function Set-CUPIRootAPIURL {
    param(
        $RootAPIURL
    )
    [Environment]::SetEnvironmentVariable( "CUPIRootAPIURL", $RootAPIURL, "User" )
}

function Find-CUPIUser {
    param(
        $Query
    )
    Invoke-CUPIAPIFunctionWithQueryStringParameters -HttpMethod Get -Parameters $PSBoundParameters -ResourceType users |
    Select -ExpandProperty User
}

function Get-CUPIUserDetails {
    param(
        [Parameter(ValueFromPipelineByPropertyName)]$ObjectID
    )
    Invoke-CUPIAPIFunction -HttpMethod Get -ResourceType users -ObjectID $ObjectID
}

function Remove-CUPIUser {
    param(
        [Parameter(ValueFromPipelineByPropertyName)]$ObjectID
    )
    Invoke-CUPIAPIFunction -HttpMethod Delete -ResourceType users -ObjectID $ObjectID
}

Function Find-CUPIUserByAlias {
    param(
        $Alias
    )
    
    Find-CUPIUser -Query $(New-CUPIQuery -PropertyName alias -Operator is -Value $Alias)
}

#function New-CUPIUser {
#    param(
#        [String]$Alias,
#        [Boolean]$UseDefaultTimeZone
#    )
#    Invoke-CUPIAPIFunctionWithQueryStringParameters  -HttpMethod Get -Parameters $PSBoundParameters    
#
#}

function Get-CUPIAPIURLWithParametersInURL {
    param(
        [parameter(Mandatory)][ValidateSet("users","distributionlists","mailbox")]$ResourceType, 
        $Parameters = @{}
    )
    $URLEncodedParameters = @{}
    foreach ($Key in $Parameters.Keys) {
        $Value = if($Key -ne "query") { [Uri]::EscapeDataString($Parameters[$Key]) } else { $Parameters[$Key] }
        $URLEncodedParameters.Add($Key.ToLower(), $Value) 
    }

    $FormattedParameters = $($URLEncodedParameters.Keys | % { $_ +"=" + $URLEncodedParameters[$_] }) -join "&"

    $URL = $(Get-CUPIRootAPIURL) + "/" + $ResourceType 
    if ($FormattedParameters) {
        $URL += "?" + $FormattedParameters
    }
    $URL
}


function New-CUPIQuery {
    param(
        #http://docwiki.cisco.com/wiki/Cisco_Unity_Connection_Provisioning_Interface_(CUPI)_API_--_User_API#Listing_Specific_Tenant_Related_Users_by_System_Administrator
        [parameter(Mandatory)]
#        [ValidateSet("Inactive","Alias","DisplayName")]
        $PropertyName,

        [parameter(Mandatory)]
        [ValidateSet("is","startswith","isnull","isnotnull")]
        $Operator,

        [parameter(Mandatory)]
        $Value
    )

    "(" + [Uri]::EscapeDataString("$PropertyName $Operator $Value") + ")"
}

function New-CUCCredential {
    $CUCCredential = Get-Credential
    $CUCCredential | Export-Clixml $env:USERPROFILE\CUCCredential.txt
}  

function Invoke-CUPIAPIFunctionWithQueryStringParameters {
    param(
        [parameter(Mandatory)][ValidateSet("Get","Post","Put")]$HttpMethod,
        [parameter(Mandatory)][ValidateSet("users","distributionlists","mailbox")]$ResourceType,
        $Parameters = @{}
    )
    add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

    $Credential = Import-Clixml $env:USERPROFILE\CUCCredential.txt

    $URI = Get-CUPIAPIURLWithParametersInURL -ResourceType $ResourceType -Parameters $Parameters

    $Result = Invoke-WebRequest -Uri $URI -Method $HttpMethod -Credential $Credential -Headers @{"accept"="application/json"}
    $ResultObject = $Result.Content | ConvertFrom-Json
    $ResultObject

    #$ResourceResponse = $ResultObject.$ResourceType
    #$ResourceResponseMainPropertyName = $ResourceResponse | gm -MemberType Properties | where name -NE Total | select -ExpandProperty name
    #$ResourceResponse.$ResourceResponseMainPropertyName
}

function Invoke-CUPIAPIFunction {
    param(
        [parameter(Mandatory)][ValidateSet("Get","Post","Put","Delete")]$HttpMethod,
        [parameter(Mandatory)][ValidateSet("users","distributionlists","mailbox")]$ResourceType,
        $ObjectID
    )
    $Credential = Import-Clixml $env:USERPROFILE\CUCCredential.txt

    $URI = $(Get-CUPIRootAPIURL) + "/" + $ResourceType 
    if ($ObjectID) {
        $URI += "/" + $ObjectID
    }
    $Response = Invoke-WebRequest -Uri $URI -Method $HttpMethod -Credential $Credential
    if ($Response.StatusCode -eq 200) {
        $XmlContent = [xml]$Response.Content

        $ResourceResponse = $XmlContent.$ResourceType
        $ResourceResponseMainPropertyName = $ResourceResponse | gm -MemberType Properties | where name -NE Total | select -ExpandProperty name
        $ResourceResponse.$ResourceResponseMainPropertyName
    } else { $Response }
}
