
Samples, patterns, and various techniques

- ***Check*** shows the custom task `check` which is supposed to be invoked
  once even if a build script ("check list") is invoked repeatedly.
- ***File*** shows the custom task `file`, an incremental task with simplified
  syntax, somewhat similar to Rake `file`.
- ***Param*** shows how to create several tasks which perform similar actions
  with some differences depending on parameters.
- ***Repeat*** shows the custom task `repeat` which is supposed to be invoked
  periodically and a build script ("schedule") with such tasks.
- ***Retry*** shows the custom task `retry` which is supposed to retry its
  action on failures several times depending on parameters.
- ***Test*** shows the custom task `test` which is allowed to fail without
  stopping a build.
