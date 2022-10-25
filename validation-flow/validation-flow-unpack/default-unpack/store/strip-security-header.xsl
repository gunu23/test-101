<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:wsse10="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
                xmlns:wsse-d12="http://schemas.xmlsoap.org/ws/2002/07/secext"
                xmlns:wsse-d13="http://schemas.xmlsoap.org/ws/2003/06/secext"
                exclude-result-prefixes="wsse10 wsse-d12 wsse-d13"
                version="1.0">

  <xsl:output method="xml"/>

  <xsl:template match="wsse10:Security | wsse-d12:Security | wsse-d13:Security">
    <!-- strip Security -->
  </xsl:template>

  <xsl:template match="@*">
    <xsl:copy/>
  </xsl:template>

  <xsl:template match="*">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
