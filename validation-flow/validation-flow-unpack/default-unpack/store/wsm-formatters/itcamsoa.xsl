<?xml version="1.0" encoding="UTF-8"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2012. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
/*
 *   Copyright (c) 2005 DataPower Technology, Inc. All Rights Reserved
 *
 * THIS IS UNPUBLISHED PROPRIETARY TRADE SECRET SOURCE CODE OF DataPower
 * Technology, Inc.
 *
 * The copyright above and this notice must be preserved in all copies of
 * the source code. The copyright notice above does not evidence any actual
 * or intended publication of such source code. This source code may not be
 * copied, compiled, disclosed, distributed, demonstrated or licensed except
 * as expressly authorized by DataPower Technology, Inc.
 *
 * Name:           itcamsoa.xsl
 * Description:    Implementation of transaction accounting message formats
                   specific to ITCAM for SOA V1 integration.
 * Author:         Brian Del Vecchio
 *
 */
-->

<!DOCTYPE xsl:stylesheet [

    <!ENTITY % ws-management SYSTEM "store:///dp/ws-management.dtd"> %ws-management;
    <!ENTITY % dp-wsmgmt     SYSTEM "store:///dp/dp-wsmgmt.dtd"> %dp-wsmgmt;

    <!ENTITY crlf    "&#xA;">

]>

<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 

    xmlns:func="http://exslt.org/functions"
    xmlns:date="http://exslt.org/dates-and-times"

    xmlns:dp="http://www.datapower.com/schemas/management"
    xmlns:dpe="http://www.datapower.com/extensions" 
    xmlns:dpc="http://www.datapower.com/schemas/management"
    xmlns:dple="http://www.datapower.com/extensions/local" 
    xmlns:dpt="http://www.datapower.com/schemas/transactions"

    xmlns:env="http://www.w3.org/2003/05/soap-envelope"
    xmlns:env11="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing"  
    xmlns:wse="http://schemas.xmlsoap.org/ws/2004/08/eventing"  
    xmlns:wsen="http://schemas.xmlsoap.org/ws/2004/09/enumeration"  
    xmlns:wsman="http://schemas.xmlsoap.org/ws/2005/02/management"  
    xmlns:wsmancat="http://schemas.xmlsoap.org/ws/2005/02/wsmancat"

    exclude-result-prefixes="func date dpc dpe dple dpt wsa wse wsen wsman wsmancat"
    extension-element-prefixes="dpc dpe date">

    <xsl:include href="store:///dp/wsm-library.xsl" dpe:ignore-multiple="yes"/>
    <xsl:include href="store:///dp/msgcat/mplane.xml.xsl" dp:ignore-multiple="yes"/>

    <xsl:variable name="Debug" select="dpe:variable('var://system/ws-mgmt/debug')"/>

    <!--
       Available Context variables are:
         var://context/wsm/verbosity: 'Content' element from Pull Request
         var://context/wsm/events: transaction accounting message
    -->

    <xsl:template match="/">

        <xsl:variable name="verbosity2"
                 select="dpe:variable('var://context/wsm/verbosity')"/>

        <xsl:variable name="verbosity">
            <xsl:choose>
                <xsl:when test="$verbosity2=''">
	            <xsl:value-of select="'full'"/>
                </xsl:when>
                <xsl:otherwise>
	            <xsl:value-of select="$verbosity2"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="events"
                 select="dpe:variable('var://context/wsm/events')"/>

        <xsl:message dp:priority="debug" dpe:id="{$DPLOG_MPLANE_ITCAMSOA_VERBOSITY}">
            <dpe:with-param value="{$verbosity}"/>
        </xsl:message>

        <dpt:transaction-log
            records="{count($events/dpt:transaction) + count($events/*/dpt:backend-message)}"
            format="text" version="0.9">
            <xsl:text disable-output-escaping="yes">&crlf;</xsl:text>
            <xsl:apply-templates mode="itcamsoa-csv" select="$events/*">
                <xsl:with-param name="verbosity" select="$verbosity"/>
            </xsl:apply-templates>
            <xsl:text disable-output-escaping="yes">&crlf;</xsl:text>
       </dpt:transaction-log>

    </xsl:template>

    <xsl:template mode="itcamsoa-csv" match="dpt:transaction">
        <xsl:param name="verbosity"/>

        <xsl:apply-templates mode="itcamsoa-front" select=".">
            <xsl:with-param name="verbosity" select="$verbosity"/>
        </xsl:apply-templates>
        <!-- generate one record for each backend-message -->
        <xsl:apply-templates mode="itcamsoa-back" select="dpt:backend-message">
            <xsl:with-param name="verbosity" select="$verbosity"/>
        </xsl:apply-templates>

    </xsl:template>

    <xsl:template mode="itcamsoa-front" match="dpt:transaction">
        <xsl:param name="verbosity"/>

        <xsl:text>1,</xsl:text>

        <!-- +++bdv: seconds to milliseconds -->
        <xsl:value-of select="concat(dpt:start-time/@utc, '000')"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="(dpt:front-latency-ms + dpt:back-latency-ms)"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="dpt:transaction-id"/>
        <xsl:text>,</xsl:text>

        <xsl:text>HTTP,</xsl:text>

        <xsl:text>"""</xsl:text>
        <xsl:value-of select="dpt:request-url"/>
        <xsl:text>"""</xsl:text>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="dpt:service-port"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="dpt:ws-operation"/>
        <xsl:text>,</xsl:text>

        <xsl:choose>
            <xsl:when test="(dpt:is-one-way=1 or dpt:is-one-way=true)">
                <xsl:text>1,</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>2,</xsl:text>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:value-of select="dpt:request-size"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="dpt:response-size"/>
        <xsl:text>,</xsl:text>

        <!-- +++bdv: correlator info -->
        <xsl:text>,,</xsl:text>

        <!-- +++bdv: client hostname -->
        <xsl:text>,</xsl:text>

        <xsl:value-of select="dpt:client"/>
        <xsl:text>,</xsl:text>

        <!-- fault code -->
        <xsl:if test="dpt:fault-code">
            <xsl:text>"</xsl:text>
            <xsl:value-of select="dpt:fault-code"/>
            <xsl:text>"</xsl:text>
        </xsl:if>
        <xsl:text>,</xsl:text>

        <!-- fault string -->
        <xsl:if test="dpt:fault-message">
            <xsl:text>"</xsl:text>
            <xsl:value-of select="dpt:fault-message"/>
            <xsl:text>"</xsl:text>
        </xsl:if>
        <xsl:text>,</xsl:text>

        <xsl:apply-templates mode="msg-escape" select="dpt:request-message">
            <xsl:with-param name="verbosity" select="$verbosity"/>
        </xsl:apply-templates>
        <xsl:text>,</xsl:text>
        <xsl:apply-templates mode="msg-escape" select="dpt:response-message">
            <xsl:with-param name="verbosity" select="$verbosity"/>
        </xsl:apply-templates>

        <xsl:text>,</xsl:text>
        <xsl:value-of select="dpt:ws-client-id"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="dpt:ws-clientid-extmthd"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="dpt:ws-correlator-version"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="dpt:ws-correlator-sfid"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="dpt:ws-client-socode"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="dpt:ws-dp-socode"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="dpt:ws-server-socode"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="dpt:ws-client-hopcount"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="dpt:ws-server-hopcount"/>

        <xsl:text disable-output-escaping="yes">&crlf;</xsl:text>
        
    </xsl:template>

    <xsl:template mode="itcamsoa-back" match="dpt:backend-message">
        <xsl:param name="verbosity"/>

        <xsl:text>2,</xsl:text>

        <!-- +++bdv: seconds to milliseconds -->
        <xsl:value-of select="concat(../dpt:start-time/@utc, '000')"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="../dpt:back-latency-ms"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="../dpt:transaction-id"/>
        <xsl:text>,</xsl:text>

        <xsl:text>HTTP,</xsl:text>

        <xsl:text>"""</xsl:text>
        <xsl:value-of select="dpt:backend-url"/>
        <xsl:text>"""</xsl:text>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="../dpt:service-port"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="../dpt:ws-operation"/>
        <xsl:text>,</xsl:text>

        <xsl:choose>
            <xsl:when test="(../dpt:is-one-way=1 or ../dpt:is-one-way=true)">
                <xsl:text>1,</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>2,</xsl:text>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:value-of select="dpt:request-size"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="dpt:response-size"/>
        <xsl:text>,</xsl:text>

        <!-- +++bdv: correlator info -->
        <xsl:text>,,</xsl:text>

        <xsl:value-of select="dpt:backend-host"/>
        <xsl:text>,</xsl:text>

        <!-- +++bdv: backend address -->
        <xsl:text>,</xsl:text>

        <!-- +++bdv: fault code -->
        <xsl:text>,</xsl:text>

        <!-- +++bdv: fault string -->
        <xsl:text>,</xsl:text>

        <xsl:apply-templates mode="msg-escape" select="dpt:request-message">
            <xsl:with-param name="verbosity" select="$verbosity"/>
        </xsl:apply-templates>
        <xsl:text>,</xsl:text>

        <xsl:apply-templates mode="msg-escape" select="dpt:response-message">
            <xsl:with-param name="verbosity" select="$verbosity"/>
        </xsl:apply-templates>

        <xsl:text>,</xsl:text>
        <xsl:value-of select="../dpt:ws-client-id"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="../dpt:ws-clientid-extmthd"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="../dpt:ws-correlator-version"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="../dpt:ws-correlator-sfid"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="../dpt:ws-client-socode"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="../dpt:ws-dp-socode"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="../dpt:ws-server-socode"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="../dpt:ws-client-hopcount"/>
        <xsl:text>,</xsl:text>

        <xsl:value-of select="../dpt:ws-server-hopcount"/>

        <xsl:text disable-output-escaping="yes">&crlf;</xsl:text>

    </xsl:template>

    <xsl:template match="dpt:request-message|dpt:response-message" mode="msg-escape">
        <xsl:param name="verbosity"/>

        <xsl:if test="not($verbosity = 'none')">
            
            <xsl:choose>
                <xsl:when test="($verbosity = 'headers')">
                    <!-- extract SOAP 1.2 or 1.1 headers from message -->
                    <xsl:choose>
                        <xsl:when test="env:Envelope/env:Header">
                            
                            <xsl:variable name="temp">
                                <dpe:serialize select="(env:Envelope/env:Header)"/>
                            </xsl:variable>
                            <xsl:text>"""</xsl:text>
                            <xsl:value-of select="translate($temp, '&#x0D;&#x0A;', ' ')"/>
                            <xsl:text>"""</xsl:text>
                        </xsl:when>
                        <xsl:when test="env11:Envelope/env11:Header">
                            <xsl:variable name="temp">
                                <dpe:serialize select="(env11:Envelope/env11:Header)"/>
                            </xsl:variable>
                            <xsl:text>"""</xsl:text>
                            <xsl:value-of select="translate($temp, '&#x0D;&#x0A;', ' ')"/>
                            <xsl:text>"""</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="($verbosity = 'full')">
                    <xsl:variable name="temp">
                        <dpe:serialize select="*"/>
                    </xsl:variable>
                    <xsl:text>"""</xsl:text>
                    <xsl:value-of select="translate($temp, '&#x0D;&#x0A;', ' ')"/>
                    <xsl:text>"""</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message dp:priority="debug" dpe:id="{$DPLOG_MPLANE_ITCAMSOA_UN_VERBOSITY}">
                        <dpe:with-param value="{$verbosity}"/>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
            

        </xsl:if>

    </xsl:template>

    <xsl:template mode="itcamsoa-csv" match="text()"/>
    <xsl:template mode="itcamsoa-front" match="text()"/>
    <xsl:template mode="itcamsoa-back" match="text()"/>

</xsl:stylesheet>
