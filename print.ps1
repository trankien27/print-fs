Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-LoginForm {
    $loginSuccess = $false
    $correctPassword = "funstud!o"

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Login"
    $form.Size = New-Object System.Drawing.Size(300, 160)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Enter password:"
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Size = New-Object System.Drawing.Size(250, 20)
    $form.Controls.Add($label)

    $textbox = New-Object System.Windows.Forms.TextBox
    $textbox.Location = New-Object System.Drawing.Point(20, 45)
    $textbox.Size = New-Object System.Drawing.Size(240, 25)
    $textbox.UseSystemPasswordChar = $true
    $form.Controls.Add($textbox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object System.Drawing.Point(50, 90)
    $okButton.Size = New-Object System.Drawing.Size(80, 30)
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Exit"
    $cancelButton.Location = New-Object System.Drawing.Point(150, 90)
    $cancelButton.Size = New-Object System.Drawing.Size(80, 30)
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

$defaultFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)

$form = New-Object System.Windows.Forms.Form
$form.Text = "Print by transactionId"
$form.Size = New-Object System.Drawing.Size(650, 400)
$form.StartPosition = "CenterScreen"
$form.Font = $defaultFont

$btnLoad = New-Object System.Windows.Forms.Button
$btnLoad.Text = "Load list transactions id"
$btnLoad.Location = New-Object System.Drawing.Point(30, 20)
$btnLoad.Size = New-Object System.Drawing.Size(200, 30)
$form.Controls.Add($btnLoad)

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

$lblSelected = New-Object System.Windows.Forms.Label
$lblSelected.Text = "transactionId: ()"
$lblSelected.Location = New-Object System.Drawing.Point(30, 250)
$lblSelected.Size = New-Object System.Drawing.Size(600, 25)
$form.Controls.Add($lblSelected)

$lblLayout = New-Object System.Windows.Forms.Label
$lblLayout.Text = "LayoutId:"
$lblLayout.Location = New-Object System.Drawing.Point(30, 285)
$lblLayout.Size = New-Object System.Drawing.Size(70, 25)
$form.Controls.Add($lblLayout)

$txtLayout = New-Object System.Windows.Forms.TextBox
$txtLayout.Location = New-Object System.Drawing.Point(110, 283)
$txtLayout.Size = New-Object System.Drawing.Size(120, 25)
$form.Controls.Add($txtLayout)

$lblNumber = New-Object System.Windows.Forms.Label
$lblNumber.Text = "Number of images:"
$lblNumber.Location = New-Object System.Drawing.Point(250, 285)
$lblNumber.Size = New-Object System.Drawing.Size(120, 25)
$form.Controls.Add($lblNumber)

$numImage = New-Object System.Windows.Forms.NumericUpDown
$numImage.Location = New-Object System.Drawing.Point(360, 283)
$numImage.Size = New-Object System.Drawing.Size(60, 25)
$numImage.Minimum = 1
$numImage.Maximum = 10
$numImage.Value = 1
$form.Controls.Add($numImage)

$btnSend = New-Object System.Windows.Forms.Button
$btnSend.Text = "Send print command"
$btnSend.Location = New-Object System.Drawing.Point(450, 280)
$btnSend.Size = New-Object System.Drawing.Size(150, 30)
$form.Controls.Add($btnSend)

$global:transactionId = ""

$btnLoad.Add_Click({
    $listView.Items.Clear()
    $global:transactionId = ""

    $root = "D:\Work\PhotoBooth\Image"
    if (-not (Test-Path $root)) {
        [System.Windows.Forms.MessageBox]::Show("Folder does not exist: $root", "Error")
        return
    }

    Get-ChildItem -Path $root -Directory -Force |
    Sort-Object LastWriteTime -Descending |
    ForEach-Object {
        $item = New-Object System.Windows.Forms.ListViewItem($_.Name)
        $item.SubItems.Add($_.LastWriteTime.ToString("yyyy-MM-dd HH:mm"))
        $listView.Items.Add($item)
    }

    [System.Windows.Forms.MessageBox]::Show("Transactions loaded successfully!", "Notification")
})

$listView.Add_SelectedIndexChanged({
    if ($listView.SelectedItems.Count -gt 0) {
        $selectedItem = $listView.SelectedItems[0]
        $global:transactionId = $selectedItem.Text
        $lblSelected.Text = "transactionId: $($global:transactionId)"
    }
})

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

$btnSend.Add_Click({
    if (-not $global:transactionId) {
        [System.Windows.Forms.MessageBox]::Show("You have not selected transactionId!", "Missing information")
        return
    }
    if (-not $txtLayout.Text) {
        [System.Windows.Forms.MessageBox]::Show("You have not typed layoutId", "Missing information")
        return
    }

    Send-ToPrintAPI -transactionId $global:transactionId `
                    -layoutId $txtLayout.Text `
                    -numberOfImage ([int]$numImage.Value)
})

if (Show-LoginForm) {
    $form.Topmost = $true
    [void]$form.ShowDialog()
} else {
    [System.Windows.Forms.MessageBox]::Show("You exited or entered the wrong password!", "Exit")
}
