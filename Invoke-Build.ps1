
<#
Invoke-Build - PowerShell Task Scripting
Copyright (c) 2011-2012 Roman Kuzmin

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

#.ExternalHelp Invoke-Build.ps1-Help.xml
param(
	[Parameter(Position=0)][string[]]$Task,
	[Parameter(Position=1)][string]$File,
	[Parameter(Position=2)][hashtable]$Parameters,
	[string]$Checkpoint,
	[hashtable]$Hook,
	$Result,
	[switch]$Safe,
	[switch]$WhatIf
)

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildVersion {[System.Version]'1.5.2'}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Add-BuildTask {
	[CmdletBinding(DefaultParameterSetName='.')]
	param(
		[Parameter(Position=0, Mandatory=1)][string]$Name,
		[Parameter(Position=1)][object[]]$Jobs,
		$If=1,
		[object[]]$After,
		[object[]]$Before,
		[Parameter(ParameterSetName='Incremental')][hashtable]$Incremental,
		[Parameter(ParameterSetName='Partial')][hashtable]$Partial
	)
	try{
		if($t=$BuildList[$Name]){throw *EI 'Task already exists:' $t}

		$t=1 | Select-Object Name, Error, Started, Elapsed, Jobs, Try, If, Inputs, Outputs, Partial, After, Before, InvocationInfo
		$t.Name=$Name
		$t.Jobs=$1=[System.Collections.ArrayList]@()
		$t.Try=$2=[System.Collections.ArrayList]@()
		$t.If=$If
		$t.After=$After
		$t.Before=$Before
		$t.InvocationInfo=$MyInvocation
		$BuildList.Add($Name, $t)

		switch($PSCmdlet.ParameterSetName){
			Incremental {$t.Inputs, $t.Outputs=*KV $Incremental}
			Partial {$t.Partial=1; $t.Inputs, $t.Outputs=*KV $Partial}
		}

		if($Jobs){foreach($_ in $Jobs){
			$r, $d=*RD $_
			$null=$1.Add($r)
			if(1 -eq $d){$null=$2.Add($r)}
			elseif(!($_ -is [string] -or $_ -is [scriptblock])){throw "Invalid job type."}
		}}
	}catch{*Die "Task '$Name': $_" InvalidArgument}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Assert-BuildTrue([Parameter()]$Condition, [string]$Message)
{if(!$Condition){*Die $(if($Message){"Assertion failed: $Message"}else{'Assertion failed.'}) InvalidOperation}}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildError([Parameter(Mandatory=1)][string]$Task)
{if(!($_=$BuildList[$Task])){*Die "Missing task '$Task'." ObjectNotFound} $_.Error}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildFile($Path){
	$f=[System.IO.Directory]::GetFiles($Path, '*.build.ps1')
	if($f.Count -eq 1){$f}else{foreach($_ in $f){if([System.IO.Path]::GetFileName($_) -eq '.build.ps1'){return $_}}}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildProperty([Parameter(Mandatory=1)][string]$Name, $Value){
	if($null -ne ($_=$PSCmdlet.GetVariableValue($Name)) -or $null -ne ($_=[System.Environment]::GetEnvironmentVariable($Name)) -or $null -ne ($_=$Value)){$_}
	else{*Die "Missing variable '$Name'." ObjectNotFound}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Invoke-BuildExec([Parameter(Mandatory=1)][scriptblock]$Command, [int[]]$ExitCode=0){
	${private:-c}, ${private:-x}=$Command, $ExitCode; Remove-Variable Command, ExitCode
	. ${-c}
	if(${-x} -notcontains $LastExitCode){*Die "Command {${-c}} exited with code $LastExitCode." InvalidResult}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Use-BuildAlias([string]$Path, [Parameter(Mandatory=1)][string[]]$Name){
	if($Path){
		try{
			$d=if($Path -like 'Framework*'){"$env:windir\Microsoft.NET\$Path"}else{$PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)}
			if(![System.IO.Directory]::Exists($d)){throw "Missing directory '$d'."}
		}catch{*Die $_ InvalidArgument}
	}else{
		$d=[System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
	}
	foreach($_ in $Name){Set-Alias $_ (Join-Path $d $_) -Scope 1}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Write-BuildText([System.ConsoleColor]$Color, [string]$Text)
{$_=$Host.UI.RawUI.ForegroundColor; try{$Host.UI.RawUI.ForegroundColor=$Color; $Text}finally{$Host.UI.RawUI.ForegroundColor=$_}}

if($MyInvocation.InvocationName -eq '.'){
	"Invoke-Build.ps1 Version $(Get-BuildVersion)`r`nCopyright (c) 2011-2012 Roman Kuzmin"
	'Add-BuildTask','Use-BuildAlias','Invoke-BuildExec','Assert-BuildTrue','Get-BuildProperty','Get-BuildError','Get-BuildVersion','Write-BuildText' |
	.{process{Get-Help $_}} | Format-Table Name, Synopsis -AutoSize | Out-String
	return
}

if($Host.Name -eq 'Default Host' -or $Host.Name -eq 'ServerRemoteHost' -or !$Host.UI -or !$Host.UI.RawUI)
{function Write-BuildText([System.ConsoleColor]$Color, [string]$Text){$Text}}

function Write-Warning($Message){
	$PSCmdlet.WriteWarning($Message)
	$_="WARNING: $Message"
	++$BuildInfo.WarningCount
	++$BuildInfo.AllWarningCount
	$null=$BuildInfo.Messages.Add($_), $BuildInfo.AllMessages.Add($_)
}

function **
{if(!$WhatIf){Set-Location -LiteralPath $BuildRoot -ErrorAction Stop; . $args[0] $args[1] $args[2]}}

function *II($_)
{if(($_=$_.InvocationInfo.PositionMessage)[0] -eq "`n"){$_.Trim().Replace("`n", "`r`n")}else{$_}}

function *EI($E, $I)
{"$E`r`n$(*II $I)"}

function *My
{$_.InvocationInfo.ScriptName -like '*\Invoke-Build.ps1'}

function *KV($_)
{if($_.Count -ne 1){throw "Expected hashtable @{X=Y}."} $_.Keys; $_.Values}

function *RD($_)
{if($_ -is [hashtable]){*KV $_}else{$_}}

function *Die([string]$Message, [System.Management.Automation.ErrorCategory]$Category=0)
{$PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([System.Exception]$Message), $null, $Category, $null))}

function *Heal($N, $F){
	if(($t=$BuildList[$N]).If){foreach($_ in $t.Jobs){if($_ -is [string]){
		if($_ -eq $F){if($t.Try -notcontains $_){return "Task '$F' is not protected in '$N'."}}
		elseif($w=*Heal $_ $F){return $w}
	}}}
}

function *IO {
	${private:-t}=$args[0]

	if((${private:-i}=${-t}.Inputs) -is [scriptblock]){${-i}=@(** ${-i})}
	Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
	${private:-p}=[System.Collections.ArrayList]@()
	${-i}=foreach(${private:-} in ${-i}){
		if(${-} -isnot [System.IO.FileInfo]){
			if(!(${-}=[System.IO.FileInfo]$PSCmdlet.GetUnresolvedProviderPathFromPSPath(${-})).Exists){throw "Missing input file '${-}'."}
		}
		$null=${-p}.Add(${-}.FullName)
		${-}
	}
	if(!${-p}){return 'Skipping because there is no input.'}

	if(${-t}.Partial){
		${private:-o}=@(if(${-t}.Outputs -is [scriptblock]){
			Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
			${-p} | & ${-t}.Outputs
		}else{
			${-t}.Outputs
		})
		if(${-p}.Count -ne ${-o}.Count){throw "Different input and output counts: $(${-p}.Count) and $(${-o}.Count)."}

		$1=-1
		$i2=[System.Collections.ArrayList]@()
		$o2=[System.Collections.ArrayList]@()
		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		foreach($_ in ${-i}){
			++$1
			$path=${-o}[$1]
			if(!($file=[System.IO.FileInfo]$PSCmdlet.GetUnresolvedProviderPathFromPSPath($path)).Exists -or $_.LastWriteTime -gt $file.LastWriteTime){
				$null=$i2.Add(${-p}[$1]), $o2.Add($path)
			}
		}
		if($i2){${-t}.Inputs=$i2; ${-t}.Outputs=$o2; return}
	}else{
		${-t}.Inputs=${-p}
		if(${-t}.Outputs -is [scriptblock]){if(!(${-t}.Outputs=** ${-t}.Outputs)){throw 'Incremental output cannot be empty.'}}

		$m=(${-i} | .{process{$_.LastWriteTime.Ticks}} | Measure-Object -Maximum).Maximum
		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		foreach($_ in ${-t}.Outputs){
			if(!($_=[System.IO.FileInfo]$PSCmdlet.GetUnresolvedProviderPathFromPSPath($_)).Exists -or $_.LastWriteTime.Ticks -lt $m){return}
		}
	}
	'Skipping because all outputs are up-to-date with respect to the inputs.'
}

function *Task {
	${private:-t}=$BuildList[$args[0]]
	${private:-p}=$args[1]
	${-p}=if(${-p}){"${-p}/$(${-t}.Name)"}else{${-t}.Name}
	if(${-t}.Error){Write-BuildText 8 "${-p} failed."; return}
	if(${-t}.Elapsed){Write-BuildText 8 "Done ${-p}"; return}

	if((${private:-}=${-t}.If) -is [scriptblock]){try{${-}=** ${-}}catch{${-t}.Error=$_; throw}}
	if(!${-}){Write-BuildText 8 "${-p} skipped."; return}

	${-t}.Started=[System.DateTime]::Now
	${private:-n}=${private:-io}=0
	try{
		. ** Enter-BuildTask ${-t}
		foreach(${private:-j} in ${-t}.Jobs){
			++${-n}
			if(${-j} -is [string]){
				try{
					*Task ${-j} ${-p}
				}catch{
					if(${-t}.Try -notcontains ${-j}){throw}
					foreach(${-} in $BuildTask){if(${-}=*Heal ${-} ${-j}){Write-BuildText 12 ${-}; throw}}
					Write-BuildText 12 (*EI "ERROR: $_" $_)
				}
			}else{
				${private:-m}="${-p} (${-n}/$(${-t}.Jobs.Count))"; Write-BuildText 6 "${-m}:"
				if($WhatIf){${-j}; continue}

				if($null -ne ${-t}.Inputs -and ${-io} -eq 0){${-io}=*IO ${-t}}
				if(${-io}){Write-BuildText 6 ${-io}; continue}

				try{
					. ** Enter-BuildJob ${-t} ${-n}
					Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
					if(${-t}.Inputs){
						$Inputs=${-t}.Inputs
						$Outputs=${-t}.Outputs
						if(${-t}.Partial){
							${-}=0
							$Inputs | .{process{
								$2=$Outputs[${-}]
								++${-}
								$_
							}} | & ${-j}
						}else{
							$Inputs | & ${-j}
						}
					}else{
						& ${-j}
					}
				}catch{${-t}.Error=$_; throw}
				finally{. ** Exit-BuildJob ${-t} ${-n}}
				if(${-t}.Jobs.Count -ge 2){Write-BuildText 6 "Done ${-m}"}
			}
		}

		$_=[System.DateTime]::Now - ${-t}.Started
		${-t}.Elapsed=$_
		Write-BuildText 6 "Done ${-p} $_"

		if($BuildInfo.Checkpoint){
			$(,$BuildTask; $BuildFile; $BuildInfo.Parameters; ,@(foreach($_ in $BuildList.Values){if($_.Elapsed){$_.Name}}); ** Export-Build)|
			Export-Clixml $BuildInfo.Checkpoint
		}
	}catch{
		${-t}.Elapsed=[System.DateTime]::Now - ${-t}.Started
		${-t}.Error=$_
		++$BuildInfo.ErrorCount
		++$BuildInfo.AllErrorCount
		$_=if(*My){"ERROR: Task '${-p}': $_"}else{*EI "ERROR: Task '${-p}': $_" $_}
		$null=$BuildInfo.Messages.Add($_), $BuildInfo.AllMessages.Add($_)
		Write-BuildText 14 (*II ${-t})
		throw
	}finally{
		$null=$BuildInfo.Tasks.Add(${-t}), $BuildInfo.AllTasks.Add(${-t})
		. ** Exit-BuildTask ${-t}
	}
}

filter *AB($N, $A){
	$r, $d=*RD $_
	if(!($t=$BuildList[$r])){throw "Missing task '$r'."}

	$j=$t.Jobs
	$c=$j.Count
	if($A){for($1=$c - 1; $1 -ge 0; --$1){if($j[$1] -is [scriptblock]){$c=$1 + 1; break}}}
	else{for($1=0; $1 -lt $c; ++$1){if($j[$1] -is [scriptblock]){$c=$1; break}}}

	$j.Insert($c, $N)
	if(1 -eq $d){$null=$t.Try.Add($N)}
}

function *TryTree($T, $L){
	$n=1 + $L.Add($T)
	foreach($_ in $T.Jobs){if($_ -is [string]){
		if(!($b=$BuildList[$_])){throw *EI "Task '$($T.Name)': Missing task '$_'." $T}
		if($L.Contains($b)){throw *EI "Task '$($T.Name)': Cyclic reference to '$_'." $T}
		*TryTree $b $L
		$L.RemoveRange($n, $L.Count - $n)
	}}
}

filter *TryTask
{if(!($t=$BuildList[$_])){throw "Missing task '$_'."} *TryTree $t ([System.Collections.ArrayList]@())}

function *Show($R, $T, $E, $W, $S){
	$c, $m=if($R -eq 2){12, 'Build FAILED'}
	elseif($E){12, 'Build completed with errors'}
	elseif($W){14, 'Build succeeded with warnings'}
	else{10, 'Build succeeded'}
	Write-BuildText $c "$m. $T tasks, $E errors, $W warnings, $S"
}

function Enter-BuildScript {}
function Exit-BuildScript {}
function Enter-BuildTask {}
function Exit-BuildTask {}
function Enter-BuildJob {}
function Exit-BuildJob {}
function Export-Build {}
function Import-Build {}

$ErrorActionPreference='Stop'
${private:-dir}=$PSCmdlet.GetUnresolvedProviderPathFromPSPath('')
${private:-load}=$null

try{
	if($Checkpoint){$Checkpoint=$PSCmdlet.GetUnresolvedProviderPathFromPSPath($Checkpoint)}
	if($Checkpoint -and !($Task -or $File -or $Parameters)){
		$_=Import-Clixml $Checkpoint
		$Task, $BuildFile, $Parameters, ${-load}, ${private:-data}=$_
	}elseif($File){
		if(!([System.IO.File]::Exists(($BuildFile=$PSCmdlet.GetUnresolvedProviderPathFromPSPath($File))))){throw "Missing script '$BuildFile'."}
	}else{
		if(!($BuildFile=Get-BuildFile ${-dir})){
			if($Hook){if($_=$Hook['GetFile']){$BuildFile=& $_}}
			if(!$BuildFile){throw "Missing default script."}
		}
	}
	$BuildRoot=Split-Path $BuildFile
}catch{*Die "$_" ObjectNotFound}

if(${private:-b}=$PSCmdlet.SessionState.PSVariable.Get('BuildInfo')){${-b}=if(${-b}.Description -eq 'Invoke-Build'){${-b}.Value}}

Set-Alias assert Assert-BuildTrue
Set-Alias error Get-BuildError
Set-Alias exec Invoke-BuildExec
Set-Alias property Get-BuildProperty
Set-Alias task Add-BuildTask
Set-Alias use Use-BuildAlias
Set-Alias Invoke-Build $MyInvocation.MyCommand.Path
Set-Alias Invoke-Builds (Join-Path (Split-Path $MyInvocation.MyCommand.Path) 'Invoke-Builds.ps1')
New-Variable -Name BuildList -Option Constant -Value ([System.Collections.Specialized.OrderedDictionary]([System.StringComparer]::OrdinalIgnoreCase))
New-Variable -Name BuildInfo -Option Constant -Description Invoke-Build -Value (1 | Select-Object `
AllTasks, AllMessages, AllErrorCount, AllWarningCount, Tasks, Messages, ErrorCount, WarningCount, Started, Elapsed, Error, Parameters, Checkpoint)
$BuildInfo.AllErrorCount=$BuildInfo.AllWarningCount=$BuildInfo.ErrorCount=$BuildInfo.WarningCount=0
$BuildInfo.AllTasks=[System.Collections.ArrayList]@()
$BuildInfo.AllMessages=[System.Collections.ArrayList]@()
$BuildInfo.Tasks=[System.Collections.ArrayList]@()
$BuildInfo.Messages=[System.Collections.ArrayList]@()
$BuildInfo.Started=[System.DateTime]::Now
$BuildInfo.Parameters=$Parameters
$BuildInfo.Checkpoint=$Checkpoint
if('?' -eq $Task){$WhatIf=$true}
if($Result){
	$_=if('?' -eq $Task){$BuildList}else{$BuildInfo}
	if($Result -is [string]){New-Variable -Force -Scope 1 $Result $_}
	else{$Result.Value=$_}
}
$BuildTask=$Task
${private:-Result}=$Result
${private:-Safe}=$Safe
Remove-Variable Task, File, Parameters, Hook, Checkpoint, Result, Safe

${private:-r}=0
try{
	Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
	Write-BuildText 6 "Build $($BuildTask -join ', ') $BuildFile"
	$_=if($_=$BuildInfo.Parameters){. $BuildFile @_}else{. $BuildFile}
	if(!$BuildList.Count){throw "There is no task in '$BuildFile'."}
	$_
	foreach($_ in $_){if($_ -is [scriptblock]){throw "Unexpected script block {$_}"}}

	foreach(${private:-t} in $BuildList.Values){
		try{
			if(${-t}.Before){${-t}.Before | *AB ${-t}.Name}
			if(${-t}.After){${-t}.After | *AB ${-t}.Name 1}
		}catch{throw *EI "Task '$(${-t}.Name)': $_" ${-t}}
	}

	if('?' -eq $BuildTask){
		$BuildList.Keys | *TryTask
		if(!${-Result}){
			foreach($_ in $BuildList.Values){@"
$($_.Name) $(($_.Jobs | %{if($_ -is [string]){$_}else{'{..}'}}) -join ', ') $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber)
"@}
		}
		return
	}

	if('*' -eq $BuildTask){
		$BuildList.Keys | *TryTask
		$BuildTask=foreach($_ in $BuildList.Keys){
			foreach(${private:-t} in $BuildList.Values){
				if(${-t}.Jobs -contains $_){$_=$null; break}
			}
			if($_){$_}
		}
	}else{
		if(!$BuildTask -or '.' -eq $BuildTask){$BuildTask=if($BuildList.Contains('.')){'.'}else{$BuildList.Item(0).Name}}
		$BuildTask | *TryTask
	}

	try{
		. ** Enter-BuildScript
		if(${-load}){
			. ** Import-Build ${-data}
			foreach($_ in ${-load}){$BuildList[$_].Elapsed=[TimeSpan]::Zero}
		}
		foreach($_ in $BuildTask){
			*Task $_
		}
		if($BuildInfo.Checkpoint){[System.IO.File]::Delete($BuildInfo.Checkpoint)}
	}finally{. ** Exit-BuildScript}
	${-r}=1
}catch{
	${-r}=2
	$BuildInfo.Error=$_
	if(!${-Safe}){if(*My){$PSCmdlet.ThrowTerminatingError($_)}else{throw}}
}finally{
	Set-Location -LiteralPath ${-dir} -ErrorAction Stop
	if(${-r}){
		$BuildInfo.Elapsed=[System.DateTime]::Now - $BuildInfo.Started
		$BuildInfo.Messages
		*Show ${-r} $BuildInfo.Tasks.Count $BuildInfo.ErrorCount $BuildInfo.WarningCount $BuildInfo.Elapsed

		if(${-b}){
			${-b}.AllTasks.AddRange($BuildInfo.AllTasks)
			${-b}.AllMessages.AddRange($BuildInfo.AllMessages)
			${-b}.AllErrorCount += $BuildInfo.AllErrorCount
			${-b}.AllWarningCount += $BuildInfo.AllWarningCount
		}elseif($BuildInfo.AllTasks.Count -ne $BuildInfo.Tasks.Count){
			$BuildInfo.AllMessages
			*Show ${-r} $BuildInfo.AllTasks.Count $BuildInfo.AllErrorCount $BuildInfo.AllWarningCount $BuildInfo.Elapsed
		}
	}
}
