<#PSScriptInfo
.VERSION 1.0.2
.AUTHOR Roman Kuzmin
.COPYRIGHT (c) Roman Kuzmin
.TAGS Invoke-Build, Graphviz
.GUID 43d94ab6-d0c5-4c6a-839d-2ace0449bf56
.LICENSEURI http://www.apache.org/licenses/LICENSE-2.0
.PROJECTURI https://github.com/nightroman/Invoke-Build
#>

<#
.Synopsis
	Shows Invoke-Build task graph using Graphviz Viz.js or dot.
	Copyright (c) Roman Kuzmin

.Description
	Requirements:
	- Invoke-Build command is available for calls
	- Internet connection for using online viz-standalone.js
	- or viz-standalone.js in the path, https://github.com/mdaines/viz.js
	- or, when -Dot, dot in $env:Graphviz or in the path, http://graphviz.org

	The script calls Invoke-Build to get the build tasks, makes the DOT graph,
	and uses either Viz.js or dot in order to convert the graph for show.

	Tasks without code are shown as ovals, conditional tasks as diamonds, other
	tasks as boxes. Safe references are shown as dotted edges, regular calls as
	solid edges. Job numbers are not shown by default.

	EXAMPLES

	# Make and show HTML using viz-standalone.js (local or online)
	Show-BuildGraph

	# Make and show SVG using dot
	Show-BuildGraph -Dot

	# Make Build.png with job numbers and top to bottom edges
	Show-BuildGraph -Dot -Number -NoShow -Code "" -Output Build.png

.Parameter File
		See: help Invoke-Build -Parameter File

.Parameter Output
		The custom output file path. The default is in the temp directory.
		When -Dot, the format is inferred from extension, SVG by default,
		otherwise the file extension should be htm or html.

.Parameter Code
		Custom DOT code added to the graph definition, see Graphviz manuals.
		The default 'graph [rankdir=LR]' tells to make left to right edges.

.Parameter Parameters
		Build script parameters needed in special cases when they alter tasks.

.Parameter Dot
		Tells to use Graphviz dot. By default it creates a SVG file.
		For different formats use Output with the format extension.

.Parameter NoShow
		Tells to create the output file without showing it.
		Use Output in order to specify the file exactly.

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
	[string]$Code = 'graph [rankdir=LR]'
	,
	[hashtable]$Parameters
	,
	[switch]$Dot
	,
	[switch]$NoShow
	,
	[switch]$Number
)

$ErrorActionPreference = 1

### resolve dot or js
if ($Dot) {
	$app = if ($env:Graphviz) {"$env:Graphviz/dot"} else {'dot'}
	$app = Get-Command $app -CommandType Application -ErrorAction 0
	if (!$app) {
		Write-Error 'Cannot resolve dot.exe'
	}
}
else {
	$app = Get-Command viz-standalone.js -CommandType Application -ErrorAction 0
	if ($app) {
		$jsUrl = 'file:///' + $app.Source.Replace('\', '/')
	}
	else {
		$jsUrl = 'https://github.com/mdaines/viz-js/releases/download/release-viz-3.2.4/viz-standalone.js'
	}
}

### resolve output
if ($Output) {
	if (!($type = [System.IO.Path]::GetExtension($Output))) {
		Write-Error 'Output file name must have an extension.'
	}
	$Output = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Output)
	$type = $type.Substring(1).ToLower()
}
else {
	$path = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($(if ($File) {$File} else {''}))
	$name = [System.IO.Path]::GetFileNameWithoutExtension($path)
	$hash = [System.IO.Path]::GetFileName([System.IO.Path]::GetDirectoryName($path))
	if ($Dot) {
		$Output = [System.IO.Path]::GetTempPath() + "$name-$hash.svg"
		$type = 'svg'
	}
	else {
		$Output = [System.IO.Path]::GetTempPath() + "$name-$hash.html"
		$type = 'html'
	}
}

### get tasks
if (!$Parameters) {$Parameters = @{}}
$all = Invoke-Build ?? $File @Parameters

### for synopses
$docs = @{}
. Invoke-Build

### make dot-code

function escape_text($text) {
	$text.Replace('\', '\\').Replace('"', '\"')
}

$text = @(
	### begin
	'digraph {'
	$Code

	### nodes
	$id = 0
	$map = @{}
	foreach($it in $all.get_Values()) {
		++$id
		$name = $it.Name
		$map[$name] = $id
		$attr = 'label="{0}"' -f (escape_text $name)

		$tooltip = if ($synopsis = Get-BuildSynopsis $it $docs) {$synopsis} else {$name}
		$attr += ' tooltip="{0}"' -f (escape_text $tooltip)

		$hasScript = foreach($job in $it.Jobs) {if ($job -is [scriptblock]) {$true}}
		if ($hasScript) {
			if ((-9).Equals($it.If)) {
				$attr += ' shape=box'
			}
			else {
				$attr += ' shape=note'
			}
		}

		'{0} [{1}]' -f $id, $attr
	}

	### edges
	$id = 0
	foreach($it in $all.get_Values()) {
		++$id
		$jobNumber = 0
		foreach($job in $it.Jobs) {
			++$jobNumber
			if ($job -is [string]) {
				$job, $safe = if ($job[0] -eq '?') {$job.Substring(1), 1} else {$job}
				$job = $all[$job].Name
				$id2 = $map[$job]
				$tooltip = escape_text "$($it.Name) -> $job"
				$attr = 'edgetooltip="{0}"' -f $tooltip
				if ($Number) {
					$attr += ' label="{0}" labeltooltip="{1}"' -f $jobNumber, $tooltip
				}
				if ($safe) {
					$attr += ' style=dotted'
				}
				'{0} -> {1} [{2}]' -f $id, $id2, $attr
			}
		}
	}

	### end
	'}'
)

### write output
if ($Dot) {
	$temp = "$([System.IO.Path]::GetTempPath())/Graphviz.dot"
	[System.IO.File]::WriteAllLines($temp, $text)

	& $app "-T$type" -o $Output $temp
	if ($Global:LASTEXITCODE) {
		return
	}
}
else {
	$text = $text | .{process{$_.Replace('\', '\\').Replace('"', '\"') + '\'}} | Out-String -Width 9999
	@"
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>$([System.IO.Path]::GetFileNameWithoutExtension($Output)) tasks</title>
</head>
<body>
<script src="$jsUrl"></script>
<script>
Viz.instance().then(function(viz) {document.body.appendChild(viz.renderSVGElement("$text"))})
</script>
</body>
</html>
"@ | Set-Content -LiteralPath $Output -Encoding UTF8
}

### show file
if (!$NoShow) {
	Invoke-Item -LiteralPath $Output
}
