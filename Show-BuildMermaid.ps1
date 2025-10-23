<#
.Synopsis
	Shows Invoke-Build task graph using Mermaid.
	Copyright (c) Roman Kuzmin

.Description
	Requirements:
	- Invoke-Build command is available for calls
	- Internet connection for Mermaid, https://mermaid.js.org

	The script calls Invoke-Build in order to get the tasks, generates the HTML
	page with Mermaid graph code and scripts and shows the page in the browser.

	Tasks without code are shown as ovals, conditional tasks as hexagons, other
	tasks as boxes. Safe calls are shown with dotted arrows, regular calls with
	solid arrows. Task synopses are shown at the bottom left corner on mouse
	hovering over tasks. Job numbers are optionally shown on arrows.

.Parameter File
		See: help Invoke-Build -Parameter File

.Parameter Output
		Specifies the output HTML file.
		The default is in the temp directory.

.Parameter Direction
		Specifies the direction, Top-Bottom or Left-Right: TB, BT, LR, RL.
		The default is LR.

.Parameter Directive
		Specifies the directive text, see Mermaid manuals.
		Example: %%{init: {"theme": "forest", "fontFamily": "monospace"}}%%

.Parameter Parameters
		Build script parameters needed in special cases when they alter tasks.

.Parameter NoShow
		Tells to create the output file without showing it.
		Use Output in order to specify the file exactly.

.Parameter Number
		Tells to show job numbers on arrows connecting tasks.

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
	[ValidateSet('TB', 'BT', 'LR', 'RL')]
	[string]$Direction = 'LR'
	,
	[string]$Directive
	,
	[hashtable]$Parameters
	,
	[switch]$NoShow
	,
	[switch]$Number
)

$ErrorActionPreference=1

function Escape-Text($Text) {
	$Text.Replace('"', '#quot;').Replace('<', '#lt;').Replace('>', '#gt;')
}

### resolve output
if ($Output) {
	$Output = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Output)
}
else {
	$path = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($(if ($File) {$File} else {''}))
	$name = [System.IO.Path]::GetFileNameWithoutExtension($path)
	$hash = [System.IO.Path]::GetFileName([System.IO.Path]::GetDirectoryName($path))
	$Output = [System.IO.Path]::GetTempPath() + "$name-$hash.html"
}

### get tasks
if (!$Parameters) {$Parameters = @{}}
$all = Invoke-Build ?? $File @Parameters

### for synopses
$docs = @{}
. Invoke-Build

### make text
$map = @{}
$text = @(
	if ($Directive) {$Directive}
	"graph $($Direction.ToUpper())"

	$id = 0
	foreach($it in $all.get_Values()) {
		++$id
		$name = $it.Name
		$map[$name] = $id
		$name = Escape-Text $name
		$hasScript = foreach($job in $it.Jobs) {if ($job -is [scriptblock]) {1; break}}
		if (!$hasScript) {
			"$id([`"$name`"])"
		}
		elseif ($it.Inputs -or !(-9).Equals($it.If)) {
			"$id{{`"$name`"}}"
		}
		else {
			"$id[`"$name`"]"
		}

		if ($synopsis = Get-BuildSynopsis $it $docs) {
			$synopsis = Escape-Text $synopsis
			"click $id callback `"$synopsis`""
		}
	}

	$id = 0
	foreach($it in $all.get_Values()) {
		++$id
		$jobNumber = 0
		foreach($job in $it.Jobs) {
			++$jobNumber
			if ($job -is [string]) {
				$job, $safe = if ($job[0] -eq '?') {$job.Substring(1), 1} else {$job}
				$id2 = $map[$job]
				$arrow = if ($safe) {'-.->'} else {'-->'}
				$text = if ($Number) {"|$jobNumber|"} else {''}
				'{0} {1} {2} {3}' -f $id, $arrow, $text, $id2
			}
		}
	}
)

### write HTML
@(
	@"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>$([System.IO.Path]::GetFileNameWithoutExtension($Output)) tasks</title>
</head>
<body>
<pre class="mermaid" hidden>
"@

	$text

	@'
</pre>
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/+esm';
  mermaid.initialize({ startOnLoad: true });
  document.querySelector('.mermaid').hidden = false;
</script>
</body>
</html>
'@
) | Set-Content -LiteralPath $Output -Encoding UTF8

### show file
if (!$NoShow) {
	Invoke-Item -LiteralPath $Output
}
