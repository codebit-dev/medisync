Write-Host "Testing CSV Upload..." -ForegroundColor Cyan

$FilePath = "D:\coding\Project\MEDISYNC\sample_namaste_codes.csv"
$URL = "http://localhost:5000/ingest/csv-simple"

# Create multipart form
$boundary = [System.Guid]::NewGuid().ToString()
$LF = "`r`n"

$fileBytes = [System.IO.File]::ReadAllBytes($FilePath)
$fileEnc = [System.Text.Encoding]::GetEncoding('UTF-8').GetString($fileBytes)
$fileName = Split-Path $FilePath -Leaf

$bodyLines = (
    "--$boundary",
    "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"",
    "Content-Type: text/csv",
    "",
    $fileEnc,
    "--$boundary--"
) -join $LF

try {
    $response = Invoke-RestMethod -Uri $URL -Method Post -ContentType "multipart/form-data; boundary=$boundary" -Body $bodyLines
    
    Write-Host "Upload Successful!" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Yellow
    
    if ($response.outcome) {
        Write-Host "  Outcome: $($response.outcome.issue[0].details.text)" -ForegroundColor Cyan
    }
    
    Write-Host "  Resource Type: $($response.resourceType)" -ForegroundColor Gray
    Write-Host "  Name: $($response.name)" -ForegroundColor Gray
    Write-Host "  Concepts Count: $($response.count)" -ForegroundColor Gray
    
} catch {
    Write-Host "Upload Failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
