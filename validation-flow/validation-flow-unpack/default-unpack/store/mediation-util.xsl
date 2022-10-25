<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2012,2013. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpconfig="http://www.datapower.com/param/config"
    xmlns:dpfunc="http://www.datapower.com/extensions/functions"
    xmlns:func="http://exslt.org/functions"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="dp"
    exclude-result-prefixes="dp"
>

  <!-- ********************* -->
  <!-- Substitute parameters -->
  <!-- ********************* -->
  <func:function name="dpfunc:stringSub">
        <xsl:param name="input" select="''"/>
        <xsl:param name="pattern" select="''"/>
        <xsl:param name="newval" select="''"/>

          <xsl:variable name="result" >
            <xsl:choose>
              <xsl:when test="contains($input, $pattern)">
                <xsl:for-each select="str:split($input, $pattern)">
                  <xsl:choose>
                    <xsl:when test="position() = last()"><xsl:value-of select="."/>
                    </xsl:when>
                    <xsl:otherwise><xsl:value-of select="."/><xsl:value-of select="$newval"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:for-each>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$input"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

        <func:result select="$result"/>
  </func:function>

  <!-- *************************************************************** -->
  <!-- Split the URI up into bits so we can match the appropriate part -->
  <!-- *************************************************************** -->
  <func:function name="dpfunc:splitURL">
        <xsl:param name="theURL" select="''"/>

        <dp:set-local-variable name="'remainingURL'" value="$theURL"/>
        <xsl:variable name="remainingURL" select="dp:local-variable('remainingURL')"/>

        <xsl:variable name="result">
            
          <xsl:variable name="protocol">
            <xsl:if test="contains($theURL, '://')">
              <xsl:value-of select="substring-before($theURL, '://')"/>
              <dp:set-local-variable name="'remainingURL'" value="substring-after($theURL, '://')"/>
            </xsl:if>        
          </xsl:variable>
          <xsl:element name="protocol"><xsl:value-of select="$protocol"/></xsl:element>

          <xsl:variable name="remainingURL" select="dp:local-variable('remainingURL')"/>
          
          <xsl:variable name="params">
            <xsl:if test="contains($remainingURL, '?')">
              <xsl:value-of select="substring-after($remainingURL, '?')"/>
              <dp:set-local-variable name="'remainingURL'" value="substring-before($remainingURL, '?')"/>
            </xsl:if>        
          </xsl:variable>
          <xsl:element name="params"><xsl:value-of select="$params"/></xsl:element>

          <xsl:variable name="remainingURL" select="dp:local-variable('remainingURL')"/>

          <dp:set-local-variable name="'hasRootURIPath'" value="'false'"/>

          <xsl:variable name="uri">
            <xsl:if test="contains($remainingURL, '/')">
              <xsl:value-of select="concat('/', substring-after($remainingURL, '/'))"/>
              <dp:set-local-variable name="'remainingURL'" value="substring-before($remainingURL, '/')"/>
            </xsl:if>        
          </xsl:variable>
          <xsl:element name="uri"><xsl:value-of select="$uri"/></xsl:element>
            
          <xsl:variable name="remainingURL" select="dp:local-variable('remainingURL')"/>

          <xsl:element name="port">
            <xsl:choose>
              <xsl:when test="contains($remainingURL,']')">   <!-- Port for IPv6 address -->
                <xsl:value-of select="substring-after(substring-after($remainingURL, ']'), ':')" />
                <dp:set-local-variable name="'remainingURL'" value="concat(substring-before($remainingURL, ']'), ']')"/>
              </xsl:when>    
              <xsl:when test="contains($remainingURL,':')">   <!-- Port for IPv4 address -->
                <xsl:value-of select="substring-after($remainingURL, ':')" />
                <dp:set-local-variable name="'remainingURL'" value="substring-before($remainingURL, ':')"/>
              </xsl:when>
            </xsl:choose>
          </xsl:element>
          
          <xsl:variable name="remainingURL" select="dp:local-variable('remainingURL')"/>
          
          <xsl:element name="host">
            <xsl:value-of select="$remainingURL" />
          </xsl:element>
            
        </xsl:variable>

        <func:result select="$result"/>
  </func:function>

</xsl:stylesheet>
