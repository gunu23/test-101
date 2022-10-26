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
    <description>Encrypt content using PKCS#7</description>
    <descriptionId>store.pkcs7-encrypt.dpsummary.description</descriptionId>
  </dp:summary>

  <xsl:output method="xml"/>

  <!-- FFD conversion of binary input into binary node -->
  <dp:input-mapping href="pkcs7-convert-input.ffd" type="ffd"/>
  <!-- FFD conversion of binary node into binary output -->
  <dp:output-mapping href="pkcs7-convert-output.ffd" type="ffd"/>

  <xsl:include href="utilities.xsl" dp:ignore-multiple="yes"/>
  <xsl:include href="store:///dp/msgcat/crypto.xml.xsl" dp:ignore-multiple="yes"/>

  <xsl:param name="dpconfig:input-encoding" select="'none'"/>
  <dp:param name="dpconfig:input-encoding" type="dmPKCS7DataEncoding" xmlns="">
    <display>Input Encoding Format</display>
    <displayId>store.pkcs7-encrypt.param.input-encoding.display</displayId>
    <default>none</default>
  </dp:param>

  <xsl:param name="dpconfig:output-encoding" select="'pem'"/>
  <dp:param name="dpconfig:output-encoding" type="dmPKCS7ObjectEncoding" xmlns="">
    <display>Output Encoding Format</display>
    <displayId>store.pkcs7-encrypt.param.output-encoding.display</displayId>
    <default>pem</default>
  </dp:param>

  <xsl:param name="dpconfig:old-smime" select="'on'"/>
  <dp:param name="dpconfig:old-smime" type="dmToggle" xmlns="">
    <display>Use Old S/MIME Type</display>
    <displayId>store.pkcs7-encrypt.param.old-smime.display</displayId>
    <description markup="html">    
    When set to <b>on</b> the S/MIME Content-Type header uses the MIME Subtype format 
    prior to RFC2311. When set to <b>off</b> the S/MIME Content-Type header uses the 
    MIME Subtype format described in RFC2311. The default is <b>on</b>.

    The early MIME Subtypes format prior to RFC2311 included an x- prefix. For exmample, 
    "application/x-pkcs7-mime", "application/x-pkcs7-signature", or "application/x-pkcs10". 
    RFC2311 defines a new MIME subtypes format withouth the x- prefix. RFC2311 states the 
    subtypes with or without the x- prefix have the exact same meaning. Specifying this 
    setting depends on which format the backend system supports.    
    </description>
    <descriptionId>store.pkcs7-encrypt.param.old-smime.description</descriptionId>
    <ignored-when>
      <condition evaluation="property-does-not-equal">
        <parameter-name>dpconfig:output-encoding</parameter-name>
        <value>smime</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:binary-data" select="'on'"/>
  <dp:param name="dpconfig:binary-data" type="dmToggle" xmlns="">
    <display>Binary Data</display>
    <displayId>store.pkcs7-encrypt.param.binary-data.display</displayId>
    <description>Setting to 'on', the default, indicates the data being signed is true binary
    (contains valid 8-bit data) and should not be canonicalized before encrypting because this
    may corrupt the data.  Setting to 'off' means the data is not binary and it's okay to
    canonicalize line endings before encrypting.</description>
    <descriptionId>store.pkcs7-encrypt.param.binary-data.description</descriptionId>
    <default>on</default>
  </dp:param>

  <xsl:param name="dpconfig:include-textplain-header" select="'off'"/>
  <dp:param name="dpconfig:include-textplain-header" type="dmToggle" xmlns="">
    <display>Include text/plain Header</display>
    <displayId>store.pkcs7-encrypt.param.include-textplain-header.display</displayId>
    <description>If the "Output Encoding Format" is 'S/MIME' and the "Binary Data" switch is
    'off' then setting this switch to 'on' causes a "Content-Type: text/plain" MIME header to be
    prepended to the data before it's encrypted (i.e. it's part of the encrypted data).  The
    default is 'off'.  Some S/MIME clients expect a MIME header as part of the data.</description>
    <descriptionId>store.pkcs7-encrypt.param.include-textplain-header.description</descriptionId>
    <default>off</default>
  </dp:param>

  <xsl:param name="dpconfig:recipients" select="''"/>
  <dp:param name="dpconfig:recipients" type="dmReference" reftype="CryptoCertificate" vector="true" xmlns="">
    <display>Recipients</display>
    <displayId>store.pkcs7-encrypt.param.recipients.display</displayId>
    <description>Certificate(s) for the recipient(s); used to wrap the symmetric
    content encryption key.</description>
    <descriptionId>store.pkcs7-encrypt.param.recipients.description</descriptionId>
  </dp:param>

  <xsl:param name="dpconfig:algorithm" select="'tripledes-cbc'"/>
  <dp:param name="dpconfig:algorithm" type="dmPKCS7CryptoEncryptionAlgorithm" xmlns="">
    <display>Encryption algorithm</display>
    <displayId>store.pkcs7-encrypt.param.algorithm.display</displayId>
    <description>The symmetric algorithm used for PKCS#7 encryption.</description>
    <descriptionId>store.pkcs7-encrypt.param.algorithm.description</descriptionId>
    <default>tripledes-cbc</default>
  </dp:param>

  <xsl:param name="dpconfig:output-metadata-context" select="'_cryptobin'"/>
  <dp:param name="dpconfig:output-metadata-context" type="dmString" xmlns="">
    <display>Name of Context Variable Holding Output Metadata</display>
    <displayId>store.pkcs7-encrypt.param.output-metadata-context.display</displayId>
    <description>The output of a PKCS#7 encrypt is the encrypted object.  Additionally, metadata
    about the encryption is written to a special context variable for later access.  This
    parameter is the name of the context the metadata should be written to.  Metadata includes
    things like error information.  The string "var://context/" is automatically prepended to
    this name.</description>
    <descriptionId>store.pkcs7-encrypt.param.output-metadata-context.description</descriptionId>
    <default>_cryptobin</default>
  </dp:param>

  <xsl:template match="/">
    <xsl:variable name="pkcs7-encrypt-args" xmlns="">
      <arguments>
        <!-- Arguments related to the input data -->
        <input
          encoding="{$dpconfig:input-encoding}"
          binary-data="{$dpconfig:binary-data}"/>

        <!-- Arguments related to the output data -->
        <output
          encoding="{$dpconfig:output-encoding}"
          old-smime="{$dpconfig:old-smime}"
          include-textplain-header="{$dpconfig:include-textplain-header}"/>

        <algorithm><xsl:value-of select="$dpconfig:algorithm"/></algorithm>

        <!-- The recipients, one certificate for each recipient.  Those from dpconfig:recipients
             are assumed to be names of certificate objects and so use the "name:" convention.
             Other certificates using the "cert:" and "ski:" conventions could also be placed
             here manually, for example:

             <certificate>cert:MIID0TCCAzqgAw...</certificate>
          -->
        <xsl:variable name="recipients">
          <xsl:copy-of select="dpfunc:parse-parameter-vector($dpconfig:recipients)"/>
        </xsl:variable>
        <recipients>
          <xsl:for-each select="$recipients/entry">
            <recipient><xsl:value-of select="concat('name:', .)"/></recipient>
          </xsl:for-each>
        </recipients>
      </arguments>
    </xsl:variable>

    <!-- The return nodeset looks like:

         <results>
           <data>encrypted data object (binary node)</data>
           <error>error message</error>
         </results>

         The "error" element is not present if all went well.
      -->
    <xsl:variable name="result">
      <xsl:choose>
        <xsl:when test="function-available('dp:pkcs7-encrypt')">
          <xsl:copy-of select="dp:pkcs7-encrypt(., $pkcs7-encrypt-args)"/>
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
        <!-- Successful encryption -->
        <!-- The output ffd extracts just the binary data node as the output of this stylesheet -->
        <xsl:copy-of select="$result"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- Failed encryption -->
        <xsl:message dp:priority="error" dp:id="{$DPLOG_CRYPTO_PKCS7_ENCRYPTION_FAILED}" terminate="yes">
          <dp:with-param value="{$result/results/error}"/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>

</xsl:stylesheet>
