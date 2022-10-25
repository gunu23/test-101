<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2015. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dp="http://www.datapower.com/extensions"
                xmlns:dpconfig="http://www.datapower.com/param/config"
                xmlns:dpfunc="http://www.datapower.com/extensions/functions"

                xmlns:func="http://exslt.org/functions"
                xmlns:dyn="http://exslt.org/dynamic"
                xmlns:regexp="http://exslt.org/regular-expressions"
                xmlns:exsl="http://exslt.org/common"
                xmlns:set="http://exslt.org/sets"

                extension-element-prefixes="dp dyn func regexp exsl set"
                exclude-result-prefixes="dp dpconfig dyn dpfunc func regexp exsl set"
                >

<xsl:output method="xml" />

    <xsl:include href="store:///dp/msgcat/xslt.xml.xsl" dp:ignore-multiple="yes"/>

    <dp:summary xmlns="">
        <operation>antivirus</operation>
        <description>Virus Scanning</description>
        <descriptionId>store.antivirus.dpsummary.description</descriptionId>
    </dp:summary>

    <xsl:variable name="eol" select="'&#13;&#10;'" />

    <!-- AV Processing Mode -->
    <xsl:param name="dpconfig:AntiVirusProcessingMode" select="'entire-message'" />
    <dp:param name="dpconfig:AntiVirusProcessingMode" type="AntiVirusProcessingModeType" xmlns="">
        <display>Antivirus Scan Type</display>
        <displayId>store.antivirus.param.AntiVirusProcessingMode.display</displayId>
        <description>Select the type of antivirus scan.</description>
        <descriptionId>store.antivirus.param.AntiVirusProcessingMode.description</descriptionId>

        <tab-override>basic</tab-override>
        <refresh-on-change>true</refresh-on-change>
        <no-save-checkbox>true</no-save-checkbox>
        <format>radio</format>

        <required-when><condition evaluation="logical-true" /></required-when>
        <default>entire-message</default>

        <type name="AntiVirusProcessingModeType" base="enumeration" displayOrder="fixed">
            <value-list>
                <value name="entire-message">
                    <display>Scan Entire Message</display>
                    <displayId>store.antivirus.param.AntiVirusProcessingMode.value1.display</displayId>
                    <description>Scan both the message body and attachments.</description>
                    <descriptionId>store.antivirus.param.AntiVirusProcessingMode.value1.description</descriptionId>
                </value>
                <value name="attachments">
                    <display>Scan All Attachments</display>
                    <displayId>store.antivirus.param.AntiVirusProcessingMode.value2.display</displayId>
                    <description>Scan all message attachments.</description>
                    <descriptionId>store.antivirus.param.AntiVirusProcessingMode.value2.description</descriptionId>
                </value>
                <value name="attachment-content-type">
                    <display>Scan Attachments by Content Type</display>
                    <displayId>store.antivirus.param.AntiVirusProcessingMode.value3.display</displayId>
                    <description>Scan every attachment with a specified content type.</description>
                    <descriptionId>store.antivirus.param.AntiVirusProcessingMode.value3.description</descriptionId>
                </value>
                <value name="attachment-uri">
                    <display>Scan Attachments by URI</display>
                    <displayId>store.antivirus.param.AntiVirusProcessingMode.value4.display</displayId>
                    <description>Scan attachments with a specified uri.</description>
                    <descriptionId>store.antivirus.param.AntiVirusProcessingMode.value4.description</descriptionId>
                </value>
                <value name="xpath">
                    <display>Scan by XPath Expression</display>
                    <displayId>store.antivirus.param.AntiVirusProcessingMode.value5.display</displayId>
                    <description>Scan a partial message, selected by XPath expression.</description>
                    <descriptionId>store.antivirus.param.AntiVirusProcessingMode.value5.description</descriptionId>
                </value>
            </value-list>
        </type>
    </dp:param>

    <!-- XPath Selection -->
    <xsl:param name="dpconfig:AntiVirusXPathSelection" select="'/'" />
    <dp:param name="dpconfig:AntiVirusXPathSelection" type="dmXPathExpr" xmlns="">
        <display>XPath Expression</display>
        <displayId>store.antivirus.param.AntiVirusXPathSelection.display</displayId>
        <description>XPath expression defining the partial message to evaluate.</description>
        <descriptionId>store.antivirus.param.AntiVirusXPathSelection.description</descriptionId>

        <tab-override>basic</tab-override>
        <no-save-checkbox>true</no-save-checkbox>

        <required-when>
            <condition evaluation="property-equals">
                <parameter-name>dpconfig:AntiVirusProcessingMode</parameter-name>
                <value>xpath</value>
            </condition>
        </required-when>
        <ignored-when><condition evaluation="logical-true" /></ignored-when>
    </dp:param>

    <!-- Attachment Content-Type Selection -->
    <xsl:param name="dpconfig:AntiVirusAttachmentContentType" select="'.*'" />
    <dp:param name="dpconfig:AntiVirusAttachmentContentType" type="dmPCRE" xmlns="">
        <display>Attachment Content-Type</display>
        <displayId>store.antivirus.param.AntiVirusAttachmentContentType.display</displayId>
        <description>PCRE matching attachment content types to scan.</description>
        <descriptionId>store.antivirus.param.AntiVirusAttachmentContentType.description</descriptionId>

        <tab-override>basic</tab-override>
        <no-save-checkbox>true</no-save-checkbox>

        <required-when>
            <condition evaluation="property-equals">
                <parameter-name>dpconfig:AntiVirusProcessingMode</parameter-name>
                <value>attachment-content-type</value>
            </condition>
        </required-when>
        <ignored-when><condition evaluation="logical-true" /></ignored-when>
    </dp:param>

    <!-- URI Selection -->
    <xsl:param name="dpconfig:AntiVirusAttachmentURI" select="'.*'" />
    <dp:param name="dpconfig:AntiVirusAttachmentURI" type="dmPCRE" xmlns="">
        <display>Attachment URI PCRE</display>
        <displayId>store.antivirus.param.AntiVirusAttachmentURI.display</displayId>
        <description>URI of attachments to scan.</description>
        <descriptionId>store.antivirus.param.AntiVirusAttachmentURI.description</descriptionId>

        <tab-override>basic</tab-override>
        <no-save-checkbox>true</no-save-checkbox>

        <required-when>
            <condition evaluation="property-equals">
                <parameter-name>dpconfig:AntiVirusProcessingMode</parameter-name>
                <value>attachment-uri</value>
            </condition>
        </required-when>
        <ignored-when><condition evaluation="logical-true" /></ignored-when>
    </dp:param>



    <!-- ICAP Host Type -->
    <xsl:param name="dpconfig:ICAPHostType" select="'clam'" />
    <dp:param name="dpconfig:ICAPHostType" type="ICAPHostType" xmlns="">
        <display>ICAP Host Type</display>
        <displayId>store.antivirus.param.ICAPHostType.display</displayId>
        <description>Select which type of ICAP host to use for the antivirus scan.</description>
        <descriptionId>store.antivirus.param.ICAPHostType.description</descriptionId>

        <tab-override>basic</tab-override>
        <refresh-on-change>true</refresh-on-change>
        <no-save-checkbox>true</no-save-checkbox>
        <format>radio</format>

        <required-when><condition evaluation="logical-true" /></required-when>


        <type name="ICAPHostType" base="enumeration" displayOrder="fixed">
            <value-list>
                <value name="clam">
                    <display>Clam</display>
                    <displayId>store.antivirus.param.ICAPHostType.value1.display</displayId>
                    <description>Clam AV ICAP Server</description>
                    <descriptionId>store.antivirus.param.ICAPHostType.value1.description</descriptionId>
                </value>
                <value name="symantec">
                    <display>Symantec</display>
                    <displayId>store.antivirus.param.ICAPHostType.value2.display</displayId>
                    <description>Symantec Scan Engine ICAP</description>
                    <descriptionId>store.antivirus.param.ICAPHostType.value2.description</descriptionId>
                </value>
                <value name="trend">
                    <display>Trend Micro</display>
                    <displayId>store.antivirus.param.ICAPHostType.value3.display</displayId>
                    <description>Trend Micro InterScan WebProtect for ICAP</description>
                    <descriptionId>store.antivirus.param.ICAPHostType.value3.description</descriptionId>
                </value>
                <value name="webwasher">
                    <display>Webwasher</display>
                    <displayId>store.antivirus.param.ICAPHostType.value4.display</displayId>
                    <description>Webwasher ICAP Server</description>
                    <descriptionId>store.antivirus.param.ICAPHostType.value4.description</descriptionId>
                </value>
                <value name="custom">
                    <display>Custom</display>
                    <displayId>store.antivirus.param.ICAPHostType.value5.display</displayId>
                    <description>Custom ICAP client</description>
                    <descriptionId>store.antivirus.param.ICAPHostType.value5.description</descriptionId>
                </value>
            </value-list>
        </type>
    </dp:param>

    <!-- ICAP Server Address -->
    <xsl:param name="dpconfig:ICAPRemoteHost" select="''" />
    <dp:param name="dpconfig:ICAPRemoteHost" type="dmHostname" xmlns="">
        <display>Remote Host Name</display>
        <displayId>store.antivirus.param.ICAPRemoteHost.display</displayId>
        <description>The host name of the Virus Scanner.</description>
        <descriptionId>store.antivirus.param.ICAPRemoteHost.description</descriptionId>

        <tab-override>basic</tab-override>
        <no-save-checkbox>true</no-save-checkbox>

        <required-when><condition evaluation="logical-true" /></required-when>
    </dp:param>

    <!-- ICAP Server Port -->
    <xsl:param name="dpconfig:ICAPRemotePort" select="''" />
    <dp:param name="dpconfig:ICAPRemotePort" type="dmIPPort" xmlns="">
        <display>Remote Port</display>
        <displayId>store.antivirus.param.ICAPRemotePort.display</displayId>
        <description>Remote port of the Virus Scanner.</description>
        <descriptionId>store.antivirus.param.ICAPRemotePort.description</descriptionId>

        <tab-override>basic</tab-override>
        <no-save-checkbox>true</no-save-checkbox>
    </dp:param>

    <!-- ICAP Server URI -->
    <xsl:param name="dpconfig:ICAPRemoteURI" select="''" />
    <dp:param name="dpconfig:ICAPRemoteURI" type="dmString" xmlns="">
        <display>Remote URI</display>
        <displayId>store.antivirus.param.ICAPRemoteURI.display</displayId>
        <description>URI of the Virus Scanner.</description>
        <descriptionId>store.antivirus.param.ICAPRemoteURI.description</descriptionId>

        <tab-override>basic</tab-override>
        <no-save-checkbox>true</no-save-checkbox>
    </dp:param>




    <!-- AV Processing Mode -->
    <xsl:param name="dpconfig:AntiVirusPolicy" select="'reject'" />
    <dp:param name="dpconfig:AntiVirusPolicy" type="AntiVirusPolicy" xmlns="">
        <display>Antivirus Policy</display>
        <displayId>store.antivirus.param.AntiVirusPolicy.display</displayId>
        <description>Virus handling policy</description>
        <descriptionId>store.antivirus.param.AntiVirusPolicy.description</descriptionId>
        <default>reject</default>

        <tab-override>basic</tab-override>
        <no-save-checkbox>true</no-save-checkbox>
        <format>radio</format>

        <type name="AntiVirusPolicy" base="enumeration" displayOrder="fixed">
            <value-list>
                <value name="log">
                    <display>Log</display>
                    <displayId>store.antivirus.param.AntiVirusPolicy.value1.display</displayId>
                    <description>Log but do not strip attachment or reject policy.</description>
                    <descriptionId>store.antivirus.param.AntiVirusPolicy.value1.description</descriptionId>
                </value>
                <value name="reject">
                    <display>Reject</display>
                    <displayId>store.antivirus.param.AntiVirusPolicy.value2.display</displayId>
                    <description>Reject message</description>
                    <descriptionId>store.antivirus.param.AntiVirusPolicy.value2.description</descriptionId>
                </value>
                <value name="strip">
                    <display>Strip</display>
                    <displayId>store.antivirus.param.AntiVirusPolicy.value3.display</displayId>
                    <description>Strip offending attachment</description>
                    <descriptionId>store.antivirus.param.AntiVirusPolicy.value3.description</descriptionId>
                </value>
            </value-list>
        </type>
    </dp:param>

    <!-- AV Processing Mode -->
    <xsl:param name="dpconfig:AntiVirusErrorPolicy" select="'reject'" />
    <dp:param name="dpconfig:AntiVirusErrorPolicy" type="AntiVirusErrorPolicy" xmlns="">
        <display>Antivirus Error Policy</display>
        <displayId>store.antivirus.param.AntiVirusErrorPolicy.display</displayId>
        <description>Antivirus error handling policy</description>
        <descriptionId>store.antivirus.param.AntiVirusErrorPolicy.description</descriptionId>
        <default>reject</default>

        <tab-override>basic</tab-override>
        <no-save-checkbox>true</no-save-checkbox>
        <format>radio</format>

        <type name="AntiVirusErrorPolicy" base="enumeration" displayOrder="fixed">
            <value-list>
                <value name="log">
                    <display>Log</display>
                    <displayId>store.antivirus.param.AntiVirusErrorPolicy.value1.display</displayId>
                    <description>Log but do not strip attachment or reject policy.</description>
                    <descriptionId>store.antivirus.param.AntiVirusErrorPolicy.value1.description</descriptionId>
                </value>
                <value name="reject">
                    <display>Reject</display>
                    <displayId>store.antivirus.param.AntiVirusErrorPolicy.value2.display</displayId>
                    <description>Reject message</description>
                    <descriptionId>store.antivirus.param.AntiVirusErrorPolicy.value2.description</descriptionId>
                </value>
                <value name="strip">
                    <display>Strip</display>
                    <displayId>store.antivirus.param.AntiVirusErrorPolicy.value3.display</displayId>
                    <description>Strip offending attachment</description>
                    <descriptionId>store.antivirus.param.AntiVirusErrorPolicy.value3.description</descriptionId>
                </value>
            </value-list>
        </type>
    </dp:param>


    <!-- Logging Category -->
    <xsl:param name="dpconfig:LogCategory" select="'xsltmsg'" />
    <dp:param name="dpconfig:LogCategory" type="dmReference" reftype="LogLabel" xmlns="">
        <display>Log Category</display>
        <displayId>store.antivirus.param.LogCategory.display</displayId>
        <description>The log category for Virus Scanner logs.</description>
        <descriptionId>store.antivirus.param.LogCategory.description</descriptionId>
        <default>xsltmsg</default>

        <tab-override>basic</tab-override>
        <no-save-checkbox>true</no-save-checkbox>
    </dp:param>


    <xsl:variable name="icap-url">
        <xsl:text>icap://</xsl:text>
        <xsl:value-of select="$dpconfig:ICAPRemoteHost" />
        <xsl:if test="$dpconfig:ICAPRemotePort and string($dpconfig:ICAPRemotePort) != ''">
            <xsl:text>:</xsl:text>
            <xsl:value-of select="$dpconfig:ICAPRemotePort" />
        </xsl:if>
        <xsl:value-of select="$dpconfig:ICAPRemoteURI" />
    </xsl:variable>

    <!-- ##### COMMON TEMPLATES ##### -->

    <xsl:template match="/">
        <!-- default to accept, any reject after this will override -->
        <dp:accept />

        <xsl:variable name="attachments" select="dp:variable('var://local/attachment-manifest')/manifest/attachments" />

        <xsl:variable name="attachments-to-test">
            <xsl:choose>
                <xsl:when test="$dpconfig:AntiVirusProcessingMode = 'entire-message' or $dpconfig:AntiVirusProcessingMode = 'attachments'">
                    <xsl:copy-of select="$attachments/attachment" />
                </xsl:when>

                <xsl:when test="$dpconfig:AntiVirusProcessingMode = 'attachment-content-type'">
                    <xsl:copy-of select="$attachments/attachment[regexp:test( header[name = 'Content-Type']/value, $dpconfig:AntiVirusAttachmentContentType, '')]" />
                </xsl:when>

                <xsl:when test="$dpconfig:AntiVirusProcessingMode = 'attachment-uri'">
                    <xsl:copy-of select="$attachments/attachment[regexp:test( uri, $dpconfig:AntiVirusAttachmentURI, '')]" />
                </xsl:when>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="test-attachments-result">
            <xsl:apply-templates mode="icap-test-attachment" select="$attachments-to-test/attachment" />
        </xsl:variable>

        <xsl:choose>
            <!-- if we have no attachments, this will not be reject -->
            <xsl:when test="$test-attachments-result/reject">
                <dp:reject override="true"><xsl:value-of select="dpfunc:join(set:distinct($test-attachments-result/reject), '; ')" /></dp:reject>
            </xsl:when>

            <xsl:when test="$dpconfig:AntiVirusProcessingMode = 'entire-message' or $dpconfig:AntiVirusProcessingMode = 'xpath'">
                <xsl:variable name="icap-result">
                    <xsl:choose>
                        <xsl:when test="$dpconfig:AntiVirusProcessingMode = 'xpath'">
                            <xsl:copy-of select="dpfunc:icap-test(dyn:evaluate($dpconfig:AntiVirusXPathSelection), 'xml')" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="dpfunc:icap-test(., 'xml')" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <!-- There are three possible results: a clean message, a virus, and an error -->
                <xsl:choose>
                    <xsl:when test="$icap-result/virus">
                        <xsl:choose>
                            <xsl:when test="$dpconfig:AntiVirusProcessingMode = 'xpath'">
                                <xsl:message dp:type="{$dpconfig:LogCategory}" dp:priority="error" dp:id="{$DPLOG_XSLT_VIRUSINEXTRACTED}">
                                  <dp:with-param value="{$dpconfig:AntiVirusXPathSelection}" />
                                </xsl:message>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:message dp:type="{$dpconfig:LogCategory}" dp:priority="error" dp:id="{$DPLOG_XSLT_VIRUSINBODY}"/>
                            </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                            <xsl:when test="$dpconfig:AntiVirusPolicy = 'reject' or $dpconfig:AntiVirusPolicy = 'strip'">
                                <!-- if the policy is reject virus, we don't need to continue -->
                                <dp:reject>Virus Found</dp:reject>
                                <!--  <dp:set-variable name="'var://service/error-subcode'" value="'0x01d30005'" /> -->
                                <dp:set-variable name="'var://service/error-subcode'" value="30605317" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:copy-of select="." />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$icap-result/error">
                        <xsl:message dp:type="{$dpconfig:LogCategory}" dp:priority="error" dp:id="{$DPLOG_XSLT_VIRUSSCANFAILED}">
                          <dp:with-param value="{$icap-result/error}" />
                        </xsl:message>
                        <xsl:choose>
                            <xsl:when test="$dpconfig:AntiVirusErrorPolicy = 'reject' or $dpconfig:AntiVirusErrorPolicy = 'strip'">
                                <dp:reject override="true">Unable to virus scan.</dp:reject>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:copy-of select="." />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="." />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$dpconfig:AntiVirusProcessingMode = 'attachments' or $dpconfig:AntiVirusProcessingMode = 'attachment-content-type' or $dpconfig:AntiVirusProcessingMode = 'attachment-uri'">
                <!-- do nothing -->
                <xsl:copy-of select="." />
            </xsl:when>
            <xsl:otherwise>
              <xsl:message dp:type="{$dpconfig:LogCategory}" dp:priority="error" dp:id="{$DPLOG_XSLT_VIRUSSCANFAILED_UNKNOWNMODE}">
                <dp:with-param value="{$dpconfig:AntiVirusProcessingMode}" />
              </xsl:message>


                <xsl:choose>
                    <xsl:when test="$dpconfig:AntiVirusErrorPolicy = 'reject' or $dpconfig:AntiVirusErrorPolicy = 'strip'">
                        <dp:reject override="true">Unable to virus scan.</dp:reject>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="." />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- join a list of nodes with an arbitrary delimiter
         @param nodes the node set to join
         @param delimiter the delimiter
     -->
    <func:function name="dpfunc:join">
        <xsl:param name="nodes" />
        <xsl:param name="delimiter" select="','" />

        <func:result>
            <xsl:for-each select="$nodes/self::node()">
                <xsl:value-of select="." />
                <xsl:if test="position() != last()"><xsl:value-of select="$delimiter" /></xsl:if>
            </xsl:for-each>
        </func:result>
    </func:function>


    <xsl:template mode="icap-test-attachment" match="attachment">
        <xsl:variable name="uri" select="normalize-space(uri)" />

        <xsl:choose>
            <xsl:when test="$uri = ''">
                <xsl:message dp:type="{$dpconfig:LogCategory}" dp:priority="error" dp:id="{$DPLOG_XSLT_VIRUSSCANFAILED_NOATTURI}"/>

                <xsl:choose>
                    <xsl:when test="$dpconfig:AntiVirusErrorPolicy = 'reject'">
                        <reject>Unable to virus scan.</reject>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="$dpconfig:AntiVirusErrorPolicy = 'strip'">
                            <dp:strip-attachments uri="{uri}"/>
                            <xsl:message dp:type="{$dpconfig:LogCategory}" dp:priority="error" dp:id="{$DPLOG_XSLT_UNSCANNABLESTRIPPED}">
                              <dp:with-param value="{$uri}" />
                            </xsl:message>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!-- get base64 encoded attachment -->
                <xsl:variable name="binarydata">
                    <dp:url-open target="{concat($uri,'?Encode=base64')}" />
                </xsl:variable>

                <xsl:message dp:type="{$dpconfig:LogCategory}" dp:priority="notice" dp:id="{$DPLOG_XSLT_SCANNINGATTACH}">
                  <dp:with-param value="{$uri}" />
                </xsl:message>

                <!-- do the actual scanning -->
                <xsl:variable name="icap-result" select="dpfunc:icap-test($binarydata/base64/text(), 'base64')" />


                <!-- There are three possible results: a clean message, a virus, and an error -->
                <xsl:choose>
                    <xsl:when test="$icap-result/virus">
                        <xsl:message dp:type="{$dpconfig:LogCategory}" dp:priority="error" dp:id="{$DPLOG_XSLT_VIRUSINATTACH}">
                          <dp:with-param value="{$uri}" />
                        </xsl:message>

                        <xsl:choose>
                            <xsl:when test="$dpconfig:AntiVirusPolicy = 'reject'">
                                <!-- if the policy is reject virus, we don't need to continue -->
                                <reject>Virus Found</reject>
                                <!-- <dp:set-variable name="'var://service/error-subcode'" value="'0x01d30005'" /> -->
                                <dp:set-variable name="'var://service/error-subcode'" value="30605317" />
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- if the policy if strip infected attachments, do it an log it -->
                                <xsl:if test="$dpconfig:AntiVirusPolicy = 'strip'">
                                    <dp:strip-attachments uri="{uri}"/>
                                    <xsl:message dp:type="{$dpconfig:LogCategory}" dp:priority="warning" dp:id="{$DPLOG_XSLT_INFECTEDSTRIPPED}">
                                      <dp:with-param value="{$uri}" />
                                    </xsl:message>
                                </xsl:if>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$icap-result/error">
                        <xsl:message dp:type="{$dpconfig:LogCategory}" dp:priority="error" dp:id="{$DPLOG_XSLT_VIRUSSCANFAILED}">
                          <dp:with-param value="{$icap-result/error}" />
                        </xsl:message>

                        <xsl:choose>
                            <xsl:when test="$dpconfig:AntiVirusErrorPolicy = 'reject'">
                                <reject override="true">Unable to virus scan.</reject>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:if test="$dpconfig:AntiVirusErrorPolicy = 'strip'">
                                    <dp:strip-attachments uri="{uri}"/>
                                    <xsl:message dp:type="{$dpconfig:LogCategory}" dp:priority="error" dp:id="{$DPLOG_XSLT_UNSCANNABLESTRIPPED}">
                                      <dp:with-param value="{$uri}" />
                                    </xsl:message>
                                </xsl:if>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- EXSLT wrapper around the icap-test template for simplicity -->
    <func:function name="dpfunc:icap-test">
        <xsl:param name="icap-data" />
        <xsl:param name="icap-data-type" />

        <func:result>
            <xsl:call-template name="icap-test">
                <xsl:with-param name="icap-data" select="$icap-data" />
                <xsl:with-param name="icap-data-type" select="$icap-data-type" />
            </xsl:call-template>
        </func:result>
    </func:function>

</xsl:stylesheet>
