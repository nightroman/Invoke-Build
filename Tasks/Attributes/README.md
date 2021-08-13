The script [Attributes.build.ps1](Attributes.build.ps1) defines custom
attributes with actions (`Init` and `Kill`) and uses these attributes
for a task action job.

Then build blocks `Enter-BuildJob` and `Exit-BuildJob` retrieve job attributes
and invoke their custom actions. This example fakes initialization and disposal
of two dummy resources `Foo1` and `Foo2`.

---

- [Invoke-Build/issues/185](https://github.com/nightroman/Invoke-Build/issues/185)
