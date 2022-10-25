<?xml version="1.0"?>
<!--
    Licensed Materials - Property of IBM
    IBM WebSphere DataPower Appliances
    Copyright IBM Corporation 2008,2013. All Rights Reserved.
    US Government Users Restricted Rights - Use, duplication or disclosure
    restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dp="http://www.datapower.com/extensions"
                xmlns:dpfunc="http://www.datapower.com/extensions/functions"
                xmlns:dpconfig="http://www.datapower.com/param/config"
                xmlns:func="http://exslt.org/functions" 
                extension-element-prefixes="dp func dpfunc"
                exclude-result-prefixes="dp dpfunc func dpconfig">

    <xsl:output method="xml" />

    <xsl:include href="store:///utilities.xsl"  dp:ignore-multiple="yes"/>

    <dp:summary xmlns="">
        <operation>mq</operation>
        <description>MQ Header Processing</description>
        <descriptionId>store.mq-header.dpsummary.description</descriptionId>
    </dp:summary>

    <!-- MQ header processing mode -->
    <xsl:param name="dpconfig:mq-processing-type" select="'request'" />
    <dp:param name="dpconfig:mq-processing-type" type="MQProcessingType" xmlns="">
        <display>MQ Processing Type</display>
        <displayId>store.mq-header.param.mq-processing-type.display</displayId>
        <description>Which type of header to process</description>
        <descriptionId>store.mq-header.param.mq-processing-type.description</descriptionId>

        <tab-override>basic</tab-override>
        <no-save-checkbox>true</no-save-checkbox>
        <format>radio</format>
        <default>request</default>

        <type name="MQProcessingType" base="enumeration">
            <value-list>
                <value name="request">
                    <display>request</display>
                    <displayId>store.mq-header.param.mq-processing-type.value1.display</displayId>
                    <description>MQ request header processing</description>
                    <descriptionId>store.mq-header.param.mq-processing-type.value1.description</descriptionId>
                </value>
                <value name="response">
                    <display>response</display>
                    <displayId>store.mq-header.param.mq-processing-type.value2.display</displayId>
                    <description>MQ response header processing</description>
                    <descriptionId>store.mq-header.param.mq-processing-type.value2.description</descriptionId>
                </value>
            </value-list>
        </type>
    </dp:param>

    <!-- request headers -->
    <xsl:param name="dpconfig:mq-processing-request" select="'mqmd-put'" />
    <dp:param name="dpconfig:mq-processing-request" type="MQProcessingRequest" xmlns="">
        <display>MQ Request Header Processing</display>
        <displayId>store.mq-header.param.mq-processing-request.display</displayId>
        <description>Which MQ request header to process</description>
        <descriptionId>store.mq-header.param.mq-processing-request.description</descriptionId>

        <tab-override>basic</tab-override>
        <format>list</format>
        <default>mqmd-put</default>

        <type name="MQProcessingRequest" base="enumeration">
            <value-list>
                <value name="mqmd-put">
                    <display>MQMD for PUT</display>
                    <displayId>store.mq-header.param.mq-processing-request.value1.display</displayId>
                    <description>Set the MQMD header when the Multi-Protocol Gateway puts
                    the request message to the backend</description>
                    <descriptionId>store.mq-header.param.mq-processing-request.value1.description</descriptionId>
                </value>
                <value name="mqmd-get">
                    <display>MQMD for GET</display>
                    <displayId>store.mq-header.param.mq-processing-request.value2.display</displayId>
                    <description>Set the MQMD header when the Multi-Protocol Gateway gets
                    the response message from the backend</description>
                    <descriptionId>store.mq-header.param.mq-processing-request.value2.description</descriptionId>
                </value>
            </value-list>
        </type>

        <ignored-when>
            <condition evaluation="property-does-not-equal">
                <parameter-name>dpconfig:mq-processing-type</parameter-name>
                <value>request</value>
            </condition>
        </ignored-when>
    </dp:param>

    <!-- response headers -->
    <xsl:param name="dpconfig:mq-processing-response" select="'reply-to-q'" />
    <dp:param name="dpconfig:mq-processing-response" type="MQProcessingResponse" xmlns="">
        <display>MQ Response Header Processing</display>
        <displayId>store.mq-header.param.mq-processing-response.display</displayId>
        <description>Which MQ response header to process</description>
        <descriptionId>store.mq-header.param.mq-processing-response.description</descriptionId>

        <tab-override>basic</tab-override>
        <format>list</format>
        <default>reply-to-q</default>

        <type name="MQProcessingResponse" base="enumeration">
            <value-list>
                <value name="reply-to-q">
                    <display>ReplyToQ</display>
                    <displayId>store.mq-header.param.mq-processing-response.value1.display</displayId>
                    <description>Set the name of reply queue</description>
                    <descriptionId>store.mq-header.param.mq-processing-response.value1.description</descriptionId>
                </value>
                <value name="reply-to-qm">
                    <display>ReplyToQM</display>
                    <displayId>store.mq-header.param.mq-processing-response.value2.display</displayId>
                    <description>Set the name of reply queue manager</description>
                    <descriptionId>store.mq-header.param.mq-processing-response.value2.description</descriptionId>
                </value>
                <value name="mqmd">
                    <display>MQMD</display>
                    <displayId>store.mq-header.param.mq-processing-response.value3.display</displayId>
                    <description>Set the MQMD header to be used when the Multi-Protocol Gateway
                    puts the response message to the front side</description>
                    <descriptionId>store.mq-header.param.mq-processing-response.value3.description</descriptionId>
                </value>
            </value-list>
        </type>

        <ignored-when>
            <condition evaluation="property-does-not-equal">
                <parameter-name>dpconfig:mq-processing-type</parameter-name>
                <value>response</value>
            </condition>
        </ignored-when>
    </dp:param>
    
    <xsl:param name="dpconfig:override-mqmd" select="'off'"/>
    <dp:param name="dpconfig:override-mqmd" type="dmToggle" xmlns="">
        <display>Override Existing MQMD</display>
        <displayId>store.mq-header.param.override-mqmd.display</displayId>
        <description>If this toggle is set to on, this action will override the values in the 
        MQMD header using the values specified in this action. If this toggle is set to off, 
        this action will replace the MQMD header using the values specified in this action and 
        default values.</description>
        <descriptionId>store.mq-header.param.override-mqmd.description</descriptionId>
        <tab-override>basic</tab-override>
        <default>off</default>
        
        <ignored-when>
            <condition evaluation="logical-or">
                <condition evaluation="logical-and">
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mq-processing-type</parameter-name>
                        <value>request</value>
                    </condition>
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mq-processing-request</parameter-name>
                        <value>mqmd-get</value>
                    </condition>
                </condition>
                <condition evaluation="logical-and">
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mq-processing-type</parameter-name>
                        <value>response</value>
                    </condition>
                    <condition evaluation="property-value-in-list">
                        <parameter-name>dpconfig:mq-processing-response</parameter-name>
                        <value>reply-to-q</value>
                        <value>reply-to-qm</value>
                    </condition>
                </condition>
            </condition>
        </ignored-when>
    </dp:param>

    <!-- MQMD field parameters -->
    <xsl:param name="dpconfig:mqmd-msg-id" select="''" />
    <dp:param name="dpconfig:mqmd-msg-id" type="dmString" xmlns="">
        <display>Message Id</display>
        <displayId>store.mq-header.param.mqmd-msg-id.display</displayId>
        <description>Message identifier (MsgId)</description>
        <descriptionId>store.mq-header.param.mqmd-msg-id.description</descriptionId>
        <tab-override>basic</tab-override>

        <ignored-when>
            <condition evaluation="logical-and">
                <condition evaluation="property-equals">
                    <parameter-name>dpconfig:mq-processing-type</parameter-name>
                    <value>response</value>
                </condition>
                <condition evaluation="property-value-in-list">
                    <parameter-name>dpconfig:mq-processing-response</parameter-name>
                    <value>reply-to-q</value>
                    <value>reply-to-qm</value>
                </condition>
            </condition>
        </ignored-when>
    </dp:param>

    <xsl:param name="dpconfig:mqmd-correl-id" select="''" />
    <dp:param name="dpconfig:mqmd-correl-id" type="dmString" xmlns="">
        <display>Correlation Id</display>
        <displayId>store.mq-header.param.mqmd-correl-id.display</displayId>
        <description>Correlation identifier (CorrelId)</description>
        <descriptionId>store.mq-header.param.mqmd-correl-id.description</descriptionId>
        <tab-override>basic</tab-override>

        <ignored-when>
            <condition evaluation="logical-and">
                <condition evaluation="property-equals">
                    <parameter-name>dpconfig:mq-processing-type</parameter-name>
                    <value>response</value>
                </condition>
                <condition evaluation="property-value-in-list">
                    <parameter-name>dpconfig:mq-processing-response</parameter-name>
                    <value>reply-to-q</value>
                    <value>reply-to-qm</value>
                </condition>
            </condition>
        </ignored-when>
    </dp:param>

    <xsl:param name="dpconfig:mqmd-ccsid" select="''" />
    <dp:param name="dpconfig:mqmd-ccsid" type="dmString" xmlns="">
        <display>Character Set Id</display>
        <displayId>store.mq-header.param.mqmd-ccsid.display</displayId>
        <description>Character set identifier of message data (CodedCharSetId)</description>
        <descriptionId>store.mq-header.param.mqmd-ccsid.description</descriptionId>
        <tab-override>basic</tab-override>

        <ignored-when>
            <condition evaluation="logical-or">
                <condition evaluation="logical-and">
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mq-processing-type</parameter-name>
                        <value>request</value>
                    </condition>
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mq-processing-request</parameter-name>
                        <value>mqmd-get</value>
                    </condition>
                </condition>
                <condition evaluation="logical-and">
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mq-processing-type</parameter-name>
                        <value>response</value>
                    </condition>
                    <condition evaluation="property-value-in-list">
                        <parameter-name>dpconfig:mq-processing-response</parameter-name>
                        <value>reply-to-q</value>
                        <value>reply-to-qm</value>
                    </condition>
                </condition>
            </condition>
        </ignored-when>
    </dp:param>

    <xsl:param name="dpconfig:mqmd-format" select="''" />
    <dp:param name="dpconfig:mqmd-format" type="dmString" xmlns="">
        <display>Format Name</display>
        <displayId>store.mq-header.param.mqmd-format.display</displayId>
        <description>Format name of message data (Format)</description>
        <descriptionId>store.mq-header.param.mqmd-format.description</descriptionId>
        <tab-override>basic</tab-override>

        <ignored-when>
            <condition evaluation="logical-or">
                <condition evaluation="logical-and">
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mq-processing-type</parameter-name>
                        <value>request</value>
                    </condition>
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mq-processing-request</parameter-name>
                        <value>mqmd-get</value>
                    </condition>
                </condition>
                <condition evaluation="logical-and">
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mq-processing-type</parameter-name>
                        <value>response</value>
                    </condition>
                    <condition evaluation="property-value-in-list">
                        <parameter-name>dpconfig:mq-processing-response</parameter-name>
                        <value>reply-to-q</value>
                        <value>reply-to-qm</value>
                    </condition>
                </condition>
            </condition>
        </ignored-when>
    </dp:param>

    <xsl:param name="dpconfig:mqmd-reply-to-q-type" select="'specified'" />
    <dp:param name="dpconfig:mqmd-reply-to-q-type" type="ReplyToQType" xmlns="">
        <display>ReplyToQ Processing Type</display>
        <displayId>store.mq-header.param.mqmd-reply-to-q-type.display</displayId>
        <description>How the ReplyToQ field is processed</description>
        <descriptionId>store.mq-header.param.mqmd-reply-to-q-type.description</descriptionId>
        <default>specified</default>
        <tab-override>basic</tab-override>
        <type name="ReplyToQType" base="enumeration">
            <value-list>
                <value name="empty">
                    <display>Empty</display>
                    <displayId>store.mq-header.param.mqmd-reply-to-q-type.value1.display</displayId>
                    <description>Use empty reply queue name. This will make the 
                    Multi-Protocol Gateway to not send the response</description>
                    <descriptionId>store.mq-header.param.mqmd-reply-to-q-type.value1.description</descriptionId>
                </value>
                <value name="specified">
                    <display>Specified</display>
                    <displayId>store.mq-header.param.mqmd-reply-to-q-type.value2.display</displayId>
                    <description>Specify the name of reply queue to be used</description>
                    <descriptionId>store.mq-header.param.mqmd-reply-to-q-type.value2.description</descriptionId>
                </value>
            </value-list>
        </type>

        <ignored-when>
            <condition evaluation="logical-or">
                <condition evaluation="property-does-not-equal">
                    <parameter-name>dpconfig:mq-processing-response</parameter-name>
                    <value>reply-to-q</value>
                </condition>
                <condition evaluation="property-does-not-equal">
                    <parameter-name>dpconfig:mq-processing-type</parameter-name>
                    <value>response</value>
                </condition>
            </condition>
        </ignored-when>

    </dp:param>

    <xsl:param name="dpconfig:mqmd-reply-to-q" select="''" />
    <dp:param name="dpconfig:mqmd-reply-to-q" type="dmString" xmlns="">
        <display>ReplyToQ</display>
        <displayId>store.mq-header.param.mqmd-reply-to-q.display</displayId>
        <description>Name of reply queue (ReplyToQ)</description>
        <descriptionId>store.mq-header.param.mqmd-reply-to-q.description</descriptionId>
        <tab-override>basic</tab-override>

        <ignored-when>
            <condition evaluation="logical-or">
                <condition evaluation="logical-and">
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mq-processing-type</parameter-name>
                        <value>request</value>
                    </condition>
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mq-processing-request</parameter-name>
                        <value>mqmd-get</value>
                    </condition>
                </condition>
                <condition evaluation="logical-and">
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mq-processing-type</parameter-name>
                        <value>response</value>
                    </condition>
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mq-processing-response</parameter-name>
                        <value>reply-to-qm</value>
                    </condition>
                </condition>
                <condition evaluation="logical-and">
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mq-processing-response</parameter-name>
                        <value>reply-to-q</value>
                    </condition>
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mqmd-reply-to-q-type</parameter-name>
                        <value>empty</value>
                    </condition>
                </condition>
            </condition>
        </ignored-when>
        <required-when>
            <condition evaluation="logical-and">
                <condition evaluation="property-equals">
                    <parameter-name>dpconfig:mq-processing-type</parameter-name>
                    <value>response</value>
                </condition>
                <condition evaluation="property-equals">
                    <parameter-name>dpconfig:mq-processing-response</parameter-name>
                    <value>reply-to-q</value>
                </condition>
                <condition evaluation="property-equals">
                    <parameter-name>dpconfig:mqmd-reply-to-q-type</parameter-name>
                    <value>specified</value>
                </condition>
            </condition>
        </required-when>
        
    </dp:param>

    <xsl:param name="dpconfig:mqmd-reply-to-qm-type" select="'specified'" />
    <dp:param name="dpconfig:mqmd-reply-to-qm-type" type="ReplyToQMType" xmlns="">
        <display>ReplyToQM Processing Type</display>
        <displayId>store.mq-header.param.mqmd-reply-to-qm-type.display</displayId>
        <description>How the ReplyToQM response header is processed</description>
        <descriptionId>store.mq-header.param.mqmd-reply-to-qm-type.description</descriptionId>
        <default>specified</default>
        <tab-override>basic</tab-override>
        <type name="ReplyToQMType" base="enumeration">
            <value-list>
                <value name="empty">
                    <display>Empty</display>
                    <displayId>store.mq-header.param.mqmd-reply-to-qm-type.value1.display</displayId>
                    <description>Use empty reply queue manager name. This will make the 
                    Multi-Protocol Gateway to use the default queue manager from the MQ
                    front side handler and ignore the ReplyToQMgr value in the request 
                    header</description>
                    <descriptionId>store.mq-header.param.mqmd-reply-to-qm-type.value1.description</descriptionId>
                </value>
                <value name="specified">
                    <display>Specified</display>
                    <displayId>store.mq-header.param.mqmd-reply-to-qm-type.value2.display</displayId>
                    <description>Specify the name of reply queue manager</description>
                    <descriptionId>store.mq-header.param.mqmd-reply-to-qm-type.value2.description</descriptionId>
                </value>
            </value-list>
        </type>

        <ignored-when>
            <condition evaluation="logical-or">
                <condition evaluation="property-does-not-equal">
                    <parameter-name>dpconfig:mq-processing-type</parameter-name>
                    <value>response</value>
                </condition>
                <condition evaluation="property-does-not-equal">
                    <parameter-name>dpconfig:mq-processing-response</parameter-name>
                    <value>reply-to-qm</value>
                </condition>
            </condition>
        </ignored-when>
    </dp:param>

    <xsl:param name="dpconfig:mqmd-reply-to-qm" select="''" />
    <dp:param name="dpconfig:mqmd-reply-to-qm" type="dmString" xmlns="">
        <display>ReplyToQMgr</display>
        <displayId>store.mq-header.param.mqmd-reply-to-qm.display</displayId>
        <description>Name of reply queue manager (ReplyToQMgr)</description>
        <descriptionId>store.mq-header.param.mqmd-reply-to-qm.description</descriptionId>
        <tab-override>basic</tab-override>

        <ignored-when>
            <condition evaluation="logical-or">
                <condition evaluation="logical-and">
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mq-processing-type</parameter-name>
                        <value>request</value>
                    </condition>
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mq-processing-request</parameter-name>
                        <value>mqmd-get</value>
                    </condition>
                </condition>
                <condition evaluation="logical-and">
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mq-processing-type</parameter-name>
                        <value>response</value>
                    </condition>
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mq-processing-response</parameter-name>
                        <value>reply-to-q</value>
                    </condition>
                </condition>
                <condition evaluation="logical-and">
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mq-processing-response</parameter-name>
                        <value>reply-to-qm</value>
                    </condition>
                    <condition evaluation="property-equals">
                        <parameter-name>dpconfig:mqmd-reply-to-qm-type</parameter-name>
                        <value>empty</value>
                    </condition>
                </condition>
            </condition>
        </ignored-when>

        <required-when>
            <condition evaluation="logical-and">
                <condition evaluation="property-equals">
                    <parameter-name>dpconfig:mq-processing-type</parameter-name>
                    <value>response</value>
                </condition>
                <condition evaluation="property-equals">
                    <parameter-name>dpconfig:mq-processing-response</parameter-name>
                    <value>reply-to-qm</value>
                </condition>
                <condition evaluation="property-equals">
                    <parameter-name>dpconfig:mqmd-reply-to-qm-type</parameter-name>
                    <value>specified</value>
                </condition>
            </condition>
        </required-when>


    </dp:param>




    <xsl:template match="/">
        <xsl:choose>
            <!-- header processing for request direction -->
            <xsl:when test="$dpconfig:mq-processing-type = 'request'">
                <xsl:choose>
                    <xsl:when test="$dpconfig:mq-processing-request = 'mqmd-put'">
                        <xsl:variable name="msg-header-nodeset" select="dpfunc:mq-request-header('MQMD')" />
                        <xsl:choose>
                            <!-- to merge nodeset, MQMD header should be present -->
                            <xsl:when test="$dpconfig:override-mqmd = 'on' and $msg-header-nodeset">
                                <!-- get nodesets from action and message header -->
                                <xsl:variable name="action-nodeset">
                                    <xsl:call-template name="gen-mqmd-nodeset">
                                        <xsl:with-param name="serialize" select="false()" />
                                    </xsl:call-template>
                                </xsl:variable>

                                <!-- merge the nodesets -->
                                <xsl:variable name="merged-nodeset">
                                    <xsl:call-template name="merge-nodeset">
                                        <xsl:with-param name="action-nodeset" select="$action-nodeset"/>
                                        <xsl:with-param name="msg-header-nodeset" select="$msg-header-nodeset" />
                                    </xsl:call-template>
                                </xsl:variable>

                                <!-- set request header -->
                                <dp:set-request-header name="'MQMD'" value="$merged-nodeset" />
                                
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="mqmd-nodeset">
                                    <xsl:call-template name="gen-mqmd-nodeset">
                                        <xsl:with-param name="serialize" select="true()" />
                                    </xsl:call-template>
                                </xsl:variable>
                                <dp:set-request-header name="'X-MQMD-PUT'" value="$mqmd-nodeset" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$dpconfig:mq-processing-request = 'mqmd-get'">
                        <xsl:variable name="mqmd-nodeset">
                            <xsl:call-template name="gen-mqmd-nodeset-get" />
                        </xsl:variable>
                        <dp:set-request-header name="'X-MQMD-GET'" value="$mqmd-nodeset" />
                    </xsl:when>
                </xsl:choose>
            </xsl:when>

            <!-- header processing for response direction -->
            <xsl:when test="$dpconfig:mq-processing-type = 'response'">
                <xsl:choose>
                    <xsl:when test="$dpconfig:mq-processing-response = 'reply-to-q'">
                        <xsl:choose>
                            <xsl:when test="$dpconfig:mqmd-reply-to-q-type = 'empty'">
                                <dp:set-response-header name="'ReplyToQ'" value="''" />
                            </xsl:when>
                            <xsl:when test="$dpconfig:mqmd-reply-to-q-type = 'specified'">
                                <dp:set-response-header name="'ReplyToQ'"
                                                        value="$dpconfig:mqmd-reply-to-q" />
                            </xsl:when>
                            <xsl:otherwise><!-- do nothing --></xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$dpconfig:mq-processing-response = 'reply-to-qm'">
                        <xsl:choose>
                            <xsl:when test="$dpconfig:mqmd-reply-to-qm-type = 'empty'">
                                <dp:set-response-header name="'ReplyToQM'" value="''" />
                            </xsl:when>
                            <xsl:when test="$dpconfig:mqmd-reply-to-qm-type = 'specified'">
                                <dp:set-response-header name="'ReplyToQM'"
                                                        value="$dpconfig:mqmd-reply-to-qm" />
                            </xsl:when>
                            <xsl:otherwise><!-- do nothing --></xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$dpconfig:mq-processing-response = 'mqmd'">
                        <xsl:variable name="msg-header-nodeset" select="dpfunc:mq-response-header('MQMD')" />
                        <xsl:choose>
                            <xsl:when test="$dpconfig:override-mqmd = 'on' and $msg-header-nodeset">
                                <!-- get nodesets from action and message header -->
                                <xsl:variable name="action-nodeset">
                                    <xsl:call-template name="gen-mqmd-nodeset">
                                        <xsl:with-param name="serialize" select="false()" />
                                    </xsl:call-template>
                                </xsl:variable>
                                
                                <!-- merge nodesets -->
                                 <xsl:variable name="merged-nodeset">
                                    <xsl:call-template name="merge-nodeset">
                                        <xsl:with-param name="action-nodeset" select="$action-nodeset"/>
                                        <xsl:with-param name="msg-header-nodeset" select="$msg-header-nodeset" />
                                    </xsl:call-template>
                                </xsl:variable>
        
                                <!-- set response header -->
                                <dp:set-response-header name="'MQMD'" value="$merged-nodeset" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="mqmd-nodeset">
                                    <xsl:call-template name="gen-mqmd-nodeset">
                                        <xsl:with-param name="serialize" select="true()" />
                                    </xsl:call-template>
                                </xsl:variable>
                                <dp:set-response-header name="'MQMD'" value="$mqmd-nodeset" />
                            </xsl:otherwise>
                        </xsl:choose>
                                
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
        </xsl:choose>

        <!-- output the entire message body -->
        <xsl:copy-of select="." />

    </xsl:template>

    <xsl:template name="gen-mqmd-nodeset">
        <xsl:param name="serialize" />
        <xsl:variable name="nodeset">
            <MQMD>
                <xsl:if test="$dpconfig:mqmd-msg-id">
                    <MsgId>
                        <xsl:value-of select="$dpconfig:mqmd-msg-id" />
                    </MsgId>
                </xsl:if>
                <xsl:if test="$dpconfig:mqmd-correl-id">
                    <CorrelId>
                        <xsl:value-of select="$dpconfig:mqmd-correl-id" />
                    </CorrelId>
                </xsl:if>
                <xsl:if test="$dpconfig:mqmd-ccsid">
                    <CodedCharSetId>
                        <xsl:value-of select="$dpconfig:mqmd-ccsid" />
                    </CodedCharSetId>
                </xsl:if>
                <xsl:if test="$dpconfig:mqmd-format">
                    <Format>
                        <xsl:value-of select="$dpconfig:mqmd-format" />
                    </Format>
                </xsl:if>
                <xsl:if test="$dpconfig:mqmd-reply-to-q">
                    <ReplyToQ>
                        <xsl:value-of select="$dpconfig:mqmd-reply-to-q" />
                    </ReplyToQ>
                </xsl:if>
                <xsl:if test="$dpconfig:mqmd-reply-to-qm">
                    <ReplyToQMgr>
                        <xsl:value-of select="$dpconfig:mqmd-reply-to-qm" />
                    </ReplyToQMgr>
                </xsl:if>
            </MQMD>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$serialize">
                <dp:serialize select="$nodeset" omit-xml-decl="yes"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$nodeset" />
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>

    <xsl:template name="gen-mqmd-nodeset-get">
        <xsl:variable name="nodeset">
            <MQMD>
                <xsl:if test="$dpconfig:mqmd-msg-id">
                    <MsgId>
                        <xsl:value-of select="$dpconfig:mqmd-msg-id" />
                    </MsgId>
                </xsl:if>
                <xsl:if test="$dpconfig:mqmd-correl-id">
                    <CorrelId>
                        <xsl:value-of select="$dpconfig:mqmd-correl-id" />
                    </CorrelId>
                </xsl:if>
            </MQMD>
        </xsl:variable>
        <dp:serialize select="$nodeset" omit-xml-decl="yes"/>
    </xsl:template>

    <xsl:template name="merge-nodeset">
        <xsl:param name="action-nodeset" />
        <xsl:param name="msg-header-nodeset" />
    
        <xsl:variable name="action-nodeset-names">
            <xsl:for-each select="$action-nodeset/MQMD/*">
                <xsl:copy-of select="concat(name(), ' ')"/>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:variable name="merged-nodeset">
            <MQMD>
                <xsl:for-each select="$action-nodeset/MQMD/*">
                    <xsl:copy-of select="." />
                </xsl:for-each>
                <xsl:for-each select="$msg-header-nodeset/MQMD/*[not(contains($action-nodeset-names, name()))]">
                    <xsl:copy-of select="." />
                </xsl:for-each>
            </MQMD>
        </xsl:variable>
        
        <dp:serialize select="$merged-nodeset" omit-xml-decl="yes"/>
        
    </xsl:template>

</xsl:stylesheet>
