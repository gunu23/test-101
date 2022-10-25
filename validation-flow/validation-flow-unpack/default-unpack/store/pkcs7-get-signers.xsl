<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2013. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:dp="http://www.datapower.com/extensions"
  xmlns:dpconfig="http://www.datapower.com/param/config"
  xmlns:dpfunc="http://www.datapower.com/extensions/functions"
  extension-element-prefixes="dp"
  exclude-result-prefixes="dp dpconfig dpfunc"
>
  <!-- Sample stylesheet showing how to call dp:pkcs7-get-signers().  It's similar to calling
       dp:pkcs7-verify(), but fewer options. -->

  <xsl:output method="xml"/>

  <!-- FFD conversion of binary input into binary node -->
  <dp:input-mapping href="pkcs7-convert-input.ffd" type="ffd"/>
  <!-- FFD conversion of binary node into binary output -->
  <dp:output-mapping href="pkcs7-convert-output.ffd" type="ffd"/>

  <xsl:include href="utilities.xsl" dp:ignore-multiple="yes"/>
  <xsl:include href="store:///dp/msgcat/crypto.xml.xsl" dp:ignore-multiple="yes"/>

  <xsl:param name="dpconfig:input-encoding" select="'pem'"/>
  <dp:param name="dpconfig:input-encoding" type="dmPKCS7ObjectEncoding" xmlns="">
    <display>Input Encoding Format</display>
    <displayId>store.pkcs7-get-signers.param.input-encoding.display</displayId>
    <default>pem</default>
  </dp:param>

  <xsl:param name="dpconfig:additional-certificates" select="''"/>
  <dp:param name="dpconfig:additional-certificates" type="dmReference" reftype="CryptoCertificate"
    vector="true" xmlns="">
    <display>Additional Certificates to Check for Signers</display>
    <displayId>store.pkcs7-get-signers.param.additional-certificates.display</displayId>
    <description>Additional certificates from which the signers' certificates may be taken.
    This is necessary because each signer's information in the PKCS#7 object does not contain
    the whole certificate but just the Issuer and Serial Number, and there is no requirement
    that the corresponding certificate is included in the object.  Therefore there must be a way
    to specify externally a matching certificate. Also see the "Allow Internal Signers'
    Certificates" parameter.</description>
    <descriptionId>store.pkcs7-get-signers.param.additional-certificates.description</descriptionId>
  </dp:param>

  <xsl:param name="dpconfig:allow-internal-signers" select="'on'"/>
  <dp:param name="dpconfig:allow-internal-signers" type="dmToggle" xmlns="">
    <display>Allow Internal Signers' Certificates</display>
    <displayId>store.pkcs7-get-signers.param.allow-internal-signers.display</displayId>
    <description>Setting to 'on', the default, indicates that additional certificates which are
    included in the PKCS#7 object may be searched for each signer's certificate when doing
    signature verification.  If set to 'off' then the certificates in the PKCS#7 object may not
    be used and the signers' certificates must be specified externally (see "Additional
    Certificates to Check for Signers").</description>
    <descriptionId>store.pkcs7-get-signers.param.allow-internal-signers.description</descriptionId>
    <default>on</default>
  </dp:param>

  <xsl:param name="dpconfig:output-metadata-context" select="'_cryptobin'"/>
  <dp:param name="dpconfig:output-metadata-context" type="dmString" xmlns="">
    <display>Name of Context Variable Holding Output Metadata</display>
    <displayId>store.pkcs7-get-signers.param.output-metadata-context.display</displayId>
    <description>The output of a PKCS#7 verify is the data which was signed.  Additionally,
    metadata about the signature is written to a special context variable for later access.
    This parameter is the name of the context the metadata should be written to.  Metadata
    includes things like the signers.  The string "var://context/" is automatically prepended to
    this name.</description>
    <descriptionId>store.pkcs7-get-signers.param.output-metadata-context.description</descriptionId>
    <default>_cryptobin</default>
  </dp:param>

  <xsl:template match="/">

    <xsl:variable name="pkcs7-get-signers-args" xmlns="">
      <arguments>
        <!-- Arguments related to the input data -->
        <input
          encoding="{$dpconfig:input-encoding}"
          allow-internal-signers="{$dpconfig:allow-internal-signers}"/>

        <!-- Additional certificates from which the signers' certificates may be taken.  Those
             from dpconfig:additional-certificates are assumed to be names of certificate
             objects and so use the "name:" convention.  Other certificates using the "cert:"
             and "ski:" conventions could also be placed here manually, for example:

             <certificate>cert:MIID0TCCAzqgAw...</certificate>
          -->
        <xsl:variable name="certificates">
          <xsl:copy-of select="dpfunc:parse-parameter-vector($dpconfig:additional-certificates)"/>
        </xsl:variable>

        <certificates>
          <xsl:for-each select="$certificates/entry">
            <certificate><xsl:value-of select="concat('name:', .)"/></certificate>
          </xsl:for-each>
        </certificates>
      </arguments>
    </xsl:variable>

    <!-- The return nodeset looks like:

         <results>
           <signers>
             <signer>
               <certificate subject="/C=US..." issuer="/C=US..." serial-number="1...">MII....</certificate>
             </signer>
             <signer>
               <certificate subject="/C=US..." issuer="/C=US..." serial-number="1...">MII....</certificate>
             </signer>
             ...
           </signers>
           <error>error message</error>
         </results>

         The signers are provided for use with things like AAA afterward.  The "error" element
         is not present if all went well.
      -->

    <xsl:variable name="result">
      <xsl:choose>
        <xsl:when test="function-available('dp:pkcs7-get-signers')">
          <xsl:copy-of select="dp:pkcs7-get-signers(., $pkcs7-get-signers-args)"/>
        </xsl:when>
        <xsl:otherwise>
          <results>
            <data/>
            <error>*PKCS#7 is not licensed for this device*</error>
          </results>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- The error element is only present when there is an error.  But always set the error
         context variable, even though it may be empty. -->
    <dp:set-variable name="concat('var://context/', $dpconfig:output-metadata-context, '/error')"
      value="$result/results/error"/>

    <xsl:choose>
      <xsl:when test="not($result/results/error)">
        <!-- Successful get-signers -->

        <!-- Save info returned by the extension function for later steps to access -->
        <dp:set-variable name="concat('var://context/', $dpconfig:output-metadata-context, '/signers')"
          value="$result/results/signers"/>

        <!-- The output ffd extracts just the binary data node as the output of this stylesheet.
             And there is none so there is no output, only metadata as a side effect. -->
        <xsl:copy-of select="$result"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- Failed get-signers -->
        <xsl:message dp:priority="error" dp:id="{$DPLOG_CRYPTO_PKCS7_GETSIGNERS_FAILED}" terminate="yes">
          <dp:with-param value="{$result/results/error}"/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

</xsl:stylesheet>
