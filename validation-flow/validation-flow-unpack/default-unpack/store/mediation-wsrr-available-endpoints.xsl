<?xml version="1.0"?>
<!--
Licensed Materials - Property of IBM
IBM WebSphere DataPower Appliances
Copyright IBM Corporation 2013. All Rights Reserved.
US Government Users Restricted Rights - Use, duplication or disclosure
restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
    This stylesheet will set the var://service/routing-url to the an endpoint returned from a dynamic WSRR query.
-->

<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:dp="http://www.datapower.com/extensions"
xmlns:dpconfig="http://www.datapower.com/param/config"
xmlns:str="http://exslt.org/strings"
extension-element-prefixes="dp dpconfig"
exclude-result-prefixes="dp dpconfig">

<!-- 
    This stylesheet pulls context variable information to accomplish its task
    o WSRR Server Name (required)          - name of WSRR server object with which to communicate
    o Routing SSL Proxy Profile (optional) - needed for secure communication to WSRR server
-->

<xsl:variable name="q">'</xsl:variable>
<xsl:variable name="qurlCapability"   select="concat($q, 'http://www.ibm.com/xmlns/prod/serviceregistry/profile/v6r3/GovernanceEnablementModel%23CapabilityVersion', $q)"/>
<xsl:variable name="qurlSLAActive"    select="concat($q, 'http://www.ibm.com/xmlns/prod/serviceregistry/lifecycle/v6r3/LifecycleDefinition%23SLAActive', $q)"/>
<xsl:variable name="qurlSLDSubscribe" select="concat($q, 'http://www.ibm.com/xmlns/prod/serviceregistry/lifecycle/v6r3/LifecycleDefinition%23SLDSubscribable', $q)"/>
<xsl:variable name="qurlProduction"   select="concat($q, 'http://www.ibm.com/xmlns/prod/serviceregistry/6/1/GovernanceProfileTaxonomy%23Production', $q)"/>
<xsl:variable name="qurlOnline"       select="concat($q, 'http://www.ibm.com/xmlns/prod/serviceregistry/lifecycle/v6r3/LifecycleDefinition%23Online', $q)"/>
<xsl:variable name="qurlInternal"     select="concat($q, 'http://www.ibm.com/xmlns/prod/serviceregistry/8/0/visibilitytaxonomy%23Internal', $q)"/>
<xsl:variable name="qurlSLD"          select="concat($q, 'http://www.ibm.com/xmlns/prod/serviceregistry/profile/v6r3/GovernanceEnablementModel%23ServiceLevelDefinition', $q)"/>

<!-- 
    This example stylesheet will demonstrate how to perform dynamic endpoint lookup and routing using a WSRR registry.
 
    The example differentiates between SLA routing (based on ConsumerID and ContextID information) and SLD routing (based on SLD / Service).
		 
    (1) Determine if we are executing this route action during a SLA or SLD rule enforcement.
		 		
    (2a) If routing is being enforced on an SLA rule, then perform a WSRR endpoint lookup using the "ConsumerID" and "ContextID" extracted from transaction metadata.
		 
    (2b) If routing is being enforced on an SLD rule, then perform a WSRR endpoint lookup using the "SLDName" extracted from transaction metadata.
		 
    (3) The example selects the first returned endpoint and assigns the endpoint URL to transaction route variable 
        (along with any SSL Profile provided as parameter to stylesheet). Your selection logic may use a different choice.
-->

<xsl:template match="/">  

<!-- Set DEBUG to true in order to get debug information at the console -->
<xsl:variable name="DEBUG" select="boolean('true')"/>
<xsl:variable name="TAG"   select="'[wsrr-endpoints] '"/>

<!-- ================================================================= -->          
<!-- (0) Collect information specific to this context.                 -->
<!-- ================================================================= -->          
<xsl:variable name="Algorithm"         select="dp:variable('var://context/mediation-policy/custom-routing-algorithm')"/>
<xsl:variable name="RoutingSSLProfile" select="dp:variable('var://context/mediation-policy/custom-routing-ssl-profile')"/>
<xsl:variable name="WSRRServerName"    select="dp:variable('var://context/mediation-policy/custom-routing-registry-server')"/>
<xsl:variable name="Endpoints"         select="dp:variable('var://context/mediation-policy/custom-routing-endpoints')"/>  <!-- not used here -->
<xsl:variable name="Parameters"        select="dp:variable('var://context/mediation-policy/custom-routing-parameters')"/> <!-- not used here -->
<xsl:variable name="RuleName"          select="dp:variable('var://service/transaction-rule-name')"/>

<xsl:if test="$DEBUG">
    <xsl:message dp:priority="warn"><xsl:value-of select="$TAG"/>Algorithm <xsl:value-of select="$Algorithm"/></xsl:message>
    <xsl:message dp:priority="warn"><xsl:value-of select="$TAG"/>RoutingSSLProfile <xsl:value-of select="$RoutingSSLProfile"/></xsl:message>
    <xsl:message dp:priority="warn"><xsl:value-of select="$TAG"/>WSRRServerName <xsl:value-of select="$WSRRServerName"/></xsl:message>
    <xsl:message dp:priority="warn"><xsl:value-of select="$TAG"/>RuleName <xsl:value-of select="$RuleName"/></xsl:message>
</xsl:if>
	  
<!-- ================================================================= -->          
<!-- (1) Determine if performing endpoint route in SLA or SLD context. -->
<!-- ================================================================= -->          
<xsl:variable name="slaCheckResults" select="dp:variable('var://context/sla/check-results')"/>
<xsl:variable name="sldCheckResults" select="dp:variable('var://context/sld/check-results')"/>

<xsl:if test="$DEBUG">
    <xsl:message dp:priority="warn"><xsl:value-of select="$TAG"/>slaCheckResults <xsl:copy-of select="$slaCheckResults"/></xsl:message>
    <xsl:message dp:priority="warn"><xsl:value-of select="$TAG"/>sldCheckResults <xsl:copy-of select="$sldCheckResults"/></xsl:message>
</xsl:if>

<!-- (example slaCheckResults) 
    <SLACheck>
        <SLA Rule="service_28_2_sla1-req">
            <Identity>
                <Filter Name="Acme_ConsumerID">Value1</Filter>
                <Filter Name="Acme_ContextID">Value2</Filter>
             </Identity>
        </SLA>
        <SLA Rule="service_28_2_sla2-req">
            <Identity>
	        <Filter Name="Name1">Value1</Filter>
                <Filter Name="Name2">Value2</Filter>
            </Identity>
        </SLA>
        <SLA Rule="service_28_2_sla3-req">
            <Identity>
                <Filter Name="Name1">Value1</Filter>
                <Filter Name="Name2">Value2</Filter>
            </Identity>
        </SLA>	  
    </SLACheck
-->	

<!-- Info for entry that matches RuleName -->
<xsl:variable name="slaRuleInfo" select="$slaCheckResults/SLACheck/SLA[@Rule=$RuleName]"/>
<xsl:variable name="sldRuleInfo" select="$sldCheckResults/SLDCheck/SLD[@Rule=$RuleName]"/>

<!-- ================================================================= -->          
<!-- (2a) Process if SLA rule was matched.                             -->
<!-- ================================================================= -->          
<xsl:if test="count($slaRuleInfo) > 0">

    <xsl:if test="$DEBUG">
        <xsl:message dp:priority="warn"><xsl:value-of select="$TAG"/>SLA rule match <xsl:value-of select="$RuleName"/></xsl:message>
    </xsl:if>

    <!-- Retrieve "ConsumerID" value -->
    <xsl:variable name="consumerID">
        <xsl:value-of select="str:encode-uri($slaRuleInfo/Identity/Filter[contains(@Name, '_ConsumerID')], false())"/>
    </xsl:variable>

    <xsl:if test="$DEBUG">
        <xsl:message dp:priority="warn"><xsl:value-of select="$TAG"/>ConsumerID <xsl:value-of select="$consumerID"/></xsl:message>
    </xsl:if>
   
    <!-- Retrieve "ContextID" value -->
    <xsl:variable name="contextID">
        <xsl:value-of select="str:encode-uri($slaRuleInfo/Identity/Filter[contains(@Name, '_ContextID')], false())"/>
    </xsl:variable>

    <xsl:if test="$DEBUG">
        <xsl:message dp:priority="warn"><xsl:value-of select="$TAG"/>ContextID <xsl:value-of select="$contextID"/></xsl:message>
    </xsl:if>

    <xsl:variable name="qconsumerID" select="concat($q, $consumerID, $q)"/>
    <xsl:variable name="qcontextID"  select="concat($q, $contextID, $q)"/>

    <!-- Build WSRR query string (REST API URL). Note that we inject the ConsumerID and ContextID into string below. -->
    <xsl:variable name="class1" select="concat('classifiedByAllOf(.,', $qurlCapability, ')')"/>
    <xsl:variable name="class2" select="concat('classifiedByAllOf(.,', $qurlSLAActive, ')')"/>
    <xsl:variable name="class3" select="concat('classifiedByAllOf(.,', $qurlSLDSubscribe, ')')"/>
    <xsl:variable name="class4" select="concat('classifiedByAllOf(.,', $qurlProduction, ',', $qurlOnline, ',', $qurlInternal, ')')"/>

    <!-- GraphQuery, as an alternative to the PropertyQuery below.
    <xsl:variable name="WSRRQuery" select="concat('/WSRR/8.0/Metadata/XML/GraphQuery?query=', 
                                                  '/WSRR/GenericObject[', $class1, '%20and%20@gep63_consumerIdentifier=', $qconsumerID, ']',
                                                  '/gep63_consumes(.)[@gep63_contextIdentifier=', $qcontextID, '%20and%20',$class2, ']',
                                                  '/gep63_agreedEndpoints(.)[',$class3, ']', 
                                                  '/gep63_availableEndpoints(.)[',$class4, ']')"/>
    end GraphQuery -->                                                 

    <!-- PropertyQuery, returning only properties named 'name'. These are the routing endpoints. -->
    <xsl:variable name="WSRRQuery" select="concat('/WSRR/8.0/Metadata/XML/PropertyQuery?query=', 
                                                  '/WSRR/GenericObject[', $class1, '%20and%20@gep63_consumerIdentifier=', $qconsumerID, ']',
                                                  '/gep63_consumes(.)[@gep63_contextIdentifier=', $qcontextID, '%20and%20',$class2, ']',
                                                  '/gep63_agreedEndpoints(.)[',$class3, ']', 
                                                  '/gep63_availableEndpoints(.)[',$class4, ']', 
                                                  '&amp;p1=name')"/>
    <!-- end PropertyQuery -->                                                 

    <xsl:variable name="urlWSRRQuery" select="concat('wsrr://', $WSRRServerName, $WSRRQuery)"/>
  
    <xsl:if test="$DEBUG">
        <xsl:message dp:priority="warn"><xsl:value-of select="$TAG"/>SLA urlWSRRQuery <xsl:copy-of select="$urlWSRRQuery"/></xsl:message>
    </xsl:if>

    <!-- Get service available endpoints meeting criteria -->
    <xsl:variable name="endpoints">
        <dp:url-open target="{$urlWSRRQuery}" response="xml"/>
    </xsl:variable>

    <xsl:if test="$DEBUG">
        <xsl:message dp:priority="warn"><xsl:value-of select="$TAG"/>SLA results, endpoints <xsl:copy-of select="$endpoints"/></xsl:message>
    </xsl:if>

    <!-- At this point, WSRR query might return any number of valid and available endpoints from registry -->
    <!--
    <resources>
        <resource>
            <properties>
                <property name="name" value="http://host1:1234/foo" />
            </properties>
        </resource>
        <resource>
            <properties>
                <property name="name" value="http://host2:4321/foo" />
            </properties>
        </resource>
        <resource>
            <properties>
                <property name="name" value="http://host3:1212/foo" />
            </properties>
        </resource>
    </resources>
    -->
   
    <!-- Add customization to select an endpoint. -->
    <!-- This example selects the first endpoint, -->   
    <xsl:variable name="endpointResource" select="$endpoints/resources/resource[1]"/>  <!-- select 1st resource -->   
    <xsl:variable name="endpointURL">
        <xsl:value-of select="$endpointResource/properties/property/@value"/>
    </xsl:variable>

    <xsl:if test="$DEBUG">
        <xsl:message dp:priority="warn"><xsl:value-of select="$TAG"/>SLA selected endpointURL <xsl:value-of select="$endpointURL"/></xsl:message>
    </xsl:if>

    <!-- ================================================================= -->          
    <!-- (3) Set backend routing URL variable and request is forwarded     -->
    <!--     to desired endpoint. Also set the backend routing SSL Profile -->
    <!--     if present.                                                   -->
    <!-- ================================================================= -->          
    <dp:set-variable name="'var://service/routing-url'" value="string($endpointURL)" />

    <xsl:if test="string-length($RoutingSSLProfile) != 0">
        <dp:set-variable name="'var://service/routing-url-sslprofile'" value="string($RoutingSSLProfile)" />
    </xsl:if>

</xsl:if>

<!-- ================================================================= -->          
<!-- (2b) Process if SLD rule was matched.                             -->
<!-- ================================================================= -->          
<xsl:if test="count($sldRuleInfo) > 0">

    <xsl:if test="$DEBUG">
        <xsl:message dp:priority="warn"><xsl:value-of select="$TAG"/>SLD rule match <xsl:value-of select="$RuleName"/></xsl:message>
    </xsl:if>
   
    <!-- Retrieve "SLDName" value -->
    <xsl:variable name="SLDName">
        <xsl:value-of select="str:encode-uri($sldRuleInfo/Identity, false())"/>
    </xsl:variable>

    <xsl:if test="$DEBUG">
        <xsl:message dp:priority="warn"><xsl:value-of select="$TAG"/>SLDName <xsl:value-of select="$SLDName"/></xsl:message>
    </xsl:if>

    <xsl:variable name="qSLDName" select="concat($q, $SLDName, $q)"/>
   
    <!-- Build WSRR query string (REST API URL). Note that we inject the SLD name into string below. -->
    <xsl:variable name="class1" select="concat('classifiedByAllOf(.,', $qurlSLD, ',', $qurlSLDSubscribe, ')')"/>
    <xsl:variable name="class4" select="concat('classifiedByAllOf(.,', $qurlProduction, ',', $qurlOnline, ',', $qurlInternal, ')')"/>

    <xsl:variable name="WSRRQuery" select="concat('/WSRR/8.0/Metadata/XML/PropertyQuery?query=', 
                                                  '/WSRR/GenericObject[@name=', $qSLDName, '%20and%20', $class1, ']',
                                                  '/gep63_availableEndpoints(.)[',$class4, ']', 
                                                  '&amp;p1=name')"/>
    <xsl:variable name="urlWSRRQuery" select="concat('wsrr://', $WSRRServerName, $WSRRQuery)"/>

    <xsl:if test="$DEBUG">
        <xsl:message dp:priority="warn"><xsl:value-of select="$TAG"/>SLD urlWSRRQuery <xsl:copy-of select="$urlWSRRQuery"/></xsl:message>
    </xsl:if>

    <!-- Get service available endpoints meeting criteria -->
    <xsl:variable name="endpoints">
        <dp:url-open target="{$urlWSRRQuery}" response="xml"/>
    </xsl:variable>

    <xsl:if test="$DEBUG">
        <xsl:message dp:priority="warn"><xsl:value-of select="$TAG"/>SLD results, endpoints <xsl:copy-of select="$endpoints"/></xsl:message>
    </xsl:if>

    <!-- At this point, WSRR query might return any number of valid and available endpoints from registry -->
    <!--
    <resources>
        <resource>    
            <properties>
                <property name=""name"" value=""http://dpbanking.com:8765/foo/""/>
            </properties>
        </resource>
    </resources>"
    -->

    <!-- Add customization to select an endpoint. -->
    <!-- This example selects the first endpoint, -->   
    <xsl:variable name="endpointResource" select="$endpoints/resources/resource[1]"/>  <!-- select 1st resource -->   
    <xsl:variable name="endpointURL">
        <xsl:value-of select="$endpointResource/properties/property/@value"/>
    </xsl:variable>

    <xsl:if test="$DEBUG">
        <xsl:message dp:priority="warn"><xsl:value-of select="$TAG"/>SLD selected endpointURL <xsl:value-of select="$endpointURL"/></xsl:message>
    </xsl:if>

    <!-- ================================================================= -->          
    <!-- (3) Set backend routing URL variable and request is forwarded     -->
    <!--     to desired endpoint. Also set the backend routing SSL Profile -->
    <!--     if present.                                                   -->
    <!-- ================================================================= -->          
    <dp:set-variable name="'var://service/routing-url'" value="string($endpointURL)" />

    <xsl:if test="string-length($RoutingSSLProfile) != 0">
        <dp:set-variable name="'var://service/routing-url-sslprofile'" value="string($RoutingSSLProfile)" />
    </xsl:if>
   
</xsl:if>

</xsl:template>
  
</xsl:stylesheet>
