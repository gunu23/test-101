<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2010. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
    Generate a DSA or RSA WS-Security signature.
-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:date="http://exslt.org/dates-and-times"
  xmlns:dp="http://www.datapower.com/extensions"
  xmlns:dpconfig="http://www.datapower.com/param/config"
  xmlns:dpfunc="http://www.datapower.com/extensions/functions"
  xmlns:dsig="http://www.w3.org/2000/09/xmldsig#"
  xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
  xmlns:wsse11="http://docs.oasis-open.org/wss/oasis-wss-wssecurity-secext-1.1.xsd"
  xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
  extension-element-prefixes="date dp dpfunc"
  exclude-result-prefixes="date dp dpconfig dpfunc dsig wsse wsse11 wsu"
>

  <xsl:output method="xml"/>

  <xsl:include href="store:///set-wssec-sign-param.xsl" dp:ignore-multiple="yes"/>

  <dp:dynamic-namespace prefix="wsse" select="$wsse-uri"/>
  <dp:dynamic-namespace prefix="wsu" select="$wsu-uri"/>

  <xsl:variable name="body-copy">
    <!-- Should only be one Body, xsl:for-each allows us to use xsl:copy -->
    <xsl:for-each select="/*[namespace-uri()=$___soapnsuri___ and local-name()='Envelope']/*[namespace-uri()=$___soapnsuri___ and local-name()='Body'][1]">
      <!-- Copy the Body element so the exact prefix is used in case this message already has a
           signature over the Body; changing the prefix would invalidate the existing
           signature. -->
      <xsl:copy>
        
        <xsl:copy-of select="@*"/>
        
        <!-- See if there are existing ID type attribute, the signing action
             should use the existing one. It is not a good idea to add new one again,
             which may break a signature covering this node
             or generate a message not conformant with the dsig/xenc schemas.
             -->
        <xsl:choose>
          <xsl:when test="@xml:id | @*[local-name()='Id']">
            <!--
              The dp/sign.xsl doesn't really use @ID attribute while calculating
              references (and we can't change that without a pressing reason to break
              many Autobuild tests), we will process existing @Id, @wsu:Id, @xml:id
              attributes differently from @ID.

              If there are @Id, @wsu:Id or @xml:id present, whether or not those attributes
              are being referred, copy the ids. (Actually, they were copied above
              already, so nothing more to do here.)
            -->
          </xsl:when>
          <xsl:otherwise>
            <!-- There aren't any id attributes, including no @wsu:Id, so create one -->
            <xsl:variable name="body-id" select="concat('Body-', dp:generate-uuid())"/>
            <xsl:choose>
              <xsl:when test="$dpconfig:wssec-id-ref-type='wsu:Id'"><xsl:attribute name="wsu:Id"><xsl:value-of select="$body-id"/></xsl:attribute></xsl:when>
              <xsl:otherwise><xsl:attribute name="xml:id"><xsl:value-of select="$body-id"/></xsl:attribute></xsl:otherwise>
            </xsl:choose>
            <xsl:if test="$dpconfig:include-second-id = 'on'">
              <xsl:attribute name="id">
                <xsl:value-of select="$body-id"/>
              </xsl:attribute>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:copy-of select="@*[translate(local-name(), 'ID', 'id')!='id']"/>
        <xsl:for-each select="*|text()">
          <xsl:copy-of select='.'/>
        </xsl:for-each>
      </xsl:copy>
    </xsl:for-each>
  </xsl:variable>

  <xsl:template match="/">

    <xsl:call-template name="clear-num-wssec-counter"/>

    <xsl:choose>
      <xsl:when test="dpfunc:ambiguous-wssec-actor(key('soap-actor-role', $resolved-actor-role-id), $dpconfig:actor-role-id)">
        <xsl:call-template name="wssec-security-header-fault">
          <xsl:with-param name="actor" select="$dpconfig:actor-role-id"/>
          <xsl:with-param name="soapnsuri" select="$___soapnsuri___"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="/*[local-name()='Envelope']">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:copy-of select="namespace::*"/>
      <xsl:choose>
        <!-- if there is Header. -->
        <xsl:when test="*[namespace-uri()=$___soapnsuri___ and local-name()='Header']">
            <xsl:apply-templates select="*[namespace-uri()=$___soapnsuri___ and local-name()='Header']"/>
        </xsl:when>
        <xsl:otherwise>
            <!-- create a SOAP header -->
            <xsl:element namespace="{$___soapnsuri___}" name="{concat($___soapnsprefix___, 'Header')}">
              <xsl:call-template name="create-security-header"/>
            </xsl:element>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:copy-of select="$body-copy"/>
      <!-- copy all the others. -->
      <xsl:copy-of select="*[not(namespace-uri()=$___soapnsuri___ and (local-name()='Header' or local-name()='Body'))]"/>
    </xsl:copy>
  </xsl:template>

  <!-- some more templates defined in set-wssec-sign-param.xsl, 
       which is share by both msg and field level wssec signing. -->

</xsl:stylesheet>
