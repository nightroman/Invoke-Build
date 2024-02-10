# InvokeBuild is installed, imported, and called explicitly.
# Suitable for multiple uses and scripts without bootstrap.

FROM mcr.microsoft.com/powershell
RUN ["pwsh", "-c", "Install-Module InvokeBuild -Force"]

WORKDIR /app
COPY . .

ENTRYPOINT ["pwsh", "-c", "Import-Module InvokeBuild; Invoke-Build -TeaBags 2 -SugarLumps 1"]
