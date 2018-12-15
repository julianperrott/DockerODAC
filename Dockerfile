FROM microsoft/aspnet:4.7.2-windowsservercore-ltsc2016

# Install Chocolaty
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install Microsoft Visual C++ Redistributable (used by oracle client) via chocolatey
#RUN ["choco", "install", "vcredist2010", "-y", "--allow-empty-checksums"] <--- for oracle 11
RUN ["choco", "install", "vcredist2013", "-y", "--allow-empty-checksums"] 

COPY . c:/install

#32-bit Oracle Data Access Components (ODAC) and NuGet Downloads
#http://download.oracle.com/otn/other/ole-oo4o/ODAC122010Xcopy_32bit.zip
RUN powershell -Command "expand-archive -Path 'c:\install\ODAC122010Xcopy_32bit.zip' -DestinationPath 'c:\install\oracleInstall'"
WORKDIR c:/install/oracleInstall

# Install Oracle Client
RUN ".\install.bat odp.net4 c:\oracle odac true;"

# fix - error 0175: The specified store provider cannot be found in the configuration, or is not valid.
WORKDIR c:/Oracle/ODP.NET/bin/4

RUN ./oraprovcfg.exe /action:config /product:odp /frameworkversion:v4.0.30319 /providerpath:C:\Oracle\ODP.NET\bin\4\Oracle.DataAccess.dll

# Set path to oracle client
RUN "[Environment]::SetEnvironmentVariable(\"Path\", $env:Path + \";C:\\oracle\\\", [EnvironmentVariableTarget]::Machine)"

SHELL ["powershell", "-command"]

# set app pool to allow 32bit, remove default web site, add my 32 bit web application and use the 32-bit app pool
RUN Import-Module WebAdministration; Set-ItemProperty -Path IIS:\AppPools\'.Net v4.5' -Name enable32BitAppOnWin64 -Value 'True'; \
	Remove-WebSite -Name 'Default Web Site'; \ 
	New-Website -Name 'my-app' -Port 80 -PhysicalPath 'C:\install' -ApplicationPool '.NET v4.5'

ENTRYPOINT powershell