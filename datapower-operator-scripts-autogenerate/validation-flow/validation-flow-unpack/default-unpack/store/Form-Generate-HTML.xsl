<?xml version="1.0" encoding="UTF-8"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2012,2015. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
     HMTL-Generate-Form.xsl
     Copyright 2012, 2014 DataPower Technology, Inc. All Rights Reserved.

     This file is shipped as an example on how to customize the HTML Form Based
     authentication.
    
     Login form :
     ==========
       operation : login

       MUST : The HTML form must have the following value, and they MUST match 
              to the HTML Form Policy.  And it comes in thru $input/input/FormsLoginPolicy/...

       action   : FormsLoginPolicy/FormProcessingURL

       username : FormsLoginPolicy/UsernameField
      
       password : FormsLoginPolicy/PasswordField
      
       original requested uri : content/original-uri
                This is the original request from the requester, so if authentication
                and/or authorization successed, DataPower will redirect the request
                back to the original requested uri.

       OPTIONAL :
       radius-state : To support radius challenge response, for example NextToken.

     Logout form :
     ===========
       operation : logout

     Error form :
     ==========
       operation : error

     Failure : 
     =======
       operation : failure
       Unexpected error
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:dp="http://www.datapower.com/extensions"
                xmlns:str="http://exslt.org/strings"
                extension-element-prefixes="dp str"
                exclude-result-prefixes="dp str">
    
    <xsl:output method="html" omit-xml-declaration="yes" />

    <xsl:template match="/">
  

      <html lang="en" xml:lang="en">
        <xsl:choose>
          <xsl:when test="/input/operation = 'login'">
            
            <!-- only source coming from the the appliance to be trusted. 
                 This is executed as on the request side, and the following is sufficient
            -->
            <dp:set-http-response-header name="'Content-Security-Policy'" value='"default-src &apos;self&apos;"'/>
            <dp:set-http-response-header name="'X-Frame-Options'" value="'SAMEORIGIN'"/>  <!-- for ClickJack -->
            <dp:set-http-response-header name="'Frame-Options'" value="'SAMEORIGIN'"/>    <!-- for ClickJack --> 
            <dp:set-http-response-header name="'X-XSS-Protection'" value="'1; mode=block'"/>   <!-- XSS Protection -->

            <xsl:call-template name="login-page">
              <xsl:with-param name="input" select="/" />
            </xsl:call-template>
          </xsl:when>

          <xsl:when test="/input/operation = 'logout'">
            <head>
              <meta http-equiv="Pragma" content="no-cache"/>
              <meta http-equiv="content-type" content="text/html; charset=UTF-8"/>
              <meta charset="UTF-8"/>
              <title>Logged out</title>
            </head>
            <body>
              <H2>You are now logged out of the Web Application</H2>
              <P>You will be required to log in again before you can access protected pages.</P>
            </body>
          </xsl:when>

          <xsl:when test="/input/operation = 'error'">
            <head>
              <meta http-equiv="Pragma" content="no-cache"/>
              <meta http-equiv="content-type" content="text/html; charset=UTF-8"/>
              <meta charset="UTF-8"/>
              <title>A Form login authentication failure occurred</title>
            </head>
            <body>
              <H2>A Form login authentication failure occurred</H2>
              <P>Authentication may fail with one of many reasons.  Some possibilities include:
                <OL>
                  <LI>The user-id or password may be entered incorrectly; 
                      either misspelled or the wrong case was used.</LI>
                  <LI>The user-id or password does not exist, has expired, 
                      or has been disabled.</LI>
                </OL>
              </P>
            </body>
          </xsl:when>

          <xsl:otherwise>
            <head>
              <meta http-equiv="Pragma" content="no-cache"/>
              <meta http-equiv="content-type" content="text/html; charset=UTF-8"/>
              <meta charset="UTF-8"/>
              <title>Unexpected Error</title>
            </head>
            <body>
              <h1>Unexpected Error</h1>
              <p>An error occurred, please contact the administrator of the site.</p>
            </body>
          </xsl:otherwise>
        </xsl:choose>
      </html>

    </xsl:template>

    <!-- generate a login page-->
    <xsl:template name="login-page">
      <xsl:param name="input" select="/.."/>

      <!-- 
         in the configuration, the default has a / in the FormProcessingURL, however
         for the action, the / must be removed
      -->
      <xsl:variable name="formpolicy" select="$input/input/identity/entry[@type='html-forms-auth']/policy"/>

      <xsl:variable name="action">
        <xsl:choose>
          <xsl:when test="starts-with($formpolicy/FormsLoginPolicy/FormProcessingURL, '/')">
            <xsl:value-of select="substring($formpolicy/FormsLoginPolicy/FormProcessingURL, 2)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$formpolicy/FormsLoginPolicy/FormProcessingURL"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <head>
        <meta http-equiv="Pragma" content="no-cache"/>
        <meta http-equiv="content-type" content="text/html; charset=UTF-8"/>
        <meta charset="UTF-8"/>
        <title>Login Page</title>
      </head>
      <body>
        <h2>DataPower Form Login</h2>
        <form name="LoginForm" method="post">
          <xsl:attribute name="action"><xsl:value-of select="$action"/></xsl:attribute>
          <p>
            <xsl:choose>
              <xsl:when test="$input/input/radius-challenged/node()">
                <!--  For supporting RADIUS Challenge/Response protocol, the message from the RADIUS server
                      if given, should be displayed for the end user
                      This section can be removed if the protocol is not supported.
                -->
                <xsl:choose>
                  <xsl:when test="$input/input/radius-challenged/message != ''">
                    <strong><xsl:value-of select="$input/input/radius-challenged/message"/></strong><br/>
                  </xsl:when>
                  <xsl:otherwise>
                    <strong>Wait for tokencode to change, then enter your username and new tokencode.<br/>
                    <font size="2" color="grey">Tokencode is the number on RSA SecurID token, enter it without your PIN. It may take a minute or more for the tokencode to change.</font><br/></strong>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:otherwise>
                <strong>Please enter your user ID and password.</strong>
              </xsl:otherwise>
            </xsl:choose>
            <br/>
            <font size="2" color="grey">If you have forgotten your user ID or password, 
            please contact the server administrator.</font>
          </p>
          <p>
            <table>
              <tr>
                <td>User ID:</td>
                <td>
                  <input type="text" size="20">
                    <xsl:attribute name="name"><xsl:value-of select="$formpolicy/FormsLoginPolicy/UsernameField"/></xsl:attribute>
                  </input>
                </td>
              </tr>
              <tr>
                <td>Password:</td>
                <td>
                  <input type="password" size="20">
                    <xsl:attribute name="name"><xsl:value-of select="$formpolicy/FormsLoginPolicy/PasswordField"/></xsl:attribute>
                  </input>
                </td>
              </tr>
            </table>
          </p>
          <p><input type="submit" name="login" value="Login"/></p>
          <input type="hidden" size="1024">
            <xsl:attribute name="name"><xsl:value-of select="$formpolicy/FormsLoginPolicy/RedirectField"/></xsl:attribute>
            <xsl:attribute name="value"><xsl:value-of select="$input/input/content/original-uri"/></xsl:attribute>
          </input>

          <!-- For supporting RADIUS Challenge/Response protocol, the STATE attribute will be stored in a hidden field
               on the form, so it can be sent back to the RADIUS server.
               This section can be removed if the protocol is not supported
          -->
          <xsl:if test="$input/input/radius-challenged/node()">
            <input type="hidden" size="32" name="radius-state">
              <xsl:attribute name="value"><xsl:value-of select="$input/input/radius-challenged/radius-state"/></xsl:attribute>
            </input>
          </xsl:if>
        </form>
      </body>
    </xsl:template>

</xsl:stylesheet>
