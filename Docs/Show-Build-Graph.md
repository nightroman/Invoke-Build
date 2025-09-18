# Show Build Graph

[Show-BuildDgml.ps1]: https://github.com/nightroman/Invoke-Build/blob/main/Show-BuildDgml.ps1
[Show-BuildGraph.ps1]: https://github.com/nightroman/Invoke-Build/blob/main/Show-BuildGraph.ps1
[Show-BuildMermaid.ps1]: https://github.com/nightroman/Invoke-Build/blob/main/Show-BuildMermaid.ps1

Build task graphs can be visualized by the following scripts

- [Show-BuildGraph.ps1] generates and shows HTML, SVG, PNG, PDF, ... using [Viz.js](https://github.com/mdaines/viz.js) or [Graphviz](http://graphviz.org)
- [Show-BuildMermaid.ps1] generates and shows HTML using [Mermaid](https://mermaid.js.org)
- [Show-BuildDgml.ps1] generates DGML and opens it in Visual Studio (Visual Studio features: Individual components / Code tools / DGML editor).

See scripts help comments for the details and available customizations.

`Show-BuildGraph` is available at the [PSGallery](https://www.powershellgallery.com/packages/Show-BuildGraph) and may be installed and updated as

```powershell
Install-Script Show-BuildGraph
Update-Script Show-BuildGraph
```

These commands use web resources by default and may be used right away

```powershell
Show-BuildGraph
Show-BuildMermaid
```

SVG images for this page are created using Graphviz dot, e.g. by the command below.
Tooltips, e.g. task synopses, are not shown here but available for other renderers.

```powershell
Show-BuildGraph -Dot -Output MyBuildScript.svg
```

## FarNet

See [Building FarNet Showcase](Building-FarNet-Showcase.md) for more complex
build graphs with several scripts involved and graphs created with task
clusters, e.g. by this command:

```powershell
Show-BuildGraph -Cluster
```

## Invoke-Build

Here is the task graph created for the build script of this project. Tasks with
own code are shown as boxes, tasks that simply trigger other tasks are shown as
ovals.

```powershell
Show-BuildGraph
```

![Invoke-Build](https://raw.githubusercontent.com/nightroman/Invoke-Build/refs/heads/main/Docs/images/IB.svg)

## Mdbc

This example ([Mdbc's build script](https://github.com/nightroman/Mdbc/blob/main/.build.ps1))
shows some more features

- Task call numbers can be shown.
- Call edges can go from top to bottom.
- Safe references are shown as dotted edges.

```powershell
Show-BuildGraph -Number -Code ""
```

![Mdbc](https://github.com/nightroman/Invoke-Build/raw/refs/heads/main/Docs/images/Mdbc.svg)

## Pode

This example shows some more complex graph of [pode.build.ps1](https://github.com/Badgerati/Pode/blob/develop/pode.build.ps1)

![Pode](https://github.com/nightroman/Invoke-Build/raw/refs/heads/main/Docs/images/Pode.svg)
