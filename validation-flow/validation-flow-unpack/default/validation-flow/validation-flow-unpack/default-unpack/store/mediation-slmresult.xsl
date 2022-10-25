<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2011,2014. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
    This stylesheet will parse the <SLMResults> from the slm action and pass on either
    <Conditional>true</Conditional>
    or
    <Conditional>false</Conditional>
    
    depending on the input.  The SLMResult will look like of these
        <SLMResults>
          <PolicyName>mediation-conditional-policy-testservice_5_1-1-SLMPolicy</PolicyName>
          <ExecutionPolicy>terminate-at-first-reject</ExecutionPolicy>
          <Statement>
            <SLMId>1</SLMId>
            <UserString />
            <Resource>
              <result>
                <match />
                <match-type>NoClassifier</match-type>
                <value>*</value>
              </result>
            </Resource>
            <Credential>
              <result>
                <match />
                <match-type>NoClassifier</match-type>
                <value>*</value>
              </result>
            </Credential>
            <CheckResult>reject</CheckResult>
            <ActionResult>log</ActionResult>
            <StatementResult>log</StatementResult>
          </Statement>
      </SLMResults>
     
     and

      <SLMResults>
        <PolicyName>mediation-conditional-policy-testservice_5_1-1-SLMPolicy</PolicyName>
        <ExecutionPolicy>terminate-at-first-reject</ExecutionPolicy>
        <Statement>
          <SLMId>1</SLMId>
          <UserString />
          <Resource>
            <result>
              <match />
              <match-type>NoClassifier</match-type>
              <value>*</value>
            </result>
          </Resource>
          <Credential>
            <result>
              <match />
              <match-type>NoClassifier</match-type>
              <value>*</value>
            </result>
          </Credential>
          <CheckResult>accept</CheckResult>
          <ActionResult>log</ActionResult>
          <StatementResult>log</StatementResult>
        </Statement>
      </SLMResults>

-->

<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpconfig="http://www.datapower.com/param/config"
    extension-element-prefixes="dp dpconfig"
    exclude-result-prefixes="dp dpconfig">

    <xsl:param name="dpconfig:ConditionName" select="''"/>

    <xsl:template match="/">
      <xsl:choose>
        <xsl:when test="/SLMResults/Statement/CheckResult/text() = 'reject'">
          <xsl:element name="Conditional"><xsl:text>true</xsl:text></xsl:element>
        </xsl:when>
        <xsl:otherwise>
          <xsl:element name="Conditional"><xsl:text>false</xsl:text></xsl:element>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:if test="string-length($dpconfig:ConditionName) > 0">
        <dp:set-variable name="concat('var://context/policy/ws-mediationpolicy/result/',$dpconfig:ConditionName)" value="."/>
      </xsl:if>

    </xsl:template>
</xsl:stylesheet>