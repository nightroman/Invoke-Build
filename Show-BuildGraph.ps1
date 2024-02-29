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

	# Make and show PDF using dot
	Show-BuildGraph -Dot

	# Make Build.png with job numbers and top to bottom edges
	Show-BuildGraph -Dot -Number -NoShow -Code "" -Output Build.png

.Parameter File
		See: help Invoke-Build -Parameter File

.Parameter Output
		The custom output file path. The default is in the temp directory.
		When -Dot, the format is inferred from extension, PDF by default.
		Otherwise the file extension should be .html.

.Parameter Code
		Custom DOT code added to the graph definition, see Graphviz manuals.
		The default 'graph [rankdir=LR]' tells edges to go from left to right.

.Parameter Parameters
		Build script parameters needed in special cases when they alter tasks.

.Parameter Dot
		Tells to use Graphviz dot. By default it creates a PDF file.
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
		$jsUrl = "https://github.com/mdaines/viz-js/releases/download/release-viz-3.2.4/viz-standalone.js"
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
		$Output = "$([System.IO.Path]::GetTempPath())/$name-$hash.pdf"
		$type = 'pdf'
	}
	else {
		$Output = "$([System.IO.Path]::GetTempPath())/$name-$hash.html"
		$type = 'html'
	}
}

### get tasks
if (!$Parameters) {$Parameters = @{}}
$all = Invoke-Build ?? $File @Parameters

### make dot-code
$text = @(
	'digraph Tasks {'
	$Code
	foreach($it in $all.get_Values()) {
		$name = $it.Name
		'"{0}"' -f $name

		$jobNumber = 0
		$hasScript = $false
		foreach($job in $it.Jobs) {
			++$jobNumber
			if ($job -is [string]) {
				$job, $safe = if ($job[0] -eq '?') {$job.Substring(1), 1} else {$job}
				$job = $all[$job].Name
				$edge = ' '
				if ($Number) {
					$edge += "label=$jobNumber "
				}
				if ($safe) {
					$edge += "style=dotted "
				}
				'"{0}" -> "{1}" [{2}]' -f $name, $job, $edge
			}
			else {
				$hasScript = $true
			}
		}

		if ($hasScript) {
			if ((-9).Equals($it.If)) {
				$node = 'shape=box'
			}
			else {
				$node = 'shape=diamond'
			}
			'"{0}" [ {1} ]' -f $name, $node
		}
	}
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
	$text = $text | .{process{$_.Replace('"', '\"') + '\'}} | Out-String -Width 9999
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
Viz.instance().then(function(viz) {document.body.appendChild(viz.renderSVGElement("$text"));});
</script>
</body>
</html>
"@ | Set-Content -LiteralPath $Output -Encoding UTF8
}

### show file
if ($NoShow) {
	return
}
Invoke-Item $Output
