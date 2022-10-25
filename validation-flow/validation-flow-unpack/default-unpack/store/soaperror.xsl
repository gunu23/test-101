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

    <xsl:template match="/">
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

        <xsl:variable name="rmode">
            <xsl:value-of select="dp:variable('var://service/response-mode')"/>
        </xsl:variable>

        <xsl:variable name="foo">
             <xsl:choose>
                <xsl:when test="$rmode='2'">
                   <xsl:value-of select="dp:exter-correlator( $kd4h, '1' )"/>
                </xsl:when>
                <xsl:otherwise>
                   <xsl:value-of select="dp:exter-correlator( $kd4h, '0' )"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:copy>
            <soap:Envelope>
            <xsl:if test="$foo!='NEW_CORRELATOR'">
            <soap:Header>
                <kd4:KD4SoapHeaderV2>
                    <xsl:value-of select="$foo"/>
                </kd4:KD4SoapHeaderV2>
            </soap:Header>
            </xsl:if>
            <soap:Body><soap:Fault>
                <soap:faultcode>
                    <xsl:choose>
                        <xsl:when test="$rmode='2'">soap:Server</xsl:when>
                        <xsl:otherwise>soap:Client</xsl:otherwise>
                    </xsl:choose>
                </soap:faultcode>
                <soap:faultstring>
                    <xsl:choose>
                        <xsl:when test="$rmode='2'">Internal Error (from server)</xsl:when>
                        <xsl:otherwise>Internal Error (from client)</xsl:otherwise>
                    </xsl:choose>
                    </soap:faultstring>
            </soap:Fault></soap:Body>
            </soap:Envelope>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>

