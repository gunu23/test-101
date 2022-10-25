<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2013. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
    This is the stylesheet allows logging of messages.
-->

<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:env="http://www.w3.org/2003/05/soap-envelope"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpconfig="http://www.datapower.com/param/config"
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="dp date"
    exclude-result-prefixes="dp dpconfig date env"
>

    <!-- stylesheet summary -->
    <dp:summary xmlns="">
        <operation>xform</operation>
        <description>Log the input context.</description>
        <descriptionId>store.log.dpsummary.description</descriptionId>
    </dp:summary>

    <!-- URL of log server the message is sent to -->
    <xsl:param name="dpconfig:LogURL" select="''"/>
    <dp:param name="dpconfig:LogURL" type="dmURL" required="true" xmlns="">
        <display>Log Server URL</display>
        <displayId>store.log.param.LogURL.display</displayId>
        <description>The Log Server URL the log message is posted to</description>
        <descriptionId>store.log.param.LogURL.description</descriptionId>
    </dp:param>
    
    <!-- log category the message is logged under -->
    <xsl:param name="dpconfig:LogCategory" select="'xsltmsg'"/>
    <dp:param name="dpconfig:LogCategory" type="dmReference" reftype="LogLabel" xmlns="">
        <display>Log Category</display>
        <displayId>store.log.param.LogCategory.display</displayId>
        <description>The Log Category associated with the message</description>
        <descriptionId>store.log.param.LogCategory.description</descriptionId>
        <default>xsltmsg</default>
    </dp:param>
    
    <!-- log category the message is logged under -->
    <xsl:param name="dpconfig:LogPriority" select="'info'"/>
    <dp:param name="dpconfig:LogPriority" type="dmLogLevel" xmlns="">
        <display>Log Priority</display>
        <displayId>store.log.param.LogPriority.display</displayId>
        <description>The Log Priority associated with the message</description>
        <descriptionId>store.log.param.LogPriority.description</descriptionId>
        <default>info</default>
    </dp:param>
    
    
    <!-- main -->
    <xsl:template match="/">
        
        <!-- build log message -->
        <xsl:variable name="log-message">
            <env:Envelope>
                <env:Body>
                    <log-entry>
                        <date>
                            <xsl:value-of select="date:date()"/>
                        </date>
                        <time>
                            <xsl:value-of select="date:time()"/>
                        </time>
                        <transaction>
                            <xsl:value-of select="dp:variable('var://service/transaction-id')"/>                    
                        </transaction>
                        <type>
                            <xsl:value-of select="$dpconfig:LogCategory"/>
                        </type>
                        <level>
                            <xsl:value-of select="$dpconfig:LogPriority"/>                            
                        </level>
                        <message>
                            <xsl:copy-of select="."/>
                        </message>
                    </log-entry>
                </env:Body>
            </env:Envelope>        
        </xsl:variable>
        
        <!-- make soap call to remote Log server -->    
        <xsl:variable name="discard" select="dp:soap-call($dpconfig:LogURL, $log-message)"/>
        
        <!-- identity transform -->
        <xsl:copy-of select="."/>
    </xsl:template>

</xsl:stylesheet>
