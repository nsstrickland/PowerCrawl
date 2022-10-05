<#
# File: dataStore.ps1
# Created: Monday September 19th 2022
# Author: Nick Strickland
# -----
# Last Modified: Wednesday, 21st September 2022 12:05:52 am
# ----
# Copright 2022 Nick Strickland, nsstrickland@outlook.com>>
# GNU General Public License v3.0 only - https://www.gnu.org/licenses/gpl-3.0-standalone.html
#>

# Probably multiple CSVs per major class
# 
$customerOrders = [System.Data.DataSet]::new("CustomerOrders")
$ordersTable = $customerOrders.Tables.Add("Orders")
$pkid=$ordersTable.Columns.Add("OrderID",[int32])
$ordersTable.Columns.Add("OrderQuantity",[int32])
$ordersTable.Columns.Add("CompanyName",[string])
$ordersTable.PrimaryKey=


$dt = New-Object System.Data.Datatable
[void]$dt.Columns.Add("First")
[void]$dt.Columns.Add("Second")
[void]$dt.Columns.Add("Third")
[void]$dt.Columns.Add("Fourth")

# Add a row manually
[void]$dt.Rows.Add("1","2","3","4")

# Or add an array
$me = "computername","userdomain","username"
$array = (Get-Childitem env: | Where-Object { $me -contains $_.Name }).Value
[void]$dt.Rows.Add($array)

# Continuing from above
$dt.TableName = "Me"
$ds = New-Object System.Data.DataSet
$ds.Tables.Add($dt)

$dt2 = New-Object System.Data.Datatable "AnotherTable"
[void]$dt2.Columns.Add("MyColumn")
[void]$dt2.Rows.Add("MyRow")
$ds.Tables.Add($dt2)

$ds.tables["Me"]
$ds.tables["AnotherTable"]

$ds