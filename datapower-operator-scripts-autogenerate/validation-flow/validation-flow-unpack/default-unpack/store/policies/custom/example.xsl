<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2014. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!-- template for a ws-policy domain specifc stylesheet -->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dpe="http://www.datapower.com/extensions"
    xmlns:dppolicy="http://www.datapower.com/policy"
    xmlns:dpconfig="http://www.datapower.com/param/config"
    xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy"
    xmlns:mypolicy="http://www.datapower.com/mypolicy"
    extension-element-prefixes="dpe"
    exclude-result-prefixes="dpe dpconfig dppolicy wsp mypolicy">

    <!-- (1) Declare the policy domain(s) this stylesheet is implementing -->

    <dpe:summary xmlns=""> 
        <!-- here commented out as to prevent the policy domain to be processed -->
        <!-- <dppolicy:domain>http://www.datapower.com/mypolicy</dppolicy:domain> -->
        <operation>xform</operation>
        <description>Implements my policy</description>
    </dpe:summary>
    
    <!-- (2) Declare required configuration bindings and asociate them to policy assertions -->

    <!-- idcred for my signing -->
    <xsl:param name="dpconfig:my-policy-cred" select="''"/>
    <dpe:param name="dpconfig:my-policy-cred" type="dmReference" reftype="CryptoIdentCred" xmlns="">
        <dppolicy:assertion>{http://www.datapower.com/mypolicy}SignThis</dppolicy:assertion>
        <dppolicy:assertion>{http://www.datapower.com/mypolicy}SignThat</dppolicy:assertion>
        <display>Signature Idcred</display>
        <description>Signature Crypto Idcred</description>
    </dpe:param>

    <!-- the policy domain namespace the stylesheet is executed for -->
    <xsl:variable name="seqno" select="/dppolicy:request/dppolicy:header/dppolicy:SequenceNo"/>
    <xsl:variable name="nsuri" select="/dppolicy:request/dppolicy:sequence/DomainNamespace[position()=$seqno]/@uri"/>

    <!-- (3) The following global variables represent the input document -->

    <!-- header with aux informations -->
    <xsl:variable name="header" select="/dppolicy:request/dppolicy:header"/>
    <!-- configured policy bindings defined as dpe:param above -->
    <xsl:variable name="bindings" select="/dppolicy:request/dppolicy:bindings"/>
    <!-- ws-policy alternative -->
    <xsl:variable name="policy" select="/dppolicy:request/dppolicy:policy"/>
    <!-- previously generated configuration for this policy alternative -->
    <xsl:variable name="configuration" select="/dppolicy:request/dppolicy:configuration"/>
    <!-- general notepad to pass information between processing steps of one alternative -->
    <xsl:variable name="notepad" select="/dppolicy:request/dppolicy:notepad"/>

    <!-- main -->
    
    <xsl:template match="/">
        <!-- process single alternative -->
        <xsl:apply-templates select="$policy/*[local-name()='All']"/>
    </xsl:template>

    <!-- process single alternative -->
    
    <xsl:template match="*[local-name()='All']">

        <!-- for all policy assertions in my domain namespace -->
        <xsl:for-each select="mypolicy:*">
            <xsl:choose>
                <!-- process assertion -->
                <xsl:when test="local-name()='SignThis' or 
                                local-name()='SignThat'">
                    <xsl:call-template name="SignAssertion"/>
                </xsl:when>

                <!-- benign, only referenced by above assertions -->
                <xsl:when test="local-name()='dontcareaboutme'"/>
                
                <!-- unknown assertion in my domain namespace -->
                <xsl:otherwise>
                    <xsl:message dpe:priority="warning">Unknown Assertion <xsl:value-of select="local-name()"/></xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template> 


    <!-- my domain assertions -->

    <!-- SIGN -->
    
    <xsl:template name="SignAssertion">
    
        <!-- generated one or more aux config snippets -->
        <dppolicy:config>
            <ConfigType name="MyName">
                <MyProperty>MyProperty</MyProperty>
            </ConfigType>
        </dppolicy:config>
        
        <!-- generate processing action to execute (assertionNo = order of processing) -->
        <!-- NOTE: previously added configuration are accessible from $configuration -->
        <dppolicy:config assertionNo="{position()}">
            <StylePolicyAction name="MyName">
                <Type>xform</Type>
                <StylesheetParameters>
                    <ParameterName>signature-idcred</ParameterName>
                    <!-- access declared and configured bindings -->
                    <ParameterValue><xsl:value-of select="$bindings/my-policy-cred"/></ParameterValue>
                </StylesheetParameters>
            </StylePolicyAction>
        </dppolicy:config>
        
        <!-- pass arbitrary information to next processing step -->
        <!-- NOTE: previously added notes are available from $notepad -->
        <dppolicy:note domain="http://www.datapower.com/mypolicy">
            <foobar/>
        </dppolicy:note>
        
    </xsl:template>

    <!-- default catch all -->
    <xsl:template match="text()"/>

</xsl:stylesheet>
