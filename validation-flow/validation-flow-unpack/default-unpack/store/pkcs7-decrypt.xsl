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
  <dp:summary xmlns="">
    <description>Decrypt content using PKCS#7</description>
    <descriptionId>store.pkcs7-decrypt.dpsummary.description</descriptionId>
  </dp:summary>

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
    <displayId>store.pkcs7-decrypt.param.input-encoding.display</displayId>
    <default>pem</default>
  </dp:param>

  <xsl:param name="dpconfig:output-encoding" select="'none'"/>
  <dp:param name="dpconfig:output-encoding" type="dmPKCS7DataEncoding" xmlns="">
    <display>Output Encoding Format</display>
    <displayId>store.pkcs7-decrypt.param.output-encoding.display</displayId>
    <default>none</default>
  </dp:param>

  <xsl:param name="dpconfig:remove-textplain-header" select="'off'"/>
  <dp:param name="dpconfig:remove-textplain-header" type="dmToggle" xmlns="">
    <display>Remove text/plain Header</display>
    <displayId>store.pkcs7-decrypt.param.remove-textplain-header.display</displayId>
    <description>If the "Input Encoding Format" is 'S/MIME' then setting this switch to 'on'
    causes a "Content-Type: text/plain" MIME header to be deleted from the data after
    decryption.  It's an error if the header isn't present. The default is 'off'.</description>
    <descriptionId>store.pkcs7-decrypt.param.remove-textplain-header.description</descriptionId>
    <default>off</default>
  </dp:param>

  <xsl:param name="dpconfig:recipients" select="''"/>
  <dp:param name="dpconfig:recipients" type="dmReference" reftype="CryptoIdentCred" vector="true" xmlns="">
    <display>Recipients</display>
    <displayId>store.pkcs7-decrypt.param.recipients.display</displayId>
    <description>The CryptoIdentCred to decrypt the content-encryption key.  The private key is
    what's actually used, but the certificate is necessary in order to locate the correct
    recipient in the PKCS#7 object.  If the recipient (based on the certificate) is not present
    in the PKCS#7 object then decryption will fail.  Each recipient is tried in turn until the
    decryption succeeds, or all have failed.</description>
    <descriptionId>store.pkcs7-decrypt.param.recipients.description</descriptionId>
  </dp:param>

  <xsl:param name="dpconfig:output-metadata-context" select="'_cryptobin'"/>
  <dp:param name="dpconfig:output-metadata-context" type="dmString" xmlns="">
    <display>Name of Context Variable Holding Output Metadata</display>
    <displayId>store.pkcs7-decrypt.param.output-metadata-context.display</displayId>
    <description>The output of a PKCS#7 decryption is the original data.  Additionally, metadata
    about the decryption is written to a special context variable for later access.  This
    parameter is the name of the context the metadata should be written to.  Metadata includes
    things like error information.  The string "var://context/" is automatically prepended to
    this name.</description>
    <descriptionId>store.pkcs7-decrypt.param.output-metadata-context.description</descriptionId>
    <default>_cryptobin</default>
  </dp:param>

  <xsl:template match="/">
    <xsl:variable name="pkcs7-decrypt-args" xmlns="">
      <arguments>
        <!-- Arguments related to the input data -->
        <input
          encoding="{$dpconfig:input-encoding}"/>

        <!-- Arguments related to the output data -->
        <output
          encoding="{$dpconfig:output-encoding}"
          remove-textplain-header="{$dpconfig:remove-textplain-header}"/>

        <!-- An idcred for each recipient -->
        <xsl:variable name="recipients">
          <xsl:copy-of select="dpfunc:parse-parameter-vector($dpconfig:recipients)"/>
        </xsl:variable>

        <recipients>
          <xsl:for-each select="$recipients/entry">
            <recipient><xsl:value-of select="."/></recipient>
          </xsl:for-each>
        </recipients>

      </arguments>
    </xsl:variable>

    <!-- The return nodeset looks like:

         <results>
           <data>decrypted data (binary node)</data>
           <error>error message</error>
         </Results>

         The "error" element is not present if all went well.
      -->
    <xsl:variable name="result">
      <xsl:choose>
        <xsl:when test="function-available('dp:pkcs7-decrypt')">
          <xsl:copy-of select="dp:pkcs7-decrypt(., $pkcs7-decrypt-args)"/>
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
        <!-- Successful decryption -->
        <!-- The output ffd extracts just the binary data node as the output of this stylesheet -->
        <xsl:copy-of select="$result"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- Failed decryption -->
        <xsl:message dp:priority="error" dp:id="{$DPLOG_CRYPTO_PKCS7_DECRYPTION_FAILED}" terminate="yes">
          <dp:with-param value="{$result/results/error}"/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

</xsl:stylesheet>
