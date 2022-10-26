<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2013. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:dp="http://www.datapower.com/extensions"
  xmlns:dpconfig="http://www.datapower.com/param/config"
  extension-element-prefixes="dp"
  exclude-result-prefixes="dp dpconfig"
  version="1.0">

<xsl:output method="xml" />
    <dp:summary xmlns="">
        <operation>antivirus</operation>
        <description>Clam Virus Scanning</description>
        <descriptionId>store.antivirus-clam.dpsummary.description</descriptionId>
    </dp:summary>


    <xsl:include href="antivirus.xsl"  dp:ignore-multiple="yes"/>

    <!-- the core of the tests. -->
    <xsl:template name="icap-test">
        <xsl:param name="icap-data" />
        <xsl:param name="icap-data-type" />

        <xsl:variable name="test-result">
            <dp:url-open target="{$icap-url}" response="responsecode-ignore" data-type="{$icap-data-type}">
                <xsl:copy-of select="$icap-data" />
            </dp:url-open>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="string($test-result/url-open/responsecode) = '201'
                    or $test-result/url-open/headers/header[@name = 'X-Infection-Found']
                    or $test-result/url-open/headers/header[@name = 'X-Clam-Virus'] = 'yes'">
                <virus />
            </xsl:when>
            <xsl:when test="string($test-result/url-open/responsecode) != '200'">
                <error>
                    <xsl:text>Unrecognized response code "</xsl:text>
                    <xsl:value-of select="$test-result/url-open/responsecode" />
                    <xsl:text>".</xsl:text>
                    <xsl:if test="$test-result/url-open/errorstring">
                        <xsl:text> Error: "</xsl:text>
                        <xsl:value-of select="$test-result/url-open/errorstring" />
                        <xsl:text>"</xsl:text>
                    </xsl:if>
                </error>
            </xsl:when>
        </xsl:choose>

    </xsl:template>

</xsl:stylesheet>
