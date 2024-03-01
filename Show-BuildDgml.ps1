<#
.Synopsis
	Shows Invoke-Build task graph using DGML.
	Copyright (c) Roman Kuzmin

.Description
	Requires:
	- Visual Studio: Individual components \ Code tools \ DGML editor.
	- Invoke-Build is in the path or available as the module command.

	The script calls Invoke-Build in order to get the tasks, builds the DGML
	and invokes the associated application (Visual Studio) in order to show it.

	Tasks with code are shown as boxes, tasks without code are shown as ovals.
	Safe references are shown with dotted edges, regular calls are shown with
	solid edges. Job numbers are not shown by default.

	EXAMPLES

	# Make and show DGML for the default build script
	Show-BuildDgml

	# Make Build.dgml with job numbers
	Show-BuildDgml -Number -NoShow -Output Build.dgml

.Parameter File
		See: help Invoke-Build -Parameter File
.Parameter Output
		The output file and the format specified by its extension.
		The default is "$env:TEMP\name-xxxxxxxx.dgml".
.Parameter Parameters
		Build script parameters needed in special cases when they alter tasks.
.Parameter NoShow
		Tells to create the output file without showing it.
		In this case Output is normally specified by a caller.
.Parameter Number
		Tells to show job numbers on edges connecting tasks.

.Link
	https://github.com/nightroman/Invoke-Build
#>

param(
	[Parameter(Position=0)]
	[string]$File
	,
	[Parameter(Position=1)]
	[string]$Output
	,
	[hashtable]$Parameters
	,
	[switch]$NoShow
	,
	[switch]$Number
)

$ErrorActionPreference = 1

### resolve output
if ($Output) {
	$Output = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Output)
}
else {
	$path = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($(if ($File) {$File} else {''}))
	$name = [System.IO.Path]::GetFileNameWithoutExtension($path)
	$hash = [System.IO.Path]::GetFileName([System.IO.Path]::GetDirectoryName($path))
	$Output = [System.IO.Path]::GetTempPath() + "$name-$hash.dgml"
}

### get tasks
if (!$Parameters) {$Parameters = @{}}
$all = Invoke-Build ?? $File @Parameters

### for synopses
$docs = @{}
. Invoke-Build

### make DGML
$xml = [xml]'<?xml version="1.0" encoding="utf-8"?><DirectedGraph/>'
$doc = $xml.DocumentElement
$nodes = $doc.AppendChild($xml.CreateElement('Nodes'))
$links = $doc.AppendChild($xml.CreateElement('Links'))
$styles = $doc.AppendChild($xml.CreateElement('Styles'))
$styles.InnerXml = @'
<Style TargetType="Node">
  <Condition Expression="HasCategory('Calls')" />
  <Setter Property="NodeRadius" Value="15" />
</Style>
<Style TargetType="Node">
  <Condition Expression="HasCategory('Script')" />
  <Setter Property="NodeRadius" Value="2" />
</Style>
'@
foreach($it in $all.get_Values()) {
	$name = $it.Name
	$node = $nodes.AppendChild($xml.CreateElement('Node'))
	$node.SetAttribute('Id', $name)

	if ($synopsis = Get-BuildSynopsis $it $docs) {
		$node.SetAttribute('Synopsis', $synopsis)
	}

	$jobNumber = 0
	$hasScript = $false
	foreach($job in $it.Jobs) {
		++$jobNumber
		if ($job -is [string]) {
			$job, $safe = if ($job[0] -eq '?') {$job.Substring(1), 1} else {$job}
			$job = $all[$job].Name
			$link = $links.AppendChild($xml.CreateElement('Link'))
			$link.SetAttribute('Source', $name)
			$link.SetAttribute('Target', $job)
			if ($Number) {
				$link.SetAttribute('Label', $jobNumber)
			}
			if ($safe) {
				$link.SetAttribute('StrokeDashArray', '2 2')
			}
		}
		else {
			$hasScript = $true
		}
	}

	if ($hasScript) {
		$node.SetAttribute('Category', 'Script')
	}
	else {
		$node.SetAttribute('Category', 'Calls')
	}
}

### save DGML
$doc.SetAttribute('xmlns', 'http://schemas.microsoft.com/vs/2009/dgml')
$xml.Save($Output)

### show file
if (!$NoShow) {
	Invoke-Item -LiteralPath $Output
}
