<?xml version="1.0" encoding="utf-8"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2013. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:dpfunc='http://www.datapower.com/extensions/functions'
                xmlns:dp="http://www.datapower.com/extensions"
                extension-element-prefixes="dp"
                exclude-result-prefixes="dpfunc dp">

    <xsl:include href="store:///dp/msgcat/mplane.xml.xsl"/>
    <xsl:import href="webgui:///webmsgcat.xsl"/>

    <!-- output options -->
    <xsl:output method="xml" encoding="utf-8" indent="yes"/>

    <dp:summary>
        <operation>conformance-checker</operation>
        <description>DataPower Configuration Profiler</description>
    </dp:summary>

    <!-- this can be set from the CLI to see debug output. -->
    <xsl:variable name="debug" select="dp:variable('var://system/soma/debug')"/>

    <xsl:template match="/">
        <xsl:if test="($debug &gt; 1)">
            <xsl:message dp:priority="info" dp:id="{$DPLOG_MPLANE_PROF_CONF_CFG}">
            </xsl:message>
        </xsl:if>

        <ConformanceAnalysis>
            <xsl:variable name="config" select="'{http://www.datapower.com/param/config}'"/>
            <xsl:variable name="configuration" select="input/configuration"/>
            <xsl:variable name="lang">
                <xsl:choose>
                    <xsl:when test="input/locale">
                        <xsl:value-of select="input/locale"/>
                    </xsl:when>
                    <xsl:otherwise>en</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <!-- (1) non-default domains without default visible -->
            <xsl:variable name="Domains" select="$configuration/Domain[@name != 'default']"/>
            <xsl:for-each select="$Domains">
                <xsl:if test="not(NeighborDomain = 'default')">
                    <Report type="Miscellaneous" severity="Warn">
                        <Location object-type="{local-name()}" object-name="{@name}"/>
                        <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-cfg-bp.domains.details')"/></Details>
                    </Report>
                </xsl:if>
            </xsl:for-each>

            <!-- (2) load-balancers defined, but not referenced -->
            <xsl:variable name="LBGroups" select="$configuration/LoadBalancerGroup"/>
            <xsl:for-each select="$LBGroups">
                <xsl:if test="not($configuration//*[@class = 'LoadBalancerGroup'] = @name)">
                    <Report type="Miscellaneous" severity="Warn">
                        <Location object-type="{local-name()}" object-name="{@name}"/>
                        <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-cfg-bp.lbgroups.details')"/></Details>
                    </Report>
                </xsl:if>
            </xsl:for-each>

            <!-- (3) MPGW or WSProxy with url forwarding option misset -->
            <xsl:variable name="ServiceURLFwd" select="$configuration/*[(local-name() = 'WSGateway') or 
                                                                        (local-name() = 'MultiProtocolGateway')]"/>
            <xsl:for-each select="$ServiceURLFwd">
                <xsl:if test="not(PropagateURI = 'off')">
                    <Report type="Miscellaneous">
                        <xsl:attribute name="severity">
                            <xsl:choose>
                                <xsl:when test="local-name() = 'WSGateway'">Fail</xsl:when>
                                <xsl:otherwise>Warn</xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <Location object-type="{local-name()}" object-name="{@name}"/>
                        <ParameterName>PropagateURI</ParameterName>
                        <PermittedSetting>off</PermittedSetting>
                        <ActualSetting><xsl:value-of select="PropagateURI"/></ActualSetting>
                        <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-cfg-bp.serviceURLFwd.details')"/></Details>
                    </Report>
                </xsl:if>
            </xsl:for-each>

            <!-- (4) host alias with invalid local interface -->
            <xsl:variable name="HostAlias" select="$configuration/HostAlias"/>
            <xsl:for-each select="$HostAlias">
                <xsl:variable name="ip" select="IPAddress"/>
                <xsl:if test="not($configuration/EthernetInterface/*[(text() = $ip) or (substring-before(text(),'/') = $ip)])">
                    <Report type="Miscellaneous" severity="Fail">
                        <Location object-type="{local-name()}" object-name="{@name}"/>
                        <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-cfg-bp.hostAlias.details')"/></Details>
                    </Report>
                </xsl:if>
            </xsl:for-each>

            <!-- (5) actions, rules and stylepolicies defined, but not referenced -->
            <xsl:variable name="Leftovers" select="$configuration/*[(local-name() = 'StylePolicyAction') or 
                                                                    (local-name() = 'StylePolicyRule') or 
                                                                    (local-name() = 'StylePolicy') or
                                                                    (local-name() = 'Matching')]"/>
            <xsl:for-each select="$Leftovers">
                <xsl:variable name="class" select="local-name()"/>
                <xsl:if test="not($configuration//*[@class = $class] = @name) and
                              not(@intrinsic = 'true')">
                    <Report type="Miscellaneous" severity="Info">
                        <Location object-type="{local-name()}" object-name="{@name}"/>
                        <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-cfg-bp.leftovers.details')"/></Details>
                    </Report>
                </xsl:if>
            </xsl:for-each>

            <!-- (6) probe enabled on services -->
            <xsl:variable name="probe" select="$configuration/*[DebugMode and not(DebugMode = 'off')]"/>
            <xsl:for-each select="$probe">
                <Report type="Miscellaneous" severity="Warn">
                    <Location object-type="{local-name()}" object-name="{@name}"/>
                        <ParameterName>DebugMode</ParameterName>
                        <PermittedSetting>off</PermittedSetting>
                        <ActualSetting><xsl:value-of select="DebugMode"/></ActualSetting>
                        <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-cfg-bp.probe.details')"/></Details>
                </Report>
            </xsl:for-each>
            
            <!-- (7) logging 'debug' 'all' -->
            <xsl:variable name="debuglog" select="$configuration/LogTarget[LogEvents[(Class = 'all') and
                                                                                     (Priority = 'debug')]]"/>
            <xsl:for-each select="$debuglog">
                <Report type="Miscellaneous" severity="Warn">
                    <Location object-type="{local-name()}" object-name="{@name}"/>
                    <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-cfg-bp.debuglog.details')"/></Details>
                </Report>
            </xsl:for-each>
            
            <!-- (8) file capture enabled-->
            <xsl:variable name="debuglog2" select="$configuration/xmltrace[not(Mode = 'off')]"/>
            <xsl:for-each select="$debuglog2">
                <Report type="Miscellaneous" severity="Warn">
                    <Location object-type="{local-name()}" object-name="{@name}"/>
                    <ParameterName>Mode</ParameterName>
                    <PermittedSetting>off</PermittedSetting>
                    <ActualSetting><xsl:value-of select="Mode"/></ActualSetting>
                    <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-cfg-bp.debuglog2.details')"/></Details>
                </Report>
            </xsl:for-each>
            
            <!-- (9) do not allow SSLv2 -->
            <xsl:variable name="sslv2profile" select="$configuration/CryptoProfile[SSLOptions/Disable-SSLv2 = 'off']"/>
            <xsl:for-each select="$sslv2profile">
                <Report type="Miscellaneous" severity="Fail">
                    <Location object-type="{local-name()}" object-name="{@name}"/>
                    <ParameterName>SSLOptions/Disable-SSLv2</ParameterName>
                    <PermittedSetting>on</PermittedSetting>
                    <ActualSetting><xsl:value-of select="SSLOptions/Disable-SSLv2"/></ActualSetting>
                    <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-cfg-bp.sslv2profile.details')"/></Details> 
                </Report>
            </xsl:for-each>
            
            <!-- (10) verify action without valcred -->
            <xsl:variable name="verifynoval" select="$configuration/StylePolicyAction[(Type = 'filter') and 
                                                                                      (Transform = 'store:///verify.xsl') and
                                                                                      not(StylesheetParameters/ParameterName = '{http://www.datapower.com/param/config}valcred')]"/>
            <xsl:for-each select="$verifynoval">
                <Report type="Miscellaneous" severity="Warn">
                    <Location object-type="{local-name()}" object-name="{@name}"/>
                    <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-cfg-bp.verifynoval.details')"/></Details> 
                </Report>
            </xsl:for-each>

            <!-- (11) ssh, telnet, webgui, or xml-mgmt configured on all local interfaces -->
            <xsl:variable name="mgmtwith0" select="$configuration/*[((local-name() = 'TelnetService') or 
                                                                    (local-name() = 'SSHService') or 
                                                                    (local-name() = 'WebGUI') or
                                                                    (local-name() = 'MgmtInterface')) and 
                                                                    ((LocalAddress = '0') or (LocalAddress = '0.0.0.0')) and
                                                                    (mAdminState = 'enabled')]"/>
            <xsl:for-each select="$mgmtwith0">
                <Report type="Miscellaneous" severity="Warn">
                    <Location object-type="{local-name()}" object-name="{@name}"/>
                    <ParameterName>LocalAddress</ParameterName>
                    <PermittedSetting/>
                    <ActualSetting><xsl:value-of select="LocalAddress"/></ActualSetting>
                    <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-cfg-bp.mgmtwith0.details')"/></Details>
                </Report>
            </xsl:for-each>
            
            <!-- (12) check for valid webgui timeout -->
            <xsl:variable name="webguiIdle" select="$configuration/WebGUI[IdleTimeout = '0']"/>
            <xsl:for-each select="$webguiIdle">
                <Report type="Miscellaneous" severity="Warn">
                    <Location object-type="{local-name()}" object-name="{@name}"/>
                    <ParameterName>IdleTimeout</ParameterName>
                    <PermittedSetting>600</PermittedSetting>
                    <ActualSetting><xsl:value-of select="IdleTimeout"/></ActualSetting>
                    <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-cfg-bp.webguiIdle.details')"/></Details>
                </Report>
            </xsl:for-each>
            
            <!-- (13) check for webgui save-config overwrite -->
            <xsl:variable name="webguiSave" select="$configuration/WebGUI[SaveConfigOverwrites = 'off']"/>
            <xsl:for-each select="$webguiSave">
                <Report type="Miscellaneous" severity="Warn">
                    <Location object-type="{local-name()}" object-name="{@name}"/>
                    <ParameterName>SaveConfigOverwrites</ParameterName>
                    <PermittedSetting>on</PermittedSetting>
                    <ActualSetting><xsl:value-of select="SaveConfigOverwrites"/></ActualSetting>
                    <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-cfg-bp.webguiSave.details')"/></Details>
                </Report>
            </xsl:for-each>
            
            <!-- (14) document cache disabled on xmlmgr -->
            <xsl:variable name="nodoccache" select="$configuration/XMLManager[DocCacheSize = '0']"/>
            <xsl:for-each select="$nodoccache">
                <Report type="Miscellaneous" severity="Info">
                    <Location object-type="{local-name()}" object-name="{@name}"/>
                    <ParameterName>DocCacheSize</ParameterName>
                    <PermittedSetting/>
                    <ActualSetting><xsl:value-of select="DocCacheSize"/></ActualSetting>
                    <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-cfg-bp.nodoccache.details')"/></Details>
                </Report>
            </xsl:for-each>
            
            <!-- (15) document cache enabled on xmlmgr but no policy -->
            <xsl:variable name="doccachepol" select="$configuration/XMLManager[DocCacheSize != '0' and  
                                                                               not(DocCachePolicy)]"/>
            <xsl:for-each select="$doccachepol">
                <Report type="Miscellaneous" severity="Fail">
                    <Location object-type="{local-name()}" object-name="{@name}"/>
                    <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-cfg-bp.doccachepol.details')"/></Details>
                </Report>
            </xsl:for-each>
            
            <!-- (16) log target without event subscription -->
            <xsl:variable name="logtargets1" select="$configuration/LogTarget[not(LogEvents)]"/>
            <xsl:for-each select="$logtargets1">
                <Report type="Miscellaneous" severity="Fail">
                    <Location object-type="{local-name()}" object-name="{@name}"/>
                    <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-cfg-bp.logtargets1.details')"/></Details>
                </Report>
            </xsl:for-each>
                        
            <!-- (17) check for RBM 'apply-cli' if AU is set to 'client-ssl' -->
            <xsl:variable name="rbmNoCLI" select="$configuration/RBMSettings[(AUMethod = 'client-ssl') and (ApplyToCLI = 'on')]"/>
            <xsl:for-each select="$rbmNoCLI">
                <Report type="Miscellaneous">
                    <xsl:attribute name="severity">
                        <xsl:choose>
                            <xsl:when test="$configuration/RBMSettings[FallbackLogin = 'disabled']">Fail</xsl:when>
                            <xsl:otherwise>Warn</xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <Location object-type="{local-name()}" object-name="{@name}"/>
                    <ParameterName>ApplyToCLI</ParameterName>
                    <PermittedSetting>off</PermittedSetting>
                    <ActualSetting><xsl:value-of select="ApplyToCLI"/></ActualSetting>
                    <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-cfg-bp.rbmNoCLI.details')"/></Details>
                </Report>
            </xsl:for-each>
            
        </ConformanceAnalysis>
    </xsl:template>
</xsl:stylesheet>
