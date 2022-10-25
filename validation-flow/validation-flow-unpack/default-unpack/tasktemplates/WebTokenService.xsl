<?xml version="1.0" encoding="utf-8"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2011,2015. 2013. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!DOCTYPE xsl:stylesheet [
  <!ENTITY nbsp "&#160;">
]>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" 
    xmlns:dpwebgui="http://www.datapower.com/webgui" 
    xmlns:dpfunc="http://www.datapower.com/extensions/functions"
    xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp">

    <xsl:import href="/ttMain.xsl" />
    <xsl:import href="/webmsgcat.xsl"/>

    <xsl:variable name="TemplateName" select="'WebTokenService'"/>

    <xsl:variable name="TemplateSummary" select="dpfunc:get-message('tt.WebTokenService.TemplateSummary')"/>   

    <xsl:variable name="TemplateVars">
        <var name="service-name" type="dmObjectName" required="true" style="over-under">
            <display><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.var.service-name.display')"/></display>
            <objType>WebTokenService</objType>
            <description><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.var.service-name.description')"/></description>
        </var>

        <var name="AAAPolicy" type="dmReference" reftype="AAAPolicy" required="true"
            newButton="true" newStep="create-object"
            editButton="true" editStep="extract-identity"
            taskTemplateInputParam="newObjPopupInput"
            taskTemplateEditInputParam="edit-object"
            taskTemplate="AAATaskTemplate">
            <display><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.var.AAAPolicy.display')"/></display>
            <object>StylePolicyAction</object>
            <property>AAA</property>
        </var>

        <var name="FrontSide" type="dmSSLFrontSide" vector="true" style="over-under" required="true">
            <display><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.var.FrontSide.display')"/></display>
            <object>WebTokenService</object>
            <property>FrontSide</property>
        </var>

        <!-- Variable used to check for a forms based login policy, Does not get set directly by the user -->
        <var name="check-forms-login-policy" transient="true"/>

        <!-- Variable used to check if the AAA policy is configured correctly and control the wizard flow -->
        <var name="check-aaa-policy" transient="true"/>

        <!-- Contains the xml string configuration for the FrontSide vector -->
        <var name="jsFrontSide" vector="true"/>

        <var name="WebTokenServiceType" type="dmWebTokenServiceType" style="over-under">
            <display><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.var.WebTokenServiceType.display')"/></display>
            <description><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.var.WebTokenServiceType.description')"/></description>
            <default>oauth</default>
        </var>

        <var name="genFormBasedLoginRule" type="dmToggle" display-format="checkbox" style="over-under">
            <display><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.var.genFormBasedLoginRule.display')"/></display>
        </var>
    </xsl:variable>

    <xsl:variable name="TemplateSteps">
        <step name="create-obj" initial="true">
            <summary><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.step.create-obj.summary')"/></summary>
            <header-spacing>both</header-spacing>
            <section name="create-obj-info"/>
            <section name="obj-name">
                <input>WebTokenServiceType</input>
                <input>service-name</input>
            </section>
            <navigation label="{dpfunc:get-message('tt.WebTokenService.navigation.dir.Cancel')}" dir="Cancel" close="true"/>
            <navigation label="{dpfunc:get-message('tt.WebTokenService.navigation.dir.Next')}" dir="Next">
                <next-step>oauth-token-service-sources</next-step>
            </navigation>
        </step>

        <step name="oauth-token-service-sources">
            <summary><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.step.oauth-token-service-sources.summary')"/></summary>
            <header-spacing>both</header-spacing>
            <section name="token-service-sources-info"/>
            <section name="token-service-sources-input">
                <input>FrontSide</input>
            </section>
            <navigation label="{dpfunc:get-message('tt.WebTokenService.navigation.dir.Back')}" dir="Back"   validation="false">
                <next-step>create-obj</next-step>
            </navigation>
            <navigation label="{dpfunc:get-message('tt.WebTokenService.navigation.dir.Cancel')}" dir="Cancel" close="true"/>
            <navigation label="{dpfunc:get-message('tt.WebTokenService.navigation.dir.Next')}" dir="Next" validation="false">
                <next-step>token-service-aaa</next-step>
                <nav-action>
                    if (document.getElementsByName('jsFrontSide').length == 0) {
                        loadingMaskHide();
                        alert('<xsl:value-of select="dpfunc:javascript-safe-string(dpfunc:get-message('tt.WebTokenService.alertMessage.noSourceAddresses'))"/>');
                        return(false);
                    }
                </nav-action>
            </navigation>
        </step>

        <step name="token-service-aaa">
            <summary><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.step.token-service-aaa.summary')"/></summary>
            <header-spacing>both</header-spacing>
            <section name="token-service-aaa-info"/>
            <section name="aaa-input">
                <input>AAAPolicy</input>
            </section>
            <navigation label="{dpfunc:get-message('tt.WebTokenService.navigation.dir.Back')}" dir="Back"   validation="false">
                <next-step>oauth-token-service-sources</next-step>
            </navigation>
            <navigation label="{dpfunc:get-message('tt.WebTokenService.navigation.dir.Cancel')}" dir="Cancel" close="true"/>
            <navigation label="{dpfunc:get-message('tt.WebTokenService.navigation.dir.Next')}" dir="Next">
                <next-step>
                    <var-binding>check-aaa-policy</var-binding>
                </next-step>
            </navigation>
        </step>

        <step name="token-service-aaa-error" suppress-global-help="true">
            <summary><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.step.token-service-aaa-error.summary')"/></summary>
            <header-spacing>both</header-spacing>
            <section name="token-service-aaa-error-info"/>
            <navigation label="{dpfunc:get-message('tt.WebTokenService.navigation.dir.Back')}" dir="Back" validation="false">
                <next-step>token-service-aaa</next-step>
            </navigation>
            <navigation label="{dpfunc:get-message('tt.WebTokenService.navigation.dir.Cancel')}" dir="Cancel" close="true"/>
        </step>

        <step name="confirm" suppress-global-help="true">
            <summary><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.step.confirm.summary')"/></summary>
            <header-spacing>both</header-spacing>
            <section name="review">
                <input read-only="true">service-name</input>
                <input read-only="true">WebTokenServiceType</input>
                <input read-only="true">FrontSide</input>
                <input read-only="true">AAAPolicy</input>
            </section>
            <section name="forms-based-login-message"/>
            <navigation label="{dpfunc:get-message('tt.WebTokenService.navigation.dir.Back')}" dir="Back" validation="false">
                <next-step>token-service-aaa</next-step>
            </navigation>
            <navigation label="{dpfunc:get-message('tt.WebTokenService.navigation.dir.Cancel')}" dir="Cancel" close="true"/>
            <navigation label="{dpfunc:get-message('tt.WebTokenService.navigation.dir.Commit')}" dir="Commit">
                <next-step>commit</next-step>
             </navigation>
        </step>

        <step name="commit" exec-config="true" help-inline="false" suppress-global-help="true">
            <section name="do-config" exec-config="true">
                <output-binding>main</output-binding>
            </section>
            <section name="success">
                <navigation label="{dpfunc:get-message('tt.WebTokenService.navigation.dir.Done')}" dir="Done" close="true"/>
                <navigation label="{dpfunc:get-message('tt.WebTokenService.navigation.dir.View_Web_Token_Service')}" dir="View Web Token Service">
                    <nav-action>genericRequest('/configure/WebTokenService/' + document.getElementById('input_service-name').value);</nav-action>
                </navigation>
            </section>
            <section name="error">
                <navigation label="{dpfunc:get-message('tt.WebTokenService.navigation.dir.Back')}" dir="Back" validation="false">
                    <next-step>confirm</next-step>
                </navigation>
                <navigation label="{dpfunc:get-message('tt.WebTokenService.navigation.dir.Cancel')}" dir="Cancel" close="true"/>
            </section>
        </step>
    </xsl:variable>

    <xsl:variable name="TemplateMessages">
        <message name="success">
		<text msgid="tt.WebTokenService.TemplateMessages.success">
            <variable>service-name</variable>
		</text>
	</message>
        <message name="error">
		<text msgid="tt.WebTokenService.TemplateMessages.error">
            <variable>service-name</variable>
		</text>
	</message>
    </xsl:variable>

    <xsl:variable name="TemplateBindings">
        <output name="main">
            <!-- Naming convention: <wst_name>_rule_<ruleIndex>_<action>_<actionIndex> -->
            <!-- Generate the rules to support form based login if it was detected on the AAA policy -->
            <xsl:if test="string($VarValues/value[@name='check-forms-login-policy'])='on'">
                <xsl:variable name="formsBasedLoginConfig">
                    <xsl:call-template name="get-config-forms-based-login"/>
                </xsl:variable>

                <xsl:variable name="LoginForm" select="$formsBasedLoginConfig/FormsLoginPolicy/LoginForm"/>
                <xsl:variable name="ErrorPage" select="$formsBasedLoginConfig/FormsLoginPolicy/ErrorPage"/>

                <!-- PCRE Match expression looks like -->
                <!-- (/LoginPage.htm|/ErrorPage.htm)(\?originalUrl=.*)? -->
                <xsl:variable name="regexFBL" select="concat('(',$LoginForm, '|', $ErrorPage, ')(\?originalUrl=.*)?')"/>

                <!-- Forms based login AAA Policy, this is different from the one supplied in the wizard -->
                <!-- Requires the forms login policy from the user supplied AAA Policy -->
                <!-- This AAA policy will be named using the AAA policy supplied and appending _unauthenticated -->
                <AAAPolicy>
                    <xsl:attribute name="name">
                        <xsl:value-of select="concat($VarValues/value[@name='AAAPolicy'], '_unauthenticated')"/> 
                    </xsl:attribute>
                    <ExtractIdentity>
                        <EIBitmap>
                            <html-forms-auth>on</html-forms-auth>
                        </EIBitmap>
                        <!-- Take the forms based login policy from the original AAA policy supplied -->
                        <EIFormsLoginPolicy>
                            <xsl:value-of select="$AAAConfig/AAAPolicy/ExtractIdentity/EIFormsLoginPolicy"/>
                        </EIFormsLoginPolicy>
                    </ExtractIdentity>
                    <Authenticate>
                        <AUMethod>token</AUMethod>
                        <AUCacheAllow>absolute</AUCacheAllow>
                        <AUCacheTTL>3</AUCacheTTL>
                    </Authenticate>
                    <MapCredentials>
                        <MCMethod>none</MCMethod>
                    </MapCredentials>
                    <ExtractResource>
                        <ERBitmap>
                            <original-url>on</original-url>
                        </ERBitmap>
                    </ExtractResource>
                    <MapResource>
                        <MRMethod>none</MRMethod>
                    </MapResource>
                    <Authorize>
                        <AZMethod>passthrough</AZMethod>
                        <AZCacheAllow>absolute</AZCacheAllow>
                        <AZCacheTTL>3</AZCacheTTL>
                    </Authorize>
                </AAAPolicy>

                <!-- Forms based login rules consist of a regular expression match on the LoginForm, and Error page
                     persisted in the AAA Policy FormsLoginPolicy. -->
                <Matching>
                    <xsl:attribute name="name">
                      <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_0_match_0')"/>
                    </xsl:attribute>
                    <MatchWithPCRE>on</MatchWithPCRE>
                    <MatchRules>
                      <Type>url</Type>
                      <Url><xsl:value-of select="$regexFBL"/></Url>
                    </MatchRules>
                </Matching>

                <StylePolicyAction>
                    <xsl:attribute name="name">
                      <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_0_aaa_0')"/>
                    </xsl:attribute>
                    <Type>aaa</Type>
                    <AAA>
                        <xsl:value-of select="concat($VarValues/value[@name='AAAPolicy'], '_unauthenticated')"/>                    
                    </AAA>
                    <Input>INPUT</Input>
                    <Output>PIPE</Output>
                </StylePolicyAction>

                <StylePolicyAction>
                    <xsl:attribute name="name">
                      <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_0_results_0')"/>
                    </xsl:attribute>
                  <Type>results</Type>
                  <Input>PIPE</Input>
                  <OutputType>default</OutputType>
                </StylePolicyAction>

                <StylePolicyRule>
                    <xsl:attribute name="name">
                        <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_0')"/>
                    </xsl:attribute>
                    <Direction>request-rule</Direction>
                    <Actions>
                        <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_0_aaa_0')"/>
                    </Actions>
                    <Actions>
                        <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_0_results_0')"/>
                    </Actions>
                </StylePolicyRule>
            </xsl:if>

            <!-- Rule 1 configuration constists of a match on /favicon.ico and a results action -->
            <Matching>
                <xsl:attribute name="name">
                  <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_1_match_0')"/>
                </xsl:attribute>
                <MatchWithPCRE>on</MatchWithPCRE>
                <MatchRules>
                  <Type>url</Type>
                  <Url>.*/favicon.ico</Url>
                </MatchRules>
            </Matching>

            <StylePolicyAction>
                <xsl:attribute name="name">
                  <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_1_results_0')"/>
                </xsl:attribute>
              <Type>results</Type>
              <Input>INPUT</Input>
              <OutputType>default</OutputType>
            </StylePolicyAction>

            <StylePolicyRule>
                <xsl:attribute name="name">
                    <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_1')"/>
                </xsl:attribute>
                <Direction>request-rule</Direction>
                <Actions>
                    <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_1_results_0')"/>
                </Actions>
            </StylePolicyRule>

            <!-- Rule 2 configuration consitsts of a match all followed by an HTTP convert and user provided AAA action -->
            <Matching>
                <xsl:attribute name="name">
                  <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_2_match_0')"/>
                </xsl:attribute>
                <MatchRules>
                  <Type>url</Type>
                  <Url>*</Url>
                </MatchRules>
            </Matching>

            <!-- keep the same number for the rule, for the least interruption further down -->
            <xsl:choose>
                <xsl:when test="$VarValues/value[@name='WebTokenServiceType'] = 'other'">
                    <StylePolicyAction>
                        <xsl:attribute name="name">
                            <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_2_aaa_0')"/>
                        </xsl:attribute>
                        <Type>aaa</Type>
                        <AAA><xsl:value-of select="$VarValues/value[@name='AAAPolicy']"/></AAA>
                        <Input>INPUT</Input>
                        <Output>PIPE</Output>
                    </StylePolicyAction>
                </xsl:when>
                <xsl:otherwise>
                    <StylePolicyAction>
                        <xsl:attribute name="name">
                            <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_2_convert-http_0')"/>
                        </xsl:attribute>
                        <Type>convert-http</Type>
                        <Input>INPUT</Input>
                        <Output>PIPE</Output>
                    </StylePolicyAction>

                    <StylePolicyAction>
                        <xsl:attribute name="name">
                            <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_2_aaa_0')"/>
                        </xsl:attribute>
                        <Type>aaa</Type>
                        <AAA><xsl:value-of select="$VarValues/value[@name='AAAPolicy']"/></AAA>
                        <Input>PIPE</Input>
                        <Output>PIPE</Output>
                    </StylePolicyAction>
                </xsl:otherwise>
            </xsl:choose>

            <StylePolicyAction>
                <xsl:attribute name="name">
                  <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_2_results_0')"/>
                </xsl:attribute>
              <Type>results</Type>
              <Input>PIPE</Input>
              <OutputType>default</OutputType>
            </StylePolicyAction>

            <StylePolicyRule>
                <xsl:attribute name="name">
                    <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_2')"/>
                </xsl:attribute>
                <Direction>request-rule</Direction>
                <xsl:if test="$VarValues/value[@name='WebTokenServiceType'] = 'oauth'">
                    <Actions>
                        <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_2_convert-http_0')"/>
                    </Actions>
                </xsl:if>
                <Actions>
                    <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_2_aaa_0')"/>
                </Actions>
                <Actions>
                    <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_2_results_0')"/>
                </Actions>
            </StylePolicyRule>
            
            <!-- Style Policy -->
            <StylePolicy>
                <attr-binding attr="name">service-name</attr-binding>
                <PolicyMaps>
                    <Match>
                        <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_1_match_0')"/>
                    </Match>
                    <Rule>
                        <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_1')"/>
                    </Rule>
                </PolicyMaps>
                <xsl:if test="string($VarValues/value[@name='check-forms-login-policy'])='on'">
                    <PolicyMaps>
                        <Match>
                            <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_0_match_0')"/>
                        </Match>
                        <Rule>
                            <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_0')"/>
                        </Rule>
                    </PolicyMaps>
                </xsl:if>
                <PolicyMaps>
                    <Match>
                        <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_2_match_0')"/>
                    </Match>
                    <Rule>
                        <xsl:value-of select="concat($VarValues/value[@name='service-name'], '_rule_2')"/>
                    </Rule>
                </PolicyMaps>
            </StylePolicy>

            <!-- Web Token Service -->
            <WebTokenService>
                <attr-binding attr="name">service-name</attr-binding>
                <StylePolicy>
                  <var-binding>service-name</var-binding>
                </StylePolicy>
                <xsl:for-each select="$request/args//jsFrontSide">
                    <xsl:copy-of select="dp:parse(.)"/>
                </xsl:for-each>
            </WebTokenService>
        </output>
    </xsl:variable>

    <!-- Need information from the AAA policy if one has been set -->
    <xsl:variable name="AAAConfig">
        <xsl:variable name="AAAPolicyName" select="$request/args/AAAPolicy"/>
        <xsl:if test="not(string($AAAPolicyName) = '')">
            <xsl:variable name="tempAAAConfig">
                <xsl:call-template name="do-mgmt-request">
                    <xsl:with-param name="request">
                        <request>
                            <operation type='get-config'>
                                <request-class>AAAPolicy</request-class>
                                <request-name><xsl:value-of select="$AAAPolicyName"/></request-name>
                            </operation>
                        </request>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:variable>
            <xsl:copy-of select="$tempAAAConfig/response/operation/configuration/AAAPolicy"/>
        </xsl:if>
    </xsl:variable>

    <!-- Checks for the forms based login policy -->
    <xsl:template name="get-config-forms-based-login"> 
        <xsl:variable name="HTMLFBLPolicy" select="$AAAConfig/AAAPolicy/ExtractIdentity/EIFormsLoginPolicy"/>
        <xsl:if test="$HTMLFBLPolicy/@class = 'FormsLoginPolicy'">        
            <xsl:variable name="HTMLFBLPolicyConfig">
                <xsl:call-template name="do-mgmt-request">
                    <xsl:with-param name="request">
                        <request>
                            <operation type='get-config'>
                                <request-class>FormsLoginPolicy</request-class>
                                <request-name><xsl:value-of select="$HTMLFBLPolicy"/></request-name>
                            </operation>
                        </request>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:variable> 
            <xsl:copy-of select="$HTMLFBLPolicyConfig/response/operation/configuration/FormsLoginPolicy"/> 
        </xsl:if>  
    </xsl:template>

    <!-- Called to check if the AAA policy is enabled for Oauth authorization -->
    <!-- Checks must be made at the EI, AU, ER, AZ and PP setps of the AAA policy -->
    <xsl:template mode="variable-value-form" match="var[@name='check-aaa-policy']" priority="5">
        <!--
        <xsl:variable name="AAAOauthEIEnabled" select="$AAAConfig/AAAPolicy/ExtractIdentity/EIBitmap/oauth = 'on'"/>
        <xsl:variable name="AAAOauthAUMethod" select="not($AAAConfig/AAAPolicy/Authenticate/AUOAuth = 'off')"/>
        <xsl:variable name="AAAOauthAZMethod" select="$AAAConfig/AAAPolicy/Authorize/AZMethod = 'oauth'"/>
        <xsl:variable name="AAAOauthPPMethod" select="$AAAConfig/AAAPolicy/PostProcess/PPOAuth = 'on'"/>
        <xsl:variable name="AAAOauthEREnabled" select="$AAAConfig/AAAPolicy/ExtractResource/ERBitmap/oauth = 'on'"/>
        -->

        <value name="{@name}">
            <xsl:choose>
                
                <xsl:when test="var[@name='WebTokenServiceType'] = 'oauth' and
                                $AAAConfig/AAAPolicy/ExtractIdentity/EIBitmap/oauth != 'on'"> 
                    <xsl:text>token-service-aaa-error</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>confirm</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </value>
    </xsl:template>

    <!-- Called to check if the AAA policy contains a forms based login policy -->
    <xsl:template mode="variable-value-form" match="var[@name='check-forms-login-policy']" priority="5">
        <value name="{@name}">
            <xsl:variable name="formsBasedLoginEnabled" select="$AAAConfig/AAAPolicy/ExtractIdentity/EIBitmap/html-forms-auth = 'on'"/>
            <xsl:variable name="formsBasedLoginConfig">
                <xsl:call-template name="get-config-forms-based-login"/>
            </xsl:variable>

            <xsl:choose>
                <xsl:when test="$formsBasedLoginConfig/FormsLoginPolicy/FormSupportType = 'custom'">
                    <xsl:text>off</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="LoginForm" select="$formsBasedLoginConfig/FormsLoginPolicy/LoginForm"/>
                    <xsl:variable name="ErrorPage" select="$formsBasedLoginConfig/FormsLoginPolicy/ErrorPage"/>
                    <xsl:variable name="LogoutPage" select="$formsBasedLoginConfig/FormsLoginPolicy/LogoutPage"/>

                    <xsl:choose>
                        <xsl:when test="$formsBasedLoginEnabled and $LoginForm and $ErrorPage and $LogoutPage">
                            <xsl:text>on</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>off</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </value>
    </xsl:template>

    <!-- Message text -->
    <xsl:template mode="section-content" match="section[@name='create-obj-info']">
        <tr>
            <td>
                <div class="wizardtext">
            <xsl:call-template name="renderOnGlass">
            <xsl:with-param name="unique" select="'createwts'"/>
              <xsl:with-param name="onGlass">
                <purpose><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.create-obj-info.purpose')"/></purpose>
                <description>
                  <xsl:copy-of select="dpfunc:get-message('tt.WebTokenService.create-obj-info.description')"/>
                </description>
              </xsl:with-param>
            </xsl:call-template>
                </div>
            </td>
        </tr>
    </xsl:template>

    <xsl:template mode="section-content" match="section[@name='token-service-aaa-info']">
        <tr>
            <td>
                <div class="wizardtext">
                    <xsl:call-template name="renderOnGlass">
            <xsl:with-param name="unique" select="'aaasettings'"/>
              <xsl:with-param name="onGlass">
                <purpose><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.token-service-aaa-info.purpose')"/></purpose>
                <description>
                    <xsl:copy-of select="dpfunc:get-message('tt.WebTokenService.token-service-aaa-info.description')"/>
                </description>
              </xsl:with-param>
            </xsl:call-template>
                </div>
            </td>
        </tr>
    </xsl:template>

    <xsl:template mode="section-content" match="section[@name='token-service-sources-info']">
        <tr>
            <td>
                <div class="wizardtext">
                    <xsl:call-template name="renderOnGlass">
            <xsl:with-param name="unique" select="'clientsettings'"/>
              <xsl:with-param name="onGlass">
                <purpose><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.token-service-sources-info.purpose')"/></purpose>
                <description>
                    <xsl:copy-of select="dpfunc:get-message('tt.WebTokenService.token-service-sources-info.description')"/>
                </description>
              </xsl:with-param>
            </xsl:call-template>
                </div>
            </td>
        </tr>
    </xsl:template>

    <xsl:template mode="section-content" match="section[@name='token-service-fbl-error-info']">
        <tr>
            <td>
                <div class="wizardtext">
					<xsl:copy-of select="dpfunc:get-message('tt.WebTokenService.wizardtext.token-service-fbl-error')"/>
                </div>
            </td>
        </tr>
    </xsl:template>

    <xsl:template mode="section-content" match="section[@name='token-service-aaa-error-info']">
        <tr>
            <td>
                <div class="wizardtext">
					<xsl:copy-of select="dpfunc:get-message('tt.WebTokenService.wizardtext.token-service-aaa-error')"/>
                </div>
            </td>
        </tr>
    </xsl:template>

    <xsl:template mode="section-content" match="section[@name='forms-based-login-message']">
        <xsl:if test="string($VarValues/value[@name='check-forms-login-policy'])='on'">
	        <xsl:variable name="aaaName">
	            <param><xsl:value-of select="$VarValues/value[@name='AAAPolicy']"/></param>   
            </xsl:variable>
            <tr>
                <td>
                    <div class="wizardtext">
						<xsl:copy-of select="dpfunc:get-message('tt.WebTokenService.wizardtext.forms-based-login', $aaaName)"/>
                    </div>
                </td>
            </tr>
        </xsl:if>
    </xsl:template>

    <!-- This template is used to render the FrontSide complex vector -->
    <xsl:template mode="schema-input-wrap" match="*[self::property or self::var][@name='FrontSide']" priority="5"
        name="multi-select-edit-field" >
        <xsl:param name="pname" select="@name"/>

        <xsl:variable name="reftype" select="@reftype"/>

        <!-- This is the table that gets built showing the configured and assigned front-sides-->
        <div id="front-side-list">
            <table border="0" cellspacing="0" cellpadding="0" class="list-table" id="fs-table">
                <thead>
                <tr>
                    <th class="left"><label for="input_ip_{$pname}"><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.table.ip')"/></label></th>
   	                <th><label for="input_port_{$pname}"><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.table.port')"/></label></th>
       	            <th style="min-width:60px;"><label for="input_ssl_{$pname}"><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.table.ssl')"/></label></th>
       	            <th style="min-width:300px;"><label for="input_ssl_proxy_profile{$pname}"><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.table.ssl.proxy.profile')"/></label></th>
       	            <th class="right" style="min-width:60px;"><label for="btn_multiadd_{$pname}"><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.table.action')"/></label></th>
           	    </tr>
           	    </thead>
                <tbody class="list-table-body">
                <xsl:for-each select="$request/args//jsFrontSide">
                    <xsl:variable name="currentNode">
                        <xsl:copy-of select="dp:parse(.)"/>
                    </xsl:variable>
                    <xsl:if test="$currentNode != ''">
                       <xsl:variable name="localPort" select="$currentNode//LocalPort"/>
                       <xsl:variable name="localAddr" select="$currentNode//LocalAddress"/>
                       <xsl:variable name="useSSL" select="$currentNode//UseSSL"/>
                       <xsl:variable name="proxyProfile">
                         <xsl:choose>
                           <xsl:when test="$currentNode//SSLServerConfigType = 'server'">
                             <xsl:value-of select="$currentNode//SSLServer"/>
                           </xsl:when>
                           <xsl:when test="$currentNode//SSLServerConfigType = 'sni'">
                             <xsl:value-of select="$currentNode//SSLSNIServer"/>
                           </xsl:when>
                           <xsl:otherwise>
                             <xsl:value-of select="$currentNode//SSLProxyProfile"/>
                           </xsl:otherwise>
                         </xsl:choose>
                       </xsl:variable>

                       <tr id="{$localAddr}_{$localPort}_row">
                            <td class="left">
                                <!-- type -->
                                <xsl:value-of select="$localAddr"/>
                            </td>
                            <td>
                               <xsl:value-of select="$localPort"/>
                            </td>

                            <td>
                                (
                                <xsl:choose>
                                    <xsl:when test="$useSSL='on'">
                                        <xsl:value-of select="dpfunc:get-message('common.value.on')"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="dpfunc:get-message('common.value.off')"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                                )
                            </td>
                            <td>
                                <xsl:value-of select="$proxyProfile"/>
                            </td>
                           <td class="right rewriteIconButton">
                                <a class="IconButton" href="javascript:void(0)" onclick="deleteFS('{$localAddr}_{$localPort}','{$pname}');">
                                    <img class="IconButtonImg" alt="{dpfunc:get-message('tt.WebTokenService.title.Remove.Icon')}" src="/images/button-icons/remove.gif"/>
                                    <span class="IconButtonLabel"><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.icon.remove')"/></span>
                                </a>
                           </td>
                        </tr>
                    </xsl:if>
                </xsl:for-each>
                </tbody>
                <div id="multi_{$pname}">
                    <tfoot id="multi_edit_{$pname}"  class="list-table-foot inputWrapper">
                        <tr>
                            <td class="left">
                                <xsl:variable name="typeRef1" select="dpfunc:get-complex-property('dmSSLFrontSide', 'LocalAddress')" />
                                <div class="inputWrapper">
                                    <xsl:apply-templates mode="schema-input-wrap" select="$typeRef1">
                                    </xsl:apply-templates> 
                                </div>
                            </td>
                            <td>
                                <xsl:variable name="typeRef2" select="dpfunc:get-complex-property('dmSSLFrontSide', 'LocalPort')" />
                                <div class="inputWrapper">
                                    <xsl:apply-templates mode="schema-input-wrap" select="$typeRef2">
                                    </xsl:apply-templates> 
                                </div>
                            </td>
                            <td>
                                <xsl:variable name="typeRef3" select="dpfunc:get-complex-property('dmSSLFrontSide', 'SSLServerConfigType')" />
                                <div class="inputWrapper">
                                    <xsl:variable name="tempProp">
                                            <property name="SSLServerConfigType" type="dmSSLConfigType">
                                              <xsl:copy-of select="$typeRef3/*[local-name() != 'ignored-when' and local-name() != 'required-when']" />
                                            </property>
                                    </xsl:variable> 

                                    <xsl:apply-templates mode="schema-input-wrap" select="$tempProp/property">
                                    </xsl:apply-templates> 
                                </div>
                            </td>
                            <td>
                                <xsl:variable name="typeRef4a" select="dpfunc:get-complex-property('dmSSLFrontSide', 'SSLProxyProfile')" />
                                <xsl:variable name="typeRef4b" select="dpfunc:get-complex-property('dmSSLFrontSide', 'SSLServer')" />
                                <xsl:variable name="typeRef4c" select="dpfunc:get-complex-property('dmSSLFrontSide', 'SSLSNIServer')" />

                                <!-- re-define the SSLProxyProfile, SSLServer & SSLSNIServer properties here -->
                                <!-- copy part of the ignored-when conditions of the 3 properties in mgmt-schema -->
                                <!-- make the appearance of the 3 properties only depend on the value of "SSLServerConfigType" -->
                                <div class="inputWrapper">
                                    <xsl:variable name="tempProp4a">
                                        <property name="SSLProxyProfile" type="dmReference" reftype="SSLProxyProfile">
                                            <xsl:copy-of select="$typeRef4a/*[local-name() != 'ignored-when' and local-name() != 'required-when']" />                       
                                            <ignored-when>
                                                <condition evaluation="property-does-not-equal">
                                                    <property-name>SSLServerConfigType</property-name>
                                                    <value>proxy</value>
                                                </condition>
                                            </ignored-when>
                                        </property>
                                    </xsl:variable> 
                                    <xsl:apply-templates mode="schema-input-wrap" select="$tempProp4a">
                                    </xsl:apply-templates>
                                </div>
                                <div class="inputWrapper">
                                    <xsl:variable name="tempProp4b">
                                        <property name="SSLServer" type="dmReference" reftype="SSLServerProfile">
                                            <xsl:copy-of select="$typeRef4b/*[local-name() != 'ignored-when' and local-name() != 'required-when']" />
                                            <ignored-when>
                                                <condition evaluation="property-does-not-equal">
                                                    <property-name>SSLServerConfigType</property-name>
                                                    <value>server</value>
                                                </condition>
                                            </ignored-when>
                                        </property>
                                    </xsl:variable>
                                    <xsl:apply-templates mode="schema-input-wrap" select="$tempProp4b">
                                    </xsl:apply-templates>
                                </div>
                                <div class="inputWrapper">
                                    <xsl:variable name="tempProp4c">
                                        <property name="SSLSNIServer" type="dmReference" reftype="SSLSNIServerProfile">
                                            <xsl:copy-of select="$typeRef4c/*[local-name() != 'ignored-when' and local-name() != 'required-when']" />
                                            <ignored-when>
                                                <condition evaluation="property-does-not-equal">
                                                    <property-name>SSLServerConfigType</property-name>
                                                    <value>sni</value>
                                                </condition>
                                            </ignored-when>
                                        </property>
                                    </xsl:variable> 
                                    <xsl:apply-templates mode="schema-input-wrap" select="$tempProp4c">
                                    </xsl:apply-templates>
                                </div>
                            </td>

                            <!--
                            <td colspan='2'>
                                <xsl:variable name="typeRef3" select="dpfunc:get-complex-property('dmSSLFrontSide', 'SSLProxyProfile')" />
                                <xsl:variable name="tempProp">
                                    <property name="SSLProxyProfile" type="dmReference" reftype="SSLProxyProfile">
                                        <xsl:copy-of select="$typeRef3/*[local-name() != 'ignored-when' and local-name() != 'required-when']" />
                                    </property>
                                </xsl:variable> 
                                <div class="inputWrapper" style="white-space:nowrap">
                                    <xsl:apply-templates mode="schema-input-wrap" select="$tempProp/property">
                                    </xsl:apply-templates>
                                </div> 
                            </td>
                            -->
                            <td class="right rewriteIconButton">
                                <a class="IconButton" id="btn_multiadd_{$pname}" href="#" 
                                    onclick="addToFSTable('{$reftype}','{$pname}');">
                                    <img class="IconButtonImg" alt="{dpfunc:get-message('tt.WebTokenService.title.Add.Icon')}" src="/images/button-icons/add.gif"/>
                                    <span class="IconButtonLabel"><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.icon.add')"/></span>
                                </a>
                            </td>
                        </tr>
                    </tfoot>
                </div>
            </table>
        </div>

    </xsl:template>

    <!-- This template is used to render the summary for the FrontSide complex vector just before the commit -->
    <xsl:template mode="template-display-input"  match="*[self::property or self::var][@name='FrontSide']" priority="5">
        <div id="front-side-list">
            <table cellspacing="O" class="wafw-fs-table" id="fs-table">
                <tr>
                    <th><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.table.ip')"/></th>
                    <th><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.table.port')"/></th>
                    <th><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.table.ssl')"/></th>
                    <!--<th><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.table.proxy.profile')"/></th>-->
                    <th><xsl:value-of select="dpfunc:get-message('tt.WebTokenService.table.ssl.proxy.profile')"/></th>
                </tr>
                <xsl:for-each select="$request/args//jsFrontSide">
                    <xsl:variable name="currentNode">
                        <xsl:copy-of select="dp:parse(.)"/>
                    </xsl:variable>

                    <xsl:variable name="proxyProfile">
                        <xsl:choose>
                            <xsl:when test="$currentNode//SSLServerConfigType = 'server'">
                                <xsl:value-of select="$currentNode//SSLServer"/>
                            </xsl:when>
                            <xsl:when test="$currentNode//SSLServerConfigType = 'sni'">
                                <xsl:value-of select="$currentNode//SSLSNIServer"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$currentNode//SSLProxyProfile"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>

                    <xsl:if test="$currentNode != ''">
                        <tr id="{.}_row">
                            <td>
                                <!-- type -->
                                <xsl:value-of select="$currentNode//LocalAddress"/>
                            </td>
                            <td>
                                <xsl:value-of select="$currentNode//LocalPort"/>
                            </td>
                            <td>
                                (
                                <xsl:choose>
                                    <xsl:when test="$currentNode//UseSSL = dpfunc:get-message('common.value.on')">
                                        <xsl:value-of select="dpfunc:get-message('common.value.on')"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="dpfunc:get-message('common.value.off')"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                                )
                            </td>
                            <td>
                                <!--<xsl:value-of select="$currentNode//SSLProxyProfile"/>-->
                                <xsl:choose>
                                    <xsl:when test="$proxyProfile != ''">
                                        <xsl:value-of select="$proxyProfile"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <!-- if no proxyProfile value, display (none) instead -->
                                        <xsl:value-of select="dpfunc:get-message('widgets.opt.none')"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </td>
                        </tr>

                    </xsl:if>
                </xsl:for-each>
            </table>
        </div>
    </xsl:template>

    <!-- This template is resposnible for passing the FrontSide complex vector from page to page -->
    <xsl:template mode="template-hidden-input" match="var[@vector='true' and @name='jsFrontSide']" priority="5">
        <xsl:variable name="varName" select="@name"/>
        <xsl:for-each select="$VarValues/value[@name=$varName]">
            <xsl:choose>
                <xsl:when test="$varName='jsFrontSide' and . != ''">
                    <xsl:variable name="currentNode">
                        <xsl:copy-of select="dp:parse(.)"/>
                    </xsl:variable>
                    <input type="hidden" name="{$varName}" value="{.}" id="FrontSide_{$currentNode//LocalAddress}_{$currentNode//LocalPort}"/>
                </xsl:when>
                <xsl:otherwise>
                    <input type="hidden" name="{$varName}" value="{.}"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
