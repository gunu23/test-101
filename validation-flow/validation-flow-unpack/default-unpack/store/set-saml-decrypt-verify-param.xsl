<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2014. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
    This stylesheet decrypts all xenc:EncryptedData nodes.  It is
    complicated because there are a number of ways that a key can
    be associated with the encrypted data.
-->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpconfig="http://www.datapower.com/param/config"
    xmlns:regexp="http://exslt.org/regular-expressions"
    xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion"
    xmlns:wsse11="http://docs.oasis-open.org/wss/oasis-wss-wssecurity-secext-1.1.xsd"
    xmlns:xenc="http://www.w3.org/2001/04/xmlenc#"
    exclude-result-prefixes="dp dpconfig regexp saml2 wsse11 xenc"
>

  <xsl:output method="xml"/>

  <xsl:param name="dpconfig:validate-saml" select="'on'"/>
  <dp:param name="dpconfig:validate-saml" type="dmToggle" xmlns="">
    <display>Validate Applicable SAML Assertion</display>
    <displayId>store.set-saml-decrypt-verify-param.param.validate-saml.display</displayId>
    <description>Validate the SAML assertion used by the crypto operation</description>
    <descriptionId>store.set-saml-decrypt-verify-param.param.validate-saml.description</descriptionId>
    <default>on</default>
    <ignored-when>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:saml-skew-time" select="'0'"/>
  <dp:param name="dpconfig:saml-skew-time" type="dmTimeInterval" xmlns="">
    <display>SAML Skew Time</display>
    <displayId>store.set-saml-decrypt-verify-param.param.saml-skew-time.display</displayId>
    <description>Skew time is the difference, in seconds, between the device clock time and other system times.
     When the skew time is set, the SAML assertion expiration takes the time difference into
     account when the appliance consumes SAML tokens. NotBefore is validated with CurrentTime minus SkewTime.
     NotOnOrAfter is validated with CurrentTime plus SkewTime.
    </description>
    <descriptionId>store.set-saml-decrypt-verify-param.param.saml-skew-time.description</descriptionId>
    <units>sec</units>
    <unitsDisplayId>store.set-saml-decrypt-verify-param.param.saml-skew-time.unit.sec</unitsDisplayId>
    <minimum>0</minimum>
    <maximum>630720000</maximum>     <!-- 20 years -->
    <default>0</default>
    <ignored-when>
      <condition evaluation="property-does-not-equal">
        <parameter-name>dpconfig:validate-saml</parameter-name>
        <value>on</value>
      </condition>
    </ignored-when>
  </dp:param>

</xsl:stylesheet>
