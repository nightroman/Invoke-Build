
<#
.Synopsis
	Tests incremental and partial incremental tasks.
#>

. .\Shared.ps1

Exit-Build {
	#! LiteralPath does not work in [ ] test.
	Remove-Item z.new1.tmp, z.new2.tmp, z.old1.tmp, z.old2.tmp
}

### Make a few temporary old and new files
function New-OldFile($Name) {
	$null > $Name
	[System.IO.File]::SetLastWriteTime("$BuildRoot\$Name", '2000-01-01')
}
# old files
$old1 = 'z.old1.tmp'
$old2 = 'z.old2.tmp'
New-OldFile($old1)
New-OldFile($old2)
# new files
$new1 = 'z.new1.tmp'
$new2 = 'z.new2.tmp'
$null > $new1
$null > $new2

# Empty inputs as an array. All (!) script jobs are not invoked.
task EmptyInputs1 -Partial -Inputs @() -Outputs {} {throw 'Unexpected.'}, {throw 'Unexpected.'}

# Empty inputs as a script. All (!) script jobs are not invoked.
task EmptyInputs2 -Partial -Inputs {} -Outputs {} {throw 'Unexpected.'}, {throw 'Unexpected.'}

# Outputs are up-to-date.
# The script job is not invoked but the task-job is invoked before.
$PreFullIncrementalOneUpToDate = 0
task PreFullIncrementalOneUpToDate { ++$script:PreFullIncrementalOneUpToDate }
task FullIncrementalOneUpToDate -Inputs {'Incremental.test.ps1'} -Outputs Incremental.test.ps1 PreFullIncrementalOneUpToDate, {
	throw 'Unexpected.'
}
task TestFullIncrementalOneUpToDate FullIncrementalOneUpToDate, {
	equals $PreFullIncrementalOneUpToDate 1
}

# Outputs are up-to-date.
# The script job is not invoked but the task-job is invoked after.
$PostPartIncrementalOneUpToDate = 0
task PostPartIncrementalOneUpToDate { ++$script:PostPartIncrementalOneUpToDate }
task PartIncrementalOneUpToDate -Partial -Inputs {'Incremental.test.ps1'} -Outputs {'Incremental.test.ps1'} {
	throw 'Unexpected.'
}, PostPartIncrementalOneUpToDate
task TestPartIncrementalOneUpToDate PartIncrementalOneUpToDate, {
	equals $PostPartIncrementalOneUpToDate 1
}

# One missing output item.
# The script job is invoked with the inputs.
$FullIncrementalOneMissing = 0
task FullIncrementalOneMissing -Inputs {'Incremental.test.ps1'} -Outputs 'missing' {
	++$script:FullIncrementalOneMissing
	equals $Inputs.Count 1
	equals $Inputs[0] "$BuildRoot\Incremental.test.ps1"
	equals $Outputs 'missing'
}
task TestFullIncrementalOneMissing FullIncrementalOneMissing, {
	equals $FullIncrementalOneMissing 1
}

# One missing output item.
# The script job is invoked with the inputs.
$PartIncrementalOneMissing = 0
task PartIncrementalOneMissing -Partial -Inputs {'Incremental.test.ps1'} -Outputs {'missing'} {
	++$script:PartIncrementalOneMissing
	equals $Inputs.Count 1
	equals $Inputs[0] "$BuildRoot\Incremental.test.ps1"
	equals $Outputs.Count 1
	equals $Outputs[0] 'missing'
}
task TestPartIncrementalOneMissing PartIncrementalOneMissing, {
	equals $PartIncrementalOneMissing 1
}

# One out-of-date item.
# The script job is invoked with the inputs.
$FullIncrementalOneOutOfDate = 0
task FullIncrementalOneOutOfDate -Inputs {'Incremental.test.ps1'} -Outputs $old1 {
	++$script:FullIncrementalOneOutOfDate
	equals $Inputs.Count 1
	equals $Inputs[0] "$BuildRoot\Incremental.test.ps1"
	equals $Outputs $old1
}
task TestFullIncrementalOneOutOfDate FullIncrementalOneOutOfDate, {
	equals $FullIncrementalOneOutOfDate 1
}

# One out-of-date item.
# The script job is invoked with the inputs.
$PartIncrementalOneOutOfDate = 0
task PartIncrementalOneOutOfDate -Partial -Inputs {'Incremental.test.ps1'} -Outputs {$old1} {
	++$script:PartIncrementalOneOutOfDate
	equals $Inputs.Count 1
	equals $Inputs[0] "$BuildRoot\Incremental.test.ps1"
	equals $Outputs.Count 1
	equals $Outputs[0] $old1
}
task TestPartIncrementalOneOutOfDate PartIncrementalOneOutOfDate, {
	equals $PartIncrementalOneOutOfDate 1
}

# 2+ outputs are up-to-date. Inputs is an array.
task FullIncrementalTwoUpToDate -Inputs Incremental.test.ps1, .build.ps1 -Outputs $new1, $new2 {
	throw 'Unexpected.'
}

# 2+ outputs are up-to-date. Inputs is a script.
task PartIncrementalTwoUpToDate -Partial -Inputs {'Incremental.test.ps1'; '.build.ps1'} -Outputs {$new1; $new2} {
	throw 'Unexpected.'
}

# One output item is missing.
# All input items are piped (2). Inputs is a script.
$FullIncrementalTwoMissing = 0
task FullIncrementalTwoMissing -Inputs {'Incremental.test.ps1'; '.build.ps1'} -Outputs 'missing', $new2 {
	++$script:FullIncrementalTwoMissing
	equals $Inputs.Count 2
	equals $Inputs[0] "$BuildRoot\Incremental.test.ps1"
	equals $Inputs[1] "$BuildRoot\.build.ps1"
	equals $Outputs.Count 2
	equals $Outputs[0] 'missing'
	equals $Outputs[1] $new2
}
task TestFullIncrementalTwoMissing FullIncrementalTwoMissing, {
	equals $FullIncrementalTwoMissing 1
}

# One output item is missing.
# Only items with missing output are piped (1). Inputs is an array.
$PartIncrementalTwoMissing = 0
task PartIncrementalTwoMissing -Partial -Inputs Incremental.test.ps1, .build.ps1 -Outputs {$new1, 'missing'} {
	++$script:PartIncrementalTwoMissing
	equals $Inputs.Count 1
	equals $Inputs[0] "$BuildRoot\.build.ps1"
	equals $Outputs.Count 1
	equals $Outputs[0] 'missing'
}
task TestPartIncrementalTwoMissing PartIncrementalTwoMissing, {
	equals $PartIncrementalTwoMissing 1
}

# One output item is out-of-date.
# All input items are piped (2).
$FullIncrementalTwoOutOfDate = 0
task FullIncrementalTwoOutOfDate -Inputs {'Incremental.test.ps1'; '.build.ps1'} -Outputs $new1, $old2 {
	++$script:FullIncrementalTwoOutOfDate
	equals $Inputs.Count 2
	equals $Inputs[0] "$BuildRoot\Incremental.test.ps1"
	equals $Inputs[1] "$BuildRoot\.build.ps1"
	equals $Outputs.Count 2
	equals $Outputs[0] $new1
	equals $Outputs[1] $old2
}
task TestFullIncrementalTwoOutOfDate FullIncrementalTwoOutOfDate, {
	equals $FullIncrementalTwoOutOfDate 1
}

# One output item is out-of-date.
# Only items with out-of-date output are piped (1).
$PartIncrementalTwoOutOfDate = 0
task PartIncrementalTwoOutOfDate -Partial -Inputs {
	'Incremental.test.ps1'; '.build.ps1'
} -Outputs {
	$new1, $old2
} {process{
	++$script:PartIncrementalTwoOutOfDate
	equals $Inputs.Count 1
	equals $Inputs[0] "$BuildRoot\.build.ps1"
	equals $Outputs.Count 1
	equals $Outputs[0] $old2
	assert($_ -eq "$BuildRoot\.build.ps1")
	assert($2 -eq $old2)
}}
task TestPartIncrementalTwoOutOfDate PartIncrementalTwoOutOfDate, {
	equals $PartIncrementalTwoOutOfDate 1
}

# The inputs script fails.
task IncrementalInputsFails -Inputs {throw 'Throw in input.'} -Outputs {} {throw}
task PartialInputsFails -Partial -Inputs {throw 'Throw in input.'} -Outputs {} {throw}
task TestInputsFails ?IncrementalInputsFails, ?PartialInputsFails, {
	Test-Error IncrementalInputsFails "Throw in input.*At *\Incremental.test.ps1:*"
	Test-Error PartialInputsFails "Throw in input.*At *\Incremental.test.ps1:*"
}

# The outputs script fails.
task IncrementalOutputsFails -Inputs {'.build.ps1'} -Outputs {throw 'Throw in output.'} {throw}
task PartialOutputsFails -Partial -Inputs {'.build.ps1'} -Outputs {throw 'Throw in output.'} {throw}
task TestOutputsFails ?IncrementalOutputsFails, ?PartialOutputsFails, {
	Test-Error IncrementalOutputsFails "Throw in output.*At *\Incremental.test.ps1:*"
	Test-Error PartialOutputsFails "Throw in output.*At *\Incremental.test.ps1:*"
}

# Error: incremental output is empty
task IncrementalOutputsIsEmpty {
	$file = {
		task t1 -Inputs {'.build.ps1'} -Outputs {} {throw}
	}
	($r = try {Invoke-Build t1 $file} catch {$_})
	$e = $r[-1]
	assert ($e.CategoryInfo.Category -eq 'InvalidArgument')
	equals $e.FullyQualifiedErrorId Invoke-Build.ps1
	equals $e.InvocationInfo.ScriptName $BuildFile
	equals "$e" 'Outputs must not be empty.'
}

# Error: partial inputs and outputs have different number of items
task InputsOutputsMismatch {
	$file = {
		task t1 -Partial -Inputs {'.build.ps1'} -Outputs {} {throw}
	}
	($r = try {Invoke-Build t1 $file} catch {$_})
	$e = $r[-1]
	assert ($e.CategoryInfo.Category -eq 'InvalidData')
	equals $e.FullyQualifiedErrorId Invoke-Build.ps1
	equals $e.InvocationInfo.ScriptName $BuildFile
	equals "$e" 'Different Inputs/Outputs counts: 1/0.'
}

# Error: one of the input items is missing (normal).
task IncrementalMissingInputs {
	$file = {
		task t1 -Inputs {'missing'} -Outputs {} {throw}
	}
	($r = try {Invoke-Build t1 $file} catch {$_})
	$e = $r[-1]
	assert ($e.CategoryInfo.Category -eq 'ObjectNotFound')
	equals $e.FullyQualifiedErrorId Invoke-Build.ps1
	equals $e.InvocationInfo.ScriptName $BuildFile
	assert ("$e" -like "Missing input '*missing'.")
}

# Error: one of the input items is missing (partial).
task PartialMissingInputs {
	$file = {
		task t1 -Partial -Inputs {'missing'} -Outputs {} {throw}
	}
	($r = try {Invoke-Build t1 $file} catch {$_})
	$e = $r[-1]
	assert ($e.CategoryInfo.Category -eq 'ObjectNotFound')
	equals $e.FullyQualifiedErrorId Invoke-Build.ps1
	equals $e.InvocationInfo.ScriptName $BuildFile
	assert ("$e" -like "Missing input '*missing'.")
}

### #49
task PartialIncremental49 {
	$file = {
		task t1 -Partial -Inputs z.New1.tmp, z.Old2.tmp -Outputs z.Old1.tmp, z.New2.tmp {}
	}
	($r = Invoke-Build . $file)
	equals $r[2] 'Out-of-date outputs: 1/2.'
}
task FullIncremental49 {
	$file = {
		task t1 -Inputs z.New1.tmp, z.Old2.tmp -Outputs z.Old1.tmp, z.New2.tmp {}
	}
	($r = Invoke-Build . $file)
	equals $r[2] "Out-of-date output 'z.Old1.tmp'."
}

### #50
$param = @{
	Inputs = {Get-ChildItem -Filter z.new*}
	Outputs = {process{ [IO.Path]::ChangeExtension($_, '.txt') }}
}
task InputsPipedToOutputs @param {
	$script:InputsPipedToOutputs = 'InputsPipedToOutputs'
	equals $Inputs.Count 2
	assert ($Inputs[0] -like '*\Tests\z.new1.tmp')
	assert ($Inputs[1] -like '*\Tests\z.new2.tmp')
	equals $Outputs.Count 2
	assert ($Outputs[0] -like '*\Tests\z.new1.txt')
	assert ($Outputs[1] -like '*\Tests\z.new2.txt')
}
task TestInputsPipedToOutputs InputsPipedToOutputs, {
	equals $script:InputsPipedToOutputs InputsPipedToOutputs
}
