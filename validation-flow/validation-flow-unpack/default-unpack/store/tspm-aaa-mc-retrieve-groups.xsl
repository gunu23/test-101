<?xml version="1.0" encoding="UTF-8"?>

<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2008,2013. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->


<!-- 
  FILENAME
    tspm-aaa-mc-retrieve-groups.xsl
 
  DESCRIPTION
    This stylesheet is for use in the Map Credentials phase of the AAA
    pipeline. This stylesheet must be modified for your environment before use.
    
  DETAILS: 
 
    This style sheet may be used as a custom stylesheet for the Map Credentials 
    phase of AAA Policy processing. Using the service requester's identity
    credentials, as presented from the AAA authentication phase, retrieves the
    corresponding LDAP groups (and/or other LDAP attributes). Adds these
    attributes to the credential that flows to the next pahse of the AAA Policy.
    
    The AAA Policy authorization phase can be configured to use the custom
    XACML binding stylesheet, aaa-xacml-binding-rtss.xml. This stylesheet will
    extract the attribute information and place it in the XACML <Request>
    under the <Subject>.

   OUTPUT / ATTRIBUTE DETAILS:
    The <attributes> element is added to the credential by this stylesheet.
    The resulting <mapped-credentials> object may be similar to: 
    <mapped-credentials type="stylesheet" au-success="true" url="local://tspm-aaa-mc-retrieve-groups.xsl">
        <entry type="ldap">cn=user1,o=ibm,c=au</entry>
        <entry type="ldap-attributes">
            <attribute AttributeId="urn:oasis:names:tc:xacml:1.0:subject:group-id" DataType="http://www.w3.org/2001/XMLSchema#string">cn=group1,o=ibm,c=au</entry>
            <attribute AttributeId="urn:oasis:names:tc:xacml:1.0:subject:group-id" DataType="http://www.w3.org/2001/XMLSchema#string">cn=group2,o=ibm,c=au</entry>
            <attribute AttributeId="urn:jkenterprises:department" DataType="http://www.w3.org/2001/XMLSchema#string" Issuer="foo">departmentBackwards</entry>
        </entry>
    </mapped-credentials>

===============================================================================
-->


<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xalan="http://xml.apache.org/xslt"
                xmlns:dp="http://www.datapower.com/extensions"
                xmlns:str="http://exslt.org/strings"
                version="1.0"
                exclude-result-prefixes="dp"
                extension-element-prefixes="dp">
    <xsl:include href="store://dp/msgcat/crypto.xml.xsl" dp:ignore-multiple="yes"/>

    <!-- =================== START ADMIN-EDITABLE SECTION! ==================== 
        LDAP environment-specific connection information must be specified in
        this section.
    -->

    <!-- Specify your LDAP Server -->
    <xsl:variable name="server">your.server</xsl:variable>
    <xsl:variable name="bindDN">your_bind_dn</xsl:variable>
    <xsl:variable name="bindPassword">your_password</xsl:variable>
    <xsl:variable name="port">389</xsl:variable>

    <!-- Specify base DN to begin search -->
    <xsl:variable name="baseDN">your.groups.base.dn</xsl:variable>

    <!-- Specify attribute to be returned for each entry that matches -->
    <xsl:variable name="attributeName">dn</xsl:variable>

    <!-- RETRIEVE LDAP GROUPS that userDN is a member of -->
    <!--  Specify the LDAP filter - change if  'member of group' not desired -->
    <!--  Note that userDN will be concatenated into the filter in another
          section
    -->
    <xsl:variable name="filterPrefix">(member=</xsl:variable>
    <xsl:variable name="filterSuffix">)</xsl:variable>

    <!--  SAML subjects may be simple strings or other formats. If a simple string -->
    <!--  then it needs to be changed to an LDAP DN to be used. These strings will be -->
    <!--  concatenated round it to form the DN  -->
    <xsl:variable name="dnPrefix"></xsl:variable>
    <xsl:variable name="dnSuffix"></xsl:variable>

    <!-- Change scope to "one" or "base" if more stringent LDAP search is
         desired.
    -->
    <xsl:variable name="scope">subtree</xsl:variable>
    <xsl:variable name="proxyProfile"/>
    <xsl:variable name="loadBalancerGroup"/>

    <!-- Required for Kerberos to convert Kerberos principal identifier to DN  -->
    <!-- The LDAP attribute that represents the Kerberos principal identifier -->
    <!-- For Active Directory domains this will be "userprincipalname" otherwise -->
    <!-- it might be "mail"                                                       -->
    <xsl:variable name="identityAttribute">userPrincipalName</xsl:variable>

    <!-- Required for Kerberos to provide keytab for ticket expansion -->
    <!-- The name of the DP keytab object used for the original authentication    -->
    <xsl:variable name="keytabName">your_keytab_object</xsl:variable>


    <!--   SPECIFY ADDITIONAL LDAP AND/OR KERBEROS ATTRIBUTES IF DESIRED
        If desired, update this section for additional LDAP or Kerberos ticket attributes to be
        retrieved. Retrieving LDAP groups is specified by the previous section.

        This enables this stylesheet to act as a basic LDAP or Kerberos PIP as well.

        If "DataType" is omitted, then it defaults to string. If specified, it
        MUST be a valid XACML DataType!

        Issuer may be specified (see example below), however if "Issuer" is
        omitted it defaults to the 'server' value above.
    -->
    <xsl:variable name="pipConfig">
        <pipConfig>
        <!--  OPTIONAL: For each additional LDAP or Kerberos attribute to be retrieved, add
              an entry. Examples follow.

        <attribute ldapAttr="userPrincipalName" AttributeId="http://www.test.com/email" DataType="http://www.w3.org/2001/XMLSchema#string" /> 


        <attribute ldapAttr="cn" AttributeId="http://www.test.com/shortName" DataType="http://www.w3.org/2001/XMLSchema#string" Issuer="foo" />

        <attribute ldapAttr="sn" AttributeId="http://www.test.com/surname" DataType="http://www.w3.org/2001/XMLSchema#string" /> 

        <attribute ldapAttr="departmentNumber"  AttributeId="urn:wlcCompany:user-Department"  DataType="http://www.w3.org/2001/XMLSchema#string" Issuer="user-Department" />

            <attribute krbAttr="server" AttributeId="http://www.test.com/serverName" DataType="http://www.w3.org/2001/XMLSchema#string" Issuer="Server" />

            <attribute krbAttr="client" AttributeId="http://www.test.com/clientName" DataType="http://www.w3.org/2001/XMLSchema#string" Issuer="Server" />

         -->
        </pipConfig>
    </xsl:variable>

    <!-- =================== END ADMIN-EDITABLE SECTION! ==================== -->

    <xsl:attribute-set name="types">
        <xsl:attribute name="type">kerberos-principal-dn</xsl:attribute>
    </xsl:attribute-set>

    <xsl:template match="credentials">
        <!-- mapped-credentials -->
        <xsl:apply-templates/>
    </xsl:template>

    <!-- Handle getting LDAP attributes for each map creds entry -->
    <xsl:template match="entry">
        <xsl:variable name="serialcred">
            <dp:serialize select="."/>
        </xsl:variable>
        <xsl:message dp:type="crypto" dp:id="{$DPLOG_TIVOLI_TSPMCREDSTOMAP}">
            <dp:with-param value="{$serialcred}"/>
        </xsl:message>

        <xsl:copy-of select="."/>

        <xsl:choose>
            <xsl:when test="@type='xmlfile'">
                <xsl:call-template name="do-group-search">
                    <xsl:with-param name="userDN" select="./*[local-name()='OutputCredential']/text()"/>
                </xsl:call-template>
            </xsl:when>

            <!-- BST from message, selected via XPath -->
            <xsl:when test="@type='token'">
                <xsl:variable name="subject-dn" select="dp:get-cert-subject(concat('cert:', text()))"/>
                <xsl:call-template name="do-group-search">
                    <xsl:with-param name="userDN" select="$subject-dn"/>
                </xsl:call-template>
            </xsl:when>

            <!-- Username selected from SAML attr token -->
            <xsl:when test="@type='saml-nameid'">
                <xsl:choose>
                    <xsl:when test=".//@Format='urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName'">
                        <xsl:message dp:priority="debug">Retrieving saml X509SubjectName '<xsl:value-of select="."/>' </xsl:message>
                        <xsl:variable name="subject-dn">
                        <!-- Convert the big-endian comma-delimited X500 DN to LDAP RDN -->
                            <xsl:call-template name="new-convert-dn">
                                <xsl:with-param name="originalDN" select="."/>
                            </xsl:call-template>
                         </xsl:variable>
                         <xsl:call-template name="do-group-search">
                             <xsl:with-param name="userDN" select="$subject-dn"/>
                         </xsl:call-template>
                    </xsl:when>

                    <xsl:otherwise>
                        <!-- By default assume a simple name and convert to a DN -->
                        <xsl:message dp:priority="debug">Retrieving saml default name '<xsl:value-of select="."/>' </xsl:message>
                       <xsl:variable name='subject' select="."/>
                        <xsl:variable name="subject-dn" select="concat($dnPrefix,
                            $subject, $dnSuffix)"/>
                        <xsl:call-template name="do-group-search">
                            <xsl:with-param name="userDN" select="$subject-dn"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <!-- Client certificate from SSL connection -->
            <xsl:when test="@type='client-ssl'">
                <!-- This holds the subject dn -->
                <!-- Convert the big-endian slash-delimited X500 DN to LDAP RDN -->
                <xsl:variable name="ldap-subject-dn" select="dp:auth-info('ssl-client-subject', 'ldap-strict')"/>
                <xsl:call-template name="do-group-search">
                    <xsl:with-param name="userDN" select="$ldap-subject-dn"/>
                </xsl:call-template>
            </xsl:when>

            <!-- Validated BST Element from WS-Security Header -->
            <xsl:when test="@type='validate-signer'">
                <!-- This holds the subject dn -->
                <xsl:variable name="ldap-subject-dn">
                    <!-- Convert the big-endian comma-delimited X500 DN to LDAP RDN -->
                    <xsl:call-template name="convert-dn">
                        <xsl:with-param name="originalDN" select="node()/*[local-name()='Subject']"/>
                    </xsl:call-template>
                </xsl:variable>                  
                <xsl:call-template name="do-group-search">
                    <xsl:with-param name="userDN" select="$ldap-subject-dn"/>
                </xsl:call-template>
            </xsl:when>

            <!-- Filter out entries that don't contain wanted identifiers -->
            <xsl:when test="@type='saml' or  @type='saml-attributes'">
            </xsl:when>

            <!-- Kerberos principal -->
            <xsl:when test="@type='kerberos-principal'">
                <xsl:variable name="ldap-subject-dn">
                    <xsl:call-template name="convert-upn2dn">
                        <xsl:with-param name="uPN" select="."/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:element name="entry" use-attribute-sets="types">
                    <xsl:value-of select="$ldap-subject-dn"/>
                </xsl:element>
            <xsl:message dp:priority="debug">Found principal DN '<xsl:value-of select="$ldap-subject-dn"/>'</xsl:message>
                <xsl:call-template name="do-group-search">
                    <xsl:with-param name="userDN" select="$ldap-subject-dn"/>
                </xsl:call-template>
            </xsl:when> 

            <!-- Extract ticket attributes from actual Kerberos token -->
            <xsl:when test="@type='kerberos'">
                <xsl:variable name="krbAttrs" select="dp:kerberos-parse-apreq(
                    //apreq-base64,
                    concat('keytabname:', $keytabName))"/>
                <entry type="kerberos-attributes">
                    <xsl:apply-templates select="$pipConfig/pipConfig">
                        <xsl:with-param name="attrs" select="$krbAttrs/apreq/ticket/*"/>
                    </xsl:apply-templates>
                </entry>
            </xsl:when> 

            <xsl:otherwise>
                <xsl:call-template name="do-group-search">
                    <xsl:with-param name="userDN" select="text()"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
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

    <!-- Convert the big-endian non-comma-delimited X500 DN to LDAP RDN -->
    <!-- but if it isn't X500 then it is already in LDAP RDN format -->
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
                <xsl:variable name="newDN" select=
             "substring-after(substring($newSplitDN, 1,string-length($newSplitDN) - 1),',')" /> 
                <xsl:value-of select="$newDN"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$originalDN"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Convert userPrincipalName from kerberos token to LDAP DN --> 
    <xsl:template name="convert-upn2dn">
        <xsl:param name="uPN"/>
        <xsl:message dp:priority="debug">Retrieving DN for principal '<xsl:value-of select="$uPN"/>'</xsl:message>
        <xsl:variable name="upnFilter" select="concat('(',$identityAttribute, '=', $uPN, ')')"/>
        <xsl:variable name="newDN" select="dp:ldap-search($server, $port, $bindDN, $bindPassword,             $baseDN, 'dn', $upnFilter, $scope, $proxyProfile, $loadBalancerGroup )"/>
        <xsl:value-of select="$newDN//LDAP-search-results/result/DN"/>
    </xsl:template>

    <xsl:template name="do-group-search">
        <xsl:param name="userDN"/>
        <xsl:message dp:priority="debug">Retrieving groups for user '<xsl:value-of select="$userDN"/>' from LDAP server.</xsl:message>
        <entry type="ldap-attributes">
            <!-- Use the extension function "ldap-search()" to get the groups:
                 dp:ldap-search(serverAddress, portNumber, bindDN, bindPassword,
                     targetDN, attributeName, filter, scope, sslProxyProfile,
                     ldapLBGroup)
            -->
            <xsl:variable name="filterString" select="concat($filterPrefix,
                $userDN, $filterSuffix)"/>
            <xsl:variable name="searchResults" select="dp:ldap-search($server,
                $port, $bindDN, $bindPassword, $baseDN, $attributeName,
                $filterString, $scope, $proxyProfile, $loadBalancerGroup )"/>

            <xsl:apply-templates select="$searchResults"/>
            <xsl:apply-templates select="$pipConfig/pipConfig">
                <xsl:with-param name="userDN" select="$userDN"/>
            </xsl:apply-templates>
        </entry>
    </xsl:template>

    <!-- This template handles the result of a ldap-search call, which we use
         for getting groups
    -->
    <xsl:template match="LDAP-search-results">
        <xsl:variable name="ldapres">
            <dp:serialize select="."/>
        </xsl:variable>
        <xsl:message dp:type="crypto" dp:id="{$DPLOG_TIVOLI_TSPMLDAPSEARCHRESULTS}">
            <dp:with-param value="{$ldapres}"/>
        </xsl:message>
        <xsl:for-each select="./*">
            <attribute AttributeId="urn:oasis:names:tc:xacml:1.0:subject:group-id"
                       DataType="http://www.w3.org/2001/XMLSchema#string">
                <xsl:value-of select=".//DN/text()"/>
            </attribute>
            <attribute AttributeId="urn:oasis:names:tc:xacml:1.0:subject:group-id"  
                       DataType="urn:oasis:names:tc:xacml:1.0:data-type:x500Name">
                <xsl:value-of select=".//DN/text()" /> 
            </attribute>
        </xsl:for-each>
    </xsl:template>

    <!-- This template handles the error case for ldap-search -->
    <xsl:template match="LDAP-search-error">
        <xsl:variable name="ldapsrcherr">
            <xsl:value-of select="//error/text()"/>
        </xsl:variable>
        <xsl:message dp:type="crypto" dp:priority="error" dp:id="{$DPLOG_TIVOLI_TSPMSEARCHERROR}">
            <dp:with-param value="{$ldapsrcherr}"/>
        </xsl:message>
    </xsl:template>

    <!-- Template entry to generate attribute elements for kerberos and ldap attributes -->
    <!-- attrValue - is the value of the new element -->
    <!-- attrAttr - is the element from pipConfig that defines the new elements attributes --> 

    <xsl:template name="generateAttr">
        <xsl:param name="attrValue"/>
        <xsl:param name="attrAttr"/>
        <attribute>
            <xsl:attribute name="AttributeId">
                <xsl:value-of select="$attrAttr/@AttributeId"/>
            </xsl:attribute>
            <xsl:choose>
                <xsl:when test="@DataType">
                    <xsl:attribute name="DataType">
                        <xsl:value-of select="$attrAttr/@DataType"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="DataType">http://www.w3.org/2001/XMLSchema#string</xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="@Issuer">
                    <xsl:attribute name="Issuer">
                        <xsl:value-of select="$attrAttr/@Issuer"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="Issuer">
                        <xsl:value-of select="$server"/>
                    </xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="$attrValue"/>
        </attribute>
    </xsl:template>

    <!-- This template handles getting the attributes based on the <pipConfig> element -->
    <xsl:template match="pipConfig">
        <xsl:param name="userDN"/>
        <xsl:param name="attrs"/>

        <!-- Kerberos ticket attributes -->
        <xsl:if test="$attrs">
            <xsl:for-each select="//attribute[@krbAttr]">
                <xsl:variable name="realAttr" select="."/>
                <xsl:variable name="realAttrName">
                    <xsl:value-of select="@krbAttr"/>
                </xsl:variable>
                <xsl:for-each select="$attrs">
                    <xsl:message dp:priority="debug">
                       Retrieve attribute element <xsl:value-of select="local-name()"/> with value <dp:serialize select="."/>.
                    </xsl:message>
                    <xsl:variable name='attrName'>
                        <xsl:value-of select="local-name()"/>
                    </xsl:variable>
                    <xsl:if test="$attrName=$realAttrName">
                        <xsl:call-template name="generateAttr">
                            <xsl:with-param name="attrValue" select="."/>
                            <xsl:with-param name="attrAttr" select="$realAttr"/>
                        </xsl:call-template>
                    </xsl:if>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:if>

        <!-- LDAP attributes --> 
        <xsl:if test="$userDN">
            <xsl:for-each select="//attribute[@ldapAttr]">
                <xsl:message dp:priority="debug">
                    Retrieve attribute <xsl:value-of select="@ldapAttr"/> for user '<xsl:value-of select="$userDN"/>'.</xsl:message>

                <xsl:variable name="attrValue"
                    select="dp:ldap-simple-query($server, $port, $bindDN, $bindPassword,
                       $userDN, @ldapAttr, 'base', $proxyProfile, $loadBalancerGroup)"/>

                <xsl:message dp:priority="debug">LDAP simple query result: <xsl:value-of select="$attrValue"/></xsl:message>
                <xsl:choose>
                    <!-- The string '*ERROR*' is returned if the lookup failed -->
                    <xsl:when test="$attrValue != '*ERROR*'">
                        <xsl:call-template name="generateAttr">
                            <xsl:with-param name="attrValue" select="$attrValue"/>
                            <xsl:with-param name="attrAttr" select="."/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message dp:type="crypto" dp:priority="error" dp:id="{$DPLOG_TIVOLI_TSPMERRORFINDINGLDAPATTRFORUSER}">
                            <dp:with-param value="{@ldapAttr}"/>
                            <dp:with-param value="{$userDN}"/>
                        </xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:if>

    </xsl:template>
</xsl:stylesheet>
