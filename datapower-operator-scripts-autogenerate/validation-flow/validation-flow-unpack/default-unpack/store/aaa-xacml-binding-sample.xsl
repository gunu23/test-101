<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2010. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpfunc="http://www.datapower.com/extensions/functions"
    xmlns:dpquery="http://www.datapower.com/param/query"
    xmlns:dpconfig="http://www.datapower.com/param/config"
    xmlns:dpxacml="urn:ibm:names:datapower:xacml:2.0"
    xmlns:func="http://exslt.org/functions"
    xmlns:dyn="http://exslt.org/dynamic"
    xmlns:xacml         ="urn:oasis:names:tc:xacml:2.0:policy:schema:os"
    xmlns:xacml-context ="urn:oasis:names:tc:xacml:2.0:context:schema:os"
    exclude-result-prefixes="dp dpfunc dpquery dpconfig dpxacml func dyn xacml xacml-context"
    extension-element-prefixes="dp dpfunc"
    version="1.0">

    <!-- This style sheet is a sample file to map AAA results to a
         <xacml-context:Resquest/>, aka xacml context request message. 

        - This stylesheet is called after user is authenticated, meaning
          EI, AU, MC, ER, MR are done already. All those information 
          are passed from AAA framework to this Stylesheet as xsl parameters
          if 'store:///dp/aaa-xacml-context.xsl' is included to this
          stylesheet.
          Those parameters include but not limited to:
            dpxacml:xacml-version     The XACML version of the request context
            dpxacml:identity          The result of EI step.
            dpxacml:credentials       The result of AU step.
            dpxacml:mapped-credentials    The result of MC step.
            dpxacml:resource          The result of ER step.
            dpxacml:mapped-resource   The result of MR step.
        - AAA framework doesn't provide any other additiona information,
          unless the information is part of result from one/more of the above
          AAA steps. However, customer can use AAA custom steps to put additional 
          information, then those information will be then available to this stylesheet
          via the above parameters.
        - The stylesheet input is the original message being passed for AAA
          processing, however this stylesheet does not extract any information
          from the input request to generate the xacml context request message.
        - This stylesheet can pass arbitrary HTTP headers to the external PDP by
          setting the header with a special name.
          for example, if the external PDP requires PEP with two HTTP headers "SOAPAction" 
          and "Authorization" for any reason, the following codes can be added to 
          this stylesheet
            <dp:set-request-header name="'X-XACML-SOAPAction'" value="'http://tempuri.org/Echo'"/>
            <dp:set-request-header name="'X-XACML-Authorization'" value="'Basic ZnJlZDpmbGludHN0b25l'"/>
        - This stylesheet can pass arbitrary SOAP headers to the external PDP 
          if the XACML request will be wrapped in a SOAP message. This is done
          by outputing an element on the same level of the <xacml-context:Request/>,
          for example, the following lines will add a wsa:To SOAP header in the
          SOAP request to the external XACML PDP.

              <SoapHeader>
                 <wsa:To>The external PDP.</wsa:To>
              </SoapHeader>
              <xacml-context:Request>
              ...
              </xacml-context:Request>
          
                      

      This stylesheet demonstrates how to extract the AAA information and
      map them into XACML context request message. 
      The mapping obeys the following rules:

      1. The AttributeId URI, if it is not one of the spec constants, always 
         starts with 'urn:ibm:names:datapower:xs:aaa:', followed by the string 
         identifying AAA source.
    
      XACML Subject mapping:
      =====================

      2. MC result mapping:
        - MC method is mapped to Subject Attribute "urn:ibm:names:datapower:xs:aaa:mc-method"
        - Each sub-element of MC result <entry>, including the 'custom' MC method, is mapped 
          to a Subject attribute, with
         attribute id: "urn:ibm:names:datapower:xs:aaa:mapped-credential:<mc-method>:<element-localname>"
         attribute value: the serialized copy of the child element.
         attribute datatype: "http://www.w3.org/2001/XMLSchema#string"
        - If MC method is "none", the MC result is ignored.

      3. AU result mapping:
        - AU method is mapped to Subject Attribute "urn:ibm:names:datapower:xs:aaa:au-method"
        - Each AU method output is mapped specially.
      
      4. EI result mapping:
        - AU method is mapped to Subject Attribute "urn:ibm:names:datapower:xs:aaa:au-method"
        - If the EI result contains SAML Assertion (for certain SAML EI methods), this stylesheet will
          map the SAML Attribute to XACML Subject Attribute.
          attribute id: "urn:ibm:names:datapower:xs:aaa:identity::<ei-type>:attr:<attr-name>
          attribute value: the text value of the saml attribute item
          attribute datatype: "http://www.w3.org/2001/XMLSchema#string"
        - For all the other EI method, each sub-element of EI result <entry> is mapped 
          to a Subject attribute, with
         attribute id: "urn:ibm:names:datapower:xs:aaa:identity:<ei-method>:<element-localname>"
         attribute value: the serialized copy of the child element.
         attribute datatype: "http://www.w3.org/2001/XMLSchema#string"

      XACML Resource mapping:
      =====================

      5. MR result mapping:
        - MR method is mapped to Resource Attribute "urn:ibm:names:datapower:xs:aaa:mr-method"
        - Each sub-element of MR result <entry>, including the 'custom' MR method, is mapped 
          to a Resource attribute, with
                      <xsl:when test="$childname = 'target-url' or
                                      $childname = 'original-url' or
                                      $childname = 'request-uri'">
         attribute id: "urn:ibm:names:datapower:xs:aaa:mapped-resource:<mr-method>:<element-localname>"
         attribute value: the string value of the target/original/request-url, or the serialized 
                          copy of the child element.
         attribute datatype: "http://www.w3.org/2001/XMLSchema#string"
        - If MR method is "none", the MR result is ignored.

      6. ER result mapping:
        - ER method is mapped to Resource Attribute "urn:ibm:names:datapower:xs:aaa:er-method"
        - For all the ER methods, each sub-element of ER result <item> is mapped 
          to a Subject attribute, with
                  <xsl:when test="$er-type = 'request-opname' or
                                  $er-type = 'xpath' or
                                  $er-type = 'http-method'">
         attribute id: "urn:ibm:names:datapower:xs:aaa:resource:<er-method>:<element-localname>"
         attribute value: the value of the child element.
         attribute datatype: "http://www.w3.org/2001/XMLSchema#string" or 
                             "http://www.w3.org/2001/XMLSchema#anyURI"

      XACML Action mapping:
      =====================
      7.      AAA does not specifically provide information regarding actions, 
              so there is no direct mapping. This sample stylesheet has provided the following:
              - http-method (GET/POST/etc), if the request is in HTTP/s, and 
              - If the request-opname and request-url ER are used, we will also
                output the opname action, and action namespace.

      XACML Environment mapping:
      ==========================
      8.      AAA does not specifically provide information regarding access control 
              environment information, so there is no direct mapping.

              This sample stylesheet has provided the following:
                - current system date time.
      -->

    <xsl:include href="store:///utilities.xsl" dp:ignore-multiple="yes"/>

    <xsl:include href="store:///dp/aaa-xacml-context.xsl" dp:ignore-multiple="yes"/>

    <xsl:variable name="___xacml_ns_uri___">
      <xsl:choose>
        <xsl:when test="$dpxacml:xacml-version &lt; 2">urn:oasis:names:tc:xacml:1.0:policy</xsl:when>
        <xsl:otherwise>urn:oasis:names:tc:xacml:2.0:policy:schema:os</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="___xacml-context_ns_uri___">
      <xsl:choose>
        <xsl:when test="$dpxacml:xacml-version &lt; 2">urn:oasis:names:tc:xacml:1.0:context</xsl:when>
        <xsl:otherwise>urn:oasis:names:tc:xacml:2.0:context:schema:os</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <dp:dynamic-namespace prefix="xacml" select="$___xacml_ns_uri___"/>
    <dp:dynamic-namespace prefix="xacml-context" select="$___xacml-context_ns_uri___"/>

    <xsl:template match="/">
      <xsl:message dp:priority="debug">IBM XACML Demo PEP input : <dp:serialize select="."/></xsl:message>
      <xsl:message dp:priority="debug">IBM XACML Demo PEP $dpxacml:xacml-version : <xsl:value-of 
                                  select="$dpxacml:xacml-version"/></xsl:message>
      <xsl:message dp:priority="debug">IBM XACML Demo PEP $dpxacml:identity : <dp:serialize 
                                  select="$dpxacml:identity"/></xsl:message>
      <xsl:message dp:priority="debug">IBM XACML Demo PEP $dpxacml:credentials : <dp:serialize 
                                  select="$dpxacml:credentials"/></xsl:message>
      <xsl:message dp:priority="debug">IBM XACML Demo PEP $dpxacml:mapped-credentials : <dp:serialize 
                                  select="$dpxacml:mapped-credentials"/></xsl:message>
      <xsl:message dp:priority="debug">IBM XACML Demo PEP $dpxacml:resource : <dp:serialize 
                                  select="$dpxacml:resource"/></xsl:message>
      <xsl:message dp:priority="debug">IBM XACML Demo PEP $dpxacml:mapped-resource : <dp:serialize 
                                  select="$dpxacml:mapped-resource"/></xsl:message>
      <xsl:message dp:priority="debug">IBM XACML Demo PEP xacml ns uri : <xsl:value-of 
                                  select="$___xacml_ns_uri___"/></xsl:message>
      <xsl:message dp:priority="debug">IBM XACML Demo PEP xacml-context ns uri : <xsl:value-of 
                                  select="$___xacml-context_ns_uri___"/></xsl:message>

      <!-- usually, customization starts here. -->

      <!-- The HTTP Headers to the external PDP. -->
      <dp:set-request-header name="'X-XACML-SOAPAction'" value="'http://tempuri.org/Echo'"/>
      <dp:set-request-header name="'X-XACML-Authorization'" value="'Basic ZnJlZDpmbGludHN0b25l'"/>

      <!-- The SOAP Headers to the external PDP. -->
      <SoapHeader>
         <wsa:To xmlns:wsa="http://www.w3.org/2005/08/addressing">The external PDP.</wsa:To>
      </SoapHeader>
      
      <xsl:variable name = "customized-request">
        <xacml-context:Request>
          <!--===================================================
              Starting here for the XACML Subject attributes
              ===================================================-->

          <!-- Put the mapped Credential, Credentials or Identity info as Subject attribute. -->
          <xacml-context:Subject>

            <!--*************************************************
                Starting here, use the MC result as subject. 
                **************************************************-->

            <xsl:variable name="mc-method" select="$dpxacml:mapped-credentials/@type"/>
            <xsl:message dp:priority="debug">MC method : <xsl:value-of select="$mc-method"/></xsl:message>

            <xacml-context:Attribute
              AttributeId="urn:ibm:names:datapower:xs:aaa:mc-method"
              DataType="http://www.w3.org/2001/XMLSchema#string">
                <xacml-context:AttributeValue><xsl:value-of select="$mc-method"/></xacml-context:AttributeValue>
            </xacml-context:Attribute>

            <xsl:choose>
              <xsl:when test="$dpxacml:mapped-credentials/@au-success = 'false'">
                <xsl:message dp:priority="debug">No XACML attribute is applicable for user is not authenticated.</xsl:message>
              </xsl:when>

              <xsl:when test="$mc-method != 'none'">
                <!-- all the other MC methods come here, for all the sub elements
                    each child will be output as one Subject Attribute. -->
                <xsl:for-each select="$dpxacml:mapped-credentials/entry/*">
                  <xsl:variable name="childname" select="local-name()"/>
                  <xsl:variable name="datatype">
                    <xsl:choose>
                        <xsl:when test="$childname='username' or
                                        $childname='dn'">urn:oasis:names:tc:xacml:1.0:data-type:x500Name</xsl:when>
                        <xsl:otherwise>http://www.w3.org/2001/XMLSchema#string</xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  <xacml-context:Attribute>
                      <xsl:attribute name="AttributeId">
                        <xsl:value-of select="concat('urn:ibm:names:datapower:xs:aaa:mapped-credential:', $mc-method, ':', $childname)"/>
                      </xsl:attribute>
                      <xsl:attribute name="DataType"><xsl:value-of select="$datatype"/></xsl:attribute>
                      <xacml-context:AttributeValue><dp:serialize select="."/></xacml-context:AttributeValue>
                  </xacml-context:Attribute>
                </xsl:for-each>
              </xsl:when>
            </xsl:choose>

            <!--*************************************************
                Starting here, use the AU result as subject. 
                **************************************************-->
            <xsl:variable name="au-method" select="$dpxacml:credentials/entry/@type"/>
            <xsl:message dp:priority="debug">AU method : <xsl:value-of select="$au-method"/></xsl:message>
            <xsl:variable name="au-credential" select="$dpxacml:credentials/entry"/>
            <xsl:message dp:priority="debug">AU credential : <dp:serialize select="$au-credential"/></xsl:message>
            
            <xacml-context:Attribute
              AttributeId="urn:ibm:names:datapower:xs:aaa:au-method"
              DataType="http://www.w3.org/2001/XMLSchema#string">
                <xacml-context:AttributeValue><xsl:value-of select="$au-method"/></xacml-context:AttributeValue>
            </xacml-context:Attribute>

            <xsl:choose>
              <xsl:when test="$au-method = 'xmlfile'">
                <xacml-context:Attribute
                      AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id"
                      DataType="http://www.w3.org/2001/XMLSchema#string">
                    <xacml-context:AttributeValue><xsl:value-of select="$au-credential/*[local-name()='OutputCredential']"/></xacml-context:AttributeValue>
                </xacml-context:Attribute>
              </xsl:when>

              <xsl:when test="$au-method = 'ldap' or
                              $au-method = 'tivoli' or
                              $au-method = 'client-ssl'">
                <xacml-context:Attribute
                      AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id"
                      DataType="urn:oasis:names:tc:xacml:1.0:data-type:x500Name">
                    <xacml-context:AttributeValue><xsl:value-of select="$au-credential"/></xacml-context:AttributeValue>
                </xacml-context:Attribute>
              </xsl:when>

              <xsl:when test="$au-method = 'netegrity'">
                <xacml-context:Attribute
                      AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id"
                      DataType="http://www.w3.org/2001/XMLSchema#string">
                    <xacml-context:AttributeValue><xsl:value-of select="$au-credential/username"/></xacml-context:AttributeValue>
                </xacml-context:Attribute>
              </xsl:when>

              <xsl:when test="$au-method = 'radius'">
                <xacml-context:Attribute
                      AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id"
                      DataType="http://www.w3.org/2001/XMLSchema#string">
                    <xacml-context:AttributeValue><xsl:value-of select="$au-credential"/></xacml-context:AttributeValue>
                </xacml-context:Attribute>
              </xsl:when>

              <xsl:when test="$au-method = 'validate-signer'">
                <xacml-context:Attribute
                      AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id"
                      DataType="urn:oasis:names:tc:xacml:1.0:data-type:x500Name">
                    <xacml-context:AttributeValue><xsl:value-of select="$au-credential/CertificateDetails/Subject"/></xacml-context:AttributeValue>
                </xacml-context:Attribute>
                <xacml-context:Attribute
                  AttributeId="urn:ibm:names:datapower:xs:aaa:certificate:SerialNumber"
                  DataType="http://www.w3.org/2001/XMLSchema#string">
                    <xacml-context:AttributeValue><xsl:value-of select="$au-credential/CertificateDetails/SerialNumber"/></xacml-context:AttributeValue>
                </xacml-context:Attribute>
                <xacml-context:Attribute
                  AttributeId="urn:ibm:names:datapower:xs:aaa:certificate:SignatureAlgorithm"
                  DataType="http://www.w3.org/2001/XMLSchema#string">
                    <xacml-context:AttributeValue><xsl:value-of select="$au-credential/CertificateDetails/SignatureAlgorithm"/></xacml-context:AttributeValue>
                </xacml-context:Attribute>
                <xacml-context:Attribute
                  AttributeId="urn:ibm:names:datapower:xs:aaa:certificate:issuer"
                  DataType="urn:oasis:names:tc:xacml:1.0:data-type:x500Name">
                    <xacml-context:AttributeValue><xsl:value-of select="$au-credential/CertificateDetails/Issuer"/></xacml-context:AttributeValue>
                </xacml-context:Attribute>
                <xacml-context:Attribute
                  AttributeId="urn:ibm:names:datapower:xs:aaa:certificate:NotBefore"
                  DataType="http://www.w3.org/2001/XMLSchema#dateTime">
                    <xacml-context:AttributeValue><xsl:value-of select="$au-credential/CertificateDetails/NotBefore"/></xacml-context:AttributeValue>
                </xacml-context:Attribute>
                <xacml-context:Attribute
                  AttributeId="urn:ibm:names:datapower:xs:aaa:certificate:NotAfter"
                  DataType="http://www.w3.org/2001/XMLSchema#dateTime">
                    <xacml-context:AttributeValue><xsl:value-of select="$au-credential/CertificateDetails/NotAfter"/></xacml-context:AttributeValue>
                </xacml-context:Attribute>
                <xacml-context:Attribute
                  AttributeId="urn:ibm:names:datapower:xs:aaa:certificate:SubjectPublicKeyAlgorithm"
                  DataType="http://www.w3.org/2001/XMLSchema#string">
                    <xacml-context:AttributeValue><xsl:value-of select="$au-credential/CertificateDetails/SubjectPublicKeyAlgorithm"/></xacml-context:AttributeValue>
                </xacml-context:Attribute>
              </xsl:when>

              <xsl:when test="$au-method = 'saml'">
                <xacml-context:Attribute
                      AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id"
                      DataType="http://www.w3.org/2001/XMLSchema#string">
                    <xacml-context:AttributeValue><xsl:copy-of select="$au-credential"/></xacml-context:AttributeValue>
                </xacml-context:Attribute>
              </xsl:when>

              <xsl:when test="$au-method = 'token'">
                <xacml-context:Attribute
                      AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id"
                      DataType="http://www.w3.org/2001/XMLSchema#string">
                    <xacml-context:AttributeValue><xsl:copy-of select="$au-credential"/></xacml-context:AttributeValue>
                </xacml-context:Attribute>
              </xsl:when>

              <xsl:when test="$au-method = 'ws-trust'">
                <xacml-context:Attribute
                      AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id"
                      DataType="http://www.w3.org/2001/XMLSchema#string">
                    <xacml-context:AttributeValue><xsl:copy-of select="$au-credential"/></xacml-context:AttributeValue>
                </xacml-context:Attribute>
              </xsl:when>

              <xsl:when test="$au-method = 'ws-secureconversation'">
                <xacml-context:Attribute
                      AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id"
                      DataType="http://www.w3.org/2001/XMLSchema#string">
                    <xacml-context:AttributeValue><xsl:copy-of select="$au-credential/context"/></xacml-context:AttributeValue>
                </xacml-context:Attribute>
              </xsl:when>

              <xsl:when test="$au-method = 'custom'">
                <!-- Hello, custom AU stylesheet. add it here please. -->
                <xacml-context:Attribute
                      AttributeId="NOT-PROCESSED"
                      DataType="http://www.w3.org/2001/XMLSchema#string">
                    <xacml-context:AttributeValue>NOT-PROCESSED</xacml-context:AttributeValue>
                </xacml-context:Attribute>
              </xsl:when>

              <xsl:otherwise>
                <xsl:message dp:priority="debug">No XACML attribute is applicable for the status with AU method '<xsl:value-of select="$au-method"/>'</xsl:message>
              </xsl:otherwise>
            </xsl:choose>

            <!--*************************************************
                Starting here, use the EI result as subject. 
                **************************************************-->
            <xsl:for-each select="$dpxacml:identity/entry">
              <xsl:variable name="ei-type" select="@type"/>
              <xsl:message dp:priority="debug">EI method : <xsl:value-of select="$ei-type"/></xsl:message>
              <xsl:message dp:priority="debug">Extracted Identities: <dp:serialize select="."/></xsl:message>

              <xsl:choose>
                <!-- SAML attributes can be utilized for XACML -->
                <xsl:when test="$ei-type = 'saml-attr-name' or
                                $ei-type = 'saml-authen-name'">
                  <xacml-context:Attribute
                        AttributeId="{concat('urn:ibm:names:datapower:xs:aaa:identity:', $ei-type, ':username')}"
                        DataType="urn:oasis:names:tc:xacml:1.0:data-type:x500Name">
                      <xacml-context:AttributeValue><xsl:value-of select="./username"/></xacml-context:AttributeValue>
                  </xacml-context:Attribute>
                  <!-- copy all the saml attributes -->
                  <xsl:for-each select="./attributes//*[local-name()='Attribute']">
                    <xsl:variable name="name" select="@Name"/>
                    <xsl:variable name="name-format" select="@NameFormat"/>
                    <xsl:variable name="value" select="/*[local-name()='AttributeValue'][1]"/>
                    <xacml-context:Attribute>
                        <xsl:attribute name="AttributeId">
                          <xsl:value-of select="concat('urn:ibm:names:datapower:xs:aaa:identity:',$ei-type,':attr:',$name)"/>
                        </xsl:attribute>
                        <xsl:attribute name="DataType">http://www.w3.org/2001/XMLSchema#string</xsl:attribute>
                        <xacml-context:AttributeValue><xsl:copy-of select="$value"/></xacml-context:AttributeValue>
                    </xacml-context:Attribute>
                  </xsl:for-each>
                </xsl:when>
                
                <!-- all the other EI methods come here -->
                <xsl:otherwise>
                    <xsl:for-each select="*">
                      <xsl:variable name="childname" select="local-name()"/>
                      <xsl:variable name="datatype">
                        <xsl:choose>
                            <xsl:when test="$childname='username' or
                                            $childname='dn' or
                                            $childname='issuer'">urn:oasis:names:tc:xacml:1.0:data-type:x500Name</xsl:when>
                            <xsl:when test="$childname='ip-address'">urn:oasis:names:tc:xacml:1.0:data-type:ipAddress</xsl:when>
                            <xsl:when test="$childname='nonce'">http://www.w3.org/2001/XMLSchema#base64Binary</xsl:when>
                            <xsl:when test="$childname='created'">http://www.w3.org/2001/XMLSchema#dateTime</xsl:when>
                            <xsl:when test="$childname='context'">http://www.w3.org/2001/XMLSchema#anyURI</xsl:when>
                            <xsl:otherwise>http://www.w3.org/2001/XMLSchema#string</xsl:otherwise>
                        </xsl:choose>
                      </xsl:variable>
                      <xacml-context:Attribute>
                          <xsl:attribute name="AttributeId">
                            <xsl:value-of select="concat('urn:ibm:names:datapower:xs:aaa:identity:', $ei-type, ':', $childname)"/>
                          </xsl:attribute>
                          <xsl:attribute name="DataType"><xsl:value-of select="$datatype"/></xsl:attribute>
                          <xacml-context:AttributeValue><xsl:value-of select="."/></xacml-context:AttributeValue>
                      </xacml-context:Attribute>
                    </xsl:for-each>
                </xsl:otherwise>
                <!-- wssec-binary-token EI: 
                     this EI right now outputs the BinarySecurityToken whole set.
                     not good for xacml policy. EI should interpret it into meaning properties.

                     ws-trust EI: 
                     The sub-elements should be processed specially for more complicated use case.
                     -->
              </xsl:choose>
            </xsl:for-each>
          </xacml-context:Subject>

          <!--===================================================
              Starting here for the XACML Resource attributes
              ===================================================-->
          <!-- Put the mapped resource, resource info as XACML resource attributes. -->
          <xacml-context:Resource>
            <!--*************************************************
                Starting here, use MR result as Resource.
                **************************************************-->
            <xsl:variable name="mr-method" select="$dpxacml:mapped-resource/@type"/>
            <xsl:message dp:priority="debug">MR method : <xsl:value-of select="$mr-method"/></xsl:message>
            <xsl:message dp:priority="debug">Mapped Resource: <dp:serialize select="$dpxacml:mapped-resource/entry"/></xsl:message>
                  
            <xacml-context:Attribute
              AttributeId="urn:ibm:names:datapower:xs:aaa:mr-method"
              DataType="http://www.w3.org/2001/XMLSchema#string">
                <xacml-context:AttributeValue><xsl:value-of select="$mr-method"/></xacml-context:AttributeValue>
            </xacml-context:Attribute>

            <xsl:if test="$mr-method != 'none'">
              <!-- all the other MR methods come here, for all the sub elements
                  each child will be output as one Resource Attribute. -->
              <xsl:for-each select="$dpxacml:mapped-resource/entry/*">
                <xsl:variable name="childname" select="local-name()"/>
                <xacml-context:Attribute>
                    <xsl:attribute name="AttributeId">
                      <xsl:value-of select="concat('urn:ibm:names:datapower:xs:aaa:mapped-resource:', $mr-method, ':', $childname)"/>
                    </xsl:attribute>

                    <xsl:choose>
                      <xsl:when test="$childname = 'target-url' or
                                      $childname = 'original-url' or
                                      $childname = 'request-uri'">
                    <xsl:attribute name="DataType">http://www.w3.org/2001/XMLSchema#anyURI</xsl:attribute>
                    <xacml-context:AttributeValue><xsl:value-of select="."/></xacml-context:AttributeValue>
                      </xsl:when>
                      <xsl:otherwise>
                    <xsl:attribute name="DataType">http://www.w3.org/2001/XMLSchema#string</xsl:attribute>
                    <xacml-context:AttributeValue><dp:serialize select="."/></xacml-context:AttributeValue>
                      </xsl:otherwise>                            
                    </xsl:choose>
                </xacml-context:Attribute>
              </xsl:for-each>
            </xsl:if>

            <!--*************************************************
                Starting here, use the ER result as Resource.
                **************************************************-->
            <xsl:for-each select="$dpxacml:resource/item">
              <xsl:variable name="er-type" select="@type"/>
              <xsl:message dp:priority="debug">ER method : <xsl:value-of select="$er-type"/></xsl:message>
              <xsl:message dp:priority="debug">Extracted Resource: <dp:serialize select="."/></xsl:message>
              <xsl:element name="xacml-context:Attribute">
                <xsl:attribute name="AttributeId">urn:ibm:names:datapower:xs:aaa:resource:<xsl:value-of select="$er-type"/></xsl:attribute>
                <xsl:choose>
                  <xsl:when test="$er-type = 'request-opname' or
                                  $er-type = 'xpath' or
                                  $er-type = 'http-method'">

                    <xsl:attribute name="DataType">http://www.w3.org/2001/XMLSchema#string</xsl:attribute>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:attribute name="DataType">http://www.w3.org/2001/XMLSchema#anyURI</xsl:attribute>
                  </xsl:otherwise>                            
                </xsl:choose>
                <xacml-context:AttributeValue><xsl:value-of select="."/></xacml-context:AttributeValue>
              </xsl:element>
            </xsl:for-each>
          </xacml-context:Resource>

          <!--=================================================
              Starting here for the XACML Action attributes
              
              AAA does not specifically provide information regarding actions, 
              so there is no direct mapping. This sample stylesheet has provided the following:
              - http-method (GET/POST/etc), if the request is in HTTP/s, and 
              - If the request-opname and request-url ER are used, we will also
                output the opname action, and action namespace.
              
              =================================================-->
          <xacml-context:Action>
              <!-- add the request-opname as an action-id attribute, although it may not always mean that. -->
              <xsl:variable name="request-opname" select="string($dpxacml:resource/item[@type='request-opname'])"/>
              <xsl:if test="$request-opname != ''">
                <xacml-context:Attribute
                      AttributeId="urn:oasis:names:tc:xacml:1.0:action:action-id"
                      DataType="http://www.w3.org/2001/XMLSchema#string">
                    <xacml-context:AttributeValue><xsl:value-of select="$request-opname"/></xacml-context:AttributeValue>
                </xacml-context:Attribute>
              </xsl:if>

              <!-- add the request-uri as an action-namespace attribute, although it may not always mean that. -->
              <xsl:variable name="request-uri" select="string($dpxacml:resource/item[@type='request-uri'])"/>
              <xsl:if test="$request-uri != ''">
                <xacml-context:Attribute
                      AttributeId="urn:oasis:names:tc:xacml:1.0:action:action-namespace"
                      DataType="http://www.w3.org/2001/XMLSchema#string">
                    <xacml-context:AttributeValue><xsl:value-of select="$request-uri"/></xacml-context:AttributeValue>
                </xacml-context:Attribute>
              </xsl:if>

              <!-- add the http method name (if http request) as an action attribute, although it does not mean that. -->
              <xacml-context:Attribute
                    AttributeId="urn:ibm:names:datapower:xs:aaa:http-method"
                    DataType="http://www.w3.org/2001/XMLSchema#string">
                  <xacml-context:AttributeValue><xsl:value-of select="dp:http-request-method()"/></xacml-context:AttributeValue>
              </xacml-context:Attribute>
          </xacml-context:Action>

          <!--=================================================
              Starting here for the XACML Environment attributes
              
              AAA does not specifically provide information regarding access control 
              environment information, so there is no direct mapping.

              This sample stylesheet has provided the following:
                - current system date time.
              =================================================-->
          <xacml-context:Environment>
            <xacml-context:Attribute
                  AttributeId="urn:oasis:names:tc:xacml:1.0:environment:current-dateTime"
                  DataType="http://www.w3.org/2001/XMLSchema#dateTime">
                <xacml-context:AttributeValue><xsl:copy-of select="dpfunc:zulu-time()"/></xacml-context:AttributeValue>
            </xacml-context:Attribute>
          </xacml-context:Environment>
              <xsl:message dp:priority="debug">date time: <xsl:copy-of select="dpfunc:zulu-time()"/></xsl:message>
      </xacml-context:Request>
    </xsl:variable>
    <!-- usually, customization ends here. -->

    <xsl:copy-of select="$customized-request"/>
  </xsl:template>
</xsl:stylesheet>
