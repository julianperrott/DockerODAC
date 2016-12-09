![alt text](/post/img/bg_odac_600x350_2.jpg "Technology Images")

Docker is an interesting container technology which Microsoft is making available on their Windows Server 2016 platform.

For 4.x dotnet applications which need a connection to an Oracle database the managed Oracle Data Access Client is the easiest route to take these days, 
but if you must use the unmanaged version, then this blog will show you the way to setup your Docker images and 
what exceptions you may get if you wander from the happy path.

This blog makes the assumptions that you are familiar with building and using docker images. If you are not then visit these sites:

https://msdn.microsoft.com/en-gb/virtualization/windowscontainers/quick_start/quick_start_windows_server
https://www.katacoda.com/

### 1. Create a demo web application


I have created a simple MVC web application to test with. The code is all found in the Global.asax.cs file. An Index method in the home controller makes a select from an Oracle database.

<pre class="prettyprint" >
    using Oracle.DataAccess.Client;
    using System;
    using System.Data;
    using System.Web.Mvc;
    using System.Web.Routing;

    public class MvcApplication : System.Web.HttpApplication
    {
        protected void Application_Start()
        {
            RouteTable.Routes.IgnoreRoute("{resource}.axd/{*pathInfo}");
            RouteTable.Routes.MapRoute(name: "Default", url: "{controller}/{action}/{id}", 
			defaults: new { controller = "Home", action = "Index", id = UrlParameter.Optional });
        }
    }

    public class HomeController : Controller
    {
        public string Index()
        {
            var connection = new OracleConnection("data source=data source=oraclejp.northeurope.cloudapp.azure.com:1521/MYDATABASE;password=password;user id=jperrott;");
            connection.Open();
            var ds = new DataSet();
            new OracleDataAdapter("select * from dual", connection).Fill(ds);
            return DateTime.Now.ToShortTimeString() + ". select * from dual = " + 
				ds.Tables[0].Rows[0][0] + ", app type: " + (IntPtr.Size == 4 ? "32bit" : "64bit");
        }
    }

</pre>

### 2. Create your Dockerfile

If you stray from the steps listed below and it you get a runtime exception, then you will need to refer to the list of exceptions further down to work out what has gone wrong.

Note: Make sure the bitness 32 or 64 is consistent for your application, OracleDataAccess.DLL ,ODAC & C++ 2010 Redistributable !


- Download the correct ODAC (xcopy version) for your application. Either ("32-bit Oracle Data Access Components (ODAC) and NuGet Downloads") or ("64-bit Oracle Data Access Components (ODAC) Downloads")
- Compile your application with a reference to the unmanaged OracleDataAccess.DLL  (Use v11 if the ODAC is v11). (It in doubt use the one found in the ODAC Xcopy, located in odp.net4\odp.net\bin\4\Oracle.DataAccess.dll)

In your Dockerfile:

- Copy your ODAC xcopy and application into the container.
- Install the ODAC xcopy version of ODP.NET4
- If using ODAC V12 then install Microsoft Visual C++ 2010 Redistributable Package
- If using ODAC V12 then set Path to point at oracle client path.
- Enable 32 bit on the app pool if you are using a web app which is 32 bit.
- Install your application.


<br/> 
#### Dockerfile Examples ####

In my examples the dockerfile is located in the web application folder as are the Oracle ODAC xcopy extracted files.

![alt text](/post/img/Odac_Oracle_Folder.png "Oracle install folder structure")

##### Example Dockerfile for v12 32 bit
<pre class="prettyprint">
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
</pre>

</br>

##### Example Dockerfile for v12 64 bit

The only real difference is that I am not setting the app pool to allow 32 bit.

<pre class="prettyprint">
	FROM microsoft/iis

 	#Install Chocolatey
	RUN @powershell -NoProfile -ExecutionPolicy unrestricted -Command "$env:chocolateyUseWindowsCompression = 'false'; (iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))) >$null 2>&1" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin

	# Install web asp.net
	RUN powershell add-windowsfeature web-asp-net45

	COPY . c:/install

	# this is where the Oracle ODAC Xcopy version has been unzipped into
	WORKDIR c:/install/oracleInstall/xcopy_12_64

	#install ODP.NET 4 64bit, Microsoft Visual C++ 2010 Redistributable Package, Set path to include oracle home
	RUN @powershell -NoProfile -ExecutionPolicy unrestricted -Command ".\install.bat odp.net4  c:\oracle myhome true;" \ 
		&& choco install vcredist2010 -y --allow-empty-checksums; \
		&& setx /m PATH "%PATH%;C:\oracle"

	SHELL ["powershell", "-command"]

	# remove default web site, add my 64 bit web application and use the 64-bit app pool
	RUN Remove-WebSite -Name 'Default Web Site'; \ 
		New-Website -Name 'my-app' -Port 80 -PhysicalPath 'C:\install' -ApplicationPool '.NET v4.5'

	ENTRYPOINT powershell
</pre>

<br/> 

### 3. Building the image

Build using:

<pre class="prettyprint">
	docker build -t myoraclientapp .
</pre>

Example Log:

![alt text](/post/img/OdacBuildLog.png "Build log")

<br/> 

### 4. Running the container

Run using:

<pre class="prettyprint">
    docker run -it --rm -p 80:80 --name XXXX myoraclientapp
</pre>

Your can then either use a browser to view the default page or within the docker container type:

<pre class="prettyprint">
    curl 127.0.0.1 -UseBasicParsing
</pre>

<br/> 

### 5. Container run-time exceptions and what they mean


**BadImageFormatException**

<pre class="prettyprint">
BadImageFormatException: Could not load file or assembly 'NameOfYourAppHere' or one of its dependencies. An attempt was made to load a program with an incorrect format.
</pre>

This means that there is a bitness mismatch between the Application pool and the application or the application and the Oracle.DataAccess.dll.

IF App Pool has enabled 32bit apps then the app is compiled in x64 or oracle.dataaccess.dll is x64.
or if if App Pool has not enable 32bit Apps then App compiled in x86 or oracle.dataaccess.dll is x86 (App pool doesn't support x86)

<br/> 

<pre class="prettyprint">
BadImageFormatException: Could not load file or assembly 'Oracle.DataAccess' or one of its dependencies. An attempt was made to load a program with an incorrect format.

HttpException (0x80004005): Could not load file or assembly 'Oracle.DataAccess' or one of its dependencies. An attempt was made to load a program with an incorrect format.
</pre>

The application is complied in x86, but the Oracle.DataAccess.dll is x64

<br/> 

**OracleException**

<pre class="prettyprint">
OracleException (0x80004005): The provider is not compatible with the version of Oracle client
</pre>

The App pool, application and Oracle.DataAccess.dll are all 32 bit, but the ODP.NET installed on the machine is 64-bit

<pre class="prettyprint">
OracleException (0x80004005): ORA-12154: TNS:could not resolve the connect identifier specified]
</pre>

- TNSNAMES.ORA is not in the ORACLE_HOME\NETWORK\ADMIN folder.
- ADDRESS_LIST may need to be used in TNSNAMES.ORA.

<br/> 
  
**DllNotFoundException**

<pre class="prettyprint">
DllNotFoundException: Unable to load DLL 'OraOps12.dll': The specified module could not be found.
</pre>

- VcRedist2010 not installed (V12 ODP.NET), 
- or using V12 OracleDataAccess.dll with V11 ODP.NET
- or using 64 bit OracleDataAccess.dll with 32 bit ODP.NET

<br/>   
  
**NullReferenceException**

<pre class="prettyprint">
NullReferenceException: Object reference not set to an instance of an object.
</pre>

When using the v12 ODP.NET the path must point to the client folder.

<br/> 

#### Further Investigation

If you are unable to get the container to talk to your database then I recommend creating a 
sandbox VM and running the steps in the dockerfile manually and see if you can reproduce the issue.

Windows Sysinternals Process Monitor is useful to determine which dll is missing on your sandbox vm. The log of the application
can also be compared to the log from a working version if you have one.
