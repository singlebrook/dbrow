<cfscript>

/* Called by all remote methods. Override with authorization checks to
  allow access to the methods. */
public void function checkRemoteMethodAuthorization() {
  var contentType = 'text/html';
  var content = 'Unauthorized'
  if (getHTTPRequestData().headers.accept == 'application/json') {
    contentType = 'application/json';
    content = '{ "error": "Unauthorized" }';
  }
  cfcontent(type = contentType, reset = true);
  cfheader(statuscode = '401', statustext = 'Unauthorized');
  WriteOutput(content);
  abort;
}

</cfscript>
