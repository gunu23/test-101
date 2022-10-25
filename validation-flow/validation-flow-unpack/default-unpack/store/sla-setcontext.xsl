<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2013. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpconfig="http://www.datapower.com/param/config"
    extension-element-prefixes="dp"
    exclude-result-prefixes="dp"
>
  <!-- This stylesheet builds the enforcement context for the policy framework. 
       The enforcement context is built while enforcing SLDs and SLAa on the 
       request rules. There are four legitimate ways to call this stylesheet
       
       Examples (presented in typical order of execution)
       Case 1: SLD 
       Inputs:
         RulePrefix: endpoint_4_1
         Mode:  SLD
         Alternative: false
       
       Output:
         <SLD Base="rest_4_1>
           <Rule Name="rest_4_1"/>
         </SLD>
         
       Case 2: SLA
       Inputs 
         RulePrefix: endpoint_4_1_sla1
         Mode:  SLA
         Alternative: false
       
       Output:
         <SLD Base="rest_4_1>
           <Rule Name="rest_4_1"/>
           <SLA Base="rest_4_1_sla1">       (this line added)
             <Rule Name="rest_4_1_sla1"/>   (this line added)
           </SLA>
         </SLD>
       
       Case 3: SLA Alternative  
       Inputs 
         RulePrefix: endpoint_4_1_sla1-2
         Mode:  SLA
         Alternative: true
       
       Output:
         <SLD Base="rest_4_1>
           <Rule Name="rest_4_1"/>
           <SLA Base="rest_4_1_sla1">
             <Rule Name="rest_4_1_sla1-2"/> (this line changed)
           </SLA>
         </SLD>
       
       Case 4: SLD alternative
       Inputs 
         RulePrefix: endpoint_4_1-2
         Mode:  SLD
         Alternative: true
       
       Output:
         <SLD Base="rest_4_1>
           <Rule Name="rest_4_1-2"/>        (this line changed)
           <SLA Base="rest_4_1_sla1">
             <Rule Name="rest_4_1_sla1-2"/>
           </SLA>
         </SLD>
       -->
  <xsl:param name="dpconfig:RulePrefix"  select="''"/>
  <xsl:param name="dpconfig:Mode"        select="'SLD'"/>     <!-- Valid modes are SLD or SLA -->
  <xsl:param name="dpconfig:Alternative" select="'false'"/>   <!-- are we replacing a rule name, or adding? if Alternative='true', then replace -->

  <xsl:template match='/'>
    <xsl:variable name="policyEnforcementContext" select="dp:variable('var://context/policy/enforcement-path')"/>

    <!-- Set the base SLD to use later to find the correct Rule element to replace in SLD/Alternative mode, 
         or to find the right parent SLD for the new/changed SLA in SLA and SLA/Alternative mode -->
    <xsl:if test="$dpconfig:Mode = 'SLD' and $dpconfig:Alternative = 'false'">
      <dp:set-variable name="'var://context/policy/enforcement-path-sld-index'" value="$dpconfig:RulePrefix"/>
    </xsl:if>

    <!-- Set the base SLA to use later to find the correct Rule element to replace in SLD/Alternative mode -->
    <xsl:if test="$dpconfig:Mode = 'SLA' and $dpconfig:Alternative = 'false'">
      <dp:set-variable name="'var://context/policy/enforcement-path-sla-index'" value="$dpconfig:RulePrefix"/>
    </xsl:if>

    <xsl:variable name="result">
      <xsl:choose>
        <xsl:when test="$dpconfig:Mode = 'SLD'">   
        <!-- See Case 1 described above -->
          <xsl:choose>
            <xsl:when test="$dpconfig:Alternative = 'false'">
              <!-- Copy what is already in the enforcement context -->
              <xsl:copy-of select="$policyEnforcementContext"/>

              <!-- Now add the SLD-->
              <xsl:element name="SLD">
                <xsl:attribute name="Base"><xsl:value-of select="$dpconfig:RulePrefix"/></xsl:attribute>
                <xsl:element name="Rule">
                  <xsl:attribute name="Name"><xsl:value-of select="$dpconfig:RulePrefix"/></xsl:attribute>
                </xsl:element>
              </xsl:element>
            </xsl:when>
            
            <xsl:otherwise>    
              <!-- See Case 4 described above -->
              <xsl:for-each select="$policyEnforcementContext/SLD">
                <xsl:choose>
                  <!-- When we find the SLD entry associated with this alternative, recreate it. -->
                  <xsl:when test="@Base = dp:variable('var://context/policy/enforcement-path-sld-index')">
                    <xsl:element name="SLD">
                      <xsl:attribute name="Base"><xsl:value-of select="dp:variable('var://context/policy/enforcement-path-sld-index')"/></xsl:attribute>
                      <xsl:element name="Rule">
                        <xsl:attribute name="Name"><xsl:value-of select="$dpconfig:RulePrefix"/></xsl:attribute>
                      </xsl:element>
                      <xsl:copy-of select="./SLA"/>
                    </xsl:element>
                  </xsl:when>
                  <!-- Otherwise, use what is already in the enforcement context -->
                  <xsl:otherwise>
                    <xsl:copy-of select="."/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each>
              <!-- Replace the "executed rule name" with the new SLA alternative rule name -->
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="$dpconfig:Alternative = 'false'">
              <!-- See Case 2 described above -->
              <xsl:for-each select="$policyEnforcementContext/SLD">
                <xsl:choose>
                  <!-- When we find the SLD entry associated with this alternative, recreate it. -->
                  <xsl:when test="@Base = dp:variable('var://context/policy/enforcement-path-sld-index')">
                    <xsl:element name="SLD">
                      <xsl:attribute name="Base"><xsl:value-of select="dp:variable('var://context/policy/enforcement-path-sld-index')"/></xsl:attribute>
                      <xsl:copy-of select="./Rule"/>
                      <xsl:copy-of select="./SLA"/>
                      <xsl:element name="SLA">
                        <xsl:attribute name="Base"><xsl:value-of select="$dpconfig:RulePrefix"/></xsl:attribute>
                        <xsl:element name="Rule">
                          <xsl:attribute name="Name"><xsl:value-of select="$dpconfig:RulePrefix"/></xsl:attribute>
                        </xsl:element>
                      </xsl:element>
                    </xsl:element>
                  </xsl:when>
                  <!-- Otherwise, use what is already in the enforcement context -->
                  <xsl:otherwise>
                    <xsl:copy-of select="."/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each>
            </xsl:when>

            <xsl:otherwise>
              <!-- See Case 3 described above -->
              <xsl:for-each select="$policyEnforcementContext/SLD">
                <xsl:choose>
                  <!-- When we find the SLA entry associated with this alternative, recreate it. -->
                  <xsl:when test="@Base = dp:variable('var://context/policy/enforcement-path-sld-index')">
                    <xsl:element name="SLD">
                      <xsl:attribute name="Base"><xsl:value-of select="dp:variable('var://context/policy/enforcement-path-sld-index')"/></xsl:attribute>
                      <xsl:copy-of select="./Rule"/>
                      
                      <xsl:for-each select="./SLA">
                        <xsl:choose>
                          <xsl:when test="@Base = dp:variable('var://context/policy/enforcement-path-sla-index')">  <!-- replace the targeted SLA -->
                            <xsl:element name="SLA">
                              <xsl:attribute name="Base"><xsl:value-of select="dp:variable('var://context/policy/enforcement-path-sla-index')"/></xsl:attribute>
                              <xsl:element name="Rule">
                                <xsl:attribute name="Name"><xsl:value-of select="$dpconfig:RulePrefix"/></xsl:attribute>
                              </xsl:element>
                            </xsl:element>
                          </xsl:when>
                          <xsl:otherwise>            <!-- copy all other SLAs -->
                            <xsl:copy-of select="."/>
                          </xsl:otherwise>
                        </xsl:choose>
                      </xsl:for-each>
                    </xsl:element> <!-- SLD -->
                  </xsl:when>
                  <!-- Otherwise, use what is already in the enforcement context -->
                  <xsl:otherwise>
                    <xsl:copy-of select="."/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each>
            </xsl:otherwise>

          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <dp:set-variable name="'var://context/policy/enforcement-path'" value="$result"/>

  </xsl:template>

</xsl:stylesheet>
