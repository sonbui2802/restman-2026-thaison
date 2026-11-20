param([string]$BaseUrl = 'http://localhost:8080/restman6', [switch]$WriteData)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Net.Http
function New-Client6 {
    $handler6 = New-Object System.Net.Http.HttpClientHandler
    $handler6.CookieContainer = New-Object System.Net.CookieContainer
    return New-Object System.Net.Http.HttpClient($handler6)
}
function Request6($Client, [string]$Page, [hashtable]$Fields = $null) {
    $url6 = "$BaseUrl/view/$Page"
    if ($null -eq $Fields) { $response6 = $Client.GetAsync($url6).GetAwaiter().GetResult() }
    else {
        $dict6 = New-Object 'System.Collections.Generic.Dictionary[string,string]'
        foreach ($key6 in $Fields.Keys) { $dict6.Add($key6, [string]$Fields[$key6]) }
        $body6 = New-Object System.Net.Http.FormUrlEncodedContent($dict6)
        try { $response6 = $Client.PostAsync($url6,$body6).GetAwaiter().GetResult() }
        finally { $body6.Dispose() }
    }
    try {
        return @{ Status=[int]$response6.StatusCode; Html=$response6.Content.ReadAsStringAsync().GetAwaiter().GetResult(); Url=$response6.RequestMessage.RequestUri.AbsoluteUri }
    } finally { $response6.Dispose() }
}
function Assert6([bool]$Condition, [string]$Message) { if (!$Condition) { throw $Message }; Write-Host "PASS $Message" }
function Token6($Page) {
    $match6 = [regex]::Match($Page.Html,'name="csrf6" value="([^"]+)"')
    Assert6 $match6.Success 'CSRF token present'
    return $match6.Groups[1].Value
}
function Buttons6($Page,[int]$Count) {
    Assert6 ($Page.Status -eq 200) 'JSP returns HTTP 200'
    Assert6 ([regex]::Matches($Page.Html,'<button\b').Count -eq $Count) "Exactly $Count buttons"
}
function Fields6($Page,[int]$Count) {
    $controls6 = [regex]::Matches($Page.Html,'<(input|select|textarea)\b[^>]*>')
    $visible6 = @($controls6 | Where-Object { $_.Value -notmatch 'type="hidden"' })
    Assert6 ($visible6.Count -eq $Count) "Exactly $Count visible form controls"
}
$manager6 = New-Client6
$customer6 = New-Client6
$anonymous6 = New-Client6
try {
    $page6=Request6 $anonymous6 'AddDish6.jsp'
    Assert6 ($page6.Url.EndsWith('/Login6.jsp')) 'Anonymous requests require login'
    $page6=Request6 $manager6 'Login6.jsp'
    Buttons6 $page6 1; Fields6 $page6 2
    $token6=Token6 $page6
    $page6=Request6 $manager6 'Login6.jsp' @{csrf6=$token6; username='managerson'; password='wrong'}
    Assert6 ($page6.Html.Contains('Tài khoản hoặc mật khẩu không đúng.')) 'Wrong password rejected'
    $page6=Request6 $manager6 'Login6.jsp' @{csrf6=$token6; username='managerson'; password='12345678'}
    Assert6 ($page6.Url.EndsWith('/ManagerHome6.jsp')) 'Manager login routes correctly'
    Buttons6 $page6 2
    Assert6 ((Request6 $manager6 'CustomerHome6.jsp').Status -eq 403) 'Manager cannot access customer pages'
    $page6=Request6 $manager6 'ManageDish6.jsp'; Buttons6 $page6 1
    Assert6 ([regex]::Matches($page6.Html,'<th>').Count -eq 8) 'Dish list has exactly eight columns'
    $page6=Request6 $manager6 'AddDish6.jsp'; Buttons6 $page6 2; Fields6 $page6 6
    $token6=Token6 $page6
    $category6=[regex]::Match($page6.Html,'<option value="([0-9]+)"').Groups[1].Value
    $page6=Request6 $manager6 'AddDish6.jsp' @{txtName='Bad CSRF'; btnAdd='1'}
    Assert6 ($page6.Html.Contains('Phiên biểu mẫu hết hạn')) 'Dish form rejects missing CSRF'
    $page6=Request6 $manager6 'AddDish6.jsp' @{csrf6=$token6; txtName='Invalid price'; slCategory=$category6; txtPrice='NaN'; txtUnit='Đĩa'; btnAdd='1'}
    Assert6 ($page6.Html.Contains('Đơn giá phải là số dương hữu hạn.')) 'Dish form rejects non-finite price'
    if ($WriteData) {
        $marker6='HTTP6-'+[guid]::NewGuid().ToString('N')
        $page6=Request6 $manager6 'AddDish6.jsp' @{csrf6=$token6; txtName="$marker6 <script>"; slCategory=$category6; txtPrice='120000'; txtUnit='Đĩa'; txtImage=''; txtDescription='Món Việt'; btnAdd='1'}
        Assert6 ($page6.Url.EndsWith('/ManageDish6.jsp') -and $page6.Html.Contains('Thêm món ăn thành công')) 'Dish is saved'
        Assert6 ($page6.Html.Contains("$marker6 &lt;script&gt;")) 'Dish name is escaped'
        Write-Host "Created dish marker: $marker6"
    }
    $page6=Request6 $customer6 'Login6.jsp'; $token6=Token6 $page6
    $page6=Request6 $customer6 'Login6.jsp' @{csrf6=$token6; username='customer6'; password='12345678'}
    Assert6 ($page6.Url.EndsWith('/CustomerHome6.jsp')) 'Customer login routes correctly'; Buttons6 $page6 2
    Assert6 ((Request6 $customer6 'ManageDish6.jsp').Status -eq 403) 'Customer cannot access manager pages'
    $page6=Request6 $customer6 'SearchTable6.jsp'; Buttons6 $page6 1; Fields6 $page6 4; $token6=Token6 $page6
    Assert6 ($page6.Html.Contains('name="inStartTime" type="time"') -and $page6.Html.Contains('name="inEndTime" type="time"')) 'Search uses separate start and end time fields'
    Assert6 (!$page6.Html.Contains('inTimeBlock')) 'Fixed time-block selector removed'
    $page6=Request6 $customer6 'SearchTable6.jsp' @{csrf6=$token6; inDate='2020-01-01'; inStartTime='19:10'; inEndTime='21:05'; inGuestNumber='5'; btnSearch='1'}
    Assert6 ($page6.Html.Contains('Vui lòng chọn thời gian trong tương lai.')) 'Past reservation rejected'
    $date6=(Get-Date).AddDays(120).ToString('yyyy-MM-dd')
    foreach ($endTime6 in @('18:00','19:10')) {
        $page6=Request6 $customer6 'SearchTable6.jsp' @{csrf6=$token6; inDate=$date6; inStartTime='19:10'; inEndTime=$endTime6; inGuestNumber='5'; btnSearch='1'}
        Assert6 ($page6.Html.Contains('Giờ kết thúc phải sau giờ bắt đầu')) 'End time must be later than start time'
    }
    $page6=Request6 $customer6 'SearchTable6.jsp' @{csrf6=$token6; inDate=$date6; inStartTime='25:00'; inEndTime='21:05'; inGuestNumber='5'; btnSearch='1'}
    Assert6 ($page6.Html.Contains('giờ bắt đầu và giờ kết thúc hợp lệ')) 'Invalid time rejected by JSP'
    $page6=Request6 $customer6 'SearchTable6.jsp' @{csrf6=$token6; inDate=$date6; inStartTime='19:10'; inEndTime='21:05'; inGuestNumber='5'; btnSearch='1'}
    Assert6 ($page6.Url.EndsWith('/SelectTable6.jsp')) 'Search routes to table selection'; Buttons6 $page6 2
    Assert6 ($page6.Html.Contains('19:10 - 21:05')) 'Arbitrary start and end times preserved'
    $page6=Request6 $customer6 'SelectTable6.jsp' @{csrf6=$token6; btnBack='1'}
    Assert6 ($page6.Url.EndsWith('/SearchTable6.jsp') -and $page6.Html.Contains('name="inStartTime" type="time" step="60" required value="19:10"') -and $page6.Html.Contains('name="inEndTime" type="time" step="60" required value="21:05"')) 'Back navigation restores both time fields'
    $page6=Request6 $customer6 'SearchTable6.jsp' @{csrf6=$token6; inDate=$date6; inStartTime='19:10'; inEndTime='21:05'; inGuestNumber='5'; btnSearch='1'}
    Assert6 ([regex]::Matches($page6.Html,'<th>').Count -eq 5) 'Table selection has exactly five columns'
    Assert6 (!$page6.Html.Contains('<th>id</th>')) 'Table selection has no extra id column'
    $matches6=[regex]::Matches($page6.Html,'name="chkTables" value="([0-9]+)"')
    Assert6 ($matches6.Count -ge 2) 'Demo has two free tables'
    $tableA6=$matches6[0].Groups[1].Value; $tableB6=$matches6[1].Groups[1].Value
    $page6=Request6 $customer6 'SelectTable6.jsp' @{csrf6=$token6; chkTables='2147483647'; btnContinue='1'}
    Assert6 ($page6.Html.Contains('lựa chọn không hợp lệ')) 'Tampered table ID rejected'
    $page6=Request6 $customer6 'SelectTable6.jsp' @{csrf6=$token6; chkTables=$tableA6; btnContinue='1'}
    Assert6 ($page6.Html.Contains('Tổng sức chứa các bàn chưa đủ')) 'Insufficient capacity rejected'
    # Use encoded content with repeated keys to select two tables.
    $url6="$BaseUrl/view/SelectTable6.jsp"
    $encoded6="csrf6=$token6&chkTables=$tableA6&chkTables=$tableB6&btnContinue=1"
    $content6=New-Object System.Net.Http.StringContent($encoded6,[Text.Encoding]::UTF8,'application/x-www-form-urlencoded')
    $response6=$customer6.PostAsync($url6,$content6).GetAwaiter().GetResult()
    try { $page6=@{Status=[int]$response6.StatusCode; Html=$response6.Content.ReadAsStringAsync().GetAwaiter().GetResult(); Url=$response6.RequestMessage.RequestUri.AbsoluteUri} }
    finally { $response6.Dispose(); $content6.Dispose() }
    Assert6 ($page6.Url.EndsWith('/ConfirmReservation6.jsp')) 'Valid selection routes to confirmation'
    Buttons6 $page6 2; Fields6 $page6 4
    Assert6 ([regex]::Matches($page6.Html,'<output>').Count -eq 5) 'Confirmation has exactly five output rows'
    $fields6=@{csrf6=$token6; inName='HTTP6 Customer'; inPhone='0901234567'; inEmail='bad-email'; inNote='Gần cửa sổ'; btnConfirm='1'}
    $page6=Request6 $customer6 'ConfirmReservation6.jsp' $fields6
    Assert6 ($page6.Html.Contains('Email không hợp lệ.')) 'Invalid email rejected by JSP'
    if ($WriteData) {
        $fields6.inEmail='customer@example.com'
        $page6=Request6 $customer6 'ConfirmReservation6.jsp' $fields6
        Assert6 ($page6.Url.EndsWith('/CustomerHome6.jsp') -and $page6.Html.Contains('Đặt bàn thành công')) 'Reservation saved successfully'
        $page6=Request6 $customer6 'ConfirmReservation6.jsp' $fields6
        Assert6 ($page6.Url.EndsWith('/SearchTable6.jsp')) 'Duplicate confirmation cannot create another reservation'
        $page6=Request6 $customer6 'SearchTable6.jsp' @{csrf6=$token6; inDate=$date6; inStartTime='19:10'; inEndTime='21:05'; inGuestNumber='5'; btnSearch='1'}
        Assert6 (!$page6.Html.Contains('name="chkTables" value="'+$tableA6+'"') -and !$page6.Html.Contains('name="chkTables" value="'+$tableB6+'"')) 'Reserved tables disappear from same time slot'
        Write-Host "Created reservation contactName=HTTP6 Customer, date=$date6"
    }
    foreach ($role6 in @(@{Client=$manager6; Home='ManagerHome6.jsp'}, @{Client=$customer6; Home='CustomerHome6.jsp'})) {
        $page6=Request6 $role6.Client $role6.Home
        $logoutToken6=Token6 $page6
        Assert6 ((Request6 $role6.Client $role6.Home @{btnLogout='1'}).Status -eq 403) 'Logout rejects missing CSRF'
        $page6=Request6 $role6.Client $role6.Home @{csrf6=$logoutToken6; btnLogout='1'}
        Assert6 ($page6.Url.EndsWith('/Login6.jsp')) 'Logout returns to login'
        Assert6 ((Request6 $role6.Client $role6.Home).Url.EndsWith('/Login6.jsp')) 'Logout invalidates authenticated session'
    }
    Write-Host 'HTTP verification passed.'
} finally { $manager6.Dispose(); $customer6.Dispose(); $anonymous6.Dispose() }

