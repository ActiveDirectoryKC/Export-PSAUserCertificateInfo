<#
    .SYNOPSIS 
    Exports certificate information from the userCertificates of the specified user(s).

    .DESCRIPTION
    Exports certificate information from the userCertificates of the specified user(s) to the specified directory (default C:\temp). 
    Information exported
    - Subject Name
    - Issuer
    - NotBefore (Issued date)
    - NotAfter (Expiry)
    - Certificiate Template Name
    - Certificate Template OID

    .PARAMETER UserList
    [string[]] Specify the user(s) that you wish to export their userCertificate attribute.
    Can accept SamAccountName, Name (cn), or UserPrincipalNames.

    .PARAMETER OutputPath
    [string] Specify the output directory for the exported CSV files. Default: C:\temp.
    Should be a directory. If not, the parent directory of the specified file will be used.

    .OUTPUTS
    VOID. Exports the list as a CSV. Returns some standard warning/error if they are encountered. 

    .EXAMPLE
    PS> .\Export-PSADUserCertificateInfo.ps1 -UserList John.Doe, Jane.Doe, Administrator
    Exports the userCertificate(s) for the John.Doe, Jane.Doe, and Administrator users to D:\temp.
    
    .Example 
    PS> .\Export-PSADUserCertificateInfo.ps1 -UserList John.Doe, Jane.Doe, Administrator -OutputPath D:\temp
    Exports the userCertificate(s) for the John.Doe, Jane.Doe, and Administrator users to D:\temp.

    .NOTES
    Created By: Tyler Jacobs
    Created On: 04/27/2023
    Version 1.0

    .LICENSE
    Copyright (c) 2023 ActiveDirectoryKC.NET/Tyler Jacobs

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, HelpMessage="Specify the user(s) that you wish to export their userCertificate attribute.")]
    [string[]]$UserList,

    [Parameter(Mandatory=$false, HelpMessage="Specify the output directory for the exported CSV files. Default: C:\temp")]
    [string]$OutputPath = "C:\temp"
)

# Test the output path. If it is invalid, create it. 
if( !(Test-Path -Path $OutputPath) )
{
    try
    { 
        New-Item -Path $OutputPath -ItemType Directory
    }
    catch
    {
        Write-Error -Message "Failed to create path - $OutputPath - $($PSItem.Exception.Message)"
        throw $Error
    }
}
else # If there is already a path, ensure it isn't a file. If so, assume the parent directory.
{
    if( (Get-Item -Path $OutputPath) -is [FileInfo] )
    {
        $OutputPath = Split-Path -Path $OutputPath -Parent
        Write-Warning -Message "Path '$OutputPath' is a file using the parent directory"
    }
}

foreach( $User in $UserList )
{
    # UserCertificate is a binary array (multi-valued) in AD. Each element represents a certificate.
    # UsersList can be any list of Names, SamAccountNames, or UserPrincipalNames.
    # Don't go crazy with the computer list. This could take awhile for 1000s of users.  
    $UserInfo = Get-ADUser -Filter "Name -eq '$User' -or SamAccountName -eq '$User' -or userPrincipalName -eq '$User'" -Properties userCertificate
    
    # If it is blank, we don't care. Skip it and notify. 
    if( $UserInfo.userCertificate.Count -gt 0 )
    {
        Write-Host -Object "User $User has $($UserInfo.userCertificate.Count) issued certificates in AD - Certificate info exported to C:\temp\" -ForegroundColor Cyan

        # Stores the list of certificates we generate. 
        $ParsedCerts = [System.Collections.Generic.List[object]]::new()

        # Loop through the raw binary data in the userCertificate. 
        foreach( $CertBlob in $UserInfo.userCertificate )
        {
            # There is a .NET class for certificates. Use it. 
            # NOTE: There is an X509Certificate class (without the 2), it appears to have less info than this one. 
            $Cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new()
            $Cert.Import( $CertBlob ) # Import the blob data

            # Template information is stored as part of the extension referenced here. This is standard so this OID will work everywhere.
            # This comes in as a bunch of text. Split the text by carriage return/line break (`r), replace some text, and split again based on the (.
            # This will give us the template name, if it exists, and the template OID. 
            # NOTE: Format accepts any int. 2 seemed the most useful here. 
            # NOTE: The Where() method is kind of funky so be careful modifying this. 
            $CertTemplateInfo = ($Cert.Extensions.Where({ $PSItem.Oid.Value -eq '1.3.6.1.4.1.311.21.7' }).Format(2) -split "`r")[0].Replace("Template=", "").Replace(")","").split("(")

            # Craft a Select-Object with expressions to generate a table. 
            $ParsedCert = $Cert | Select-Object -Property Subject, Issuer, NotBefore, NotAfter, @{Name = "TemplateName"; Expression = { $CertTemplateInfo[0] } }, @{ Name = "TemplateOID"; Expression = { $CertTemplateInfo[1] } }

            # Add the table with Subject (who gets the cert), Issuer (where it came from), NotBefore (Start), NotAfter (Expire), and the template information (TemplateName and OID). 
            $ParsedCerts.Add( $ParsedCert )
        }

        # Dump to a csv. This should allow for quick viewing of lots of users. 
        $ParsedCerts | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath "C:\temp\$($UserInfo.SamAccountName)`_$(Get-Date -Format yyyyMMdd.HHmmss).csv"
    }
    else
    {
        Write-Warning -Message "User $User does not have any issued certificates in AD"
    }
}