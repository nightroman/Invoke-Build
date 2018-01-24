
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
		Tells to show task job numbers. Jobs are tasks (numbers are shown on
		edges) and own scripts (numbers are shown in task boxes after names).

.Link
	https://github.com/nightroman/Invoke-Build
#>

param(
	[Parameter(Position=0)]
	[string]$File,
	[Parameter(Position=1)]
	[string]$Output,
	[hashtable]$Parameters,
	[switch]$NoShow,
	[switch]$Number
)

trap {$PSCmdlet.ThrowTerminatingError($_)}
$ErrorActionPreference = 'Stop'

# output
if (!$Output) {
	$path = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($(if ($File) {$File} else {''}))
	$name = [System.IO.Path]::GetFileNameWithoutExtension($path)
	$hash = '{0:x8}' -f ($path.ToUpper().GetHashCode())
	$Output = "$env:TEMP\$name-$hash.dgml"
}

# get tasks
if (!$Parameters) {$Parameters = @{}}
$all = Invoke-Build ?? $File @Parameters

# synopses
$docs = @{}
. Invoke-Build

# make DGML
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
foreach($it in $all.Values) {
	$name = $it.Name
	$node = $nodes.AppendChild($xml.CreateElement('Node'))
	$node.SetAttribute('Id', $name)

	if ($synopsis = Get-BuildSynopsis $it $docs) {
		$node.SetAttribute('Synopsis', $synopsis)
	}

	$num = 0
	$script = ''
	foreach($job in $it.Jobs) {
		++$num
		if ($job -is [string]) {
			$job, $safe = if ($job[0] -eq '?') {$job.Substring(1), 1} else {$job}
			$link = $links.AppendChild($xml.CreateElement('Link'))
			$link.SetAttribute('Source', $name)
			$link.SetAttribute('Target', $job)
			if ($Number) {
				$link.SetAttribute('Label', $num)
			}
			if ($safe) {
				$link.SetAttribute('StrokeDashArray', '2 2')
			}
		}
		else {
			$script += "{$num}"
		}
	}

	if ($script) {
		$node.SetAttribute('Category', 'Script')
		if ($Number) {
			$node.SetAttribute('Label', "$name $script")
		}
	}
	else {
		$node.SetAttribute('Category', 'Calls')
	}
}

# save DGML
$doc.SetAttribute('xmlns', 'http://schemas.microsoft.com/vs/2009/dgml')
$xml.Save($Output)

# show
if ($NoShow) {return}
Invoke-Item $Output
