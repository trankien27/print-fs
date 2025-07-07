Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Load SQLite DLL manually from local file
# Load SQLite DLL from GitHub if not already in TEMP
$sqliteDllPath = "D:\\Work\\PhotoBooth\\Data\\System.Data.SQLite.dll"
if (-not (Test-Path $sqliteDllPath)) {
    try {
        Invoke-WebRequest -Uri "https://github.com/trankien27/print-fs/raw/refs/heads/main/System.Data.SQLite.dll" `
            -OutFile $sqliteDllPath -UseBasicParsing
    } catch {
        [System.Windows.Forms.MessageBox]::Show("❌ Cannot download SQLite DLL. Check internet connection or update URL.", "DLL Load Error")
        exit
    }
}
Add-Type -Path $sqliteDllPath

if (![System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Start-Process powershell.exe "-STA -WindowStyle Normal -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# SQLite Connection
$global:DbPath = "D:\Work\PhotoBooth\Data\Funstudio.db"
$connectionString = "Data Source=$global:DbPath;Version=3;"
$global:SQLiteConnection = New-Object -TypeName System.Data.SQLite.SQLiteConnection -ArgumentList $connectionString

function Open-SQLiteConnection {
    try {
        $global:SQLiteConnection.Open()
    } catch {
        $msg = "Cannot connect to database: $global:DbPath`nError: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show($msg, "Database Error")
        throw
    }
}

function Close-SQLiteConnection {
    if ($global:SQLiteConnection.State -eq 'Open') {
        $global:SQLiteConnection.Close()
    }
}

function Show-LoginForm {
    $loginSuccess = $false
    $correctPassword = "funstud!o"

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Login"
    $form.Size = New-Object System.Drawing.Size(400, 220)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Regular)

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Enter password:"
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Size = New-Object System.Drawing.Size(350, 30)
    $form.Controls.Add($label)

    $textbox = New-Object System.Windows.Forms.TextBox
    $textbox.Location = New-Object System.Drawing.Point(20, 60)
    $textbox.Size = New-Object System.Drawing.Size(340, 30)
    $textbox.UseSystemPasswordChar = $true
    $form.Controls.Add($textbox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object System.Drawing.Point(70, 110)
    $okButton.Size = New-Object System.Drawing.Size(100, 40)
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Exit"
    $cancelButton.Location = New-Object System.Drawing.Point(200, 110)
    $cancelButton.Size = New-Object System.Drawing.Size(100, 40)
    $form.Controls.Add($cancelButton)

    $okButton.Add_Click({
        if ($textbox.Text -eq $correctPassword) {
            $form.Tag = $true
            $form.Close()
        } else {
            [System.Windows.Forms.MessageBox]::Show("Wrong password!", "Error")
            $textbox.Clear()
        }
    })

    $cancelButton.Add_Click({
        $form.Tag = $false
        $form.Close()
    })

    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton

    [void]$form.ShowDialog()
    return $form.Tag -eq $true
}

# Hàm gọi API
function Send-ToPrintAPI {
    param (
        [string]$transactionId,
        [string]$layoutId,
        [int]$numberOfImage = 1,
        [string]$apiUrl = "http://localhost:8088/api/print/printimage"
    )

    try {
        $body = @{
            transactionId = $transactionId
            layoutId = $layoutId
            numberOfImage = $numberOfImage
        }
        $json = $body | ConvertTo-Json -Depth 3
        $response = Invoke-RestMethod -Uri $apiUrl -Method POST -Body $json -ContentType "application/json"
        [System.Windows.Forms.MessageBox]::Show("✅ Print successfully!", "Success")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("❌ Send error: $_", "Error")
    }
}

# Form chính
$form = New-Object System.Windows.Forms.Form
$form.Text = "Transactions Viewer"
$form.Size = New-Object System.Drawing.Size(900, 600)
$form.StartPosition = "CenterScreen"
$form.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Regular)

$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(20, 20)
$listView.Size = New-Object System.Drawing.Size(840, 400)
$listView.View = [System.Windows.Forms.View]::Details
$listView.FullRowSelect = $true
$listView.GridLines = $true
$listView.Columns.Add("TransactionId", 300)
$listView.Columns.Add("Date", 200)
$listView.Columns.Add("LayoutId", 200)
$form.Controls.Add($listView)

$lblSelected = New-Object System.Windows.Forms.Label
$lblSelected.Text = "Selected TransactionId:"
$lblSelected.Location = New-Object System.Drawing.Point(20, 440)
$lblSelected.Size = New-Object System.Drawing.Size(500, 30)
$form.Controls.Add($lblSelected)

$txtLayoutId = New-Object System.Windows.Forms.TextBox
$txtLayoutId.Location = New-Object System.Drawing.Point(20, 480)
$txtLayoutId.Size = New-Object System.Drawing.Size(300, 30)
$form.Controls.Add($txtLayoutId)

$txtNumPrint = New-Object System.Windows.Forms.TextBox
$txtNumPrint.Location = New-Object System.Drawing.Point(340, 480)
$txtNumPrint.Size = New-Object System.Drawing.Size(80, 30)
$txtNumPrint.Text = "1"
$form.Controls.Add($txtNumPrint)

$btnPrintNow = New-Object System.Windows.Forms.Button
$btnPrintNow.Text = "Print"
$btnPrintNow.Location = New-Object System.Drawing.Point(430, 480)
$btnPrintNow.Size = New-Object System.Drawing.Size(120, 40)
$form.Controls.Add($btnPrintNow)

$btnPrintNow.Add_Click({
    if ($listView.SelectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please select a transaction!", "Missing data")
        return
    }
    if (-not $txtLayoutId.Text) {
        [System.Windows.Forms.MessageBox]::Show("Please enter layoutId", "Missing data")
        return
    }
    $num = 1
    if ([int]::TryParse($txtNumPrint.Text, [ref]$num) -eq $false -or $num -le 0) {
        [System.Windows.Forms.MessageBox]::Show("Invalid number of prints", "Error")
        return
    }

    $selected = $listView.SelectedItems[0]
    $transactionId = $selected.Text
    Send-ToPrintAPI -transactionId $transactionId -layoutId $txtLayoutId.Text -numberOfImage $num
})

$listView.Add_SelectedIndexChanged({
    if ($listView.SelectedItems.Count -gt 0) {
        $selected = $listView.SelectedItems[0]
        $lblSelected.Text = "Selected TransactionId: " + $selected.Text
        $txtLayoutId.Text = $selected.SubItems[2].Text
    }
})

# Load danh sách giao dịch từ DB
function Load-Transactions {
    $listView.Items.Clear()
    $query = "SELECT Id, RecordAt, LayoutId FROM Transactions ORDER BY RecordAt DESC LIMIT 200"
    $cmd = $global:SQLiteConnection.CreateCommand()
    $cmd.CommandText = $query
    $reader = $cmd.ExecuteReader()
    while ($reader.Read()) {
        $id = $reader["Id"]
        $date = ([datetime]$reader["RecordAt"]).ToString("yyyy-MM-dd HH:mm")
        $layout = $reader["LayoutId"]
        $item = New-Object System.Windows.Forms.ListViewItem($id)
        $item.SubItems.Add($date)
        $item.SubItems.Add($layout)
        $listView.Items.Add($item)
    }
    $reader.Close()
}

# Chạy chương trình
if (Show-LoginForm) {
    Open-SQLiteConnection
    Load-Transactions
    $form.Topmost = $true
    [void]$form.ShowDialog()
    Close-SQLiteConnection
} else {
    [System.Windows.Forms.MessageBox]::Show("You exited or entered the wrong password!", "Exit")
}