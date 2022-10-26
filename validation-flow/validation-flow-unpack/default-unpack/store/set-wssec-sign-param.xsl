<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2014. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
    Set WS-Security Signing doc/field level related parameters, if those <dp:param>
    are Signing only or has to define differently from ws-sec encryption stylesheets;
    otherwise, please try to inject the new <dp:param/> into set-wssec-common-param.xsl
-->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpconfig="http://www.datapower.com/param/config"
    xmlns:dpfunc="http://www.datapower.com/extensions/functions"
    xmlns:dpquery="http://www.datapower.com/param/query"
    xmlns:dsig="http://www.w3.org/2000/09/xmldsig#"
    xmlns:wsc="http://schemas.xmlsoap.org/ws/2004/04/sc"
    xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
    xmlns:wsse11="http://docs.oasis-open.org/wss/oasis-wss-wssecurity-secext-1.1.xsd"
    xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
    xmlns:xenc="http://www.w3.org/2001/04/xmlenc#"
    extension-element-prefixes="date dp dpfunc"
    exclude-result-prefixes="date dp dpconfig dpfunc dpquery dsig wsc wsse wsse11 wsu xenc"
>

  <xsl:import href="store:///dp/msgcat/crypto.xml.xsl" dp:ignore-multiple="yes"/>
 
  <xsl:include href="store:///set-wssec-common-param.xsl" dp:ignore-multiple="yes"/>

  <xsl:param name="dpconfig:swa-sign-compatibility" select="'1.0'"/>

  <xsl:param name="dpconfig:swa-sign-transform" select="'MIMEContentOnly'"/>

  <xsl:param name="dpconfig:use-asymmetric-key" select="'on'"/>
  <dp:param name="dpconfig:use-asymmetric-key" type="dmToggle" xmlns="">
    <display>Use Asymmetric Key</display>
    <displayId>store.set-wssec-sign-param.param.use-asymmetric-key.display</displayId>
    <description>
      Specifies if an asymmetric key shall be used for RSA/DSA signing or a 
      symmetric key shall be used for HMAC signing. 
      This setting will result in different signing algorithm and KeyInfo output. 
      By default it is "on" meaning the RSA/DSA key is required as the default 
      behavior for WSSec signing; otherwise a symmetric key is 
      required for WSSec HMAC signing.
    </description>
    <descriptionId>store.set-wssec-sign-param.param.use-asymmetric-key.description</descriptionId>
    <tab-override>basic</tab-override>
    <default>on</default>
  </dp:param>

  <xsl:param name="dpconfig:c14nalg" select="'exc-c14n'"/>
  <dp:param name="dpconfig:c14nalg" type="dmCryptoExclusiveCanonicalizationAlgorithm" xmlns="">
    <default>exc-c14n</default>
  </dp:param>

  <xsl:param name="dpconfig:hashalg" select="'sha1'"/>
  <dp:param name="dpconfig:hashalg" type="dmCryptoHashAlgorithm" xmlns=""/>

  <!-- We need to enable/disable RSA/DSA or HMAC settings based on dpconfig:use-asymmetric-key. 
       The following is copied from the set-keypair.xsl, which is used by some 
       other signing stylesheets without dpconfig:use-asymmetric-key setting.
       -->

  <!-- start of the HMAC key. -->

  <xsl:param name="dpconfig:hmac-sigalg" select="'hmac-sha1'"/>
  <dp:param name="dpconfig:hmac-sigalg" type="dmCryptoHMACSigningAlgorithm" xmlns="">
    <tab-override>basic</tab-override>
    <ignored-when>
      <condition evaluation="property-does-not-equal">
        <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
        <value>off</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:symmetric-key-type" select="'sct-available'"/>
  <dp:param name="dpconfig:symmetric-key-type" type="dmSymmetricKeyType" xmlns="">
    <display>Symmetric Key Type</display>
    <displayId>store.set-wssec-sign-param.param.symmetric-key-type.display</displayId>
    <description>
    Specify what type of the symmetric key the HMAC signing will use.  
    By default the value is "sct-available", which uses a key from a 
    WS-SecureConversation security context. The key identified by this parameter
    can be used either directly as the HMAC signature key, or as the base key in 
    a derived key scenario.
    </description>
    <descriptionId>store.set-wssec-sign-param.param.symmetric-key-type.description</descriptionId>
    <tab-override>basic</tab-override>
    <default>sct-available</default>
    <ignored-when>
      <condition evaluation="property-does-not-equal">
        <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
        <value>off</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:algorithm" select="$URI-XENC-3DES-CBC"/>
  <dp:param name="dpconfig:algorithm" type="dmCryptoEncryptionAlgorithm" xmlns="">
    <display>Symmetric Encryption Algorithm</display>
    <displayId>store.set-wssec-sign-param.param.algorithm.display</displayId>
    <description>The symmetric encryption algorithm to use.</description>
    <descriptionId>store.set-wssec-sign-param.param.algorithm.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or"> 
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
          <value>off</value>
        </condition>
        <condition evaluation="property-value-not-in-list">
          <parameter-name>dpconfig:symmetric-key-type</parameter-name>
          <value>encryptedkey</value>
          <value>eks</value>
          <value>saml-symmetric-hok</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:validate-saml" select="'on'"/>
  <dp:param name="dpconfig:validate-saml" type="dmToggle" xmlns="">
    <display>Validate Applicable SAML Assertion</display>
    <displayId>store.set-wssec-sign-param.param.validate-saml.display</displayId>
    <description>Validate the SAML assertion used by the crypto operation</description>
    <descriptionId>store.set-wssec-sign-param.param.validate-saml.description</descriptionId>
    <default>on</default>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
          <value>off</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:symmetric-key-type</parameter-name>
          <value>saml-symmetric-hok</value>
        </condition>
      </condition>
    </ignored-when>  
  </dp:param>

  <xsl:param name="dpconfig:saml-skew-time" select="'0'"/>
  <dp:param name="dpconfig:saml-skew-time" type="dmTimeInterval" xmlns="">
    <display>SAML Skew Time</display>
    <displayId>store.set-wssec-sign-param.param.saml-skew-time.display</displayId>
    <description>Skew time is the difference, in seconds, between the device clock time and other system times.
     When the skew time is set, the SAML assertion expiration takes the time difference into
     account when the appliance consumes SAML tokens. NotBefore is validated with CurrentTime minus SkewTime.
     NotOnOrAfter is validated with CurrentTime plus SkewTime.
    </description>
    <descriptionId>store.set-wssec-sign-param.param.saml-skew-time.description</descriptionId>
    <units>sec</units>
    <unitsDisplayId>store.set-wssec-sign-param.param.saml-skew-time.unit.sec</unitsDisplayId>        
    <minimum>0</minimum>
    <maximum>630720000</maximum>     <!-- 20 years -->
    <default>0</default>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:validate-saml</parameter-name>
          <value>on</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
          <value>off</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:symmetric-key-type</parameter-name>
          <value>saml-symmetric-hok</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:wssec11-enckey-cache" select="'0'"/>
  <dp:param name="dpconfig:wssec11-enckey-cache" type="dmTimeInterval" xmlns="">
    <display>EncryptedKeySHA1 Cache Lifetime for Derived Key</display>
    <displayId>store.set-wssec-sign-param.param.wssec11-enckey-cache.display</displayId>
    <units>sec</units>
    <unitsDisplayId>store.set-wssec-sign-param.param.wssec11-enckey-cache.unit.sec</unitsDisplayId>    
    <minimum>0</minimum> <!-- there will be no cache for this -->
    <maximum>604800</maximum> <!-- 7 days, this is chosen arbitrary -->
    <default>0</default>    
    <description>This is the Cache Lifetime for the generated key.  Setting the value to 0 means the generated key will not be cached.</description>
    <descriptionId>store.set-wssec-sign-param.param.wssec11-enckey-cache.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
          <value>off</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:symmetric-key-type</parameter-name>
          <value>encryptedkey</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:wssec-compatibility</parameter-name>
          <value>1.1</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:clientprinc"/>
  <dp:param name="dpconfig:clientprinc" type="dmString" xmlns="">
    <display>Kerberos Signer Principal</display>
    <displayId>store.set-wssec-sign-param.param.clientprinc.display</displayId>
    <description>The name of the Kerberos principal that will sign the message.</description>
    <descriptionId>store.set-wssec-sign-param.param.clientprinc.description</descriptionId>
    <ignored-when>
      <condition evaluation="property-does-not-equal">
        <parameter-name>dpconfig:symmetric-key-type</parameter-name>
        <value>kerberos</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:serverprinc"/>
  <dp:param name="dpconfig:serverprinc" type="dmString" xmlns="">
    <display>Kerberos Verifier Principal</display>
    <displayId>store.set-wssec-sign-param.param.serverprinc.display</displayId>
    <description>The name of the Kerberos principal that will later verify the signature.</description>
    <descriptionId>store.set-wssec-sign-param.param.serverprinc.description</descriptionId>
    <ignored-when>
      <condition evaluation="property-does-not-equal">
        <parameter-name>dpconfig:symmetric-key-type</parameter-name>
        <value>kerberos</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:keytab"/>
  <dp:param name="dpconfig:keytab" type="dmReference" reftype="CryptoKerberosKeytab" xmlns="">
    <display>Kerberos Keytab</display>
    <displayId>store.set-wssec-sign-param.param.keytab.display</displayId>
    <description>The name of the Kerberos Keytab that contains the signer principal's shared secret.</description>
    <descriptionId>store.set-wssec-sign-param.param.keytab.description</descriptionId>
    <ignored-when>
      <condition evaluation="property-does-not-equal">
        <parameter-name>dpconfig:symmetric-key-type</parameter-name>
        <value>kerberos</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:include href="store:///dp/kerberos-library.xsl" dp:ignore-multiple="yes"/>

  <xsl:param name="dpconfig:kerberos-value-type" select="$URI-KRB5-GSS-APREQ-WSS11"/>
  <dp:param name="dpconfig:kerberos-value-type" type="dmCryptoKerberosBstValueType" xmlns="">
    <default>http://docs.oasis-open.org/wss/oasis-wss-kerberos-token-profile-1.1#GSS_Kerberosv5_AP_REQ</default>
    <display>WS-Security BinarySecurityToken Kerberos ValueType</display>
    <displayId>store.set-wssec-sign-param.param.kerberos-value-type.display</displayId>
    <description>The WS-Security Kerberos Token Profile BinarySecurityToken ValueType to use.</description>
    <descriptionId>store.set-wssec-sign-param.param.kerberos-value-type.description</descriptionId>
    <ignored-when>
      <condition evaluation="property-does-not-equal">
        <parameter-name>dpconfig:symmetric-key-type</parameter-name>
        <value>kerberos</value>
      </condition>
    </ignored-when>
  </dp:param>

  <!-- settings for "static" SSKey symmetric key -->
  <dp:param name="key" type="dmReference" reftype="CryptoSSKey" xmlns="">
    <display>Shared Secret Key</display>
    <displayId>store.set-wssec-sign-param.param.kerberos-value-type.display</displayId>
    <description>The name of the shared secret key to use.  This value overrides any setting of
    the Alternate Shared Secret Key.</description>
    <descriptionId>store.set-wssec-sign-param.param.kerberos-value-type.description</descriptionId>
    <tab-override>basic</tab-override>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
          <value>off</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:symmetric-key-type</parameter-name>
          <value>static</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:key" select="'KEY'"/>
  <dp:param name="dpconfig:key" type="dmString" xmlns="">
    <display>Alternate Shared Secret Key</display>
    <displayId>store.set-wssec-sign-param.param.key.display</displayId>
    <description> The name of the shared secret key to use.  The name may be taken from a query
    parameter called "dpquery:key" by entering here the value "%url%", or from a HTTP header
    named "X-Use-Credentials" by entering here the value "X-Use-Credentials".  This parameter is
    overriden by the Shared Secret Key parameter.</description>
    <descriptionId>store.set-wssec-sign-param.param.key.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
          <value>off</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:symmetric-key-type</parameter-name>
          <value>static</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <!-- The condition to force the .NET interop to use v1.2 WS-SC namespace is gone. 
       The wsp mapping now takes the versioning from its context token and security 
       policy version. With a discussion for wsHTTP/ws2007Http, wsFed/ws2007Fed and 
       custombinding for wsHTTP kerberos, the forced-wssc-capability setting to use
       static 1.2 namespace is not always working, and the new change in wsp-sp.xsl will.
       
       So this parameter is actually in no use any more. It is the right time to 
       comment it out before 3.8.0.0 regression testing starts. 

       If there is a regression we can revisit this code, otherwise FRED_TO_DO
       we should remove this comment and not to set it on by wsp-sp.xsl. Fred 6/16/2006. 
  -->
  <xsl:param name="dpconfig:forced-wssc-capability" select="'off'"/>

  <xsl:param name="dpconfig:include-sct-token" select="'on'"/>

  <xsl:param name="dpquery:key" select="'KEY'"/>

  <xsl:param name="key">
    <xsl:choose>
      <xsl:when test="$dpconfig:key = 'X-Use-Credentials'">
        <xsl:value-of select='dp:http-request-header("X-Use-Credentials")'/>
      </xsl:when>
      <xsl:when test="$dpconfig:key = '*url*'">
        <xsl:value-of select="$dpquery:key"/>
      </xsl:when>
      <xsl:when test="$dpconfig:key = '%url%'">
        <xsl:value-of select="$dpquery:key"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$dpconfig:key"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:param>
  
  <!-- settings for "dkt" symmetric key -->
  <xsl:param name="dpconfig:base-dkt-name" select="''"/>
  <dp:param name="dpconfig:base-dkt-name" type="dmString" xmlns="">
    <display>Name of the Base DKT to Derive a Key</display>
    <displayId>store.set-wssec-sign-param.param.base-dkt-name.display</displayId>
    <description>When the symmetric signing key is obtained from a named
    DerivedKeyToken (DKT), this parameter specifies the token's name. A named
    DKT typically has a "wsc:Properties/wsc:Name" element.
    </description>
    <descriptionId>store.set-wssec-sign-param.param.base-dkt-name.description</descriptionId>
    <tab-override>basic</tab-override>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
          <value>off</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:symmetric-key-type</parameter-name>
          <value>dkt</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <!-- settings for "encryptedkey" symmetric key -->
  <xsl:param name="dpconfig:recipient" select="''"/>
  <dp:param name="dpconfig:recipient" type="dmReference" reftype="CryptoCertificate" xmlns="">
    <display>Certificate of the Encrypted Key's Recipient</display>
    <displayId>store.set-wssec-sign-param.param.recipient.display</displayId>
    <description>It is only visible when deriving a key from an "encryptedkey".
    When the symmetric key type is "encryptedkey", a random key is used as symmetric key
    which can also be used as the shared secret if key derivation is enabled.
    That random key will then be encrypted and returned
    as a xenc:EncryptedKey to the recipient. The one who verifies the signature
    will essentially decrypt the key before using it as the symmetric key.<p/>
    Specify a CryptoCertificate object, with the public certificate of the intended 
    recipient who will verify the signed message. 
    </description>
    <descriptionId>store.set-wssec-sign-param.param.recipient.description</descriptionId>
    <tab-override>basic</tab-override>
    <required-when>
      <condition evaluation="logical-and">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
          <value>off</value>
        </condition>
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:symmetric-key-type</parameter-name>
          <value>encryptedkey</value>
        </condition>
      </condition>
    </required-when>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
          <value>off</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:symmetric-key-type</parameter-name>
          <value>encryptedkey</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <!-- end of the HMAC key. -->

  <xsl:param name="dpconfig:use-key-derivation" select="'off'"/>
  <dp:param name="dpconfig:use-key-derivation" type="dmToggle" xmlns="">
    <display>Use WS-SC Key Derivation</display>
    <displayId>store.set-wssec-sign-param.param.use-key-derivation.display</displayId>
    <description>
      Specifies if the HMAC signing key is a derived key or not.<p/>
      If it is 'on', the retrieved key from the symmetric key source
      will be used as the key derivation base and the derived key is
      is the actual HMAC signing key. In this case a wsc:DerivedKeyToken
      will always accopany with the signature KeyInfo.<p/>
      By default it is "off" meaning the key from the symmetric key source
      will be directly used as the HMAC symmetric key.<p/>
      Please note: the static SSKey can not be used directly as a key derivation
      base as the WS-SC spec requires to put a wsse:SecurityTokenReference for
      DKT and the SSKey dsig:KeyName can not be referred by this reference mechanism. 
    </description>
    <descriptionId>store.set-wssec-sign-param.param.use-key-derivation.description</descriptionId>
    <tab-override>basic</tab-override>
    <default>off</default>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
          <value>off</value>
        </condition>
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:symmetric-key-type</parameter-name>
          <value>static</value>
        </condition>
        <condition evaluation="property-value-not-in-list">
          <parameter-name>dpconfig:wssec-compatibility</parameter-name>
          <value>1.0</value>
          <value>1.1</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <!-- start of the key derivation. -->
  <xsl:include href="store:///dp/ws-sx-utils.xsl" dp:ignore-multiple="yes"/>

  <xsl:param name="dpconfig:wssc-version" select="'1.2'"/>
  <dp:param name="dpconfig:wssc-version" type="dmCryptoWSSXVersion" xmlns="">
    <display>DKT Namespace Version if Unknown</display>
    <displayId>store.set-wssec-sign-param.param.wssc-version.display</displayId>
    <description>The WS-SecureConversation specs to use when it outputs a
    wsc:DerivedKeyToken. If the input message contains a SCT, DKT or a WS-Trust RSTR,
    the output DKT version will match the input WS-SecureConversation namespace.</description>
    <descriptionId>store.set-wssec-sign-param.param.wssc-version.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
          <value>off</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-key-derivation</parameter-name>
          <value>on</value>
        </condition>
        <condition evaluation="property-value-not-in-list">
          <parameter-name>dpconfig:symmetric-key-type</parameter-name>
          <value>dkt</value>
          <value>sct-available</value>
          <value>kerberos</value>
        </condition>
      </condition>
    </ignored-when>
    <default>1.2</default>
  </dp:param>

  <xsl:param name="dpconfig:dkt-length" select="'32'"/>
  <dp:param name="dpconfig:dkt-length" type="dmUInt16" xmlns="">
    <display>Length of the Derived Key</display>
    <displayId>store.set-wssec-sign-param.param.dkt-length.display</displayId>
    <description>
    This setting indicates the size of the derived key.
    </description>
    <descriptionId>store.set-wssec-sign-param.param.dkt-length.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
          <value>off</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-key-derivation</parameter-name>
          <value>on</value>
        </condition>
      </condition>
    </ignored-when>
    <default>32</default>
  </dp:param>

  <xsl:param name="dpconfig:dkt-offset" select="'0'"/>
  <dp:param name="dpconfig:dkt-offset" type="dmUInt16" xmlns="">
    <display>Offset of the Derived Key in the Key Sequence</display>
    <displayId>store.set-wssec-sign-param.param.dkt-offset.display</displayId>
    <description>
    This setting indicates where of the derived key starts in the byte stream
    of the lengthy generated key sequence. The default value is zero. 
    <p>This setting is exclusive with the "Generation" setting described as following.
    Set this setting as an empty string to enable the "Generation" setting.
    </p>
    </description>
    <descriptionId>store.set-wssec-sign-param.param.dkt-offset.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
          <value>off</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-key-derivation</parameter-name>
          <value>on</value>
        </condition>
      </condition>
    </ignored-when>
    <default>0</default>
  </dp:param>

  <xsl:param name="dpconfig:dkt-generation" select="''"/>
  <dp:param name="dpconfig:dkt-generation" type="dmUInt16" xmlns="">
    <display>Generation of the Derived Key in the Key Sequence</display>
    <displayId>store.set-wssec-sign-param.param.dkt-generation.display</displayId>
    <description>
    If a fixed sized key is generated, then this optional setting can be used
    to specify which generation of the key to use. The value of this setting
    is an unsigned long value indicating the index number of the fixed key in
    the lengthy key sequence. It starts with zero. If this setting is set, it
    precedes the above "Offset" setting; that is:
          offset = (generation) * length
    </description>
    <descriptionId>store.set-wssec-sign-param.param.dkt-generation.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
          <value>off</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-key-derivation</parameter-name>
          <value>on</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:dkt-offset</parameter-name>
          <value></value>
        </condition>
      </condition>
    </ignored-when>
    <default></default>
  </dp:param>

  <xsl:param name="dpconfig:dkt-label" select="''"/>
  <dp:param name="dpconfig:dkt-label" type="dmString" xmlns="">
    <display>Label of the Derived Key</display>
    <displayId>store.set-wssec-sign-param.param.dkt-label.display</displayId>
    <description>
    Specify the label string for the wsc:DerivedKeyToken, if not specified, the default
    "WS-SecureConversationWS-SecureConversation" (represented as UTF-8 octets) is used.
    </description>
    <descriptionId>store.set-wssec-sign-param.param.dkt-label.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
          <value>off</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-key-derivation</parameter-name>
          <value>on</value>
        </condition>
        <!-- the "dkt" derivation type will use the value from the parent DKT. -->
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:symmetric-key-type</parameter-name>
          <value>dkt</value>
        </condition>
      </condition>
    </ignored-when>
    <default></default>
  </dp:param>
  <!-- end of the key derivation. -->

  <xsl:param name="dpconfig:sigalg" select="'rsa'"/>
  <dp:param name="dpconfig:sigalg" type="dmCryptoSigningAlgorithm" xmlns="">
    <tab-override>basic</tab-override>
    <ignored-when>
      <condition evaluation="property-does-not-equal">
        <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
        <value>on</value>
      </condition>
    </ignored-when>
  </dp:param>

  <!-- start of the RSA/DSA key pair. -->
  <xsl:param name="defaultkeypair">
    <xsl:choose>
      <xsl:when test="$dpconfig:sigalg = 'dsa'">DSADEFAULT</xsl:when>
      <xsl:otherwise>DEFAULT</xsl:otherwise>
    </xsl:choose>
  </xsl:param>

  <xsl:param name="dpconfig:keypair" select="$defaultkeypair"/>
  <xsl:param name="dpquery:keypair" select="$defaultkeypair"/>
  <dp:param name="dpconfig:keypair" type="dmString" xmlns="">
    <display>Key/Certificate Base Name</display>
    <displayId>store.set-wssec-sign-param.param.keypair.display</displayId>
    <description>The base of the names of the key and certificate to use.  This value is the
    first part of the name used for both the key and certificate.  The end part of the key's
    name is "KEY" and of the certificate's name is "CERT".  For example, enter "foo" if the key
    is named "fooKEY" and the certificate is named "fooCERT".  The base name may be taken from a
    query parameter called "dpquery:keypair" by entering the value "%url%", or from a HTTP
    header named "X-Use-Credentials" by entering the value "X-Use-Credentials".  If the key and
    certificate don't follow the base name naming convention then use the separate Key and
    Certificate parameters instead of this Base Name parameter.</description>
    <descriptionId>store.set-wssec-sign-param.param.keypair.description</descriptionId>
    <ignored-when>
      <condition evaluation="property-does-not-equal">
        <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
        <value>on</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:keypair-key"/>
  <dp:param name="dpconfig:keypair-key" type="dmReference" reftype="CryptoKey" xmlns="">
      <display>Key</display>
      <displayId>store.set-wssec-sign-param.param.keypair-key.display</displayId>
      <description>The key to use.  Setting this overrides any value set in the Key/Certificate
      Base Name.</description>
      <descriptionId>store.set-wssec-sign-param.param.keypair-key.description</descriptionId>
      <ignored-when>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
          <value>on</value>
        </condition>
      </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:keypair-cert"/>
  <dp:param name="dpconfig:keypair-cert" type="dmReference" reftype="CryptoCertificate" xmlns="">
      <display>Certificate</display>
      <displayId>store.set-wssec-sign-param.param.keypair-cert.display</displayId>
      <description>The certificate to use.  Setting this overrides any value set in the
      Key/Certificate Base Name.</description>
      <descriptionId>store.set-wssec-sign-param.param.keypair-cert.description</descriptionId>
      <ignored-when>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
          <value>on</value>
        </condition>
      </ignored-when>
  </dp:param>

  <xsl:param name="pair">
    <xsl:choose>
      <xsl:when test="$dpconfig:keypair = 'X-Use-Credentials'">
        <xsl:value-of select='dp:http-request-header("X-Use-Credentials")'/>
      </xsl:when>
      <xsl:when test="$dpconfig:keypair = '*url*'">
        <xsl:value-of select="$dpquery:keypair"/>
      </xsl:when>
      <xsl:when test="$dpconfig:keypair = '%url%'">
        <xsl:value-of select="$dpquery:keypair"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$dpconfig:keypair"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:param>

  <xsl:variable name="pair-key">
    <xsl:choose>
      <xsl:when test="$dpconfig:keypair-key != ''">
        <xsl:value-of select="$dpconfig:keypair-key"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat($pair, 'KEY')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="pair-cert">
    <xsl:choose>
      <xsl:when test="$dpconfig:keypair-cert != ''">
        <xsl:value-of select="$dpconfig:keypair-cert"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat($pair, 'CERT')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <!-- end of the RSA/DSA key pair. -->

  <!-- ws-security common dp:param definition. -->
  <xsl:include href="store:///set-soap-sender-param.xsl" dp:ignore-multiple="yes"/>

  <xsl:param name="dpconfig:token-reference-mechanism" select="'Direct'"/>
  <dp:param name="dpconfig:token-reference-mechanism" type="dmCryptoWSSSignatureTokenReferenceMechanism" xmlns="">
    <default>Direct</default>
    <ignored-when>
      <condition evaluation="logical-and">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
          <value>off</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:symmetric-key-type</parameter-name>
          <value>encryptedkey</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:symmetric-key-type</parameter-name>
          <value>kerberos</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>


  <xsl:param name="dpconfig:wss-x509-token-type" select="'X509'"/>
  <dp:param name="dpconfig:wss-x509-token-type" type="dmCryptoWSSX509TokenType" xmlns="">
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="logical-and">
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
            <value>off</value>
          </condition>
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:symmetric-key-type</parameter-name>
            <value>encryptedkey</value>
          </condition>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:token-reference-mechanism</parameter-name>
          <value>Direct</value>
        </condition>
        <condition evaluation="property-value-not-in-list">
          <parameter-name>dpconfig:wssec-compatibility</parameter-name>
          <value>1.0</value>
          <value>1.1</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <!-- the id-cred parameter is not wssec settings, but it is governed by dpconfig:wss-x509-token-type for now.
       we can move it up once the id-cred is used for all signing scenarios.
       -->
  <xsl:param name="dpconfig:signature-idcred" select="''"/>
  <dp:param name="dpconfig:signature-idcred" type="dmReference" reftype="CryptoIdentCred" xmlns="">
      <display>Identity Credential</display>
      <displayId>store.set-wssec-sign-param.param.signature-idcred.display</displayId>
      <description>The identity credential used to generate the signature. 
      This is currently only applicable when the BinarySecurityToken 
      ValueType is either "#PKCS7" or "#X509PKIPathv1". The valcred key is
      used to generate the signature itself, and the associated certificates
      are placed in the WS-Security BinarySecurityToken in the chosen encoding
      format.</description>
      <descriptionId>store.set-wssec-sign-param.param.signature-idcred.description</descriptionId>
      <ignored-when>
        <condition evaluation="logical-and">
            <condition evaluation="property-does-not-equal">
                <parameter-name>dpconfig:wss-x509-token-type</parameter-name>
                <value>PKCS7</value>
            </condition>
            <condition evaluation="property-does-not-equal">
                <parameter-name>dpconfig:wss-x509-token-type</parameter-name>
                <value>PKIPath</value>
            </condition>
        </condition>
      </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:wss-x509-token-profile-1.0-binarysecuritytoken-reference-valuetype"
    select="'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3'"/>
  <dp:param name="dpconfig:wss-x509-token-profile-1.0-binarysecuritytoken-reference-valuetype"
    type="dmCryptoWSSX509TokenProfile10BinarySecurityTokenReferenceValueType" xmlns="">
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="logical-and">
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
            <value>off</value>
          </condition>
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:symmetric-key-type</parameter-name>
            <value>encryptedkey</value>
          </condition>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:token-reference-mechanism</parameter-name>
          <value>Direct</value>
        </condition>
        <condition evaluation="property-value-not-in-list">
          <parameter-name>dpconfig:wssec-compatibility</parameter-name>
          <value>1.0</value>
          <value>1.1</value>
        </condition> 
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:wss-x509-token-type</parameter-name>
          <value>X509</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:wss-x509-token-profile-1.0-keyidentifier-valuetype"
    select="'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509SubjectKeyIdentifier'"/>
  <dp:param name="dpconfig:wss-x509-token-profile-1.0-keyidentifier-valuetype"
    type="dmCryptoWSSX509TokenProfile10KeyIdentifierValueType" xmlns="">
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="logical-and">
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
            <value>off</value>
          </condition>
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:symmetric-key-type</parameter-name>
            <value>encryptedkey</value>
          </condition>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:token-reference-mechanism</parameter-name>
          <value>KeyIdentifier</value>
        </condition>
        <condition evaluation="property-value-not-in-list">
          <parameter-name>dpconfig:wssec-compatibility</parameter-name>
          <value>1.0</value>
          <value>1.1</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:skitype" select="'pkix'"/>
  <dp:param name="dpconfig:skitype" type="dmCryptoSKIType" xmlns="">
    <description>The form of the Subject Key Identifier to use. This
    parameter is only relevant when the WS-Security Version is 1.0/1.1 and
    the Token Reference Mechanism is "KeyIdentifier".</description>
    <descriptionId>store.set-wssec-sign-param.param.skitype.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="logical-and">
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
            <value>off</value>
          </condition>
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:symmetric-key-type</parameter-name>
            <value>encryptedkey</value>
          </condition>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:token-reference-mechanism</parameter-name>
          <value>KeyIdentifier</value>
        </condition>
        <condition evaluation="property-value-not-in-list">
          <parameter-name>dpconfig:wssec-compatibility</parameter-name>
          <value>1.0</value>
          <value>1.1</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <dp:dynamic-namespace prefix="wsse" select="$wsse-uri"/>
  <dp:dynamic-namespace prefix="wsu" select="$wsu-uri"/>

  <xsl:param name="dpconfig:include-inline-cert" select="'off'"/>
  <dp:param name="dpconfig:include-inline-cert" hidden="true" type="dmToggle" xmlns="">
    <display>Include Signer's Certificate In-line</display>
    <displayId>store.set-wssec-sign-param.param.include-inline-cert.display</displayId>
    <description>Setting to 'on' causes the signer's certificate to be included in the Signature
    element inside a second KeyInfo block.  This may aid compatibility with certain
    applications.</description>
    <descriptionId>store.set-wssec-sign-param.param.include-inline-cert.description</descriptionId>
    <default>off</default>
    <ignored-when>
      <condition evaluation="property-does-not-equal">
        <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
        <value>on</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:include-second-id" select="'off'"/>
  <dp:param name="dpconfig:include-second-id" hidden="true" type="dmToggle" xmlns="">
    <display>Include Second Id Attribute</display>
    <displayId>store.set-wssec-sign-param.param.include-second-id.display</displayId>
    <description>Setting to 'on' causes the output message to include a plain "id" attribute on
    the SOAP Body element in addition to the normal "wsu:Id" attribute.  This may aid
    compatibility with certain applications.</description>
    <descriptionId>store.set-wssec-sign-param.param.include-second-id.description</descriptionId>
    <default>off</default>
  </dp:param>

  <xsl:param name="dpconfig:include-timestamp" select="'on'"/>
  <dp:param name="dpconfig:include-timestamp" type="dmToggle" xmlns="">
    <display>Include Timestamp</display>
    <displayId>store.set-wssec-sign-param.param.include-timestamp.display</displayId>
    <description>Setting to 'on', the default, causes the output message to include a Timestamp
    block.</description>
    <descriptionId>store.set-wssec-sign-param.param.include-timestamp.description</descriptionId>
    <default>on</default>
  </dp:param>

  <xsl:param name="dpconfig:timestamp-expiration-period" select="'300'"/>
  <dp:param name="dpconfig:timestamp-expiration-period" type="dmTimeInterval" xmlns="">
    <display>Timestamp Expiration Period</display>
    <displayId>store.set-wssec-sign-param.param.timestamp-expiration-period.display</displayId>
    <units>sec</units>
    <unitsDisplayId>store.set-wssec-sign-param.param.timestamp-expiration-period.unit.sec</unitsDisplayId>    
    <minimum>0</minimum>
    <maximum>31536000</maximum> <!-- 365 days -->
    <default>300</default>
    <description>The expiration period in seconds for the Timestamp (and therefore of the
    security semantics in this signature).  A value of zero (0) means no expiration.  The
    default is 300 seconds (5 minutes).  The maximum is 31536000 seconds (365 days).</description>
    <descriptionId>store.set-wssec-sign-param.param.timestamp-expiration-period.description</descriptionId>
    <ignored-when>
      <condition evaluation="property-does-not-equal">
        <parameter-name>dpconfig:include-timestamp</parameter-name>
        <value>on</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:check-timestamp-elements" select="'on'"/>
  <dp:param name="dpconfig:check-timestamp-elements" type="dmToggle" xmlns="">
    <display>Check Timestamp</display>
    <displayId>store.set-wssec-sign-param.param.check-timestamp-elements.display</displayId>
    <description>Setting to 'on', the default, causes an existing Timestamp block to be 
    validated for the number of Timestamp blocks, 'Created' and 'Expires' elements. 
    Setting it to 'on' also enables to control the checking of Created and Expiration times.
    See 'Check Timestamp Created' and 'Check Timestamp Expiration' toggles.  This setting applies
    to the time range specified by NotBefore and NotOnOrAfter of a saml:Conditions. 
    Setting to 'off' prevents checking timestamp blocks for any errors.
     </description>
    <descriptionId>store.set-wssec-sign-param.param.check-timestamp-elements.description</descriptionId>
    <default>on</default>
  </dp:param>

  <xsl:param name="dpconfig:check-timestamp-created" select="'off'"/>
  <dp:param name="dpconfig:check-timestamp-created" type="dmToggle" xmlns="">
    <display>Check Timestamp Created</display>
    <displayId>store.set-wssec-sign-param.param.check-timestamp-created.display</displayId>
    <description>Setting to 'on', causes an existing Timestamp block to be checked
    for created time. It should always be lesser than the current time. 
    If not, the transaction is terminated. This toggle is activated only when the toggle
    'Check Timestamp' is set to 'on'. Setting to 'off' prevents checking Timestamp Created.
    </description>
    <descriptionId>store.set-wssec-sign-param.param.check-timestamp-created.description</descriptionId>
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
    <displayId>store.set-wssec-sign-param.param.check-timestamp.display</displayId>
    <description>Setting to 'on', the default, causes an existing Timestamp block to be checked
    for expiration when an expiration time is specified, and the transaction terminated if the
    Timestamp is expired. This toggle is activated only when the toggle 'Check Timestamp' is set
    to 'on'. Setting to 'off' prevents checking Timestamp expiration.
    </description>
    <descriptionId>store.set-wssec-sign-param.param.check-timestamp.description</descriptionId>
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
    <displayId>store.set-wssec-sign-param.param.timestamp-expiration-override.display</displayId>
    <units>sec</units>
    <unitsDisplayId>store.set-wssec-sign-param.param.timestamp-expiration-override.unit.sec</unitsDisplayId>    
    <minimum>0</minimum>
    <maximum>630720000</maximum> <!-- 20 years -->
    <default>0</default>
    <description>The override expiration period in seconds for the Timestamp checking.  A value of
    zero (0) means no override.  The default is 0.  The maximum is 630720000 seconds (20 years).
    </description>
    <descriptionId>store.set-wssec-sign-param.param.timestamp-expiration-override.description</descriptionId>
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

  <xsl:param name="dpconfig:sign-binarysecuritytoken" select="'off'"/>
  <dp:param name="dpconfig:sign-binarysecuritytoken" type="dmToggle" xmlns="">
    <display>Sign BinarySecurityToken</display>
    <displayId>store.set-wssec-sign-param.param.sign-binarysecuritytoken.display</displayId>
    <description>If the Token Reference Mechanism is "Direct" then by default
    the inserted BinarySecurityToken is not signed.  Setting this switch to
    'on' causes the BinarySecurityToken to be signed.  In other words, the
    digital signature will cover the BinarySecurityToken along with the other
    signed portions of the message.  Compatibility with certain versions of BEA
    WebLogic may require setting this parameter to 'on'.</description>
    <descriptionId>store.set-wssec-sign-param.param.sign-binarysecuritytoken.description</descriptionId>
    <default>off</default>
    <ignored-when>
      <condition evaluation="logical-not">
        <condition evaluation="logical-or">
          <condition evaluation="logical-and">
            <condition evaluation="property-equals">
              <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
              <value>on</value>
            </condition>
            <condition evaluation="property-equals">
              <parameter-name>dpconfig:token-reference-mechanism</parameter-name>
              <value>Direct</value>
            </condition>
          </condition>
          <condition evaluation="logical-and">
            <condition evaluation="property-equals">
              <parameter-name>dpconfig:use-asymmetric-key</parameter-name>
              <value>off</value>
            </condition>
            <condition evaluation="property-does-not-equal">
              <parameter-name>dpconfig:recipient</parameter-name>
              <value></value>
            </condition>
          </condition>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:include-signatureconfirmation" select="'off'"/>
  <dp:param name="dpconfig:include-signatureconfirmation" type="dmToggle" xmlns="">
    <display>Include SignatureConfirmation</display>
    <displayId>store.set-wssec-sign-param.param.include-signatureconfirmation.display</displayId>
    <description>SignatureConfirmation only applies to WS-Security 1.1.  Setting
    this switch to 'on' causes SignatureConfirmation to be generated if the request
    contains "ds:SignatureValue".</description>
    <descriptionId>store.set-wssec-sign-param.param.include-signatureconfirmation.description</descriptionId>
    <default>off</default>
    <ignored-when>
      <condition evaluation="property-does-not-equal">
        <parameter-name>dpconfig:wssec-compatibility</parameter-name>
        <value>1.1</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:expect-signatureconfirmation" select="'off'"/>
  <dp:param name="dpconfig:expect-signatureconfirmation" type="dmToggle" xmlns="">
    <display>Expect Verifier to Return wsse11:SignatureConfirmation</display>
    <displayId>store.set-wssec-sign-param.param.expect-signatureconfirmation.display</displayId>
    <description>If we expect the returned response message contains WS-Security 1.1 
    SignatureConfirmation, set this switch to 'on' to save the generated signature 
    value, so that a Verify action can process the response to verify the WS-Security 1.1 
    SignatureConfirmation.</description>
    <descriptionId>store.set-wssec-sign-param.param.expect-signatureconfirmation.description</descriptionId>
    <default>off</default>
    <ignored-when>
      <condition evaluation="property-does-not-equal">
        <parameter-name>dpconfig:wssec-compatibility</parameter-name>
        <value>1.1</value>
      </condition>
    </ignored-when>
  </dp:param>

  <!-- See bz#26904 for detail regarding the change and choice of default value. -->
  <xsl:param name="dpconfig:security-header-layout" select="'strict'"/>
  <dp:param name="dpconfig:security-header-layout" type="dmSecurityHeaderLayout" xmlns="">
    <display>WS-Security Security Header Layout</display>
    <displayId>store.set-wssec-sign-param.param.security-header-layout.display</displayId>
    <description>The layout rule to apply to the security header.</description>
    <descriptionId>store.set-wssec-sign-param.param.security-header-layout.description</descriptionId>
    <default>strict</default>
  </dp:param>

  <xsl:param name="dpconfig:enable-wssec-str-transform" select="'off'"/>
  <dp:param name="dpconfig:enable-wssec-str-transform" type="dmToggle" xmlns="">
    <display>Enable STR-Transform to Sign WS-Security Token Reference</display>
    <displayId>store.set-wssec-sign-param.param.enable-wssec-str-transform.display</displayId>
    <description>If the target to be signed has a wsse:SecurityTokenReference,
    especially for the field level wssec signing, the STR Dereference Transform (STRDT) 
    can be used to sign the security token that the STR pointing at rather the STR element 
    itself.</description>
    <descriptionId>store.set-wssec-sign-param.param.enable-wssec-str-transform.description</descriptionId>
    <default>off</default>
  </dp:param>

  <xsl:param name="dpconfig:extra-prefix-list" select="''"/>
  <dp:param name="dpconfig:extra-prefix-list" type="dmString" xmlns="">
    <display>Extra Inclusive Namespaces Prefix List</display>
    <displayId>store.set-wssec-sign-param.param.extra-prefix-list.display</displayId>
    <summary>Specify the namespaces that are additionally needed to include for the exclusive canonicalization.</summary>
    <description markup="html">
    By default, no value is needed and all the visibly utilized namespaces are protected.
    Otherwise, specify the namespace prefixes that are additionally signed with 
    the target nodeset. <p/>

    It is strongly recommended to put empty string for this setting and have 
    better compatibility for exclusive canonicalization. This setting is enabled 
    only when the STR-Transform is used per some special requirement for WAS.<p/>

    The signature with exclusive canonicalization transformation algorithms always 
    covers the namespaces that are being visibly utilized by the target element or 
    attribute. When a namespace is inherited from parent or ancestor elements 
    and not being visibly utilized by the target nodes, this setting
    can be used to include that namespace and protect that namespace and its URI.<p/>

    The #default prefix string is defined by the specification to include the
    namespace has no prefix. <p/>
    </description>
    <descriptionId>store.set-wssec-sign-param.param.extra-prefix-list.description</descriptionId>
    <default></default>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-value-not-in-list">
          <parameter-name>dpconfig:c14nalg</parameter-name>
          <value>exc-c14n</value>
          <value>exc-c14n-comments</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:enable-wssec-str-transform</parameter-name>
          <value>on</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:wssec-str-compatibility" select="'standard'"/>
  <dp:param name="dpconfig:wssec-str-compatibility" type="dmSTRCompatible" xmlns="">
    <type name="dmSTRCompatible" base="enumeration" validation="range">
      <display>STR-Transform Reference Format</display>
      <displayId>store.set-wssec-sign-param.param.wssec-str-compatibility.display</displayId>
      <description>
        Select what type of Reference is used by the WS Security Token Reference for the STR-Transform.
      </description>
      <descriptionId>store.set-wssec-sign-param.param.wssec-str-compatibility.description</descriptionId>
      <value-list>
        <value name="standard" default="true">
          <display>Default/Standard</display>
          <displayId>store.set-wssec-sign-param.param.wssec-str-compatibility.value1.display</displayId>
          <description>
            Use the default STR format that is standard or determined mostly compatible to the
            input message and configuration settings.
          </description>
          <descriptionId>store.set-wssec-sign-param.param.wssec-str-compatibility.value1.description</descriptionId>
        </value>
        <value name="direct">
          <display>Direct Reference</display>
          <displayId>store.set-wssec-sign-param.param.wssec-str-compatibility.value2.display</displayId>
          <description>
            The STR will try to use the WS-Sec Direct references, which may not be compatible to
            a standard or specification.
          </description>
          <descriptionId>store.set-wssec-sign-param.param.wssec-str-compatibility.value2.description</descriptionId>
        </value>
        <value name="keyid">
          <display>Key Identifier Reference</display>
          <displayId>store.set-wssec-sign-param.param.wssec-str-compatibility.value3.display</displayId>
          <description>
            The STR will try to use the WS-Sec Key Identifier references, which may not be compatible to
            a standard or specification. In case of generating STR-Transform signed local SAML 2.0 assertion
            for WAS 7, it is required to use this option.
          </description>
          <descriptionId>store.set-wssec-sign-param.param.wssec-str-compatibility.value3.description</descriptionId>
        </value>
      </value-list>
    </type>
    <default>standard</default>
    <ignored-when>
      <condition evaluation="property-equals">
        <parameter-name>dpconfig:enable-wssec-str-transform</parameter-name>
        <value>off</value>
      </condition>
    </ignored-when>
  </dp:param>
  <!-- please note: 
    1) for now it is hidden, controled by enable-wssec-str-transform, used by ws-sp.
    2) When STR-Transform other option is enabled, sign it with STR-Transform.  
    3) there are interop issues need to solve for the inclusive c14n, which
    is believed due to the extra namespaces added while signing, such as
    soapenv:mustUnderstand. 
    WS-Sec spec recommended only exclusive c14ns used any way, and
    wssec sign actions don't allow inclusive c14n as valid setting on WebGui.
    -->
  <xsl:param name="dpconfig:sign-keyinfo" select="'off'"/>
  <dp:param name="dpconfig:sign-keyinfo" hidden="true" type="dmToggle" xmlns="">
    <display>Sign the KeyInfo SecurityTokenReference</display>
    <displayId>store.set-wssec-sign-param.param.sign-keyinfo.display</displayId>
    <description>

    Setting to 'on' will also sign the STR element inside of the dsig:KeyInfo generated 
    by this action.
    <p/>

    As required by WS-SecurityPolicy, when ws-sec sign action generates a BST being used
    by the KeyInfo, the STR for this case must be signed with STR-Transform,
    </description>
    <descriptionId>store.set-wssec-sign-param.param.sign-keyinfo.description</descriptionId>
    <default>off</default>
    <ignored-when>
      <condition evaluation="property-equals">
        <parameter-name>dpconfig:enable-wssec-str-transform</parameter-name>
        <value>off</value>
      </condition>
    </ignored-when>
  </dp:param>

  <!-- this turns off the namespace prefix during the STR-Transform, BEA is not
       following the spec, as of WebLogic 10.0 TechPreview 3, on doing this, they
       don't carry the prefix from SecurityTokenReference when they build the BST
       on the fly.
  -->
  <xsl:param name="dpconfig:skip-namespace-prefix-for-strtransform" select="'off'"/>

  <!-- this allow SignatureConfirmation to be added on the request side.
       In WS-SecurityPolicy, with BootstrapPolicy, we short-circuit the process such that
       the traffic is not sent to backend.  So all processing must be done on the request
       side, and without this switch, we can't support SupportSignatureConfirmation Assertion
  -->
  <xsl:param name="dpconfig:add-signatureconfirmation-on-request" select="'off'"/>

  <!-- do we support EncryptedKeySHA1, remove the response side requirement, since in a 
       STS exchange, all are happening on the request traffic
  -->

  <xsl:variable name="use-encryptedkeysha1">
    <xsl:if test="$dpconfig:use-asymmetric-key = 'off' and
                  ($dpconfig:symmetric-key-type = 'eks' or $dpconfig:symmetric-key-type = 'saml-symmetric-hok')">
      <xsl:copy-of select="dp:variable('var://context/transaction/cipherkey')"/>
    </xsl:if>
  </xsl:variable>

  <xsl:include href="store:///dp/sign.xsl" dp:ignore-multiple="yes"/>
  <xsl:include href="store:///utilities.xsl" dp:ignore-multiple="yes"/>

  <xsl:variable name="wsse-idcred-format">
      <xsl:choose>
          <xsl:when test="$dpconfig:wss-x509-token-type = 'PKCS7'">
              <xsl:value-of select="'pkcs7'"/>
          </xsl:when>       
          <xsl:when test="$dpconfig:wss-x509-token-type = 'PKIPath'">
              <xsl:value-of select="'pkipath'"/>
          </xsl:when>
          <xsl:otherwise>       <!-- The default -->
              <xsl:value-of select="''"/>
          </xsl:otherwise>
      </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="wsse-idcred-data">
      <xsl:choose>
          <xsl:when test="$dpconfig:signature-idcred">
              <xsl:copy-of select="dp:get-idcred 
                   ($dpconfig:signature-idcred, 
                    $wsse-idcred-format)"/>
          </xsl:when>
      </xsl:choose>
  </xsl:variable>

  <!-- retrieve the apreq and status from message, cache or prior action. -->
  <xsl:variable name="available-kerberos-token">
    <xsl:if test="$dpconfig:symmetric-key-type = 'kerberos'">
      <xsl:copy-of select="dpfunc:check-kerberos-apreq ($existing-security-header,
                                                        $dpconfig:serverprinc,
                                                        $dpconfig:clientprinc,
                                                        $dpconfig:keytab)"/>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="bst-value-type">
    <xsl:choose>
      <xsl:when test="$dpconfig:wss-x509-token-type='X509'">
        <xsl:value-of select="$dpconfig:wss-x509-token-profile-1.0-binarysecuritytoken-reference-valuetype"/>
      </xsl:when>
      <xsl:when test="$dpconfig:wss-x509-token-type='PKCS7'">
        <xsl:text>http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#PKCS7</xsl:text>
      </xsl:when>
      <xsl:when test="$dpconfig:wss-x509-token-type='PKIPath'">
        <xsl:text>http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509PKIPathv1</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>unspecified</xsl:text>
        <xsl:message dp:id="{$DPLOG_SOAP_INVALID_BST}" dp:priority="error" terminate="yes">
            <dp:with-param value="{$dpconfig:wss-x509-token-type}"/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- EncodingType attribute URI value for WS-Security v1.0 and v1.1 -->
  <xsl:variable name="wssec-b64-encoding">
    <xsl:text>http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary</xsl:text>
  </xsl:variable>

  <!-- stylesheet to process any of the SOAP headers, will be called from the SOAPENV:Header. -->
  <xsl:template match="/*[local-name()='Envelope']/*[local-name()='Header']">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:copy-of select="namespace::*"/>
      <xsl:apply-templates mode="soap-header"/>
      <xsl:if test="dpfunc:test-num-wssec-counter() &lt; 0">
          <!-- no security headers have been used to inject data, we get to add a new header. -->
          <xsl:call-template name="create-security-header"/>
      </xsl:if>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="create-security-header">
    <wsse:Security>
      <xsl:if test="$dpconfig:include-mustunderstand = 'on'">
        <xsl:attribute namespace="{$___soapnsuri___}" name="{concat($___soapnsprefix___, 'mustUnderstand')}">1</xsl:attribute>
      </xsl:if>

      <xsl:if test="$dpconfig:actor-role-id != ''">
        <!-- not to omit the actor/role attribute when there is non empty actor/role. -->
        <xsl:attribute namespace="{$___soapnsuri___}" name="{$___actor_role_attr_name___}"><xsl:value-of select="$dpconfig:actor-role-id"/></xsl:attribute>
      </xsl:if>

      <xsl:call-template name="wssec-sign-node"/>
    </wsse:Security>
  </xsl:template>


  <!-- stylesheet to process any of the SOAP headers, will be called from the SOAPENV:Header. -->
  <xsl:template mode="soap-header" match="*">
    <xsl:choose>
        <!-- we inject our data to this existing security header, do match the namespace!
             if there are more than one security headers? we already faulted the request.-->
        <xsl:when test="namespace-uri() = $wsse-uri and
                        ( count(key('soap-actor-role', $resolved-actor-role-id) | .) =
                          count(key('soap-actor-role', $resolved-actor-role-id)))
                        ">
            <!-- preserve the existing attributes for this security header -->
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:copy-of select="namespace::*"/>

                <!-- we need not to inject the actor/role as this existing Security header already matches the actor/role. -->

                <xsl:if test="$dpconfig:include-mustunderstand = 'on'">
                  <xsl:attribute namespace="{$___soapnsuri___}" name="{concat($___soapnsprefix___, 'mustUnderstand')}">1</xsl:attribute>
                </xsl:if>

                <!-- First copy the base tokens, timestamp, etc,..before copying the derived key tokens, signature elements, etc,..Bug 26904 -->
                <xsl:if test="$dpconfig:security-header-layout = 'strict' or 
                              $dpconfig:security-header-layout = 'Strict'">  <!--  see bug 28629 -->
                  <xsl:copy-of select="./*[not(self::xenc:EncryptedData | self::dsig:Signature | self::xenc:ReferenceList)]"/>
                </xsl:if>

                <xsl:call-template name="wssec-sign-node"/>

                <!-- preserve all the existing nodes -->
                <xsl:choose>
                  <xsl:when test="$dpconfig:security-header-layout = 'strict' or
                                  $dpconfig:security-header-layout = 'Strict'">  <!-- see bug 28629 -->                   
                    <xsl:copy-of select="./*[self::xenc:EncryptedData | self::dsig:Signature | self::xenc:ReferenceList]"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:copy-of select="./*"/>
                  </xsl:otherwise>
                </xsl:choose>
            </xsl:copy>
        </xsl:when>
        <xsl:otherwise>
            <!-- does not match the actor/role
                 Preserve the other wssec header elements, like saml:Assertion etc. -->
            <xsl:copy-of select="."/>
        </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- get the available token from message or from a well know dp variable
       'var://context/ca-out1/store-sct-var', the latter one is applicable for
       any soap actors. -->
  <xsl:variable name="available-sct-token">
    <xsl:if test="$dpconfig:symmetric-key-type = 'sct-available'">
      <xsl:variable name="token-in-header"
                    select="$existing-security-header/*[
                              local-name()='SecurityContextToken' or local-name()='SecureConversationToken'][1]"/>
      <xsl:variable name="token-in-body"
                    select="/*[local-name()='Envelope']/*[local-name()='Body']//*
                              [local-name()='RequestSecurityTokenResponse']/*
                              [local-name()='RequestedSecurityToken']/*
                              [local-name()='SecurityContextToken' or local-name()='SecureConversationToken'][1]"/>

      <xsl:choose>
        <xsl:when test="count($token-in-header) &gt; 0">
          <xsl:copy-of select="$token-in-header"/>
          <location>header</location>
        </xsl:when>
        <xsl:when test="count($token-in-body) &gt; 0">
          <xsl:copy-of select="$token-in-body"/>
          <location>body</location>
        </xsl:when>
        <xsl:otherwise>
          <!-- this is tie to WS-Security Policy processing
               request side : the autogenerated action will store the SCT in the following variable
          -->
          <xsl:copy-of select="dp:variable('var://context/ca-out1/store-sct-var')[1]"/>
          <location>variable</location>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:variable>

  <!-- In case of the intrest of ws-sc processing, check the input message for the spec versions DP supported. -->
  <xsl:variable name="wssc-capability">
    <xsl:choose>
    <!-- FRED_TO_DO, see the comments at definition.
      <xsl:when test="$dpconfig:forced-wssc-capability = 'on'">
        <xsl:copy-of select="dpfunc:get-wssx-compatibility
                             ($dpconfig:wssc-version, 'version')"/>
      </xsl:when>
      -->
      <xsl:when test="$dpconfig:use-asymmetric-key = 'on'">
          <!-- do not waste time to test the wssc capability. -->
      </xsl:when>
      <xsl:when test="$dpconfig:symmetric-key-type = 'sct-available'">
        <xsl:copy-of select="dpfunc:get-wssx-compatibility(
                                    $available-sct-token/*[local-name()='SecurityContextToken' or local-name()='SecureConversationToken'],
                                    'wssc')"/>
        
      </xsl:when>
      <xsl:when test="$dpconfig:symmetric-key-type = 'dkt'">
        <xsl:copy-of select="dpfunc:get-wssx-compatibility(
                ( /*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='Security']/*[local-name()='DerivedKeyToken'] |
                  /*[local-name()='Envelope']/*[local-name()='Body']//*[local-name()='DerivedKeyToken']
                ) , 'wssc')"/>
      </xsl:when>
      <xsl:when test="$dpconfig:use-key-derivation = 'on'">
        <xsl:variable name="wst-response"
                      select="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='IssuedToken'] |
                              /*[local-name()='Envelope']/*[local-name()='Body']//*[local-name()='RequestSecurityTokenResponse']"/> 
        <xsl:choose>
          <xsl:when test="count($wst-response) &gt; 0">
            <!-- In case the input message is a WS-Trust response,
                 the output message shall use the same version for DKT. -->
            <xsl:copy-of select="dpfunc:get-wssx-compatibility($wst-response[1], 'wst')"/>
          </xsl:when>
          <xsl:otherwise> <!-- use the default wssc version. -->
            <xsl:copy-of select="dpfunc:get-wssx-compatibility($dpconfig:wssc-version, 'version')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>

  <dp:dynamic-namespace prefix="wsc" select="$wssc-capability/wssc/namespace-uri"/>

  <!-- this template creates the corresponding elements, including Signature, for the ws-security header.-->
  <xsl:template name="wssec-security-header-content">
    <xsl:param name="nodes-to-sign" select="/.."/>
    <xsl:param name="wssec-data-handling" select="'message'"/>

      <!-- timestamp to output. -->
      <xsl:variable name="timestamp">
        <xsl:variable name="existing-timestamp" select="$existing-security-header/*[local-name()='Timestamp']"/>
        <xsl:choose>
          <xsl:when test="$existing-timestamp">
            <xsl:variable name="err">
              <xsl:if test="$dpconfig:check-timestamp-elements = 'on'">
                <xsl:value-of select="dpfunc:verify-wssec-timestamp($existing-timestamp,
                                                                    $dpconfig:check-timestamp-created, 
                                                                    $dpconfig:check-timestamp, 
                                                                    $dpconfig:timestamp-expiration-override)"/>
              </xsl:if>
            </xsl:variable>
            <xsl:if test="$err != ''">
              <xsl:message dp:id="{$DPLOG_SOAP_ERR}" dp:priority="error" terminate="yes">
                <dp:with-param value="{$err}"/>
              </xsl:message>
            </xsl:if>
          </xsl:when>
          <xsl:when test="$dpconfig:include-timestamp = 'on'">
            <!-- Only add a Timestamp if there isn't already one present -->
            <wsu:Timestamp>
              <xsl:choose>
                <xsl:when test="$dpconfig:wssec-id-ref-type='wsu:Id'"><xsl:attribute name="wsu:Id"><xsl:value-of select="concat('Timestamp-', dp:generate-uuid())"/></xsl:attribute></xsl:when>
                <xsl:otherwise><xsl:attribute name="xml:id"><xsl:value-of select="concat('Timestamp-', dp:generate-uuid())"/></xsl:attribute></xsl:otherwise>
              </xsl:choose>
              <xsl:variable name="now" select="dpfunc:zulu-time()"/>
              <wsu:Created><xsl:value-of select="$now"/></wsu:Created>
              <xsl:if test="$dpconfig:timestamp-expiration-period &gt; 0">
                <wsu:Expires>
                  <xsl:value-of select="date:add($now, date:duration($dpconfig:timestamp-expiration-period))"/>
                </wsu:Expires>
              </xsl:if>
            </wsu:Timestamp>
          </xsl:when>
        </xsl:choose>
      </xsl:variable>

      <xsl:if test="$dpconfig:security-header-layout != 'laxtimestamplast'">
        <xsl:copy-of select="$timestamp/*"/>
      </xsl:if>

      <xsl:variable name="signatureconfirmation">
        <xsl:if test="(dp:responding() or 
                       (not(dp:responding()) and $dpconfig:add-signatureconfirmation-on-request = 'on')) and
                      ($dpconfig:include-signatureconfirmation='on') and
                      ($dpconfig:wssec-compatibility = '1.1')">
          <xsl:variable name="verified-signatures" select="dp:variable('var://context/transaction/verified-signatures')"/> 
          <xsl:choose>
            <xsl:when test="count($verified-signatures/Signature) &gt; 0">
              <xsl:for-each select="$verified-signatures/Signature"> 
                <wsse11:SignatureConfirmation>
                  <!-- wsse11:SignatureConfirmation only allows wsu10:Id. no other id attributes are allowed. the werid attribute name is to workaround bug 14025-->
                  <xsl:attribute name="{concat('wsu10:Id')}" namespace="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
                    <xsl:value-of select="concat('id-', dp:generate-uuid())"/>
                  </xsl:attribute>
                  <xsl:attribute name="Value"><xsl:value-of select='.'/></xsl:attribute>
                </wsse11:SignatureConfirmation>
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <!-- empty SignatureConfirmation if input message is not signed --> 
              <wsse11:SignatureConfirmation>
                  <!-- wsse11:SignatureConfirmation only allows wsu10:Id. no other id attributes are allowed. the werid attribute name is to workaround bug 14025-->
                  <xsl:attribute name="{concat('wsu10:Id')}" namespace="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
                    <xsl:value-of select="concat('id-', dp:generate-uuid())"/>
                  </xsl:attribute>
              </wsse11:SignatureConfirmation>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:if>
      </xsl:variable>
      <xsl:copy-of select="$signatureconfirmation/*"/>

      <xsl:variable name="token-str">
          <xsl:if test="$dpconfig:enable-wssec-str-transform = 'on'">
            <!-- output the new SecurityTokenReference elements if there are tokens need
                 STR-Transform.-->
            <xsl:apply-templates mode="str-transform-nodes" select="$nodes-to-sign"/>
          </xsl:if>
      </xsl:variable>
      <xsl:copy-of select="$token-str/*"/>

      <xsl:choose>
        <!-- RSA/DSA signing. Default behavior for the wssec-sign.xsl. -->
        <xsl:when test="$dpconfig:use-asymmetric-key != 'off'">
          <!-- Build the BinarySecurityToken if doing a Direct reference -->
          <xsl:variable name="bst-id" select="concat('SecurityToken-', dp:generate-uuid())"/>
          <xsl:variable name="BST">
            <xsl:call-template name="create-x509-bst">
              <xsl:with-param name="ref-id" select="$bst-id"/>
              <xsl:with-param name="cert" select="concat('name:', $pair-cert)"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:copy-of select="$BST/*"/>
          <xsl:variable name="BST-for-signing">
            <xsl:if test="$dpconfig:sign-binarysecuritytoken = 'on'">
              <xsl:copy-of select="$BST/*"/>
            </xsl:if>
          </xsl:variable>

          <xsl:variable name="keyid">
            <xsl:choose>
              <xsl:when test="string($dpconfig:signature-idcred)">
                <!-- Beginning of signing using idcreds.  
                     See set-wssec-sign-param.xsk for $wsse-idcred 
                -->
                <xsl:value-of select="$wsse-idcred-data/idcred/key"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select='concat("name:", $pair-key)'/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <xsl:variable name="certid">
            <xsl:choose>
              <xsl:when test="string($dpconfig:signature-idcred)">
                <!-- Since we're only using idcreds for BSTs with PKCS#7
                     or PKIPath, we don't want any <ds:X509> data elements
                     in the <ds:KeyInfo> block. This will change as we fully
                     migrate to using idcreds.

                     Note that it's legal to pass in a cert chain encoded
                     as a series of discrete X.509 certificates, starting 
                     from the signer cert, up to the CA - a future use case?
                -->
                <xsl:value-of select="''"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:if test="$dpconfig:include-inline-cert = 'on'">
                  <xsl:value-of select="concat('name:', $pair-cert)"/>
                </xsl:if>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <xsl:variable name="keyinfo-str">
            <xsl:call-template name="create-token-reference">
              <xsl:with-param name="ref-id" select="$bst-id"/>
              <xsl:with-param name="token-type" select="'x509'"/>
            </xsl:call-template>
          </xsl:variable>

          <xsl:variable name="certinfo">
            <xsl:if test="$dpconfig:include-inline-cert = 'on'">
              <!-- Include the exact contents for the 'certid' KeyInfo block here so we can get
                   wsse:SecurityTokenReference in the right namespace. -->
              <xsl:variable name="crt" select="concat('name:', $pair-cert)"/>
              <wsse:SecurityTokenReference>
                <dsig:X509Data>
                  <dsig:X509Certificate>
                    <xsl:value-of select="dp:base64-cert($crt)"/>
                  </dsig:X509Certificate>
                  <dsig:X509IssuerSerial>
                    <dsig:X509IssuerName><xsl:value-of select="dpfunc:compat-dn(dp:get-cert-issuer($crt), $compat)"/></dsig:X509IssuerName>
                    <dsig:X509SerialNumber><xsl:value-of select="dp:get-cert-serial($crt)"/></dsig:X509SerialNumber>
                  </dsig:X509IssuerSerial>
                </dsig:X509Data>
              </wsse:SecurityTokenReference>
            </xsl:if>
          </xsl:variable>

          <xsl:variable name="STR-for-signing">
            <xsl:if test="$dpconfig:enable-wssec-str-transform = 'on'">
              <xsl:copy-of select="$token-str/*"/>
            </xsl:if>

            <xsl:if test="$dpconfig:sign-keyinfo = 'on'">
              <xsl:copy-of select="$keyinfo-str/*"/>
            </xsl:if>
          </xsl:variable>
          
          <xsl:choose>
            <xsl:when test="$wssec-data-handling = 'message'">
              <xsl:call-template name="dp-sign">
                <xsl:with-param name="node" 
                                select="$nodes-to-sign[ not($dpconfig:enable-wssec-str-transform='on' and local-name()='Assertion')] | 
                                        $timestamp/* | $signatureconfirmation/* | $BST-for-signing/* | $STR-for-signing/*"/>
                <!-- Empty refuri means URIs are pulled from $node -->
                <xsl:with-param name="refuri" select="''"/>
                <xsl:with-param name="keyid" select="$keyid"/>
                <xsl:with-param name="certid" select="$certid"/>
                <xsl:with-param name="sigalg" select='$dpconfig:sigalg'/>
                <xsl:with-param name="c14nalg" select='$dpconfig:c14nalg'/>
                <xsl:with-param name="extra-prefix-list" select="normalize-space($dpconfig:extra-prefix-list)"/>
                <xsl:with-param name="hashalg" select='$dpconfig:hashalg'/>
                <xsl:with-param name="keyinfo" select="$keyinfo-str"/>
                <xsl:with-param name="certinfo" select="$certinfo"/>
                <xsl:with-param name="store-signature" select="$dpconfig:expect-signatureconfirmation"/>
                <xsl:with-param name="existing-security-header" select="$nodes-to-sign | $existing-security-header | $BST/*"/>
                <xsl:with-param name="enable-str-transform" select="$dpconfig:enable-wssec-str-transform"/>
                <xsl:with-param name="wssec-args">
                  <xsl:if test="$dpconfig:skip-namespace-prefix-for-strtransform = 'on'">
                    <skip-namespace-prefix-for-strtransform>
                      <xsl:value-of select="$dpconfig:skip-namespace-prefix-for-strtransform"/>
                    </skip-namespace-prefix-for-strtransform>
                  </xsl:if>
                </xsl:with-param>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="dp-sign-attachments">
                <xsl:with-param name="node" select="$nodes-to-sign | $timestamp/* | $signatureconfirmation/* | $BST-for-signing/*"/>
                <!-- Empty refuri means URIs are pulled from $node -->
                <xsl:with-param name="refuri" select="''"/>
                <xsl:with-param name="keyid" select="$keyid"/>
                <xsl:with-param name="certid" select="$certid"/>
                <xsl:with-param name="sigalg" select='$dpconfig:sigalg'/>
                <xsl:with-param name="c14nalg" select='$dpconfig:c14nalg'/>
                <xsl:with-param name="hashalg" select='$dpconfig:hashalg'/>
                <xsl:with-param name="keyinfo" select="$keyinfo-str"/>
                <xsl:with-param name="certinfo" select="$certinfo"/>
                <xsl:with-param name="store-signature" select="$dpconfig:expect-signatureconfirmation"/>
                <xsl:with-param name="signheaders" select="$dpconfig:swa-sign-transform = 'MIMEContentAndHeader'"/>
                <xsl:with-param name="swaversion" select="$dpconfig:swa-sign-compatibility"/>
                <xsl:with-param name="wssec-sign" select="$wssec-data-handling"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>

        <!-- HMAC signing with/out key derivation. -->
        <xsl:otherwise>
          <!-- output of the symmetric key or key derivation-result. -->
          <xsl:variable name="symmetric-result">

            <xsl:choose>

              <!-- the default behavior, use the SCT if it is available. -->
              <xsl:when test="$dpconfig:symmetric-key-type = 'sct-available'">
                <xsl:variable name="sct" select="$available-sct-token/*[local-name()='SecurityContextToken' or local-name()='SecureConversationToken']"/>
                <xsl:variable name="sct-id" select="$sct/@*[translate(local-name(), 'ID', 'id')='id']"/>
                <xsl:variable name="new-sct-id">
                  <xsl:choose>
                    <xsl:when test="$available-sct-token/location = 'body'">
                      <xsl:value-of select="concat('SCT-', dp:generate-uuid())"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="$sct-id"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
 
                <xsl:variable name="symmetric-tokens">
                  <!-- If the Security Context Token was not in the WS-Security
                       header, put it in (this means it was in the body), which is
                       actually not according to spec.
                  -->
                  <xsl:choose>
                    <xsl:when test="$dpconfig:include-sct-token = 'on' and
                                    $available-sct-token/location = 'variable'">
                      <xsl:copy-of select="$available-sct-token/*[local-name()='SecurityContextToken']"/>
                    </xsl:when>
                    <xsl:when test="$new-sct-id != $sct-id">
                      <xsl:for-each select="$sct">
                        <xsl:copy>
                          <xsl:choose>
                            <xsl:when test="$dpconfig:wssec-id-ref-type='wsu:Id'">
                              <xsl:attribute name="wsu:Id">
                                <xsl:value-of select="$new-sct-id"/>
                              </xsl:attribute>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:attribute name="xml:id">
                                <xsl:value-of select="$new-sct-id"/>
                              </xsl:attribute>
                            </xsl:otherwise>
                          </xsl:choose>
                          <xsl:copy-of select="@*[translate(local-name(),'ID','id') != 'id']"/>
                          <xsl:copy-of select="namespace::* | comment()"/>
                          <xsl:copy-of select="child::*"/>
                        </xsl:copy>
                      </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise/>
                  </xsl:choose>

                  <xsl:if test="$dpconfig:use-key-derivation = 'on'">
                    <xsl:call-template name="create-dkt-token">
                      <xsl:with-param name="ref-id" select="$new-sct-id"/>
                    </xsl:call-template>
                  </xsl:if>
                </xsl:variable>

                <symmetric-token>
                  <xsl:copy-of select="$symmetric-tokens"/>
                </symmetric-token>
                <xsl:choose>
                  <xsl:when test="$dpconfig:use-key-derivation = 'on'">
                    <symmetric-key>
                      <xsl:call-template name="dp-generate-derived-key">
                        <xsl:with-param name="from-token" select="$sct"/>
                        <xsl:with-param name="dkt" select="$symmetric-tokens/*[local-name()='DerivedKeyToken']"/>
                        <xsl:with-param name="existing-security-header" select="$existing-security-header"/>
                      </xsl:call-template>
                    </symmetric-key>
                  </xsl:when>
                  <xsl:otherwise>
                    <symmetric-key>
                      <!-- fetch the base-64 encoded key from Security Context. -->
                      <xsl:variable name="context-id" >
                        <xsl:value-of select="$sct/*[local-name()='Identifier']"/>
                      </xsl:variable>
                      <xsl:variable name="context-instance">
                        <xsl:value-of select="$sct/*[local-name()='Instance']"/>
                      </xsl:variable>
                      <xsl:copy-of select="dp:aaa-get-context-info($context-id, 'transaction-key', $context-instance)"/>
                    </symmetric-key>
                    <symmetric-token-reference>
                      <xsl:call-template name="create-token-reference">
                        <xsl:with-param name="ref-id" select="$new-sct-id"/>
                      </xsl:call-template>
                    </symmetric-token-reference>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>

              <!-- Derive a key using a Kerberos APREQ message.
              -->
              <xsl:when test="$dpconfig:symmetric-key-type = 'kerberos'">
                <!-- Ensure the Kerberos APREQ was actually created. If not,
                     log the error and terminate. If so, create a BST for it and
                     store the key identifier so that in future messages, which may
                     reference the APREQ by the key identifier value and
                     not include the BST itself, we can still process the
                     key identifier reference.
                -->
                <xsl:if test="$available-kerberos-token/kerberos-error">
                  <xsl:message dp:id="{$DPLOG_SOAP_KRB_ERR}" dp:priority="error" terminate="yes">
                    <dp:with-param value="{$available-kerberos-token/kerberos-error}"/>
                  </xsl:message>
                </xsl:if>
                <xsl:variable name="new-kerberos-bst">
                  <xsl:if test="$available-kerberos-token/kerberos-bst[@new='true']">
                    <xsl:call-template name="create-kerberos-bst">
                      <xsl:with-param name="apreq" select="$available-kerberos-token"/>
                      <xsl:with-param name="vt" select="$dpconfig:kerberos-value-type"/>
                      <xsl:with-param name="id-attr-name" select="$dpconfig:wssec-id-ref-type"/>
                    </xsl:call-template>
                  </xsl:if>
                </xsl:variable>

                <!-- Use the BST either the one from the message or the newly generated one -->
                <xsl:variable name="kerberos-bst-id"
                              select="($new-kerberos-bst/*[local-name()='BinarySecurityToken'] |
                                       $available-kerberos-token/kerberos-bst/*[local-name()='BinarySecurityToken'])
                                       [1]/@*[translate(local-name(), 'ID','id') = 'id']"/>

                <xsl:variable name="b64-sessionkey"
                              select="dpfunc:extract-kerberos-session-key($available-kerberos-token)"/>
                
                <xsl:variable name="symmetric-tokens">
                  <!-- the kerberos BST token, if it is not already in the security header. -->
                  <xsl:copy-of select="$new-kerberos-bst/*"/>

                  <xsl:if test="$dpconfig:use-key-derivation = 'on'">
                    <xsl:call-template name="create-dkt-token">
                      <xsl:with-param name="ref-id" select="$kerberos-bst-id"/>
                    </xsl:call-template>
                  </xsl:if>
                </xsl:variable>

                <symmetric-token>
                  <xsl:copy-of select="$symmetric-tokens"/>
                </symmetric-token>

                <symmetric-key>
                  <xsl:choose>
                    <xsl:when test="$dpconfig:use-key-derivation = 'on'">
                      <xsl:call-template name="dp-generate-derived-key">
                        <xsl:with-param name="from-token">
                          <session-key><xsl:value-of select="$b64-sessionkey"/></session-key>
                        </xsl:with-param>
                        <xsl:with-param name="dkt" select="$symmetric-tokens/*[local-name()='DerivedKeyToken']"/>
                        <xsl:with-param name="existing-security-header" select="$existing-security-header"/>
                      </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise> 
                      <xsl:value-of select="$b64-sessionkey"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </symmetric-key>

                <symmetric-token-reference>
                  <xsl:call-template name="create-token-reference">
                    <xsl:with-param name="ref-id" select="$kerberos-bst-id"/>
                  </xsl:call-template>
                </symmetric-token-reference>

              </xsl:when>

              <!-- derive a key from a named DKT. -->
              <xsl:when test="$dpconfig:symmetric-key-type = 'dkt'">
                <xsl:variable name="parent-dkt">
                  <xsl:choose>
                    <!-- by name. -->
                    <xsl:when test="$dpconfig:base-dkt-name != ''">
                      <xsl:copy-of select="($existing-security-header/*[local-name()='DerivedKeyToken']/*[local-name()='Properties']/*[
                                                                 local-name()='Name' and string(.)=$dpconfig:base-dkt-name]/../..) [1]" />
                    </xsl:when>
                    <!-- or use the first one. -->
                    <xsl:otherwise>
                      <xsl:copy-of select="($existing-security-header/*[local-name()='DerivedKeyToken'])[1]"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>

                <xsl:variable name="dkt-id" select="$parent-dkt/*[local-name()='DerivedKeyToken']/@*[translate(local-name(), 'ID', 'id')='id']"/>
                <xsl:variable name="new-dkt-id">
                  <xsl:choose>
                    <xsl:when test="not($dkt-id)">
                      <xsl:value-of select="concat('DKT-', dp:generate-uuid())"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="$dkt-id"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
 
                <xsl:variable name="symmetric-tokens">
                  <xsl:if test="$dpconfig:use-key-derivation = 'on'">
                    <xsl:call-template name="create-dkt-token">
                      <xsl:with-param name="ref-id" select="$new-dkt-id"/>
                      <xsl:with-param name="default-nonce" select="$parent-dkt/*[local-name()='DerivedKeyToken']/*[local-name()='Properties']/*[local-name()='Nonce']"/>
                    </xsl:call-template>
                  </xsl:if>
                </xsl:variable>

                <symmetric-token>
                  <!-- If the DKT is reused but it doesnt have an ID attribute, 
                       copy it to a new DKT by adding the attribute for referencing. -->
                  <xsl:if test="$dpconfig:base-dkt-name = '' and $new-dkt-id != $dkt-id">
                    <xsl:for-each select="$parent-dkt/*[local-name()='DerivedKeyToken']">
                      <xsl:copy>
                        <xsl:choose>
                          <xsl:when test="$dpconfig:wssec-id-ref-type='wsu:Id'">
                            <xsl:attribute name="wsu:Id">
                              <xsl:value-of select="$new-dkt-id"/>
                            </xsl:attribute>
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:attribute name="xml:id">
                              <xsl:value-of select="$new-dkt-id"/>
                            </xsl:attribute>
                          </xsl:otherwise>
                        </xsl:choose>
                        <xsl:copy-of select="@*[translate(local-name(),'ID','id') != 'id']"/>
                        <xsl:copy-of select="namespace::* | comment()"/>
                        <xsl:copy-of select="child::*"/>
                      </xsl:copy>
                    </xsl:for-each>
                  </xsl:if>

                  <xsl:copy-of select="$symmetric-tokens"/>
                </symmetric-token>
                <xsl:choose>
                  <xsl:when test="$dpconfig:use-key-derivation = 'on'">
                    <symmetric-key>
                      <xsl:call-template name="dp-generate-derived-key">
                        <xsl:with-param name="from-token" select="$parent-dkt/*[local-name()='DerivedKeyToken']"/>
                        <xsl:with-param name="dkt" select="$symmetric-tokens/*[local-name()='DerivedKeyToken']"/>
                        <xsl:with-param name="existing-security-header" select="$existing-security-header"/>
                      </xsl:call-template>
                    </symmetric-key>
                  </xsl:when>
                  <xsl:otherwise>
                    <symmetric-key>
                      <!-- get the symmetric key out of parent-dkt by resolve that derived key. -->
                      <xsl:call-template name="dp-resolve-symmetric-key">
                        <xsl:with-param name="dkt" select="$parent-dkt/*[local-name()='DerivedKeyToken']"/> 
                        <xsl:with-param name="existing-security-header" select="$existing-security-header"/>
                      </xsl:call-template>
                    </symmetric-key>
                    <symmetric-token-reference>
                      <xsl:call-template name="create-token-reference">
                        <xsl:with-param name="ref-id" select="$new-dkt-id"/>
                      </xsl:call-template>
                    </symmetric-token-reference>
                  </xsl:otherwise>
                </xsl:choose>

              </xsl:when>

              <!-- encrypted key, with/out key derivation, as symmetric key. -->
              <xsl:when test="$dpconfig:symmetric-key-type = 'encryptedkey'">
                <!-- generate a session key, then encrypt it. -->
                <xsl:variable name="session-key" select="dp:generate-key($dpconfig:algorithm)"/>
                <xsl:variable name="encrypted-key">
                  <xsl:call-template name="dp-generate-encrypted-key">
                    <xsl:with-param name="session-key" select="$session-key"/>
                    <xsl:with-param name="recipient" select="concat('name:', $dpconfig:recipient)"/>
                    <xsl:with-param name="need-id-attr" select="true()"/>
                    <xsl:with-param name="wssec11-enckey-cache" select="$dpconfig:wssec11-enckey-cache"/>
                  </xsl:call-template>
                </xsl:variable>

                <xsl:variable name="symmetric-tokens">
                  <xsl:if test="$dpconfig:use-key-derivation = 'on'">
                    <xsl:call-template name="create-dkt-token">
                      <xsl:with-param name="ref-id" select="$encrypted-key/*[local-name()='EncryptedKey']/@*[translate(local-name(),'ID','id')='id'][1]"/>
                    </xsl:call-template>
                  </xsl:if>
                </xsl:variable>

                <symmetric-token>
                  <!-- we will always use BST Direct referencing for this generated EncryptedKey. -->
                  <xsl:variable name="bst-id" select="concat('SecurityToken-', dp:generate-uuid())"/>
                  <xsl:call-template name="create-x509-bst">
                    <xsl:with-param name="ref-id" select="$bst-id"/>
                    <xsl:with-param name="cert" select="concat('name:', $dpconfig:recipient)"/>
                  </xsl:call-template>
                  <xsl:for-each select="$encrypted-key/*">
                    <xsl:copy>
                      <xsl:copy-of select="@Id"/>
                      <xsl:copy-of select="xenc:EncryptionMethod"/>
                      <dsig:KeyInfo>
                        <xsl:call-template name="create-token-reference">
                          <xsl:with-param name="ref-id" select="$bst-id"/>
                          <xsl:with-param name="token-type" select="'x509'"/>
                        </xsl:call-template>
                      </dsig:KeyInfo>
                      <xsl:copy-of select="xenc:CipherData"/>
                    </xsl:copy>
                  </xsl:for-each>

                  <!-- output the DKT, which uses the EncryptedKey. -->
                  <xsl:copy-of select="$symmetric-tokens"/>
                </symmetric-token>
                <xsl:choose>
                  <xsl:when test="$dpconfig:use-key-derivation = 'on'">
                    <symmetric-key>
                      <xsl:call-template name="dp-generate-derived-key">
                        <xsl:with-param name="from-token">
                          <session-key><xsl:value-of select="$session-key"/></session-key>
                        </xsl:with-param>
                        <xsl:with-param name="dkt" select="$symmetric-tokens/*[local-name()='DerivedKeyToken']"/>
                        <xsl:with-param name="existing-security-header" select="$existing-security-header"/>
                      </xsl:call-template>
                    </symmetric-key>
                  </xsl:when>
                  <xsl:otherwise>
                    <symmetric-key>
                      <xsl:value-of select="$session-key"/>
                    </symmetric-key>
                    <symmetric-token-reference>
                      <xsl:call-template name="create-token-reference">
                        <xsl:with-param name="ref-id" select="$encrypted-key/*[local-name()='EncryptedKey']/@*[translate(local-name(),'ID','id')='id'][1]"/>
                      </xsl:call-template>
                    </symmetric-token-reference>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>

              <!-- EncryptedKeySHA1 or SAMLSymmetricHoK-->
              <xsl:when test="$dpconfig:symmetric-key-type = 'eks' or $dpconfig:symmetric-key-type = 'saml-symmetric-hok'">

                <xsl:if test="$dpconfig:symmetric-key-type = 'saml-symmetric-hok' and
                              $dpconfig:validate-saml = 'on' and
                              not(dpfunc:check-saml-timestamp(
                                         $use-encryptedkeysha1/saml-token/Conditions/@NotBefore,
                                         $use-encryptedkeysha1/saml-token/Conditions/@NotOnOrAfter,
                                         $dpconfig:saml-skew-time))">
                  <xsl:message dp:id="{$DPLOG_CRYPTO_GENERIC_EXPIRED_SAML}" dp:priority="error"/>
                  <dp:reject>The SAML assertion has expired.</dp:reject>
                </xsl:if>

                <xsl:variable name="symmetric-tokens">
                  <xsl:if test="$dpconfig:use-key-derivation = 'on'">
                    <xsl:call-template name="create-dkt-token">
                    </xsl:call-template>
                  </xsl:if>
                </xsl:variable>

                <xsl:if test="$dpconfig:use-key-derivation = 'on'">
                  <symmetric-token>
                    <xsl:copy-of select="$symmetric-tokens"/>
                  </symmetric-token>
                </xsl:if>

                <symmetric-token-reference>
                  <xsl:choose>
                    <xsl:when test="$dpconfig:use-key-derivation = 'on'">
                      <xsl:copy-of select="$symmetric-tokens"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:call-template name="create-token-reference">
                      </xsl:call-template>
                    </xsl:otherwise>
                  </xsl:choose>
                </symmetric-token-reference>

                <symmetric-key>
                  <xsl:choose>
                    <xsl:when test="$dpconfig:use-key-derivation = 'on'">
                      <xsl:call-template name="dp-generate-derived-key">
                        <xsl:with-param name="from-token">
                          <session-key><xsl:value-of select="$use-encryptedkeysha1/sessionkey"/></session-key>
                        </xsl:with-param>
                        <xsl:with-param name="dkt" select="$symmetric-tokens/*[local-name()='DerivedKeyToken']"/>
                        <xsl:with-param name="existing-security-header" select="$existing-security-header"/>
                      </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="$use-encryptedkeysha1/sessionkey"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </symmetric-key>

              </xsl:when>

              <!-- use a SSKey, this can be configured for direct symmetric key only. No key derivation. -->
              <xsl:when test="$dpconfig:symmetric-key-type = 'static'">
                <xsl:variable name="sskey" select="concat('name:', $key)"/>
                <symmetric-token/> <!-- No tokens can be referenced. -->
                <symmetric-key>
                  <xsl:value-of select="$sskey"/>
                </symmetric-key>
                <symmetric-token-reference>
                  <!-- output name:<SSKeyName> as the reference for the existing DP HMAC signing behavior.
                       This is really not correct, the KeyName is better be something interoperatible,
                       such as x509 subject name.-->
                  <dsig:KeyName><xsl:value-of select="$sskey"/></dsig:KeyName> 
                </symmetric-token-reference>
              </xsl:when>

              <xsl:otherwise>
                <xsl:message dp:id="{$DPLOG_SOAP_KEY_TYPE}" dp:priority="error" terminate="yes">
                    <dp:with-param value="{$dpconfig:symmetric-key-type}"/>
                </xsl:message>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <xsl:copy-of select="$symmetric-result/symmetric-token/*"/>

          <xsl:variable name="BST-for-signing">
            <xsl:if test="$dpconfig:sign-binarysecuritytoken = 'on'">
              <xsl:copy-of select="$symmetric-result/symmetric-token/*[local-name()='BinarySecurityToken']"/>
            </xsl:if>
          </xsl:variable>

          <xsl:variable name="keyinfo-str">
            <xsl:choose>
              <xsl:when test="$dpconfig:use-key-derivation = 'on'">
                <wsse:SecurityTokenReference>
                  <xsl:if test="$dpconfig:enable-wssec-str-transform = 'on'">
                    <xsl:variable name="strid"><xsl:value-of select="concat('STR-', dp:generate-uuid())"/></xsl:variable>
                    <xsl:choose>
                      <xsl:when test="$dpconfig:wssec-id-ref-type='wsu:Id'">
                        <xsl:attribute name="wsu:Id"><xsl:value-of select="$strid"/></xsl:attribute>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:attribute name="xml:id"><xsl:value-of select="$strid"/></xsl:attribute>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:if>

                  <wsse:Reference URI="{concat('#', $symmetric-result/symmetric-token/*[
                                          local-name()='DerivedKeyToken']/@*[translate(local-name(),'ID','id')='id'][1])}"
                                  ValueType="{$wssc-capability/wssc/dk}"/>
                </wsse:SecurityTokenReference>
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="$symmetric-result/symmetric-token-reference/*"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="STR-for-signing">
            <xsl:if test="$dpconfig:enable-wssec-str-transform = 'on'">
              <xsl:copy-of select="$token-str/*"/>
            </xsl:if>

            <xsl:if test="$dpconfig:sign-keyinfo = 'on'">
              <xsl:copy-of select="$keyinfo-str/*"/>
            </xsl:if>
          </xsl:variable>
          
          <!-- the HMAC symmetric signing with/out key derivation calls the same lib.
               -->
          <xsl:call-template name="dp-sign-hmac-wssec">
            <xsl:with-param name="node" 
                            select="$nodes-to-sign[ not($dpconfig:enable-wssec-str-transform='on' and local-name()='Assertion')] | 
                                    $timestamp/* | $signatureconfirmation/* | $BST-for-signing/* | $STR-for-signing/*"/>
            <xsl:with-param name="refuri" select="''"/>
            <xsl:with-param name="keyid" select="$symmetric-result/symmetric-key" />
            <xsl:with-param name="sigalg" select="$dpconfig:hmac-sigalg"/>
            <xsl:with-param name="hashalg" select='$dpconfig:hashalg'/>
            <xsl:with-param name="c14nalg" select="$dpconfig:c14nalg"/>
            <xsl:with-param name="extra-prefix-list" select="normalize-space($dpconfig:extra-prefix-list)"/>
            <xsl:with-param name="tokenstr" select="$keyinfo-str"/>
            <xsl:with-param name="store-signature" select="$dpconfig:expect-signatureconfirmation"/>
            <xsl:with-param name="existing-security-header" select="$nodes-to-sign | $existing-security-header | $symmetric-result/symmetric-token/*"/>
            <xsl:with-param name="enable-str-transform" select="$dpconfig:enable-wssec-str-transform"/>
            <xsl:with-param name="wssec-args">
              <xsl:if test="$dpconfig:skip-namespace-prefix-for-strtransform = 'on'">
                <skip-namespace-prefix-for-strtransform>
                  <xsl:value-of select="$dpconfig:skip-namespace-prefix-for-strtransform"/>
                </skip-namespace-prefix-for-strtransform>
              </xsl:if>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:if test="$dpconfig:security-header-layout = 'laxtimestamplast'">
        <xsl:copy-of select="$timestamp/*"/>
      </xsl:if>
      <!-- increate the counter -->
      <xsl:call-template name="inc-num-wssec-counter"/>
  </xsl:template>

  <xsl:template name="create-token-reference">
    <xsl:param name="ref-id" select="''"/>
    <xsl:param name="token-type" select="''"/>

    <wsse:SecurityTokenReference>
      <!-- If the generated element is signed by the inclusive C14N or the extra Namespace PrefixList
           is not empty, those namespaces from the wsse:Security element or ancestor matter, copy then. -->
      <xsl:if test="$dpconfig:extra-prefix-list != '' or 
                    $dpconfig:c14nalg = 'c14n' or 
                    $dpconfig:c14nalg = 'c14n-comments'">
        <xsl:copy-of select="namespace::*"/>
      </xsl:if>

      <xsl:if test="$dpconfig:enable-wssec-str-transform = 'on'">
        <xsl:variable name="strid"><xsl:value-of select="concat('STR-', dp:generate-uuid())"/></xsl:variable>
        <xsl:choose>
          <xsl:when test="$dpconfig:wssec-id-ref-type='wsu:Id'">
            <xsl:attribute name="wsu:Id"><xsl:value-of select="$strid"/></xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="xml:id"><xsl:value-of select="$strid"/></xsl:attribute>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>

      <xsl:choose>
        <!-- there is a BST generated, either by asymmetric keys or symmetric EK using BST. -->
        <xsl:when test="$token-type = 'x509' and
                        not($use-encryptedkeysha1/node())"> 
          <xsl:variable name="cert">
            <xsl:choose>
              <xsl:when test="$dpconfig:use-asymmetric-key = 'on'">
                <xsl:value-of select="concat('name:', $pair-cert)"/>
              </xsl:when>
              <xsl:otherwise>
                <!-- it is the encrypted-key symmetric key using a x509. -->
                <xsl:value-of select="concat('name:', $dpconfig:recipient)"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <xsl:choose>
            <xsl:when test="$dpconfig:token-reference-mechanism = 'Direct'">
              <wsse:Reference URI="{concat('#', $ref-id)}">
                <xsl:if test="($wssec-version = '1.0') or ($wssec-version = '1.1')">
                  <xsl:attribute name="ValueType"><xsl:value-of select="$bst-value-type"/></xsl:attribute>
                </xsl:if>
              </wsse:Reference>
            </xsl:when>
            <xsl:when test="$dpconfig:token-reference-mechanism = 'KeyIdentifier'">
              <wsse:KeyIdentifier>
                <xsl:if test="($wssec-version = '1.0') or ($wssec-version = '1.1')">
                  <xsl:attribute name="ValueType">
                    <xsl:value-of select="$dpconfig:wss-x509-token-profile-1.0-keyidentifier-valuetype"/>
                  </xsl:attribute>
                  <xsl:attribute name="EncodingType">
                    <xsl:value-of select="$wssec-b64-encoding"/>
                  </xsl:attribute>
                </xsl:if>
                <xsl:value-of select="dp:get-typed-cert-ski($cert, $dpconfig:skitype)"/>
              </wsse:KeyIdentifier>
            </xsl:when>
            <xsl:when test="$dpconfig:token-reference-mechanism = 'ThumbPrintSHA1'">
              <wsse:KeyIdentifier
                ValueType="http://docs.oasis-open.org/wss/oasis-wss-soap-message-security-1.1#ThumbPrintSHA1"
                EncodingType="{$wssec-b64-encoding}">
                <xsl:value-of select="dp:get-cert-thumbprintsha1($cert)"/>
              </wsse:KeyIdentifier>
            </xsl:when>
            <xsl:when test="$dpconfig:token-reference-mechanism = 'ThumbprintSHA1'">
              <wsse:KeyIdentifier
                ValueType="http://docs.oasis-open.org/wss/oasis-wss-soap-message-security-1.1#ThumbprintSHA1"
                EncodingType="{$wssec-b64-encoding}">
                <xsl:value-of select="dp:get-cert-thumbprintsha1($cert)"/>
              </wsse:KeyIdentifier>
            </xsl:when>
            <xsl:when test="$dpconfig:token-reference-mechanism = 'X509IssuerSerial'">
              <dsig:X509Data>
                <dsig:X509IssuerSerial>
                  <dsig:X509IssuerName><xsl:value-of select="dpfunc:compat-dn(dp:get-cert-issuer($cert), $compat)"/></dsig:X509IssuerName>
                  <dsig:X509SerialNumber><xsl:value-of select="dp:get-cert-serial($cert)"/></dsig:X509SerialNumber>
                </dsig:X509IssuerSerial>
              </dsig:X509Data>
            </xsl:when>
          </xsl:choose>
        </xsl:when>

        <!-- the default behavior, use the SCT is it is available. -->
        <xsl:when test="$dpconfig:include-sct-token = 'on' and
                        $dpconfig:symmetric-key-type = 'sct-available'">
          <wsse:Reference URI="{concat('#', $ref-id)}" ValueType="{$wssc-capability/wssc/sct}"/>
        </xsl:when>
        <xsl:when test="$dpconfig:include-sct-token = 'off' and
                        $dpconfig:symmetric-key-type = 'sct-available'">
          <wsse:Reference URI="{$available-sct-token//*[local-name()='Identifier']}" ValueType="{$wssc-capability/wssc/sct}"/>
        </xsl:when>

        <!-- derive a key from a named DKT. -->
        <xsl:when test="$dpconfig:symmetric-key-type = 'dkt'">
          <xsl:choose>
            <!-- by name. -->
            <xsl:when test="$dpconfig:base-dkt-name != ''">
              <wsse:Reference URI="{$dpconfig:base-dkt-name}" ValueType="{$wssc-capability/wssc/dk}"/>
            </xsl:when>
            <!-- or use the Id attr. -->
            <xsl:otherwise>
              <wsse:Reference URI="{concat('#', $ref-id)}" ValueType="{$wssc-capability/wssc/dk}"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        
        <!-- derive a key from an EncryptedKey. -->
        <xsl:when test="$dpconfig:symmetric-key-type = 'encryptedkey'">
          <wsse:Reference URI="{concat('#', $ref-id)}" ValueType="http://docs.oasis-open.org/wss/oasis-wss-soap-message-security-1.1#EncryptedKey"/>
        </xsl:when>

        <!-- derive a key from Kerberos token. -->
        <xsl:when test="$dpconfig:symmetric-key-type = 'kerberos'">
          <xsl:choose>
            <!-- the caller takes the responsibility to pass in the ref-id if a BST Id attribute is available. -->
            <xsl:when test="$ref-id != ''">
              <wsse:Reference URI="{concat('#', $ref-id)}" ValueType="{$dpconfig:kerberos-value-type}"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="create-kerberos-keyidentifier">
                <xsl:with-param name="apreq" select="$available-kerberos-token"/>
                <xsl:with-param name="vt" select="$dpconfig:kerberos-value-type"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>

        <!-- EncryptedKeySHA1 -->
        <xsl:when test="$dpconfig:symmetric-key-type = 'eks'">
          <xsl:attribute name="wsse11:TokenType">http://docs.oasis-open.org/wss/oasis-wss-soap-message-security-1.1#EncryptedKey</xsl:attribute>
           <wsse:KeyIdentifier ValueType="http://docs.oasis-open.org/wss/oasis-wss-soap-message-security-1.1#EncryptedKeySHA1" EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary"><xsl:value-of select="$use-encryptedkeysha1/eksvalue"/></wsse:KeyIdentifier>
        </xsl:when>

        <!-- SAML-Symmetric-HoK -->
        <xsl:when test="$dpconfig:symmetric-key-type = 'saml-symmetric-hok'">
          <xsl:choose>
            <xsl:when test="$use-encryptedkeysha1/saml-token/version = '2.0'">
              <xsl:attribute name="wsse11:TokenType">http://docs.oasis-open.org/wss/oasis-wss-saml-token-profile-1.1#SAMLV2.0</xsl:attribute>
              <wsse:KeyIdentifier ValueType="http://docs.oasis-open.org/wss/oasis-wss-saml-token-profile-1.1#SAMLID">
                <xsl:value-of select="$use-encryptedkeysha1/saml-token/ID"/>
              </wsse:KeyIdentifier>
            </xsl:when>
            <xsl:when test="$use-encryptedkeysha1/saml-token/version = '1.x'">
              <xsl:attribute name="wsse11:TokenType">http://docs.oasis-open.org/wss/oasis-wss-saml-token-profile-1.1#SAMLV1.1</xsl:attribute>
              <wsse:KeyIdentifier ValueType="http://docs.oasis-open.org/wss/oasis-wss-saml-token-profile-1.0#SAMLAssertionID">
                <xsl:value-of select="$use-encryptedkeysha1/saml-token/ID"/>
              </wsse:KeyIdentifier>
            </xsl:when>
            <xsl:otherwise>
              <!-- error message-->
              <xsl:message dp:id="{$DPLOG_SOAP_BAD_SAML_HOK_CACHE}" dp:priority="error"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
      </xsl:choose>
    </wsse:SecurityTokenReference>
  </xsl:template>

  <xsl:template name="create-x509-bst">
    <xsl:param name="ref-id" select="''"/>
    <xsl:param name="cert" select="''"/>

    <xsl:if test="$dpconfig:token-reference-mechanism = 'Direct'">
      <wsse:BinarySecurityToken>
        <!-- If the generated element is signed by the inclusive C14N or the extra Namespace PrefixList
             is not empty, those namespaces from the wsse:Security element or ancestor matter, copy then. -->
        <xsl:if test="$dpconfig:extra-prefix-list != '' or 
                      $dpconfig:c14nalg = 'c14n' or 
                      $dpconfig:c14nalg = 'c14n-comments'">
          <xsl:copy-of select="namespace::*"/>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="$dpconfig:wssec-id-ref-type='wsu:Id'"><xsl:attribute name="wsu:Id"><xsl:value-of select="$ref-id"/></xsl:attribute></xsl:when>
          <xsl:otherwise><xsl:attribute name="xml:id"><xsl:value-of select="$ref-id"/></xsl:attribute></xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="($wssec-version = 'draft-13') or
                          ($wssec-version = 'draft-12')">
            <xsl:attribute name="EncodingType">wsse:Base64Binary</xsl:attribute>
            <xsl:attribute name="ValueType">wsse:X509v3</xsl:attribute>
            <xsl:value-of select="dp:base64-cert($cert)"/>
          </xsl:when>

          <!-- Content of BST depends on the ValueType -->
          <xsl:when test="substring-after($bst-value-type, '#') = 'PKCS7' 
                       or substring-after($bst-value-type, '#') = 'X509PKIPathv1'">

              <!-- See also for $wsse-idcred-data and $wsse-idcred-format -->
              <xsl:attribute name="EncodingType"><xsl:value-of select="$wssec-b64-encoding"/></xsl:attribute>
              <xsl:attribute name="ValueType"><xsl:value-of select="$bst-value-type"/></xsl:attribute>
              <xsl:value-of select="$wsse-idcred-data/idcred/*[local-name() = $wsse-idcred-format]"/>
          </xsl:when> 

          <!-- BST ValueType is X509v3 -->
          <xsl:otherwise>
            <!-- Default to 1.0 or 1.1 -->
            <xsl:attribute name="EncodingType"><xsl:value-of select="$wssec-b64-encoding"/></xsl:attribute>
            <xsl:attribute name="ValueType"><xsl:value-of select="$bst-value-type"/></xsl:attribute>
            <xsl:value-of select="dp:base64-cert($cert)"/>
          </xsl:otherwise>
        </xsl:choose>
      </wsse:BinarySecurityToken>
    </xsl:if>
  </xsl:template>

  <xsl:template name="create-dkt-token">
    <xsl:param name="ref-id" select="''"/>
    <xsl:param name="default-nonce" select="/.."/>

    <xsl:variable name="length">
      <!-- see the list also with type dmCryptoEncryptionAlgorithm and crCipher.cpp-->
      <xsl:choose>
        <xsl:when test="$dpconfig:dkt-length !=''">
          <xsl:value-of select="number($dpconfig:dkt-length)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'32'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="nonce">
      <xsl:choose>
        <xsl:when test="$default-nonce != ''">
          <xsl:value-of select="$default-nonce"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="dp:random-bytes($length)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
      <!-- wsc DKT doesn't allow @xml:id, always use the @wsu:Id. -->
    <wsc:DerivedKeyToken Algorithm="{$wssc-capability/wssc/dk-p_sha1}" wsu:Id="{concat('DKT-', dp:generate-uuid())}">
      <xsl:call-template name="create-token-reference">
        <xsl:with-param name="ref-id" select="$ref-id"/>
      </xsl:call-template>
      <xsl:choose>
        <xsl:when test="$dpconfig:dkt-offset !=''">
          <wsc:Offset><xsl:value-of select="number($dpconfig:dkt-offset)"/></wsc:Offset>
        </xsl:when>
        <xsl:when test="$dpconfig:dkt-generation !=''">
          <wsc:Generation><xsl:value-of select="number($dpconfig:dkt-generation)"/></wsc:Generation>
        </xsl:when>
        <xsl:otherwise>
          <wsc:Offset>0</wsc:Offset>
        </xsl:otherwise>
      </xsl:choose>
      <wsc:Length><xsl:value-of select="$length"/></wsc:Length>
      <xsl:if test="$dpconfig:dkt-label !=''">
        <wsc:Label><xsl:value-of select="$dpconfig:dkt-label"/></wsc:Label>
      </xsl:if>
      <wsc:Nonce><xsl:value-of select="$nonce"/></wsc:Nonce>
    </wsc:DerivedKeyToken>
  </xsl:template>

  <!-- in case of str-transfor for the SAML tokens, generate the STR here. -->
  <xsl:template mode="str-transform-nodes"
                match="*[local-name()='Assertion' and 
                         (  namespace-uri()='urn:oasis:names:tc:SAML:2.0:assertion' or 
                            namespace-uri()='urn:oasis:names:tc:SAML:1.0:assertion')] ">
      <xsl:call-template name="make-saml-security-token-reference">
        <xsl:with-param name="assertion" select="."/>
        <xsl:with-param name="wssec-str-compatibility" select="$dpconfig:wssec-str-compatibility"/>
      </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>

