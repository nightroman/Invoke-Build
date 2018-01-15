
<#
.Synopsis
	Shows Invoke-Build task graph using Graphviz.
	Copyright (c) Roman Kuzmin

.Description
	Requires:
	- Graphviz: http://graphviz.org
	- Graphviz\bin is in the path or defined as $env:Graphviz.
	- Invoke-Build is in the path or available as the module command.

	The script calls Invoke-Build in order to get the tasks, builds the DOT
	and calls Graphviz's dot.exe in order to visualize it using one of the
	supported output formats and the associated application.

	Tasks with code are shown as boxes, tasks without code are shown as ovals.
	Safe references are shown with dotted edges, regular calls are shown with
	solid edges. Job numbers are not shown by default.

	EXAMPLES

	# Make and show PDF for the default build script
	Show-BuildGraph

	# Make Build.png with job numbers and top to bottom edges
	Show-BuildGraph -Number -NoShow -Code '' -Output Build.png

.Parameter File
		See: help Invoke-Build -Parameter File
.Parameter Output
		The output file and the format specified by its extension.
		The default is "$env:TEMP\name-xxxxxxxx.pdf".
.Parameter Code
		Custom DOT code added to the graph definition, see Graphviz manuals.
		The default 'graph [rankdir=LR]' tells edges to go from left to right.
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
	[string]$Code = 'graph [rankdir=LR]',
	[hashtable]$Parameters,
	[switch]$NoShow,
	[switch]$Number
)

trap {$PSCmdlet.ThrowTerminatingError($_)}
$ErrorActionPreference = 'Stop'

# resolve dot.exe
$dot = if ($env:Graphviz) {"$env:Graphviz\dot.exe"} else {'dot.exe'}
$dot = Get-Command $dot -CommandType Application -ErrorAction 0
if (!$dot) {throw 'Cannot resolve dot.exe'}

# output
if ($Output) {
	if (!($type = [System.IO.Path]::GetExtension($Output))) {throw 'Output must have an extension'}
	$Output = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Output)
	$type = $type.Substring(1).ToLower()
}
else {
	$path = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($(if ($File) {$File} else {''}))
	$name = [System.IO.Path]::GetFileNameWithoutExtension($path)
	$hash = '{0:x8}' -f ($path.ToUpper().GetHashCode())
	$Output = "$env:TEMP\$name-$hash.pdf"
	$type = 'pdf'
}

# get tasks
if (!$Parameters) {$Parameters = @{}}
$all = Invoke-Build ?? $File @Parameters

# DOT code
$text = @(
	'digraph Tasks {'
	$Code
	foreach($it in $all.Values) {
		$name = $it.Name
		'"{0}"' -f $name
		$num = 0
		$script = ''
		foreach($job in $it.Jobs) {
			++$num
			if ($job -is [string]) {
				$job, $safe = if ($job[0] -eq '?') {$job.Substring(1), 1} else {$job}
				$edge = ' '
				if ($Number) {
					$edge += "label=$num "
				}
				if ($safe) {
					$edge += "style=dotted "
				}
				'"{0}" -> "{1}" [{2}]' -f $name, $job, $edge
			}
			else {
				$script += "{$num}"
			}
		}
		if ($script) {
			if ($Number) {
				'"{0}" [ shape=box label="{0} {1}" ]' -f $name, $script
			}
			else {
				'"{0}" [ shape=box ]' -f $name
			}
		}
	}
	'}'
)

#! temp file UTF8 no BOM
$temp = "$env:TEMP\Graphviz.dot"
[System.IO.File]::WriteAllLines($temp, $text)

# make
& $dot "-T$type" -o $Output $temp
if ($LastExitCode) {return}

# show
if ($NoShow) {return}
Invoke-Item $Output
