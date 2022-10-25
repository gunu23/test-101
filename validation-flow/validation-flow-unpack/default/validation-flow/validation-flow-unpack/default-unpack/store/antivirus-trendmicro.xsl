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
        <description>TrendMicro Virus Scanning</description>
        <descriptionId>store.antivirus-trendmicro.dpsummary.description</descriptionId>
    </dp:summary>


    <xsl:include href="antivirus.xsl"  dp:ignore-multiple="yes"/>

    <!-- the core of the tests. -->
    <xsl:template name="icap-test">
        <xsl:param name="icap-data" />
        <xsl:param name="icap-data-type" />

        <xsl:variable name="httpHeaders">
            <header name="X-ICAP-Method">Request</header>
            <header name="Host">127.0.0.1</header>
            <header name="Allow">204</header>
            <header name="Encapsulated"><xsl:value-of select="concat('req-hdr=0, req-body=60', $eol, $eol, 'POST /0 HTTP/1.1', $eol, 'Host: test', $eol, 'Transfer-Encoding: chunked')" /></header>
        </xsl:variable>

        <xsl:variable name="test-result">
            <dp:url-open target="{$icap-url}" response="responsecode-ignore" data-type="{$icap-data-type}" http-headers="$httpHeaders">
                <xsl:copy-of select="$icap-data" />
            </dp:url-open>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="string($test-result/url-open/responsecode) = '403' or string($test-result/url-open/responsecode) = '200'">
                <virus />
            </xsl:when>
            <xsl:when test="string($test-result/url-open/responsecode) != '204'">
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
