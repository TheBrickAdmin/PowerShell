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
        [ValidatePattern('^[A-Za-z_][A-Za-z0-9_]*$')] # Ensures valid registry key names
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
                Write-Warning "The environment variable '$Name' does not exist or could not be retrieved."
            }

            # Convert the encrypted string back to a secure string
            try {
                $secureString = $encryptedString | ConvertTo-SecureString -ErrorAction Stop
            } catch {
                Write-Error "Failed to convert the encrypted string to SecureString for '$Name'."
            }

            # Convert the secure string to plaintext
            try {
                $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
                $plaintext = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
            } catch {
                Write-Error "Failed to convert SecureString to plaintext for '$Name'."
            } finally {
                # Always clear sensitive data from memory as soon as possible
                if ($bstr) {
                    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
                }
                $secureString = $null
            }

            # Return the plaintext string
            return $plaintext
        } catch {
            Write-Error "Unexpected error occurred in Get-SecureEnvironmentEncryptedString: $_"
        }
    }

    end {}
}