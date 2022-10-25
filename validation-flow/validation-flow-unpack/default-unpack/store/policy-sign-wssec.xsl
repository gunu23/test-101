<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2013. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
     Insert WS-Policy and RSA/DSA signature on it into SOAP header.
     -->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:SOAP="http://schemas.xmlsoap.org/soap/envelope/"
  xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" 
  xmlns:wsse-d12="http://schemas.xmlsoap.org/ws/2002/07/secext"
  xmlns:wsse-d13="http://schemas.xmlsoap.org/ws/2003/06/secext"
  xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
  xmlns:wsu-d12="http://schemas.xmlsoap.org/ws/2002/07/utility"
  xmlns:wsu-d13="http://schemas.xmlsoap.org/ws/2003/06/utility"
  xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy"
  xmlns:dpp="http://www.datapower.com/policy"
  xmlns:dp="http://www.datapower.com/extensions"
  xmlns:dpconfig="http://www.datapower.com/param/config"
  extension-element-prefixes="dp"
  exclude-result-prefixes="dp dpconfig SOAP">

  <dp:summary xmlns="">
    <operation>xform</operation>
    <description>Insert WS-Policy and RSA/DSA signature on it into SOAP header.</description>
    <descriptionId>store.policy-sign-wssec.dpsummary.description</descriptionId>
  </dp:summary>

  <xsl:output method="xml"/>

  <xsl:include href="store:///dp/sign.xsl" dp:ignore-multiple="yes"/>

  <xsl:param name="dpconfig:sigalg" select="'rsa'"/>
  <dp:param name="dpconfig:sigalg" type="dmCryptoSigningAlgorithm" xmlns=""/>

  <xsl:param name="dpconfig:hashalg" select="'sha1'"/>
  <dp:param name="dpconfig:hashalg" type="dmCryptoHashAlgorithm" xmlns=""/>

  <xsl:param name="dpconfig:wss-x509-token-profile-1.0-binarysecuritytoken-reference-valuetype"
    select="'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3'"/>
  <dp:param name="dpconfig:wss-x509-token-profile-1.0-binarysecuritytoken-reference-valuetype"
    type="dmCryptoWSSX509TokenProfile10BinarySecurityTokenReferenceValueType" xmlns=""/>

  <xsl:include href="store:///set-keypair.xsl" dp:ignore-multiple="yes"/>

  <xsl:param name="dpconfig:include-inline-cert" select="'off'"/>
  <dp:param name="dpconfig:include-inline-cert" hidden="true" type="dmToggle" xmlns="">
    <display>Include Signer's Certificate In-line</display>
    <displayId>store.policy-sign-wssec.param.include-inline-cert.display</displayId>
    <description>Setting to 'on' causes the signer's certificate to be included in the Signature
    element inside a second KeyInfo block.  This may aid compatibility with certain
    applications.</description>
    <descriptionId>store.policy-sign-wssec.param.include-inline-cert.description</descriptionId>
    <default>off</default>
  </dp:param>

  <xsl:param name="dpconfig:expect-signatureconfirmation" select="'off'"/>
  <dp:param name="dpconfig:expect-signatureconfirmation" type="dmToggle" xmlns="">
    <display>Expect Verifier to Return wsse11:SignatureConfirmation</display>
    <displayId>store.policy-sign-wssec.param.expect-signatureconfirmation.display</displayId>
    <description>If we expect the returned response message contains WS-Security 1.1
    SignatureConfirmation, set this switch to 'on' to save the generated signature
    value, so that a Verify action can process the response to verify the WS-Security 1.1
    SignatureConfirmation.</description>
    <descriptionId>store.policy-sign-wssec.param.expect-signatureconfirmation.description</descriptionId>
    <default>off</default>
  </dp:param>

  <xsl:variable name="wsse-token" select='concat("name:", $pair-cert)'/>
  <xsl:variable name="cert-id" select="generate-id()"/>

  <!-- policy variables -->
  <xsl:include href="store:///dp/policy-common.xsl" dp:ignore-multiple="yes"/>

  <xsl:template match="*">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="SOAP:Envelope">
    <SOAP:Envelope>
      <xsl:copy-of select="@*"/>
      <xsl:if test="not (SOAP:Header)">
        <xsl:call-template name="SOAP:Header">
          <xsl:with-param name="new" select="true()"/>
        </xsl:call-template>
      </xsl:if>  
      <xsl:apply-templates select="*"/>
    </SOAP:Envelope>
  </xsl:template>

  <xsl:template name="SOAP:Header" match="SOAP:Header">
    <xsl:param name="new" select="false()"/>  
    <SOAP:Header>
      <xsl:copy-of select="$policy-body"/>
      <xsl:if test="not (wsse:Security | wsse-d12:Security | wsse-d13:Security)">
        <xsl:call-template name="wsse:Security">
          <xsl:with-param name="new" select="true()"/>
        </xsl:call-template>
      </xsl:if>
      <xsl:if test="not($new)">
        <xsl:copy-of select="@*"/>
        <xsl:apply-templates select="*"/>
      </xsl:if>
    </SOAP:Header>  
  </xsl:template>

  <xsl:template name="wsse:Security" match="wsse:Security">
    <xsl:param name="new" select="false()"/>
    <wsse:Security>
      <xsl:if test="not($new)">
        <xsl:copy-of select="@*"/>
      </xsl:if>
      <wsse:BinarySecurityToken
        EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary"
        ValueType="{$dpconfig:wss-x509-token-profile-1.0-binarysecuritytoken-reference-valuetype}">
        <xsl:attribute name="{$wsu-id}">
          <xsl:value-of select="$cert-id"/>
        </xsl:attribute>
        <xsl:value-of select="dp:base64-cert($wsse-token)"/>      
      </wsse:BinarySecurityToken>
      <xsl:call-template name="dp-sign">
        <xsl:with-param name="node"    select="$policy-body" />
        <xsl:with-param name="refuri"  select="concat('#', $policy-id)" />
        <xsl:with-param name="keyid"   select="concat('name:', $pair-key)"/>
        <xsl:with-param name="certid">
          <xsl:choose>
            <xsl:when test="$dpconfig:include-inline-cert = 'on'">
              <xsl:value-of select="concat('name:', $pair-cert)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="''"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:with-param>
        <xsl:with-param name="sigalg" select='$dpconfig:sigalg'/>
        <xsl:with-param name="c14nalg" select="'exc-c14n'"/>
        <xsl:with-param name="hashalg" select='$dpconfig:hashalg'/>
        <xsl:with-param name="keyinfo">
          <wsse:SecurityTokenReference>
            <wsse:Reference URI="{concat('#', $cert-id)}"
              ValueType="{$dpconfig:wss-x509-token-profile-1.0-binarysecuritytoken-reference-valuetype}"/>
          </wsse:SecurityTokenReference>
        </xsl:with-param>
        <xsl:with-param name="store-signature" select="$dpconfig:expect-signatureconfirmation"/>
      </xsl:call-template>
      <xsl:if test="not($new)">
        <xsl:copy-of select="*"/>
      </xsl:if>
    </wsse:Security>
  </xsl:template>

  <xsl:template match="wsse-d12:Security">
    <xsl:param name="new" select="false()"/>
    <wsse-d12:Security>
      <xsl:if test="not($new)">
        <xsl:copy-of select="@*"/>
      </xsl:if>
      <wsse-d12:BinarySecurityToken
        EncodingType="wsse-d12:Base64Binary"
        ValueType="wsse-d12:X509v3">
        <xsl:attribute name="{$wsu-id}">
          <xsl:value-of select="$cert-id"/>
        </xsl:attribute>
        <xsl:value-of select="dp:base64-cert($wsse-token)"/>
      </wsse-d12:BinarySecurityToken>
      <xsl:call-template name="dp-sign">
        <xsl:with-param name="node"    select="$policy-body" />
        <xsl:with-param name="refuri"  select="concat('#', $policy-id)" />
        <xsl:with-param name="keyid"   select="concat('name:', $pair-key)"/>
        <xsl:with-param name="certid">
          <xsl:choose>
            <xsl:when test="$dpconfig:include-inline-cert = 'on'">
              <xsl:value-of select="concat('name:', $pair-cert)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="''"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:with-param>
        <xsl:with-param name="sigalg" select='$dpconfig:sigalg'/>
        <xsl:with-param name="c14nalg" select="'exc-c14n'"/>
        <xsl:with-param name="hashalg" select='$dpconfig:hashalg'/>
        <xsl:with-param name="keyinfo">
          <wsse-d12:SecurityTokenReference>
            <wsse-d12:Reference URI="{concat('#', $cert-id)}"/>
          </wsse-d12:SecurityTokenReference>
        </xsl:with-param>
        <xsl:with-param name="store-signature" select="$dpconfig:expect-signatureconfirmation"/>
      </xsl:call-template>
      <xsl:if test="not($new)">
        <xsl:copy-of select="*"/>
      </xsl:if>
    </wsse-d12:Security>
  </xsl:template>

  <xsl:template match="wsse-d13:Security">
    <xsl:param name="new" select="false()"/>
    <wsse-d13:Security>
      <xsl:if test="not($new)">
        <xsl:copy-of select="@*"/>
      </xsl:if>
      <wsse-d13:BinarySecurityToken
        EncodingType="wsse-d13:Base64Binary"
        ValueType="wsse-d13:X509v3">
        <xsl:attribute name="{$wsu-id}">
          <xsl:value-of select="$cert-id"/>
        </xsl:attribute>
        <xsl:value-of select="dp:base64-cert($wsse-token)"/>
      </wsse-d13:BinarySecurityToken>
      <xsl:call-template name="dp-sign">
        <xsl:with-param name="node"    select="$policy-body" />
        <xsl:with-param name="refuri"  select="concat('#', $policy-id)" />
        <xsl:with-param name="keyid"   select="concat('name:', $pair-key)"/>
        <xsl:with-param name="certid">
          <xsl:choose>
            <xsl:when test="$dpconfig:include-inline-cert = 'on'">
              <xsl:value-of select="concat('name:', $pair-cert)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="''"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:with-param>
        <xsl:with-param name="sigalg" select='$dpconfig:sigalg'/>
        <xsl:with-param name="c14nalg" select="'exc-c14n'"/>
        <xsl:with-param name="hashalg" select='$dpconfig:hashalg'/>
        <xsl:with-param name="keyinfo">
          <wsse-d13:SecurityTokenReference>
            <wsse-d13:Reference URI="{concat('#', $cert-id)}"/>
          </wsse-d13:SecurityTokenReference>
        </xsl:with-param>
        <xsl:with-param name="store-signature" select="$dpconfig:expect-signatureconfirmation"/>
      </xsl:call-template>
      <xsl:if test="not($new)">
        <xsl:copy-of select="*"/>
      </xsl:if>
    </wsse-d13:Security>
  </xsl:template>

</xsl:stylesheet>
