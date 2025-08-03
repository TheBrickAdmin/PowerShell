
# Secure Environment Variable Management Functions

This directory provides two PowerShell functions for securely storing and retrieving sensitive environment variables in the Windows registry under the current user (HKCU). These functions are:

- `Set-SecureEnvironmentEncryptedString`
- `Get-SecureEnvironmentEncryptedString`

## Overview

These functions allow you to store sensitive strings (such as passwords or API keys) in the Windows registry in an encrypted format, and retrieve them securely for use in scripts or automation. The encryption is user- and machine-specific, meaning only the same user on the same computer can decrypt the value.

> **Note:**
> - PowerShell's `SecureString` is not cryptographically strong and is deprecated in .NET Core/PowerShell 7+ for true secrets management.
> - These functions are not a replacement for enterprise-grade secret management solutions like Azure Key Vault or HashiCorp Vault.

---

## Function: Set-SecureEnvironmentEncryptedString

**Purpose:**
Encrypts a plaintext string and stores it as an environment variable value in the HKCU environment registry.

**Parameters:**
- `-Content` (string, required): The plaintext value to encrypt and store.
- `-Name` (string, required): The name of the environment variable. Must match `^[A-Za-z_][A-Za-z0-9_]*$`.
- `-Force` (switch, optional): Overwrite an existing value without confirmation.

**Example:**
```powershell
Set-SecureEnvironmentEncryptedString -Content "Welcome123" -Name "MyEncryptedApplicationPassword" -Force
```

**How it works:**
1. Converts the plaintext to a SecureString.
2. Serializes the SecureString to an encrypted string.
3. Stores the encrypted string in the registry at `HKCU:\Environment` under the specified name.
4. Handles overwrites and prompts for confirmation unless `-Force` is used.

---

## Function: Get-SecureEnvironmentEncryptedString

**Purpose:**
Retrieves, decrypts, and returns the plaintext value of an environment variable stored as an encrypted string in the HKCU environment registry.

**Parameters:**
- `-Name` (string, required): The name of the environment variable to retrieve and decrypt.

**Example:**
```powershell
$password = Get-SecureEnvironmentEncryptedString -Name "MyEncryptedApplicationPassword"
```

**How it works:**
1. Reads the encrypted string from the registry at `HKCU:\Environment`.
2. Converts the encrypted string back to a SecureString.
3. Decrypts the SecureString to plaintext.
4. Returns the plaintext value.

---

## Security Considerations

- The encryption is only as strong as the user's Windows account security.
- The encrypted value can only be decrypted by the same user on the same machine.
- For cross-user, cross-machine, or production secrets, use a dedicated secrets management solution (e.g., Azure Key Vault).
- These functions are best suited for local development, automation, or non-critical secrets.

---

## Setting Environment Variables via Task Scheduler with a gMSA

If you are running a process under a Group Managed Service Account (gMSA) and need to set an environment variable for that process, you can use **Task Scheduler**.

### Steps:

1. **Create or Edit a Scheduled Task**
    - Open **Task Scheduler** (`taskschd.msc`).
    - Create a new task or edit an existing one.

2. **Place the secret in a temporary file**
    - Temporarily put the secret in a file, e.g. "C:\Temp\Mysecret.txt"

3. **Set the Environment Variable Using PowerShell and Invoke-Command**
    - Create an action invoking `pwsh.exe` or `powershell.exe`.
    - Pass the following argument:
    ```powershell
    -Command &{ Set-SecureEnvironmentEncryptedString -Name "MyEncryptedApplicationPassword" -Content $(Get-Content -Path "C:\Temp\Mysecret.txt") -Force }
    ```

4. **Schedule the task to run as the gMSA**
    ```powershell
    $principal = New-ScheduledTaskPrincipal -UserId $gMSA -LogonType "Password"
    Set-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Principal $principal
    ```

5. **Run and delete the scheduled task**
    - Run the scheduled task.
    - Once run, delete the scheduled task.
    - Delete the temporary file containing the secret.

---

## Troubleshooting

- If you cannot retrieve a value, ensure the environment variable exists and is set for the correct user context.
- If using PowerShell 7+ or .NET Core, consider using a more secure secrets management solution.

---

## See Also

- [Microsoft Docs: Secrets Management in PowerShell](https://docs.microsoft.com/powershell/utility-modules/secretmanagement/overview)
- [HashiCorp Vault](https://www.hashicorp.com/en/products/vault)
- [Azure Key Vault](https://azure.microsoft.com/en-us/products/key-vault/)