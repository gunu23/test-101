<?xml version="1.0" encoding="UTF-8"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2009, 2019. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corporation.

  See APAR IT28401 for details
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns:func="http://exslt.org/functions"
    xmlns:xalan="http://xml.apache.org/xslt"
    xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx"
    xmlns:regexp="http://exslt.org/regular-expressions" 
    xmlns:dp="http://www.datapower.com/extensions"
>
    
    
    <xsl:output method="text" encoding="utf-8" indent="no" media-type="application/json"/>

    <func:function name="json:procNameAttr">
       <xsl:if test="local-name(..)='object'">
          <func:result select="concat('&quot;', dp:encode(@name, 'json-escape-reverse-solidus'), '&quot;', ':')"/>
       </xsl:if>
    </func:function>

    <xsl:template match="json:object">
        <xsl:value-of select="json:procNameAttr()"/>
        <xsl:text>{ </xsl:text>
        <xsl:for-each select="*">
           <xsl:apply-templates select="."/>
            <xsl:if test="position() != last()">
                <xsl:text>, </xsl:text>
            </xsl:if>
       </xsl:for-each>
       <xsl:text> }</xsl:text>
    </xsl:template>

    <xsl:template match="json:array">
        <xsl:value-of select="json:procNameAttr()" />
        <xsl:text>[ </xsl:text>
        <xsl:for-each select="*">
            <xsl:apply-templates select="." />
            <xsl:if test="position() != last()">
                <xsl:text>, </xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text> ]</xsl:text>
    </xsl:template>

    <xsl:template match="json:string">
       <xsl:value-of select="json:procNameAttr()"/>
       <xsl:text>"</xsl:text>  
       <xsl:value-of select="dp:encode(., 'json-escape-reverse-solidus')"/>
       <xsl:text>"</xsl:text>
    </xsl:template>

    <xsl:template match="json:number">
       <xsl:value-of select="json:procNameAttr()"/>
       <xsl:value-of select="normalize-space()"/>
    </xsl:template>

    <xsl:template match="json:boolean">
       <xsl:value-of select="json:procNameAttr()"/>
       <xsl:value-of select="normalize-space()"/>
    </xsl:template>

    <xsl:template match="json:null">
        <xsl:value-of select="json:procNameAttr()"/>
        <xsl:text>null</xsl:text>
    </xsl:template>

</xsl:stylesheet>
