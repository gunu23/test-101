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
    <description>Verify a PKCS#7 signature</description>
    <descriptionId>store.pkcs7-verify.dpsummary.description</descriptionId>
  </dp:summary>

  <xsl:output method="xml"/>

  <!-- FFD conversion of binary input into binary node -->
  <dp:input-mapping href="pkcs7-convert-input.ffd" type="ffd"/>
  <!-- FFD conversion of binary node into binary output -->
  <dp:output-mapping href="pkcs7-convert-output.ffd" type="ffd"/>

  <xsl:include href="utilities.xsl" dp:ignore-multiple="yes"/>

  <xsl:param name="dpconfig:input-encoding" select="'pem'"/>
  <dp:param name="dpconfig:input-encoding" type="dmPKCS7ObjectEncoding" xmlns="">
    <display>Input Encoding Format</display>
    <displayId>store.pkcs7-verify.param.input-encoding.display</displayId>
    <default>pem</default>
  </dp:param>

  <xsl:param name="dpconfig:output-encoding" select="'none'"/>
  <dp:param name="dpconfig:output-encoding" type="dmPKCS7DataEncoding" xmlns="">
    <display>Output Encoding Format</display>
    <displayId>store.pkcs7-verify.param.output-encoding.display</displayId>
    <default>none</default>
  </dp:param>

  <xsl:param name="dpconfig:valcred" select="''"/>
  <dp:param name="dpconfig:valcred" type="dmReference" reftype="CryptoValCred" xmlns="">
    <display>Validation Credential</display>
    <displayId>store.pkcs7-verify.param.valcred.display</displayId>
    <description>The Validation Credential to use for validating the signer's certificate.  If
    there is more then one signer this valcred is used for validating all of them.</description>
    <descriptionId>store.pkcs7-verify.param.valcred.description</descriptionId>
  </dp:param>

  <!-- Future enhancement: Not needed right now since full certificate chain checking is not
       performed. -->
  <!--
  <xsl:param name="dpconfig:validation-certificates" select="''"/>
  <dp:param name="dpconfig:validation-certificates" type="dmReference"
    reftype="CryptoCertificate" vector="true" xmlns="">
    <display>Additional Certificates for Certificate Validation</display>
    <displayId>store.pkcs7-verify.param.validation-certificates.display</displayId>
    <description>When validating the signers' certificates these are additional certificates
    which may be used to help build certificate chains for validation.  They may be used in
    conjunction with certificates from inside the PKCS#7 object.</description>
    <descriptionId>store.pkcs7-verify.param.validation-certificates.description</descriptionId>
  </dp:param>
  -->

  <xsl:param name="dpconfig:max-signatures" select="'10'"/>
  <dp:param name="dpconfig:max-signatures" type="dmUInt32" xmlns="">
    <display>Maximum Number of Signatures to Verify</display>
    <displayId>store.pkcs7-verify.param.max-signatures.display</displayId>
    <description>The maximum number of signatures in the PKCS#7 object to verify.  This is
    protection against a Denial-of-Service attack in which an object containing an exceedingly
    large number of signatures is submitted for verification.  The default is 10.  The minimum
    is 1; the maximum is 25.</description>
    <descriptionId>store.pkcs7-verify.param.max-signatures.description</descriptionId>
    <minimum>1</minimum>
    <maximum>25</maximum>
    <default>10</default>
  </dp:param>

  <xsl:param name="dpconfig:additional-certificates" select="''"/>
  <dp:param name="dpconfig:additional-certificates" type="dmReference" reftype="CryptoCertificate"
    vector="true" xmlns="">
    <display>Additional Certificates to Check for Signers</display>
    <displayId>store.pkcs7-verify.param.additional-certificates.display</displayId>
    <description>Additional certificates from which the signers' certificates may be taken.
    This is necessary because each signer's information in the PKCS#7 object does not contain
    the whole certificate but just the Issuer and Serial Number, and there is no requirement
    that the corresponding certificate is included in the object.  Therefore there must be a way
    to specify externally a matching certificate. Also see the "Allow Internal Signers'
    Certificates" parameter.</description>
    <descriptionId>store.pkcs7-verify.param.additional-certificates.description</descriptionId>
  </dp:param>

  <xsl:param name="dpconfig:allow-internal-signers" select="'on'"/>
  <dp:param name="dpconfig:allow-internal-signers" type="dmToggle" xmlns="">
    <display>Allow Internal Signers' Certificates</display>
    <displayId>store.pkcs7-verify.param.allow-internal-signers.display</displayId>
    <description>Setting to 'on', the default, indicates that additional certificates which are
    included in the PKCS#7 object may be searched for each signer's certificate when doing
    signature verification.  If set to 'off' then the certificates in the PKCS#7 object may not
    be used and the signers' certificates must be specified externally (see "Additional
    Certificates to Check for Signers").</description>
    <descriptionId>store.pkcs7-verify.param.allow-internal-signers.description</descriptionId>
    <default>on</default>
  </dp:param>

  <xsl:param name="dpconfig:detached-data-url" select="''"/>
  <dp:param name="dpconfig:detached-data-url" type="dmURL" xmlns="">
    <display>URL Location of Detached Data</display>
    <displayId>store.pkcs7-verify.param.detached-data-url.display</displayId>
    <description>When verifying a detached signature (and the "Input Encoding Format" isn't
    'S/MIME'), the main input message contains the PKCS#7 object and the detached data is
    retrieved from this URL.</description>
    <descriptionId>store.pkcs7-verify.param.detached-data-url.description</descriptionId>
  </dp:param>

  <xsl:param name="dpconfig:detached-data-encoding" select="'none'"/>
  <dp:param name="dpconfig:detached-data-encoding" type="dmPKCS7DataEncoding" xmlns="">
    <display>Detached Data Encoding Format</display>
    <displayId>store.pkcs7-verify.param.detached-data-encoding.display</displayId>
    <description>The encoding format of the detached data which was signed.  The data is decoded
    before it's used for verification.</description>
    <descriptionId>store.pkcs7-verify.param.detached-data-encoding.description</descriptionId>
    <default>none</default>
  </dp:param>

  <xsl:param name="dpconfig:output-metadata-context" select="'_cryptobin'"/>
  <dp:param name="dpconfig:output-metadata-context" type="dmString" xmlns="">
    <display>Name of Context Variable Holding Output Metadata</display>
    <displayId>store.pkcs7-verify.param.output-metadata-context.display</displayId>
    <description>The output of a PKCS#7 verify is the data which was signed.  Additionally,
    metadata about the signature is written to a special context variable for later access.
    This parameter is the name of the context the metadata should be written to.  Metadata
    includes things like the signers.  The string "var://context/" is automatically prepended to
    this name.</description>
    <descriptionId>store.pkcs7-verify.param.output-metadata-context.description</descriptionId>
    <default>_cryptobin</default>
  </dp:param>

  <xsl:template match="/">
    <xsl:variable name="pkcs7-verify-args" xmlns="">
      <arguments>
        <!-- Arguments related to the input data -->
        <input
          encoding="{$dpconfig:input-encoding}"
          max-signatures="{$dpconfig:max-signatures}"
          allow-internal-signers="{$dpconfig:allow-internal-signers}"
          detached-data-encoding="{$dpconfig:detached-data-encoding}"/>

        <!-- Arguments related to the output data -->
        <output
          encoding="{$dpconfig:output-encoding}"/>

        <validation-credential><xsl:value-of select="$dpconfig:valcred"/></validation-credential>

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

        <!-- Future enhancement: Not needed right now since full certificate chain checking is
             not performed. -->
        <!--
        <xsl:variable name="validation-certificates">
          <xsl:copy-of select="dpfunc:parse-parameter-vector($dpconfig:validation-certificates)"/>
        </xsl:variable>

        <validation-certificates>
          <xsl:for-each select="$validation-certificates/entry">
            <certificate><xsl:value-of select="concat('name:', .)"/></certificate>
          </xsl:for-each>
        </validation-certificates>
        -->
      </arguments>
    </xsl:variable>

    <!-- Retrieve the detached data into a binary node.  The returned nodeset looks like:
         <result>
           <binary>***BINARY NODE***</binary>
         </result>
      -->
    <xsl:variable name="detached-data">
      <xsl:if test="$dpconfig:detached-data-url">
        <dp:url-open target="{$dpconfig:detached-data-url}" response="binaryNode"/>
      </xsl:if>
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
           <data>data from the signed object (binary node)</data>
           <error>error message</error>
         </results>

         The signers are provided for use with things like AAA afterward. The signers aren't
         present if validation fails.  The "error" element is not present if all went well.
      -->
    <xsl:variable name="result">
      <xsl:choose>
        <xsl:when test="function-available('dp:pkcs7-verify')">
          <xsl:copy-of select="dp:pkcs7-verify(.,
                               $detached-data,
                               $pkcs7-verify-args)"/>
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
        <!-- Passed verification -->
        <dp:accept/>

        <!-- Save info returned by the extension function for later steps to access -->
        <dp:set-variable name="concat('var://context/', $dpconfig:output-metadata-context, '/signers')"
          value="$result/results/signers"/>

        <!-- The output ffd extracts just the binary data node as the output of this stylesheet -->
        <xsl:copy-of select="$result"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- Failed verification -->
        <dp:reject override="true"><xsl:value-of select="$result/results/error"/></dp:reject>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

</xsl:stylesheet>
