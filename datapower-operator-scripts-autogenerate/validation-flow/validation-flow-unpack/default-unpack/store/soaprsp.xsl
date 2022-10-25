<?xml version="1.0" encoding="UTF-8"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2009. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!-- The top level stylesheet for Web Services Management -->

<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 

    xmlns:dp="http://www.datapower.com/extensions" 

    xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"

    xmlns:kd4="http://www.ibm.com/KD4Soap"
    exclude-result-prefixes="dp" extension-element-prefixes="dp">

    
	<xsl:output method="xml"/>

    <xsl:template match="soap:Envelope">

        <xsl:variable name="kd4h">
            <xsl:choose>
                <xsl:when test=".//kd4:KD4SoapHeaderV2">
                   <xsl:value-of select=".//kd4:KD4SoapHeaderV2"/>
                </xsl:when>
                <xsl:otherwise>
                   <xsl:text>NEW_CORRELATOR</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:copy>
            <soap:Header>
                <xsl:variable name="foo" select="dp:exter-correlator( $kd4h, '1' )"/>
                <xsl:if test="$foo!='NEW_CORRELATOR'">
                <kd4:KD4SoapHeaderV2> <xsl:value-of select="$foo"/>
                </kd4:KD4SoapHeaderV2>
                </xsl:if>
                <xsl:apply-templates mode="soap-header" select="soap:Header/*">
                </xsl:apply-templates>
            </soap:Header>
            <xsl:copy-of select="soap:Body"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template mode="soap-header" match="kd4:KD4SoapHeaderV2">
    </xsl:template>

    <xsl:template mode="soap-header" match="*">
        <xsl:copy-of select="."/>
    </xsl:template>

    <xsl:template match="@*">
        <xsl:copy/>
    </xsl:template>



</xsl:stylesheet>

