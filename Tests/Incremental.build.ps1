
<#
.Synopsis
	Tests of full incremental and partial incremental tasks.

.Description
	These examples are just tests. For a real example of partial incremental
	build with dynamic input and output see .build.ps1, task ConvertMarkdown.

.Example
	Invoke-Build . Incremental.build.ps1
#>

. .\Shared.ps1

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
task FullIncrementalOneUpToDate -Inputs {'Incremental.build.ps1'} -Outputs Incremental.build.ps1 PreFullIncrementalOneUpToDate, {
	throw 'Unexpected.'
}

# Outputs are up-to-date.
# The script job is not invoked but the task-job is invoked after.
$PostPartIncrementalOneUpToDate = 0
task PostPartIncrementalOneUpToDate { ++$script:PostPartIncrementalOneUpToDate }
task PartIncrementalOneUpToDate -Partial -Inputs {'Incremental.build.ps1'} -Outputs {'Incremental.build.ps1'} {
	throw 'Unexpected.'
}, PostPartIncrementalOneUpToDate

# One missing output item.
# The script job is invoked with the inputs.
$FullIncrementalOneMissing = 0
task FullIncrementalOneMissing -Inputs {'Incremental.build.ps1'} -Outputs 'missing' {
	++$script:FullIncrementalOneMissing
	equals $Inputs.Count 1
	equals $Inputs[0] "$BuildRoot\Incremental.build.ps1"
	equals $Outputs 'missing'
}

# One missing output item.
# The script job is invoked with the inputs.
$PartIncrementalOneMissing = 0
task PartIncrementalOneMissing -Partial -Inputs {'Incremental.build.ps1'} -Outputs {'missing'} {
	++$script:PartIncrementalOneMissing
	equals $Inputs.Count 1
	equals $Inputs[0] "$BuildRoot\Incremental.build.ps1"
	equals $Outputs.Count 1
	equals $Outputs[0] 'missing'
}

# One out-of-date item.
# The script job is invoked with the inputs.
$FullIncrementalOneOutOfDate = 0
task FullIncrementalOneOutOfDate -Inputs {'Incremental.build.ps1'} -Outputs $old1 {
	++$script:FullIncrementalOneOutOfDate
	equals $Inputs.Count 1
	equals $Inputs[0] "$BuildRoot\Incremental.build.ps1"
	equals $Outputs $old1
}

# One out-of-date item.
# The script job is invoked with the inputs.
$PartIncrementalOneOutOfDate = 0
task PartIncrementalOneOutOfDate -Partial -Inputs {'Incremental.build.ps1'} -Outputs {$old1} {
	++$script:PartIncrementalOneOutOfDate
	equals $Inputs.Count 1
	equals $Inputs[0] "$BuildRoot\Incremental.build.ps1"
	equals $Outputs.Count 1
	equals $Outputs[0] $old1
}

# 2+ outputs are up-to-date. Inputs is an array.
task FullIncrementalTwoUpToDate -Inputs Incremental.build.ps1, .build.ps1 -Outputs $new1, $new2 {
	throw 'Unexpected.'
}

# 2+ outputs are up-to-date. Inputs is a script.
task PartIncrementalTwoUpToDate -Partial -Inputs {'Incremental.build.ps1'; '.build.ps1'} -Outputs {$new1; $new2} {
	throw 'Unexpected.'
}

# One output item is missing.
# All input items are piped (2). Inputs is a script.
$FullIncrementalTwoMissing = 0
task FullIncrementalTwoMissing -Inputs {'Incremental.build.ps1'; '.build.ps1'} -Outputs 'missing', $new2 {
	++$script:FullIncrementalTwoMissing
	equals $Inputs.Count 2
	equals $Inputs[0] "$BuildRoot\Incremental.build.ps1"
	equals $Inputs[1] "$BuildRoot\.build.ps1"
	equals $Outputs.Count 2
	equals $Outputs[0] 'missing'
	equals $Outputs[1] $new2
}

# One output item is missing.
# Only items with missing output are piped (1). Inputs is an array.
$PartIncrementalTwoMissing = 0
task PartIncrementalTwoMissing -Partial -Inputs Incremental.build.ps1, .build.ps1 -Outputs {$new1, 'missing'} {
	++$script:PartIncrementalTwoMissing
	equals $Inputs.Count 1
	equals $Inputs[0] "$BuildRoot\.build.ps1"
	equals $Outputs.Count 1
	equals $Outputs[0] 'missing'
}

# One output item is out-of-date.
# All input items are piped (2).
$FullIncrementalTwoOutOfDate = 0
task FullIncrementalTwoOutOfDate -Inputs {'Incremental.build.ps1'; '.build.ps1'} -Outputs $new1, $old2 {
	++$script:FullIncrementalTwoOutOfDate
	equals $Inputs.Count 2
	equals $Inputs[0] "$BuildRoot\Incremental.build.ps1"
	equals $Inputs[1] "$BuildRoot\.build.ps1"
	equals $Outputs.Count 2
	equals $Outputs[0] $new1
	equals $Outputs[1] $old2
}

# One output item is out-of-date.
# Only items with out-of-date output are piped (1).
$PartIncrementalTwoOutOfDate = 0
task PartIncrementalTwoOutOfDate -Partial -Inputs {
	'Incremental.build.ps1'; '.build.ps1'
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

# The inputs script fails.
task IncrementalInputsFails -Inputs {throw 'Throw in input.'} -Outputs {} {throw}
task PartialInputsFails -Partial -Inputs {throw 'Throw in input.'} -Outputs {} {throw}

# The outputs script fails.
task IncrementalOutputsFails -Inputs {'.build.ps1'} -Outputs {throw 'Throw in output.'} {throw}
task PartialOutputsFails -Partial -Inputs {'.build.ps1'} -Outputs {throw 'Throw in output.'} {throw}

# Error: incremental output is empty
# Error: partial inputs and outputs have different number of items
task IncrementalOutputsIsEmpty -Inputs {'.build.ps1'} -Outputs {} {throw}
task InputsOutputsMismatch -Partial -Inputs {'.build.ps1'} -Outputs {} {throw}

# Error: one of the input items is missing.
task IncrementalMissingInputs -Inputs {'missing'} -Outputs {} {throw}
task PartialMissingInputs -Partial -Inputs {'missing'} -Outputs {} {throw}

# The default task calls all test tasks and then checks the expected results.
task . `
EmptyInputs1,
EmptyInputs2,
FullIncrementalOneUpToDate,
PartIncrementalOneUpToDate,
FullIncrementalOneMissing,
PartIncrementalOneMissing,
FullIncrementalOneOutOfDate,
PartIncrementalOneOutOfDate,
FullIncrementalTwoUpToDate,
PartIncrementalTwoUpToDate,
FullIncrementalTwoMissing,
PartIncrementalTwoMissing,
FullIncrementalTwoOutOfDate,
PartIncrementalTwoOutOfDate,
(job IncrementalInputsFails -Safe),
(job PartialInputsFails -Safe),
(job IncrementalOutputsFails -Safe),
(job PartialOutputsFails -Safe),
{
	equals $PreFullIncrementalOneUpToDate 1
	equals $PostPartIncrementalOneUpToDate 1

	equals $FullIncrementalOneMissing 1
	equals $PartIncrementalOneMissing 1

	equals $FullIncrementalOneOutOfDate 1
	equals $PartIncrementalOneOutOfDate 1

	equals $FullIncrementalTwoMissing 1
	equals $PartIncrementalTwoMissing 1

	equals $FullIncrementalTwoOutOfDate 1
	equals $PartIncrementalTwoOutOfDate 1

	# thrown from task code
	#! v5 truncates source differently
	Test-Error IncrementalInputsFails "Throw in input.*At *\Incremental.build.ps1:*"
	Test-Error PartialInputsFails "Throw in input.*At *\Incremental.build.ps1:*"
	Test-Error IncrementalOutputsFails "Throw in output.*At *\Incremental.build.ps1:*"
	Test-Error PartialOutputsFails "Throw in output.*At *\Incremental.build.ps1:*"

	# thrown from the engine
	Test-Issue IncrementalOutputsIsEmpty Incremental.build.ps1 "Outputs must not be empty.*try { Invoke-Build *OperationStopped*"
	Test-Issue InputsOutputsMismatch Incremental.build.ps1 "Different Inputs/Outputs counts: 1/0.*try { Invoke-Build *OperationStopped*"
	Test-Issue IncrementalMissingInputs Incremental.build.ps1 "Missing Inputs item: '*\missing'.*try { Invoke-Build *OperationStopped*"
	Test-Issue PartialMissingInputs Incremental.build.ps1 "Missing Inputs item: '*\missing'.*try { Invoke-Build *OperationStopped*"

	#! LiteralPath does not work in [ ] test.
	Remove-Item z.new1.tmp, z.new2.tmp, z.old1.tmp, z.old2.tmp
}
