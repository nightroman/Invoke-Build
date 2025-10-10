<#
.Synopsis
	Used by Invoke-TaskFromISE.test.ps1 and Invoke-TaskFromVSCode.test.ps1
#>

## test-no-task

task t1 { ## test-t1-first-line
	## test-t1-inner-line
	'//t1//'
}
## test-t1-after-line

task . {
	'//.//'
}

task fail {
    ## test-fail: caret moves to the next line to `throw`
    $x = 1; throw 'Oops!'
}

task redefined {
	## redefined-1
	throw "Unexpected."
}

task redefined {
	## redefined-2
	"Redefined task."
}
