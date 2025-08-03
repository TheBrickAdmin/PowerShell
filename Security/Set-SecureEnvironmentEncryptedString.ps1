
function Set-SecureEnvironmentEncryptedString {
    <#
    .SYNOPSIS
        Encrypts a plaintext string and stores it as an environment variable value in the HKCU environment registry.

    .DESCRIPTION
        This function takes a plaintext string, encrypts it using a method that ensures it can only be decrypted by the same user on the same computer, and stores the encrypted value in the HKCU environment registry under the specified environment variable name.
        
        Note:
            PowerShell SecureString is not cryptographically strong and is deprecated in .NET Core/PowerShell 7+ for true secrets management.
            This function is not a full replacement for a keyvault like HashiCorp Vault, Azure Key Vault, or other dedicated secret management solutions.

    .PARAMETER Content
        The plaintext string to encrypt and store.

    .PARAMETER Name
        The name of the environment variable to store in the HKCU registry. Must match ^[A-Za-z_][A-Za-z0-9_]*$

    .PARAMETER Force
        A switch to force overwriting an existing environment variable without confirmation.

    .EXAMPLE
        PS> Set-SecureEnvironmentEncryptedString -Content "Welcome123" -Name "MyEncryptedApplicationPassword" -Force
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[A-Za-z_][A-Za-z0-9_]*$')] # Ensures valid registry key names
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    begin {}

    process {
        try {
            # Define the registry path
            $regPath = "HKCU:\Environment"

            # Check if the registry key already exists
            try {
                $existingValue = Get-ItemProperty -Path $regPath -Name $Name -ErrorAction Stop | Select-Object -ExpandProperty $Name
            } catch {
                # It's OK if the value doesn't exist
                $existingValue = $null
            }

            if ($existingValue -and -not $Force.IsPresent) {
                $message = "The environment variable '$Name' already exists. Do you want to overwrite it?"
                if (-not $PSCmdlet.ShouldContinue($message, "Confirm")) {
                    Write-Warning "Operation cancelled: The environment variable '$Name' already exists and was not overwritten."
                    return $false
                }
            }

            if ($PSCmdlet.ShouldProcess("Setting environment variable '$Name'")) {

                # Convert the plaintext string to a secure string
                try {
                    $secureString = ConvertTo-SecureString -String $Content -AsPlainText -Force
                } catch {
                    Write-Error "Failed to convert content to SecureString."
                    return $false
                }

                # Store the encrypted string in the HKCU registry
                try {
                    Set-ItemProperty -Path $regPath -Name $Name -Value ($secureString | ConvertFrom-SecureString)
                } catch {
                    Write-Error "Failed to set the registry value for '$Name'."
                    return $false
                }

                return $true
            } else {
                Write-Warning "ShouldProcess declined: The environment variable '$Name' was not set."
                return $false
            }
        } catch {
            Write-Error "Unexpected error occurred in Set-SecureEnvironmentEncryptedString: $_"
            return $false
        }
    }

    end {}
}