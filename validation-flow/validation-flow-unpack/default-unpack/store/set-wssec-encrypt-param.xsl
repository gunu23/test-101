<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007, 2020. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
    Set WS-Security Encrypt doc/field level related parameters, if those <dp:param>
    are Encrypt only or has to define differently from ws-sec signing stylesheets; 
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
    xmlns:func="http://exslt.org/functions"
    xmlns:wsc="http://schemas.xmlsoap.org/ws/2005/02/sc"
    xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
    xmlns:wsse11="http://docs.oasis-open.org/wss/oasis-wss-wssecurity-secext-1.1.xsd"
    xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
    xmlns:xenc="http://www.w3.org/2001/04/xmlenc#"
    xmlns:xenc11="http://www.w3.org/2009/xmlenc11#"
    extension-element-prefixes="dp func"
    exclude-result-prefixes="date dp dpconfig dpfunc dpquery dsig func wsc wsse wsse11 wsu xenc xenc11"
>
  <xsl:import href="store:///dp/msgcat/crypto.xml.xsl" dp:ignore-multiple="yes"/>
  <!-- '' or 'message' (default), 'attachments', 'message-attachments'.  -->
  <xsl:param name="dpconfig:wssec-encrypt" select="'message'"/>
  <dp:param name="dpconfig:wssec-encrypt" type="dmWSSecEncryptionType" xmlns="">
    <display>Message and Attachment Handling</display>
    <displayId>store.set-wssec-encrypt-param.param.wssec-encrypt.display</displayId>
    <description>Setting what WS-Security data will be encrypted: SOAP message only,
    SwA attachments only or both.
    
    </description>
    <descriptionId>store.set-wssec-encrypt-param.param.wssec-encrypt.description</descriptionId>
    <default>message</default>
  </dp:param>

  <xsl:param name="dpconfig:encryption-key-type" select="'asymmetric'"/>
  <dp:param name="dpconfig:encryption-key-type" type="dmCryptoEncryptionKeyType" xmlns="">
    <tab-override>basic</tab-override>
    <default>asymmetric</default>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:wssec-encrypt</parameter-name>
          <value>attachments</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:use-key-derivation" select="'on'"/>
  <dp:param name="dpconfig:use-key-derivation" type="dmToggle" xmlns="">
    <display>Use WS-SC Key Derivation</display>
    <displayId>store.set-wssec-encrypt-param.param.use-key-derivation.display</displayId>
    <description>
      Specifies if a derived key will be used as the symmetric key for data encryption,
      or symmetric key to wrap the ephemeral key.<p/>
      If it is 'on', the retrieved key from the symmetric key source
      will be used as the key derivation base and the derived key is
      is the actual key to encrypt the data or wrap up the symmetric key. <p/>
      By default it is "off" meaning the key from the symmetric key source
      will be directly used for encryption.<p/>
      Please note: the static SSKey can not be used directly as a key derivation
      base as the WS-SC spec requires to put a wsse:SecurityTokenReference for
      DKT and the SSKey dsig:KeyName can not be referred by this reference mechanism.
    </description>
    <descriptionId>store.set-wssec-encrypt-param.param.use-key-derivation.description</descriptionId>
    <tab-override>basic</tab-override>
    <default>on</default>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:wssec-encrypt</parameter-name>
          <value>attachments</value>
        </condition>
        <condition evaluation="property-value-not-in-list">
          <parameter-name>dpconfig:wssec-compatibility</parameter-name>
          <value>1.0</value>
          <value>1.1</value>
        </condition>
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:encryption-key-type</parameter-name>
          <value>asymmetric</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:symmetric-key-type" select="'sct-available'"/>
  <dp:param name="dpconfig:symmetric-key-type" type="dmSymmetricKeyType" xmlns="">
    <display>Symmetric Key Encryption Source</display>
    <displayId>store.set-wssec-encrypt-param.param.symmetric-key-type.display</displayId>
    <description>
    Specify the source of the symmetric key used to encrypt the generated bulk 
    By default the value is "sct-availabe", which uses a key from a 
    WS-SecureConversation security context. The key identified by this parameter
    can be used either directly as the encryption key, or as the base key in 
    a derived key scenario.
    </description>
    <descriptionId>store.set-wssec-encrypt-param.param.symmetric-key-type.description</descriptionId>
    <tab-override>basic</tab-override>
    <default>sct-available</default>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:wssec-encrypt</parameter-name>
          <value>attachments</value>
        </condition>
        <condition evaluation="property-value-not-in-list">
          <parameter-name>dpconfig:wssec-compatibility</parameter-name>
          <value>1.0</value>
          <value>1.1</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-key-derivation</parameter-name>
          <value>off</value>
        </condition>
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:encryption-key-type</parameter-name>
          <value>asymmetric</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:derivation-base" select="'sct-available'"/>
  <dp:param name="dpconfig:derivation-base" type="dmWSSCKeyDerivationType" xmlns="">
    <display>WS-SecureConversation DKT Derivation Base</display>
    <displayId>store.set-wssec-encrypt-param.param.derivation-base.display</displayId>
    <description>Select what type of key derivation to use or choose what the base token
    to derive a key. By default the value is "sct-available", which derives a key from 
    an existing wsc:SecurityContextToken or fall onto "asymmetric" Encryption Key Type if 
    no SCT token is available. If a key derivation is used by this action, a DKT is 
    issued with the encrypted message.
    </description>
    <descriptionId>store.set-wssec-encrypt-param.param.derivation-base.description</descriptionId>
    <tab-override>basic</tab-override>
    <default>sct-available</default>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:wssec-encrypt</parameter-name>
          <value>attachments</value>
        </condition>
        <condition evaluation="property-value-not-in-list">
          <parameter-name>dpconfig:wssec-compatibility</parameter-name>
          <value>1.0</value>
          <value>1.1</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-key-derivation</parameter-name>
          <value>on</value>
        </condition>
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:encryption-key-type</parameter-name>
          <value>asymmetric</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:include href="store:///set-rsa-encrypt-param.xsl" dp:ignore-multiple="yes"/>
  <xsl:include href="store:///set-recipient.xsl"  dp:ignore-multiple="yes"/>

  <xsl:param name="dpconfig:symmetric-keywrap-algo" select="$URI-XENC-KW-3DES"/>
  <dp:param name="dpconfig:symmetric-keywrap-algo" type="dmCryptoKeySymmetricEncryptionAlgorithm" xmlns="">
    <display>Symmetric Key Wrap Algorithm</display>
    <displayId>store.set-wssec-encrypt-param.param.symmetric-keywrap-algo.display</displayId>
    <description>
      When the bulk encryption key is itself encrypted by a symmetric key, this
      parameter determines the key wrap algorithm used.
    </description>
    <descriptionId>store.set-wssec-encrypt-param.param.symmetric-keywrap-algo.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:wssec-encrypt</parameter-name>
          <value>attachments</value>
        </condition>
        <condition evaluation="property-value-not-in-list">
          <parameter-name>dpconfig:wssec-compatibility</parameter-name>
          <value>1.0</value>
          <value>1.1</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:encryption-key-type</parameter-name>
          <value>keywrap</value>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:encryption-key-type</parameter-name>
            <value>asymmetric</value>
          </condition>
          <condition evaluation="property-value-not-in-list">
            <parameter-name>dpconfig:derivation-base</parameter-name>
            <value>encryptedkey</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>on</value>
          </condition>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:encryption-key-type</parameter-name>
            <value>asymmetric</value>
          </condition>
          <condition evaluation="property-value-not-in-list">
            <parameter-name>dpconfig:symmetric-key-type</parameter-name>
            <value>encryptedkey</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>off</value>
          </condition>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:include href="store:///set-wssec-common-param.xsl" dp:ignore-multiple="yes"/>
  <xsl:include href="store:///set-soap-sender-param.xsl" dp:ignore-multiple="yes"/>

  <!-- the following convoluted logic is based on the check of this for use-encryptedkeysha1
      <xsl:if test="$dpconfig:wssec-compatibility = '1.1' and
                  ($dpconfig:encryption-key-type = 'asymmetric' and 
                   $dpconfig:token-reference-mechanism = 'EncryptedKeySHA1') 
                  or ($dpconfig:encryption-key-type = 'symmetric' and
                      ($dpconfig:symmetric-key-type = 'eks' or $dpconfig:symmetric-key-type = 'saml-symmetric-hok') 
                     )
                  or ($dpconfig:encryption-key-type = 'symmetric' and
                      $dpconfig:use-key-derivation = 'on' and
                      ($dpconfig:derivation-base = 'eks' or $dpconfig:derivation-base = 'saml-symmetric-hok'))">
  -->

  <xsl:param name="dpconfig:validate-saml" select="'on'"/>
  <dp:param name="dpconfig:validate-saml" type="dmToggle" xmlns="">
    <display>Validate Applicable SAML Assertion</display>
    <displayId>store.set-wssec-encrypt-param.param.validate-saml.display</displayId>
    <description>Validate the SAML assertion used by the crypto operation</description>
    <descriptionId>store.set-wssec-encrypt-param.param.validate-saml.description</descriptionId>
    <default>on</default>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-value-in-list">
          <parameter-name>dpconfig:encryption-key-type</parameter-name>
          <value>asymmetric</value>
          <value>keywrap</value>
        </condition>
        <!-- only remaining for the symmetric -->
        <condition evaluation="logical-and">
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>off</value>
          </condition>
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:symmetric-key-type</parameter-name>
            <value>saml-symmetric-hok</value>
          </condition>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>on</value>
          </condition>
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:derivation-base</parameter-name>
            <value>saml-symmetric-hok</value>
          </condition>
        </condition>
      </condition>
    </ignored-when>  
  </dp:param>

  <xsl:param name="dpconfig:saml-skew-time" select="'0'"/>
  <dp:param name="dpconfig:saml-skew-time" type="dmTimeInterval" xmlns="">
    <display>SAML Skew Time</display>
    <displayId>store.set-wssec-encrypt-param.param.saml-skew-time.display</displayId>
    <description>Skew time is the difference, in seconds, between the device clock time and other system times.
     When the skew time is set, the SAML assertion expiration takes the time difference into
     account when the appliance consumes SAML tokens. NotBefore is validated with CurrentTime minus SkewTime.
     NotOnOrAfter is validated with CurrentTime plus SkewTime.
    </description>
    <descriptionId>store.set-wssec-encrypt-param.param.saml-skew-time.description</descriptionId>
    <units>sec</units>
    <unitsDisplayId>store.set-wssec-encrypt-param.param.saml-skew-time.unit.sec</unitsDisplayId>    
    <minimum>0</minimum>
    <maximum>630720000</maximum>     <!-- 20 years -->
    <default>0</default>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:validate-saml</parameter-name>
          <value>on</value>
        </condition>
        <condition evaluation="property-value-in-list">
          <parameter-name>dpconfig:encryption-key-type</parameter-name>
          <value>asymmetric</value>
          <value>keywrap</value>
        </condition>
        <!-- only remaining for the symmetric -->
        <condition evaluation="logical-and">
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>off</value>
          </condition>
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:symmetric-key-type</parameter-name>
            <value>saml-symmetric-hok</value>
          </condition>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>on</value>
          </condition>
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:derivation-base</parameter-name>
            <value>saml-symmetric-hok</value>
          </condition>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:swa-compatibility" select="'1.1'"/>
  <dp:param name="dpconfig:swa-compatibility" type="dmCryptoSwAVersion" xmlns="">
    <ignored-when>
      <condition evaluation="property-equals">
        <parameter-name>dpconfig:wssec-encrypt</parameter-name>
        <value>message</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:swa-encrypt-transform" select="'MIMEContentOnly'"/>
  <dp:param name="dpconfig:swa-encrypt-transform" type="dmCryptoSwATransform" xmlns="">
    <ignored-when>
      <condition evaluation="property-equals">
        <parameter-name>dpconfig:wssec-encrypt</parameter-name>
        <value>message</value>
      </condition>
    </ignored-when>
  </dp:param>

  <!-- TODO: The Kerberos may not need to show this setting:
       we always output BST (direct reference) when a new kerberos token is generated.
       we always output KeyIdentifier when a cached kerberos apreq is used.
    -->
  <xsl:param name="dpconfig:token-reference-mechanism" select="'KeyIdentifier'"/>
  <dp:param name="dpconfig:token-reference-mechanism" type="dmCryptoWSSTokenReferenceMechanism" xmlns="">
    <default>KeyIdentifier</default>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:encryption-key-type</parameter-name>
            <value>asymmetric</value>
          </condition>
          <condition evaluation="property-value-not-in-list">
            <parameter-name>dpconfig:derivation-base</parameter-name>
            <value>encryptedkey</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>on</value>
          </condition>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:encryption-key-type</parameter-name>
            <value>asymmetric</value>
          </condition>
          <condition evaluation="property-value-not-in-list">
            <parameter-name>dpconfig:symmetric-key-type</parameter-name>
            <value>encryptedkey</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>off</value>
          </condition>
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
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:token-reference-mechanism</parameter-name>
          <value>Direct</value>
        </condition>
        <condition evaluation="property-value-not-in-list">
          <parameter-name>dpconfig:wssec-compatibility</parameter-name>
          <value>1.0</value>
          <value>1.1</value>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:encryption-key-type</parameter-name>
            <value>asymmetric</value>
          </condition>
          <condition evaluation="property-value-not-in-list">
            <parameter-name>dpconfig:derivation-base</parameter-name>
            <value>encryptedkey</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>on</value>
          </condition>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:encryption-key-type</parameter-name>
            <value>asymmetric</value>
          </condition>
          <condition evaluation="property-value-not-in-list">
            <parameter-name>dpconfig:symmetric-key-type</parameter-name>
            <value>encryptedkey</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>off</value>
          </condition>
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
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:token-reference-mechanism</parameter-name>
          <value>KeyIdentifier</value>
        </condition>
        <condition evaluation="property-value-not-in-list">
          <parameter-name>dpconfig:wssec-compatibility</parameter-name>
          <value>1.0</value>
          <value>1.1</value>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:encryption-key-type</parameter-name>
            <value>asymmetric</value>
          </condition>
          <condition evaluation="property-value-not-in-list">
            <parameter-name>dpconfig:derivation-base</parameter-name>
            <value>encryptedkey</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>on</value>
          </condition>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:encryption-key-type</parameter-name>
            <value>asymmetric</value>
          </condition>
          <condition evaluation="property-value-not-in-list">
            <parameter-name>dpconfig:symmetric-key-type</parameter-name>
            <value>encryptedkey</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>off</value>
          </condition>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:skitype" select="'pkix'"/>
  <dp:param name="dpconfig:skitype" type="dmCryptoSKIType" xmlns="">
    <description>The form of the Subject Key Identifier to use. This
    parameter is only relevant when the WS-Security Version is 1.0/1.1 and
    the Token Reference Mechanism is "KeyIdentifier".</description>
    <descriptionId>store.set-wssec-encrypt-param.param.skitype.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:token-reference-mechanism</parameter-name>
          <value>KeyIdentifier</value>
        </condition>
        <condition evaluation="property-value-not-in-list">
          <parameter-name>dpconfig:wssec-compatibility</parameter-name>
          <value>1.0</value>
          <value>1.1</value>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:encryption-key-type</parameter-name>
            <value>asymmetric</value>
          </condition>
          <condition evaluation="property-value-not-in-list">
            <parameter-name>dpconfig:derivation-base</parameter-name>
            <value>encryptedkey</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>on</value>
          </condition>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:encryption-key-type</parameter-name>
            <value>asymmetric</value>
          </condition>
          <condition evaluation="property-value-not-in-list">
            <parameter-name>dpconfig:symmetric-key-type</parameter-name>
            <value>encryptedkey</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>off</value>
          </condition>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:key" select="''"/>
  <dp:param name="dpconfig:key" type="dmReference" reftype="CryptoSSKey" xmlns="">
    <display>Shared Secret Key</display>
    <displayId>store.set-wssec-encrypt-param.param.key.display</displayId>
    <description>
    The named shared secret key that is used as symmetric bulk encryption key,
    or to wrap the generated bulk encryption key.
    </description>
    <descriptionId>store.set-wssec-encrypt-param.param.key.description</descriptionId>
    <tab-override>basic</tab-override>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:wssec-encrypt</parameter-name>
          <value>attachments</value>
        </condition>
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:encryption-key-type</parameter-name>
          <value>asymmetric</value>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:derivation-base</parameter-name>
            <value>static</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>on</value>
          </condition>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:symmetric-key-type</parameter-name>
            <value>static</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>off</value>
          </condition>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:base-dkt-name" select="''"/>
  <dp:param name="dpconfig:base-dkt-name" type="dmString" xmlns="">
    <display>Base DerivedKeyToken name</display>
    <displayId>store.set-wssec-encrypt-param.param.base-dkt-name.display</displayId>
    <description>For a symmetric encryption key wrap scenario, where the
    symmetric key type is a DerivedKeyToken (DKT), this parameter allows a 
    particular named DKT to be used. A named DKT typically has a 
    "wsc:Properties/wsc:Name" element; this is the value specified by the parameter.
    </description>
    <descriptionId>store.set-wssec-encrypt-param.param.base-dkt-name.description</descriptionId>
    <tab-override>basic</tab-override>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:wssec-encrypt</parameter-name>
          <value>attachments</value>
        </condition>
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:encryption-key-type</parameter-name>
          <value>asymmetric</value>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:derivation-base</parameter-name>
            <value>dkt</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>on</value>
          </condition>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:symmetric-key-type</parameter-name>
            <value>dkt</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>off</value>
          </condition>
        </condition>
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:encryption-key-type</parameter-name>
          <value>asymmetric</value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:wssc-version" select="'1.2'"/>
  <dp:param name="dpconfig:wssc-version" type="dmCryptoWSSXVersion" xmlns="">
    <display>DKT Namespace Version if Unknown</display>
    <displayId>store.set-wssec-encrypt-param.param.wssc-version.display</displayId>
    <description>The WS-SecureConversation specs to use when it outputs a
    wsc:DerivedKeyToken. If the input message contains a SCT, DKT or a WS-Trust RSTR,
    the output DKT version will match the input WS-SecureConversation namespace.</description>
    <descriptionId>store.set-wssec-encrypt-param.param.wssc-version.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:wssec-encrypt</parameter-name>
          <value>attachments</value>
        </condition>
        <condition evaluation="property-value-in-list">
          <parameter-name>dpconfig:derivation-base</parameter-name>
          <value>no</value>
          <value>dkt</value>
          <value>sct-available</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-key-derivation</parameter-name>
          <value>on</value>
        </condition>
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:encryption-key-type</parameter-name>
          <value>asymmetric</value>
        </condition>
      </condition>
    </ignored-when>
    <default>1.2</default>
  </dp:param>

  <xsl:param name="dpconfig:dkt-offset" select="'0'"/>
  <dp:param name="dpconfig:dkt-offset" type="dmUInt16" xmlns="">
    <display>Offset of the Derived Key in the Key Sequence</display>
    <displayId>store.set-wssec-encrypt-param.param.dkt-offset.display</displayId>
    <description>
    This setting indicates where of the derived key starts in the byte stream
    of the lengthy generated key sequence. The default value is zero. 
    <p>This setting is exclusive with the "Generation" setting described as following.
    Set this setting as an empty string to enable the "Generation" setting.
    </p>
    </description>
    <descriptionId>store.set-wssec-encrypt-param.param.dkt-offset.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:wssec-encrypt</parameter-name>
          <value>attachments</value>
        </condition>
        <condition evaluation="property-value-not-in-list">
          <parameter-name>dpconfig:derivation-base</parameter-name>
          <value>sct-available</value>
          <value>dkt</value>
          <value>encryptedkey</value>
          <value>kerberos</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-key-derivation</parameter-name>
          <value>on</value>
        </condition>
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:encryption-key-type</parameter-name>
          <value>asymmetric</value>
        </condition>
      </condition>
    </ignored-when>
    <default>0</default>
  </dp:param>

  <xsl:param name="dpconfig:dkt-generation" select="''"/>
  <dp:param name="dpconfig:dkt-generation" type="dmUInt16" xmlns="">
    <display>Generation of the Derived Key in the Key Sequence</display>
    <displayId>store.set-wssec-encrypt-param.param.dkt-generation.display</displayId>
    <description>
    If a fixed sized key is generated, then this optional setting can be used
    to specify which generation of the key to use. The value of this setting
    is an unsigned long value indicating the index number of the fixed key in
    the lengthy key sequence. It starts with zero. If this setting is set, it
    precedes the above "Offset" setting; that is:
          offset = (generation) * length
    </description>
    <descriptionId>store.set-wssec-encrypt-param.param.dkt-generation.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:wssec-encrypt</parameter-name>
          <value>attachments</value>
        </condition>
        <condition evaluation="property-value-not-in-list">
          <parameter-name>dpconfig:derivation-base</parameter-name>
          <value>sct-available</value>
          <value>dkt</value>
          <value>encryptedkey</value>
          <value>kerberos</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:dkt-offset</parameter-name>
          <value></value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-key-derivation</parameter-name>
          <value>on</value>
        </condition>
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:encryption-key-type</parameter-name>
          <value>asymmetric</value>
        </condition>
      </condition>
    </ignored-when>
    <default></default>
  </dp:param>

  <xsl:param name="dpconfig:dkt-label" select="''"/>
  <dp:param name="dpconfig:dkt-label" type="dmString" xmlns="">
    <display>Label of the Derived Key</display>
    <displayId>store.set-wssec-encrypt-param.param.dkt-label.display</displayId>
    <description>
    Specify the label string for the wsc:DerivedKeyToken, if not specified, the default
    "WS-SecureConversationWS-SecureConversation" (represented as UTF-8 octets) is used.
    </description>
    <descriptionId>store.set-wssec-encrypt-param.param.dkt-label.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:wssec-encrypt</parameter-name>
          <value>attachments</value>
        </condition>
        <!-- the "dkt" derivation type will use the value from the parent DKT. -->
        <condition evaluation="property-value-not-in-list">
          <parameter-name>dpconfig:derivation-base</parameter-name>
          <value>sct-available</value>
          <value>encryptedkey</value>
          <value>kerberos</value>
        </condition>
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:use-key-derivation</parameter-name>
          <value>on</value>
        </condition>
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:encryption-key-type</parameter-name>
          <value>asymmetric</value>
        </condition>
      </condition>
    </ignored-when>
    <default></default>
  </dp:param>


  <xsl:param name="dpconfig:use-dynamic-enccert" select="'off'"/>
  <dp:param name="dpconfig:use-dynamic-enccert" type="dmToggle" xmlns="">
    <display>Use Dynamically Configured Recipient Certificate</display>
    <displayId>store.set-wssec-encrypt-param.param.use-dynamic-enccert.display</displayId>
    <description>Enable this property to encrypt the message with the verified signing
    certificate. The verified signing certificate is from the preceding verify
    action. If the message is not signed, encrypts with the public key for the
    intended recipient.</description>
    <descriptionId>store.set-wssec-encrypt-param.param.use-dynamic-enccert.description</descriptionId>
    <default>off</default>
    <ignored-when>
      <condition evaluation="property-does-not-equal">
        <parameter-name>dpconfig:encryption-key-type</parameter-name>
        <value>asymmetric</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:one-key-encryption" select="'off'"/>
  <dp:param name="dpconfig:one-key-encryption" type="dmToggle" xmlns="">
    <display>One Ephemeral Key</display>
    <displayId>store.set-wssec-encrypt-param.param.one-key-encryption.display</displayId>
    <description>Setting to 'on' causes all the encryption in this step to use the same
    Ephemeral Key. There will be only one ephemeral key encryption. Its corresponding
    EncryptedKey will add a DataReference URI for each EncryptedData. Enabling this setting
    will get better performance.
    When there is a WS-SecureConversation Key Derivation mechanism configured to be "encryptedkey"
    it is forced to use one EncryptedKey.
    </description>
    <descriptionId>store.set-wssec-encrypt-param.param.one-key-encryption.description</descriptionId>
    <default>off</default>
    <ignored-when>
      <condition evaluation="property-does-not-equal">
        <parameter-name>dpconfig:encryption-key-type</parameter-name>
        <value>asymmetric</value>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:include-reference-list" select="'off'"/>
  <dp:param name="dpconfig:include-reference-list" type="dmToggle">
    <display>Include xenc:ReferenceList in wsse:Security</display>
    <displayId>store.set-wssec-encrypt-param.param.include-reference-list.display</displayId>
    <description markup="html">Specify if the Security header will 
    include the xenc:ReferenceList element or not.
    </description>
    <descriptionId>store.set-wssec-encrypt-param.param.include-reference-list.description</descriptionId>
    <default>off</default>
  </dp:param>

  <xsl:param name="dpconfig:wssec11-enckey-cache" select="'0'"/>
  <dp:param name="dpconfig:wssec11-enckey-cache" type="dmTimeInterval" xmlns="">
    <display>EncryptedKeySHA1 Cache Lifetime for Derived Key</display>
    <displayId>store.set-wssec-encrypt-param.param.wssec11-enckey-cache.display</displayId>
    <units>sec</units>
    <unitsDisplayId>store.set-wssec-encrypt-param.param.wssec11-enckey-cache.unit.sec</unitsDisplayId>    
    <minimum>0</minimum> <!-- there will be no cache for this -->
    <maximum>604800</maximum> <!-- 7 days, this is chosen arbitrary -->
    <default>0</default>    
    <description markup="html"><p>This is the Cache Lifetime for the generated key.  Setting the value to 0 means the generated key will not be cached.</p>
    </description>
    <descriptionId>store.set-wssec-encrypt-param.param.wssec11-enckey-cache.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:token-reference-mechanism</parameter-name>
          <value>EncryptedKeySHA1</value>
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
    <display>Kerberos Encryptor Principal</display>
    <displayId>store.set-wssec-encrypt-param.param.clientprinc.display</displayId>
    <description>The name of the Kerberos principal that will encrypt the message.</description>
    <descriptionId>store.set-wssec-encrypt-param.param.clientprinc.description</descriptionId>
    <tab-override>basic</tab-override>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:wssec-encrypt</parameter-name>
          <value>attachments</value>
        </condition>
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:encryption-key-type</parameter-name>
          <value>asymmetric</value>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:derivation-base</parameter-name>
            <value>kerberos</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>on</value>
          </condition>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:symmetric-key-type</parameter-name>
            <value>kerberos</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>off</value>
          </condition>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:serverprinc"/>
  <dp:param name="dpconfig:serverprinc" type="dmString" xmlns="">
    <display>Kerberos Decryptor Principal</display>
    <displayId>store.set-wssec-encrypt-param.param.serverprinc.display</displayId>
    <description>The name of the Kerberos principal that will later decrypt the message.</description>
    <descriptionId>store.set-wssec-encrypt-param.param.serverprinc.description</descriptionId>
    <tab-override>basic</tab-override>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:wssec-encrypt</parameter-name>
          <value>attachments</value>
        </condition>
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:encryption-key-type</parameter-name>
          <value>asymmetric</value>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:derivation-base</parameter-name>
            <value>kerberos</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>on</value>
          </condition>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:symmetric-key-type</parameter-name>
            <value>kerberos</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>off</value>
          </condition>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:keytab"/>
  <dp:param name="dpconfig:keytab" type="dmReference" reftype="CryptoKerberosKeytab" xmlns="">
    <display>Kerberos Encryptor Keytab</display>
    <displayId>store.set-wssec-encrypt-param.param.keytab.display</displayId>
    <description>The name of the Kerberos Keytab that contains the encryptor's shared secret.</description>
    <descriptionId>store.set-wssec-encrypt-param.param.keytab.description</descriptionId>
    <tab-override>basic</tab-override>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:wssec-encrypt</parameter-name>
          <value>attachments</value>
        </condition>
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:encryption-key-type</parameter-name>
          <value>asymmetric</value>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:derivation-base</parameter-name>
            <value>kerberos</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>on</value>
          </condition>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:symmetric-key-type</parameter-name>
            <value>kerberos</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>off</value>
          </condition>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:kerberos-value-type" select="$URI-KRB5-GSS-APREQ-WSS11"/>
  <dp:param name="dpconfig:kerberos-value-type" type="dmCryptoKerberosBstValueType" xmlns="">
    <default>http://docs.oasis-open.org/wss/oasis-wss-kerberos-token-profile-1.1#GSS_Kerberosv5_AP_REQ</default>
    <display>WS-Security BinarySecurityToken Kerberos ValueType</display>
    <displayId>store.set-wssec-encrypt-param.param.kerberos-value-type.display</displayId>
    <description>The WS-Security Kerberos Token Profile BinarySecurityToken ValueType to use.</description>
    <descriptionId>store.set-wssec-encrypt-param.param.kerberos-value-type.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:wssec-encrypt</parameter-name>
          <value>attachments</value>
        </condition>
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:encryption-key-type</parameter-name>
          <value>asymmetric</value>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:derivation-base</parameter-name>
            <value>kerberos</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>on</value>
          </condition>
        </condition>
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:symmetric-key-type</parameter-name>
            <value>kerberos</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>off</value>
          </condition>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:forced-wssc-capability" select="'off'"/>
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

  <xsl:param name="dpconfig:include-sct-token" select="'on'"/>
  <dp:param name="dpconfig:include-sct-token" hidden="true" type="dmToggle" xmlns="">
  </dp:param>

  <!-- See bz#26904 for detail regarding the change and choice of default value. -->
  <xsl:param name="dpconfig:security-header-layout" select="'strict'"/>
  <dp:param name="dpconfig:security-header-layout" type="dmSecurityHeaderLayout" xmlns="">
    <display>WS-Security Security Header Layout</display>
    <displayId>store.set-wssec-encrypt-param.param.security-header-layout.display</displayId>
    <description>This indicates which layout rules to apply when adding items to the security header.</description>
    <descriptionId>store.set-wssec-encrypt-param.param.security-header-layout.description</descriptionId>
    <default>strict</default>
  </dp:param>
                               

  <xsl:include href="store:dp/kerberos-library.xsl" dp:ignore-multiple="yes"/>

  <xsl:include href="store:dp/ws-sx-utils.xsl" dp:ignore-multiple="yes"/>

  <!-- EncodingType attribute URI value for WS-Security v1.0 and v1.1 -->
  <xsl:variable name="wssec-b64-encoding">
    <xsl:text>http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary</xsl:text>
  </xsl:variable>

  <!-- some common xsl variables. -->

  <!-- determine whether we are supporting #EncryptedKeySHA1
       This is used by sign, encrypt action, and on the respond side.
       Is it possible for the request side ? I suspect it is possible, 
       e.g. 2 signatures with one generated session key and protected by X509, and other
       signature is derived from the first session key - this has not been seen in the field,
       so we are not going to worry about that here [since this assume we can perform
       2 signing operations within 1 sign action, or else we need some context variable for
       piping 2 sign actions, and both are not possible today with our framework]. 

       EncryptedKeySHA1 could happens :
       asymmetric encryption with EncryptedKeySHA1 is specified as KeyIdentifier - pre-3.7.3
       symmetric encryption with eks as keytype or derived key with eks as base
  -->
  <xsl:variable name="use-encryptedkeysha1">
    <xsl:if test="$dpconfig:wssec-compatibility = '1.1' and
                  ($dpconfig:encryption-key-type = 'asymmetric' and 
                   $dpconfig:token-reference-mechanism = 'EncryptedKeySHA1') 
                  or ($dpconfig:encryption-key-type = 'symmetric' and
                      ($dpconfig:symmetric-key-type = 'eks' or $dpconfig:symmetric-key-type = 'saml-symmetric-hok') 
                     )
                  or ($dpconfig:encryption-key-type = 'symmetric' and
                      $dpconfig:use-key-derivation = 'on' and
                      ($dpconfig:derivation-base = 'eks' or $dpconfig:derivation-base = 'saml-symmetric-hok'))">
      <xsl:copy-of select="dp:variable('var://context/transaction/cipherkey')"/>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="encrypt-headers">
    <xsl:choose>
      <xsl:when test="$dpconfig:swa-encrypt-transform = 'MIMEContentAndHeader'">
        <xsl:value-of select="'true'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="'false'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- swa-encrypt-type is determined by which version of swa profile is being used and whether or not parts of the mime header are being encrypted -->
  <xsl:variable name="swa-encrypt-type">
      <xsl:choose>
          <xsl:when test="$dpconfig:swa-compatibility = '1.1' and $encrypt-headers = 'true'">
              <xsl:value-of select="'http://docs.oasis-open.org/wss/oasis-wss-SwAProfile-1.1#Attachment-Complete'"/>
          </xsl:when>
          <xsl:when test="$dpconfig:swa-compatibility = '1.1' and $encrypt-headers = 'false'">
              <xsl:value-of select="'http://docs.oasis-open.org/wss/oasis-wss-SwAProfile-1.1#Attachment-Content-Only'"/>
          </xsl:when>
          <xsl:when test="$dpconfig:swa-compatibility = '1.0' and $encrypt-headers = 'true'">
              <xsl:value-of select="'http://docs.oasis-open.org/wss/2004/XX/oasis-2004XX-wss-swa-profile-1.0#Attachment-Complete'"/>
          </xsl:when>
          <xsl:otherwise>
              <xsl:value-of select="'http://docs.oasis-open.org/wss/2004/XX/oasis-2004XX-wss-swa-profile-1.0#Attachment-Content-Only'"/>
          </xsl:otherwise>
      </xsl:choose>
  </xsl:variable>

  <xsl:variable name="swa-transform">
      <xsl:choose>
          <xsl:when test="$dpconfig:swa-compatibility = '1.1'">
              <xsl:value-of select="'http://docs.oasis-open.org/wss/oasis-wss-SwAProfile-1.1#Attachment-Ciphertext-Transform'"/>
          </xsl:when>
          <xsl:otherwise>
              <xsl:value-of select="'http://docs.oasis-open.org/wss/2004/XX/oasis-2004XX-wss-swa-profile-1.0#Attachment-Content-Only-Transform'"/>
          </xsl:otherwise>
      </xsl:choose>
  </xsl:variable>

  <!-- this combination is not valid on purpose, it indicates the old wssec-encrypt
       behavior to use the SCT if it is available in the message even if asymmetric settings are on.  -->
  <xsl:variable name="old-behavior"
                select="$dpconfig:encryption-key-type = 'asymmetric' and
                        $dpconfig:use-key-derivation = 'on'"/>

  <xsl:variable name="available-sct-token">

    <xsl:choose>
      <xsl:when test="$dpconfig:derivation-base = 'no'">
        <!-- do not waste time to resolve the wssc version.  -->
      </xsl:when>

      <xsl:when test="($old-behavior and $dpconfig:derivation-base = 'sct-available') or
                      ($dpconfig:use-key-derivation != 'on' and $dpconfig:symmetric-key-type = 'sct-available') or
                      ($dpconfig:use-key-derivation = 'on' and $dpconfig:derivation-base = 'sct-available')">

        <xsl:variable name="token-in-header"
                      select="$existing-security-header/*[
                                local-name()='SecurityContextToken' or local-name()='SecureConversationToken'][1]"/>
        <xsl:variable name="token-in-body"
                      select="/*[local-name()='Envelope']/*[local-name()='Body']//*[
                                local-name()='RequestSecurityTokenResponse']/*[
                                local-name()='RequestedSecurityToken']/*[
                                local-name()='SecurityContextToken' or local-name()='SecureConversationToken'][1]"/>

        <source>sct-available</source>
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
	            get the available token from message or from a well known dp variable
	            'var://context/ca-out1/store-sct-var', the latter one is applicable for
	            any soap actors. 
            -->
            <xsl:variable name="sct-from-variable" select="dp:variable('var://context/ca-out1/store-sct-var')[1]"/>
            <xsl:if test="count($sct-from-variable) &gt; 0">
              <xsl:copy-of select="$sct-from-variable"/>
              <location>variable</location>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>

  <!-- variable indicates where the symmetric session key is from for the data encryption. -->
  <xsl:variable name="symmetric-key-base">
    <xsl:choose>
      <!-- attachment will always use EK? this use case was never discussed by the 3.7.1 scope,
           so assuming it is. -->
      <xsl:when test="$to-encrypt-attachment = 'true'"> 
        <xsl:value-of select="'encryptedkey'"/>
      </xsl:when>
      <!-- the old behavior of no sct token case will come here. -->
      <xsl:when test="$available-sct-token/source='sct-available' and
                      count($available-sct-token/location) = 0"> 
        <xsl:value-of select="'encryptedkey'"/>
      </xsl:when>
      <xsl:when test="$old-behavior and $dpconfig:derivation-base != 'no'"> 
        <xsl:value-of select="$dpconfig:derivation-base"/>
      </xsl:when>
      <xsl:when test="$dpconfig:encryption-key-type = 'asymmetric'">
        <xsl:value-of select="'encryptedkey'"/>
      </xsl:when>
      <xsl:when test="$dpconfig:use-key-derivation = 'on'">
        <xsl:value-of select="$dpconfig:derivation-base"/>
      </xsl:when>
      <xsl:when test="$dpconfig:use-key-derivation = 'off'">
        <xsl:value-of select="$dpconfig:symmetric-key-type"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- the wssec-encrypt default will use X509 cert to wrap the key. 
             it should never come to here as all the cases should have been processed.
          -->
        <xsl:message dp:id="{$DPLOG_SOAP_CHECK_CONFIG}" dp:priority="warn"/>
        <xsl:value-of select="'encryptedkey'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- variable indicates a DerivedKey token is ouput, and the derived key is
       the symmetric session key for data encryption. 
       -->
  <xsl:variable name="via-dk">
    <xsl:choose>
      <xsl:when test="$old-behavior and $dpconfig:derivation-base !='no' and
                      ($dpconfig:derivation-base != 'sct-available' or 
                       count($available-sct-token/location) &gt; 0)"> 
        <xsl:value-of select="'true'"/>
      </xsl:when>
      <xsl:when test="$dpconfig:encryption-key-type != 'asymmetric'">
        <xsl:value-of select="$dpconfig:use-key-derivation = 'on'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="'false'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- determine what need to be used to calculate key id or thumbprint in case X509 EK is output,
       for perf optimization, test the use-dynamic-enccert first. -->
  <xsl:variable name="effective-recipient">
    <xsl:choose>
      <xsl:when test="$dpconfig:encryption-key-type = 'keywrap'">
        <xsl:value-of select='concat("sskey:", $dpconfig:key)'/>
      </xsl:when>
      <xsl:when test="$symmetric-key-base != 'encryptedkey'">
        <!-- do nothing. -->
      </xsl:when>
      <xsl:when test="$dpconfig:use-dynamic-enccert = 'off'">
        <xsl:value-of select="concat('name:', $recipient)"/>
      </xsl:when>
      <xsl:when test="dp:variable('var://context/transaction/encrypting-cert') != ''">
        <xsl:value-of select="dp:variable('var://context/transaction/encrypting-cert')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('name:', $dpconfig:recipient)"/>
      </xsl:otherwise>
    </xsl:choose>                  
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
      <xsl:when test="$symmetric-key-base = 'sct-available'">
        <xsl:copy-of select="dpfunc:get-wssx-compatibility(
                                    $available-sct-token/*[local-name()='SecurityContextToken' or local-name()='SecureConversationToken'], 
                                    'wssc')"/>
      </xsl:when>
      <xsl:when test="$symmetric-key-base = 'dkt'">
        <xsl:copy-of select="dpfunc:get-wssx-compatibility(
                ( /*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='Security']/*[local-name()='DerivedKeyToken'] |
                  /*[local-name()='Envelope']/*[local-name()='Body']//*[local-name()='DerivedKeyToken']
                ) , 'wssc')"/>
      </xsl:when>
      <xsl:when test="$via-dk = 'true'">
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
            <!-- all those derived keys via a DerivedKeyToken, use the dpconfig:wssc-version config
                 to specify which version of WSSC namespace is used. -->
            <xsl:copy-of select="dpfunc:get-wssx-compatibility($dpconfig:wssc-version, 'version')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <!-- do not waste time to resolve the wssc version.  -->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <!-- retrieve the apreq and status from message, cache or prior action. -->
  <xsl:variable name="available-kerberos-token">
    <xsl:if test="$symmetric-key-base = 'kerberos'">
      <xsl:copy-of select="dpfunc:check-kerberos-apreq ($existing-security-header, 
                                                        $dpconfig:serverprinc, 
                                                        $dpconfig:clientprinc, 
                                                        $dpconfig:keytab)"/>
    </xsl:if>
  </xsl:variable>

  <dp:dynamic-namespace prefix="wsse" select="$wsse-uri"/>
  <dp:dynamic-namespace prefix="wsu" select="$wsu-uri"/>
  <dp:dynamic-namespace prefix="wsc" select="$wssc-capability/wssc/namespace-uri"/>

  <xsl:variable name="to-encrypt-attachment">
    <xsl:choose>
      <xsl:when test="$dpconfig:wssec-encrypt = 'message' or
                      $dpconfig:wssec-encrypt = ''">
        <xsl:value-of select="'false'"/>
      </xsl:when>
      <xsl:when test="( $dpconfig:wssec-encrypt = 'attachments' or 
                        $dpconfig:wssec-encrypt = 'message-attachments')">
        <xsl:value-of select="'true'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="'false'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="to-encrypt-message">
    <xsl:choose>
      <xsl:when test="$dpconfig:wssec-encrypt = '' or
                      $dpconfig:wssec-encrypt = 'message' or
                      $dpconfig:wssec-encrypt = 'message-attachments'">
        <xsl:value-of select="'true'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="'false'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:include href="store:///dp/encrypt.xsl" dp:ignore-multiple="yes"/>
  <xsl:include href="store:///dp/wssec-saml.xsl" dp:ignore-multiple="yes"/>

  <!-- Get the symmetric key result: the base token element and the base64 encoded symmetric key.

      As WS-Sec encryption is always using a symmetric key for data encryption, so every different
      token being used should provide some result like the following:  
          <symmetric-token>
              The NEW security tokens which are used in order to get the encryption key.
              If the tokens were in the input security header, do bother to output them here.
          </symmetric-token>
          <symmetric-key>
              the base64 encoded key returned by template "dp-generate-derived-key"
          </symmetric-key>
          <symmetric-token-reference>
              the SecurityTokenReference elements in order to refer to the symmetric-tokens
              without key derivation.
              if the DKT is the one being referred by EncryptedData, the STR will be
              handled automatically.
          </symmetric-token-reference>
    -->
  <xsl:variable name="symmetric-result">

    <!-- the symmetric result contains the tokens and keys for the final data encryption,
         however the configuration may result in using the keys from token to protect a
         ephemeral key, such as RSA Asymmetric key transport or symmetric KeyWrap, 
         So the keys from tokens will be put in a buffer for those configurations, and
         the final symmetric bulk encryption key is the ephemeral key.
         -->
    <xsl:variable name="pass1-result">
      <xsl:choose>                                            

        <!-- the default behavior, use the SCT if it is available. -->
        <xsl:when test="$symmetric-key-base = 'sct-available'">
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
            <!-- We have to insert the <wsc:SecurityTokenContext> node from
                 wherever we found it into the same WS-Security header as the
                 new derived key token node.
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
                      <xsl:when test="$dpconfig:wssec-id-ref-type='wsu:Id'"><xsl:attribute name="wsu:Id"><xsl:value-of select="$new-sct-id"/></xsl:attribute></xsl:when>
                      <xsl:otherwise><xsl:attribute name="xml:id"><xsl:value-of select="$new-sct-id"/></xsl:attribute></xsl:otherwise>
                    </xsl:choose>
                    <xsl:copy-of select="@*[translate(local-name(),'ID','id') != 'id']"/>
                    <xsl:copy-of select="namespace::* | comment()"/>
                    <xsl:copy-of select="child::*"/>
                  </xsl:copy>
                </xsl:for-each>
              </xsl:when>
              <xsl:otherwise/>
            </xsl:choose>

            <xsl:if test="$via-dk = 'true'">
              <xsl:call-template name="create-dkt-token">
                <xsl:with-param name="ref-id" select="$new-sct-id"/>
              </xsl:call-template>
            </xsl:if>

          </xsl:variable>

          <!-- output to the temp variable -->
          <symmetric-token>
            <xsl:copy-of select="$symmetric-tokens"/>
          </symmetric-token>
          <xsl:choose>
            <xsl:when test="$via-dk = 'true'">
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

        </xsl:when>  <!-- sct-available -->

        <!-- a WS-Security Kerberos token -->
        <xsl:when test="$symmetric-key-base = 'kerberos'">
          <!-- Ensure the Kerberos APREQ was actually created. If not,
               log the error and terminate. If so, create a BST for it and
               store the key identifier so that in future messages, which may
               reference the APREQ by the key identifier value and
               not include the BST itself, we can still process the
               key identifier reference.
          -->
          <xsl:if test="$available-kerberos-token/kerberos-error">
            <xsl:message dp:id="{$DPLOG_SOAP_KRB_ERR}" dp:priority="error" terminate="yes">
              <dp:with-param value="{string($available-kerberos-token/kerberos-error)}"/>
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

          <xsl:variable name="symmetric-tokens">
            <!-- the kerberos BST token, if it is not already in the security header. -->
            <xsl:copy-of select="$new-kerberos-bst/*"/>

            <!-- Key derivation -->
            <xsl:if test="$via-dk = 'true'">
              <xsl:call-template name="create-dkt-token">
                <xsl:with-param name="ref-id" select="$kerberos-bst-id"/>
              </xsl:call-template>
            </xsl:if>
          </xsl:variable>

          <xsl:variable name="sym-key"
                        select="dpfunc:extract-kerberos-session-key($available-kerberos-token, $dpconfig:algorithm)"/>
          <symmetric-token>
            <xsl:copy-of select="$symmetric-tokens"/>
          </symmetric-token>

          <xsl:choose>
            <xsl:when test="$via-dk = 'true'">
              <symmetric-key>
                <xsl:call-template name="dp-generate-derived-key">
                  <xsl:with-param name="from-token">
                    <session-key><xsl:value-of select="$sym-key"/></session-key>
                  </xsl:with-param>
                  <xsl:with-param name="dkt" select="$symmetric-tokens/*[local-name()='DerivedKeyToken']"/>
                  <xsl:with-param name="existing-security-header" select="$existing-security-header"/>
                </xsl:call-template>
              </symmetric-key>
            </xsl:when>
            <xsl:otherwise>
              <symmetric-key>
                <!-- Not a derived key - the Kerberos session key -->
                <xsl:value-of select="$sym-key"/>
              </symmetric-key>
              <symmetric-token-reference>
                <xsl:call-template name="create-token-reference">
                  <xsl:with-param name="ref-id" select="$kerberos-bst-id"/>
                </xsl:call-template>
              </symmetric-token-reference>
            </xsl:otherwise>
          </xsl:choose>

        </xsl:when>  <!-- kerberos -->

        <!-- derive a key from a named DKT. -->
        <xsl:when test="$symmetric-key-base = 'dkt'">
          <xsl:variable name="dkt">
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

          <xsl:variable name="dkt-id" select="$dkt/*[local-name()='DerivedKeyToken']/@*[translate(local-name(), 'ID', 'id')='id']"/>
          <xsl:variable name="length" select="dpfunc:get-dkt-length-for-encryption()"/>
          <xsl:variable name="new-dkt-id">
            <xsl:choose>
              <xsl:when test="not($dkt-id)">
                <xsl:value-of select="concat('DKT-', dp:generate-uuid())"/>
              </xsl:when>
              <xsl:when test="$length != $dkt/*[local-name()='DerivedKeyToken']/*[local-name()='Length']">
                <xsl:message dp:id="{$DPLOG_SOAP_INCORRECT_DKT_LEN}" dp:priority="info"/>
                <xsl:value-of select="concat('DKT-', dp:generate-uuid())"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$dkt-id"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <xsl:variable name="new-dkt">
            <xsl:if test="$dpconfig:base-dkt-name = '' and $new-dkt-id != $dkt-id">
              <xsl:for-each select="$dkt/*[local-name()='DerivedKeyToken']">
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

                  <xsl:for-each select="child::*">
                    <xsl:choose>
                      <xsl:when test="local-name() = 'Length'">
                        <xsl:copy><xsl:value-of select="$length"/></xsl:copy>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:copy-of select="."/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:for-each>
                </xsl:copy>
              </xsl:for-each>
            </xsl:if>

            <xsl:copy-of select="$dkt"/>
          </xsl:variable>
          
          <xsl:variable name="parent-dkt" 
                        select="($new-dkt/*[local-name()='DerivedKeyToken'])[1]"/>
          
          <xsl:if test="count($parent-dkt) = 0">
            <xsl:message dp:id="{$DPLOG_SOAP_NO_DKT}" dp:priority="error" terminate="yes"/>
          </xsl:if>
          
          <xsl:variable name="symmetric-tokens">
            <xsl:if test="$via-dk = 'true'">
              <xsl:call-template name="create-dkt-token">
                <xsl:with-param name="ref-id" select="$new-dkt-id"/>
                <xsl:with-param name="default-nonce" select="$parent-dkt/*[local-name()='Properties']/*[local-name()='Nonce']"/>
              </xsl:call-template>
            </xsl:if>
          </xsl:variable>

          <symmetric-token>
            <!-- If the DKT is reused but it doesnt have an ID attribute,
                 copy it to a new DKT by adding the attribute for referencing. -->
            <xsl:if test="$dpconfig:base-dkt-name = '' and $new-dkt-id != $dkt-id">
              <xsl:copy-of select="$parent-dkt"/>
            </xsl:if>

            <xsl:copy-of select="$symmetric-tokens"/>
          </symmetric-token>

          <!-- output to the temp variable -->
          <xsl:choose>
            <xsl:when test="$via-dk = 'true'">
              <symmetric-key>
                <xsl:call-template name="dp-generate-derived-key">
                  <xsl:with-param name="from-token" select="$parent-dkt"/>
                  <xsl:with-param name="dkt" select="$symmetric-tokens/*[local-name()='DerivedKeyToken']"/>
                  <xsl:with-param name="existing-security-header" select="$existing-security-header"/>
                </xsl:call-template>
              </symmetric-key>
            </xsl:when>
            <xsl:otherwise>
              <symmetric-key>
                <!-- get the symmetric key out of parent-dkt by resolve that derived key. -->
                <xsl:call-template name="dp-resolve-symmetric-key">
                  <xsl:with-param name="dkt" select="$parent-dkt"/>
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

        </xsl:when>   <!-- dkt -->                                          

        <!-- encrypted key, with/out key derivation -->
        <xsl:when test="$symmetric-key-base = 'encryptedkey' or 
                        $symmetric-key-base = 'eks' or
                        $symmetric-key-base = 'saml-symmetric-hok'">

          <xsl:variable name="sym-key">
            <xsl:choose>
              <!-- secure conversation for one-key? yes, it is possible when key derivation-base is encryptedkey.
                   when a DKT is from an encrypted key, always use one encrypted key. -->
              <xsl:when test="$symmetric-key-base = 'encryptedkey' and
                              ($dpconfig:one-key-encryption = 'on' or $via-dk = 'true')">
                <xsl:value-of select="dp:generate-key($dpconfig:algorithm)"/>
              </xsl:when>
              <xsl:when test="$symmetric-key-base = 'eks'">
                <xsl:value-of select="$use-encryptedkeysha1/sessionkey"/>
              </xsl:when>
              <xsl:when test="$symmetric-key-base = 'saml-symmetric-hok'">
                <xsl:if test="$dpconfig:validate-saml = 'on' and
                              not(dpfunc:check-saml-timestamp(
                                         $use-encryptedkeysha1/saml-token/Conditions/@NotBefore,
                                         $use-encryptedkeysha1/saml-token/Conditions/@NotOnOrAfter,
                                         $dpconfig:saml-skew-time))">
                  <xsl:message dp:id="{$DPLOG_CRYPTO_GENERIC_EXPIRED_SAML}" dp:priority="error"/>
                  <dp:reject>The SAML assertion has expired.</dp:reject>
                </xsl:if>
                <xsl:value-of select="$use-encryptedkeysha1/sessionkey"/>
              </xsl:when>
              <xsl:otherwise>
                <!-- no one key, the key will be generated by each data encryption. -->
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <xsl:variable name="encrypted-key">
            <xsl:choose>
              <!-- secure converation for one-key? yes, it is possible when key derivation-base is encryptedkey.
                   when a DKT is from an encrypted key, always use one encrypted key. -->
              <xsl:when test="$symmetric-key-base = 'encryptedkey' and
                              ($dpconfig:one-key-encryption = 'on' or $via-dk = 'true')">

                <xsl:call-template name="dp-generate-encrypted-key">
                    <xsl:with-param name="session-key" select='$sym-key'/>
                    <xsl:with-param name="recipient" select="$effective-recipient"/>
                    <xsl:with-param name="use-dynamic-enccert" select='$dpconfig:use-dynamic-enccert'/>
                    <xsl:with-param name="need-id-attr" select="$via-dk = 'true'"/>
                    <xsl:with-param name="algo"
                                    select="$dpconfig:key-transport-algorithm"/>
                    <xsl:with-param name="oaep-params"
                                    select="$dpconfig:oaep-params"/>
                    <xsl:with-param name="oaep-digest-algorithm"
                                    select="$dpconfig:oaep-digest-algorithm"/>
                    <xsl:with-param name="wssec11-enckey-cache" select="$dpconfig:wssec11-enckey-cache"/>
                    <xsl:with-param name="oaep-mgf-algorithm"
                                    select="$dpconfig:oaep-mgf-algorithm"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>   <!-- eks/saml-symmetric-hok does not have key material -->
                <!-- no one key, the key will be generated by each data encryption. -->
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <!-- the variable $encrypted-key should have the token to derive from. -->
          <xsl:variable name="symmetric-tokens">
            <xsl:if test="$via-dk = 'true'">
              <xsl:choose>
                <xsl:when test="$symmetric-key-base = 'encryptedkey'">
                  <xsl:call-template name="create-dkt-token">
                    <xsl:with-param name="ref-id" select="$encrypted-key/*[local-name()='EncryptedKey']/@*[translate(local-name(),'ID','id')='id'][1]"/>
                  </xsl:call-template>
                </xsl:when>
                <xsl:otherwise> <!-- eks or saml-symmetric-hok -->
                  <xsl:call-template name="create-dkt-token">
                  </xsl:call-template>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:if>
          </xsl:variable>

          <!-- output to the temp variable -->
          <symmetric-token>
            <!-- output the DKT, which uses the EncryptedKey. -->
            <xsl:copy-of select="$symmetric-tokens"/>

            <!-- only "encryptedkey" base will contain something. -->
            <xsl:copy-of select="$encrypted-key/xenc:EncryptedKey"/>
          </symmetric-token>

          <xsl:choose>
            <xsl:when test="$via-dk = 'true'">
              <symmetric-key>
                <xsl:choose>
                  <xsl:when test="$symmetric-key-base = 'encryptedkey'">
                    <xsl:call-template name="dp-generate-derived-key">
                      <xsl:with-param name="from-token" select="$sym-key"/>
                      <xsl:with-param name="dkt" select="$symmetric-tokens/*[local-name()='DerivedKeyToken']"/>
                      <xsl:with-param name="existing-security-header" select="$existing-security-header"/>
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:when test="not($use-encryptedkeysha1/node())"> <!-- eks, but no eks material -->
                   <xsl:message dp:id="{$DPLOG_SOAP_NO_ENCRYPTEDKEYSHA1}" dp:priority="error"/>
                  </xsl:when>
                  <xsl:otherwise>  <!-- eks or saml-symmetric-hok -->
                    <xsl:if test="$symmetric-key-base = 'saml-symmetric-hok' and
                                  $dpconfig:validate-saml = 'on' and
                                  not(dpfunc:check-saml-timestamp(
                                         $use-encryptedkeysha1/saml-token/Conditions/@NotBefore,
                                         $use-encryptedkeysha1/saml-token/Conditions/@NotOnOrAfter,
                                         $dpconfig:saml-skew-time))">
                      <xsl:message dp:id="{$DPLOG_CRYPTO_GENERIC_EXPIRED_SAML}" dp:priority="error"/>
                      <dp:reject>The SAML assertion has expired.</dp:reject>
                    </xsl:if>
                    <xsl:call-template name="dp-generate-derived-key">
                      <xsl:with-param name="from-token">
                        <session-key><xsl:value-of select="$use-encryptedkeysha1/sessionkey"/></session-key>
                      </xsl:with-param>
                      <xsl:with-param name="dkt" select="$symmetric-tokens/*[local-name()='DerivedKeyToken']"/>
                      <xsl:with-param name="existing-security-header" select="$existing-security-header"/>
                    </xsl:call-template>
                  </xsl:otherwise>
                </xsl:choose>
              </symmetric-key>
            </xsl:when>

            <!-- if the EK is generated by each data encryption, no need to output the key. -->
            <xsl:when test="$sym-key != ''"> 
              <symmetric-key>
                <xsl:value-of select="$sym-key"/>
              </symmetric-key>
              <symmetric-token-reference>
                <xsl:choose>
                  <xsl:when test="$symmetric-key-base = 'encryptedkey'">
                    <xsl:call-template name="create-token-reference">
                      <xsl:with-param name="ref-id" select="$encrypted-key/xenc:EncryptedKey/@*[translate(local-name(),'ID','id')='id'][1]"/>
                    </xsl:call-template>
                  </xsl:when>
                  <!-- eks or saml-symmetric-hok. -->
                  <xsl:when test="$use-encryptedkeysha1/node()">
                    <xsl:call-template name="create-token-reference">
                    </xsl:call-template>
                  </xsl:when>
                </xsl:choose>
              </symmetric-token-reference>
            </xsl:when>
          </xsl:choose>
        </xsl:when>  <!-- encryptedkey ,  eks or saml-symmetric-hok -->

        <!-- use a SSKey, this can be configured for direct symmetric key only. No key derivation. -->
        <xsl:when test="$symmetric-key-base = 'static'">
          <xsl:variable name="sskey" select="concat('name:', $dpconfig:key)"/>
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
          <xsl:message dp:id="{$DPLOG_SOAP_SYMMETRIC_KEY_ERROR}" dp:priority="error" terminate="yes">
            <dp:with-param value="{string($symmetric-key-base)}"/>
          </xsl:message>
        </xsl:otherwise>
      </xsl:choose>                                           
    </xsl:variable>
    
    <xsl:variable name="symmetric-token-reference">
      <xsl:choose>
        <xsl:when test="$via-dk = 'true'">
          <wsse:SecurityTokenReference>
            <wsse:Reference URI="{concat('#', $pass1-result/symmetric-token/*[
                                                local-name()='DerivedKeyToken']/@*[
                                                translate(local-name(),'ID','id')='id'][1])}"
                            ValueType="{$wssc-capability/wssc/dk}"/>
          </wsse:SecurityTokenReference>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="$pass1-result/symmetric-token-reference/*"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- pass2: protect the bulk encryption key. output the final tokens/keys visible by EncryptedData.  -->
    <xsl:choose>                                            
      <!-- encrypted key base is asymmetrically protect by X509 already, 
           if keywrap protection is needed, do it now for any symmetric key type. -->
      <xsl:when test="$dpconfig:encryption-key-type = 'keywrap' and $symmetric-key-base != 'encryptedkey'">

          <!--  Generate an ephemeral key as the bulk encryption key, and wrap it up by the shared symmetric 
                token from pass1. 
          
                If the session key is wrapped, we should not make the EncryptedData to refer to the 
                symmetric tokens directly, instead it refers to the EK and EK points to the relative
                tokens, which means the output symmetric-key and symmetric-token-reference will be different
                from pass1.
                -->

          <xsl:variable name="sym-key" select="dp:generate-key($dpconfig:algorithm)"/>

          <xsl:message dp:id="{$DPLOG_SOAP_WRAP_EPHEMERAL_KEY}" dp:priority="info"/>

          <xsl:variable name="encrypted-key">
            <xsl:if test="$dpconfig:symmetric-keywrap-algo = $URI-XENC-KW-3DES and $dpconfig:algorithm != $URI-XENC-3DES-CBC">
              <xsl:message dp:id="{$DPLOG_SOAP_3DES_INVALID_ENC_ALG}" dp:priority="error" terminate="yes"/>
            </xsl:if>
            <xsl:call-template name="dp-generate-wrapped-key">
              <xsl:with-param name="session-key" select='$sym-key'/>
              <xsl:with-param name="algo" select="$dpconfig:symmetric-keywrap-algo"/>
              <xsl:with-param name="kwkey" select="$pass1-result/symmetric-key"/>
              <xsl:with-param name="kw-token-reference" select="$symmetric-token-reference"/>
            </xsl:call-template>
          </xsl:variable>

          <symmetric-token>
            <xsl:copy-of select="$pass1-result/symmetric-token/*"/>
            <!-- now the wrapped EK should be one of the tokens to output. -->
            <xsl:copy-of select="$encrypted-key/xenc:EncryptedKey"/>
          </symmetric-token>

          <symmetric-key>
            <xsl:value-of select="$sym-key"/>
          </symmetric-key>
          <symmetric-token-reference>
            <xsl:variable name="ref-id" select="$encrypted-key/xenc:EncryptedKey/@*[translate(local-name(),'ID','id')='id'][1]"/>
            <wsse:Reference URI="{concat('#', $ref-id)}" 
                            ValueType="http://docs.oasis-open.org/wss/oasis-wss-soap-message-security-1.1#EncryptedKey"/>
          </symmetric-token-reference>
      </xsl:when>

      <xsl:otherwise>
          <xsl:copy-of select="$pass1-result/symmetric-token | $pass1-result/symmetric-key"/>
          <symmetric-token-reference>
              <xsl:copy-of select="$symmetric-token-reference"/>
          </symmetric-token-reference>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="all-encrypted-attachments">
    <xsl:choose>
      <xsl:when test="$to-encrypt-attachment = 'false'">
        <!-- no need to encrypt attachments -->
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="all-attachments" select="dp:variable('var://local/attachment-manifest')"/>
        <!--
        <dp:dump-nodes file="'attachment-manifest.xml'" nodes="$all-attachments"/>
        -->

        <xsl:for-each select="$all-attachments/manifest/attachments/attachment">
            <xsl:variable name="content-size">
                <xsl:value-of select="size"/>
            </xsl:variable>
            <xsl:message dp:id="{$DPLOG_SOAP_CONTENT_SIZE}" dp:priority="debug">
              <dp:with-param value="{string($content-size)}"/>
            </xsl:message>

            <xsl:variable name="uri">
                <xsl:value-of select="uri"/>
            </xsl:variable>
            <xsl:message dp:id="{$DPLOG_SOAP_URI}" dp:priority="debug"> 
              <dp:with-param value="{string($uri)}"/>
            </xsl:message>

            <xsl:variable name="content-type">
                <xsl:value-of select="header[name='Content-Type']/value"/>
            </xsl:variable>
            <xsl:message dp:id="{$DPLOG_SOAP_CONTENT_TYPE}" dp:priority="debug">
              <dp:with-param value="{string($content-type)}"/>
            </xsl:message>

            <xsl:if test="not($content-size = 0 or $uri = '')">
              <!-- output the EncryptedData for each attachment.-->
              <xsl:call-template name="dp-encrypt-attachment">
                  <xsl:with-param name="attachment-uri" select="$uri"/>
                  <xsl:with-param name="attachment-type" select="$content-type"/>
                  <xsl:with-param name="algorithm" select="$dpconfig:algorithm"/>
                  <xsl:with-param name="secret-key" select="string($symmetric-result/symmetric-key)"/>
                  <xsl:with-param name="encrypted-secret-key" select="$symmetric-result/symmetric-token/xenc:EncryptedKey"/>
                  <xsl:with-param name="swa-encrypt-type" select="$swa-encrypt-type"/>
                  <xsl:with-param name="swa-transform" select="$swa-transform"/>
                  <xsl:with-param name="encrypt-headers" select="$dpconfig:swa-encrypt-transform = 'MIMEContentAndHeader'"/>
                  <xsl:with-param name="recipient" select='concat("name:", $recipient)'/>
                  <xsl:with-param name="use-dynamic-enccert" select='$dpconfig:use-dynamic-enccert'/>
                  <xsl:with-param name="wssec11-enckey-cache" select="$dpconfig:wssec11-enckey-cache"/>
                  <xsl:with-param name="use-encryptedkeysha1" select ="$use-encryptedkeysha1"/>
                  <xsl:with-param name="key-transport-algorithm"
                                  select ="$dpconfig:key-transport-algorithm"/>
                  <xsl:with-param name="oaep-params"
                                  select ="$dpconfig:oaep-params"/>
                  <xsl:with-param name="oaep-digest-algorithm"
                                  select ="$dpconfig:oaep-digest-algorithm"/>
                  <xsl:with-param name="oaep-mgf-algorithm"
                                    select="$dpconfig:oaep-mgf-algorithm"/>
              </xsl:call-template>
            </xsl:if>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <func:function name="dpfunc:get-dkt-length-for-encryption">

    <xsl:variable name="length">
      <!-- see the list also with type dmCryptoEncryptionAlgorithm and crCipher.cpp-->
      <xsl:choose>
        <xsl:when test="$dpconfig:algorithm = $URI-XENC-3DES-CBC or
                        $dpconfig:algorithm = $URI-XENC-AES192-CBC or
                        $dpconfig:algorithm = 'aes192-ecb' or
                        $dpconfig:algorithm = 'http://www.datapower.com/cf#modified-3des' or
                        $dpconfig:algorithm = '3des-ecb'">
          <xsl:value-of select="'24'"/>
        </xsl:when>
        <xsl:when test="$dpconfig:algorithm = $URI-XENC-AES128-CBC or
                        $dpconfig:algorithm = 'aes128-ecb' or
                        $dpconfig:algorithm = 'aes128-cbc-ltpa'">
          <xsl:value-of select="'16'"/>
        </xsl:when>
        <xsl:when test="$dpconfig:algorithm = $URI-XENC-AES256-CBC or
                        $dpconfig:algorithm = 'aes256-ecb'">
          <xsl:value-of select="'32'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'32'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <func:result select="$length"/>
  </func:function>


  <xsl:template name="create-dkt-token">
    <xsl:param name="ref-id" select="''"/>
    <xsl:param name="default-nonce" select="/.."/>
    
    <xsl:variable name="length" select="dpfunc:get-dkt-length-for-encryption()"/>

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

  <!-- MSG AND FIELD LEVEL ENCRYPTION CODES MERGED HERE
    The followings codes are merged from, and being
    reused by, msg level and field level wssec-encrypt 
    stylesheets.
    -->

  <xsl:param name="dpconfig:include-keyname" select="'off'"/>

  <xsl:template name="generate-one-key-dataref">
      <xenc:ReferenceList>
        <xsl:if test="$to-encrypt-attachment = 'true'">
          <xsl:for-each select="$all-encrypted-attachments/xenc:EncryptedData">
            <xenc:DataReference URI="{concat('#', @Id)}"/>
          </xsl:for-each>
        </xsl:if>
        <xsl:if test="$to-encrypt-message = 'true'">
          <xsl:for-each select="$encrypted-trees/encrypted-tree">
            <xenc:DataReference URI="{concat('#', @node-id)}"/>
          </xsl:for-each>
        </xsl:if>
      </xenc:ReferenceList>
  </xsl:template>

  <!-- pre-compute the encrypted trees for the selected nodes and
       store in a global var -->
  <xsl:variable name="encrypted-trees">
    <xsl:if test="$to-encrypt-message = 'true'">
      <xsl:apply-templates mode="encrypted-trees" select="/"/>
    </xsl:if>
  </xsl:variable>

  <xsl:template match="/">

    <xsl:call-template name="clear-num-wssec-counter"/>

    <!--
    <dp:dump-nodes file="'to-encrypt.xml'" nodes="/"/>
    <xsl:message dp:priority="debug"> dpconfig:wssec-encrypt: <xsl:copy-of select="$dpconfig:wssec-encrypt"/></xsl:message>
    <xsl:message dp:priority="debug"> dpconfig:swa-compatibility: <xsl:copy-of select="$dpconfig:swa-compatibility"/></xsl:message>
    <xsl:message dp:priority="debug"> to-encrypt-message: <xsl:copy-of select="$to-encrypt-message"/></xsl:message>
    <xsl:message dp:priority="debug"> to-encrypt-attachment: <xsl:copy-of select="$to-encrypt-attachment"/></xsl:message>
    <xsl:message dp:priority="debug"> dpconfig:encryption-key-type: <xsl:copy-of select="$dpconfig:encryption-key-type"/></xsl:message>
    <xsl:message dp:priority="debug"> dpconfig:use-key-derivation: <xsl:copy-of select="$dpconfig:use-key-derivation"/></xsl:message>
    <xsl:message dp:priority="debug"> dpconfig:derivation-base: <xsl:copy-of select="$dpconfig:derivation-base"/></xsl:message>
    <xsl:message dp:priority="debug"> dpconfig:symmetric-key-type: <xsl:copy-of select="$dpconfig:symmetric-key-type"/></xsl:message>
    <xsl:message dp:priority="debug"> old-behavior: <xsl:copy-of select="$old-behavior"/></xsl:message>
    <xsl:message dp:priority="debug"> symmetric-key-base: <xsl:copy-of select="$symmetric-key-base"/></xsl:message>
    <xsl:message dp:priority="debug"> via-dk: <xsl:copy-of select="$via-dk"/></xsl:message>
    <xsl:message dp:priority="debug"> available-sct-token: <xsl:copy-of select="$available-sct-token"/></xsl:message>
    <xsl:message dp:priority="debug"> available-kerberos-token: <xsl:copy-of select="$available-kerberos-token"/></xsl:message>                                 
    <xsl:message dp:priority="debug"> dpconfig:wssc-version: <xsl:copy-of select="$dpconfig:wssc-version"/></xsl:message>
    <xsl:message dp:priority="debug"> dpconfig:include-reference-list: <xsl:copy-of select="$dpconfig:include-reference-list"/></xsl:message>
    <xsl:message dp:priority="debug"> dpconfig:one-key-encryption: <xsl:copy-of select="$dpconfig:one-key-encryption"/></xsl:message>
    <xsl:message dp:priority="debug"> resolved-actor-role-id: <xsl:copy-of select="$resolved-actor-role-id"/></xsl:message>
    <xsl:message dp:priority="debug"> symmetric-result: <xsl:copy-of select="$symmetric-result"/></xsl:message>
    <xsl:message dp:priority="debug"> session-key: <xsl:copy-of select="$symmetric-result/symmetric-key"/></xsl:message>
    <xsl:message dp:priority="debug"> encrypted-trees: <xsl:copy-of select="$encrypted-trees"/></xsl:message>
    <xsl:message dp:priority="debug"> all-encrypted-attachments: <xsl:copy-of select="$all-encrypted-attachments"/></xsl:message>
    <xsl:message dp:priority="debug"> wsse-uri: <xsl:copy-of select="$wsse-uri"/></xsl:message>
    <xsl:message dp:priority="debug"> use-encryptedkeysha1: <xsl:copy-of select="$use-encryptedkeysha1"/></xsl:message>

    <dp:dump-nodes file="'all-encrypted-attachments.xml'" nodes="$all-encrypted-attachments"/>
    <dp:dump-nodes file="'all-encrypted-trees.xml'" nodes="$encrypted-trees"/>
    <dp:dump-nodes file="'symmetric-result.xml'" nodes="$symmetric-result"/>
    <dp:dump-nodes file="'wssc-capability.xml'" nodes="$wssc-capability"/>

    <xsl:for-each select="key('soap-actor-role', $resolved-actor-role-id)">
          <xsl:message>Name=: <xsl:value-of select="local-name(.)"/></xsl:message>
          <xsl:message>   matched=: <xsl:value-of select="dpfunc:match-actor-role(., $resolved-actor-role-id)"/></xsl:message>
    </xsl:for-each>
    -->

    <xsl:choose>
      <xsl:when test="dpfunc:ambiguous-wssec-actor(key('soap-actor-role', $resolved-actor-role-id), $dpconfig:actor-role-id)">
        <xsl:call-template name="wssec-security-header-fault">
          <xsl:with-param name="actor" select="$dpconfig:actor-role-id"/>
          <xsl:with-param name="soapnsuri" select="$___soapnsuri___"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="/*[local-name()='Envelope']">

    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:copy-of select="namespace::*"/>
      <xsl:choose>
        <!-- if there is Header. -->
        <xsl:when test="*[namespace-uri()=$___soapnsuri___ and local-name()='Header']">
            <xsl:apply-templates select="*[namespace-uri()=$___soapnsuri___ and local-name()='Header']"/>
        </xsl:when>
        <xsl:otherwise>
            <!-- create a SOAP header -->
            <xsl:element namespace="{$___soapnsuri___}" name="{concat($___soapnsprefix___, 'Header')}">
              <!-- no security headers have been used to inject data, we get to add a new header. -->
              <xsl:call-template name="create-security-header"/>
            </xsl:element>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:apply-templates select="./*[namespace-uri()=$___soapnsuri___ and local-name() = 'Body']"/>
      
      <!-- copy all the others. -->
      <xsl:copy-of select="*[not(namespace-uri()=$___soapnsuri___ and (local-name()='Header' or local-name()='Body'))]"/>
    </xsl:copy>
  </xsl:template>

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
    <xsl:variable name="security-header">
      <wsse:Security>
        <xsl:if test="$dpconfig:include-mustunderstand = 'on'">
          <xsl:attribute namespace="{$___soapnsuri___}" name="{concat($___soapnsprefix___, 'mustUnderstand')}">1</xsl:attribute>
        </xsl:if>

        <xsl:if test="$dpconfig:actor-role-id != ''">
          <!-- not to omit the actor/role attribute when there is non empty actor/role. -->
          <xsl:attribute namespace="{$___soapnsuri___}" name="{$___actor_role_attr_name___}"><xsl:value-of select="$dpconfig:actor-role-id"/></xsl:attribute>
        </xsl:if>

        <xsl:call-template name="wssec-security-header-content"/>

     </wsse:Security>
    </xsl:variable>
    <!-- Only copy in the WS-Security header if it actually contains
         children. It will not, for instance, if the encryption uses
         wsse:KeyIdentifier as a child of KeyInfo - this will appear
         directly in the encrypted data element.
    -->
    <xsl:if test="count($security-header//*) &gt; 1">
      <xsl:copy-of select="$security-header"/>
    </xsl:if>
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

                <xsl:call-template name="wssec-security-header-content">
                  <xsl:with-param name="security" select="."/>
                </xsl:call-template>

            </xsl:copy>
        </xsl:when>
        <xsl:otherwise>
            <!-- does not match the actor/role, 
                 Preserve the other wssec header elements, like saml:Assertion etc. 
                 Process all of the stuff in the Security header
                 some of which may be slated for encryption. -->
            <xsl:apply-templates select="."/>
        </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="@*" priority="-3">
    <xsl:copy/>
  </xsl:template>

  <xsl:template match="node()" priority="-3">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:copy-of select="namespace::*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="xenc:EncryptedData" mode ="swa">
    <xsl:choose>
      <xsl:when test="$dpconfig:token-reference-mechanism = 'EncryptedKeySHA1'">
          <!-- When encrypting an attachment, according to SwA spec V1.1 section 5.5.0 or line 586,
               if there is a EncryptedKey element in the Security header for the encrypted attachment,
               the EncryptedData must NOT contain a dsig:KeyInfo element.
               In case of EncryptedKeySHA1 keyidentifier, there is no EncryptedKey in the security header,
               so we must copy the KeyInfo.
               -->
        <xsl:copy-of select="."/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <xsl:copy-of select="namespace::*"/>
          <!-- When encrypting an attachment, according to SwA spec V1.1 section 5.5.0 or line 586,
               if there is a EncryptedKey element in the Security header for the encrypted attachment,
               the EncryptedData must NOT contain a dsig:KeyInfo element.

               DP implementation always generate EncryptedKey for Security header, so we must strip 
               the dsig:KeyInfo out from the EncryptedData, if there is, in case of SwA encryption.
           -->
          <xsl:copy-of select="*[not(self::dsig:KeyInfo)]"/>
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="wssec-security-header-content">
    <xsl:param name="security" select="/.."/>
    
    <!-- First copy the base tokens, then the tokens derived out of it-->
    <xsl:if test="$dpconfig:security-header-layout = 'strict' or
                  $dpconfig:security-header-layout = 'Strict'">   <!-- see bug 28629 -->             
      <xsl:apply-templates select="$security/*[local-name()='SecurityContextToken']"/>
    </xsl:if>

    <!--
         In case of key base 'encryptedkey' the buffer may have contained the EncryptedKey,
         which have been output, now process those EncryptedKey which are not in the
         symmetric-result.
         -->
    <xsl:choose>
      <xsl:when test="$dpconfig:encryption-key-type = 'keywrap' and $symmetric-key-base != 'encryptedkey'">
        <xsl:apply-templates mode="keywrap" select="$symmetric-result/symmetric-token/xenc:EncryptedKey"/>
      </xsl:when>
      <xsl:when test="$symmetric-key-base != 'encryptedkey'">
        <!-- no additional EKs to output.  -->
      </xsl:when>
      <xsl:when test="$dpconfig:one-key-encryption = 'on' or $via-dk = 'true'">
        <!-- output the one-key EK. -->
        <xsl:apply-templates mode="keys" select="$symmetric-result/symmetric-token/xenc:EncryptedKey"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates mode="keys" select="$encrypted-trees/encrypted-tree"/>
        <xsl:apply-templates mode="keys" select="$all-encrypted-attachments/xenc:EncryptedData"/>
      </xsl:otherwise>
    </xsl:choose>

    <!-- In case of WS-SC, the DKT and/or SCT are stored in the buffer, 
         output them here directly (that's why we can remove the $dkt-elem param.)
         In case of non WS-SC when key base is 'encryptedkey', the buffer may have 
         contained the EncryptedKey, which doesn't have the data Reference.
      -->
    <xsl:copy-of select="$symmetric-result/symmetric-token/*[not(self::xenc:EncryptedKey)]"/>
    
    <xsl:if test="$dpconfig:include-reference-list='on'">
      <xsl:call-template name="generate-one-key-dataref"/>
    </xsl:if>

    <xsl:apply-templates select="$all-encrypted-attachments/xenc:EncryptedData" mode="swa"/>

    <!-- Now process all of existing security header contents.
         some of which may be slated for encryption. -->
    <xsl:choose>
      <xsl:when test="$dpconfig:security-header-layout = 'strict' or
                      $dpconfig:security-header-layout = 'Strict'"> <!-- see bug 28629 -->
        <xsl:apply-templates select="$security/*[not(local-name()='SecurityContextToken')]"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="$security/*"/>
      </xsl:otherwise>
    </xsl:choose>

    <!-- increate the counter -->
    <xsl:call-template name="inc-num-wssec-counter"/>
 
  </xsl:template>

  <!-- keywrap mode: the EncryptedKey is protected by kw algorithm, 
       output it and insert the data reference.  -->
  <xsl:template mode="keywrap" 
                match="xenc:EncryptedKey[substring(substring-after(xenc:EncryptionMethod/@Algorithm, '#'), 1, 3) = 'kw-']">
    <xsl:if test="$to-encrypt-attachment = 'true' or $to-encrypt-message = 'true'">
      <xsl:copy>
        <xsl:copy-of select="@Id"/>
        <xsl:copy-of select="xenc:EncryptionMethod"/>
        <xsl:copy-of select="dsig:KeyInfo"/>
        <xsl:copy-of select="xenc:CipherData"/>
        <xsl:call-template name="generate-one-key-dataref"/>
      </xsl:copy>
    </xsl:if>
  </xsl:template>

  <!-- keys mode: the encrypted xml nodes. -->
  <xsl:template mode="keys" match="encrypted-tree">
    <xsl:apply-templates mode="keys" select="xenc:EncryptedData//xenc:EncryptedKey">
      <xsl:with-param name="ref-id" select="@node-id"/>
    </xsl:apply-templates>
  </xsl:template>

   <!-- keys mode: the encrypted attachments and encrypted soap body. -->
  <xsl:template mode="keys" match="xenc:EncryptedData">
    <xsl:apply-templates mode="keys" select=".//xenc:EncryptedKey">
        <xsl:with-param name="ref-id" select="@Id"/>
    </xsl:apply-templates>
  </xsl:template>

  <!--
       keys mode: create the EncryptedKey elements for the header
       (they point to the data!)
       -->
  <xsl:template mode="keys" match="xenc:EncryptedKey">
    <!-- if it is possible to update the autobuild ref files, it would be better to use a dynamic id. -->
    <xsl:param name="ref-id" select="'body'"/>
    
    <xsl:if test="$to-encrypt-attachment = 'true' or $to-encrypt-message = 'true'">
      <xsl:variable name="bst-id" select="concat('SecurityToken-', dp:generate-uuid())"/>

      <xsl:call-template name="create-x509-bst">
        <xsl:with-param name="ref-id" select="$bst-id"/>
        <xsl:with-param name="cert" select="$effective-recipient"/>
      </xsl:call-template>

      <xenc:EncryptedKey>
        <xsl:copy-of select="@Id"/>
        <xsl:copy-of select="./xenc:EncryptionMethod"/>
        <dsig:KeyInfo>
          <xsl:call-template name="create-token-reference">
            <xsl:with-param name="ref-id" select="$bst-id"/>
            <xsl:with-param name="token-type" select="'x509'"/>
          </xsl:call-template>
        </dsig:KeyInfo>

        <xsl:if test="$dpconfig:include-keyname = 'on'">
          <dsig:KeyInfo>
            <dsig:KeyName><xsl:value-of select="./dsig:KeyInfo/dsig:KeyName"/></dsig:KeyName>
          </dsig:KeyInfo>
        </xsl:if>

        <xsl:if test="$dpconfig:token-reference-mechanism != 'EncryptedKeySHA1'">
          <xsl:copy-of select="./xenc:CipherData"/>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="$via-dk = 'true'">
             <!-- the EncryptedKey is not directly used for an encryption, do not 
                  output ReferenceList for this case. -->
          </xsl:when>

          <!-- In case of one-key-encryption, we should make the data reference for the
               encrypted element/attachment with this one key.  -->
          <xsl:when test="$dpconfig:one-key-encryption = 'on' or $dpconfig:token-reference-mechanism = 'EncryptedKeySHA1'">
            <xsl:call-template name="generate-one-key-dataref"/>
          </xsl:when>

          <xsl:otherwise>
            <xenc:ReferenceList>
              <xenc:DataReference URI="{concat('#', $ref-id)}"/>
            </xenc:ReferenceList>
          </xsl:otherwise>
        </xsl:choose>
      </xenc:EncryptedKey>
    </xsl:if>
  </xsl:template>

  <xsl:template name="create-x509-bst">
    <xsl:param name="ref-id" select="''"/>
    <xsl:param name="cert" select="''"/>

    <xsl:if test="$dpconfig:token-reference-mechanism = 'Direct'">
      <wsse:BinarySecurityToken>
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

          <xsl:otherwise>
            <!-- Default to 1.0 or 1.1 -->
            <xsl:attribute name="EncodingType"><xsl:value-of select="$wssec-b64-encoding"/></xsl:attribute>
            <xsl:attribute name="ValueType"><xsl:value-of select="$dpconfig:wss-x509-token-profile-1.0-binarysecuritytoken-reference-valuetype"/></xsl:attribute>
            <xsl:value-of select="dp:base64-cert($cert)"/>
          </xsl:otherwise>
        </xsl:choose>
          <!--
              'cert:', 'ski:', 'thumbprintsha1:', 'name:', 'issuerserial:' - get base64 format of the cert if possible.
               this is interesting, if the function failed, then the error message will act as cert.
          -->
      </wsse:BinarySecurityToken>
    </xsl:if>
  </xsl:template>

  <!-- token-type can be 'x509'
  -->
  <xsl:template name="create-token-reference">
    <xsl:param name="ref-id" select="''"/>
    <xsl:param name="token-type" select="''"/>

    <wsse:SecurityTokenReference>

      <xsl:choose>
        <!-- there is a BST generated, either by asymmetric keys or symmetric EK using BST. -->
        <xsl:when test="$token-type = 'x509' and
                        not($use-encryptedkeysha1/node())"> 
          <xsl:variable name="cert">
            <xsl:choose>
              <xsl:when test="$dpconfig:use-dynamic-enccert = 'off'">
                <xsl:value-of select="concat('name:', $recipient)"/>
              </xsl:when>
              <xsl:when test="dp:variable('var://context/transaction/encrypting-cert') != ''">
                <xsl:value-of select="dp:variable('var://context/transaction/encrypting-cert')"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="concat('name:', $recipient)"/>
              </xsl:otherwise>
            </xsl:choose>                  
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="$dpconfig:token-reference-mechanism = 'Direct'">
              <wsse:Reference URI="{concat('#', $ref-id)}">
                <xsl:if test="($wssec-version = '1.0') or ($wssec-version = '1.1')">
                  <xsl:attribute name="ValueType">
                    <xsl:value-of select="$dpconfig:wss-x509-token-profile-1.0-binarysecuritytoken-reference-valuetype"/>
                  </xsl:attribute>
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
        </xsl:when>   <!-- x509 -->

        <!-- the default behavior, use the SCT is it is available. -->
        <xsl:when test="$dpconfig:include-sct-token = 'on' and
                        $symmetric-key-base = 'sct-available'">
          <wsse:Reference URI="{concat('#', $ref-id)}" ValueType="{$wssc-capability/wssc/sct}"/>
        </xsl:when>
        <xsl:when test="$dpconfig:include-sct-token = 'off' and
                        $symmetric-key-base = 'sct-available'">
          <wsse:Reference URI="{$available-sct-token//*[local-name()='Identifier']}" ValueType="{$wssc-capability/wssc/sct}"/>
        </xsl:when>

        <!-- derive a key from a named DKT. -->
        <xsl:when test="$symmetric-key-base = 'dkt'">
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
        <xsl:when test="$symmetric-key-base = 'encryptedkey'">
          <wsse:Reference URI="{concat('#', $ref-id)}" ValueType="http://docs.oasis-open.org/wss/oasis-wss-soap-message-security-1.1#EncryptedKey"/>
        </xsl:when>

        <!-- derive a key from Kerberos token. -->
        <xsl:when test="$symmetric-key-base = 'kerberos'">
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
        
        <!-- derive a key from SAML hok token. -->
        <xsl:when test="$symmetric-key-base = 'saml-symmetric-hok'">
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

        <!-- EncryptedKeySHA1 -->
        <xsl:when test="$use-encryptedkeysha1/node()">
          <xsl:attribute name="wsse11:TokenType">http://docs.oasis-open.org/wss/oasis-wss-soap-message-security-1.1#EncryptedKey</xsl:attribute>
          <wsse:KeyIdentifier ValueType="http://docs.oasis-open.org/wss/oasis-wss-soap-message-security-1.1#EncryptedKeySHA1" 
                              EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">
            <xsl:value-of select="$use-encryptedkeysha1/eksvalue"/>
          </wsse:KeyIdentifier>
        </xsl:when>

      </xsl:choose>
    </wsse:SecurityTokenReference>
  </xsl:template>

</xsl:stylesheet>
