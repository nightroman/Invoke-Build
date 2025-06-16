
param(
	$Param1 = 0
)

$Ask = @{If = {Confirm-Build}}

task Step1 @Ask {
	(++$Script:Param1)
}

task Step2 @Ask {
	(++$Script:Param1)
}

task Step3 @Ask {
	(++$Script:Param1)
}

task . {
    Build-Checkpoint "$BuildFile.clixml" @{Task = '*'; File = $BuildFile} -Auto
}
