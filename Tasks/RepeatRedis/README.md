
This demo is similar to [Repeat2](../Repeat2) but it uses Redis for task records instead of CLIXML files
and provides some extra features like task and error logging to Redis (why not, Redis is used).
Required module: [FarNet.Redis](https://www.powershellgallery.com/packages/FarNet.Redis).

[Repeat.tasks.ps1](Repeat.tasks.ps1) defines `repeat` parameters.
It is designed for using by any build script, not just this demo.

[Repeat.build.ps1](Repeat.build.ps1) shows main and extra features.

See also [Repeat](../Repeat).
