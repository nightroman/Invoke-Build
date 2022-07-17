<#
.Synopsis
	Shows Invoke-Build task graph using Graphviz.
	Copyright (c) Roman Kuzmin

.Description
	Requirements:
	- Invoke-Build is in the path or available as the module command.
	- Graphviz (http://graphviz.org) is used as the default engine.
	  Graphviz\bin is in the path or defined as $env:Graphviz.
	- viz.js is used as an alternative, see the parameter JS.

	The script calls Invoke-Build in order to get the tasks, writes DOT, and
	uses either dot.exe or viz.js in order to visualize it using one of the
	supported output formats and the associated application.

	Tasks without code are shown as ovals, conditional tasks as diamonds, other
	tasks as boxes. Safe references are shown as dotted edges, regular calls as
	solid edges. Job numbers are not shown by default.

	EXAMPLES

	# Make and show PDF graph using dot.exe
	Show-BuildGraph

	# Make and show HTML graph by viz.js
	Show-BuildGraph -JS *

	# Make Build.png with job numbers and top to bottom edges
	Show-BuildGraph -Number -NoShow -Code '' -Output Build.png

.Parameter File
		See: help Invoke-Build -Parameter File
.Parameter Output
		The output file and the format specified by its extension.
		The default is "$env:TEMP\name-xxxxxxxx.ext".
.Parameter JS
		Tells to use viz.js and generate an HTML file. If it is * then the
		online script is used. Otherwise, it specifies the path to the
		directory containing viz.js and lite.render.js.
		See https://github.com/mdaines/viz.js
.Parameter Code
		Custom DOT code added to the graph definition, see Graphviz manuals.
		The default 'graph [rankdir=LR]' tells edges to go from left to right.
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
	[string]$File,
	[Parameter(Position=1)]
	[string]$Output,
	[string]$JS,
	[string]$Code = 'graph [rankdir=LR]',
	[hashtable]$Parameters,
	[switch]$NoShow,
	[switch]$Number
)

trap {$PSCmdlet.ThrowTerminatingError($_)}
$ErrorActionPreference = 'Stop'

# resolve dot.exe or js
if ($JS) {
	$vizjs = @('viz.js', 'lite.render.js')
	if ($JS -eq '*') {
		$jsUrl = foreach($_ in $vizjs) {
			"https://cdnjs.cloudflare.com/ajax/libs/viz.js/2.1.2/$_"
		}
	}
	else {
		$JS = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($JS)
		$jsUrl = foreach($_ in $vizjs) {
			$_ = Join-Path $JS $_
			if (!(Test-Path -LiteralPath $_)) {throw "Cannot find '$_'."}
			'file:///' + $_.Replace('\', '/')
		}
	}
}
else {
	$dot = if ($env:Graphviz) {"$env:Graphviz\dot.exe"} else {'dot.exe'}
	$dot = Get-Command $dot -CommandType Application -ErrorAction 0
	if (!$dot) {throw 'Cannot resolve dot.exe'}
}

# output
if ($Output) {
	if (!($type = [System.IO.Path]::GetExtension($Output))) {throw 'Output must have an extension'}
	$Output = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Output)
	$type = $type.Substring(1).ToLower()
}
else {
	$path = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($(if ($File) {$File} else {''}))
	$name = [System.IO.Path]::GetFileNameWithoutExtension($path)
	$hash = $hash = [IO.Path]::GetFileName([IO.Path]::GetDirectoryName($path))
	if ($JS) {
		$Output = "$env:TEMP\$name-$hash.html"
		$type = 'html'
	}
	else {
		$Output = "$env:TEMP\$name-$hash.pdf"
		$type = 'pdf'
	}
}

# get tasks
if (!$Parameters) {$Parameters = @{}}
$all = Invoke-Build ?? $File @Parameters

# DOT code
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

if ($JS) {
	@"
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Build graph</title>
</head>
<body>
$($jsUrl | .{process{"<script src=`"$_`"></script>"}} | Out-String -Width ([int]::MaxValue))
<script>
var viz = new Viz();
viz.renderSVGElement("$(
	$text | .{process{$_.Replace('"', '\"') + '\'}} | Out-String -Width ([int]::MaxValue)
)")
.then(function(element) {
	document.body.appendChild(element);
})
.catch(error => {
	viz = new Viz();
	console.error(error);
});
</script>
</body>
</html>
"@ | Set-Content -LiteralPath $Output -Encoding UTF8
}
else {
	#! temp file UTF8 no BOM
	$temp = "$env:TEMP\Graphviz.dot"
	[System.IO.File]::WriteAllLines($temp, $text)

	# make
	& $dot "-T$type" -o $Output $temp
	if ($LastExitCode) {return}
}

# show
if ($NoShow) {return}
Invoke-Item $Output
