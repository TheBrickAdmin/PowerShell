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
        [ValidatePattern('^[A-Za-z_][A-Za-z0-9_]*$')] # Disallow characters not valid in registry value names
        [string]$Name
    )

    begin {}

    process {
        try {
            # Retrieve the encrypted string from the HKCU registry
            $regPath = "HKCU:\Environment"
            try {
                $encryptedString = Get-ItemProperty -Path $regPath -Name $Name -ErrorAction Stop | Select-Object -ExpandProperty $Name
            } catch {
                return $null
            }

            # Convert the encrypted string back to a secure string
            try {
                $secureString = $encryptedString | ConvertTo-SecureString -ErrorAction Stop
            } catch {
                return $null
            }

            # Convert the secure string to plaintext
            try {
                $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
                $plaintext = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
            } catch {
                return $null
            } finally {
                # Always clear sensitive data from memory as soon as possible
                if ($bstr) {
                    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
                }
                if ($secureString -and ($secureString -is [System.IDisposable])) {
                    $secureString.Dispose()
                }
            }

            # Return the plaintext string
            return $plaintext
        } catch {
            return $null
        }
    }

    end {}
}