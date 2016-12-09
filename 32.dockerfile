FROM microsoft/iis

# Install Chocolatey
RUN @powershell -NoProfile -ExecutionPolicy unrestricted -Command "$env:chocolateyUseWindowsCompression = 'false'; (iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))) >$null 2>&1" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin

# Install web asp.net
RUN powershell add-windowsfeature web-asp-net45

COPY . c:/install

# this is where the Oracle ODAC Xcopy version has been unzipped into
WORKDIR c:/install/oracleInstall/xcopy_12

#install ODP.NET 4 32bit, Microsoft Visual C++ 2010 Redistributable Package, Set path to include oracle home
RUN @powershell -NoProfile -ExecutionPolicy unrestricted -Command ".\install.bat odp.net4  c:\oracle myhome true;" \ 
	&& choco install vcredist2010 -y --allow-empty-checksums; \
	&& setx /m PATH "%PATH%;C:\oracle"

SHELL ["powershell", "-command"]

# set app pool to allow 32bit, remove default web site, add my 32 bit web application and use the 32-bit app pool
RUN Import-Module WebAdministration; Set-ItemProperty -Path IIS:\AppPools\'.Net v4.5' -Name enable32BitAppOnWin64 -Value 'True'; \
	Remove-WebSite -Name 'Default Web Site'; \ 
	New-Website -Name 'my-app' -Port 80 -PhysicalPath 'C:\install' -ApplicationPool '.NET v4.5'

ENTRYPOINT powershell