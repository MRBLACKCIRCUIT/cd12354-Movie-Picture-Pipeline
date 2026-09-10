# PowerShell script to add github-action-user to EKS aws-auth ConfigMap
$ErrorActionPreference = "Stop"

Write-Host "Fetching IAM github-action-user ARN..." -ForegroundColor Cyan
try {
    $userArn = (aws iam get-user --user-name github-action-user --query "User.Arn" --output text).Trim()
    Write-Host "Found User ARN: $userArn" -ForegroundColor Green
} catch {
    Write-Warning "Could not fetch IAM user automatically via AWS CLI. Using default ARN from patch file."
    $userArn = "arn:aws:iam::207770330185:user/github-action-user"
}

$patchContent = @"
data:
  mapUsers: |
    - userarn: $userArn
      username: github-action-role
      groups:
      - system:masters
"@

$patchFilePath = Join-Path $PSScriptRoot "aws-auth-patch.yaml"
Set-Content -Path $patchFilePath -Value $patchContent -Encoding UTF8
Write-Host "Wrote updated patch file to $patchFilePath" -ForegroundColor Green

Write-Host "Applying patch to EKS aws-auth ConfigMap..." -ForegroundColor Cyan
kubectl patch configmap/aws-auth -n kube-system --patch-file $patchFilePath

Write-Host "Verifying aws-auth ConfigMap..." -ForegroundColor Cyan
kubectl get configmap/aws-auth -n kube-system -o yaml
Write-Host "Done! github-action-user has been successfully added to Kubernetes auth." -ForegroundColor Green
