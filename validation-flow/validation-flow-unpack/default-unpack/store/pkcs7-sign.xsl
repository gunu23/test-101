<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007, 2019. All Rights Reserved.
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
    <description>Generate a PKCS#7 signature</description>
    <descriptionId>store.pkcs7-sign.dpsummary.description</descriptionId>
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
    <displayId>store.pkcs7-sign.param.input-encoding.display</displayId>
    <default>none</default>
  </dp:param>

  <xsl:param name="dpconfig:output-encoding" select="'pem'"/>
  <dp:param name="dpconfig:output-encoding" type="dmPKCS7ObjectEncoding" xmlns="">
    <display>Output Encoding Format</display>
    <displayId>store.pkcs7-sign.param.output-encoding.display</displayId>
    <default>pem</default>
  </dp:param>

  <xsl:param name="dpconfig:old-smime" select="'on'"/>
  <dp:param name="dpconfig:old-smime" type="dmToggle" xmlns="">
    <display>Use Old S/MIME Type</display>
    <displayId>store.pkcs7-sign.param.old-smime.display</displayId>
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
    <descriptionId>store.pkcs7-sign.param.old-smime.description</descriptionId>
    <default>on</default>
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
    <displayId>store.pkcs7-sign.param.binary-data.display</displayId>
    <description markup="html"><p>Setting to 'on', the default, indicates the data being signed is
    true binary (contains valid 8-bit data) and should not be canonicalized before signing
    because this may corrupt the data.  Setting to 'off' means the data is not binary and it's
    okay to canonicalize line endings before signing.</p>
    <p>When creating a detached S/MIME signature ("Output Encoding Format" is "S/MIME" and
    "Include Content Data" is 'off') setting "Binary Data" to 'off' may produce an unverifiable
    signature since the data is not canonicalized as expected for an S/MIME message.  True
    binary data should be base64 encoded before signing with a detached S/MIME signature.
    "Binary Data" may be set 'off' for base64 encoded data.</p></description>
    <descriptionId>store.pkcs7-sign.param.binary-data.description</descriptionId>
    <default>on</default>
  </dp:param>

  <xsl:param name="dpconfig:include-textplain-header" select="'off'"/>
  <dp:param name="dpconfig:include-textplain-header" type="dmToggle" xmlns="">
    <display>Include text/plain Header</display>
    <displayId>store.pkcs7-sign.param.include-textplain-header.display</displayId>
    <description>If the "Output Encoding Format" is 'S/MIME' and the "Binary Data" switch is
    'off' then setting this switch to 'on' causes a "Content-Type: text/plain" MIME header to be
    prepended to the data before it's signed (i.e. it's part of the signed data).  The default
    is 'off'. Some S/MIME clients expect a MIME header as part of the data.</description>
    <descriptionId>store.pkcs7-sign.param.include-textplain-header.description</descriptionId>
    <default>off</default>
  </dp:param>

  <xsl:param name="dpconfig:signers" select="''"/>
  <dp:param name="dpconfig:signers" type="dmReference" reftype="CryptoIdentCred" vector="true" xmlns="">
    <display>Signers</display>
    <displayId>store.pkcs7-sign.param.signers.display</displayId>
    <description>The CryptoIdentCred (certificate and private key) for each signer.</description>
    <descriptionId>store.pkcs7-sign.param.signers.description</descriptionId>
  </dp:param>

  <xsl:param name="dpconfig:include-content" select="'on'"/>
  <dp:param name="dpconfig:include-content" type="dmToggle" xmlns="">
    <display>Include Content Data</display>
    <displayId>store.pkcs7-sign.param.include-content.display</displayId>
    <description>Setting to 'on', the default, causes the content data to be included in the
    PKCS#7 signature object.  Setting to 'off' produces a detached signature (the content is not
    included in the PKCS#7 signature object but is separate).</description>
    <descriptionId>store.pkcs7-sign.param.include-content.description</descriptionId>
    <default>on</default>
  </dp:param>

  <xsl:param name="dpconfig:include-signers-certificate" select="'on'"/>
  <dp:param name="dpconfig:include-signers-certificate" type="dmToggle" xmlns="">
    <display>Include Signer's Certificate</display>
    <displayId>store.pkcs7-sign.param.include-signers-certificate.display</displayId>
    <description>Setting to 'on', the default, causes the signer's certificate to be included in
    the signature.  Setting to 'off' means the signer's certificate is not included and so must
    be supplied by other means to an entity verifying the signature.  If there is more than one
    signer then this switch applies to all of them</description>
    <descriptionId>store.pkcs7-sign.param.include-signers-certificate.description</descriptionId>
    <default>on</default>
  </dp:param>

  <xsl:param name="dpconfig:include-ca-certificates" select="'on'"/>
  <dp:param name="dpconfig:include-ca-certificates" type="dmToggle" xmlns="">
    <display>Include CA Certificates</display>
    <displayId>store.pkcs7-sign.param.include-ca-certificates.display</displayId>
    <description>Setting to 'on', the default, causes the CA certificates in the signer's
    CryptoIdentCred to be included in the signature, if there are any.  Setting to 'off' means
    these certificates are not included and may need to be supplied by other means to an entity
    verifying the signature.  If there is more than one signer then this switch applies to all
    of them.</description>
    <descriptionId>store.pkcs7-sign.param.include-ca-certificates.description</descriptionId>
    <default>on</default>
  </dp:param>

  <xsl:param name="dpconfig:include-auth-attributes" select="'on'"/>
  <dp:param name="dpconfig:include-auth-attributes" type="dmToggle" xmlns="">
    <display>Include Authenticated (Signed) Attributes</display>
    <displayId>store.pkcs7-sign.param.include-auth-attributes.display</displayId>
    <description>Setting to 'on', the default, causes authenticated (signed) attributes for
    contentType, signingTime, and messageDigest to be included in the PKCS#7 signature.  This is
    typically desirable, though there may be some situations in which it is helpful to not have
    any attributes included.</description>
    <descriptionId>store.pkcs7-sign.param.include-auth-attributes.description</descriptionId>
    <default>on</default>
  </dp:param>

  <xsl:param name="dpconfig:include-cms-alg-protect-attribute" select="'off'"/>
  <dp:param name="dpconfig:include-cms-alg-protect-attribute" type="dmToggle" xmlns="">
    <display>Include CMS Algorithm Protection Attribute</display>
    <displayId>store.pkcs7-sign.param.include-cms-alg-protect-attribute.display</displayId>
    <description>Setting to 'on' causes authenticated (signed) attributes to include the
    CMS Algorithm Protection attribute (defined in rfc6211) in the PKCS#7 signature.
    This attribute includes digest and signature algorithms and associated parameters.</description>
    <descriptionId>store.pkcs7-sign.param.include-cms-alg-protect-attribute.description</descriptionId>
    <default>off</default>
    <ignored-when>
      <condition evaluation="property-does-not-equal">
        <parameter-name>dpconfig:include-auth-attributes</parameter-name>
        <value>on</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:additional-certificates" select="''"/>
  <dp:param name="dpconfig:additional-certificates" type="dmReference" reftype="CryptoCertificate"
    vector="true" xmlns="">
    <display>Additional Certificates</display>
    <displayId>store.pkcs7-sign.param.additional-certificates.display</displayId>
    <description>A list of additional certificates to include in the PKCS#7 object.  Also see
    the "Include Certificates Only" configuration parameter.</description>
    <descriptionId>store.pkcs7-sign.param.additional-certificates.description</descriptionId>
  </dp:param>

  <xsl:param name="dpconfig:certificates-only" select="'off'"/>
  <dp:param name="dpconfig:certificates-only" type="dmToggle" xmlns="">
    <display>Include Certificates Only</display>
    <displayId>store.pkcs7-sign.param.certificates-only.display</displayId>
    <description>When set to 'on' this indicates the output should be a PKCS#7 object which is a
    "bag of certificates".  The object contains all of the "Additional Certificates", if
    specified.  Plus, when Signers are specified the "Include Signer's Certificate" and "Include
    CA Certificates" switches are respected.  It is not necessary to specify any Signers
    though. Any input data is ignored and not included in the object, nor is a signature
    produced (so the setting of the "Include Content" switch is ignored, as well as the settings
    for any switches related to attributes).</description>
    <descriptionId>store.pkcs7-sign.param.certificates-only.description</descriptionId>
    <default>off</default>
  </dp:param>

  <xsl:param name="dpconfig:algorithm" select="'rsa-sha1'"/>
  <dp:param name="dpconfig:algorithm" type="dmPKCS7SigningAlgorithm" xmlns="">
    <display>Signature algorithm</display>
    <description>The signature algorithm used for PKCS#7 signing.</description>
    <default>rsa-sha1</default>
  </dp:param>

  <xsl:param name="dpconfig:output-metadata-context" select="'_cryptobin'"/>
  <dp:param name="dpconfig:output-metadata-context" type="dmString" xmlns="">
    <display>Name of Context Variable Holding Output Metadata</display>
    <displayId>store.pkcs7-sign.param.output-metadata-context.display</displayId>
    <description>The output of PKCS#7 sign is the signed object.  Additionally, metadata about
    the signature is written to a special context variable for later access.  This parameter is
    the name of the context the metadata should be written to.  Metadata includes things like
    error information.  The string "var://context/" is automatically prepended to this
    name.</description>
    <descriptionId>store.pkcs7-sign.param.output-metadata-context.description</descriptionId>
    <default>_cryptobin</default>
  </dp:param>

  <xsl:template match="/">
    <xsl:variable name="pkcs7-sign-args" xmlns="">
      <arguments>
        <!-- Arguments related to the input data -->
        <input
          encoding="{$dpconfig:input-encoding}"
          binary-data="{$dpconfig:binary-data}"/>

        <!-- Arguments related to the output data -->
        <output
          algorithm="{$dpconfig:algorithm}"
          encoding="{$dpconfig:output-encoding}"
          old-smime="{$dpconfig:old-smime}"
          include-content="{$dpconfig:include-content}"
          include-signers-certificate="{$dpconfig:include-signers-certificate}"
          include-ca-certificates="{$dpconfig:include-ca-certificates}"
          certificates-only="{$dpconfig:certificates-only}"
          include-auth-attributes="{$dpconfig:include-auth-attributes}"
          include-cms-alg-protect-attribute="{$dpconfig:include-cms-alg-protect-attribute}"
          include-textplain-header="{$dpconfig:include-textplain-header}"/>

        <!-- Names of idcred, one for each signer-->
        <xsl:variable name="signers">
          <xsl:copy-of select="dpfunc:parse-parameter-vector($dpconfig:signers)"/>
        </xsl:variable>

        <signers>
          <xsl:for-each select="$signers/entry">
            <signer><xsl:value-of select="."/></signer>
          </xsl:for-each>
        </signers>

        <!-- Additional certificates to be included in the signed object.  Those from
             dpconfig:additional-certificates are assumed to be names of certificate objects and
             so use the "name:" convention.  Other certificates using the "cert:" and "ski:"
             conventions could also be placed here manually, for example:

             <certificate>cert:MIID0TCCAzqgAw...</certificate>

             Any certificates specified here are included even if the signers' and CA
             certificates are not included.  -->
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
           <data>signed data object (binary node)</data>
           <error>error message</error>
         </results>

         The "error" element is not present if all went well.
      -->
    <xsl:variable name="result">
      <xsl:choose>
        <xsl:when test="function-available('dp:pkcs7-sign')">
          <xsl:copy-of select="dp:pkcs7-sign(., $pkcs7-sign-args)"/>
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
        <!-- Successful signing -->
        <!-- The output ffd extracts just the binary data node as the output of this stylesheet -->
        <xsl:copy-of select="$result"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- Failed signing -->
        <xsl:message dp:priority="error" dp:id="{$DPLOG_CRYPTO_PKCS7_SIGN_FAILED}" terminate="yes">
          <dp:with-param value="{$result/results/error}"/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

</xsl:stylesheet>
