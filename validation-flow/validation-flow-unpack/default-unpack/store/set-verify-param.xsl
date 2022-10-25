<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2016. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
    Verify RSA, DSA or HMAC signatures.

    The common stylesheet for store:verify.xsl and store:verify-hmac.xsl.
    
    !! IT IS NOT INTENDED TO BE USED DIRECTLY!!
    
    This stylesheet must be used indirectly by the store:///verify.xsl
    or store:///verify-hmac.xsl, which now both can verify both symmetrically
    and asymmetrically signed signatures.
-->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpconfig="http://www.datapower.com/param/config"
    xmlns:dpfunc="http://www.datapower.com/extensions/functions"
    xmlns:dpquery="http://www.datapower.com/param/query"
    xmlns:dsig="http://www.w3.org/2000/09/xmldsig#"
    xmlns:dyn="http://exslt.org/dynamic"
    xmlns:wsse11="http://docs.oasis-open.org/wss/oasis-wss-wssecurity-secext-1.1.xsd"
    xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
    xmlns:wsu-d12="http://schemas.xmlsoap.org/ws/2002/07/utility"
    xmlns:wsu-d13="http://schemas.xmlsoap.org/ws/2003/06/utility"
    extension-element-prefixes="dp dpfunc"
    exclude-result-prefixes="dp dpconfig dpfunc dpquery dsig wsse11 wsu wsu-d12 wsu-d13 dyn"
>

  <xsl:output method="xml"/>

  <xsl:include href="store:///dp/msgcat/crypto.xml.xsl" dp:ignore-multiple="yes"/>

  <xsl:param name="dpquery:signer" select="''"/>
  <dp:param name="dpquery:signer" hidden="true" xmlns=""/>

  <xsl:param name="dpconfig:valcred" select="''"/>
  <dp:param name="dpconfig:valcred" type="dmReference" reftype="CryptoValCred" xmlns="">
    <display>Validation Credential</display>
    <displayId>store.set-verify-param.param.valcred.display</displayId>
    <tab-override>basic</tab-override>
    <description>The Validation Credential to use for validating the signer's
    certificate.</description>
    <descriptionId>store.set-verify-param.param.valcred.description</descriptionId>
    <ignored-when>
      <condition evaluation="property-equals">
        <parameter-name>dpconfig:signature-method-type</parameter-name>
        <value>symmetric</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:check-timestamp-elements" select="'on'"/>
  <dp:param name="dpconfig:check-timestamp-elements" type="dmToggle" xmlns="">
    <display>Check Timestamp</display>
    <displayId>store.set-verify-param.param.check-timestamp-elements.display</displayId>
    <description>Setting to 'on', the default, causes an existing Timestamp block to be 
    validated for the number of Timestamp blocks, 'Created' and 'Expires' elements. 
    Setting it to 'on' also enables to control the checking of Created and Expiration times.
    See 'Check Timestamp Created' and 'Check Timestamp Expiration' toggles.  This setting applies
    to the time range specified by NotBefore and NotOnOrAfter of a saml:Conditions. 
    Setting to 'off' prevents checking timestamp blocks for any errors.
     </description>
    <descriptionId>store.set-verify-param.param.check-timestamp-elements.description</descriptionId>
    <default>on</default>
  </dp:param>

  <xsl:param name="dpconfig:check-timestamp-created" select="'off'"/>
  <dp:param name="dpconfig:check-timestamp-created" type="dmToggle" xmlns="">
    <display>Check Timestamp Created</display>
    <displayId>store.set-verify-param.param.check-timestamp-created.display</displayId>
    <description>Setting to 'on', causes an existing Timestamp block to be checked
    for created time. It should always be lesser than the current time. 
    If not, the transaction is terminated. This toggle is activated only when the toggle
    'Check Timestamp' is set to 'on'. Setting to 'off' prevents checking Timestamp Created.
    </description>
    <descriptionId>store.set-verify-param.param.check-timestamp-created.description</descriptionId>
    <default>off</default>
    <ignored-when>
      <condition evaluation="property-does-not-equal">
        <parameter-name>dpconfig:check-timestamp-elements</parameter-name>
        <value>on</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:check-timestamp" select="'on'"/>
  <dp:param name="dpconfig:check-timestamp" type="dmToggle" xmlns="">
    <display>Check Timestamp Expiration</display>
    <displayId>store.set-verify-param.param.check-timestamp.display</displayId>
    <description>Setting to 'on', the default, causes an existing Timestamp block to be checked
    for expiration when an expiration time is specified, and the transaction terminated if the
    Timestamp is expired. This toggle is activated only when the toggle 'Check Timestamp' is set
    to 'on'. Setting to 'off' prevents checking Timestamp expiration.
    </description>
    <descriptionId>store.set-verify-param.param.check-timestamp.description</descriptionId>
    <default>on</default>
    <ignored-when>
      <condition evaluation="property-does-not-equal">
        <parameter-name>dpconfig:check-timestamp-elements</parameter-name>
        <value>on</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:timestamp-expiration-override" select="'0'"/>
  <dp:param name="dpconfig:timestamp-expiration-override" type="dmTimeInterval" xmlns="">
    <display>Timestamp Expiration Override Period</display>
    <displayId>store.set-verify-param.param.timestamp-expiration-override.display</displayId>
    <description>The override expiration period in seconds for the Timestamp checking.  A value of 
    zero (0) means no override.  The default is 0.  The maximum is 630720000 seconds (20 years).
    </description>
    <descriptionId>store.set-verify-param.param.timestamp-expiration-override.description</descriptionId>
    <units>sec</units>
    <unitsDisplayId>store.set-verify-param.param.timestamp-expiration-override.unit.sec</unitsDisplayId>
    <minimum>0</minimum>
    <maximum>630720000</maximum> <!-- 20 years -->
    <default>0</default>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:check-timestamp-elements</parameter-name>
          <value>on</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:check-timestamp</parameter-name>
          <value>on</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:must-be-signed-xpath" select="''"/>
  <dp:param name="dpconfig:must-be-signed-xpath" type="dmXPathExpr" vector="true" xmlns="">
    <display>XPath Expressions Which Must be Signed</display>
    <displayId>store.set-verify-param.param.must-be-signed-xpath.display</displayId>
    <description>If any XPath expressions are configured for this parameter,
      the nodesets which result from the expression, if exist, must be signed. So,
      a signature reference must either sign the result of the XPath
      expression, or an ancestor of the expression nodeset. This configuration
      parameter may be used to express the contents of a SignedElements
      WS-SecurityPolicy assertion.  
    </description>
    <descriptionId>store.set-verify-param.param.must-be-signed-xpath.description</descriptionId>
  </dp:param>

  <xsl:param name="dpconfig:check-signatureconfirmation" select="'off'"/>
  <dp:param name="dpconfig:check-signatureconfirmation" type="dmToggle" xmlns="">
    <display>Must check SignatureConfirmation (WS-Security 1.1)</display>
    <displayId>store.set-verify-param.param.check-signatureconfirmation.display</displayId>
    <description>This will check for SignatureConfirmation according to the requirement
    specified in WS-Security 1.1.  By setting it to 'on', if no SignatureConfirmation is 
    is given in the message, the message will fail the verify step.</description>
    <descriptionId>store.set-verify-param.param.check-signatureconfirmation.description</descriptionId>
    <default>off</default>
  </dp:param>

  <xsl:param name="dpconfig:signatureconfirmation-requested" select="'off'"/>
  <dp:param name="dpconfig:signatureconfirmation-requested" type="dmToggle" xmlns="">
    <display>Save Verified Signatures for Later wsse11:SignatureConfirmation</display>
    <displayId>store.set-verify-param.param.signatureconfirmation-requested.display</displayId>
    <description>If the client sends a signed request and expects to receive WS-Security 1.1 
    SignatureConfirmation back to make sure the signatures verified are the original, then
    we should set this switch to 'on' to save the verified signatures so that a WS-Sec Sign action 
    can insert WS-Security 1.1 SignatureConfirmation elements to the response message for the client. 
    This setting is only effective for the request message.</description>
    <descriptionId>store.set-verify-param.param.signatureconfirmation-requested.description</descriptionId>
    <default>off</default>
  </dp:param>

  <xsl:param name="dpconfig:wssec11-enckey-cache" select="'0'"/>
  <dp:param name="dpconfig:wssec11-enckey-cache" type="dmTimeInterval" xmlns="">
    <display>WS-Security 1.1: EncryptedKeySHA1 Cache Lifetime for the Extracted Token</display>
    <displayId>store.set-verify-param.param.wssec11-enckey-cache.display</displayId>
    <units>sec</units>
    <unitsDisplayId>store.set-verify-param.param.wssec11-enckey-cache.unit.sec</unitsDisplayId>    
    <minimum>0</minimum> <!-- there will be no cache for this -->
    <maximum>604800</maximum> <!-- 7 days, this is chosen arbitrary -->
    <default>0</default>
    <description markup="html"><p>This sets the Cache Lifetime for the extracted
    key material being used during the Verify operation.
    The key material might be an EncryptedKey token, an EncryptedKeySHA1 key identifier,
    or a SAML token, which, if the response must be encrypted/signed, must be put in the cache 
    by using the same key and/or key referencing, such as with EncryptedKeySHA1 or SAML.
    </p>
    <p>If the value is set to 0, the extracted key material will not be cached.</p>
    </description>
    <descriptionId>store.set-verify-param.param.wssec11-enckey-cache.description</descriptionId>
    <ignored-when>
      <condition evaluation="property-equals">
        <parameter-name>dpconfig:signature-method-type</parameter-name>
        <value>asymmetric</value>
      </condition>
    </ignored-when>
  </dp:param>

  <!-- See wssec-utilities.xsl for its use. The xsl:param is also defined there. -->
  <dp:param name="dpconfig:hash-soap-body-eks" type="dmToggle" xmlns="">
    <display>WS-Security 1.1: Extract the Key Protecting SOAP Body for EncryptedKeySHA1</display>
    <displayId>store.set-verify-param.param.hash-soap-body-eks.display</displayId>
    <description>This setting to indicate if an EncryptedKey (or EncryptedKeySHA1),
    used by the SOAP Body signing/encryption, can be referred as EncryptedKeySHA1 later
    when DP generating a message back. <p/>

    When this setting is set to 'on', then the EK/EKSha1 used by the SOAP
    message security, and its SAML Assertion information if existing,  will be cached 
    for EKSha1 to protect the response message.
    If soap Body is not encrypted or signed, then no EKSha1. <p/>

    When this setting is "off", DP will *randomly* cache an EK for that purpose as
    the the default behavior provided by former releases. This randomness usually
    means the last EK or EKSha1 being used by the request rule will be the one for
    EKSha1 in generating the response message.
    </description>
    <descriptionId>store.set-verify-param.param.hash-soap-body-eks.description</descriptionId>
    <default>off</default>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:signature-method-type</parameter-name>
          <value>asymmetric</value>
        </condition>
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:wssec11-enckey-cache</parameter-name>
          <value>0</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:clientprinc" select="''"/>
  <dp:param name="dpconfig:clientprinc" type="dmString" xmlns="">
    <display>Kerberos Signer Principal</display>
    <displayId>store.set-verify-param.param.clientprinc.display</displayId>
    <description>The name of the Kerberos principal that signed the message. This parameter is optional.</description>
    <descriptionId>store.set-verify-param.param.clientprinc.description</descriptionId>
    <ignored-when>
      <condition evaluation="property-equals">
        <parameter-name>dpconfig:signature-method-type</parameter-name>
        <value>asymmetric</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:serverprinc" select="''"/>
  <dp:param name="dpconfig:serverprinc" type="dmString" xmlns="">
    <display>Kerberos Verifier Principal</display>
    <displayId>store.set-verify-param.param.serverprinc.display</displayId>
    <description>The name of the Kerberos principal that will verify the signature.</description>
    <descriptionId>store.set-verify-param.param.serverprinc.description</descriptionId>
    <ignored-when>
      <condition evaluation="property-equals">
        <parameter-name>dpconfig:signature-method-type</parameter-name>
        <value>asymmetric</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:keytab" select="''"/>
  <dp:param name="dpconfig:keytab" type="dmReference" reftype="CryptoKerberosKeytab" xmlns="">
    <display>Kerberos Verifier Keytab</display>
    <displayId>store.set-verify-param.param.keytab.display</displayId>
    <description>The name of the Kerberos Keytab that contains the Kerberos verifier principal's shared secret.</description>
    <descriptionId>store.set-verify-param.param.keytab.description</descriptionId>
    <ignored-when>
      <condition evaluation="property-equals">
        <parameter-name>dpconfig:signature-method-type</parameter-name>
        <value>asymmetric</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:enable-wssec-remote-token" select="'off'"/>
  <dp:param name="dpconfig:enable-wssec-remote-token" type="dmToggle">
    <display>WS-Security 1.1: Retrieve Remote Token</display>
    <displayId>store.set-verify-param.param.enable-wssec-remote-token.display</displayId>
    <description>The WS-Security 1.1 profiles, such as SAML Token Profile,
      specifies a mechanism to refer to the special remote tokens, which can be retrieved if this setting is 'on'
    </description>
    <descriptionId>store.set-verify-param.param.enable-wssec-remote-token.description</descriptionId>
    <default>off</default>
  </dp:param>

  <xsl:param name="dpconfig:remote-token-sslprofile-type" select="'proxy'"/>
  <dp:param name="dpconfig:remote-token-sslprofile-type" type="dmSSLClientConfigType">
    <display>WS-Security 1.1: Remote Token SSL Profile Type</display>
    <displayId>store.set-verify-param.param.remote-token-sslprofile-type.display</displayId>
    <description>The WS-Security 1.1 profiles, such as SAML Token Profile,
      specifies a mechanism to refer to the special remote tokens, which must be retrieved 
      in order to verify its signature.
 
      If the remote side requires secure socket connection, this setting specifies 
      if an SSLClientProfile or SSLProxyProfile object should be used.
    </description>
    <descriptionId>store.set-verify-param.param.remote-token-sslprofile-type.description</descriptionId>
    <default>proxy</default>
    <ignored-when>
      <condition evaluation="property-equals">
        <parameter-name>dpconfig:enable-wssec-remote-token</parameter-name>
        <value>off</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:remote-token-sslprofile" select="''"/>
  <dp:param name="dpconfig:remote-token-sslprofile" type="dmReference" reftype="SSLProxyProfile">
    <display>WS-Security 1.1: Remote Token SSL Proxy Profile (deprecated)</display>
    <displayId>store.set-verify-param.param.remote-token-sslprofile.display</displayId>
    <description>The WS-Security 1.1 profiles, such as SAML Token Profile,
      specifies a mechanism to refer to the special remote tokens, which must be retrieved 
      in order to verify its signature.
 
      If the remote side requires secure socket connection, this setting can be specified 
      with the corresponding SSLProxyProfile object.
    </description>
    <descriptionId>store.set-verify-param.param.remote-token-sslprofile.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:enable-wssec-remote-token</parameter-name>
          <value>off</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:remote-token-sslprofile-type</parameter-name>
          <value>proxy</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:remote-token-sslclientprofile" select="''"/>
  <dp:param name="dpconfig:remote-token-sslclientprofile" type="dmReference" reftype="SSLClientProfile">
    <display>WS-Security 1.1: Remote Token SSL Client Profile</display>
    <displayId>store.set-verify-param.param.remote-token-sslclientprofile.display</displayId>
    <description>The WS-Security 1.1 profiles, such as SAML Token Profile,
      specifies a mechanism to refer to the special remote tokens, which must be retrieved 
      in order to verify its signature.
 
      If the remote side requires secure socket connection, this setting can be specified 
      with the corresponding SSLClientProfile object.
    </description>
    <descriptionId>store.set-verify-param.param.remote-token-sslclientprofile.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:enable-wssec-remote-token</parameter-name>
          <value>off</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:remote-token-sslprofile-type</parameter-name>
          <value>client</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:remote-token-retrieval-idcred" select="''"/>
  <dp:param name="dpconfig:remote-token-retrieval-idcred" type="dmReference" reftype="CryptoIdentCred">
    <display>WS-Security 1.1: Remote Token Identity Credentials</display>
    <displayId>store.set-verify-param.param.remote-token-retrieval-idcred.display</displayId>
    <description>The WS-Security 1.1 profiles, such as SAML Token Profile,
      specifies a mechanism to refer to the special remote tokens, which must be retrieved 
      in order to verify its signature.
 
      If an identity credential is configured for this action, it will be used 
      to sign the SAML assertion retrieval message</description>
    <descriptionId>store.set-verify-param.param.remote-token-retrieval-idcred.description</descriptionId>
    <ignored-when>
      <condition evaluation="property-equals">
        <parameter-name>dpconfig:enable-wssec-remote-token</parameter-name>
        <value>off</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:remote-token-process-uri" select="''"/>
  <dp:param name="dpconfig:remote-token-process-uri" type="dmURL">
    <display>WS-Security 1.1: URL to Process the Remote Token</display>
    <displayId>store.set-verify-param.param.remote-token-process-uri.display</displayId>
    <description>The WS-Security 1.1 profiles, such as SAML Token Profile,
      specifies a mechanism to refer to the special remote tokens, which must be retrieved 
      in order to verify its signature.
 
      The remote WS-Sec token could be signed, encrypted or encoded.
      A firewall or proxy service with different actions can be used to process the
      remote token, either decrypting pieces of a remote SAML assertion, doing a xslt
      transform, or using AAA to assert the token. This setting is the URL for that service,
      which accepts the security token as the request of the SOAP call, and provides the
      final security token as the response if successful.
    </description>
    <descriptionId>store.set-verify-param.param.remote-token-process-uri.description</descriptionId>
    <ignored-when>
      <condition evaluation="property-equals">
        <parameter-name>dpconfig:enable-wssec-remote-token</parameter-name>
        <value>off</value>
      </condition>
    </ignored-when>
  </dp:param>

<!--
  
  Attachments are not supported in the namespaces being implemented
  for WS-Policy "Lite". Add this back in when support for the 
  official Oasis spec is introduced.

  <xsl:param name="dpconfig:must-sign-attachments" select="''"/>
  <dp:param name="dpconfig:must-sign-attachments" type="dmToggle" xmlns="">
    <display>Require Signature over Attachments</display>
    <displayId>store.set-verify-param.param.must-sign-attachments.display</displayId>
    <description>Setting this configuration parameter to "on" indicates
      that any attachments as found in a SOAP with Attachments (SwA)
      message must be signed.</description>
    <descriptionId>store.set-verify-param.param.must-sign-attachments.description</descriptionId>
    <default>off</default>
  </dp:param>
-->
  <xsl:param name="dpconfig:restrict-algorithm" select="'off'"/>
  <dp:param name="dpconfig:restrict-algorithm" type="dmToggle" xmlns="">
    <display>Restrict Signature Algorithm</display>
    <displayId>store.set-verify-param.param.restrict-algorithm.display</displayId>
    <description>Setting this configuration parameter to "on" will require all 
      signatures to be signed using the RSA SHA1 XML signature algorithm,
      whose URI is http://www.w3.org/2000/09/xmldsig#rsa-sha1.</description>
    <descriptionId>store.set-verify-param.param.restrict-algorithm.description</descriptionId>
    <default>off</default>
    <ignored-when>
      <condition evaluation="property-equals">
        <parameter-name>dpconfig:signature-method-type</parameter-name>
        <value>symmetric</value>
      </condition>
    </ignored-when>
  </dp:param>

  <!-- This parameter is optional, it is needed only if we still keep the legacy code 
       path to verify the enveloped-signatures. But as we have enhanced 
       "dp-verify-reference", the value of this setting will not really change the
       result much for the standard signature formats. -->
  <xsl:param name="dpconfig:use-enveloped-transform" select="'on'"/>
  <dp:param name="dpconfig:use-enveloped-transform" type="dmToggle" hidden="true" xmlns="">
    <display>Enveloped Signature Transform</display>
    <displayId>store.set-verify-param.param.use-enveloped-transform.display</displayId>
    <description>Each dsig:Reference determines its enveloped transformation processing.
    If "http://www.w3.org/2000/09/xmldsig#enveloped-signature" 
    transform method is used, the dsig:Reference must use enveloped signature verification,
    if not, the verification shall depend on other C14N methods, e.g. XPath Filter, to 
    determine if the enveloped dsig:Signature element will be included or not.
    </description>
    <descriptionId>store.set-verify-param.param.use-enveloped-transform.description</descriptionId>
    <default>on</default>
  </dp:param>

  <xsl:include href="store:///dp/verify.xsl" dp:ignore-multiple="yes"/>
  <xsl:include href="store:///utilities.xsl" dp:ignore-multiple="yes"/>
  <xsl:include href="store:///set-soap-receiver-param.xsl" dp:ignore-multiple="yes"/>
  <xsl:include href="store:///set-saml-decrypt-verify-param.xsl" dp:ignore-multiple="yes"/>
  <xsl:include href="store:///dp/ws-sx-utils.xsl" dp:ignore-multiple="yes"/>  <!-- for hmac signature verification -->

<!-- Variables pulled out to global level -->

  <xsl:variable name="required-xpaths" 
                select="dpfunc:unite-vector-parameter($dpconfig:must-be-signed-xpath)"/>

  <xsl:variable name="document" select="/"/>

  <xsl:template match="wsse11:SignatureConfirmation">
    <!-- if this is rejecting already, no need to do this check -->
    <!-- Verification of SignatureConfirmation only makes sense on the response flow for us,
         when we generate signature during the request.
         If one exists in the request flow, pass it alongs
         Check signature confirmation only if required.
     -->

    <xsl:if test="(dp:accepting()) and (dp:responding()) and $dpconfig:check-signatureconfirmation='on'">
      <xsl:variable name="signatures" select="dp:variable('var://context/transaction/signatures')"/>
      <xsl:variable name="SCValueAttr" select="./@Value"/>
      <xsl:choose>
        <xsl:when test="count($signatures/Signature) &gt; 0">
          <xsl:choose>
            <xsl:when test="$SCValueAttr = ''">
              <dp:reject>Missing Value attribute for SignatureConfirmation.</dp:reject>
            </xsl:when>
            <xsl:otherwise>
              <xsl:for-each select="$signatures[Signature=$SCValueAttr]">
                <xsl:variable name="matched-signatures">
                  <xsl:copy-of select="dp:variable('var://context/transaction/matched-signatures')"/>
                  <MatchedSignature><xsl:value-of select="$signatures/Signature"/></MatchedSignature>
                </xsl:variable>

                <dp:set-variable name="'var://context/transaction/matched-signatures'" value="$matched-signatures"/>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <!-- original message is not signed, then there is only one SignatureConfirmation with missing Value
           -->
          <xsl:if test="not((count($existing-security-header/wsse11:SignatureConfirmation) = 1) and
                            (not($SCValueAttr)))">
            <dp:reject>There should only be one SignatureConfirmation with empty Value attribute.</dp:reject>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <xsl:template name="combine-xpaths">
    <xsl:param name="xpaths" select="/.."/>

    <xsl:value-of select="$xpaths/entry[1]" />

    <xsl:if test="count($xpaths/entry) &gt; 1">
      <xsl:text> | </xsl:text>
      <xsl:variable name="rest">
        <xsl:copy-of select="$xpaths/entry[position() &gt; 1]" />
      </xsl:variable>
      <xsl:call-template name="combine-xpaths">
        <xsl:with-param name="xpaths" select="$rest" />
      </xsl:call-template>
    </xsl:if>

  </xsl:template>


  <xsl:template name="get-nodeids">
    <xsl:param name="xpaths" select="/.."/>
    <xsl:param name="document" select="/.."/>


<!-- This template is passed a set of xpath expression (each as an <entry> element), and returns
     a set of elements of the form <nodeid ref="foo"/> where "foo" is the NodeId of an element
     in the document that satisfies at least one of the XPaths.
-->

    <xsl:variable name="combined-xpaths">
      <entry>
      <xsl:call-template name="combine-xpaths">
        <xsl:with-param name="xpaths" select="$xpaths" />
      </xsl:call-template>
      </entry>
    </xsl:variable>

    <xsl:variable name="new-nodes">
      <xsl:for-each select="$combined-xpaths/entry">
        <xsl:variable name="expr" select="."/>
        <xsl:for-each select="$document">
          <!--the  xpath may not return one node, loop them. -->
          <xsl:for-each select="dyn:evaluate($expr)">
            <node-id>
              <xsl:attribute name="ref">
                <xsl:value-of select="generate-id(.)"/>
              </xsl:attribute>
            </node-id>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>

<!-- new-nodes holds the set of node-ids selected by any of the xpaths.  But some nodes might
     be included multiple times, so eliminate duplicates before returning the set 
-->
    <xsl:variable name="pruned-nodes">
      <xsl:for-each select="$new-nodes/node-id">
        <xsl:copy-of select=".[not(@ref = preceding-sibling::node-id/@ref)]"/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:copy-of select="$pruned-nodes/node-id"/>

  </xsl:template>


  <xsl:template match="dsig:Signature">
    <!-- We have checked the ws-security message has enforced the actor/role matching,
         now this template, in case of ws-sec signature verification, can simply use the $existing-security-header.
         -->

    <xsl:if test="dp:accepting()">

      <xsl:variable name="wssec-args">

        <xsl:if test="$dpconfig:enable-wssec-remote-token = 'on'">
          <xsl:choose>
            <xsl:when test="$dpconfig:remote-token-sslprofile-type = 'client'">
              <remote-token-retrieval-sslprofile>client:<xsl:value-of select="$dpconfig:remote-token-sslclientprofile"/></remote-token-retrieval-sslprofile>
            </xsl:when>
            <xsl:otherwise>
              <remote-token-retrieval-sslprofile><xsl:value-of select="$dpconfig:remote-token-sslprofile"/></remote-token-retrieval-sslprofile>
            </xsl:otherwise>
          </xsl:choose>
          <remote-token-retrieval-sslprofile><xsl:value-of select="$dpconfig:remote-token-sslprofile"/></remote-token-retrieval-sslprofile>
          <remote-token-process-url><xsl:value-of select="$dpconfig:remote-token-process-uri"/></remote-token-process-url>
          <xsl:if test="$dpconfig:remote-token-retrieval-idcred">
            <xsl:variable name="remote-token-retrieval-idcred-node" select="dp:get-idcred($dpconfig:remote-token-retrieval-idcred, 'object-names')"/>
            <remote-token-retrieval-signerkey><xsl:value-of select="$remote-token-retrieval-idcred-node/idcred/key-name"/></remote-token-retrieval-signerkey>
            <remote-token-retrieval-signercert><xsl:value-of select="$remote-token-retrieval-idcred-node/idcred/cert-name"/></remote-token-retrieval-signercert>
          </xsl:if>
          <xsl:if test="$dpconfig:validate-saml = 'on'">
            <saml-validate-args>
              <validate><xsl:value-of select="$dpconfig:validate-saml"/></validate>
              <skew-time><xsl:value-of select="$dpconfig:saml-skew-time"/></skew-time>
            </saml-validate-args>            
          </xsl:if>
        </xsl:if>

      </xsl:variable>

      <!--  Check if attachments, if present, must be signed.  -->

<!--

  Attachments are not supported in the namespaces being implemented
  for WS-Policy "Lite". Add this back in when support for the 
  official Oasis spec is introduced.

      <xsl:if test="$dpconfig:must-sign-attachments = 'on'">
        <xsl:variable name="ctx-name" select="dp:variable('var://service/multistep/input-context-name')"/>
        <xsl:variable name="attachments" select="dp:variable(concat('var://context/', $ctx-name, '/attachment-manifest'))"/>

        <xsl:variable name="reference-placeholder" select="''"/>
        <xsl:variable name="reference-uris">
          <xsl:for-each select="dsig:SignedInfo/dsig:Reference">
            <xsl:if test="starts-with(@URI, 'cid:')">
              <xsl:value-of select="concat($reference-placeholder, @URI)"/>
            </xsl:if>
          </xsl:for-each>
        </xsl:variable>

        <xsl:for-each select="$attachments//manifest/attachments/attachment/uri">
          <xsl:if test="dp:accepting() and not(contains($reference-uris, .))">
              <dp:reject>Attachment with Content-ID <xsl:value-of select="."/> is not signed; rejecting message</dp:reject>
          </xsl:if>
        </xsl:for-each>
      </xsl:if>
-->
      <!--  End attachment check.  -->

      <!--  Check if the signature algorithm is constrained  -->
      <xsl:if test="$dpconfig:restrict-algorithm = 'on' 
                and dsig:SignedInfo/dsig:SignatureMethod/@Algorithm != 'http://www.w3.org/2000/09/xmldsig#rsa-sha1'">
        <dp:reject>Signature algorithm <xsl:value-of select="dsig:SignedInfo/dsig:SignatureMethod"/> not allowed by policy</dp:reject>
      </xsl:if>
      <!--  End signature algorithm check  -->


      <!--  Check for required signature coverage via XPath expressions.  
            If item is not there, we don't need to worry about it -->

      <xsl:variable name="is-enveloped">
        <xsl:choose>
            <xsl:when test="$dpconfig:use-enveloped-transform = 'off'">
              <xsl:value-of select="dpfunc:is-enveloped-signature(.)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:if test="$dpconfig:must-be-signed-xpath != ''">

<!--        <xsl:variable name="document" select="/"/> -->

        <xsl:variable name="must-be-signed-nodes">
          <xsl:call-template name="get-nodeids">
            <xsl:with-param name="xpaths" select="$required-xpaths"/>
            <xsl:with-param name="document" select="$document"/>
          </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
          <xsl:when test="count($must-be-signed-nodes/node-id) = 0">

<!-- This isn't really an invalid XPath expression.  It just means that the received message contained
     none of the fields that have to be signed, so we can let the message through with no further checking
 -->
            <xsl:message dp:priority="debug" dp:id="{$DPLOG_CRYPTO_VERIFY_INVALID_XPATH}">
              <dp:with-param value="{$required-xpaths}"/>
            </xsl:message>

          </xsl:when>
          <xsl:otherwise>


            <!-- initiate the state. -->
<!--            <xsl:variable name="flag" select="'expression-is-signed'"/> -->
            <dp:set-local-variable name="'signed-nodes'" value="'0'"/>
            <dp:set-local-variable name="'found-already-nodes'" value="''"/>
            
            <xsl:for-each select="$document//dsig:SignedInfo/dsig:Reference">

              <!-- if the xpath points to multiple nodes, each node must be only covered by one
                   signature, otherwise some nodes MAY not be checked. -->

              <xsl:if test="dp:local-variable('signed-nodes') &lt; count($must-be-signed-nodes/node-id)">
                <!-- Other parts of the verification code performs the due 
                     diligence on the format of the Reference URI.
                -->
                <xsl:variable name="uriref" select="@URI"/>
                <xsl:variable name="localref" select="substring($uriref,2)"/>

                <xsl:message dp:priority="debug" dp:id="{$DPLOG_CRYPTO_VERIFY_CHECK_REF}">
                  <dp:with-param value="{$localref}"/>
                </xsl:message>

                <xsl:choose>

                  <xsl:when test="$uriref != '' and
                                  ( starts-with($uriref,'#') = false() or
                                    starts-with($uriref, 'cid:') = true()
                                  )">
                      <!-- ignore non local references or attachment references. -->
                  </xsl:when>

                  <!-- enveloped signature with empty uri reference. All the doc is covered. -->
                  <xsl:when test="$uriref = '' and ('true' = $is-enveloped or 
                                    dsig:Transforms/dsig:Transform[@Algorithm = $URI-DSIG-ENVELOPED-SIG])">
                    <dp:set-local-variable name="'signed-nodes'" value="count($must-be-signed-nodes/node-id)"/>
                  </xsl:when>

                  <!-- Handle the XPath Filter transform. Because the xsl:copy-of result nodeset
                       will have different internal node-id, we have to test the generate-id for
                       each Transform algorithm scenario sepately.-->
                  <xsl:when test="dsig:Transforms/dsig:Transform[@Algorithm = $URI-XPath-filter]">

                    <xsl:variable name="xpathexpr"
                                  select="concat('(//node() | //@* | //namespace::*)[',
                                                 string (dsig:Transforms/dsig:Transform[@Algorithm=$URI-XPath-filter]/dsig:XPath),
                                                 ']')"/>
                    <xsl:variable name="noderef-descendant"
                                  select="dp:xpath-filter($xpathexpr,
                                                          /,
                                                          dsig:Transforms/dsig:Transform[@Algorithm=$URI-XPath-filter]/dsig:XPath)
                                          /descendant-or-self::*"/>
                    <xsl:for-each select="$noderef-descendant">
                      <xsl:variable name="compare-it" select="generate-id()"/>
                      <xsl:if test="$must-be-signed-nodes/node-id[@ref=$compare-it] and not(contains(dp:local-variable('found-already-nodes'),$compare-it))">
                        <dp:set-local-variable name="'signed-nodes'" value="dp:local-variable('signed-nodes') + 1"/>
                        <dp:set-local-variable name="'found-already-nodes'" value="concat(dp:local-variable('found-already-nodes'),$compare-it)"/>
                      </xsl:if>
                    </xsl:for-each>

                  </xsl:when>

                  <!-- Handle the XPath Filter 2.0 transform. -->
                  <xsl:when test="dsig:Transforms/dsig:Transform[@Algorithm = $URI-XPath-filter2]">

                    <xsl:variable name="input-nodeset" select="dpfunc:init-xpath-filter2-input()"/>
                    <xsl:variable name="noderef-descendant"
                                  select="dpfunc:process-xpath-filter2($input-nodeset)/descendant-or-self::*"/>
                    <xsl:for-each select="$noderef-descendant">
                      <xsl:variable name="compare-it" select="generate-id()"/>
                      <xsl:if test="$must-be-signed-nodes/node-id[@ref=$compare-it] and not(contains(dp:local-variable('found-already-nodes'),$compare-it))">
                        <dp:set-local-variable name="'signed-nodes'" value="dp:local-variable('signed-nodes') + 1"/>
                        <dp:set-local-variable name="'found-already-nodes'" value="concat(dp:local-variable('found-already-nodes'),$compare-it)"/>
                      </xsl:if>
                    </xsl:for-each>

                  </xsl:when>

                  <!-- only when there is local reference -->
                  <xsl:otherwise>

                    <xsl:variable name="noderef-descendant"
                                  select="//attribute::*
                                          [.=$localref]
                                          [translate(local-name(),'ID','id')='id' or
                                           local-name()='AssertionID' or
                                           local-name()='RequestID' or
                                           local-name()='ResponseID']
                                          [1]/../descendant-or-self::*"/>
            
                    <!-- Make sure the input XPath expression representing a child node of URI -->

                    <xsl:for-each select="$noderef-descendant">
                      <xsl:variable name="compare-it" select="generate-id()"/>
                      <xsl:if test="$must-be-signed-nodes/node-id[@ref=$compare-it] and not(contains(dp:local-variable('found-already-nodes'),$compare-it))">
                        <dp:set-local-variable name="'signed-nodes'" value="dp:local-variable('signed-nodes') + 1"/>
                        <dp:set-local-variable name="'found-already-nodes'" value="concat(dp:local-variable('found-already-nodes'),$compare-it)"/>
                      </xsl:if>
                    </xsl:for-each>

                  </xsl:otherwise>
                </xsl:choose>
              </xsl:if>  <!-- dp:accepting() -->
<!-- NO!  The above /xsl:if closes the <xsl:if test="dp:local-variable('signed-nodes') &lt; count($must-be-signed-nodes/node-id)"> -->
            </xsl:for-each>

            <xsl:choose>
              <xsl:when test="dp:local-variable('signed-nodes') &gt;= count($must-be-signed-nodes/node-id)">
                <xsl:message dp:priority="debug" dp:id="{$DPLOG_CRYPTO_VERIFY_XPATH_SIGNED}">
                  <dp:with-param value="{$required-xpaths}"/>
                </xsl:message>
              </xsl:when>
              <xsl:otherwise>
                <dp:reject>XPath expression <xsl:value-of select="$required-xpaths"/> not covered by signature</dp:reject>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>

      </xsl:if>
      <!--  End XPath check.  -->


      <xsl:if test="dp:accepting()">
        <!-- determine whether this is symmetric or asymmetric algorithm -->
        <xsl:variable name="sigmech" select="dpfunc:get-signature-method-type(dsig:SignedInfo/dsig:SignatureMethod/@Algorithm)"/>

        <xsl:choose> 
          <!-- start of asymmetric signing -->
          <xsl:when test="$dpconfig:signature-method-type!='symmetric' and ($sigmech = 'asymmetric')">

            <xsl:variable name="signer">

              <xsl:choose>
                <xsl:when test="$signer-configured/asymmetric != ''">
                  <xsl:value-of select="$signer-configured/asymmetric"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:variable name="extracted-signer">
                    <xsl:call-template name="dp-get-signer">
                      <!-- Only the matched Security header should be used to look up signer for a wssec signature,
                           for the non-wssec signatures, the current dsig:Signature will be checked (X509Certificate 
                           is supported.).
                           -->
                      <xsl:with-param name="existing-security-header" select="$existing-security-header"/>
                      <xsl:with-param name="wssec-args" select="$wssec-args"/>
                    </xsl:call-template>
                  </xsl:variable>

                  <xsl:choose>
                    <xsl:when test="$extracted-signer/extracted-signer/status-code = '0'">
                      <xsl:message dp:priority="debug" dp:id="{$DPLOG_CRYPTO_VERIFY_SIGNER_STATUS}">
                        <dp:with-param value="{$extracted-signer/extracted-signer/status-message}"/>
                      </xsl:message>
                      <xsl:value-of select="string($extracted-signer/extracted-signer/signer)"/>
                    </xsl:when>
                    <!-- otherwise reject it. -->
                    <xsl:otherwise>
                      <dp:reject><xsl:value-of select="$extracted-signer/extracted-signer/status-message"/> </dp:reject>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:otherwise>
              </xsl:choose>

            </xsl:variable>

            <xsl:choose>
              <xsl:when test="not(dp:accepting())"/>

              <xsl:when test="'true' = $is-enveloped">
                <xsl:call-template name="dp-verify-enveloped-signature">
                  <xsl:with-param name="node" select="."/>            
                  <xsl:with-param name="certid" select="$signer"/>
                  <xsl:with-param name="validate-certificate" select="true()"/>
                  <xsl:with-param name="valcred-name" select="$dpconfig:valcred"/>
                </xsl:call-template>

                <!-- Bug 12691 - warn about zero-length URI -->
                <xsl:if test="dsig:SignedInfo/dsig:Reference/@URI = ''">
                    <xsl:message dp:priority="warn" dp:id="{$DPLOG_CRYPTO_VERIFY_EMPTY_URI}"/>
                </xsl:if>

              </xsl:when>

              <xsl:otherwise>
                <xsl:call-template name="dp-verify-signature">
                  <xsl:with-param name="node" select="."/>
                  <xsl:with-param name="certid" select='$signer'/>
                  <xsl:with-param name="validate-certificate" select="true()"/>
                  <xsl:with-param name="valcred-name" select="$dpconfig:valcred"/>
                  <xsl:with-param name="existing-security-header" select="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='Security']"/>
                  <xsl:with-param name="wssec-args" select="$wssec-args"/>
                  <xsl:with-param name="required-xpaths" select="$required-xpaths"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>  <!-- handle all the variation of asymmetric signing -->

            <xsl:if test="dp:accepting()">
              <!-- save the signer for dynamic encryption cert if verification is successful, VERY expensive! -->
              <dp:set-variable name="'var://context/transaction/encrypting-cert'" value="string($signer)"/>
            </xsl:if>

          </xsl:when>  <!-- asymmetric signing -->

          <xsl:when test="$dpconfig:signature-method-type!='asymmetric' and ($sigmech = 'symmetric')">
            <xsl:variable name="signer-key">
              <xsl:choose>
                <xsl:when test="$signer-configured/symmetric != ''">
                  <xsl:value-of select="$signer-configured/symmetric"/>
                </xsl:when>
                
                <xsl:when test="./dsig:KeyInfo/dsig:KeyName">
                  <xsl:value-of select="./dsig:KeyInfo/dsig:KeyName"/>
                </xsl:when>

                <xsl:when test="./dsig:KeyInfo/*[local-name()='SecurityTokenReference']">

                  <xsl:variable name="ancillary-key-info">
                    <xsl:if test="$dpconfig:serverprinc != '' and $dpconfig:keytab != ''">
                      <xsl:variable name="apreq"
                        select="dpfunc:extract-kerberos-apreq
                                (concat('keytabname:', $dpconfig:keytab), 
                                 $dpconfig:serverprinc,
                                 $dpconfig:clientprinc,
                                 true())"/>
                      <xsl:choose>
                        <xsl:when test="not($apreq/*)"/> <!-- no kerberos token is available. do nothing. -->
                        <xsl:when test="$apreq/kerberos-error">
                          <dp:reject><xsl:value-of select="$apreq/kerberos-error"/></dp:reject>
                        </xsl:when>

                        <xsl:otherwise>
                          <krbkey><xsl:value-of select="dpfunc:extract-kerberos-session-key($apreq)"/></krbkey>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:if>
                  </xsl:variable>

                  <!-- Check if the Signature is under soap body or not, so that we can cache its
                       symmetric EK if EKS is needed. -->
                  <xsl:call-template name="check-soap-body-eks">
                    <xsl:with-param name="object" select="."/>
                  </xsl:call-template>

                  <xsl:call-template name="dp-resolve-symmetric-key">
                    <xsl:with-param name="str" select="dsig:KeyInfo/*[local-name()='SecurityTokenReference']"/>
                    <xsl:with-param name="existing-security-header" select="$existing-security-header"/>
                    <xsl:with-param name="ancillary-key-info" select="$ancillary-key-info"/>
                    <xsl:with-param name="encryptedkeysha1cache" select="$dpconfig:wssec11-enckey-cache"/>
                    <xsl:with-param name="args" select="$wssec-args"/>
                  </xsl:call-template>
                </xsl:when>

                <xsl:otherwise/>
              </xsl:choose>
            </xsl:variable> <!-- signer-key -->

            <xsl:choose>
              <xsl:when test="not(dp:accepting())"/>

              <xsl:when test="'true' = $is-enveloped"> <!-- the parameter "enveloped" does not matter any more. -->
                <xsl:call-template name="dp-verify-signature-hmac">
                  <xsl:with-param name="keyid" select="$signer-key"/>
                  <xsl:with-param name="enveloped" select="true()"/>
                </xsl:call-template>
              </xsl:when>

              <xsl:otherwise>
                <xsl:call-template name="dp-verify-signature-hmac">
                  <xsl:with-param name="keyid" select="$signer-key"/>
                  <!-- Only the matched Security header should be used to look up signer for a wssec signature,
                       for the non-wssec signatures, the current dsig:Signature will be checked (X509Certificate
                       is supported.).
                    -->
                  <xsl:with-param name="existing-security-header" select="$existing-security-header"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>  <!-- handle all the variation of symmetric signing -->
          </xsl:when>  <!-- symmetric signing -->

          <!-- potential signature error is found. -->
          <xsl:when test="$sigmech = 'unknown'">
            <dp:reject>*Unknown SignatureMethod algorithm: '<xsl:value-of select="dsig:SignedInfo/dsig:SignatureMethod/@Algorithm"/>'*</dp:reject>
          </xsl:when>

          <xsl:otherwise>
            <dp:reject>*The Verification Type configuration '<xsl:value-of select="$dpconfig:signature-method-type"/>' does not allow algorithm '<xsl:value-of select="dsig:SignedInfo/dsig:SignatureMethod/@Algorithm"/>'*</dp:reject>
          </xsl:otherwise>
        </xsl:choose>

        <xsl:if test="dp:accepting()">
      <!-- save off the signature if handling the request, in case the we need to supply 
           SignatureConfirmation on the response side

           This is also relevant in a WSGW or a MPGW that is skipping the response rule.
           Unfortunately, that service rule is read-only.
       -->

          <xsl:if test="$dpconfig:signatureconfirmation-requested='on' and
                        (local-name(self::node()/..) = 'Security')"> 
            <xsl:call-template name="store-signature">
              <xsl:with-param name="verified" select="'on'"/>
              <xsl:with-param name="signature" select="./dsig:SignatureValue"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:if>

      </xsl:if>

    </xsl:if>

  </xsl:template>


  <xsl:template match="/">

    <dp:accept/>

    <xsl:choose>
      <xsl:when test="dpfunc:ambiguous-wssec-actor(key('soap-actor-role', $resolved-actor-role-id), $dpconfig:actor-role-id)">
          <dp:reject>The request was invalid for WS-Security standard, it has more than one Security header for the configured actor: "<xsl:value-of select="$dpconfig:actor-role-id"/>"</dp:reject>
      </xsl:when>

      <!-- If this is a WS-Sec message, only verify the Signatures for the configured actor/role. -->
      <xsl:when test="dpfunc:has-wssec-security()">
          <xsl:variable name="all-signatures" 
                        select="$existing-security-header//dsig:Signature | 
                                /dsig:Signature |
                                /*[local-name()='Envelope']/dsig:Signature |
                                /*[local-name()='Envelope']/*[local-name()='Header']/dsig:Signature |
                                /*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()!='Security']//dsig:Signature |
                                /*[local-name()='Envelope']/*[local-name()='Body']//dsig:Signature 
                                "/>

          <xsl:if test="count($all-signatures) = 0">
            <dp:reject>No signature in the WS-Security message for the configured soap actor/role "<xsl:value-of select="$dpconfig:actor-role-id"/>"!</dp:reject>
          </xsl:if>
          
          <!-- Check the Security's Timestamp, originally it's done with each Signature verification.  -->
          <xsl:if test="$existing-security-header/wsu:Timestamp or $existing-security-header/wsu-d12:Timestamp or $existing-security-header/wsu-d13:Timestamp">
            <xsl:variable name="ts" select="$existing-security-header/*[local-name()='Timestamp']"/>
            <xsl:if test="$ts">
              <xsl:variable name="err">
                <xsl:if test="$dpconfig:check-timestamp-elements = 'on'">            
                  <xsl:value-of select="dpfunc:verify-wssec-timestamp($ts, $dpconfig:check-timestamp-created, 
                                                                      $dpconfig:check-timestamp, 
                                                                      $dpconfig:timestamp-expiration-override)"/>
                </xsl:if>
              </xsl:variable>
              <xsl:if test="$err != ''">
                <dp:reject><xsl:value-of select="$err"/></dp:reject>
              </xsl:if>
            </xsl:if>
          </xsl:if>

          <xsl:if test="$dpconfig:check-signatureconfirmation = 'on'">
            <!-- set the context variable to nothing, so we can use it for SignatureConfirmation compare -->
            <dp:set-variable name="'var://context/transaction/matched-signatures'" value="''"/>
          </xsl:if>

          <!-- verify the security header and the signatures which are not for other soap actors. -->
          <xsl:apply-templates select="$all-signatures | $existing-security-header/wsse11:SignatureConfirmation"/>

          <xsl:if test="dp:accepting() and $dpconfig:check-signatureconfirmation = 'on'">
            <!-- var://context/transaction/signatures contains signature from signing step during request step -->
            <xsl:variable name="signatures-to-confirm" select="dp:variable('var://context/transaction/signatures')"/>
            <xsl:variable name="signatureconfirmation-cnt" select="count($existing-security-header/wsse11:SignatureConfirmation)"/>
            <xsl:variable name="signature-to-confirm-cnt" select="count($signatures-to-confirm/Signature)"/>
            <xsl:choose>
              <xsl:when test="($signatureconfirmation-cnt = 0)">
                 <!-- we want SignatureConfirmation from backend, but none is given -
                      failed the verification.
                  -->
                 <dp:reject>No SignatureConfirmation in the WS-Sec Security header for actor/role "<xsl:value-of select="$dpconfig:actor-role-id"/>".</dp:reject>
              </xsl:when>
              <xsl:when test="($signature-to-confirm-cnt &gt; 0) and
                            ($signatureconfirmation-cnt &gt; 0) and
                            ($signature-to-confirm-cnt != $signatureconfirmation-cnt)">
                <dp:reject>Mismatch number of SignatureConfirmation(s) received by actor "<xsl:value-of select="$dpconfig:actor-role-id"/>" to the Signature(s) sent from request.</dp:reject>
              </xsl:when>
              <xsl:when test=" ($signatureconfirmation-cnt &gt; 0) and
                               ($signature-to-confirm-cnt &gt; 0)">
                <!-- we better verified all the signature with the signature confirmation information -->
                <xsl:variable name='matched-signature' select="dp:variable('var://context/transaction/matched-signatures')"/>
                <xsl:if test="count($matched-signature/MatchedSignature) != $signature-to-confirm-cnt">
                  <dp:reject>Not all signature(s) is confirmed by actor "<xsl:value-of select="$dpconfig:actor-role-id"/>".</dp:reject>
                </xsl:if>
              </xsl:when>
            </xsl:choose>
          </xsl:if>
      </xsl:when>
      <!-- normal xml dsig verification -->
      <xsl:when test="count(//dsig:Signature) = 0">
        <dp:reject>No signature in message!</dp:reject>
      </xsl:when>
      <xsl:otherwise>
        <!-- None wssec message, verify all the dsig:Signature elements -->
        <xsl:apply-templates select="//dsig:Signature"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

</xsl:stylesheet>
