<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2010. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
     /*
     *
     * Copyright (c) 2003-2005 DataPower Technology, Inc. All Rights Reserved
     *
     * THIS IS UNPUBLISHED PROPRIETARY TRADE SECRET SOURCE CODE OF DataPower
     * Technology, Inc.
     *
     * The copyright above and this notice must be preserved in all copies of
     * the source code. The copyright notice above does not evidence any actual
     * or intended publication of such source code. This source code may not be
     * copied, compiled, disclosed, distributed, demonstrated or licensed except
     * as expressly authorized by DataPower Technology, Inc.
     *
     */
     -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xsd1999="http://www.w3.org/1999/XMLSchema"
  xmlns:xsd2000="http://www.w3.org/2000/10/XMLSchema"
  xmlns:xsd="http://www.w3.org/2001/XMLSchema"
  xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
  xmlns:wsdlsoap="http://schemas.xmlsoap.org/wsdl/soap/"
  xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/"
  xmlns:dp="http://www.datapower.com/extensions"
  extension-element-prefixes="dp"
  exclude-result-prefixes="dp #default xsd1999 xsd2000">

  <!-- Common utility templates and globals -->
  <xsl:include href="store:///w2sUtil.xsl" dp:ignore-multiple="yes"/>

  <!-- =============================================================== -->
  <xsl:template name="w2sFindBindings">

    <xsl:param name="content" select="/"/>
    <xsl:param name="usingSOAPEnc"/>    

    <!-- WSDL ports: -->
    <xsl:param name="ports" select="/.."/>

    <!-- Corresponding bindings: -->
    <xsl:param name="bindings" select="/.."/>

    <!-- target namespace -->
    <xsl:param name="defaultNS" select="/wsdl:definitions/@targetNamespace"/>

    <!-- filename for sub schemas,
         this is defined when schema for container is being generated -->
    <xsl:param name="myoutfile"/>

    <!-- the number of sub schema to generate -->
    <xsl:param name="my-schema-number" select="number(0)"/>

    <!-- the URI of sub schema to generate -->
    <xsl:param name="my-schema-ns"/>
    
        
    <xsl:choose>
      <!-- If we're out of ports, process the bindings. -->
      <xsl:when test="count($ports)=0">
        <xsl:call-template name="w2sRpcProcessBindings">
          <xsl:with-param name="content"          select="$content"/>
          <xsl:with-param name="usingSOAPEnc"     select="$usingSOAPEnc"/>
          <xsl:with-param name="bindings"         select="$bindings"/>
          <xsl:with-param name="defaultNS"        select="$defaultNS"/>
          <xsl:with-param name="myoutfile"        select="$myoutfile"/>
          <xsl:with-param name="my-schema-number" select="$my-schema-number"/>          
          <xsl:with-param name="my-schema-ns"     select="$my-schema-ns"/>          
        </xsl:call-template>
      </xsl:when>

      <!-- Otherwise, find the binding for the first port and repeat. -->
      <xsl:otherwise>
        <xsl:variable name="car"     select="$ports[1]"/>                <!-- current port -->
        <xsl:variable name="cdr"     select="$ports[position()&gt;1]"/>  <!-- remaining ports -->
        <xsl:variable name="ns"      select="string($car/namespace::*[local-name()=substring-before($car/@binding,':')])"/>  <!-- ns that has localname() equal to prefix of wsdl:port/@binding -->
        <xsl:variable name="defs"    select="$content/wsdl:definitions[string(@targetNamespace)=$ns]"/>                      <!-- the wsdl definition from this target namespace -->
        <!-- if the current wsdl:port/@binding has no namespace prefix, select accordingly.  or, select the binding of the matching ncname. -->
        <xsl:variable name="binding" select="$defs/wsdl:binding[(not(contains($car/@binding,':')) and @name=$car/@binding) or @name=substring-after($car/@binding,':')]"/>

        <xsl:call-template name="w2sFindBindings">
          <xsl:with-param name="content" select="$content"/>
          <xsl:with-param name="usingSOAPEnc" select="$usingSOAPEnc"/>
          <xsl:with-param name="ports" select="$cdr"/>
          <xsl:with-param name="bindings" select="$bindings|$binding"/>  <!-- note the union here -->
          <xsl:with-param name="defaultNS"        select="$defaultNS"/>
          <xsl:with-param name="myoutfile"        select="$myoutfile"/>
          <xsl:with-param name="my-schema-number" select="$my-schema-number"/>          
          <xsl:with-param name="my-schema-ns"     select="$my-schema-ns"/>          
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- =============================================================== -->

  <!-- this template will generate subschema if my-schema-number is greater than 0 ,
       otherwise main schema will be generated -->
  <xsl:template name="w2sRpcProcessBindings">

    <xsl:param name="content"/>
    <xsl:param name="usingSOAPEnc"/>
    <xsl:param name="bindings"/>
    <xsl:param name="defaultNS"/>
    <xsl:param name="myoutfile"/>
    <xsl:param name="my-schema-number" select="number(0)"/>          
    <!-- the URI of sub schema to generate -->
    <xsl:param name="my-schema-ns"/>
    
    <xsl:variable name="aliens"
      select="$bindings/wsdl:operation[wsdlsoap:operation/@style='rpc' or
              (not(wsdlsoap:operation/@style) and
              ../wsdlsoap:binding/@style='rpc')]/*/wsdlsoap:body[@namespace!=$defaultNS or
              (not(@namespace) and ../../../../@targetNamespace!=$defaultNS)]"/>
    
    <xsl:variable name="schemaSectionsNUM"
      select="count($content/wsdl:definitions/wsdl:types/*[
              self::xsd1999:schema or
              self::xsd2000:schema or
              self::xsd:schema])"/>
    <xsl:choose>

      <!-- sub schema generation by name
           this is the case when namespace on wsdlsoap:body matches one of the
           schemas' namespaces in wsdl:types -->
      <xsl:when test="$my-schema-ns">
        
        <xsl:for-each select="$content/wsdl:definitions/namespace::*">
          <xsl:copy/>
        </xsl:for-each>
        
        <xsl:apply-templates
          select="$bindings/wsdl:operation[
                  (wsdlsoap:operation/@style='rpc' or
                  (not(wsdlsoap:operation/@style) and
                  ../wsdlsoap:binding/@style='rpc')) and
                  (*/wsdlsoap:body/@namespace=$my-schema-ns or
                  (not (*/wsdlsoap:body/@namespace)) and
                  ../../@targetNamespace=$my-schema-ns)]"
          mode="portType">

          <xsl:with-param name="content"      select="$content"/>
          <xsl:with-param name="usingSOAPEnc" select="$usingSOAPEnc"/>
          <xsl:with-param name="tgtNS"        select="$my-schema-ns"/>            

        </xsl:apply-templates>
        
      </xsl:when>
      
      <!-- sub schema generation by index --> 
      <xsl:when test="number($my-schema-number)&gt;0">
        <xsl:call-template name="w2sRpcGenerateSubSchema">
          <xsl:with-param name="content"          select="$content"/>
          <xsl:with-param name="usingSOAPEnc"     select="$usingSOAPEnc"/>
          <xsl:with-param name="bindings"         select="$bindings"/>
          <xsl:with-param name="soapbodies"       select="$aliens"/>
          <xsl:with-param name="schemaindex"      select="$schemaSectionsNUM + 1"/>
          <xsl:with-param name="my-schema-number" select="$my-schema-number"/>          
        </xsl:call-template>
      </xsl:when>

      <!-- main schema -->
      <xsl:otherwise>

        <xsl:choose>
          
        <xsl:when test="count($aliens) &gt; 0">

          <xsl:call-template name="GenComment">
            <xsl:with-param name="comment"
              select="'Importing sub-schemas for the wsdl:operation'"/>
            <xsl:with-param name="major" select="true()"/>
          </xsl:call-template>
      
          <!-- Generate imports for subschema files -->
          <xsl:call-template name="w2sRpcImportSubSchemas">
            <xsl:with-param name="content"     select="$content"/>
            <xsl:with-param name="myoutfile"   select="$myoutfile"/>
            <xsl:with-param name="soapbodies"  select="$aliens"/>
            <xsl:with-param name="schemaindex" select="$schemaSectionsNUM + 1"/>
          </xsl:call-template>

        </xsl:when>

        <xsl:otherwise>
          <!-- number of sub schemas in the for of processing instruction -->
          <dp:set-variable name="'var://service/wsm/num-subschema'" value='$schemaSectionsNUM'/>
          <xsl:processing-instruction name="dp-wsdl-sub-schemas">
            <xsl:value-of select="$schemaSectionsNUM"/>
          </xsl:processing-instruction>
        </xsl:otherwise>
          
        </xsl:choose>
        
        <!-- Drill down from the wsdl:binding template
             to generate top-level schema elements (see w2sMakeContainer.xsl)-->
        <xsl:apply-templates select="$bindings">
          <xsl:with-param name="content"      select="$content"/>
          <xsl:with-param name="usingSOAPEnc" select="$usingSOAPEnc"/>
        </xsl:apply-templates>
        
      </xsl:otherwise>

    </xsl:choose>
        
  </xsl:template>

  <!-- =============================================================== -->

  <xsl:template name="w2sRpcImportSubSchemas">
    <xsl:param name="content"/>
    <xsl:param name="myoutfile"/>
    <xsl:param name="soapbodies"/>
    <xsl:param name="schemaindex"/>

    <xsl:variable name="filename"
      select="concat($myoutfile, '-subschema', $schemaindex, '.xsd')"/>

    <xsl:variable name="car" select="$soapbodies[1]"/>
    <xsl:variable name="cdr" select="$soapbodies[position()&gt;1]"/>
    <xsl:variable name="ns">
      <xsl:choose>
        <xsl:when test="$car/@namespace">
          <xsl:value-of select="$car/@namespace"/>
        </xsl:when>
        <xsl:otherwise>
          <!-- use wsdl:definitions/@targetNamespace -->
          <xsl:value-of select="$car/../../../../@targetNamespace"/> 
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- whether or not we need to import namespace or it's already was -->
    <xsl:variable name="needImportNS"
      select="count($content/wsdl:definitions/wsdl:types/xsd:schema[@targetNamespace=$ns])=0"/>

    <xsl:choose>

      <xsl:when test="count($cdr)=0">
        <xsl:choose>
          <xsl:when test="$needImportNS">
            <xsd:import namespace="{$ns}" schemaLocation="{$filename}"/> 
            <!-- number of sub schemas in the for of processing intruction -->
            <dp:set-variable name="'var://service/wsm/num-subschema'" value='$schemaindex'/> 
            <xsl:processing-instruction name="dp-wsdl-sub-schemas">
              <xsl:value-of select="$schemaindex"/>
            </xsl:processing-instruction>            
          </xsl:when>
          <xsl:otherwise>
            <!-- number of sub schemas in the for of processing intruction -->
            <dp:set-variable name="'var://service/wsm/num-subschema'" value='number($schemaindex - 1)'/> 
            <xsl:processing-instruction name="dp-wsdl-sub-schemas">
              <xsl:value-of select="number($schemaindex)-1"/>
            </xsl:processing-instruction>            
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      
      <xsl:when test="$needImportNS and
                      count($cdr[@namespace=$ns or ../../../../@targetNamespace=$ns])=0">
        <xsd:import namespace="{$ns}" schemaLocation="{$filename}"/>
        <xsl:call-template name="w2sRpcImportSubSchemas">
          <xsl:with-param name="content"     select="$content"/>
          <xsl:with-param name="myoutfile"   select="$myoutfile"/>
          <xsl:with-param name="soapbodies"  select="$cdr"/>
          <xsl:with-param name="schemaindex" select="number($schemaindex)+1"/>
        </xsl:call-template>        
      </xsl:when>
      
      <xsl:otherwise>
        <xsl:call-template name="w2sRpcImportSubSchemas">
          <xsl:with-param name="content"     select="$content"/>
          <xsl:with-param name="myoutfile" select="$myoutfile"/>
          <xsl:with-param name="soapbodies" select="$cdr"/>
          <xsl:with-param name="schemaindex" select="$schemaindex"/>
        </xsl:call-template>        
      </xsl:otherwise>
      
    </xsl:choose>
    
  </xsl:template>
  
  <!-- =============================================================== -->
  <xsl:template name="w2sRpcGenerateSubSchema">
    
    <xsl:param name="content" select="/"/>
    <xsl:param name="usingSOAPEnc"/>
    <xsl:param name="bindings"/>
    <xsl:param name="soapbodies"/>
    <xsl:param name="schemaindex"/>
    <xsl:param name="my-schema-number"/>

    <xsl:variable name="car" select="$soapbodies[1]"/>
    <xsl:variable name="cdr" select="$soapbodies[position()&gt;1]"/>
    <xsl:variable name="ns">
      <xsl:choose>
        <xsl:when test="$car/@namespace">
          <xsl:value-of select="$car/@namespace"/>
        </xsl:when>
        <xsl:otherwise>
          <!-- use wsdl:definitions/@targetNamespace -->
          <xsl:value-of select="$car/../../../../@targetNamespace"/> 
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:choose>

      <xsl:when test="$schemaindex = $my-schema-number">
        <xsd:schema>

          <xsl:for-each select="$content/wsdl:definitions/namespace::*">
            <xsl:copy/>
          </xsl:for-each>
          
          <xsl:attribute name="targetNamespace">
            <xsl:value-of select="$ns"/>
          </xsl:attribute>

          <!-- apply wsdl:binding/wsdl:operation mode="portType"
               only to those operations that have RPC-style
               and different than default namespace -->
          <xsl:apply-templates
            select="$bindings/wsdl:operation[
                    (wsdlsoap:operation/@style='rpc' or
                    (not(wsdlsoap:operation/@style) and
                    ../wsdlsoap:binding/@style='rpc')) and
                    (*/wsdlsoap:body/@namespace=$ns or
                    (not (*/wsdlsoap:body/@namespace)) and
                    ../../@targetNamespace=$ns)]"
            mode="portType">
            <xsl:with-param name="content" select="$content"/>
            <xsl:with-param name="usingSOAPEnc" select="$usingSOAPEnc"/>
            <xsl:with-param name="tgtNS" select="$ns"/>            
          </xsl:apply-templates>
        </xsd:schema>
      </xsl:when>
      
      <xsl:otherwise>
        
        <!-- whether or not we need to generate namespace or it's already was -->
        <xsl:variable name="needGenerateNS"
          select="count($content/wsdl:definitions/wsdl:types/xsd:schema[@targetNamespace=$ns])=0"/>
        
        <xsl:choose>
          
          <xsl:when test="count($cdr)=0">
            <xsl:call-template name="GenError">
              <xsl:with-param name="errorMsg"
                select="concat('Invalid schema number ', $my-schema-number)"/>
            </xsl:call-template>
          </xsl:when>
      
          <xsl:when test="$needGenerateNS and count($cdr[@namespace=$ns or
                          ../../../../@targetNamespace=$ns])=0">
            <xsl:call-template name="w2sRpcGenerateSubSchema">
              <xsl:with-param name="content"   select="$content"/>
              <xsl:with-param name="usingSOAPEnc" select="$usingSOAPEnc"/>
              <xsl:with-param name="bindings"  select="$bindings"/>
              <xsl:with-param name="soapbodies"  select="$cdr"/>
              <xsl:with-param name="schemaindex" select="number($schemaindex)+1"/>
              <xsl:with-param name="my-schema-number" select="$my-schema-number"/>
            </xsl:call-template>        
          </xsl:when>
      
          <xsl:otherwise>
            <xsl:call-template name="w2sRpcGenerateSubSchema">
              <xsl:with-param name="content"   select="$content"/>
              <xsl:with-param name="usingSOAPEnc" select="$usingSOAPEnc"/>
              <xsl:with-param name="bindings"  select="$bindings"/>
              <xsl:with-param name="soapbodies"  select="$cdr"/>
              <xsl:with-param name="schemaindex" select="$schemaindex"/>
              <xsl:with-param name="my-schema-number" select="$my-schema-number"/>
            </xsl:call-template>        
          </xsl:otherwise>
      
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>

  <!-- =============================================================== -->
  <!-- HACK :(: this is for compilation only, should never been called --> 
  <xsl:template match="HACK_TO_COMPILE" priority="-100">
    <xsl:param name="content" select="/"/>
    <xsl:param name="usingSOAPEnc"/>
  </xsl:template>

 <!-- =============================================================== -->
  <xsl:template match="wsdl:binding/wsdl:operation" mode="portType">
    <xsl:param name="content" select="/"/>
    <xsl:param name="usingSOAPEnc"/>
    <xsl:param name="tgtNS"/>

    <xsl:variable name="bindingType" select="../@type"/>

    <!-- What's the name of the corresponding port? -->
    <xsl:variable name="portName">
      <xsl:choose>
        <xsl:when test="contains($bindingType, ':')">
          <xsl:value-of select="substring-after($bindingType, ':')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$bindingType"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="portURI"
      select="string(namespace::*[
              local-name()=substring-before($bindingType,':')])"/>

    <xsl:variable name="port"
      select="$content/wsdl:definitions[
              string(@targetNamespace)=$portURI
              ]/wsdl:portType[
              substring-after(@name, ':')=$portName
              or @name=$portName]"/>
    <xsl:variable name="portOp"
      select="$port/wsdl:operation[@name=current()/@name]"/>

    <xsl:variable name="transmissionPrimitive">
      <xsl:call-template name="DetermineTransmissionPrimitive">
        <xsl:with-param name="operation" select="$portOp"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:if test="$transmissionPrimitive = $BadMEP">
      <xsl:call-template name="GenError">
        <xsl:with-param name="errorMsg"
          select="concat('Invalid Message Exchange Pattern for operation ',
                  $quote, @name, $quote)"/>
      </xsl:call-template>
    </xsl:if>
    
    <xsl:apply-templates select="." mode="rpcStyle">
      <xsl:with-param name="content"               select="$content"/>
      <xsl:with-param name="usingSOAPEnc"          select="$usingSOAPEnc"/>
      <xsl:with-param name="portOp"                select="$portOp"/>
      <xsl:with-param name="transmissionPrimitive" select="$transmissionPrimitive"/> 
      <xsl:with-param name="tgtNS"                 select="$tgtNS"/>      
    </xsl:apply-templates>
    
    
  </xsl:template>

  <!-- =============================================================== -->
  <xsl:template match="wsdl:binding/wsdl:operation" mode="rpcStyle">
    <xsl:param name="content" select="/"/>
    <xsl:param name="usingSOAPEnc"/>
    <xsl:param name="portOp"/>
    <xsl:param name="transmissionPrimitive"/>
    <xsl:param name="tgtNS" select="/wsdl:definitions/@targetNamespace"/>
    <xsl:param name="buildFaultElementsForRPCWrappers" select="true()"/>

    <!-- Are there things in this binding that don't have a
         corresponding item in the port? -->
    <xsl:variable name="extras"
      select="$portOp/wsdl:input[not (current()/wsdl:input)]|
              $portOp/wsdl:output[not (current()/wsdl:output)]|
              $portOp/wsdl:fault[not (@name = current()/wsdl:fault/@name)]"/>

    <!-- all wsdl:input in that is in the target NS -->
    <xsl:variable name="inputsInTgtNS"
      select="wsdl:input[wsdlsoap:body/@namespace=$tgtNS or
              (not (wsdlsoap:body/@namespace) and (../../../@targetNamespace=$tgtNS))]"/>

    <!-- all wsdl:output in that is in the target NS -->
    <xsl:variable name="outputsInTgtNS"
      select="wsdl:output[wsdlsoap:body/@namespace=$tgtNS or
              (not (wsdlsoap:body/@namespace) and (../../../@targetNamespace=$tgtNS)) or
              ../wsdl:input/wsdlsoap:body/@namespace=$tgtNS]"/>

    <!-- The request and response have different names.  This
         doesn't come from WSDL, but rather from a suggestion in
         SOAP 1.1 section 7.1.  -->

    <xsl:if test="$inputsInTgtNS|wsdl:fault|$extras[self::wsdl:fault]">
      <xsl:call-template name="GenComment">
        <xsl:with-param name="comment"
            select="concat('RPC style wrappers for operation ', $quote, @name, $quote)"/>
        <xsl:with-param name="major" select="false()"/>
      </xsl:call-template>
        
      <!-- rtb: i don't believe that the fault element can appear inside the input or
           output element in a soap:binding; make generation of this error element
           configurable.  Bug 8959 -->
      <xsl:if test="$buildFaultElementsForRPCWrappers">
        <xsl:apply-templates select="." mode="rpcStyleBody">
          <xsl:with-param name="content" select="$content"/>
          <xsl:with-param name="portOp" select="$portOp"/>
          <xsl:with-param name="transmissionPrimitive" select="$transmissionPrimitive"/>
          <xsl:with-param name="opName" select="@name"/>
          <xsl:with-param name="contents" select="$inputsInTgtNS|wsdl:fault"/>
          <xsl:with-param name="extras" select="$extras"/>
          <xsl:with-param name="usingSOAPEnc" select="$usingSOAPEnc"/>
        </xsl:apply-templates>
      </xsl:if>
      <xsl:if test="not( $buildFaultElementsForRPCWrappers )">
        <xsl:apply-templates select="." mode="rpcStyleBody">
          <xsl:with-param name="content" select="$content"/>
          <xsl:with-param name="portOp" select="$portOp"/>
          <xsl:with-param name="transmissionPrimitive" select="$transmissionPrimitive"/>
          <xsl:with-param name="opName" select="@name"/>
          <xsl:with-param name="contents" select="$inputsInTgtNS"/>
          <xsl:with-param name="extras" select="$extras"/>
          <xsl:with-param name="usingSOAPEnc" select="$usingSOAPEnc"/>
        </xsl:apply-templates>
      </xsl:if>
    </xsl:if>

    <xsl:if test="($outputsInTgtNS) and ($buildFaultElementsForRPCWrappers)">
        <xsl:apply-templates select="." mode="rpcStyleBody">
          <xsl:with-param name="content" select="$content"/>
          <xsl:with-param name="portOp" select="$portOp"/>
          <xsl:with-param name="transmissionPrimitive" select="$transmissionPrimitive"/>
          <xsl:with-param name="opName" select="concat(@name, 'Response')"/>
          <xsl:with-param name="contents" select="$outputsInTgtNS|wsdl:fault"/>
          <xsl:with-param name="extras" select="$extras"/>
          <xsl:with-param name="usingSOAPEnc" select="$usingSOAPEnc"/>
        </xsl:apply-templates>
    </xsl:if>
    <xsl:if test="($outputsInTgtNS) and (not($buildFaultElementsForRPCWrappers))">
        <xsl:apply-templates select="." mode="rpcStyleBody">
          <xsl:with-param name="content" select="$content"/>
          <xsl:with-param name="portOp" select="$portOp"/>
          <xsl:with-param name="transmissionPrimitive" select="$transmissionPrimitive"/>
          <xsl:with-param name="opName" select="concat(@name, 'Response')"/>
          <xsl:with-param name="contents" select="$outputsInTgtNS"/>
          <xsl:with-param name="extras" select="$extras"/>
          <xsl:with-param name="usingSOAPEnc" select="$usingSOAPEnc"/>
        </xsl:apply-templates>
    </xsl:if>

    <xsl:call-template name="GenFaults">
        <xsl:with-param name="content" select="$content"/>
        <xsl:with-param name="operation" select="$portOp"/>
        <xsl:with-param name="usingSOAPEnc" select="$usingSOAPEnc"/>
    </xsl:call-template>
  </xsl:template>
  
  <!-- =============================================================== -->

  <xsl:template match="wsdl:binding/wsdl:operation" mode="rpcStyleBody">
    <xsl:param name="content" select="/"/>
    <xsl:param name="portOp"/>
    <xsl:param name="transmissionPrimitive"/>
    <xsl:param name="opName" select="@name"/>
    <xsl:param name="contents" select="wsdl:input|wsdl:output|wsdl:fault"/>
    <xsl:param name="extras"/>
    <xsl:param name="usingSOAPEnc"/>

    <!-- We have some number of inputs, outputs, and faults.  Each
         of them can specify use="literal" or use="encoded", and may
         have a list of parts.  In rpc style, there is a top-level
         element for the operation, with child elements for each
         part.  Or, sometimes the top-level element might have an
         identically named child, which has the content; this is
         only seen on inputs, though. -->
    <xsd:element name="{$opName}">
      <xsd:complexType>
        <!-- Your choice of messages: -->
        <xsd:choice>
          <!-- Possibly ourselves, again, but maybe with a different
               name: -->
          <xsl:if test="$contents[self::wsdl:input]">
            <xsl:for-each select="$contents">
              <xsd:element>
                <xsl:attribute name="name">
                  <xsl:call-template name="DetermineIOFName">
                    <xsl:with-param name="transmissionPrimitive"
                      select="$transmissionPrimitive"/>
                    <xsl:with-param name="opName" select="$opName"/>
                  </xsl:call-template>
                </xsl:attribute>
                <xsd:complexType>
                  <xsd:choice>
                    <xsl:apply-templates select="." mode="rpcStyleContents">
                      <xsl:with-param name="content" select="$content"/>
                      <xsl:with-param name="portOp" select="$portOp"/>
                      <xsl:with-param name="transmissionPrimitive"
                        select="$transmissionPrimitive"/>
                      <xsl:with-param name="opName" select="$opName"/>
                    </xsl:apply-templates>
                  </xsd:choice>
                  <xsl:call-template name="GenAttributes">
                    <xsl:with-param name="usingSOAPEnc" select="$usingSOAPEnc"/>
                  </xsl:call-template>
                </xsd:complexType>
              </xsd:element>
            </xsl:for-each>
          </xsl:if>
          <!-- If we were handled unbound faults, allow them in this
               path, where the name is the fault name and so is
               distinct. -->
          <xsl:for-each select="$extras[self::wsdl:fault]">
            <xsd:element name="{@name}">
              <xsd:complexType>
                <xsl:call-template name="GenSequenceForIOF">
                  <xsl:with-param name="content" select="$content"/>
                  <xsl:with-param name="iof" select="."/>
                </xsl:call-template>
                <xsl:call-template name="GenAttributes">
                  <xsl:with-param name="usingSOAPEnc" select="$usingSOAPEnc"/>
                </xsl:call-template>
              </xsd:complexType>
            </xsd:element>
          </xsl:for-each>
          <!-- Or possibly just the expected contents: -->
          <xsl:apply-templates select="$contents"
            mode="rpcStyleContents">
            <xsl:with-param name="content" select="$content"/>
            <xsl:with-param name="portOp" select="$portOp"/>
            <xsl:with-param name="transmissionPrimitive"
              select="$transmissionPrimitive"/>
            <xsl:with-param name="opName" select="$opName"/>
          </xsl:apply-templates>
        </xsd:choice>
        <xsl:call-template name="GenAttributes">
          <xsl:with-param name="usingSOAPEnc" select="$usingSOAPEnc"/>
        </xsl:call-template>
      </xsd:complexType>
    </xsd:element>
  </xsl:template>

  <!-- =============================================================== -->

  <xsl:template match="wsdl:input|wsdl:output|wsdl:fault"
    mode="rpcStyleContents">
    <xsl:param name="content" select="/"/>
    <xsl:param name="portOp"/>
    <xsl:param name="transmissionPrimitive"/>
    <xsl:param name="opName" select="@name"/>

    <xsl:variable name="iofName">
      <xsl:call-template name="DetermineIOFName">
        <xsl:with-param name="transmissionPrimitive"
          select="$transmissionPrimitive"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="inputName">
      <xsl:call-template name="DetermineIOFName">
        <xsl:with-param name="iof" select="$portOp/wsdl:input"/>
        <xsl:with-param name="transmissionPrimitive"
          select="$transmissionPrimitive"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="outputName">
      <xsl:call-template name="DetermineIOFName">
        <xsl:with-param name="iof" select="$portOp/wsdl:output"/>
        <xsl:with-param name="transmissionPrimitive"
          select="$transmissionPrimitive"/>
      </xsl:call-template>
    </xsl:variable>

    <!-- Corresponding input/output/fault in the port's operation:
         (Either the port's name is $iofName, or neither the
         port nor the binding have a name at all, so they
         both have the default, or the port has no name and the
         appropriate default matches $iofName.) -->
    <xsl:variable name="portIOF"
      select="$portOp/*[name(.)=name(current()) and
              (@name=$iofName or not(@name or current()/@name) or
              (not(@name) and
              ((local-name(.)='input' and $iofName=$inputName) or
              (local-name(.)='output' and $iofName=$outputName))))]"/>
    <!-- And the message that matches that: -->
    <xsl:variable name="message"
      select="$content/wsdl:definitions[
              string(@targetNamespace)=
              string($portIOF/namespace::*[
              local-name()=substring-before($portIOF/@message,':')
              ])
              ]/wsdl:message[@name=$portIOF/@message or
              @name=substring-after($portIOF/@message, ':')]"/>
    
    <!-- Things from our soap:body child: -->
    <xsl:variable name="parts" select="wsdlsoap:body/@parts"/>
    <xsl:variable name="use" select="wsdlsoap:body/@use"/>
    
    <!-- For both literal and encoded cases, generate a sequence
         of possible child elements. -->
    <xsl:call-template name="GenSequenceForIOF">
      <xsl:with-param name="content" select="$content"/>
      <xsl:with-param name="iof" select="$portIOF"/>
      <xsl:with-param name="parts" select="$parts"/>
    </xsl:call-template>
  </xsl:template>

  <!-- =============================================================== -->

</xsl:stylesheet>
