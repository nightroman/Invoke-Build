
param(
	# Specifies inherited task prefixes, "one::" and "two::" for Base and More.
	[ValidateScript({"one::Base\Base.build.ps1", "two::More\More.build.ps1"})]
	$Extends
)

# References base tasks using prefixes.
task Build one::Build, two::Build, {
	"Test $Configuration"
}
