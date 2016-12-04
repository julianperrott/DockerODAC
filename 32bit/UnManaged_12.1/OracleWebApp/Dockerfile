FROM dotnetiis

COPY . c:/install

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



#ENTRYPOINT powershell

#docker build -t myoraclientapp .
#docker run -it --rm -p 80:80 --name XXXX myoraclientapp

#SHELL ["cmd", "/S"", "/C"]

# Restore packages, build, copy
#RUN nuget restore \
#    && "c:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe" /p:VisualStudioVersion=12.0 /p:VSToolsPath=c:\MSBuild.Microsoft.VisualStudio.Web.targets.14.0.0.3\tools\VSToolsPath ReadDb.sln
