<!--- Source of file --->
<cfparam name="attributes.location" default="">
<!--- Max Concurrent Connections --->
<cfparam name="attributes.connections" default="4">
<!--- Where to place the file (absolute path) --->
<cfparam name="attributes.destination" default="#ExpandPath('.')#">
<!--- Target file --->
<cfparam name="attributes.filename" default="">
<cfif attributes.filename EQ "">
	<cfset attributes.filename = Reverse(GetToken(Reverse(attributes.location),1,'/'))>
</cfif>
<cfset currentFile = "#attributes.destination#\#attributes.filename#">
<cfif attributes.location EQ "">Location cannot be left blank <cfabort></cfif>

<!--- Retrive the total size of the file in bytes from 0 to x-size --->
<cfhttp url="#Attributes.Location#" useragent="#CGI.USER_AGENT#" method="HEAD"></cfhttp>
<!--- if anyone knows a better way to retrieve content-length let me know --->
<cfloop collection="#cfhttp.ResponseHeader#" item="httpHeader">
	<cfif httpHeader EQ "Content-Length">
		<cfset contentLength = cfhttp.ResponseHeader[httpHeader]>
	</cfif>
</cfloop>
<!--- <cfdump var="content length: #contentLength#"><br> --->
<!--- Divides the work evenly among each thread --->
<cfset threadName = ArrayNew(1)>
<cfloop from="0" to="#attributes.connections - 1#" index="i">
	<!--- :( didn't want to do this if someone can figure out a better formula please let me know--->
	<cfset sadHack = #iif((i EQ 0),DE(0),DE(1))#>
	<cfset baseOffset = Int(i * (contentLength / attributes.connections))>
	<cfset startOffset = baseOffset + sadHack>
	<cfset endOffset = baseOffset + Fix(contentLength / attributes.connections)>
	<!--- <cfdump var="#i#: start #startOffset# end #endOffset#"><br>--->
	<cfset threadName[i + 1] = "thread_#i##randRange(1,1000,'SHA1PRNG')#">
	<cfthread action="RUN" name="#threadName[i + 1]#" priority="high"
		index="#i#"
		location="#attributes.location#" 
		destination="#attributes.destination#"
		startOffset="#startOffset#" 
		endOffset="#endOffset#">
		<cfhttp url="#location#" method="GET" useragent="#CGI.USER_AGENT#" path="#destination#" file="file#index#.tmp" getasbinary="yes">
			<cfhttpparam type="HEADER" name="Range" value="bytes=#startOffset#-#endOffset#">
		</cfhttp> 	
	</cfthread> 
</cfloop>
<!---  <cfabort>  --->
<!--- delete any existing file with the given filename --->

<cfif fileExists("#currentFile#")>
	<cffile action="DELETE" file="#currentFile#" >
</cfif>	
<cfloop from="0" to="#attributes.connections - 1#" index="i">
	<!--- join all threads --->
	<cfthread action="JOIN" name="#threadName[i + 1]#" />
	<!--- read temp file --->
	<cffile action="readBinary" file="#attributes.destination#\file#i#.tmp" variable="readFile#i#">
	<!--- append temp to new file --->
	<cfif fileExists("#currentFile#")>
		<cffile action = "append"	
			file = "#currentFile#"	
			output = "#Evaluate('readFile#i#')#">	
	<cfelse>
		<cffile action = "write"	
			file = "#currentFile#"	
			output = "#Evaluate('readFile#i#')#">	
	</cfif>
	<!--- clean up temp files --->	
	<cffile action="DELETE" file="#attributes.destination#\file#i#.tmp">	
</cfloop>

