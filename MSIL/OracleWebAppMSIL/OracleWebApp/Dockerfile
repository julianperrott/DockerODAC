FROM dotnetiis

COPY . c:/install

WORKDIR c:/install/oracleInstall/xcopy_12_64


RUN Powershell c:/install/setupIIS.ps1

# install oracle
RUN @powershell -NoProfile -ExecutionPolicy unrestricted -Command ".\install.bat odp.net4  c:\oracle myhome true" \ 
    && setx /m PATH "%PATH%;C:\oracle" \
    && choco install vcredist2010 -y --allow-empty-checksums \
    && XCOPY c:\install\oracleInstall\xcopy_11_64\network\admin\*.* C:\oracle\network\admin

#RUN Powershell Remove-WebSite -Name 'Default Web Site' \ 
#    && powershell New-Website -Name 'my-app' -Port 80 -PhysicalPath 'C:\install' -ApplicationPool '.NET v4.5'
RUN powershell New-Website -Name 'my-app' -Port 80 -PhysicalPath 'C:\install' -ApplicationPool '.NET v4.5'


#docker build -t myoraclientapp .
#docker run -it --rm -p 80:80 --name XXXX myoraclientapp