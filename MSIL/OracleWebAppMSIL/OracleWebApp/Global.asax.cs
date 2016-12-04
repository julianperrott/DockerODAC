namespace OracleWebAppX64
{
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

            RouteTable.Routes.MapRoute(
                name: "Default",
                url: "{controller}/{action}/{id}",
                defaults: new { controller = "Home", action = "Index", id = UrlParameter.Optional }
            );
        }
    }

    public class HomeController : Controller
    {
        public string Index()
        {
            var tnsadmin = Environment.GetEnvironmentVariable("TNS_ADMIN");


            var connection = new OracleConnection("data source=XE;password=qwerty69;user id=jperrott");
            connection.Open();
            var ds = new DataSet();
            new OracleDataAdapter("select * from dual", connection).Fill(ds);
            return DateTime.Now.ToShortTimeString()+ ". select * from dual = " + ds.Tables[0].Rows[0][0] + ", app type: " + (IntPtr.Size == 4 ? "32bit" : "64bit");
        }

        public string tnsadmin()
        {
            return Environment.GetEnvironmentVariable("TNS_ADMIN");
        }

        public string oraclehome()
        {
            return Environment.GetEnvironmentVariable("ORACLE_HOME");
        }
    }
}