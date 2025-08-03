function Get-SecureEnvironmentEncryptedString {
    <#
    .SYNOPSIS
        Securely retrieves, decrypts, and returns the plaintext value of an environment variable stored as an encrypted string in the HKCU environment registry.

    .DESCRIPTION
        Retrieves an environment variable stored as an encrypted string in the HKCU environment registry, decrypts it securely, and returns the plaintext value.
                
        Note:
            PowerShell SecureString is not cryptographically strong and is deprecated in .NET Core/PowerShell 7+ for true secrets management.
            This function is not a full replacement for a keyvault like HashiCorp Vault, Azure Key Vault, or other dedicated secret management solutions.

    .PARAMETER Name
        The name of the environment variable to retrieve and decrypt.

    .EXAMPLE
        PS> Get-SecureEnvironmentEncryptedString -Name "MyEncryptedApplicationPassword"
        Welcome123
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[A-Za-z_][A-Za-z0-9_]*$')] # Good: Ensures valid registry key names
        [string]$Name
    )

    begin {}

    process {
        try {
            $regPath = "HKCU:\Environment"

            try {
                # Good: Using -ErrorAction Stop to catch missing registry values
                $encryptedString = Get-ItemProperty -Path $regPath -Name $Name -ErrorAction Stop | Select-Object -ExpandProperty $Name
            } catch {
                return $null # Consider logging or throwing a more descriptive error
            }

            try {
                $secureString = $encryptedString | ConvertTo-SecureString -ErrorAction Stop
            } catch {
                return $null # Same here: silent failure may hinder debugging
            }

            try {
                $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
                $plaintext = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
            } catch {
                return $null
            } finally {
                # Good: Zeroing out memory to reduce risk of sensitive data lingering
                if ($bstr) {
                    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
                }
                # Optional: SecureString doesn't implement IDisposable, so this check is unnecessary
                if ($secureString -and ($secureString -is [System.IDisposable])) {
                    $secureString.Dispose()
                }
            }

            return $plaintext
        } catch {
            # Bad: Returning null is a bad practice in pretty much any language.
            return $null # Consider using Write-Error or Write-Verbose for better diagnostics.
        }
    }

    end {}
}
