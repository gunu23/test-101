<?xml version="1.0" encoding="utf-8"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2010. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
      Converts inputs based on a "dpconfig:to" argument from any of {SOAP 1.1, SOAP 1.2} to 
      any of {SOAP 1.1, SOAP1.2, HTTP-string}

      dpconfig:to should be one of the wsdl-binding-protocol uris:
      http://schemas.xmlsoap.org/wsdl/soap/
      http://schemas.xmlsoap.org/wsdl/soap12/
      http://schemas.xmlsoap.org/wsdl/http/?verb=GET
      http://schemas.xmlsoap.org/wsdl/soap/?verb=POST
-->

<xsl:stylesheet version="1.0"
     xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
     xmlns:dp="http://www.datapower.com/extensions"
     xmlns:dpconfig="http://www.datapower.com/param/config"
     xmlns:exstr="http://exslt.org/strings"
     xmlns:soap11="http://schemas.xmlsoap.org/soap/envelope/"
     xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"
     xmlns:soap-rpc="http://www.w3.org/2003/05/soap-rpc"
     xmlns:regexp="http://exslt.org/regular-expressions"
     extension-element-prefixes="dp"
   exclude-result-prefixes="dp dpconfig soap11 soap12 exstr soap-rpc regexp"
>

  <xsl:include href="store://dp/msgcat/mplane.xml.xsl" dp:ignore-multiple="yes"/>

<xsl:param name="dpconfig:to" />

<xsl:output method="xml"/>

<xsl:variable name="nsout">
  <xsl:choose>
    <xsl:when test="$dpconfig:to='http://schemas.xmlsoap.org/wsdl/soap/'">
      <xsl:text>http://schemas.xmlsoap.org/soap/envelope/</xsl:text>
    </xsl:when>
    <xsl:when test="$dpconfig:to='http://schemas.xmlsoap.org/wsdl/soap12/'">
      <xsl:text>http://www.w3.org/2003/05/soap-envelope</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="namespace-uri(/*)"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="nsin" select="namespace-uri(/*)" />
<xsl:variable name="pfxin" select="dp:resolve-prefix(name(/*))" />

<xsl:template match="/">
  <xsl:choose>
    <xsl:when test="$dpconfig:to='http://schemas.xmlsoap.org/wsdl/soap/'">
      <xsl:variable name='action'
        select='substring-after(
                 dp:variable("var://service/original-content-type"), "action=")'/>
      <dp:set-request-header name='"Content-Type"' value="'text/xml'"/>
      <dp:set-request-header name='"SOAPAction"'
        value="regexp:match($action, '.(.*).')[2]"/>
      <xsl:apply-templates mode="to11" select="." />
    </xsl:when>
    <xsl:when test="$dpconfig:to='http://schemas.xmlsoap.org/wsdl/soap12/'">
      <xsl:if test="dp:responding()">
        <dp:set-response-header name='"Content-Type"' value="'application/soap+xml'"/>
      </xsl:if>
      <xsl:apply-templates mode="to12" select="." />
    </xsl:when>
    <xsl:when test="$dpconfig:to='http://schemas.xmlsoap.org/wsdl/http/?verb=GET'">
     <HTTPWRAP>
      <xsl:variable name="parts" select="/soap11:Body/*/*"/>
       <xsl:for-each
            select="dp:variable('var://service/wsm-http-parsed-url-replacement')/replacement/*">
        <xsl:choose>
         <xsl:when test="self::text">
          <xsl:value-of select="."/>
         </xsl:when>
         <xsl:when test="self::part">
          <xsl:value-of select="parts[name()=.]"/>
         </xsl:when>
        </xsl:choose>
       </xsl:for-each>
      </HTTPWRAP>
     </xsl:when>
     <xsl:otherwise>
       <xsl:message dp:priority="error" dp:id="{$DPLOG_MPLANE_SOAPMEDIATE_CANTMEDIATE}">
         <dp:with-param value="{$dpconfig:to}"/>
       </xsl:message>
       <xsl:copy-of select="."/>
     </xsl:otherwise>
   </xsl:choose>
</xsl:template>

<xsl:template match="*[namespace-uri() = $nsin]" priority="1" mode="to12">
  <xsl:element name="{name()}" namespace="{$nsout}">
    <xsl:apply-templates mode="to12" select="*|@*|node()"/>
  </xsl:element>
</xsl:template>

<xsl:template match="@*[namespace-uri() = $nsin]" priority="1" mode="to12">
  <xsl:attribute name="{name()}" namespace="{$nsout}">
    <xsl:apply-templates mode="to12" select="*|@*|node()"/>
  </xsl:attribute>
</xsl:template>

<!-- build a soap12 fault -->
<xsl:template match="*[local-name() = 'Fault'][namespace-uri() = $nsin]" priority="1" mode="to12">
  <!-- get the values we care about, for any random soap coming in-->
  <!-- any of split(faultcode,'.'), split(soap11:faultcode,'.') or soap12:Code|soap12:Code//soap12:subCode -->
  <xsl:variable name="faultcodes" select="(exstr:split(*[local-name()='faultcode'],'.')|
                                          *[local-name() = 'Code']|
                                          *[local-name() = 'Code']//*[local-name() = 'Subcode'])[. != '']"/>
  <!--any of faultstring, soap11:faultstring or soap12:Reason/soap12:Text -->
  <xsl:variable name="faultstring" select="*[local-name() = 'faultstring']|
                                          *[local-name() = 'Reason']/*[local-name() = 'Text'][1]"/>
  <!--any of faultactor, soap11:faultactor or soap12:Node -->
  <xsl:variable name="faultactor" select="*[local-name() = 'faultactor' or local-name() = 'Node']"/>
  <!--any of detail, soap11:detail or soap12:Detail -->
  <xsl:variable name="detail" select="*[local-name() = 'detail' or local-name() = 'Detail']"/>
  
  <!-- build the fault -->
  <xsl:element name="{name()}" namespace="{$nsout}">
    <xsl:apply-templates mode="to12" select="@*"/>
    <xsl:element name="{concat($pfxin,':Code')}" namespace="{$nsout}">
      <xsl:call-template name="soap12:Code">
        <xsl:with-param name="codes" select="$faultcodes"/>
      </xsl:call-template>
    </xsl:element>
    <xsl:element name="{concat($pfxin,':Reason')}" namespace="{$nsout}">
      <xsl:call-template name="soap12:Reason">
        <xsl:with-param name="text" select="$faultstring"/>
      </xsl:call-template>
    </xsl:element>
    <xsl:if test="$faultactor">
      <xsl:element name="{concat($pfxin,':Node')}" namespace="{$nsout}">
        <xsl:value-of select="$faultactor"/>
      </xsl:element>
    </xsl:if>
    <xsl:if test="$detail">
      <xsl:element name="{concat($pfxin,':Detail')}" namespace="{$nsout}">
        <xsl:apply-templates select="$detail/*|@*|node()"/>
      </xsl:element>
    </xsl:if>
  </xsl:element>
</xsl:template>

<!-- build (the contents of) a soap12 Code -->
<xsl:template name="soap12:Code">
  <xsl:param name="codes"/>
  <xsl:variable name="code1" select="normalize-space($codes[1])"/>
  <xsl:variable name="code1-local" select="dp:resolve-local-name($code1)"/>
  <xsl:variable name="code1-ns" select="dp:resolve-namespace-uri($code1,$codes[1])"/>
  <xsl:element name="{concat($pfxin,':Value')}" namespace="{$nsout}">
    <xsl:choose>
      <xsl:when test="$code1-ns = $nsin">
        <xsl:choose>
          <xsl:when test="$code1-local = 'Client'">
            <xsl:value-of select="concat($pfxin,':Sender')"/>
          </xsl:when>
          <xsl:when test="$code1-local = 'Server'">
            <xsl:value-of select="concat($pfxin,':Receiver')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat($pfxin,':',$code1-local)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$code1"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:element>
  <xsl:if test="$codes[position() > 1]">
    <xsl:element name="{concat($pfxin,':Subcode')}" namespace="{$nsout}">
      <xsl:call-template name="soap12:Code">
        <xsl:with-param name="codes" select="$codes[position() > 1]"/>
      </xsl:call-template>
    </xsl:element>
  </xsl:if>
</xsl:template>

<!-- build (the contents of) a soap12 Reason -->
<xsl:template name="soap12:Reason">
  <xsl:param name="text"/>
  <xsl:element name="{concat($pfxin,':Text')}" namespace="{$nsout}">
    <xsl:attribute name="xml:lang">
      <xsl:choose>
        <xsl:when test="$text/@xml:lang">
          <xsl:value-of select="$text/@xml:lang"/>
        </xsl:when>
        <xsl:otherwise>
          <!-- soap12 requires a lang, default to undetermined -->
          <xsl:text>und</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
    <xsl:value-of select="$text"/>
  </xsl:element>
</xsl:template>

<xsl:template match="*[namespace-uri() = $nsin]" priority="1" mode="to11">
  <xsl:element name="{name()}" namespace="{$nsout}">
    <xsl:apply-templates mode="to11" select="*|@*|node()"/>
  </xsl:element>
</xsl:template>

<xsl:template match="@*[namespace-uri() = $nsin]" priority="1" mode="to11">
  <xsl:attribute name="{name()}" namespace="{$nsout}">
    <xsl:apply-templates mode="to11" select="*|@*|node()"/>
  </xsl:attribute>
</xsl:template>

<xsl:template match="soap-rpc:result" mode="to11" priority="2">
</xsl:template>

<!-- build a soap11 fault -->
<xsl:template match="*[local-name() = 'Fault'][namespace-uri() = $nsin]" priority="1" mode="to11">
  <!-- get the values we care about, for any random soap coming in-->
  <!-- any of split(faultcode,'.'), split(soap11:faultcode,'.') or soap12:Code|soap12:Code//soap12:subCode -->
  <xsl:variable name="faultcodes" select="(exstr:split(*[local-name()='faultcode'],'.')|
                                          *[local-name() = 'Code']//*[local-name() = 'Value'])[. != '']"/>
  <!--any of faultstring, soap11:faultstring or soap12:Reason/soap12:Text -->
  <xsl:variable name="faultstring" select="*[local-name() = 'faultstring']|
                                          *[local-name() = 'Reason']/*[local-name() = 'Text'][1]"/>
  <!--any of faultactor, soap11:faultactor or soap12:Node -->
  <xsl:variable name="faultactor" select="*[local-name() = 'faultactor' or local-name() = 'Node']"/>
  <!--any of detail, soap11:detail or soap12:Detail -->
  <xsl:variable name="detail" select="*[local-name() = 'detail' or local-name() = 'Detail']"/>
  
  <xsl:element name="{name()}" namespace="{$nsout}">
    <xsl:apply-templates mode="to11" select="@*"/>
    <xsl:element name="faultcode">
      <xsl:call-template name="soap11:faultcode">
        <xsl:with-param name="codes" select="$faultcodes"/>
      </xsl:call-template>
    </xsl:element>
    <xsl:element name="faultstring">
      <xsl:value-of select="$faultstring"/>
    </xsl:element>
    <xsl:if test="$faultactor">
      <xsl:element name="faultactor">
        <xsl:value-of select="$faultactor"/>
      </xsl:element>
    </xsl:if>
    <xsl:if test="$detail">
      <xsl:element name="detail">
        <xsl:apply-templates mode="to11" select="$detail/*|@*|node()"/>
      </xsl:element>
    </xsl:if>
  </xsl:element>
</xsl:template>

<!-- build a soap11 faultcode -->
<xsl:template name="soap11:faultcode">
  <xsl:param name="codes"/>
<!--
  Wrong output for bug 28762 was "s:Client.s:Client".
  This becomes "s:Client.Client" now, which is a valid Qname. 

  Param $pfx allows for no ns-prefix if called recursively. 
-->
  <xsl:param name="pfx" select="concat($pfxin,':')"/>

  <xsl:variable name="code1" select="normalize-space($codes[1])"/>
  <xsl:variable name="code1-local" select="dp:resolve-local-name($code1)"/>
  <xsl:variable name="code1-ns" select="dp:resolve-namespace-uri($code1,$codes[1])"/>
  <xsl:choose>
    <xsl:when test="$code1-ns = $nsin">
      <xsl:choose>
        <xsl:when test="$code1-local = 'Sender'">
          <xsl:value-of select="concat($pfx,'Client')"/>
        </xsl:when>
        <xsl:when test="$code1-local = 'Receiver'">
          <xsl:value-of select="concat($pfx,'Server')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat($pfx,$code1-local)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$code1"/>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:if test="$codes[position() > 1]">
    <xsl:text>.</xsl:text>
    <xsl:call-template name="soap11:faultcode">
      <xsl:with-param name="codes" select="$codes[position() > 1]"/>
      <!-- no ns-prefix for recursive calls -->
      <xsl:with-param name="pfx" select="''"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>

<!-- correct mustUnderstand value for soap11 (must be 1 or 0) -->
<xsl:template match="*[local-name() = 'mustUnderstand'][namespace-uri() = $nsin]" priority="1" mode="to11">
  <xsl:attribute name="{name()}" namespace="{$nsout}">
    <xsl:choose>
      <xsl:when test=".='true' or .='1'">
        <xsl:text>1</xsl:text>
      </xsl:when> 
      <xsl:otherwise>
        <xsl:text>0</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:attribute>
</xsl:template>

<xsl:template match="soap-rpc:result" mode="to11" >
</xsl:template>
 

<xsl:template match="*|@*|node()" mode="to12">
  <xsl:copy>
    <xsl:apply-templates select="*|@*|node()" mode="to12"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="*|@*|node()" mode="to11">
  <xsl:copy>
    <xsl:apply-templates select="*|@*|node()" mode="to11" />
  </xsl:copy>
</xsl:template>

<xsl:template match="*|@*|node()">
  <xsl:copy>
    <xsl:apply-templates select="*|@*|node()"/>
  </xsl:copy>
</xsl:template>


</xsl:stylesheet>
