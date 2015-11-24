<cfsetting requesttimeout="1000">

<cfset string = "http://www.teamviewer.com/download/TeamViewer_Setup.exe">
<cfloop from="1" to="10" index="i">
	<cfset ultraHTTPTimer = GetTickCount()>
		<cf_UltraHTTP 
			<!--- Source of file --->
			Location="#string#"
			<!--- Desired File Name (leave blank to generate it off link ie: go.com/file.exe will become file.exe)--->
			Filename="setup1.exe"
			<!--- Max Concurrent Connections --->
			Connections="#i#"
			<!--- Directory to place the file in (absolute path) --->
			Destination="#ExpandPath('.')#\test2\">
	<cfdump var="time to download w/ #i# threads using ultrahttp: #NumberFormat(((GetTickCount() - ultraHTTPTimer) / 1000), ",.00")# seconds"><br><br>		
</cfloop>

<cfset cfHTTPtimer = GetTickCount()>
	<cfhttp url="#string#" method="GET" useragent="#CGI.USER_AGENT#" path="#ExpandPath('.')#\test1\" file="setup2.exe" getasbinary="yes">
	</cfhttp> 	
<cfdump var="time to download using cfhttp: #NumberFormat(((GetTickCount() - cfHTTPtimer) / 1000), ",.00")# seconds"><br><br>

<!--- if anyone knows a better way to retrieve content-length let me know --->
<cfloop collection="#cfhttp.ResponseHeader#" item="httpHeader">
	<cfif httpHeader EQ "Content-Length">
		<cfset contentLength = cfhttp.ResponseHeader[httpHeader]>
	</cfif>
</cfloop>

<cfdump var="Total File Size was: #Int(contentLength / 1024)# kb"><br>

<cfoutput>
Time difference: #NumberFormat(((GetTickCount() - ultraHTTPTimer) / 1000), ",.00") - NumberFormat(((GetTickCount() - cfHTTPtimer) / 1000), ",.00")# seconds OR
#Ceiling((NumberFormat(((GetTickCount() - cfHTTPtimer) / 1000), ",.00") / NumberFormat(((GetTickCount() - ultraHTTPTimer) / 1000), ",.00")) * 100)#% faster
</cfoutput>