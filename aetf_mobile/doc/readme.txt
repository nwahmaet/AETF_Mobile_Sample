@last-updated 10:30 Friday, February 15, 2013

1. SETUP
This document describes the additional steps needed to install the AutoEdge|TheFactory Mobile Sample app.

1.1 VARIABLES 
In all cases below, manually substitute $DLC and $INSTALL for the appropriate paths.

$INSTALL is the path where the sample has been installed. You can find this by right-clicking on the
project's name. The full path is in the Resource tab, in the Location field.

$DLC is where your OE 11.2 install is located: C:\Progress\OpenEdge is the default.

1.2 DATABASE
 Create the database from the backup located in $INSTALL/db directory, named aetf.bup In ProEnv, run the
following command:
    prorest aetf aetf.bup

Start a server for the DB. You can start the db with -S/-H if you insist, but
there's no need for it
    proserve aetf

Once the DB server has started, add the database to your workspace in PDSOE, via File > Window > Preferences >
(Progress OpenEdge > Database Connections. Name it "AETF-Mobile" and point the DB location to $INSTALL\db\aetf.db

If you call it "AETF-Mobile" the project will automatically use it; if your name is something different, then you will
have to associate the DB with the project manually.

1.3 APPSERVER
There are 2 alternatives to creating the necessary AppServer 
i) Manually create an AppServer called mobile_asAutoEdgeTheFactory. 
The parameters listed below are the only important ones (everything else can be left as the default).
    Operating Mode:     State-free
    Server startup parameters:  -pf ./cfg/server.pf     
    PROPATH:            ./src/Appserver;./src/Common;$DLC     
    Startup procedure:  as_startup.p     
    Working directory:  $INSTALL
	
ii) Use the provided $INSTALL/cfg/aetf.ubroker.properties file.
Open aetf.ubroker.properties and replace $INSTALL and $DLC with your values. 
In ProEnv, run the following command, making sure to replace $INSTALL with the appropriate value. 
    mergeprop -action update -type ubroker -delta $INSTALL/cfg/aetf.ubroker.properties     

NOTE: sometimes mergeprop has trouble with spaces in paths, so you may have to enclose the delta argument in quotes, 
eg -delta "$INSTALL/cfg/aetf.ubroker.properties"

1.4 ADD SERVERS TO THE SERVERS VIEW
In the Server view, right-click and select New > Server. Select OpenEdge AppServer; after pressing Next to get to the
2nd page, the newly-added mobile_asAutoEdgeTheFactory appserver should apprear. Select this. There is no need to add
the current project to this AppServer because the AppServer's PROPATH points directly at the project location, which
means there's no deployment necessary.

Add the OE Web Server to PDSOE In the server view, right-click and select New > Server. Select OE Web Server; after
pressing Next to get to the 2nd page, select  the default restmgr1. Click Next and add the SecurityTokenService and
SecurityTokenService to the OE Web Server.

NOTE: If you cannot add servers, make sure that you can connect to the OE Explorer connection, using the credentials
used to connect to the web-based OE Management or Explorer connection via http://localhost:9090/ . The default on 
installation is admin/admin.

1.5 MOBILE WEB APPLICATION
Add a new Mobile App. File > New > Other (or CTRL-N). Filter on 'mobile' or select 
    Progress OpenEdge > Mobile > Mobile App

Select the project, and give the app a name. We use "AETF_VehicleOrderApp".

Select the "From backup" option, and select the included ZIP file, aetf_vehicleorderapp.zip (in $INSTALL). This takes 
you to a web browser and you can now edit your application.

The wizard will prompt you for your credentials to mobile.progress.com. 

You need to edit the host name for the various services that provide data to the VehicleOrderApp. In the left-hand tree,
expand the Services node. You should see 5 services: 3 VehicleOrderService.*, 1 SecurityTokenService.SecurityTokenService
and a GeolocationService. We ignore the GeolocationService service for the host name changes.
	
For each of the 3 VehicleOrderService services (BrandDataService, DealerService and ShoppingCartService), expand the
service node and select the VehicleOrderService_*_Settings node (eg VehicleOrderService_BrandDataService_Settings).
	
Change the value of the catalogURL property to 
    http://$HOSTNAME:8980/VehicleOrderService/static/mobile/VehicleOrderService.json,
where $HOSTNAME is your machine name, in a form that's accessible from the network in which you wish to use the app.
		
 Change the value of the RESTapplicationURL property to http://$HOSTNAME:8980/VehicleOrderService
	
For the SecurityTokenService, the catalogURL and RESTapplicationURL also need to change to
    http://$HOSTNAME:8980/SecurityTokenService/static/mobile/SecurityTokenService.json and
    http://$HOSTNAME:8980/SecurityTokenService resp.
	
Make sure you Save your changes.

1.6 NETWORK CONSIDERATIONS
If you're on an Arcade instance - or otherwise strongly-firewalled machine - make sure the part 8980 is open. 

Make sure that the host is available from whereever you intend to run the app (ie if the host is on a VPN, make sure 
you have access to that host/machine).
 
2. OPERATION
2.1 BUILD / COMPILE PROJECT
Once the AppServer and DB are set up for the project, compile and build the project, via Project > Clean. Select the 
AETF Mobile Sample project and make sure that it gets built too.

2.2 START APPSERVER
Change to the Servers view. Start the mobile_asAutoEdgeTheFactory AppServer if it is not yet started, by right-click 
and selecting Start. 

2.2 DEPLOY MOBILE SERVICES
Change to the Servers view. Start the restmgr1 OE Web Server if it is not yet started, by right-click and selecting
Start. 

Once the restmgr1 OE Web Server has started, right-click the server and select Publish.

2.3 RUNNING THE APP
Once the Mobile App has been added to the project, it can be run by expanding the Mobile Apps node in the project, and
right-clicking on the app name ("AETF_VehicleOrderApp", as in 1.5 above), and selecting the Run option.

NOTE: a launch config is created for this app, which will allow you to run locally or on a server.

NOTE: application user credentials are in /AETF Mobile Sample/doc/applicationusers.txt. This contains user names and
credentials for the application. The AutoEdge|TheFactory security model requires a brand/tenant in all cases.
