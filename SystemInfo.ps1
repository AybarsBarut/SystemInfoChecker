Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# --- Sistem Bilgilerini Çekme ===
$cpu = (Get-CimInstance Win32_Processor).Name

$ramBytes = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum
$ramGB = [math]::Round($ramBytes / 1GB, 2)
$ramText = "$ramGB GB"

$diskText = ""
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
foreach ($disk in $disks) {
    if ($disk.Size) {
        $totalGB = [math]::Round($disk.Size / 1GB, 2)
        $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        $diskText += "$($disk.DeviceID) ($totalGB GB Toplam, $freeGB GB Boş)`r`n"
    } else {
        $diskText += "$($disk.DeviceID) (Boyut Bilgisi Alınamadı)`r`n"
    }
}
$diskText = $diskText.TrimEnd()

$gpuText = ""
$gpus = Get-CimInstance Win32_VideoController
foreach ($gpu in $gpus) {
    $gpuName = $gpu.Name
    $wattageInfo = ""
    if ($gpuName -match "NVIDIA") {
        try {
            $nvidiaSmi = & "nvidia-smi" -q -d power 2>$null
            if ($nvidiaSmi) {
                $maxPowerMatch = $nvidiaSmi | Select-String -Pattern "Max Power Limit\s+:\s+(.*)" | Select-Object -First 1
                if ($maxPowerMatch) {
                    $val = $maxPowerMatch.Matches[0].Groups[1].Value
                    $wattageInfo = " (Maksimum Güç Sınırı: $val)"
                }
            }
        } catch { }
    }
    $gpuText += "- $gpuName$wattageInfo`r`n"
}
$gpuText = $gpuText.TrimEnd()

$sysInfoString = "===== SİSTEM BİLGİLERİ =====`r`n`r`n"
$sysInfoString += "İŞLEMCİ (CPU):`r`n- $cpu`r`n`r`n"
$sysInfoString += "BELLEK (RAM):`r`n- $ramText`r`n`r`n"
$sysInfoString += "EKRAN KARTI (GPU):`r`n$gpuText`r`n`r`n"
$sysInfoString += "DEPOLAMA (Diskler):`r`n$diskText"

# --- UI (Kullanıcı Arayüzü) ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Sistem Araçları"
$form.Size = New-Object System.Drawing.Size(550, 500)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)

$fontMain = New-Object System.Drawing.Font("Segoe UI", 10)
$form.Font = $fontMain

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "💻 Donanım Özellikleri"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblTitle.Location = New-Object System.Drawing.Point(20, 15)
$lblTitle.AutoSize = $true
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$form.Controls.Add($lblTitle)

$txtInfo = New-Object System.Windows.Forms.TextBox
$txtInfo.Multiline = $true
$txtInfo.ReadOnly = $true
$txtInfo.ScrollBars = "Vertical"
$txtInfo.Location = New-Object System.Drawing.Point(25, 60)
$txtInfo.Size = New-Object System.Drawing.Size(485, 330)
$txtInfo.Text = $sysInfoString
$txtInfo.BackColor = [System.Drawing.Color]::White
$txtInfo.Font = New-Object System.Drawing.Font("Consolas", 10.5)
$txtInfo.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($txtInfo)

$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "Masaüstüne system.txt Olarak Kaydet"
$btnSave.Location = New-Object System.Drawing.Point(25, 405)
$btnSave.Size = New-Object System.Drawing.Size(485, 40)
$btnSave.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnSave.ForeColor = [System.Drawing.Color]::White
$btnSave.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSave.FlatAppearance.BorderSize = 0
$btnSave.Font = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
$btnSave.Cursor = [System.Windows.Forms.Cursors]::Hand

$btnSave.Add_Click({
    try {
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $filePath = Join-Path $desktopPath "system.txt"
        $sysInfoString | Out-File -FilePath $filePath -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Tüm özellikler başarıyla kaydedildi!`nKonum: $filePath", "İşlem Başarılı", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Kaydetme işlemi başarısız oldu", "Hata", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$form.Controls.Add($btnSave)

$form.ShowDialog() | Out-Null
