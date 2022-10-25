<?xml version="1.0" encoding="UTF-8"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2012,2018. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
     OAuth-Generate-HTML.xsl
     Copyright 2012 DataPower Technology, Inc. All Rights Reserved.

     This file is shipped as an example on how to customize the OAuth html
     authorization form and error page presented to the Resource Owner.

     Authorization/Consent Form:

     The authorization form is returned to a Resource Owner to gain his/her approval
     for an OAuth Client to access his/her resource.
-->

<!--
     The following are the fields that exist on the HTML authorization/consent form


[MUST] :

     Form Action :
         - /oauth/submit-url : Form data must be sent back to /oauth/submit-url for processing

     approve :
         - Resource Owner's approval

     original-url :
         - The URL sent by OAuth client for requesting the access to the resource
         - value : /oauth/original-url

     client_id :
         - OAuth client_id
         - value : /oauth/client_id

     scope :
         - The scope that the Authorization Server will be grant for
         - value : /oauth/scope

     resource-owner :
         - The resource owner's identity, this will be used for auditing purpose
         - value : /oauth/dp-state/result/resource-owner

     dp-state :
         - DataPower's specific state
         - value : /oauth/dp-state/result/code

     redirect_uri :
         - Redirect URI that OAuth client sent in with the request
         - value : /oauth/identity/oauth-id/redirect_uri

     dp-data :
         - DataPower's related data, among the information, this contains nonce, notBefore,
           notAfter.. etc
         - value : /oauth/dp-data

     miscinfo :
        - must if exists
        - this is the miscinfo from the custom stylesheet, to be carried for the OAuth

[Optional] :

     selectedscope : if it exists, it is a list of scope choosen by the resource owner
         - send back to the authorization to allow resource owner to select scope

-->

<!--
     Error Page:

     The error page is returned when a non-protocol error occurrs while processing a
     request submitted by the Resource Owner. For example, an invalid redirect_uri or
     improperly submitted authorization form will result in a non-protocol error.

     /oauth/error will always be present in the input for the error case.

     error :
         - The error string indicated the reason for failure. (e.g. invalid_client)
         - value : /oauth/error
     error_description :
         - The error description
         - value : /oauth/error_description
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:dp="http://www.datapower.com/extensions"
                xmlns:str="http://exslt.org/strings"
                extension-element-prefixes="dp str"
                exclude-result-prefixes="dp str">

    <xsl:output method="html" omit-xml-declaration="yes" />

    <xsl:template match="/">

        <xsl:choose>
            <xsl:when test="/oauth/error">
                <xsl:call-template name="error-page">
                    <xsl:with-param name="input" select="/" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>

                <dp:set-http-response-header name="'Content-Security-Policy'" value='"default-src &apos;self&apos;"'/>
                <dp:set-http-response-header name="'X-Frame-Options'" value="'SAMEORIGIN'"/>  <!-- for ClickJack -->
                <dp:set-http-response-header name="'Frame-Options'" value="'SAMEORIGIN'"/>  <!-- for ClickJack -->
                <dp:set-http-response-header name="'X-XSS-Protection'" value="'1; mode=block'"/>  <!-- XSS Protection -->

                <xsl:call-template name="az-form">
                    <xsl:with-param name="input" select="/" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

<!-- ==================================================================== -->

    <xsl:template name="error-page">
        <xsl:param name="input" select="/.."/>

    <!--
           build the error page
    -->
    <html lang="en" xml:lang="en">
        <head>
            <title>Error</title>
            <meta http-equiv="Cache-Control" content="no-cache"/>
            <meta http-equiv="Pragma" content="no-cache"/>
            <meta http-equiv="Expires" content="-1"/>
            <meta http-equiv="X-UA-Compatible" content="IE=8"/>
        </head>
        <body>
            <h1>OAuth Error</h1>
            <p>An error occurred while processing the OAuth request.</p>
            <table>
            <tr>
                <td>Error:</td>
                <td><xsl:value-of select="$input/oauth/error" /></td>
            </tr>
            <tr>
                <td>Error Description:</td>
                <td><xsl:value-of select="$input/oauth/error_description" /></td>
            </tr>
            </table>
        </body>
    </html>
    </xsl:template>

<!-- ==================================================================== -->

    <!--
           build the authorization/consent form
    -->
    <xsl:template name="az-form">
        <xsl:param name="input" select="/.."/>


        <!-- ******** The following fields are MUST for the authorization/consent form ******** -->
        <!-- Where to submit the authorization/consent form  -->
        <xsl:variable name="submit_uri"     select="$input/oauth/submit-url" />
        <!-- The URL sent by OAuth client for requesting the access to the resource -->
        <xsl:variable name="original_url"   select="$input/oauth/original-url" />
        <!-- The scope requested -->
        <xsl:variable name="scope"          select="$input/oauth/scope" />
        <!-- resource owner's identity The resource owner's identity -->
        <xsl:variable name="resource_owner" select="$input/oauth/dp-state/result/resource-owner" />
        <!-- DataPower's related data -->
        <xsl:variable name="dp-data"        select="$input/oauth/dp-data" />
        <!-- DataPower's specific code -->
        <xsl:variable name="dp-state"       select="$input/oauth/dp-state/result/code" />
        <!-- Redirect URI -->
        <xsl:variable name="redirect_uri"   select="$input/oauth/identity/oauth-id/redirect_uri" />
        <!-- OAuth Client ID -->
        <xsl:variable name="client_id"      select="$input/oauth/client_id"/>
        <!-- miscinfo -->
        <xsl:variable name="miscinfo"       select="$input/oauth/dp-state/result/miscinfo"/>

        <!-- ******** The following is for displaying purpose ******** -->
        <xsl:variable name="display_resource_owner">
          <xsl:choose>
            <xsl:when test="$input/oauth/misc-identity//username != ''">
              <xsl:value-of select="$input/oauth/misc-identity//username"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$input/oauth/dp-state/result/resource-owner"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

    <!--
           build the authorization/consent form
    -->

    <html lang="en" xml:lang="en">
    <head>
        <title>Request for Permission</title>
        <meta http-equiv="Cache-Control" content="no-cache"/>
        <meta http-equiv="Pragma" content="no-cache"/>
        <meta http-equiv="Expires" content="-1"/>
        <meta http-equiv="X-UA-Compatible" content="IE=8"/>
    </head>

    <body>
        <form method="POST" style="display: inline;"
                            enctype="application/x-www-form-urlencoded"
                            action="{$submit_uri}">
            <h2>Request for Permission</h2>
            <p>Welcome <span style="font-weight:bold;"><xsl:value-of select="$display_resource_owner" /></span></p>

            <xsl:if test="$input/oauth/scope != ''">
                Do you allow Example Inc. access to:<br/>
                <font size="2" color="grey">Choosing "Allow access" with no scope selected, DataPower will interpret it as the resource owner grants permission to all the requested scope(s).</font>
                <xsl:variable name="scopes" select="str:tokenize($input/oauth/scope, ' ')"/>
                <xsl:for-each select="$scopes">
                    <br/><input type="checkbox" checked="yes" name="selectedscope" value="{text()}"/><xsl:value-of select="text()"/>
                </xsl:for-each>
                <br/><br/>
            </xsl:if>

            <input type="hidden" name="dp-state" value="{$dp-state}"/>
            <input type="hidden" name="resource-owner" value="{$resource_owner}"/>
            <input type="hidden" name="redirect_uri" value="{$redirect_uri}"/>
            <input type="hidden" name="scope" value="{$scope}"/>
            <input type="hidden" name="original-url" value="{$original_url}"/>
            <input type="hidden" name="client_id" value="{$client_id}"/>
            <input type="hidden" name="dp-data" value="{$dp-data}"/>
            <xsl:if test="$miscinfo != ''">
                <input type="hidden" name="miscinfo" value="{$miscinfo}"/>
            </xsl:if>
            <input type="radio" name="approve" value="true"/><label>Allow access</label>
            <input type="radio" name="approve" value="false" checked="checked"/><label>No thanks</label><br/><br/>

            <input type="submit" name="submit" value="Submit"/>

            <font size="2" color="grey">        Clicking Submit will redirect you to <span style="font-weight:bold;"><xsl:value-of select="$redirect_uri"/>.</span></font>
        </form>
    </body>
    </html>
    </xsl:template>

</xsl:stylesheet>
