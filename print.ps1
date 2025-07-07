Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$defaultFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)

# Giao diện chính
$form = New-Object System.Windows.Forms.Form
$form.Text = "In ảnh theo transactionId"
$form.Size = New-Object System.Drawing.Size(650, 400)
$form.StartPosition = "CenterScreen"
$form.Font = $defaultFont

# Nút Tải thư mục
$btnLoad = New-Object System.Windows.Forms.Button
$btnLoad.Text = "Load list transacitons id"
$btnLoad.Location = New-Object System.Drawing.Point(30, 20)
$btnLoad.Size = New-Object System.Drawing.Size(200, 30)
$form.Controls.Add($btnLoad)

# ListView hiển thị danh sách folder
$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(30, 60)
$listView.Size = New-Object System.Drawing.Size(570, 180)
$listView.View = [System.Windows.Forms.View]::Details
$listView.FullRowSelect = $true
$listView.GridLines = $true
$listView.Font = $defaultFont
$listView.Columns.Add("TransactionId", 350)
$listView.Columns.Add("Date Modified", 200)
$form.Controls.Add($listView)

# Label hiển thị transactionId đã chọn
$lblSelected = New-Object System.Windows.Forms.Label
$lblSelected.Text = "transactionId: ()"
$lblSelected.Location = New-Object System.Drawing.Point(30, 250)
$lblSelected.Size = New-Object System.Drawing.Size(600, 25)
$form.Controls.Add($lblSelected)

# Label và TextBox LayoutId
$lblLayout = New-Object System.Windows.Forms.Label
$lblLayout.Text = "LayoutId:"
$lblLayout.Location = New-Object System.Drawing.Point(30, 285)
$lblLayout.Size = New-Object System.Drawing.Size(70, 25)
$form.Controls.Add($lblLayout)

$txtLayout = New-Object System.Windows.Forms.TextBox
$txtLayout.Location = New-Object System.Drawing.Point(110, 283)
$txtLayout.Size = New-Object System.Drawing.Size(120, 25)
$form.Controls.Add($txtLayout)

# Label và NumericUpDown Số ảnh
$lblNumber = New-Object System.Windows.Forms.Label
$lblNumber.Text = "Number of image:"
$lblNumber.Location = New-Object System.Drawing.Point(250, 285)
$lblNumber.Size = New-Object System.Drawing.Size(60, 25)
$form.Controls.Add($lblNumber)

$numImage = New-Object System.Windows.Forms.NumericUpDown
$numImage.Location = New-Object System.Drawing.Point(320, 283)
$numImage.Size = New-Object System.Drawing.Size(60, 25)
$numImage.Minimum = 1
$numImage.Maximum = 10
$numImage.Value = 1
$form.Controls.Add($numImage)

# Nút gửi API
$btnSend = New-Object System.Windows.Forms.Button
$btnSend.Text = "Send print command"
$btnSend.Location = New-Object System.Drawing.Point(420, 280)
$btnSend.Size = New-Object System.Drawing.Size(120, 30)
$form.Controls.Add($btnSend)

# Biến lưu transactionId
$global:transactionId = ""

# Load danh sách folder
$btnLoad.Add_Click({
    $listView.Items.Clear()
    $global:transactionId = ""

    $root = "D:\Work\PhotoBooth\Image"
    if (-not (Test-Path $root)) {
        [System.Windows.Forms.MessageBox]::Show("Folder is not exist: $root", "Error")
        return
    }

    Get-ChildItem -Path $root -Directory -Force |
    Sort-Object LastWriteTime -Descending |
    ForEach-Object {
        $item = New-Object System.Windows.Forms.ListViewItem($_.Name)
        $item.SubItems.Add($_.LastWriteTime.ToString("yyyy-MM-dd HH:mm"))
        $listView.Items.Add($item)
    }

    [System.Windows.Forms.MessageBox]::Show("Load transaction id successfully!", "Noftification")
})

# Khi chọn 1 dòng trong ListView
$listView.Add_SelectedIndexChanged({
    if ($listView.SelectedItems.Count -gt 0) {
        $selectedItem = $listView.SelectedItems[0]
        $global:transactionId = $selectedItem.Text
        $lblSelected.Text = "transactionId: $($global:transactionId)"
    }
})

# Hàm gửi API
function Send-ToPrintAPI {
    param (
        [string]$transactionId,
        [string]$layoutId,
        [int]$numberOfImage,
        [string]$apiUrl = "http://localhost:8088/api/print/printimage"
    )

    try {
        $body = @{
            transactionId = $transactionId
            layoutId = $layoutId
            numberOfImage = $numberOfImage
        }
        $json = $body | ConvertTo-Json -Depth 5
        $response = Invoke-RestMethod -Uri $apiUrl -Method POST -Body $json -ContentType "application/json"

        [System.Windows.Forms.MessageBox]::Show("✅ Print successfully!", "Success")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("❌ Send error: $_", "Error")
    }
}

# Gửi lệnh in
$btnSend.Add_Click({
    if (-not $global:transactionId) {
        [System.Windows.Forms.MessageBox]::Show("You have not selected transactionId !", "Missing information")
        return
    }
    if (-not $txtLayout.Text) {
        [System.Windows.Forms.MessageBox]::Show("You have not type layoutID ", "Missing information")
        return
    }

    Send-ToPrintAPI -transactionId $global:transactionId `
                    -layoutId $txtLayout.Text `
                    -numberOfImage ([int]$numImage.Value)
})

# Show giao diện
$form.Topmost = $true
[void]$form.ShowDialog()