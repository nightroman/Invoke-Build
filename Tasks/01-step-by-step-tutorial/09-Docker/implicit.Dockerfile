# Simple, but InvokeBuild is installed each time.
# Suitable for single use CI scenarios.

FROM mcr.microsoft.com/powershell

WORKDIR /app
COPY . .

ENTRYPOINT ["pwsh", "-c", "./tea.build.ps1 -TeaBags 2 -SugarLumps 1"]
