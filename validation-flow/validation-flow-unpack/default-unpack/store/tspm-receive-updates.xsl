<?xml version="1.0"?>

<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2008,2012. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->


<!-- 

This stylesheet is to be used in conjunction with a configured XML firewall as a client for receiving policy
updates from TSPM 7.0 only. The mechanism used changed between TSPM 7.0 and TSPM 7.1 .

 -->


<xsl:stylesheet xmlns:tspm="http://security.tivoli.ibm.com/policy/distribution" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                xmlns:dp="http://www.datapower.com/extensions" 
                xmlns:mex="http://schemas.xmlsoap.org/ws/2004/09/mex" 
                xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" 
                xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" 
                xmlns:xacml="urn:oasis:names:tc:xacml:2.0:policy:schema:os" 
                xmlns:str="http://exslt.org/strings" 
                xmlns:regExp="http://exslt.org/regular-expressions" 
                xmlns:dp-mgmt="http://www.datapower.com/schemas/management" 
                xmlns:dsig="http://www.w3.org/2000/09/xmldsig#" 
                version="1.0" 
                exclude-result-prefixes="dp xacml" 
                extension-element-prefixes="dp">
    <xsl:include href="store:///dp/msgcat/crypto.xml.xsl" dp:ignore-multiple="yes"/>

    <!-- ============== Change these values to the current environment ============== -->
    <xsl:variable name="managementHost">managementHost</xsl:variable>
    <xsl:variable name="managementPort">5550</xsl:variable>
    <xsl:variable name="user">adminUser</xsl:variable>
    <xsl:variable name="password">adminPassword</xsl:variable>
    <xsl:variable name="tspmCert">name:tspmServerCryptoCert</xsl:variable>
    <xsl:variable name="tspmSSLProxyProfile">tspmSSLProxyProfile</xsl:variable>
    <xsl:variable name="internalSSLProxyProfile">internalSSLProxyProfile</xsl:variable>
    <xsl:variable name="xacmlpdp">tspmPDP</xsl:variable>
    <!-- ============== End variables. Please do not edit below this line ============== -->

    <xsl:strip-space elements="*"/>
    <xsl:output method="xml" version="1.0" encoding="utf-8" indent="yes"/>
    <!-- Define some constants and variables that are used below -->
    <xsl:variable name="current-domain" select="dp:variable('var://service/domain-name')"/>
    <xsl:variable name="wsmex-namespace">http://schemas.xmlsoap.org/ws/2004/09/mex</xsl:variable>
    <xsl:variable name="wsmex-action">http://schemas.xmlsoap.org/ws/2004/09/mex/GetMetadata/Request</xsl:variable>
    <xsl:variable name="xacml-namespace">urn:oasis:names:tc:xacml:2.0:policy:schema:os</xsl:variable>
    <xsl:variable name="wssecpol-namespace">http://docs.oasis-open.org/ws-sx/ws-securitypolicy/200702</xsl:variable>
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="/"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="/">
        <xsl:apply-templates select="//tspm:PolicyDistributionEvents"/>
    </xsl:template>
    <xsl:template match="tspm:PolicyDistributionEvents">
        <xsl:variable name="policy-dist-events" select="."/>
        <!-- VALIDATE THE SIGNATURE -->
        <xsl:message dp:priority="debug">Validating signature of incoming PolicyDistributionEvents message</xsl:message>
        <!-- Step 1, Verify the <SignedInfo> element -->
        <xsl:variable name="canon-method" select="./dsig:Signature/dsig:SignedInfo/dsig:CanonicalizationMethod/@Algorithm"/>
        <xsl:variable name="signed-info-hash" 
                     select="dp:hash( 'http://www.w3.org/2000/09/xmldsig#sha1', dp:canonicalize(./dsig:Signature/dsig:SignedInfo, $canon-method, '', false() ) )"/>
        <xsl:variable name="sign-alg" select="./dsig:Signature/dsig:SignedInfo/dsig:SignatureMethod/@Algorithm"/>
        <xsl:variable name="sign-value" select="./dsig:Signature/dsig:SignatureValue/text()"/>
        <xsl:variable name="is-sig-valid" 
                      select="dp:verify( $sign-alg, $signed-info-hash, $sign-value, $tspmCert )"/>
        <xsl:choose>
            <xsl:when test="$is-sig-valid = ''">
                <!-- Then, we validate all the digests in Reference section -->
                <xsl:message dp:priority="debug">Ensuring contents have not been changed in transit.</xsl:message>
                <xsl:for-each select="./dsig:Signature/dsig:SignedInfo/dsig:Reference">
                    <xsl:variable name="id" select="./@URI"/>
                    <xsl:message dp:priority="debug">
                        Verifying that element '<xsl:value-of select="$id"/>' has not been changed.</xsl:message>
                    <!-- Step 2, Canonicalize -->
                    <xsl:variable name="this-ref" select="$policy-dist-events//*[contains( $id, @id )]"/>
                    <xsl:variable name="canonicalized" select="dp:canonicalize( $this-ref[1], $canon-method, '', false() )"/>
                    <!-- Step 3, Hash: dp:hash(hashAlgorithm, textString) -->
                    <xsl:variable name="hash-algorithm" select="./dsig:DigestMethod/@Algorithm"/>
                    <xsl:variable name="hashed" select="dp:hash( $hash-algorithm, $canonicalized )"/>
                    <xsl:message dp:priority="debug">Computed hash is '<xsl:value-of select="$hashed"/>'</xsl:message>
                    <xsl:choose>
                        <xsl:when test="$hashed=./dsig:DigestValue/text()">
                            <xsl:message dp:priority="debug">Computed digest matches digest in message, reference is intact</xsl:message>
                            <!-- Process this update message -->
                            <xsl:apply-templates select="$this-ref[1]"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message dp:type="crypto" dp:priority="error" dp:id="{$DPLOG_TIVOLI_TSPMUPDATEIGNORED}"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message dp:type="crypto" dp:priority="error" dp:id="{$DPLOG_TIVOLI_TSPMNOTIFICATIONREJECTED}"/>
                <dp:send-error override="true">Message rejected due to invalid signature.</dp:send-error>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- 
        Handle each PolicyDistributionUpdate message in the incoming WS-Notification message.
        
        The PolicyDistributionUpdate message contains both the location to get the update (PolicySource)
        and the protocol to do it (Protocol).
        
        This stylesheet only handles WS-MetadataExchange as the update protocol.
     -->
    <xsl:template match="tspm:PolicyDistributionUpdate">
        <xsl:message dp:priority="debug">Handling PolicyDistributionUpdate message</xsl:message>
        <xsl:variable name="eventType" select="./tspm:EventType"/>
        <xsl:variable name="context" select="./tspm:ContextId"/>
        <xsl:variable name="dialect" select="./tspm:PolicyDialect"/>
        <xsl:message dp:priority="debug">Context: <xsl:value-of select="$context"/></xsl:message>
        <xsl:message dp:priority="debug">Dialect: <xsl:value-of select="$dialect"/></xsl:message>
        <xsl:variable name="instance" select="./tspm:Instance"/>
        <xsl:variable name="origin" select="./tspm:Origin"/>
        <xsl:variable name="transactionId" select="./tspm:TransactionId"/>
        <xsl:message dp:type="crypto" dp:priority="notice" dp:id="{$DPLOG_TIVOLI_TSPMPOLICYUPDATEMSG}">
            <dp:with-param value="{$context}"/>
            <dp:with-param value="{$eventType}"/>
            <dp:with-param value="{$instance}"/>
            <dp:with-param value="{$origin}"/>
            <dp:with-param value="{$transactionId}"/>
        </xsl:message>
        <xsl:choose>
            <xsl:when test="$eventType = 'commit'">
                <xsl:message dp:priority="debug">Found EventType 'commit'</xsl:message>
                <xsl:call-template name="handle-commit">
                    <xsl:with-param name="context" select="$context"/>
                    <xsl:with-param name="dialect" select="$dialect"/>
                    <xsl:with-param name="updateMessage" select="."/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$eventType = 'remove'">
                <xsl:message dp:priority="debug">Found EventType 'remove'</xsl:message>
                <xsl:call-template name="handle-remove">
                    <xsl:with-param name="context" select="$context"/>
                    <xsl:with-param name="dialect" select="$dialect"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message dp:type="crypto" dp:priority="error" dp:id="{$DPLOG_TIVOLI_TSPMINVALIDEVENT}">
                    <dp:with-param value="{$eventType}"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- 
        Handle the EventType="commit" message
     -->
    <xsl:template name="handle-commit">
        <xsl:param name="context"/>
        <xsl:param name="dialect"/>
        <xsl:param name="updateMessage"/>
        <xsl:variable name="toAddress" select="$updateMessage//tspm:PolicySource/wsa:EndpointReference/wsa:Address"/>
        <xsl:variable name="protocol" select="$updateMessage//tspm:PolicySource/tspm:Protocol"/>
        <xsl:message dp:priority="debug">Address: <xsl:value-of select="$toAddress"/></xsl:message>
        <xsl:message dp:priority="debug">Protocol: <xsl:value-of select="$protocol"/></xsl:message>
        <xsl:choose>
            <xsl:when test="$protocol = $wsmex-namespace">
                <xsl:message dp:priority="debug">Specified protocol is WS-MetadataExchange</xsl:message>
                <xsl:message dp:priority="debug">Constructing outbound SOAP message</xsl:message>
                <xsl:variable name="rst">
                    <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" 
                                                          xmlns:enc="http://schemas.xmlsoap.org/soap/encoding/" 
                                                          xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
                                                          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                                                          xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing">
                        <soapenv:Header>
                            <wsa:To>
                                <xsl:value-of select="$toAddress"/>
                            </wsa:To>
                            <!-- Copy all the reference parameters to our output SOAP header,
                                as per the WS-Addressing protocol -->
                            <xsl:for-each select="$updateMessage//tspm:PolicySource/wsa:EndpointReference/wsa:ReferenceParameters/*">
                                <xsl:copy-of select="."/>
                            </xsl:for-each>
                            <wsa:Action>
                                <xsl:value-of select="$wsmex-action"/>
                            </wsa:Action>
                            <wsa:MessageID>
                                <xsl:value-of select="dp:generate-uuid()"/>
                            </wsa:MessageID>
                            <wsa:ReplyTo>
                                <wsa:Address>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:Address>
                            </wsa:ReplyTo>
                        </soapenv:Header>
                        <soapenv:Body>
                            <GetMetadata xmlns="http://schemas.xmlsoap.org/ws/2004/09/mex">
                                <Dialect>
                                    <xsl:value-of select="$dialect"/>
                                </Dialect>
                            </GetMetadata>
                        </soapenv:Body>
                    </soapenv:Envelope>
                </xsl:variable>
                <xsl:variable name="result" select="dp:soap-call($toAddress, $rst, $tspmSSLProxyProfile, 0, $wsmex-action)"/>
                <xsl:message dp:priority="debug">Response is <dp:serialize select="$result"/></xsl:message>
                <xsl:apply-templates select="$result//mex:MetadataSection">
                    <xsl:with-param name="context" select="$context"/>
                    <xsl:with-param name="dialect" select="$dialect"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message dp:type="crypto" dp:priority="error" dp:id="{$DPLOG_TIVOLI_TSPMWRONGPROTOCOL}">
                    <dp:with-param value="{$protocol}"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- Handle the EventType="remove" message -->
    <xsl:template name="handle-remove">
        <xsl:param name="context"/>
        <xsl:param name="dialect"/>
        <xsl:variable name="encoded-context" select="regExp:replace( $context, '[:|/]', 'gi', '_' )"/>
        <xsl:message dp:priority="debug">Encoded context is <xsl:value-of select="$encoded-context"/></xsl:message>
        <xsl:variable name="dialect-directory">
            <xsl:choose>
                <xsl:when test="$dialect = $xacml-namespace">xacml</xsl:when>
                <xsl:when test="$dialect = $wssecpol-namespace">wssecpol</xsl:when>
                <xsl:otherwise>
                    <xsl:message dp:priority="error" dp:type="crypto" dp:id="{$DPLOG_TIVOLI_TSPMDIALECTERROR}">
                        <dp:with-param value="{$dialect}"/>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="$dialect-directory != ''">
            <xsl:message dp:priority="debug">Dialect directory is <xsl:value-of select="$dialect-directory"/></xsl:message>
            <xsl:variable name="filename" select="concat( 'local:///tspm/', $dialect-directory, '/', $encoded-context, '.xml' )"/>
            <xsl:message dp:priority="debug">Filename is <xsl:value-of select="$filename"/></xsl:message>
            <!-- 
                The DP administration message for removing the policy for for this context
            -->
            <xsl:variable name="deleteMessage">
                <soapenv:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
                    <soapenv:Body>
                        <dp:request xmlns:dp="http://www.datapower.com/schemas/management" domain="{$current-domain}">
                            <dp:do-action>
                                <DeleteFile>
                                    <File>
                                        <xsl:value-of select="$filename"/>
                                    </File>
                                </DeleteFile>
                            </dp:do-action>
                        </dp:request>
                    </soapenv:Body>
                </soapenv:Envelope>
            </xsl:variable>
            <xsl:message dp:priority="debug">
                Removing policy file '<xsl:value-of select="$filename"/>'</xsl:message>
            <xsl:call-template name="do-admin-request">
                <xsl:with-param name="adminRequest" select="$deleteMessage"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    <!--
        This section handles processing each individual <mex:MetadataSection> in the response from the Policy Source.
        Each section contains some policy, which must be written to disk.  This stylesheet calls back to the DataPower
        SOAP management interface to write the files.
        
        All files are written under local://tspm/ in the current domain.
    -->
    <xsl:template match="mex:MetadataSection">
        <xsl:param name="context"/>
        <xsl:param name="dialect"/>
        <xsl:message dp:priority="debug">Handling MetadataSection</xsl:message>
        <xsl:variable name="policySet" select="child::node()"/>
        <xsl:message dp:priority="debug">policySet is <dp:serialize select="$policySet"/></xsl:message>
        <xsl:variable name="encoded-context" select="regExp:replace( $context, '[:|/]', 'gi', '_' )"/>
        <xsl:message dp:priority="debug">Encoded context is <xsl:value-of select="$encoded-context"/></xsl:message>
        <xsl:variable name="dialect-directory">
            <xsl:choose>
                <xsl:when test="$dialect = $xacml-namespace">xacml</xsl:when>
                <xsl:when test="$dialect = $wssecpol-namespace">wssecpol</xsl:when>
                <xsl:otherwise>
                    <xsl:message dp:type="crypto" dp:priority="error" dp:id="{$DPLOG_TIVOLI_TSPMDIALECTERROR}">
                        <dp:with-param value="{$dialect}"/>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="$dialect-directory != ''">
            <xsl:message dp:priority="debug">Dialect directory is <xsl:value-of select="$dialect-directory"/></xsl:message>
            <xsl:variable name="filename" select="concat( 'local:///tspm/', $dialect-directory, '/', $encoded-context, '.xml' )"/>
            <xsl:message dp:priority="debug">Filename is <xsl:value-of select="$filename"/></xsl:message>
            <xsl:variable name="policySetString">
                <dp:serialize select="$policySet"/>
            </xsl:variable>
            <xsl:variable name="filedata" select="dp:encode($policySetString, 'base-64')"/>
            <xsl:message dp:priority="debug">Filedata is <xsl:value-of select="$filedata"/></xsl:message>
            <!--
                The DP administration message for creating the directory to put files in.  If the directory
                already exists then this does nothing.
             -->
            <xsl:variable name="createDirMessage">
                <soapenv:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
                    <soapenv:Body>
                        <dp:request xmlns:dp="http://www.datapower.com/schemas/management" domain="{$current-domain}">
                            <dp:do-action>
                                <CreateDir>
                                    <Dir>local:///tspm/<xsl:value-of select="$dialect-directory"/> </Dir>
                                </CreateDir>
                            </dp:do-action>
                        </dp:request>
                    </soapenv:Body>
                </soapenv:Envelope>
            </xsl:variable>
            <!-- 
               The DP administration message for uploading our newly received policy file.  Any existing policy for this
                context + dialect will be OVERWRITTEN
            -->
            <xsl:variable name="uploadMessage">
                <soapenv:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
                    <soapenv:Body>
                        <dp:request xmlns:dp="http://www.datapower.com/schemas/management" domain="{$current-domain}">
                            <dp:set-file name="{$filename}">
                                <xsl:value-of select="$filedata"/>
                            </dp:set-file>
                        </dp:request>
                    </soapenv:Body>
                </soapenv:Envelope>
            </xsl:variable>
            <!-- 
                The DP administration message for notifying DataPower that the new file has been uploaded.
            -->
            <xsl:variable name="flushMessage">
                <env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
                    <env:Body>
                        <dp:request xmlns:dp="http://www.datapower.com/schemas/management" domain="{$current-domain}">
                            <dp:do-action>
                                <FlushPDPCache>
                                    <XACMLPDP>
                                        <xsl:value-of select="$xacmlpdp"/>
                                    </XACMLPDP>
                                </FlushPDPCache>
                            </dp:do-action>
                        </dp:request>
                    </env:Body>
                </env:Envelope>
            </xsl:variable>
            <xsl:message dp:priority="debug">Creating directory '<xsl:value-of select="$dialect-directory"/>'</xsl:message>
            <xsl:call-template name="do-admin-request">
                <xsl:with-param name="adminRequest" select="$createDirMessage"/>
            </xsl:call-template>
            <xsl:message dp:priority="debug">Uploading received policy as file '<xsl:value-of select="$filename"/>'</xsl:message>
            <xsl:call-template name="do-admin-request">
                <xsl:with-param name="adminRequest" select="$uploadMessage"/>
            </xsl:call-template>
            <!-- This will fail if we're running on firmware version 3.7.1.0 or earlier...  -->
            <!-- Only flush if updating XACML policy -->
            <xsl:if test="$dialect = $xacml-namespace">
                <xsl:message dp:priority="debug">Flushing XACML PDP cache '<xsl:value-of select="$xacmlpdp"/>'</xsl:message>
                <xsl:call-template name="do-admin-request">
                    <xsl:with-param name="adminRequest" select="$flushMessage"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    <!-- 
        ============================  
        Make an administrative request
        ============================= 
    -->
    <xsl:template name="do-admin-request">
        <xsl:param name="adminRequest"/>
        <xsl:variable name="url">https://<xsl:value-of select="$user"/>:<xsl:value-of select="$password"/>@<xsl:value-of select="$managementHost" />:<xsl:value-of select="$managementPort"/>/service/mgmt/current</xsl:variable>
        <!-- Prevent the password from being logged -->
        <xsl:variable name="redacted_url">https://<xsl:value-of select="$user"/>:****@<xsl:value-of select="$managementHost" />:<xsl:value-of select="$managementPort"/>/service/mgmt/current</xsl:variable>
        <xsl:message dp:priority="debug">Making DP administrative requests to <xsl:value-of select="$url"/></xsl:message>
        <xsl:variable name="adminResponse" select="dp:soap-call($url, $adminRequest, $internalSSLProxyProfile, 0, '')"/>
        <xsl:apply-templates select="$adminResponse//dp-mgmt:response"/>
    </xsl:template>
    <!-- Interpret the response from our DP admin callbacks and log errors as applicable -->
    <xsl:template match="dp-mgmt:response">
        <xsl:variable name="resultText">
            <xsl:value-of select="//dp-mgmt:result/text()"/>
        </xsl:variable>
        <xsl:if test="not( contains( $resultText, 'OK' ))">
            <xsl:message dp:priority="error" dp:type="crypto" dp:id="{$DPLOG_TIVOLI_TSPMSERVICEADMINERROR}">
                <dp:with-param value="{$resultText}"/>
            </xsl:message>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>
