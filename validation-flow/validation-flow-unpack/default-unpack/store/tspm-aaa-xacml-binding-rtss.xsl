<?xml version="1.0" encoding="UTF-8"?>

<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2008,2013. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->


<!--
  FILENAME:
    tspm-aaa-xacml-binding-rtss.xsl
  DESCRIPTION:
    The AAA Policy authorization phase can be configured to use this
    custom XACML binding stylesheet. This stylesheet will extract the
    attribute information and place it in the XACML <Request> under the
    <Subject>.

    This stylesheet can be used without modifications.

  DETAILS:
    This style sheet is designed to map AAA results to a
    <xacml-context:Request/>, aka xacml context request message. 

    This stylesheet is designed to be called following processing for the
    AAA Policy  EI, AU, MC, ER, MR steps. 

    Information that flows from the previous AAA steps is passed into this
    stylesheet as xsl parameters as 'store:///dp/aaa-xacml-context.xsl'
    is included in this stylesheet.

    Those parameters include but are not limited to:
        dpxacml:xacml-version      The XACML version of the request context
        dpxacml:identity           The result of EI step.
        dpxacml:credentials        The result of AU step.
        dpxacml:mapped-credentials The result of MC step.
        dpxacml:resource           The result of ER step.
        dpxacml:mapped-resource    The result of MR step.

-->


<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dp="http://www.datapower.com/extensions"
                xmlns:dpfunc="http://www.datapower.com/extensions/functions"
                xmlns:dpquery="http://www.datapower.com/param/query"
                xmlns:dpconfig="http://www.datapower.com/param/config"
                xmlns:dpxacml="urn:ibm:names:datapower:xacml:2.0"
                xmlns:func="http://exslt.org/functions"
                xmlns:dyn="http://exslt.org/dynamic"
                xmlns:xacml="urn:oasis:names:tc:xacml:2.0:policy:schema:os"
                xmlns:xacml-context="urn:oasis:names:tc:xacml:2.0:context:schema:os"
                xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
                xmlns:wsa="http://www.w3.org/2005/08/addressing"
                xmlns:str="http://exslt.org/strings"
                exclude-result-prefixes="dp dpfunc dpquery dpconfig dpxacml func dyn xacml xacml-context" 
                extension-element-prefixes="dp dpfunc"
                version="1.0">

<!-- =================== START ADMIN-EDITABLE SECTION! ==================== -->

    <xsl:variable name="fullyQualifyServiceName">false</xsl:variable>

<!-- =================== END ADMIN-EDITABLE SECTION! ==================== -->

    <xsl:include href="store:///utilities.xsl"/>
    <xsl:include href="store:///dp/aaa-xacml-context.xsl"/>
    <xsl:include href="store:///dp/msgcat/crypto.xml.xsl"/>

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
        <xsl:message dp:priority="debug">IBM TSPM PEP input : <dp:serialize select="."/></xsl:message>
        <xsl:message dp:priority="debug">IBM TSPM PEP $dpxacml:xacml-version : <xsl:value-of select="$dpxacml:xacml-version"/>
        </xsl:message>
        <xsl:message dp:priority="debug">IBM TSPM PEP $dpxacml:identity : <dp:serialize select="$dpxacml:identity"/>
        </xsl:message>
        <xsl:message dp:priority="debug">IBM TSPM PEP $dpxacml:credentials : <dp:serialize select="$dpxacml:credentials"/>
        </xsl:message>
        <xsl:message dp:priority="debug">IBM TSPM PEP $dpxacml:mapped-credentials : <dp:serialize select="$dpxacml:mapped-credentials"/>
        </xsl:message>
        <xsl:message dp:priority="debug">IBM TSPM PEP $dpxacml:resource : <dp:serialize select="$dpxacml:resource"/>
        </xsl:message>
        <xsl:message dp:priority="debug">IBM TSPM PEP $dpxacml:mapped-resource : <dp:serialize select="$dpxacml:mapped-resource"/>
        </xsl:message>
        <xsl:message dp:priority="debug">IBM XACML TSPM xacml ns uri : <xsl:value-of select="$___xacml_ns_uri___"/>
        </xsl:message>
        <xsl:message dp:priority="debug">IBM XACML TSPM xacml-context ns uri : <xsl:value-of select="$___xacml-context_ns_uri___"/>
        </xsl:message>
        <xsl:variable name="customized-request">
            <!-- Define all the variables required for RTSS -->
            <xsl:variable name="resource-id" select="dp:variable('var://service/URL-out')"/>
            <xsl:variable name="service" select="dp:variable('var://service/wsm/service')"/>
            <xsl:variable name="service-port" select="dp:variable('var://service/wsm/back-service-port')"/>
            <xsl:variable name="operation" select="dp:variable('var://service/wsm/back-operation')"/>
            <xsl:variable name="wsdl-namespace" select="substring-before( substring-after( $service, '{'), '}' )"/>
            <xsl:message dp:priority="debug">WSDL namespace: <xsl:value-of select="$wsdl-namespace"/></xsl:message>
            <xsl:variable name="service-name" select="substring-after( $service, '}' )" />
            <xsl:variable name="soap-action" select="translate(dp:request-header('SOAPAction'), '&quot;', '')"/>
            <xsl:variable name="soap12-action" select="substring-after(translate(dp:http-request-header('Content-type'), '&quot;', ''), 'action=')"/>
            <xsl:variable name="wsa-action" select="//wsa:Action/text()"/>
            <xacml-context:Request>
                <!--===================================================
                    Starting here for the XACML Subject attributes
                    ===================================================
                -->
                <!-- Put the mapped Credential, Credentials or Identity info
                     as Subject attribute.
                -->
                <xacml-context:Subject SubjectCategory="urn:oasis:names:tc:xacml:1.0:subject-category:access-subject">
                <!--*************************************************
                    Starting here, use the MC result as subject. 
                    **************************************************
                -->
                    <xsl:choose>
                        <xsl:when test="$dpxacml:mapped-credentials/@au-success = 'false'">
                            <xsl:message dp:type="crypto" dp:priority="error" dp:id="{$DPLOG_TIVOLI_TSPMUSERNOTAUTHENTICATED}"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message dp:priority="debug">Serializing mapped credentials as XACML subject.</xsl:message>
                            <xsl:for-each select="$dpxacml:mapped-credentials/entry">
                            <!-- 
                               There's a few special cases we have to handle,
                               such as XMLfile authentication, and extracting
                               attributes from a SAML assertion
                            -->
                                <xsl:choose>
                                    <xsl:when test="@type='saml-attributes'">
                                        <xsl:call-template name="serialize-saml-attributes"/>
                                    </xsl:when>

                                    <xsl:when test="@type='kerberos-principal-dn'">
                                        <xacml-context:Attribute AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id" DataType="http://www.w3.org/2001/XMLSchema#string">
                                            <xacml-context:AttributeValue>
                                                <xsl:value-of select="."/>
                                            </xacml-context:AttributeValue>
                                        </xacml-context:Attribute>
                                    </xsl:when>

                                    <xsl:when test="@type='kerberos-principal'">
                                        <xacml-context:Attribute AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id" DataType="http://www.w3.org/2001/XMLSchema#string">
<!--
                                        <xacml-context:Attribute AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id" DataType="urn:oasis:names:tc:xacml:1.0:data-type:rfc822Name">
-->
                                            <xacml-context:AttributeValue>
                                                <xsl:value-of select="."/>
                                            </xacml-context:AttributeValue>
                                        </xacml-context:Attribute>
                                    </xsl:when>

                                    <xsl:when test="@type='kerberos-attributes'">
                                        <xsl:variable name="krb-attrs" select="."/>
                                        <xsl:call-template name="serialize-krb-attributes"/>
                                        <xsl:message dp:priority="debug">Found kerberos attrs: <xsl:value-of select="$krb-attrs"/></xsl:message>
                                    </xsl:when>

                                    <xsl:when test="@type='ldap-attributes'">
                                        <xsl:variable name="ldap-attrs" select="."/>
                                        <xsl:call-template name="serialize-ldap-attributes"/>
                                        <xsl:message dp:priority="debug">Found ldap attrs: <xsl:value-of select="$ldap-attrs"/></xsl:message>
                                    </xsl:when>

                                    <!-- BST from message, selected via XPath -->
                                    <xsl:when test="@type='token'">
                                        <xsl:variable name="subject-dn" select="dp:get-cert-subject(concat('cert:', text()))"/>
                                        <xsl:message dp:priority="debug">Found subject-dn: <xsl:value-of select="$subject-dn"/></xsl:message>
                                        <xacml-context:Attribute AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id" DataType="http://www.w3.org/2001/XMLSchema#string">
                                            <xacml-context:AttributeValue>
                                                <xsl:value-of select="$subject-dn"/>
                                            </xacml-context:AttributeValue>
                                        </xacml-context:Attribute>
                                    </xsl:when>
                                    <!-- Validated BST Element from WS-Security Header -->
                                    <xsl:when test="@type='validate-signer'">
                                        <xsl:variable name="subject-id" select="./CertificateDetails/Subject"/>
                                        <xsl:message dp:priority="debug">
                                            Found user: <xsl:value-of select="$subject-id"/>
                                        </xsl:message>
                                        <xsl:variable name="new-subject-id">
                                            <!-- Convert the big-endian comma-delimited X500 DN to LDAP RDN -->
                                            <xsl:call-template name="convert-dn">
                                                <xsl:with-param name="originalDN" select="$subject-id"/>
                                            </xsl:call-template>
                                        </xsl:variable>
                                        <xsl:message dp:priority="debug">
                                            Converted subject id: <xsl:value-of select="$new-subject-id"/>
                                        </xsl:message>                                       
                                        <xacml-context:Attribute
                                            AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id"
                                            DataType="http://www.w3.org/2001/XMLSchema#string">
                                            <xacml-context:AttributeValue>
                                                <xsl:value-of select="$new-subject-id"/>
                                            </xacml-context:AttributeValue>
                                        </xacml-context:Attribute>
                                    </xsl:when>
                                    <!-- Client certificate from SSL connection -->
                                    <xsl:when test="@type='client-ssl'">
                                        <xsl:variable name="subject-id" select="dp:auth-info('ssl-client-subject', 'ldap')"/>
                                        <xsl:message dp:priority="debug">
                                            Found user: <xsl:value-of select="$subject-id"/>
                                        </xsl:message>
                                        <xacml-context:Attribute
                                            AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id"
                                            DataType="http://www.w3.org/2001/XMLSchema#string">
                                            <xacml-context:AttributeValue>
                                                <xsl:value-of select="$subject-id"/>
                                            </xacml-context:AttributeValue>
                                        </xacml-context:Attribute>
                                    </xsl:when>
                                    <xsl:when test="@type='ws-secureconversation'">
                                        <xacml-context:Attribute
                                            AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id"
                                            DataType="http://www.w3.org/2001/XMLSchema#string">
                                            <xacml-context:AttributeValue>
                                                <xsl:copy-of select="./context"/>
                                            </xacml-context:AttributeValue>
                                        </xacml-context:Attribute>
                                    </xsl:when>
                                    <xsl:when test="@type='xmlfile'">
                                        <xacml-context:Attribute
                                            AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id"
                                            DataType="http://www.w3.org/2001/XMLSchema#string">
                                            <xacml-context:AttributeValue>
                                                <xsl:value-of select="./*[local-name()='OutputCredential']"/>
                                            </xacml-context:AttributeValue>
                                        </xacml-context:Attribute>
                                    </xsl:when>

                                    <!-- We don't want the 'saml' node, all of
                                         the relevant data is either in
                                         'saml-nameid' or 'saml-attributes'
                                    -->
                                    <xsl:when test="@type='saml'">
                                    </xsl:when>

                                    <!-- Extract the SAML NameID entry -->
                                    <xsl:when test="@type='saml-nameid'">
                                        <xacml-context:Attribute
                                            AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id"
                                            DataType="http://www.w3.org/2001/XMLSchema#string">
                                        <!-- Check the Format of the NameID
                                             If 'X509Subject', treat as a LDAP
                                             RDN, as defined by the SAML spec
                                        -->
                                        <xsl:choose>
                                            <xsl:when test="//@Format='urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName'">
                                                <xsl:variable name="subject-dn">
                                                    <xsl:call-template name="new-convert-dn">
                                                        <xsl:with-param name="originalDN" select="*[@Format]"/> 
                                                    </xsl:call-template>
                                                </xsl:variable>
                                                <xsl:message dp:priority="debug">
                                                    Found user: <xsl:value-of select="$subject-dn"/>
                                                </xsl:message>
                                                        
                                                <xacml-context:AttributeValue>
                                                   <xsl:value-of select="$subject-dn"/>
                                                </xacml-context:AttributeValue>
                                             </xsl:when>
                                             <xsl:otherwise>
                                                <xsl:message dp:priority="debug">
                                                    Found user: <xsl:value-of select="*[@Format]"/>
                                                </xsl:message>
                                                <xacml-context:AttributeValue>
                                                   <xsl:value-of select="*[@Format]"/>
                                                </xacml-context:AttributeValue>
                                             </xsl:otherwise>
                                        </xsl:choose> 
                                        </xacml-context:Attribute>
                                    </xsl:when>
                                    <!-- For every other case though, we assume that the child of entry is a text() node containing the username -->
                                    <xsl:otherwise>
                                        <xsl:variable name="childname" select="local-name()"/>
                                        <xsl:message dp:priority="debug">
                                            Found user: <xsl:value-of select="."/>
                                        </xsl:message>
                                        <xacml-context:Attribute AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id"
                                                                 DataType="http://www.w3.org/2001/XMLSchema#string">
                                            <xacml-context:AttributeValue>
                                                <xsl:value-of select="text()"/>
                                            </xacml-context:AttributeValue>
                                        </xacml-context:Attribute>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                </xacml-context:Subject>
                <xsl:call-template name="add-audit-subject"/>
                <!--===================================================
                    Starting here for the XACML Resource attributes
                   ===================================================-->
                <!-- Put the mapped resource, resource info as XACML resource attributes. -->
                <xacml-context:Resource>
                    <!-- ResourceContent must go first -->
                    <xacml-context:ResourceContent>
                       <xsl:copy-of select="./*[local-name()='Envelope']/*[local-name()='Body']/*"/>
                    </xacml-context:ResourceContent>
                    <xacml-context:Attribute AttributeId="urn:oasis:names:tc:xacml:1.0:resource:resource-id" 
                                             DataType="http://www.w3.org/2001/XMLSchema#anyURI">
                        <xacml-context:AttributeValue>
                            <xsl:value-of select="$resource-id"/>
                        </xacml-context:AttributeValue>
                    </xacml-context:Attribute>
                    <xsl:if test="$service != 'var://service/wsm/service'">
                        <xacml-context:Attribute AttributeId="urn:ibm:xacml:profiles:web-services:1.0:wsdl:1.1:service" 
                                                 DataType="http://www.w3.org/2001/XMLSchema#string">
                            <xacml-context:AttributeValue>
                                <xsl:value-of select="$service"/>
                            </xacml-context:AttributeValue>
                        </xacml-context:Attribute>
                    </xsl:if>
                    <xsl:if test="$service-port != 'var://service/wsm/service-port'">
                        <xacml-context:Attribute AttributeId="urn:ibm:xacml:profiles:web-services:1.0:wsdl:1.1:port" 
                                                 DataType="http://www.w3.org/2001/XMLSchema#string">
                            <xacml-context:AttributeValue>
                                <xsl:value-of select="$service-port"/>
                            </xacml-context:AttributeValue>
                        </xacml-context:Attribute>
                    </xsl:if>
                    <xsl:if test="$operation != 'var://service/wsm/operation'">
                        <xacml-context:Attribute AttributeId="urn:ibm:xacml:profiles:web-services:1.0:wsdl:1.1:operation" 
                                                 DataType="http://www.w3.org/2001/XMLSchema#string">
                            <xacml-context:AttributeValue>
                                <xsl:value-of select="$operation"/>
                            </xacml-context:AttributeValue>
                        </xacml-context:Attribute>
                    </xsl:if>
                </xacml-context:Resource>
                <!--=================================================
                    Starting here for the XACML Action attributes
                    =================================================-->
                <xacml-context:Action>
                    <xsl:choose>
                        <xsl:when test="$wsa-action != ''">
                            <xacml-context:Attribute AttributeId="urn:oasis:names:tc:xacml:1.0:action:action-id" 
                                                     DataType="http://www.w3.org/2001/XMLSchema#anyURI">
                                <xacml-context:AttributeValue>
                                    <xsl:value-of select="$wsa-action"/>
                                </xacml-context:AttributeValue>
                            </xacml-context:Attribute>
                        </xsl:when>
                        <xsl:when test="$soap12-action != ''">
                            <dp:set-request-header name="'X-XACML-SOAPAction'" value="$soap12-action"/>

                            <xacml-context:Attribute AttributeId="urn:oasis:names:tc:xacml:1.0:action:action-id"
                                                     DataType="http://www.w3.org/2001/XMLSchema#anyURI">
                                <xacml-context:AttributeValue>
                                    <xsl:value-of select="$soap12-action"/>
                                </xacml-context:AttributeValue>
                            </xacml-context:Attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <dp:set-request-header name="'X-XACML-SOAPAction'" value="$soap-action"/>
                            <xacml-context:Attribute AttributeId="urn:oasis:names:tc:xacml:1.0:action:action-id" 
                                                     DataType="http://www.w3.org/2001/XMLSchema#anyURI">
                                <xacml-context:AttributeValue>
                                    <xsl:value-of select="$soap-action"/>
                                </xacml-context:AttributeValue>
                            </xacml-context:Attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                </xacml-context:Action>
                <!--=================================================
                    Starting here for the XACML Environment attributes
                    =================================================-->
                <xacml-context:Environment>
                <!-- Add the RTSS-required context information, seeing as we can't really modify the SOAP header -->
                    <xacml-context:Attribute AttributeId="ContextId" 
                                             DataType="http://www.w3.org/2001/XMLSchema#string" 
                                             Issuer="http://security.tivoli.ibm.com/policy/distribution">
                        <xacml-context:AttributeValue>
                            <xsl:choose>
                                <xsl:when test="$fullyQualifyServiceName = 'true'">
                                        <xsl:variable name="context" select="concat( $wsdl-namespace, ':', $service-name )" />
                                        <xsl:value-of select="$context" />
                                </xsl:when>
                                <xsl:when test="$wsdl-namespace != ''">
                                    <xsl:variable name="context" select="$wsdl-namespace"/>
                                    <xsl:value-of select="$context"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:variable name="context" select="$resource-id"/>
                                    <xsl:value-of select="$context"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xacml-context:AttributeValue>
                    </xacml-context:Attribute>
                </xacml-context:Environment>
            </xacml-context:Request>
        </xsl:variable>
        <!-- if some customization is desired, usually it is limited to above this comment  -->
        <xsl:message dp:priority="debug">IBM TSPM Req : <dp:serialize select="$customized-request"/></xsl:message>

        <!-- SOAP 1.1 envelope wrapping so don't do it again in AZ tab of AAA Policy -->
        <xsl:variable name="wrapped-request">
            <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
                <soapenv:Header>
                   <!--  no SOAP headers required -->
                </soapenv:Header>
                <soapenv:Body>
                   <xsl:copy-of select="$customized-request"/>
                </soapenv:Body>
            </soapenv:Envelope>
        </xsl:variable>

        <xsl:variable name="wrap-with-soap" select="dp:parse(dp:variable('var://context/AAA/xacml-pep-policy'))/XACMLPEP/AZXACMLUseSOAP"/>
        <xsl:variable name="onbox" select="dp:parse(dp:variable('var://context/AAA/xacml-pep-policy'))/XACMLPEP/AZXACMLUseOnBoxPDP"/>

        <xsl:choose>
            <xsl:when test="$wrap-with-soap='off' and $onbox='off'">
                <xsl:copy-of select="$wrapped-request"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$customized-request"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Add information about the requesting machine, ie this DP box, for audit purposes -->
    <!-- 
          Example contents of the variable 'var://service/system/ident'
            <identification build="main.156596" timestamp="Fri Jul 14 16:57:51 2009 ">
                <product-id>9003-XI50-03</product-id>
                <product>XI50</product>
                <model>DataPower XI50</model>
                <device-name>xi50-2.dp.ibm.com</device-name>
                <serial-number>13009X3</serial-number>
                <firmware-version>XI50.3.8.0.0</firmware-version>
                <firmware-build>main.156596</firmware-build>
                <current-date>2009-07-14</current-date>
                <current-time>16:57:51 EST</current-time>
                <reset-date>2008-05-09</reset-date>
                <reset-time>08:26:57 EST</reset-time>
                <login-message />
                <custom-ui-file />
            </identification> 
            
            ... and the audit fields:
            sourceComponentId
                application=IBM DataPower
                component=DataPower XI50 PEP
                componentIdType="DeviceName" 
                executionEnvironment= <device-name> + <firmware-version>  xi50-2.dp.ibm.com-XI50.3.8.0.0
                instanceId=<device-name> + <serial-number>  xi50-2.dp.ibm.com-13009X3
                location="gc.au.ibm.com" //Handled by receiving web service
                locationType="Hostname"  // as above
                subComponent=<device-name>    "xi50-2.dp.ibm.com"
                componentType=" PEP"
            
            Prefix the above names with "http://rtss.tscc.ibm.com/audit/".
            
            //Instead of "subComponent" the information is under 'subject-id' as we need a subject-id field.
    -->
    <xsl:template name="add-audit-subject">
        <xsl:variable name="audit-attrid-prefix">http://rtss.tscc.ibm.com/audit/</xsl:variable>
        <xsl:variable name="requesting-machine" select="dp:variable('var://service/system/ident')"/>
        <xsl:variable name="application">IBM DataPower</xsl:variable>
        <xsl:variable name="device-name" select="$requesting-machine/identification/device-name/text()"/>
        <xsl:variable name="model" select="$requesting-machine/identification/model/text()"/>
        <xsl:variable name="serial-number" select="$requesting-machine/identification/serial-number/text()"/>
        <xsl:variable name="firmware-version" select="$requesting-machine/identification/firmware-version/text()"/>
        <xacml-context:Subject SubjectCategory="urn:oasis:names:tc:xacml:1.0:subject-category:requesting-machine">
            <xacml-context:Attribute AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id" DataType="http://www.w3.org/2001/XMLSchema#string">
                <xacml-context:AttributeValue>
                    <xsl:value-of select="$device-name"/>
                </xacml-context:AttributeValue>
            </xacml-context:Attribute>
            <xacml-context:Attribute DataType="http://www.w3.org/2001/XMLSchema#string">
                <xsl:attribute name="AttributeId">
                    <xsl:value-of select="concat( $audit-attrid-prefix, 'application')"/>
                </xsl:attribute>
                <xacml-context:AttributeValue>
                    <xsl:value-of select="$application"/>
                </xacml-context:AttributeValue>
            </xacml-context:Attribute>
            <xacml-context:Attribute DataType="http://www.w3.org/2001/XMLSchema#string">
                <xsl:attribute name="AttributeId">
                    <xsl:value-of select="concat( $audit-attrid-prefix, 'component')"/>
                </xsl:attribute>
                <xacml-context:AttributeValue>
                    <xsl:value-of select="concat( $model, ' PEP')"/>
                </xacml-context:AttributeValue>
            </xacml-context:Attribute>
            <xacml-context:Attribute DataType="http://www.w3.org/2001/XMLSchema#string">
                <xsl:attribute name="AttributeId">
                    <xsl:value-of select="concat( $audit-attrid-prefix, 'componentIdType')"/>
                </xsl:attribute>
                <xacml-context:AttributeValue>DeviceName</xacml-context:AttributeValue>
            </xacml-context:Attribute>
            <xacml-context:Attribute DataType="http://www.w3.org/2001/XMLSchema#string">
                <xsl:attribute name="AttributeId">
                    <xsl:value-of select="concat( $audit-attrid-prefix, 'instanceId')"/>
                </xsl:attribute>
                <xacml-context:AttributeValue>
                    <xsl:value-of select="concat( $device-name, ' - ', $serial-number )"/>
                </xacml-context:AttributeValue>
            </xacml-context:Attribute>
            <xacml-context:Attribute DataType="http://www.w3.org/2001/XMLSchema#string">
                <xsl:attribute name="AttributeId">
                    <xsl:value-of select="concat( $audit-attrid-prefix, 'executionEnvironment')"/>
                </xsl:attribute>
                <xacml-context:AttributeValue>
                    <xsl:value-of select="concat( $device-name, ' - ', $firmware-version )"/>
                </xacml-context:AttributeValue>
            </xacml-context:Attribute>
            <xacml-context:Attribute DataType="http://www.w3.org/2001/XMLSchema#string">
                <xsl:attribute name="AttributeId">
                    <xsl:value-of select="concat( $audit-attrid-prefix, 'componentType')"/>
                </xsl:attribute>
                <xacml-context:AttributeValue>PEP</xacml-context:AttributeValue>
            </xacml-context:Attribute>
        </xacml-context:Subject>
    </xsl:template>

    <!-- Extract attributes from an LDAP server -->
    <xsl:template name="serialize-ldap-attributes">
        <xsl:message dp:priority="debug">Serializing attributes from LDAP</xsl:message>
        <xsl:for-each select=".//*[local-name()='attribute']">
            <xsl:variable name="childname" select="local-name()"/>
            <xsl:message dp:priority="debug">Found attribute with Id <xsl:value-of select="@AttributeId"/> : <xsl:value-of select="."/></xsl:message>
            <xacml-context:Attribute>
                <xsl:attribute name="AttributeId">
                    <xsl:value-of select="@AttributeId"/>
                </xsl:attribute>
                <xsl:attribute name="DataType">
                    <xsl:value-of select="@DataType"/>
                </xsl:attribute>
                <xsl:if test="@Issuer">
                    <xsl:attribute name="Issuer">
                        <xsl:value-of select="@Issuer"/>
                    </xsl:attribute>
                </xsl:if>
                <xacml-context:AttributeValue>
                    <xsl:value-of select="text()"/>
                </xacml-context:AttributeValue>
            </xacml-context:Attribute>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="serialize-krb-attributes">
        <xsl:message dp:priority="debug">Serializing attributes from kerberos.</xsl:message>
        <xsl:for-each select=".//*[local-name()='attribute']">
            <xsl:variable name="childname" select="local-name()"/>
            <xsl:message dp:priority="debug">Found attribute with Id <xsl:value-of select="@AttributeId"/> : <xsl:value-of select="."/></xsl:message>
            <xacml-context:Attribute>
                <xsl:attribute name="AttributeId">
                    <xsl:value-of select="@AttributeId"/>
                </xsl:attribute>
                <xsl:attribute name="DataType">
                    <xsl:value-of select="@DataType"/>
                </xsl:attribute>
                <xsl:if test="@Issuer">
                    <xsl:attribute name="Issuer">
                        <xsl:value-of select="@Issuer"/>
                    </xsl:attribute>
                </xsl:if>
                <xacml-context:AttributeValue>
                    <xsl:value-of select="text()"/>
                </xacml-context:AttributeValue>
            </xacml-context:Attribute>
        </xsl:for-each>
    </xsl:template>

    <!-- Extract attributes from a SAML token presented at authentication time -->
    <xsl:template name="serialize-saml-attributes">
        <xsl:message dp:priority="debug">Extracting attributes from SAML token</xsl:message>
        <!-- Extract the Issuer from the identity, attempting SAML 2.0 first -->
        <xsl:variable name="saml20-issuer"
            select="$dpxacml:identity/entry/assertion//*[local-name()='Issuer']/text()"/>

        <!-- If the Issuer isn't there, then we're probably in SAML 1.0/1.1
             instead of 2.0
        -->
        <xsl:variable name="saml10-issuer"
            select="$dpxacml:identity/entry/assertion/*[local-name()='Assertion']/@Issuer"/>
        <xsl:for-each select=".//*[local-name()='Attribute']">
            <xsl:variable name="name-format" select="@NameFormat"/>
            <xsl:variable name="DataType" select="@DataType"/>
            <xacml-context:Attribute>
                <!-- AttributeId will come from a different place depending on
                     SAML 1.0 or 2.0 -->
                <xsl:choose>
                    <xsl:when test="string-length(@Name) &gt; 0">
                        <xsl:message dp:priority="debug">Found AttributeId '<xsl:value-of select="@Name"/> '</xsl:message>
                        <xsl:attribute name="AttributeId">
                            <xsl:value-of select="@Name"/>
                        </xsl:attribute>
                    </xsl:when>
                    <xsl:when test="string-length(@AttributeName) &gt; 0">
                        <xsl:message dp:priority="debug">Found AttributeId '<xsl:value-of select="@AttributeName"/>'</xsl:message>
                        <xsl:attribute name="AttributeId">
                            <xsl:value-of select="@AttributeName"/>
                        </xsl:attribute>
                    </xsl:when>
                </xsl:choose>

                <!-- Likewise with Issuer, different places for SAML 2.0 and
                     SAML 1.0 -->
                <xsl:choose>
                    <xsl:when test="string-length( $saml20-issuer ) &gt; 0">
                        <xsl:message dp:priority="debug">Issuer of attributes is '<xsl:value-of select="$saml20-issuer"/>'</xsl:message>
                        <xsl:attribute name="Issuer">
                            <xsl:value-of select="$saml20-issuer"/>
                        </xsl:attribute>
                    </xsl:when>
                    <xsl:when test="string-length( $saml10-issuer ) &gt; 0">
                        <xsl:message dp:priority="debug">Issuer of attributes is '<xsl:value-of select="$saml10-issuer"/>'</xsl:message>
                        <xsl:attribute name="Issuer">
                            <xsl:value-of select="$saml10-issuer"/>
                        </xsl:attribute>
                    </xsl:when>
                </xsl:choose>

                <!-- If the SAML attribute has a DataType, use that.
                     Otherwise, set to string -->
                <xsl:choose>
                    <xsl:when test="@DataType">
                        <xsl:attribute name="DataType">
                            <xsl:value-of select="@DataType"/>
                        </xsl:attribute>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="DataType">http://www.w3.org/2001/XMLSchema#string</xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:for-each select="./*[local-name()='AttributeValue']">
                    <xsl:variable name="value" select="text()"/>
                    <xsl:message dp:priority="debug">Value is '<xsl:value-of select="$value"/>'</xsl:message>
                    <xacml-context:AttributeValue>
                        <xsl:copy-of select="$value"/>
                    </xacml-context:AttributeValue>
                </xsl:for-each>
            </xacml-context:Attribute>
        </xsl:for-each>
    </xsl:template>

    <!-- Convert the big-endian comma-delimited X500 DN to LDAP RDN -->
    <xsl:template name="convert-dn">
        <xsl:param name="originalDN"/>
        <xsl:variable name="splitDN">
            <xsl:copy-of select="str:split($originalDN, ',')"/>
        </xsl:variable>
        <xsl:variable name="newSplitDN">
            <xsl:for-each select="$splitDN/token">
                <xsl:sort order="descending" data-type="number" select="position()" /> 
                <xsl:variable name="this" select="normalize-space(.)" /> 
                <xsl:value-of select="concat(',',$this)" /> 
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="newDN" select="substring-after($newSplitDN,',')" /> 
        <xsl:value-of select="$newDN"/>
    </xsl:template>

    <!--
        Convert the big-endian non-comma-delimited X500 DN to LDAP RDN. If
        if it isn't X500 then assume it is already in LDAP RDN format.
    -->
    <xsl:template name="new-convert-dn">
        <xsl:param name="originalDN"/>
        <xsl:choose>
            <xsl:when test="contains($originalDN, '/')">
                <xsl:variable name="splitDN">
                    <xsl:copy-of select="str:split($originalDN, '/')"/>
                </xsl:variable>
                <xsl:variable name="newSplitDN">
                    <xsl:for-each select="$splitDN/token">
                        <xsl:sort order="descending" data-type="number" select="position()" />
                        <xsl:variable name="this" select="normalize-space(.)" />
                        <xsl:value-of select="concat(',',$this)" />
                    </xsl:for-each>
                </xsl:variable>

                <!-- Get rid of leading and trailing commas -->
                <xsl:variable name="newDN"
                    select="substring-after(substring($newSplitDN, 1,string-length($newSplitDN) - 1),',')" />
                <xsl:value-of select="$newDN"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$originalDN"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>

