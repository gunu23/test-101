<?xml version="1.0" encoding="UTF-8"?>
<!--

DataPower XB60 B2B Document Routing Preprocessor Stylesheet

Licensed Materials - Property of IBM
IBM WebSphere DataPower Appliances
Copyright IBM Corporation 2008,2009. All Rights Reserved.
US Government Users Restricted Rights - Use, duplication or disclosure
restricted by GSA ADP Schedule Contract with IBM Corp.

-->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dp="http://www.datapower.com/extensions"
                extension-element-prefixes="dp">
    <xsl:template match="/">
        <!-- Gather whatever information seems useful here.  For instance:
        
        <xsl:variable name="content-type"
                      select="dp:variable('var://service/content-type')"/>
        <xsl:variable name="protocol"
                      select="dp:variable('var://service/protocol')"/>
        <xsl:variable name="path"
                      select="dp:variable('var://service/URI')"/>

        For inbound AS2/AS3, the partner ID can be determined from the
        protocol headers and accessed:
        
        <xsl:variable name="sending-partner-id"
                      select="dp:variable('var://service/b2b-partner-from')"/>
        <xsl:variable name="receiving-partner-id"
                      select="dp:variable('var://service/b2b-partner-to')"/>
        -->
         
        <!-- Then make a decision on the message type and trading partner
        IDs.  If this stylesheet does not set the variable
        var://service/b2b-doc-type then the message type will be
        autodetected.  If this stylesheet does not set b2b-partner-from and
        b2b-partner-to then they will be extracted from X12, EDIFACT, or
        XML content as appropriate.  This stylesheet *must* set both
        partner variables for binary messages, there is no way otherwise
        to determine their values. -->
        <xsl:choose>
            <!-- All messages received via MQ are binary, with fixed
            partner IDs.
            <xsl:when test="$protocol='mq'">
                <dp:set-variable name="'var://service/b2b-doc-type'"
                                 value="'binary'"/>
                <dp:set-variable name="'var://service/b2b-partner-from'"
                                 value="'12345678'"/>
                <dp:set-variable name="'var://service/b2b-partner-to'"
                                 value="'87654321'"/>
            </xsl:when> -->
            <xsl:otherwise>
                <!-- By default, do nothing.  This will autodetect the
                message type, but binary messages will fail for lack of
                partner IDs. -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet> 
