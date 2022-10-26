<?xml version="1.0" encoding="UTF-8"?>

<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2011. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->


<!-- 
  FILENAME
    tspm-aaa-mc-saml.xsl
 
  DESCRIPTION
    This stylesheet is for use in the Map Credentials phase of the AAA
    pipeline. This stylesheet must be modified for your environment before use.
    
  DETAILS: 
 
    This style sheet may be used as a custom stylesheet for the Map Credentials 
    phase of AAA Policy processing. Using the service requester's SAML
    attributes, as presented from the AAA authentication phase, the style
    sheet maps certain user-specified role or group attributes to XACML role
    or group attributes. The style sheet adds these attributes to the credential
    that flows to the next phase of the AAA Policy.
    
    The AAA Policy authorization phase can be configured to use the custom
    XACML binding stylesheet, tspm-aaa-xacml-binding-rtss.xml. This style
    sheet will extract the attribute information and place it in the XACML
    <Request> under the <Subject>.

   OUTPUT / ATTRIBUTE DETAILS:
    The <saml-attributes> element is modified by this stylesheet.
    The resulting <mapped-credentials> object may be similar to: 
    <mapped-credentials type="stylesheet" au-success="true"
        url="local:///tspm/tspm-aaa-mc-map-saml-groups.xsl">
        <entry type="saml">user1</entry>
        <entry type="saml-nameid">
            <saml:NameID
                Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">
                    user1
            </saml:NameID>
        </entry>
        <entry type="saml-attributes">
            <saml:AttributeStatement>
                <saml:Attribute Name="group">
                    <saml:AttributeValue xsi:type="xs:string">
                        cn=group1,o=ibm,c=au
                    </saml:AttributeValue>
                </saml:Attribute>
                <saml:Attribute Name="urn:oasis:names:tc:xacml:1.0:subject:group-id"
                    DataType="http://www.w3.org/2001/XMLSchema#string">
                    <saml:AttributeValue xsi:type="xs:string">
                        cn=group1,o=ibm,c=au
                    </saml:AttributeValue>
                </saml:Attribute>
                <saml:Attribute Name="urn:oasis:names:tc:xacml:1.0:subject:group-id"
                    DataType="urn:oasis:names:tc:xacml:1.0:data-type:x500Name">
                    <saml:AttributeValue xsi:type="xs:string">
                        cn=group1,o=ibm,c=au
                    </saml:AttributeValue>
                </saml:Attribute>
            </saml:AttributeStatement>
        </entry>
    </mapped-credentials>

===============================================================================
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xalan="http://xml.apache.org/xslt"
                xmlns:dp="http://www.datapower.com/extensions"
                xmlns:saml1="urn:oasis:names:tc:SAML:1.0:assertion"
                xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion"
                xmlns:str="http://exslt.org/strings"
                exclude-result-prefixes="dp"
                extension-element-prefixes="dp"
                version="1.0">

    <xsl:include href="store://dp/msgcat/crypto.xml.xsl"/>

    <!-- =================== START ADMIN-EDITABLE SECTION! ==================== 
        The SAML attribute that contains the group / role information must be
        specified in this section. The default values are the XACML
        AttributeIds 
    -->

    <!-- Specify the group attribute -->
    <xsl:variable
        name="group-attribute">urn:oasis:names:tc:xacml:1.0:subject:group-id</xsl:variable>

    <!-- Specify the role attribute -->
    <xsl:variable
        name="role-attribute">urn:oasis:names:tc:xacml:2.0:subject:role</xsl:variable>

    <!-- =================== END ADMIN-EDITABLE SECTION! ==================== -->

    <!-- XACML AttributeIds and DataTypes -->
    <xsl:variable name="group-id"
        select="'urn:oasis:names:tc:xacml:1.0:subject:group-id'"/>
    <xsl:variable name="role"
        select="'urn:oasis:names:tc:xacml:2.0:subject:role'"/>
    <xsl:variable name="x500Name"
        select="'urn:oasis:names:tc:xacml:1.0:data-type:x500Name'"/>
    <xsl:variable name="xml-string"
        select="'http://www.w3.org/2001/XMLSchema#string'"/>

    <xsl:template match="credentials">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="entry">
        <xsl:variable name="serialcred">
            <dp:serialize select="."/>
        </xsl:variable>
        <xsl:message dp:type="crypto" dp:id="{$DPLOG_TIVOLI_TSPMCREDSTOMAP}">
            <dp:with-param value="{$serialcred}"/>
        </xsl:message>

        <!--
            We need to leave attributes other than SAML "as-is"
        -->
        <xsl:choose>
            <xsl:when test="@type='saml-attributes'">
                <xsl:message dp:priority="debug">Found SAML attributes</xsl:message>

                <!--
                    Now that we have the SAML attributes node, we need to add
                    (map) the necessary XACML attributes
                -->
                <entry type="saml-attributes">
                    <xsl:apply-templates />
                </entry>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="saml1:Subject | saml2:Subject">
        <!-- Copy the Subject as-is -->
        <xsl:message dp:priority="debug">Adding saml:Subject</xsl:message>
        <xsl:copy-of select="."/>
    </xsl:template>

    <xsl:template match="saml1:AttributeStatement | saml2:AttributeStatement">
        <xsl:message dp:priority="debug">Processing saml:AttributeStatement node</xsl:message>
        <xsl:copy>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="saml1:Attribute | saml2:Attribute">
        <xsl:message dp:priority="debug">Processing saml:Attribute node</xsl:message>

        <!-- We're not modifying the original Attribute, so copy it -->
        <xsl:copy-of select="."/>

        <!--
             Determine which SAML version we have because the attribute name
             is different. Try SAML 1.0/1.1 first
        -->
        <xsl:variable name="saml1-attribute"><xsl:value-of
                select="@AttributeName"/></xsl:variable>

        <!-- Set the correct attribute name and value per SAML version -->
        <xsl:variable name="attribute-id">
            <xsl:choose>
                <xsl:when test="string-length($saml1-attribute) &gt; 0">
                    <xsl:value-of select="@AttributeName"/>
                </xsl:when>
                <xsl:otherwise>
                     <xsl:value-of select="@Name"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:message dp:priority="debug">Found Attribute '<xsl:value-of select="$attribute-id"/>'</xsl:message>

        <!-- Now check if this matches our group or role definition -->
        <xsl:choose>
            <xsl:when test="$attribute-id = $group-attribute">
                <xsl:message dp:priority="debug">Found group Attribute to map '<xsl:value-of select="$attribute-id"/>'</xsl:message>
                <!-- Create the x500Name format of the group -->
                <xsl:copy>
                    <xsl:choose>
                        <xsl:when test="string-length($saml1-attribute) &gt; 0">
                            <xsl:attribute name="AttributeName"><xsl:value-of
                                select="$group-id"/></xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="Name"><xsl:value-of
                                select="$group-id"/></xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:attribute name="DataType"><xsl:value-of
                        select="$x500Name"/></xsl:attribute>
                    <xsl:copy-of select="./*[local-name()='AttributeValue']"/>
                </xsl:copy>
                <!-- Set the XML string format of the group -->
                <xsl:copy>
                    <xsl:choose>
                        <xsl:when test="string-length($saml1-attribute) &gt; 0">
                            <xsl:attribute name="AttributeName"><xsl:value-of
                                select="$group-id"/></xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="Name"><xsl:value-of
                                select="$group-id"/></xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:attribute name="DataType"><xsl:value-of
                        select="$xml-string"/></xsl:attribute>
                    <xsl:copy-of select="./*[local-name()='AttributeValue']"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="$attribute-id = $role-attribute">
                <xsl:message dp:priority="debug">Found role Attribute to map '<xsl:value-of select="$attribute-id"/>'</xsl:message>
                <xsl:copy>
                    <xsl:choose>
                        <xsl:when test="string-length($saml1-attribute) &gt; 0">
                            <xsl:attribute name="AttributeName"><xsl:value-of
                                select="$role"/></xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="Name"><xsl:value-of
                                select="$role"/></xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:attribute name="DataType"><xsl:value-of
                        select="$xml-string"/></xsl:attribute>
                    <xsl:copy-of select="./*[local-name()='AttributeValue']"/>
                </xsl:copy>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>

