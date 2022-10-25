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
     xmlns:dyn="http://exslt.org/dynamic"
     xmlns:func="http://exslt.org/functions"
     xmlns:S11="http://schemas.xmlsoap.org/soap/envelope/"
     xmlns:S12="http://www.w3.org/2003/05/soap-envelope"
     extension-element-prefixes="dp"
     exclude-result-prefixes="dp dpconfig dpfunc dyn func S11 S12"
>

  <xsl:include href="store:///wssec-utilities.xsl" dp:ignore-multiple="yes"/>
  <xsl:include href="store:///dp/msgcat/crypto.xml.xsl" dp:ignore-multiple="yes"/>

  <dp:summary xmlns="">
      <operation>xform</operation>
      <suboperation>soap-header-refine</suboperation>
      <description>SOAP Header and Children Elements Transformation</description>
      <descriptionId>store.soap-refine.dpsummary.description</descriptionId>
  </dp:summary>

  <xsl:param name="dpconfig:enforce-one-actor" select="'on'"/>
  <dp:param name="dpconfig:enforce-one-actor" type="dmToggle" xmlns="">
    <display>Enforce One SOAP Actor/Role</display>
    <displayId>store.soap-refine.param.enforce-one-actor.display</displayId>
    <description>
    Setting to 'off' causes this transformation to ignore the S11:actor 
    or S12:role attributes, effectively this action works as any SOAP 
    actor. Otherwise, provide the specific SOAP actor/role ID.
    </description>
    <descriptionId>store.soap-refine.param.enforce-one-actor.description</descriptionId>
    <default>on</default>
  </dp:param>

  <xsl:param name="dpconfig:actor-role-id" select="/.."/>
  <dp:param name="dpconfig:actor-role-id" type="dmString" xmlns="">
    <display>SOAP Actor/Role Identifier</display>
    <displayId>store.soap-refine.param.actor-role-id.display</displayId>
    <summary>Specify the SOAP Actor/Role Identifier for the SOAP header</summary>
    <description markup="html">
        Specify the identifier of the SOAP 1.1 actor or SOAP 1.2 role that
        this action work as in processing a SOAP header.  Some well-known values are:
     <table border="1">
        <tr>
            <td valign="left">http://schemas.xmlsoap.org/soap/actor/next</td>
            <td>Every one, including the intermediary and ultimate receiver, receives the message should be able to processing the SOAP header.</td>
        </tr>
        <tr>
            <td valign="left">http://www.w3.org/2003/05/soap-envelope/role/none</td>
            <td>No one should process the SOAP Header.</td>
        </tr>
        <tr>
            <td valign="left">http://www.w3.org/2003/05/soap-envelope/role/next</td>
            <td>Every one, including the intermediary and ultimate receiver, receives the message should be able to processing the SOAP header.</td>
        </tr>
        <tr>
            <td valign="left">http://www.w3.org/2003/05/soap-envelope/role/ultimateReceiver</td>
            <td>The message ultimate receiver can process the SOAP header. This is the default value if such setting is not configured.</td>
        </tr>
        <tr>
            <td valign="left">&lt;blank or empty string&gt;</td>
            <td>The empty string "" (without quotes) indicates that no "actor/role" identifier is configured.
                if there is no actor/role setting configured, the ultimateReceiver is assumed when processing the message.
            </td>
        </tr>
        <tr>
            <td valign="left">USE_MESSAGE_BASE_URI</td>
            <td>The value "USE_MESSAGE_BASE_URI" without quotes indicates that the actor/role identifier
                will be the base url of the message, if the SOAP message is transported using HTTP,
                the base URI is the Request-URI of the http request.</td>
        </tr>
        <tr>
            <td valign="left">any other customized string</td>
            <td>You can input any string to identify the SOAP header's actor or role.</td>
        </tr>
      </table>
    </description>
    <descriptionId>store.soap-refine.param.actor-role-id.description</descriptionId>
    <ignored-when>
      <condition evaluation="property-equals">
        <parameter-name>dpconfig:enforce-one-actor</parameter-name>
        <value>off</value>
      </condition>
    </ignored-when>
    <default></default>
  </dp:param>

  <xsl:param name="dpconfig:service" select="'ultimate'"/>
  <dp:param name="dpconfig:service" type="dmSOAPServiceType" xmlns="">
    <display>SOAP Service Type</display>
    <displayId>store.soap-refine.param.service.display</displayId>
    <summary>Is it working as a intermediary or ultimate service provider</summary>
    <description markup="html">
    SOAP Specification defines different SOAP header processing rules for different
    type of SOAP nodes or services, those processing rules are also different
    whether the SOAP header are successfully consumed by the prior actions or not.
      <p>The following are the detail processing rules
        <ul>
          <li>
          Remove the SOAP headers, if their
          S11:actor or S12:role attributes are "next".
          </li>
          <li>
          Keep the SOAP headers, if their
          S11:actor or S12:role attributes are "none".
          </li>
          <li>
          A SOAP Fault will be issued for all
          unprocessed headers if it has S11:mustUnderstand or
          S12:mustUnderstand attribute effectively 'true'. If the message
          is SOAP 1.2, additional S12:notUnderstood headers will be issued with
          the SOAP fault.
          </li>
          <li>
          The processed SOAP headers will always be removed from the message
          for the ultimate service provider.
          </li>
          <li>
          The unprocessed SOAP headers will still be removed from the message
          for the ultimate service provider.
          </li>
          <li>
          The processed SOAP headers will be removed for the intermediary
          unless its S12:relay attribute is effectively true.
          </li>
          <li>
          The unprocessed SOAP headers will be kept for the "intermediary".
          </li>
        </ul>
      </p>
    </description>
    <descriptionId>store.soap-refine.param.service.description</descriptionId>
    <ignored-when>
      <condition evaluation="logical-and">
        <condition evaluation="property-equals">
          <parameter-name>dpconfig:enforce-one-actor</parameter-name>
          <value>on</value>
        </condition>
        <condition evaluation="property-value-in-list">
          <parameter-name>dpconfig:actor-role-id</parameter-name>
          <value>http://www.w3.org/2003/05/soap-envelope/role/ultimateReceiver</value>
          <value></value>
        </condition>
      </condition>
    </ignored-when>
  </dp:param>

  <xsl:param name="dpconfig:delete-safe" select="'on'"/>
  <dp:param name="dpconfig:delete-safe" type="dmToggle" xmlns="">
    <display>Detect ID References while Deleting</display>
    <displayId>store.soap-refine.param.delete-safe.display</displayId>
    <description>
    If it is "ON", a SOAP header can be deleted only if no others 
    XML elements being kept are referencing to this header or 
    its direct children elements, 
    We only detect local ID reference mechanism using "#ID".
    This setting doesn't impact on the element to be specifically
    instructed to "remove" by the Disposition Table.

    This setting is also used to protect xenc:EncryptedKey when it
    references to EncryptedData or EncryptedHeader which will be kept,
    although there are no @URI pointing to that xenc:EncryptedKey.
    </description>
    <descriptionId>store.soap-refine.param.delete-safe.description</descriptionId>
    <default>on</default>
  </dp:param>

  <xsl:param name="dpconfig:disposition" select="''"/>
  <dp:param name="dpconfig:disposition" type="dmReference" reftype="SOAPHeaderDisposition" xmlns="">
    <display>SOAP Header Disposition Table</display>
    <displayId>store.soap-refine.param.disposition.display</displayId>
    <description>The list of instructions provided by customers to control how
    the SOAP headers and/or children elements are handled.
    </description>
    <descriptionId>store.soap-refine.param.disposition.description</descriptionId>
  </dp:param>

  <xsl:variable name="___soapnsuri___">
    <xsl:choose>
      <xsl:when test="/*[local-name()='Envelope']">
        <xsl:value-of select="namespace-uri(/*[local-name()='Envelope'])"/>
      </xsl:when>
      <xsl:otherwise>http://schemas.xmlsoap.org/soap/envelope/</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="resolved-actor-role-id" select="dpfunc:get-actor-role-value($dpconfig:actor-role-id, '1')"/>

  <xsl:variable name="disposition-table">
    <xsl:choose>
      <xsl:when test="$dpconfig:disposition = ''">
        <xsl:message dp:priority="info" dp:id="{$DPLOG_SOAP_HEADER_REFINE_NO_INSTRUCT}"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="serialized" select="dp:get-soap-disposition($dpconfig:disposition)"/>

        <xsl:choose>
          <xsl:when test="$serialized ='' or starts-with($serialized, '*')">
            <xsl:message dp:priority="error" dp:id="{$DPLOG_SOAP_HEADER_REFINE_BAD_DISPOSITION}">
              <dp:with-param value="{$dpconfig:disposition}"/>
              <dp:with-param value="{$serialized}"/>
            </xsl:message>
          </xsl:when>

          <xsl:otherwise>
            <xsl:copy-of select="dp:parse($serialized)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- the system disposition table is provided by a system object. -->
  <xsl:variable name="system">
    <xsl:variable name="serialized" select="dp:get-soap-disposition('system-default')"/>
    <xsl:choose>
      <xsl:when test="$serialized ='' or starts-with($serialized, '*')">
        <xsl:message dp:priority="error" dp:id="{$DPLOG_SOAP_HEADER_REFINE_NO_SYS_DISPOSITION}">
          <dp:with-param value="{$serialized}"/>
        </xsl:message>
      </xsl:when>

      <xsl:otherwise>
        <xsl:copy-of select="dp:parse($serialized)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <func:function name="dpfunc:is-true">
    <xsl:param name="attr"/>
    <func:result select="$attr='true' or $attr='1'"/>
  </func:function>

  <!-- believe me, this is very slow. -->
  <func:function name="dpfunc:being-referenced">
    <xsl:param name="node" select="/.."/>

    <xsl:for-each select="$node/@*[translate(local-name(), 'ID', 'id')='id']">
      <xsl:variable name="local-ref" select="concat('#', .)"/>
      <!-- for each URI referencing to this node. 
           return true if that referrer is to keep. -->
      <xsl:for-each select="//*[@URI=$local-ref]">
        <xsl:variable name="referrer-uid" select="generate-id()"/>

        <xsl:if test="$charter//disposition[@id=$referrer-uid]/@action = 'keep'">
          <func:result select="true()"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:for-each>

    <!-- no found, return false. -->
    <func:result select="false()"/>
  </func:function>

  <func:function name="dpfunc:referencing-others">
    <xsl:param name="node" select="/.."/>

    <xsl:for-each select="$node//@URI">

      <xsl:variable name="local-ref" select="substring-after(., '#')"/>

      <!-- for each URI referencing to this node. 
           return true if that referrer is to keep. -->
      <xsl:for-each select="//@*[translate(local-name(), 'ID', 'id')='id' and .=$local-ref]/..">
        <xsl:variable name="referrer-uid" select="generate-id()"/>

        <xsl:if test="$charter//disposition[@id=$referrer-uid]/@action = 'keep'">
          <func:result select="true()"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:for-each>

    <!-- no found, return false. -->
    <func:result select="false()"/>
  </func:function>
  <xsl:variable name="charter">
    <xsl:apply-templates mode="preprocess"/>
  </xsl:variable>

  <xsl:template mode="preprocess" match="node()" priority="-2">
    <xsl:param name="action" select="'keep'"/>

    <!-- apply the same the disposition for all the descendant. -->
    <xsl:element name="disposition">
      <xsl:attribute name="name"><xsl:value-of select="name()"/></xsl:attribute>
      <xsl:attribute name="id"><xsl:value-of select="generate-id()"/></xsl:attribute>
      <xsl:attribute name="action"><xsl:value-of select="$action"/></xsl:attribute>

      <xsl:apply-templates mode="preprocess" select="node()">
        <xsl:with-param name="action" select="$action"/>
      </xsl:apply-templates>
    </xsl:element>
  </xsl:template>

  <!-- SOAP header element -->
  <xsl:template mode="preprocess" match="/*[local-name()='Envelope']/*[local-name()='Header']">
    <!-- apply the same the disposition for all the descendant. -->
    <xsl:element name="disposition">
      <xsl:attribute name="name"><xsl:value-of select="name()"/></xsl:attribute>
      <xsl:attribute name="id"><xsl:value-of select="generate-id()"/></xsl:attribute>
      <xsl:attribute name="action"><xsl:value-of select="'remove'"/></xsl:attribute>

      <xsl:apply-templates mode="preprocess"/>
    </xsl:element>
  </xsl:template>

  <!-- All the SOAP headers -->
  <xsl:template mode="preprocess" match="/*[local-name()='Envelope']/*[local-name()='Header']/node() |
                                         /*[local-name()='Envelope']/*[local-name()='Header']/@*">

    <xsl:variable name="header" select="."/>

    <xsl:variable name="header-nsuri" select="namespace-uri()"/>
    <xsl:variable name="header-local-name" select="local-name()"/>

    <xsl:variable name="irrelevant-actor">
      <xsl:if test="$dpconfig:enforce-one-actor = 'on' and 
                     not(dpfunc:match-actor-role(., $resolved-actor-role-id))">
        <xsl:message dp:priority="info" dp:id="{$DPLOG_SOAP_HEADER_REFINE_MISMATCH_ACTOR}">
          <dp:with-param value="{name()}"/>
        </xsl:message>
        <xsl:value-of select="true()"/>
      </xsl:if>
    </xsl:variable>

    <!-- The internal action to take for each node:
          - remove
          - keep
          - wsse:InvalidSecurity
          - env:MustUnderstand
          - dp:Unsupported
      -->
    <xsl:variable name="header-action">
      <xsl:variable name="security-count">
        <xsl:variable name="my-actor-role" select="dpfunc:get-actor-role-value((@S11:actor | @S12:role)[1])"/>
        <xsl:if test="local-name()='Security'">
          <!-- only do it for ws-sec Security headers, we do not test the namespaces, hope it is not a big problem. -->
          <xsl:value-of select="count(/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='Security'][
                                          $my-actor-role = dpfunc:get-actor-role-value((@S11:actor | @S12:role)[1])])"/>
        </xsl:if>
      </xsl:variable>

      <xsl:choose>
        <!-- generate a wsse:InvalidSecurity fault: more than one. -->
        <xsl:when test="$security-count &gt; 1">
          <xsl:message dp:priority="error" dp:id="{$DPLOG_SOAP_HEADER_REFINE_MULTIPLE_WSSEC}">
            <dp:with-param value="{(@S11:actor | @S12:role)[1]}"/>
            <dp:with-param value="{name()}"/>
          </xsl:message>
          <xsl:value-of select="'wsse:InvalidSecurity'"/>
        </xsl:when>

        <!-- If this header should not be processed by this actor/role, copy and return.-->
        <xsl:when test="$irrelevant-actor = 'true'">
          <xsl:message dp:priority="info" dp:id="{$DPLOG_SOAP_HEADER_REFINE_MISMATCH_ACTOR}">
            <dp:with-param value="{name()}"/>
          </xsl:message>
          <xsl:value-of select="'keep'"/>
        </xsl:when>

        <xsl:when test="$header-nsuri = '' and $header-local-name = ''">
          <!-- comments nodes. -->
          <xsl:value-of select="'keep'"/>
        </xsl:when>

        <!-- the following processing rules need the judgement of service type and whether header is processed. -->
        <xsl:otherwise>
          <xsl:variable name="action">
              <xsl:variable name="instruction"
                        select="$disposition-table/SOAPHeaderDisposition/Refine[
                                  (Namespace='' or $header-nsuri = Namespace) and
                                  (LocalName='' or $header-local-name = LocalName) and
                                  ChildLocalName= ''
                                ]/Action"/>
              <xsl:variable name="system-instruction"
                        select="$system/SOAPHeaderDisposition/Refine[
                                  (Namespace='' or $header-nsuri = Namespace) and
                                  (LocalName='' or $header-local-name = LocalName) and
                                  ChildLocalName= ''
                                ]/Action"/>

              <xsl:choose>
                <xsl:when test="$instruction and $instruction != ''">
                  <xsl:value-of select="$instruction"/>
                </xsl:when>
                <xsl:when test="$system-instruction and $system-instruction != ''">
                  <xsl:value-of select="$system-instruction"/>
                </xsl:when>
                <xsl:otherwise>
                  <!-- any SOAP headers not specified by the custom or system disposition table 
                      are unknown, use the rules for the "unprocessed" rule. 
                  -->
                  <xsl:value-of select="'unprocessed'"/>
                </xsl:otherwise>
              </xsl:choose>
          </xsl:variable>
          <xsl:choose>
            <!-- generate a Receiver fault as specified. -->
            <xsl:when test="$action='fault'">
              <xsl:message dp:priority="debug" dp:id="{$DPLOG_SOAP_HEADER_REFINE_FAULT_REQUIRED}">
                <dp:with-param value="{name()}"/>
              </xsl:message>
              <xsl:value-of select="'dp:Unsupported'"/>
            </xsl:when>
    
            <!-- generate a env:MustUnderstand fault -->
            <xsl:when test="$action='unprocessed' and 
                            ( dpfunc:is-true(@S11:mustUnderstand) or dpfunc:is-true(@S12:mustUnderstand))                            
                            ">
              <xsl:message dp:priority="warn" dp:id="{$DPLOG_SOAP_HEADER_REFINE_FAULT_VOILATION}">
                <dp:with-param value="{name()}"/>
              </xsl:message>
              <xsl:value-of select="'env:MustUnderstand'"/>
            </xsl:when>

            <!-- keep the header when specified or for the intermediary if header is not processed. -->
            <xsl:when test="$action='keep'">
              <xsl:message dp:priority="debug" dp:id="{$DPLOG_SOAP_HEADER_REFINE_GO_THROUGH}">
                <dp:with-param value="{name()}"/>
              </xsl:message>
              <xsl:value-of select="'keep'"/>
            </xsl:when>

            <!-- remove the header when specified --> 
            <xsl:when test="$action='remove'"> 
              <xsl:message dp:priority="info" dp:id="{$DPLOG_SOAP_HEADER_REFINE_REMOVE_ATTR}">
                <dp:with-param value="{name()}"/>
              </xsl:message>
              <xsl:value-of select="'remove'"/>
            </xsl:when>

            <!-- here starts the default SOAP behaviors for the processed or unprocessed headers. -->

            <!-- If this header is targeted to "none" actor/role? keep it-->
            <xsl:when test="@S11:actor = 'http://www.w3.org/2003/05/soap-envelope/role/none' or
                            @S12:role = 'http://www.w3.org/2003/05/soap-envelope/role/none'
                            ">
              <xsl:message dp:priority="debug" dp:id="{$DPLOG_SOAP_HEADER_REFINE_NONE_ACTOR}">
                <dp:with-param value="{name()}"/>
              </xsl:message>
              <xsl:value-of select="'keep'"/>
            </xsl:when>

            <!-- the unprocessed header for intermediary service,
                 or the processed header with @S12:relay attribute is true
                 will be forwarded to next SOAP node. -->
            <xsl:when test="$dpconfig:service = 'intermediary' and
                            ( ($action='unprocessed') or 
                              (($action='processed' or $action='') and 
                               dpfunc:is-true(@S12:relay)
                              )
                            )">
              <xsl:message dp:priority="debug" dp:id="{$DPLOG_SOAP_HEADER_REFINE_INTERMEDIARY}">
                <dp:with-param value="{name()}"/>
              </xsl:message>
              <xsl:value-of select="'keep'"/>
            </xsl:when>

            <xsl:otherwise>
              <!-- the scenarios that this header can be deleted:
                    - any headers for a ultimate service
                    - the non-relayable unprocessed header for intermediary, or
                    - actor/role is next.
                -->
              <xsl:value-of select="'remove'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- output the disposition for this header. -->
    <xsl:element name="disposition">
      <xsl:attribute name="name"><xsl:value-of select="name()"/></xsl:attribute>
      <xsl:attribute name="id"><xsl:value-of select="generate-id()"/></xsl:attribute>
      <xsl:attribute name="action"><xsl:value-of select="$header-action"/></xsl:attribute>

      <!-- Process the header descendant. -->
      <xsl:for-each select="@* | node()">
        <xsl:variable name="child" select="."/>
        <xsl:variable name="instruction"
                      select="$disposition-table/SOAPHeaderDisposition/Refine[
                                (Namespace='' or $header-nsuri = Namespace) and
                                (LocalName='' or $header-local-name = LocalName) and
                                ChildLocalName= local-name($child)
                              ]/Action"/>
        <xsl:variable name="system-instruction"
                      select="$system/SOAPHeaderDisposition/Refine[
                                (Namespace='' or $header-nsuri = Namespace) and
                                (LocalName='' or $header-local-name = LocalName) and
                                ChildLocalName= local-name($child)
                              ]/Action"/>

        <xsl:variable name="action">
          <xsl:choose>
            <!-- keep everything in case of mismatched actors. -->
            <xsl:when test="$irrelevant-actor = 'true'">
              <xsl:value-of select="'keep'"/>
            </xsl:when>
            <xsl:when test="$instruction and $instruction != ''">
              <xsl:value-of select="$instruction"/>
            </xsl:when>
            <xsl:when test="$system-instruction and $system-instruction != ''">
              <xsl:value-of select="$system-instruction"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$header-action"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <!-- output the disposition for the children node of this header. -->
        <xsl:element name="disposition">
          <!-- The internal action to take for each node:
                - remove
                - keep
                - dp:Unsupported or wsse:UnsupportedSecurityToken
            -->
          <xsl:variable name="child-action">
            <xsl:choose>
              <!-- generate a Receiver fault as specified. -->
              <xsl:when test="$action='fault'">
                <xsl:choose>
                  <xsl:when test="$header-local-name = 'Security'">
                    <xsl:message dp:priority="debug" dp:id="{$DPLOG_SOAP_HEADER_REFINE_UNSUPPORTED_WSSEC}">
                      <dp:with-param value="{name()}"/>
                    </xsl:message>
                    <xsl:value-of select="'wsse:UnsupportedSecurityToken'"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:message dp:priority="debug" dp:id="{$DPLOG_SOAP_HEADER_REFINE_UNSUPPORTED_CHILD}">
                      <dp:with-param value="{name()}"/>
                    </xsl:message>
                    <xsl:value-of select="'dp:Unsupported'"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>

              <xsl:when test="$action='keep'">
                <xsl:value-of select="'keep'"/>
              </xsl:when>

              <xsl:when test="$action='remove'">
                <xsl:value-of select="'remove'"/>
              </xsl:when>

              <!-- the processed header children will be removed unless 
                   header is for the intermediary and @S12:relay is true.-->
              <xsl:when test="($action='processed' or $action='') and 
                               $dpconfig:service = 'intermediary' and
                               dpfunc:is-true($header/@S12:relay)">
                <xsl:message dp:priority="debug" dp:id="{$DPLOG_SOAP_HEADER_REFINE_REPLAY_CHILD}">
                  <dp:with-param value="{name()}"/>
                </xsl:message>
                <xsl:value-of select="'keep'"/>
              </xsl:when>

              <!-- the unprocessed header children will be removed unless 
                   header is for the intermediary.-->
              <xsl:when test="$action='unprocessed' and $dpconfig:service = 'intermediary'">
                <xsl:value-of select="'keep'"/>
                <xsl:message dp:priority="debug" dp:id="{$DPLOG_SOAP_HEADER_REFINE_UNPROCESSED_CHILD}">
                  <dp:with-param value="{name()}"/>
                </xsl:message>
              </xsl:when>

              <!-- remove it. -->
              <xsl:otherwise>
                <xsl:value-of select="'remove'"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <xsl:attribute name="name"><xsl:value-of select="name()"/></xsl:attribute>
          <xsl:attribute name="id"><xsl:value-of select="generate-id()"/></xsl:attribute>
          <xsl:attribute name="action"><xsl:value-of select="$child-action"/></xsl:attribute>

          <!-- we need not to save the "charter" for the nodes to be removed, that is assumed. -->
          <xsl:if test="$child-action='keep'">
            <xsl:apply-templates mode="preprocess" select="node()">
              <xsl:with-param name="action" select="$child-action"/>
            </xsl:apply-templates>
          </xsl:if>

        </xsl:element>
      </xsl:for-each>
    </xsl:element>
  </xsl:template>
  
  <xsl:template name="add-soap-fault">
    <xsl:param name="node" select="/.."/>
    <xsl:param name="code" select="'env:MustUnderstand'"/>

    <xsl:choose>
      <!-- nothing to do. -->
      <xsl:when test="count($node) = 0"/> 

      <xsl:otherwise>
        <xsl:variable name="faulted" select="dp:local-variable('faulted-nodeset')"/>
        <xsl:variable name="fault-nodeset">
          <xsl:copy-of select="$faulted"/>
          <node code="{$code}">
            <xsl:copy-of select="$node"/>
          </node>
        </xsl:variable>
        <dp:set-local-variable name="'faulted-nodeset'" value="$fault-nodeset"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="/">

    <!--
    <xsl:message dp:priority="error"> SOAP dpconfig:enforce-one-actor: <xsl:value-of select="$dpconfig:enforce-one-actor"/> </xsl:message>
    <xsl:message dp:priority="error"> SOAP dpconfig:actor-role-id: <xsl:value-of select="$dpconfig:actor-role-id"/> </xsl:message>
    <xsl:message dp:priority="error"> resolved-actor-role-id: <xsl:value-of select="$resolved-actor-role-id"/> </xsl:message>
    <xsl:message dp:priority="error"> SOAP dpconfig:service: <xsl:value-of select="$dpconfig:service"/> </xsl:message>
    <xsl:message dp:priority="error"> SOAP dpconfig:disposition: <xsl:value-of select="$dpconfig:disposition"/> </xsl:message>
    <xsl:message dp:priority="error"> SOAP dpconfig:delete-safe: <xsl:value-of select="$dpconfig:delete-safe"/> </xsl:message>
    <dp:dump-nodes file="'disposition-table.xsl'" nodes="$disposition-table"/>
    <dp:dump-nodes file="'system-disposition-table.xsl'" nodes="$system"/>
    <dp:dump-nodes file="'charter.xsl'" nodes="$charter"/>
    -->

    <xsl:choose>
      <!-- error: if there is a table, but the object is disabled. -->
      <xsl:when test="$disposition-table/SOAPHeaderDisposition/mAdminState != 'enabled'"> 
        <!-- generate a SOAP fault. -->
        <xsl:call-template name="wssec-security-header-fault">
          <xsl:with-param name="actor" select="$dpconfig:actor-role-id"/>
          <xsl:with-param name="soapnsuri" select="$___soapnsuri___"/>
          <xsl:with-param name="error-string" select="'The SOAP header Refine transformation is disabled.'"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>
        <xsl:variable name="output">
          <xsl:apply-templates/>
        </xsl:variable>

        <xsl:variable name="fault-nodeset" select="dp:local-variable('faulted-nodeset')"/>
        <xsl:variable name="not-understood-headers" select="$fault-nodeset/node[@code='env:MustUnderstand']/*"/>
        <!--
        <dp:dump-nodes file="'fault.xsl'" nodes="$fault-nodeset"/>
        -->
        <xsl:choose>
          <!-- error: if there is a table, but the object is disabled. -->
          <xsl:when test="count($fault-nodeset/node) &gt; 0"> 
            <!-- generate a SOAP fault. -->
            <xsl:call-template name="wssec-security-header-fault">
              <xsl:with-param name="actor" select="$dpconfig:actor-role-id"/>
              <xsl:with-param name="soapnsuri" select="$___soapnsuri___"/>
              <xsl:with-param name="code">
                <xsl:choose>
                  <xsl:when test="count($not-understood-headers) &gt; 0">
                    <xsl:value-of select="'env:MustUnderstand'"/>
                  </xsl:when>
                  <xsl:when test="$fault-nodeset/node[1]/@code = 'wsse:UnsupportedSecurityToken'">
                    <xsl:value-of select="$fault-nodeset/node[1]/@code"/>
                  </xsl:when>
                </xsl:choose>
              </xsl:with-param>
              <xsl:with-param name="subcode">
                <xsl:choose>
                  <!-- it is same as the default behavior. -->
                  <xsl:when test="$fault-nodeset/node[1]/@code = 'wsse:InvalidSecurity'">
                    <xsl:value-of select="''"/>
                  </xsl:when>
                  <xsl:when test="$fault-nodeset/node[1]/@code = 'dp:Unsupported'">
                    <xsl:value-of select="'dp:Unsupported'"/>
                  </xsl:when>
                </xsl:choose>
              </xsl:with-param>
              <xsl:with-param name="not-understood-headers" select="$not-understood-headers"/>
              <xsl:with-param name="soap-node-id">
                <xsl:if test="$dpconfig:service = 'intermediary'">
                  <xsl:value-of select="'IBM WebSphere DataPower SOA Appliance'"/>
                </xsl:if>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:when>

          <xsl:otherwise>
            <xsl:copy-of select="$output"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template match="@*" priority="-3">
    <xsl:copy/>
  </xsl:template>

  <xsl:template match="node()">
    <xsl:variable name="uid" select="generate-id()"/>

    <xsl:variable name="header-charter" select="$charter//disposition[@id=$uid]"/>

    <xsl:variable name="action">
      <xsl:choose>
        <xsl:when test="$header-charter/@action">
          <xsl:value-of select="$header-charter/@action"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'remove'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:choose>
      <!-- generate a SOAP fault. -->
      <xsl:when test="$action='wsse:InvalidSecurity' or $action='env:MustUnderstand' or 
                      $action='dp:Unsupported' or $action='wsse:UnsupportedSecurityToken'">
        <xsl:call-template name="add-soap-fault">
          <xsl:with-param name="node" select="."/>
          <xsl:with-param name="code" select="$action"/>
        </xsl:call-template>
      </xsl:when>

      <!-- before we remove the node, make sure it is safe to delete.-->
      <xsl:when test="$action='remove' and $dpconfig:delete-safe='on' and 
                      dpfunc:being-referenced(.)">
        <xsl:message dp:priority="info" dp:id="{$DPLOG_SOAP_HEADER_REFINE_REFERENCED}">
          <dp:with-param value="{name()}"/>
        </xsl:message>
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <xsl:copy-of select="node()"/>
        </xsl:copy>
      </xsl:when>

      <!-- The EncryptedKey is such a special case, that we have to process differently.
           Normally the EncryptedKey contains a data reference @URI to the encrypted data, 
           then the Key is configured to keep, all the encrypted data will be protected by the 
           above code.

           But how about if I configured to keep an EncryptedData, will the key be protected?
           The following is for that purpose.
           -->
      <xsl:when test="self::xenc:EncryptedKey and $action='remove' and $dpconfig:delete-safe='on' and 
                      dpfunc:referencing-others(.)" xmlns:xenc="http://www.w3.org/2001/04/xmlenc#">
        <xsl:message dp:priority="info" dp:id="{$DPLOG_SOAP_HEADER_REFINE_REFERENCING}">
          <dp:with-param value="{name()}"/>
        </xsl:message>
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <xsl:copy-of select="node()"/>
        </xsl:copy>
      </xsl:when>

      <xsl:otherwise>
        <!-- the children may be specifically instructed as well. -->
        <xsl:variable name="children">
          <xsl:apply-templates select="node()"/>
        </xsl:variable>

        <xsl:choose>
          <!-- keep.-->
          <xsl:when test="$action='keep'">
            <xsl:copy>
              <xsl:copy-of select="@*"/>
              <xsl:copy-of select="$children"/>
            </xsl:copy>
          </xsl:when>

          <!-- remove.-->
          <xsl:when test="$action='remove'">
            <xsl:choose>
              <!-- let's decide if this header should be removed completely or keep the element as container instead.  -->
              <xsl:when test="count($children/*) &gt; 0">
                <!-- just keep the element name, no attributes. -->
                <xsl:copy>
                  <xsl:copy-of select="$children"/>
                </xsl:copy>
              </xsl:when>

              <!--Remove it. -->
              <xsl:otherwise>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
