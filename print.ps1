Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Data.SQLite
# SQLite Connection
$global:DbPath = "D:\Work\PhotoBooth\Data\Funstudio.db"
$global:SQLiteConnection = New-Object System.Data.SQLite.SQLiteConnection
$global:SQLiteConnection.ConnectionString = "Data Source=$global:DbPath;Version=3;"

function Open-SQLiteConnection {
    try {
        # SQLite Connection
$global:DbPath = "D:\Work\PhotoBooth\Data\Funstudio.db"
$connectionString = "Data Source=$global:DbPath;Version=3;"
$global:SQLiteConnection = New-Object -TypeName System.Data.SQLite.SQLiteConnection -ArgumentList $connectionString

    } catch {
     $msg = "Cannot connect to database: $global:DbPath`nError: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show($msg, "Database Error")
        [System.Windows.Forms.MessageBox]::Show("Cannot connect to database: $global:DbPath", "Database Error")
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

# GUI hiển thị Transactions từ database

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

# Load data from DB
function Load-Transactions {
    $listView.Items.Clear()
    $query = "SELECT Id, RecordAt, LayoutId FROM Transactions ORDER BY RecordAt DESC LIMIT 200"
    $cmd = $global:SQLiteConnection.CreateCommand()
    $cmd.CommandText = $query
    $reader = $cmd.ExecuteReader()
    while ($reader.Read()) {
        $id = $reader["TransactionId"]
        $date = ([datetime]$reader["RecordAt"]).ToString("yyyy-MM-dd HH:mm")
        $layout = $reader["LayoutId"]
        $item = New-Object System.Windows.Forms.ListViewItem($id)
        $item.SubItems.Add($date)
        $item.SubItems.Add($layout)
        $listView.Items.Add($item)
    }
    $reader.Close()
}

$listView.Add_SelectedIndexChanged({
    if ($listView.SelectedItems.Count -gt 0) {
        $selected = $listView.SelectedItems[0]
        $lblSelected.Text = "Selected TransactionId: " + $selected.Text
        $txtLayoutId.Text = $selected.SubItems[2].Text
    }
})

if (Show-LoginForm) {
    Open-SQLiteConnection
    Load-Transactions
    $form.Topmost = $true
    [void]$form.ShowDialog()
    Close-SQLiteConnection
} else {
    [System.Windows.Forms.MessageBox]::Show("You exited or entered the wrong password!", "Exit")
}