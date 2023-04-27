# Export-PSAUserCertificateInfo
Exports certificate information from the userCertificates of the specified user(s).

## DESCRIPTION
Exports certificate information from the userCertificates of the specified user(s) to the specified directory (default C:\temp). 
Information exported
- Subject Name
- Issuer
- NotBefore (Issued date)
- NotAfter (Expiry)
- Certificiate Template Name
- Certificate Template OID

## PARAMETERS
### PARAMETER UserList
\[string\[\]\] Specify the user(s) that you wish to export their userCertificate attribute.
Can accept SamAccountName, Name (cn), or UserPrincipalNames.

### PARAMETER OutputPath
\[string\] Specify the output directory for the exported CSV files. Default: C:\temp.
Should be a directory. If not, the parent directory of the specified file will be used.

## OUTPUTS
VOID. Exports the list as a CSV. Returns some standard warning/error if they are encountered. 

## Examples
### EXAMPLE
PS> .\Export-PSADUserCertificateInfo.ps1 -UserList John.Doe, Jane.Doe, Administrator
Exports the userCertificate(s) for the John.Doe, Jane.Doe, and Administrator users to D:\temp.

### Example 
PS> .\Export-PSADUserCertificateInfo.ps1 -UserList John.Doe, Jane.Doe, Administrator -OutputPath D:\temp
Exports the userCertificate(s) for the John.Doe, Jane.Doe, and Administrator users to D:\temp.

## NOTES
Created By: Tyler Jacobs
Created On: 04/27/2023
Version 1.0

## LICENSE
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
