FROM dotnetiis

WORKDIR c:/install
COPY . c:/install

# Restore packages, build, copy
#RUN nuget restore \
#    && "c:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe" /p:VisualStudioVersion=12.0 /p:VSToolsPath=c:\MSBuild.Microsoft.VisualStudio.Web.targets.14.0.0.3\tools\VSToolsPath ReadDb.sln

WORKDIR c:/install/


# install oracle
#RUN @powershell -NoProfile -ExecutionPolicy unrestricted -Command ".\oracle\install.bat odp.net4  c:\oracle myhome true;" \
#	&& setx /m PATH "%PATH%;C:\oracle"

#&& choco install vcredist2010 -y --allow-empty-checksums; \	

RUN Powershell c:/install/setupIIS.ps1
#Import-Module WebAdministration
#Set-ItemProperty -Path IIS:\AppPools\".Net v4.5" -Name enable32BitAppOnWin64 -Value "True"
#Remove-WebSite -Name 'Default Web Site' 

# add site
RUN powershell New-Website -Name 'my-app' -Port 80 -PhysicalPath 'C:\install\' -ApplicationPool '.NET v4.5'

ENTRYPOINT powershell



#docker build -t myoraclientapp .
#docker run -it --rm --name XXXX myoraclientapp