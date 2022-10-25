<?xml version="1.0" encoding="utf-8"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007, 2020. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!-- Set RSA encryption parameters -->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpconfig="http://www.datapower.com/param/config"
    xmlns:dpfunc="http://www.datapower.com/extensions/functions"
    extension-element-prefixes="dp"
    exclude-result-prefixes="dp dpconfig dpfunc"
>
  <xsl:import href="store:///dp/xenc-library.xsl" dp:ignore-multiple="yes"/>

  <xsl:param name="dpconfig:algorithm"
             select="$URI-XENC-3DES-CBC"/>
  <dp:param name="dpconfig:algorithm"
            type="dmCryptoEncryptionAlgorithm" xmlns="">
    <display>Symmetric Encryption Algorithm</display>
    <displayId>store.set-rsa-encrypt-param.param.algorithm.display</displayId>
    <description>The symmetric encryption algorithm to use.</description>
    <descriptionId>store.set-rsa-encrypt-param.param.algorithm.description</descriptionId>
  </dp:param>

  <xsl:param name="dpconfig:key-transport-algorithm"
             select="$URI-XENC-KT-RSA-PKCS1"/>
  <dp:param name="dpconfig:key-transport-algorithm"
            type="dmCryptoKeyAsymmetricEncryptionAlgorithm" xmlns="">
    <display>Key Transport Algorithm</display>
    <displayId>store.set-rsa-encrypt-param.param.key-transport-algorithm.display</displayId>
    <description>The key transport algorithm to use for encrypting the
    symmetric key.</description>
    <descriptionId>store.set-rsa-encrypt-param.param.key-transport-algorithm.description</descriptionId>
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
            <value>sct-available</value>
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
            <value>sct-available</value>
          </condition>
          <condition evaluation="property-equals">
            <parameter-name>dpconfig:use-key-derivation</parameter-name>
            <value>off</value>
          </condition>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:oaep-params" select="''"/>
  <dp:param name="dpconfig:oaep-params" type="dmString" xmlns="">
    <display>OAEP Parameters</display>
    <displayId>store.set-rsa-encrypt-param.param.oaep-params.display</displayId>
    <description>A base64-encoded string containing the OAEP Parameters</description>
    <descriptionId>store.set-rsa-encrypt-param.param.oaep-params.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:key-transport-algorithm</parameter-name>
            <!--    no dynamic content allowed here                               -->
            <!--    <value><xsl:value-of select="$URI-XENC-KT-RSA-OAEP"/></value> -->
            <value>http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p</value>
          </condition>
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:key-transport-algorithm</parameter-name>
            <!--    no dynamic content allowed here                               -->
            <!--    <value><xsl:value-of select="$URI-XENC-KT-RSA-OAEP"/></value> -->
            <value>http://www.w3.org/2009/xmlenc11#rsa-oaep</value>
          </condition>
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

  <xsl:param name="dpconfig:oaep-digest-algorithm" select="'sha1'"/>
  <dp:param name="dpconfig:oaep-digest-algorithm"
            type="dmCryptoHashAlgorithm" xmlns="">
    <display>OAEP Digest Algorithm</display>
    <displayId>store.set-rsa-encrypt-param.param.oaep-digest-algorithm.display</displayId>
    <description>The message digest algorithm to use during OAEP padding</description>
    <descriptionId>store.set-rsa-encrypt-param.param.oaep-digest-algorithm.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="logical-and">
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:key-transport-algorithm</parameter-name>
            <!--    no dynamic content allowed here                               -->
            <!--    <value><xsl:value-of select="$URI-XENC-KT-RSA-OAEP"/></value> -->
            <value>http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p</value>
          </condition>
          <condition evaluation="property-does-not-equal">
            <parameter-name>dpconfig:key-transport-algorithm</parameter-name>
            <!--    no dynamic content allowed here                               -->
            <!--    <value><xsl:value-of select="$URI-XENC-KT-RSA-OAEP"/></value> -->
            <value>http://www.w3.org/2009/xmlenc11#rsa-oaep</value>
          </condition>
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

  <xsl:param name="dpconfig:oaep-mgf-algorithm"
             select="$URI-XENC11-MGF-SHA1"/>
  <dp:param name="dpconfig:oaep-mgf-algorithm"
            type="dmCryptoOAEPMGFAlgorithm" xmlns="">
    <display>OAEP MGF Algorithm</display>
    <displayId>store.set-rsa-encrypt-param.param.oaep-mgf-algorithm.display</displayId>
    <description>The MGF algorithm to use during OAEP padding</description>
    <descriptionId>store.set-rsa-encrypt-param.param.oaep-mgf-algorithm.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-or">
        <condition evaluation="property-does-not-equal">
          <parameter-name>dpconfig:key-transport-algorithm</parameter-name>
          <!--    no dynamic content allowed here                               -->
          <!--    <value><xsl:value-of select="$URI-XENC-KT-RSA-OAEP"/></value> -->
          <value>http://www.w3.org/2009/xmlenc11#rsa-oaep</value>
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

</xsl:stylesheet>
