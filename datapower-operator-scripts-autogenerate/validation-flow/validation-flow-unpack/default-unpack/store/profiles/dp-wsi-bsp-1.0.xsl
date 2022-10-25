<?xml version="1.0" encoding="utf-8"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2014. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!-- 
    This stylesheet implements the WSI Basic Security Profile 1.0
    configuration conformance verification.
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:dpfunc='http://www.datapower.com/extensions/functions'
                xmlns:dpe="http://www.datapower.com/extensions"
                exclude-result-prefixes="dpfunc dpe">

    <!-- output options -->
    <xsl:output method="xml" encoding="utf-8" indent="yes"/>

    <xsl:include href="webgui:///Utility.xsl"/>
    <xsl:import href="store:///dp/xenc-library.xsl"/>
    <xsl:include href="store:///dp/msgcat/crypto.xml.xsl" dpe:ignore-multiple="yes"/>
    <xsl:import href="webgui:///webmsgcat.xsl"/>

    <dpe:summary>
        <operation>conformance-checker</operation>
        <description>WS-I Basic Security Profile 1.0</description>
    </dpe:summary>

    <!-- this can be set from the CLI to see debug output. -->
    <xsl:variable name="debug" select="dpe:variable('var://system/soma/debug')"/>

    <xsl:template match="/">
        <xsl:if test="($debug &gt; 1)">
            <xsl:message dpe:id="{$DPLOG_CONFORMANCE_PROFILE_BSP10}"/>
        </xsl:if>

       <!-- The root element looks like:
              <input>
                <domain>domainName</domain>
                <configuration>
                  <StylePolicyAction>*
                  <AAAPolicy>*
                </configuration>
                <locale>locale<locale>
              </input>

             The <domain> element specifies the domain that we are in and is used for resolving domain-qualified transform stylesheet paths.
             The <configuration> element contains objects referenced by the target of the conformance check.
             We're (currently) only interested in analysing the StylePolicyAction, AAAPolicy, and CryptoProfile elements. 
             The <locale> element contains the language of details messages in the generated conformance report -->

        <ConformanceAnalysis>
          <xsl:variable name="config" select="'{http://www.datapower.com/param/config}'"/>
          <xsl:variable name="domain" select="input/domain"/>
          <xsl:variable name="configuration" select="input/configuration"/>
          <xsl:variable name="stylePolicyActions" select="$configuration/StylePolicyAction"/>
          <xsl:variable name="aaaPolicies" select="$configuration/AAAPolicy"/>
          <xsl:variable name="lang">
              <xsl:choose>
                  <xsl:when test="input/locale">
                      <xsl:value-of select="input/locale"/>
                  </xsl:when>
                  <xsl:otherwise>en</xsl:otherwise>
              </xsl:choose>
          </xsl:variable>

          <xsl:for-each select="$stylePolicyActions">

            <xsl:if test="Type='xform'">
              <!-- Determine if operation is potentially compliant by examining the dp:summary element of the associated stylesheet -->
              <!-- Message-level actions have a Transform property directly specifying the stylesheet. Field-level actions have a DynamicStylesheet
                   property associated with a DocumentCryptoMap, whose Operation property can be used to select the appropriate stylesheet. -->

              <xsl:variable name="dynamicStylesheet" select="DynamicStylesheet"/>

              <xsl:variable name="transformStylesheetPath">
                <xsl:choose>
                  <xsl:when test="$dynamicStylesheet != ''">
                    <!-- Find DocumentCryptoMap associated with the dynamicStylesheet (there can only be one) -->
                    <xsl:for-each select="$configuration/DocumentCryptoMap[@name=$dynamicStylesheet][1]">
                      <xsl:variable name="documentCryptoMapOperation" select="Operation"/>
                      <xsl:choose>
                        <xsl:when test="$documentCryptoMapOperation = 'sign-wssec'">
                          <xsl:value-of select="'store:///meta/sign-wssec.xsl'"/>
                        </xsl:when>
                        <xsl:when test="$documentCryptoMapOperation = 'encrypt-wssec'">
                          <xsl:value-of select="'store:///meta/encrypt-wssec.xsl'"/>
                        </xsl:when>
                        <xsl:when test="$documentCryptoMapOperation = 'encrypt'">
                          <xsl:value-of select="'store:///meta/encrypt.xsl'"/>
                        </xsl:when>
                        <xsl:when test="$documentCryptoMapOperation = 'decrypt'">
                          <xsl:value-of select="'store:///meta/decrypt.xsl'"/>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:for-each>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="Transform"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>

              <!-- retrieve stylesheet, taking domain into account -->
              <xsl:variable name="domainQualifiedStylesheetPath" select="dpfunc:convert-to-qualified-url($domain, $transformStylesheetPath)"/>
              <xsl:variable name="transformStylesheet" select="document($domainQualifiedStylesheetPath)"/>

              <xsl:choose>
                <xsl:when test="string($transformStylesheet)=''">
                  <Report type="Miscellaneous" severity="Fail">
                    <Location object-type="StylePolicyAction">
                      <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                    </Location>
                    <Details>                        
                        <xsl:variable name="params-details">
                            <param><xsl:value-of select="$domainQualifiedStylesheetPath"/></param>
                        </xsl:variable>
                        <xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.Miscellaneous.details',$params-details)"/>
                    </Details>
                  </Report>                      
                </xsl:when>
                <xsl:otherwise>
                  <xsl:variable name="summary" select="$transformStylesheet/xsl:stylesheet//dpe:summary"/>
                  
                  <!-- common settings for all WS-Security related sign actions, all the wssec related 
                       sign actions have defined a suboperation and non wssec related sign actions have no suboperation. -->
                  <xsl:if test="$summary/operation='sign' and $summary/suboperation != ''">
                    <xsl:variable
                         name="c14nalg"
                         select="StylesheetParameters[ParameterName=concat($config, 'c14nalg')]"/>
                    <xsl:if test="(string($c14nalg)!='')and($c14nalg/ParameterValue!='exc-c14n')">
                      <Report type="Conformance" severity="Fail" specification="BSP1.0" requirement="R5404">
                        <Location object-type="StylePolicyAction">
                          <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                        </Location>
                        <ParameterName><xsl:value-of select="concat($config, 'c14nalg')"/></ParameterName>
                        <PermittedSetting>exc-c14n</PermittedSetting>
                        <ActualSetting><xsl:value-of select="$c14nalg/ParameterValue"/></ActualSetting>
                        <Details>                        
                            <xsl:variable name="params-details">
                                <param><xsl:value-of select="$summary/suboperation"/></param>
                            </xsl:variable>
                            <xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.c14nalg.details',$params-details)"/>
                        </Details>                                               
                      </Report>
                    </xsl:if>

                    <xsl:variable
                         name="hashalg"
                         select="StylesheetParameters[ParameterName=concat($config, 'hashalg')]"/>
                    <xsl:if test="(string($hashalg)!='') and ($hashalg/ParameterValue!='sha1')">
                      <Report type="Conformance" severity="Warn" specification="BSP1.0" requirement="R5420">
                        <Location object-type="StylePolicyAction">
                          <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                        </Location>
                        <ParameterName><xsl:value-of select="concat($config, 'hashalg')"/></ParameterName>
                        <PermittedSetting>sha1</PermittedSetting>
                        <ActualSetting><xsl:value-of select="$hashalg/ParameterValue"/></ActualSetting>
                        <Details>                        
                            <xsl:variable name="params-details">
                                <param><xsl:value-of select="$summary/suboperation"/></param>
                            </xsl:variable>
                            <xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.hashalg.details',$params-details)"/>
                        </Details>
                      </Report>                      
                    </xsl:if>

                    <xsl:variable
                         name="wssec-compatibility"
                         select="StylesheetParameters[ParameterName=concat($config, 'wssec-compatibility')]"/>
                    <xsl:if test="(string($wssec-compatibility)!='') and ($wssec-compatibility/ParameterValue!='1.0') and ($wssec-compatibility/ParameterValue!='1.1')">
                      <Report type="Conformance" severity="Fail" specification="BSP1.0">
                        <Location object-type="StylePolicyAction">
                          <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                        </Location>
                        <ParameterName><xsl:value-of select="concat($config, 'wssec-compatibility')"/></ParameterName>
                        <PermittedSetting>1.0</PermittedSetting>
                        <PermittedSetting>1.1</PermittedSetting>
                        <ActualSetting><xsl:value-of select="$wssec-compatibility/ParameterValue"/></ActualSetting>
                        <Details>                        
                            <xsl:variable name="params-details">
                                <param><xsl:value-of select="$summary/suboperation"/></param>
                            </xsl:variable>
                            <xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.wssec-compatibility.details',$params-details)"/>
                        </Details>                        
                      </Report>                      
                    </xsl:if>

                    <xsl:variable
                         name="wssec-id-ref-type"
                         select="StylesheetParameters[ParameterName=concat($config, 'wssec-id-ref-type')]"/>
                    <xsl:if test="(string($wssec-id-ref-type)!='') and ($wssec-id-ref-type/ParameterValue!='wsu:Id')">
                      <Report type="Conformance" severity="Fail" specification="BSP1.0">
                        <Location object-type="StylePolicyAction">
                          <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                        </Location>
                        <ParameterName><xsl:value-of select="concat($config, 'wssec-id-ref-type')"/></ParameterName>
                        <PermittedSetting>wsu:Id</PermittedSetting>
                        <ActualSetting><xsl:value-of select="$wssec-id-ref-type/ParameterValue"/></ActualSetting>
                        <Details>                        
                            <xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.wssec-id-ref-type.details')"/>
                        </Details>
                      </Report>
                    </xsl:if>
                  </xsl:if>
                  
                  <!-- special settings for this sign action -->
                  <xsl:choose>

                    <xsl:when test="($summary/suboperation='HMAC-Kerberos-sign')">
                      <xsl:variable
                           name="sigalg"
                           select="StylesheetParameters[ParameterName=concat($config, 'sigalg')]"/>
                      <xsl:if test="(string($sigalg)!='') and ($sigalg/ParameterValue!='hmac-sha1')">
                        <Report type="Conformance" severity="Warn" specification="BSP1.0" requirement="R5421">
                          <Location object-type="StylePolicyAction">
                            <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                          </Location>
                          <ParameterName><xsl:value-of select="concat($config, 'sigalg')"/></ParameterName>
                          <PermittedSetting>hmac-sha1</PermittedSetting>
                          <ActualSetting><xsl:value-of select="$sigalg/ParameterValue"/></ActualSetting>
                          <Details>                        
                              <xsl:variable name="params-details">
                                  <param><xsl:value-of select="$summary/suboperation"/></param>
                              </xsl:variable>
                              <xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.sigalg.details',$params-details)"/>
                          </Details>                          
                        </Report>
                      </xsl:if>

                      <xsl:variable
                           name="bstvaluetype"
                           select="StylesheetParameters[ParameterName=concat($config, 'bstvaluetype')]"/>
                      <xsl:if test="(string($bstvaluetype)!='') and ($bstvaluetype/ParameterValue!='http://docs.oasis-open.org/wss/oasis-wss-kerberos-token-profile-1.1#GSS_Kerberosv5_AP_REQ')">
                        <Report type="Conformance" severity="Fail" specification="BSP1.0" requirement="R6902">
                          <Location object-type="StylePolicyAction">
                            <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                          </Location>
                          <ParameterName><xsl:value-of select="concat($config, 'bstvaluetype')"/></ParameterName>
                          <PermittedSetting>http://docs.oasis-open.org/wss/oasis-wss-kerberos-token-profile-1.1#GSS_Kerberosv5_AP_REQ</PermittedSetting>
                          <ActualSetting><xsl:value-of select="$bstvaluetype/ParameterValue"/></ActualSetting>
                          <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.bstvaluetype.details')"/></Details>                          
                        </Report>                      
                      </xsl:if>
                    </xsl:when>


                    <xsl:when test="($summary/suboperation='HMAC-sign')">
                      <Report type="Conformance" severity="Fail" specification="BSP1.0" requirement="R5417">
                        <Location object-type="StylePolicyAction">
                          <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                        </Location>
                        <ParameterName>transform</ParameterName>
                        <PermittedSetting>store:///sign-kerberos-hmac-wssec.xsl</PermittedSetting>
                        <ActualSetting><xsl:value-of select="Transform"/></ActualSetting>
                        <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.R5417.details')"/></Details>
                      </Report>

                      <xsl:variable
                           name="sigalg"
                           select="StylesheetParameters[ParameterName=concat($config, 'sigalg')]"/>
                      <xsl:if test="(string($sigalg)!='') and ($sigalg/ParameterValue!='hmac-sha1')">
                        <Report type="Conformance" severity="Warn" specification="BSP1.0" requirement="R5421">
                          <Location object-type="StylePolicyAction">
                            <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                          </Location>
                          <ParameterName><xsl:value-of select="concat($config, 'sigalg')"/></ParameterName>
                          <PermittedSetting>hmac-sha1</PermittedSetting>
                          <ActualSetting><xsl:value-of select="$sigalg/ParameterValue"/></ActualSetting>
                          <Details>                        
                              <xsl:variable name="params-details">
                                  <param><xsl:value-of select="$summary/suboperation"/></param>
                              </xsl:variable>
                              <xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.sigalg.details',$params-details)"/>
                          </Details>                          
                        </Report>
                      </xsl:if>

                      <xsl:variable
                           name="include-second-id"
                           select="StylesheetParameters[ParameterName=concat($config, 'include-second-id')]"/>
                      <xsl:if test="(string($include-second-id)!='') and ($include-second-id/ParameterValue!='off')">
                        <Report type="Conformance" severity="Fail" specification="BSP1.0">
                          <Location object-type="StylePolicyAction">
                            <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                          </Location>
                          <ParameterName><xsl:value-of select="concat($config, 'include-second-id')"/></ParameterName>
                          <PermittedSetting>off</PermittedSetting>
                          <ActualSetting><xsl:value-of select="$include-second-id/ParameterValue"/></ActualSetting>
                          <Details>                        
                              <xsl:variable name="params-details">
                                  <param><xsl:value-of select="$summary/suboperation"/></param>
                              </xsl:variable>
                              <xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.include-second-id.details',$params-details)"/>
                          </Details>                           
                        </Report>                      
                      </xsl:if>
                    </xsl:when>



                    <xsl:when test="($summary/suboperation='WSSEC-sign') or ($summary/suboperation='WSSEC-sign-field-level') or ($summary/suboperation='SwA-sign')">
                      <xsl:variable
                           name="sigalg"
                           select="StylesheetParameters[ParameterName=concat($config, 'sigalg')]"/>
                      <xsl:if test="(string($sigalg)!='') and ($sigalg/ParameterValue!='rsa') and ($sigalg/ParameterValue!='rsa-sha1')">
                        <Report type="Conformance" severity="Warn" specification="BSP1.0" requirement="R5421">
                          <Location object-type="StylePolicyAction">
                            <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                          </Location>
                          <ParameterName><xsl:value-of select="concat($config, 'sigalg')"/></ParameterName>
                          <PermittedSetting>rsa</PermittedSetting>
                          <PermittedSetting>rsa-sha1</PermittedSetting>
                          <ActualSetting><xsl:value-of select="$sigalg/ParameterValue"/></ActualSetting>
                          <Details>                        
                              <xsl:variable name="params-details">
                                  <param><xsl:value-of select="$summary/suboperation"/></param>
                              </xsl:variable>
                              <xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.sigalg.details',$params-details)"/>
                          </Details>                          
                        </Report>                      
                      </xsl:if>

                      <xsl:variable
                           name="include-inline-cert"
                           select="StylesheetParameters[ParameterName=concat($config, 'include-inline-cert')]"/>
                      <xsl:if test="(string($include-inline-cert)!='') and ($include-inline-cert/ParameterValue!='off')">
                        <Report type="Conformance" severity="Fail" specification="BSP1.0">
                          <Location object-type="StylePolicyAction">
                            <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                          </Location>
                          <ParameterName><xsl:value-of select="concat($config, 'include-inline-cert')"/></ParameterName>
                          <PermittedSetting>off</PermittedSetting>
                          <ActualSetting><xsl:value-of select="$include-inline-cert/ParameterValue"/></ActualSetting>
                          <Details>                        
                              <xsl:variable name="params-details">
                                  <param><xsl:value-of select="$summary/suboperation"/></param>
                              </xsl:variable>
                              <xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.include-inline-cert.details',$params-details)"/>
                          </Details>                          
                        </Report>                      
                      </xsl:if>

                      <xsl:variable
                           name="include-second-id"
                           select="StylesheetParameters[ParameterName=concat($config, 'include-second-id')]"/>
                      <xsl:if test="(string($include-second-id)!='') and ($include-second-id/ParameterValue!='off')">
                        <Report type="Conformance" severity="Fail" specification="BSP1.0">
                          <Location object-type="StylePolicyAction">
                            <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                          </Location>
                          <ParameterName><xsl:value-of select="concat($config, 'include-second-id')"/></ParameterName>
                          <PermittedSetting>off</PermittedSetting>
                          <ActualSetting><xsl:value-of select="$include-second-id/ParameterValue"/></ActualSetting>
                          <Details>                        
                              <xsl:variable name="params-details">
                                  <param><xsl:value-of select="$summary/suboperation"/></param>
                              </xsl:variable>
                              <xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.include-second-id.details',$params-details)"/>
                          </Details>                          
                        </Report>                      
                      </xsl:if>

                      <xsl:variable
                           name="include-signatureconfirmation"
                           select="StylesheetParameters[ParameterName=concat($config, 'include-signatureconfirmation')]"/>
                      <xsl:if test="(string($include-signatureconfirmation)!='') and ($include-signatureconfirmation/ParameterValue!='off')">
                        <Report type="Conformance" severity="Fail" specification="BSP1.0">
                          <Location object-type="StylePolicyAction">
                            <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                          </Location>
                          <ParameterName><xsl:value-of select="concat($config, 'include-signatureconfirmation')"/></ParameterName>
                          <PermittedSetting>off</PermittedSetting>
                          <ActualSetting><xsl:value-of select="$include-signatureconfirmation/ParameterValue"/></ActualSetting>
                          <Details>                        
                              <xsl:variable name="params-details">
                                  <param><xsl:value-of select="$summary/suboperation"/></param>
                              </xsl:variable>
                              <xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.include-signatureconfirmation.details',$params-details)"/>
                          </Details>                          
                        </Report>                      
                      </xsl:if>

                      <xsl:variable 
                           name="X509SKI"
                           select="'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509SubjectKeyIdentifier'"/>
                      <xsl:variable
                           name="keyIdentifier-ValueType"
                           select="StylesheetParameters[ParameterName=concat($config, 'wss-x509-token-profile-1.0-keyidentifier-valuetype')]"/>
                      <xsl:variable
                           name="token-reference-mechanism"
                           select="StylesheetParameters[ParameterName=concat($config, 'token-reference-mechanism')]"/>
                      <xsl:choose>
 
                        <xsl:when test="(string($token-reference-mechanism/ParameterValue)='') or 
                                        ($token-reference-mechanism/ParameterValue='Direct')">
                          <!-- This is the normal success case -->
                        </xsl:when>

                        <xsl:when test="$token-reference-mechanism/ParameterValue='X509IssuerSerial'">
                          <!-- Issuer/serial is allowed too... -->
                        </xsl:when>

                        <xsl:when test="$token-reference-mechanism/ParameterValue='KeyIdentifier'">

                          <xsl:if test="$keyIdentifier-ValueType/ParameterValue!=$X509SKI">
                            <Report type="Conformance" severity="Fail" specification="BSP1.0" requirement="R5206">
                              <Location object-type="StylePolicyAction">
                                <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                              </Location>
                              <ParameterName><xsl:value-of select="concat($config, 'wss-x509-token-profile-1.0-keyidentifier-valuetype')"/></ParameterName>
                              <PermittedSetting><xsl:value-of select="$X509SKI"/></PermittedSetting>
                              <ActualSetting><xsl:value-of select="$keyIdentifier-ValueType/ParameterValue"/></ActualSetting>
                              <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.R5206.details')"/></Details>
                            </Report>
                          </xsl:if>

                        </xsl:when>

                        <xsl:otherwise>
                          <Report type="Conformance" severity="Fail" specification="BSP1.0">
                            <Location object-type="StylePolicyAction">
                              <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                            </Location>
                            <ParameterName><xsl:value-of select="concat($config, 'token-reference-mechanism')"/></ParameterName>
                            <PermittedSetting>Direct</PermittedSetting>
                            <PermittedSetting>KeyIdentifier</PermittedSetting>
                            <PermittedSetting>X509IssuerSerial</PermittedSetting>
                            <ActualSetting><xsl:value-of select="$token-reference-mechanism/ParameterValue"/></ActualSetting>
                            <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.R5206-2.details')"/></Details>
                          </Report>
                        </xsl:otherwise>
                      </xsl:choose>

                      <xsl:variable
                           name="x509TokenType"
                           select="StylesheetParameters[ParameterName=concat($config, 'wss-x509-token-type')]"/>
                      <xsl:variable
                           name="x509ValueType"
                           select="StylesheetParameters[ParameterName=concat($config, 'wss-x509-token-profile-1.0-binarysecuritytoken-reference-valuetype')]"/>
                      <xsl:choose>
                        <xsl:when test="$x509TokenType/ParameterValue='PKCS7'">

                        </xsl:when>
                        <xsl:when test="$x509TokenType/ParameterValue='PKIPath'">

                        </xsl:when>
                        <xsl:otherwise>
<!-- X509 certificate token-type -->
                          <xsl:if test="(string($x509ValueType)!='') and
                                        (string($x509ValueType/ParameterValue)!='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3')">
                            <Report type="Conformance" severity="Fail" specification="BSP1.0" requirement="R3033">
                              <Location object-type="StylePolicyAction">
                                <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                              </Location>
                              <ParameterName><xsl:value-of select="concat($config, 'wss-x509-token-profile-1.0-binarysecuritytoken-reference-valuetype')"/></ParameterName>
                              <PermittedSetting>http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3</PermittedSetting>
                              <ActualSetting><xsl:value-of select="$x509ValueType/ParameterValue"/></ActualSetting>
                              <Details>                        
                                  <xsl:variable name="params-details">
                                      <param><xsl:value-of select="$summary/suboperation"/></param>
                                  </xsl:variable>
                                  <xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.R3033.details',$params-details)"/>
                              </Details> 
                            </Report>
                          </xsl:if>
                        </xsl:otherwise>
                      </xsl:choose>
                      
                    </xsl:when>



                    <xsl:when test="($summary/suboperation='WSSEC-encrypt') or ($summary/suboperation='WSSEC-encrypt-field-level')">
                      <xsl:variable
                           name="wssec-id-ref-type"
                           select="StylesheetParameters[ParameterName=concat($config, 'wssec-id-ref-type')]"/>
                      <xsl:if test="(string($wssec-id-ref-type)!='') and ($wssec-id-ref-type/ParameterValue!='wsu:Id')">
                        <Report type="Conformance" severity="Fail" specification="BSP1.0">
                          <Location object-type="StylePolicyAction">
                            <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                          </Location>
                          <ParameterName><xsl:value-of select="concat($config, 'wssec-id-ref-type')"/></ParameterName>
                          <PermittedSetting>wsu:Id</PermittedSetting>
                          <ActualSetting><xsl:value-of select="$wssec-id-ref-type/ParameterValue"/></ActualSetting>
                          <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.wssec-id-ref-type.details')"/></Details> 
                        </Report>
                      </xsl:if>

                      <xsl:variable
                           name="wssec-compatibility"
                           select="StylesheetParameters[ParameterName=concat($config, 'wssec-compatibility')]"/>
                      <xsl:if test="(string($wssec-compatibility)!='') and ($wssec-compatibility/ParameterValue!='1.0') and ($wssec-compatibility/ParameterValue!='1.1')">
                        <Report type="Conformance" severity="Fail" specification="BSP1.0">
                          <Location object-type="StylePolicyAction">
                            <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                          </Location>
                          <ParameterName><xsl:value-of select="concat($config, 'wssec-compatibility')"/></ParameterName>
                          <PermittedSetting>1.0</PermittedSetting>
                          <PermittedSetting>1.1</PermittedSetting>
                          <ActualSetting><xsl:value-of select="$wssec-compatibility/ParameterValue"/></ActualSetting>
                          <Details>                        
                              <xsl:variable name="params-details">
                                  <param><xsl:value-of select="$summary/suboperation"/></param>
                              </xsl:variable>
                              <xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.wssec-compatibility.details',$params-details)"/>
                          </Details>                          
                        </Report>                      
                      </xsl:if>


                      <xsl:variable
                           name="token-reference-mechanism"
                           select="StylesheetParameters[ParameterName=concat($config, 'token-reference-mechanism')]"/>
                      <xsl:variable
                           name="keyIdentifier-ValueType"
                           select="StylesheetParameters[ParameterName=concat($config, 'wss-x509-token-profile-1.0-keyidentifier-valuetype')]"/>
                      <xsl:choose>
                        <xsl:when test="(string($token-reference-mechanism/ParameterValue)='') or
                                        ($token-reference-mechanism/ParameterValue='Direct')">
                          <!-- This is the common successs case -->
                        </xsl:when>
                        <xsl:when test="$token-reference-mechanism/ParameterValue='X509IssuerSerial'">
                        </xsl:when>

                        <xsl:when test="$token-reference-mechanism/ParameterValue='KeyIdentifier'">
                          <xsl:if test="$keyIdentifier-ValueType/ParameterValue!='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509SubjectKeyIdentifier'">
                            <Report type="Conformance" severity="Fail" specification="BSP1.0" requirement="R5206">
                              <Location object-type="StylePolicyAction">
                                <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                              </Location>
                              <ParameterName><xsl:value-of select="concat($config, 'wss-x509-token-profile-1.0-keyidentifier-valuetype')"/></ParameterName>
                              <PermittedSetting>http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509SubjectKeyIdentifier</PermittedSetting>
                              <ActualSetting><xsl:value-of select="$keyIdentifier-ValueType/ParameterValue"/></ActualSetting>
                              <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.R5206.details')"/></Details>
                            </Report>
                          </xsl:if>
                        </xsl:when>

                        <xsl:otherwise>
                          <Report type="Conformance" severity="Fail" specification="BSP1.0">
                            <Location object-type="StylePolicyAction">
                              <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                            </Location>
                            <ParameterName><xsl:value-of select="concat($config, 'token-reference-mechanism')"/></ParameterName>
                            <PermittedSetting>Direct</PermittedSetting>
                            <PermittedSetting>KeyIdentifier</PermittedSetting>
                            <PermittedSetting>X509IssuerSerial</PermittedSetting>
                            <ActualSetting><xsl:value-of select="$token-reference-mechanism/ParameterValue"/></ActualSetting>
                            <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.R5206-2.details')"/></Details>
                          </Report>
                        </xsl:otherwise>
                      </xsl:choose>

                      <xsl:variable
                           name="algorithm" 
                           select="StylesheetParameters[ParameterName=concat($config, 'algorithm')]"/>
                      <xsl:if test="(string($algorithm)!='') 
                                     and ($algorithm/ParameterValue != $URI-XENC-3DES-CBC)
                                     and ($algorithm/ParameterValue != $URI-XENC-AES128-CBC)
                                     and ($algorithm/ParameterValue != $URI-XENC-AES256-CBC)">
                        <Report type="Conformance" severity="Fail" specification="BSP1.0" requirement="R5620">
                          <Location object-type="StylePolicyAction">
                            <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                          </Location>
                          <ParameterName><xsl:value-of select="concat($config, 'sigalg')"/></ParameterName>
                          <PermittedSetting><xsl:value-of select="$URI-XENC-3DES-CBC"/></PermittedSetting>
                          <PermittedSetting><xsl:value-of select="$URI-XENC-AES128-CBC"/></PermittedSetting>
                          <PermittedSetting><xsl:value-of select="$URI-XENC-AES256-CBC"/></PermittedSetting>
                          <ActualSetting><xsl:value-of select="$algorithm/ParameterValue"/></ActualSetting>
                          <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.algorithm.details')"/></Details>
                        </Report>                      
                      </xsl:if>

                      <xsl:variable
                           name="x509ValueType"
                           select="StylesheetParameters[ParameterName=concat($config, 'wss-x509-token-profile-1.0-binarysecuritytoken-reference-valuetype')]"/>
                      <xsl:variable
                           name="x509TokenType"
                           select="StylesheetParameters[ParameterName=concat($config, 'wss-x509-token-type')]"/>
                      <xsl:choose>
                        <xsl:when test="$x509TokenType/ParameterValue='PKCS7'">
                        </xsl:when>
                        <xsl:when test="$x509TokenType/ParameterValue='PKIPath'">
                        </xsl:when>
                        <xsl:otherwise>
                          <!-- X509 certificate token-type -->
                          <xsl:if test="(string($x509ValueType)!='') and
                                        (string($x509ValueType/ParameterValue)!='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3')">
                            <Report type="Conformance" severity="Fail" specification="BSP1.0" requirement="R3033">
                              <Location object-type="StylePolicyAction">
                                <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                              </Location>
                              <ParameterName><xsl:value-of select="concat($config, 'wss-x509-token-profile-1.0-binarysecuritytoken-reference-valuetype')"/></ParameterName>
                              <PermittedSetting>http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3</PermittedSetting>
                              <ActualSetting><xsl:value-of select="$x509ValueType/ParameterValue"/></ActualSetting>
                              <Details>                        
                                  <xsl:variable name="params-details">
                                      <param><xsl:value-of select="$summary/suboperation"/></param>
                                  </xsl:variable>
                                  <xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.R3033.details',$params-details)"/>
                              </Details>
                            </Report>
                          </xsl:if>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:when>


                    <xsl:when test="$summary/operation='decrypt'">
                      <!-- decrypt is assumed to be conformant -->
                    </xsl:when>


                    <xsl:otherwise>
                      <Report type="Conformance" severity="Warn" specification="BSP1.0">
                        <Location object-type="StylePolicyAction">
                           <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                        </Location>
                        <Details>
                            <xsl:variable name="params-details">
                                <param><xsl:value-of select="@name"/></param>
                                <param>
                                  <xsl:choose>
                                      <xsl:when test="$summary/suboperation!=''">
                                          (<xsl:value-of select="$summary/suboperation"/>)
                                      </xsl:when>
                                      <xsl:when test="$summary/operation!=''">
                                          (<xsl:value-of select="$summary/operation"/>)
                                      </xsl:when>
                                      <xsl:otherwise>                                          
                                      </xsl:otherwise>
                                  </xsl:choose>
                                </param>
                            </xsl:variable>
                            <xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.other-non-conformant.details',$params-details)"/>                            
                         </Details>
                      </Report>
                    </xsl:otherwise>

                  </xsl:choose>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:if>

          </xsl:for-each>

          <xsl:for-each select="$aaaPolicies">

            <!-- AAA policy conformance is limited to the PP stage -->
            <xsl:variable name="PPConfig" select="PostProcess"/>

            <xsl:if test="$PPConfig/PPEnabled='on'">
              <Report type="Conformance" severity="Warn" specification="BSP1.0">
                <Location object-type="AAAPolicy">
                   <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                </Location>
                <ParameterName>PPEnabled</ParameterName>
                <PermittedSetting>off</PermittedSetting>
                <ActualSetting><xsl:value-of select="$PPConfig/PPEnabled"/></ActualSetting>
                <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.PPEnabled.details')"/></Details> 
              </Report>
            </xsl:if>


            <xsl:if test="$PPConfig/PPSAMLAuthAssertion='on'">
              <xsl:if test="$PPConfig/PPSAMLVersion!='1.1'">
                <Report type="Conformance" severity="Fail" specification="BSP1.0">
                  <Location object-type="AAAPolicy">
                    <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                  </Location>
                  <ParameterName>PPSAMLVersion</ParameterName>
                  <PermittedSetting>1.1</PermittedSetting>
                  <ActualSetting><xsl:value-of select="$PPConfig/PPSAMLVersion"/></ActualSetting>
                  <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.PPSAMLVersion.details')"/></Details>
                </Report>
              </xsl:if>

              <xsl:if test="$PPConfig/PPSAMLUseWSSec!='on'">
                <Report type="Conformance" severity="Fail" specification="BSP1.0">
                  <Location object-type="AAAPolicy">
                    <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                  </Location>
                  <ParameterName>PPSAMLUseWSSec</ParameterName>
                  <PermittedSetting>on</PermittedSetting>
                  <ActualSetting><xsl:value-of select="$PPConfig/PPSAMLUseWSSec"/></ActualSetting>
                  <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.PPSAMLUseWSSec.details')"/></Details>
                </Report>
              </xsl:if>

            </xsl:if>

            <xsl:if test="$PPConfig/PPKerberosTicket='on'">
              <xsl:variable name="krb-bst-type"
                            select="'http://docs.oasis-open.org/wss/oasis-wss-kerberos-token-profile-1.1#GSS_Kerberosv5_AP_REQ'"/>
              <xsl:if test="$PPConfig/PPKerberosBstValueType!=$krb-bst-type">
                <Report type="Conformance" severity="Fail" specification="BSP1.0" requirement="R6902">
                  <Location object-type="AAAPolicy">
                    <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                  </Location>
                  <ParameterName>PPKerberosBstValueType</ParameterName>
                  <PermittedSetting><xsl:value-of select="$krb-bst-type"/></PermittedSetting>
                  <ActualSetting><xsl:value-of select="$PPConfig/PPKerberosBstValueType"/></ActualSetting>
                  <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.PPKerberosBstValueType.details')"/></Details>
                </Report>
              </xsl:if>

              <xsl:if test="$PPConfig/PPKerberosSPNEGOToken!='off'">
                <Report type="Conformance" severity="Fail" specification="BSP1.0">
                  <Location object-type="AAAPolicy">
                    <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                  </Location>
                  <ParameterName>PPKerberosSPNEGOToken</ParameterName>
                  <PermittedSetting>off</PermittedSetting>
                  <ActualSetting><xsl:value-of select="$PPConfig/PPKerberosSPNEGOToken"/></ActualSetting>
                  <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.PPKerberosSPNEGOToken.details')"/></Details>
                </Report>
              </xsl:if>
            </xsl:if>

            <xsl:if test="$PPConfig/PPWSUsernameToken">
              <xsl:if test="$PPConfig/PPWSUsernameTokenIncludePwd!='on'">
                <Report type="Conformance" severity="Fail" specification="BSP1.0">
                  <Location object-type="AAAPolicy">
                    <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                  </Location>
                  <ParameterName>PPWSUsernameTokenIncludePwd</ParameterName>
                  <PermittedSetting>on</PermittedSetting>
                  <ActualSetting><xsl:value-of select="$PPConfig/PPWSUsernameTokenIncludePwd"/></ActualSetting>
                  <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.PPWSUsernameTokenIncludePwd.details')"/></Details>
                </Report>
              </xsl:if>

            </xsl:if>

          </xsl:for-each>

          <xsl:for-each select="$configuration/CryptoProfile">

            <!-- CryptoProfile configuration should not use SSLv2 -->
            <xsl:if test="SSLOptions/Disable-SSLv2='off'">
              <Report type="Conformance" severity="Fail" specification="BSP1.0">
                <Location object-type="CryptoProfile">
                   <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
                </Location>
                <ParameterName>SSLOptions/Disable-SSLv2</ParameterName>
                <PermittedSetting>on</PermittedSetting>
                <ActualSetting><xsl:value-of select="SSLOptions/Disable-SSLv2"/></ActualSetting>
                <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bsp-1.0.Disable-SSLv2.details')"/></Details> 
              </Report>
            </xsl:if>
          </xsl:for-each>
        </ConformanceAnalysis>
    </xsl:template>


</xsl:stylesheet>
