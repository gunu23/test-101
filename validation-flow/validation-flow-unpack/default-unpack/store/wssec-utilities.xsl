<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dsig="http://www.w3.org/2000/09/xmldsig#"
                xmlns:dp="http://www.datapower.com/extensions"
                xmlns:dpfunc="http://www.datapower.com/extensions/functions"
                xmlns:dpconfig="http://www.datapower.com/param/config"
                xmlns:func="http://exslt.org/functions"
                xmlns:S11="http://schemas.xmlsoap.org/soap/envelope/"
                xmlns:S12="http://www.w3.org/2003/05/soap-envelope"
                exclude-result-prefixes="dsig dp dpfunc dpconfig func S11 S12"
                extension-element-prefixes="dp func"
                version="1.0">

<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2015. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

  <!-- For WS-Sec functionality, we define a global setting to indicate if 
       an EncryptedKey (or EncryptedKeySHA1), used by the SOAP Body security
       (message security) for signing/encryption, can be referred as 
       EncryptedKeySHA1 later when sending a message back. This is a very secure
       response because it does not even have the encrypted symmetric key but
       the recipient can still process it.

       When this setting is set to 'on', then the EK/EKSha1 used by the SOAP
       message security will be cached for EKSha1 in protecting the response message. 
       If soap Body is not encrypted or signed, then no EKSha1.

       When this setting is "off", DP will *randomly* cache an EK for that purpose as
       the the default behavior provided by former releases. This randomness usually
       means the last EK or EKSha1 being used by the request rule will be the one for
       EKSha1 in generating the response message.

       This setting can be passed in by the multistep execution context, or
       provided by some wssec crypto actions. But not every wssec action would
       really use it, so by default it is off. Those crypto action who needs to
       provide this setting, the dp:param block is needed.
  -->
  <xsl:param name="dpconfig:hash-soap-body-eks" select="'off'"/>
  
  <xsl:include href="store:///dp/msgcat/crypto.xml.xsl" dp:ignore-multiple="yes"/>

  <!--
       Templates for handling counters.  Note the use of "local-variable", so one must access
       (set, get, check) the counter from within the same stylesheet for it to work.
    -->

  <xsl:template name="set-counter">
    <xsl:param name="counter" select="''"/>
    <xsl:param name="value" select="''"/>
    <xsl:param name="inc" select="''"/>

    <!-- If value is non-null and is a number then set counter to value; otherwise if inc is
         non-null and is a number then add that to counter. -->
    <xsl:if test="not($counter = '')">
      <xsl:choose>
        <xsl:when test="not($value = '') and not(string(number($value)) = 'NaN')">
          <dp:set-local-variable name="$counter" value="$value"/>
        </xsl:when>
        <xsl:when test="not($inc = '') and not(string(number($inc)) = 'NaN')">
          <xsl:variable name="counter-value" select="number(dp:local-variable($counter))"/>
          <dp:set-local-variable name="$counter" value="string(number($counter-value) + number($inc))"/>
        </xsl:when>
      </xsl:choose>
    </xsl:if>

  </xsl:template>

  <!-- return the value of testing. 0: equal; positive: counter is greater than threshold -->
  <func:function name="dpfunc:compare-counter">
    <xsl:param name="counter" select="''"/>
    <xsl:param name="threshold" select="'0'"/>

    <xsl:choose>
      <xsl:when test="not($counter = '') and not(string(number($threshold)) = 'NaN')">
        <xsl:variable name="counter-value" select="number(dp:local-variable($counter))"/>

        <!-- For debugging 
        <xsl:message dp:priority="warn">test-counter: <xsl:value-of select="$counter"/>: <xsl:value-of select="$counter-value"/></xsl:message>
        <xsl:message dp:priority="warn">test-counter result: <xsl:value-of select="number($counter-value - $threshold)"/></xsl:message>
        -->
        <func:result select="number($counter-value - $threshold)"/>
      </xsl:when>
      <xsl:otherwise>
        <func:result select="number('-1')"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>
 
  <xsl:template name="clear-num-wssec-counter">
    <xsl:call-template name="set-counter">
      <xsl:with-param name="counter" select="'num-wssec-processed'"/>
      <xsl:with-param name="value" select="'0'"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="inc-num-wssec-counter">
    <xsl:call-template name="set-counter">
      <xsl:with-param name="counter" select="'num-wssec-processed'"/>
      <xsl:with-param name="inc" select="'1'"/>
    </xsl:call-template>
  </xsl:template>

  <func:function name="dpfunc:test-num-wssec-counter">
    <xsl:variable name="result" select="dpfunc:compare-counter('num-wssec-processed', '1')"/>
    <func:result select="$result"/>
  </func:function>

  <!-- when the current code $object, a dsig:Signature or xenc:EncryptedData element,
       is a descendant of SOAP Body, then it is processing the soap Body security.
    -->
  <xsl:template name="check-soap-body-eks">
    <xsl:param name="object" select="/.."/>

    <xsl:if test="$dpconfig:hash-soap-body-eks = 'on'">
      <xsl:variable name="body" select="/*[local-name()='Envelope']/*[local-name()='Body']"/>
      <xsl:variable name="protecting_body">
        <xsl:choose>
          <!-- In case of the signature, the Reference should point to soap body. 
               In term of WS-Sec msg security the enveloped signature is not allowed.
               -->
          <xsl:when test="$object/self::dsig:Signature">
            <!-- The code checking signature of SOAP Body is the efficient one, but not for enveloped/non-soap signing.
                 We are talking about WS-Sec signing for the EKS, if there are multiple ID attributes for the
                 SOAP Body, those are not ws-sec and unconformant. But if the reference is using XPath Filter
                 to point to SOAP Body, things get complicated, please consider to turn off hash-soap-body-eks. -->
            <xsl:variable name="body-ref" select="concat('#', $body/attribute::*[translate(local-name(),'ID','id')='id'][1])"/>
            <xsl:value-of select="count($object/dsig:SignedInfo/dsig:Reference[@URI=$body-ref]) &gt; 0"/>
          </xsl:when>

          <xsl:otherwise> <!-- EncryptedData -->
            <xsl:variable name="inside" select="$object/ancestor-or-self::*[local-name() = 'Body']"/>
            <!-- when the ancestor named 'Body' is the one under Envelope. -->
            <xsl:value-of select="$inside and count($body | $inside) = count($inside)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:if test="$protecting_body ='true'">
        <xsl:message dp:priority="debug" dp:id="{$DPLOG_CRYPTO_EKS_SET_BODY_EK}"/>
        <dp:set-local-variable name="'hash-soap-body-eks'" value="'1'"/>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <func:function name="dpfunc:current-ek-needed-by-eks">
    <xsl:choose>
      <xsl:when test="$dpconfig:hash-soap-body-eks = 'on'">
        <xsl:variable name="yes" select="number(dp:local-variable('hash-soap-body-eks')) &gt; 0"/>
        <!-- Clear the status so that no other EK will be hashed for EKS. 
             If more than EKs were used to protect SOAP Body, the first one shall
             be used.
          -->
        <xsl:if test="$yes">
          <xsl:message dp:priority="debug" dp:id="{$DPLOG_CRYPTO_EKS_CHECK_BODY_EK}">
            <dp:with-param value="{$yes}"/>
          </xsl:message>
          <dp:set-local-variable name="'hash-soap-body-eks'" value="'0'"/>
        </xsl:if>
        <func:result select="$yes"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- In case the hash-soap-body-eks is 'off', by default, every EK was needed by eks,
             so everyone will be used to update the context variable (expensive op). The last 
             EK will be used for future EKS.
             -->
        <func:result select="true()"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>

  <!-- store the signature in context variable 
       verified = on : signature is from verify action, else it is probably
                       from signing action
   -->
  <xsl:template name="store-signature">
    <xsl:param name="verified" select="'on'"/>
    <xsl:param name="signature" select="'*'"/>
 
    <xsl:if test="not(starts-with($signature, '*'))">
      <xsl:variable name="temp">
        <xsl:choose>
          <xsl:when test="$verified = 'on'">
            <xsl:copy-of select="dp:variable('var://context/transaction/verified-signatures')"/> 
            <Signature><xsl:value-of select="$signature"/></Signature>
          </xsl:when>
          <xsl:otherwise>
            <xsl:copy-of select="dp:variable('var://context/transaction/signatures')"/>
            <Signature><xsl:value-of select="$signature"/></Signature>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:choose>
        <xsl:when test="$verified = 'on'">
          <dp:set-variable name="'var://context/transaction/verified-signatures'" value="$temp"/>
        </xsl:when>
        <xsl:otherwise>
          <dp:set-variable name="'var://context/transaction/signatures'" value="$temp"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <!-- mark whether signature is encrypted -->
  <xsl:template name="signature-encrypted">
    <xsl:param name="verified" select="'on'"/>

    <xsl:variable name="temp">
      <xsl:choose>
        <xsl:when test="$verified = 'on'">
          <xsl:copy-of select="dp:variable('var://context/transaction/verified-signatures')"/> 
          <Encrypted>yes</Encrypted>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="dp:variable('var://context/transaction/signatures')"/>
          <Encrypted>yes</Encrypted>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$verified = 'on'">
        <dp:set-variable name="'var://context/transaction/verified-signatures'" value="$temp"/>
      </xsl:when>
      <xsl:otherwise>
        <dp:set-variable name="'var://context/transaction/signatures'" value="$temp"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

<!--
  <func:function name="dpfunc:get-signatures">
    <xsl:param name="verified" select="'on'"/>
    <xsl:variable name="temp">
      <xsl when test="$verified = 'on'">
        <xsl:copy-of select="dp:variable('var://context/transaction/verified-signatures')"/> 
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="dp:variable('var://context/transaction/signatures')"/>
      </xsl:otherwise>
    </xsl:choose>      
    </xsl:variable>
    <func:result select="$temp"/>
  </func:function>
-->

  <!-- Given an actor/role identifier, return a resolved value.
    -->
  <func:function name="dpfunc:get-actor-role-value">
    <xsl:param name="id" select="/.."/>
    <xsl:param name="traditional" select="'0'"/>
    <!-- traditional=1: usually is for our configuration style: the empty string will omit actor.
                     0: is all the standard way.
      -->
    <xsl:variable name="result">
      <xsl:choose>
        <!-- differentiate the specific actor value from the implicit values for finer tuning:
              - DP:NEXT_ACTOR
              - DP:ULTIMATE_RECEIVER_ACTOR
          -->
        <!-- for better performance, process the frequently used soap actor ids first. -->
        <xsl:when test="not($id)">
          <xsl:text>DP:ULTIMATE_RECEIVER_ACTOR</xsl:text>
        </xsl:when>
        <xsl:when test="$traditional = 1 and $id = ''">
          <xsl:text>DP:ULTIMATE_RECEIVER_ACTOR</xsl:text>
        </xsl:when>

        <xsl:when test="$id = 'http://www.w3.org/2003/05/soap-envelope/role/ultimateReceiver'">
          <xsl:text>DP:ULTIMATE_RECEIVER_ACTOR</xsl:text>
        </xsl:when>
        <xsl:when test="$id = 'http://schemas.xmlsoap.org/soap/actor/next' or
                        $id = 'http://www.w3.org/2003/05/soap-envelope/role/next'">
          <xsl:text>DP:NEXT_ACTOR</xsl:text>
        </xsl:when>

        <xsl:when test="$traditional = 0 and $id != ''">
          <xsl:value-of select="$id"/>
        </xsl:when>
        <xsl:when test="$traditional = 0 and $id = ''">
          <xsl:value-of select="dp:variable('var://service/URL-in')"/>
        </xsl:when>

        <!-- here starts processing the specially configured actor/role id -->
        <xsl:when test="$traditional = 1 and $id = 'USE_MESSAGE_BASE_URI'">
          <xsl:value-of select="dp:variable('var://service/URL-in')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$id"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$id">
      <!-- when the soap actor is really configured. -->
      <xsl:message dp:priority="debug" dp:id="{$DPLOG_CRYPTO_SOAP_ACTOR_RESOLVE}">
        <dp:with-param value="{$id}"/>
        <dp:with-param value="{$result}"/>
      </xsl:message>
    </xsl:if>
    <func:result select="string($result)"/>
  </func:function>

    <xsl:template name="wssec-security-header-fault">
      <xsl:param name="actor" select="''"/>
      <xsl:param name="soapnsuri" select="'http://schemas.xmlsoap.org/soap/envelope/'"/>
      <xsl:param name="code" select="''"/>
      <!-- optional sub code, only used for soap 1.2 fault. -->
      <xsl:param name="subcode" select="''"/>
      <!-- optional error string, if not presents, the template generates one for the fault code. -->
      <xsl:param name="error-string" select="''"/>
      <!-- the not-understood-headers is a nodeset which contains the unprocessed headers.
           it is useful only for the MustUnderstant fault code.-->
      <xsl:param name="not-understood-headers" select="/.."/>
      <!-- A Node element is required by the SOAP2.0 fault if the 
           soap node is not ultimate receiver, the soap-node-id param is
           then needed. -->
      <xsl:param name="soap-node-id" select="''"/>

      <xsl:variable name="faultstring">
        <xsl:choose>
          <xsl:when test="$error-string != ''"><xsl:value-of select="$error-string"/></xsl:when>
          <!-- backwards compatibility. -->
          <xsl:when test="($code = '' and $subcode = '') or $code='wsse:InvalidSecurity'"
              >The request was invalid for WS-Security standard, it has more than one Security header for the configured actor: "<xsl:value-of select="$actor"/>"</xsl:when>
          <xsl:when test="$code = 'env:MustUnderstand'"
              ><xsl:value-of select="count($not-understood-headers)"/> mandatory SOAP header block(s) not understood.</xsl:when>
          <xsl:otherwise
              >SOAP fault is found.</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:message dp:priority="error" dp:id="{$DPLOG_CRYPTO_SOAP_FAULT_STRING}">
        <dp:with-param value="{$faultstring}"/>
      </xsl:message>

      <xsl:variable name="faultcode">
        <xsl:choose>
          <xsl:when test="$code = '' and $soapnsuri = 'http://schemas.xmlsoap.org/soap/envelope/'">
            <xsl:value-of select="'env:Client'"/>
          </xsl:when>
          <xsl:when test="$code = '' and $soapnsuri = 'http://www.w3.org/2003/05/soap-envelope'">
            <xsl:value-of select="'env:Sender'"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat($code)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <dp:send-error>
        <xsl:choose>
          <xsl:when test="$soapnsuri = 'http://schemas.xmlsoap.org/soap/envelope/'">
            <!-- SOAP 1.1 Fault Message -->
            <env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
              <env:Body>
                <env:Fault>
                  <faultcode><xsl:value-of select="$faultcode"/></faultcode>
                  <faultstring><xsl:value-of select="$faultstring"/></faultstring>
                  <xsl:if test="$actor != ''">
                    <faultactor><xsl:value-of select="$actor"/></faultactor>
                  </xsl:if>
                </env:Fault>
              </env:Body>
            </env:Envelope>
          </xsl:when>
          <xsl:otherwise>
            <!-- SOAP 1.2 Fault Message -->
            <env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope">
              <xsl:if test="$code='env:MustUnderstand' and count($not-understood-headers) &gt; 0">
                <env:Header>
                  <xsl:for-each select="$not-understood-headers">
                    <xsl:variable name="prefix" select="substring-before(name(), ':')"/>
                    <env:NotUnderstood qname="{name()}">
                      <xsl:copy-of select="namespace::*[local-name()=$prefix]"/>
                    </env:NotUnderstood>
                  </xsl:for-each>
                </env:Header>
              </xsl:if>
              <env:Body>
                <env:Fault>
                  <env:Code>
                    <env:Value><xsl:value-of select="$faultcode"/></env:Value>
                    <xsl:choose>
                      <!-- backward compatibility -->
                      <xsl:when test="($code = '' and $subcode = '') or $code='wsse:InvalidSecurity'">
                        <env:Subcode>
                          <env:Value xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">wsse:InvalidSecurity</env:Value>
                        </env:Subcode>
                      </xsl:when>
                      <xsl:when test="$subcode = 'dp:Unsupported'">
                        <env:Subcode>
                          <env:Value xmlns:dp="http://www.datapower.com/extensions">dp:Unsupported</env:Value>
                        </env:Subcode>
                      </xsl:when>
                      <xsl:when test="$subcode != ''">
                        <env:Subcode>
                          <env:Value><xsl:value-of select="$subcode"/></env:Value>
                        </env:Subcode>
                      </xsl:when>
                    </xsl:choose>
                  </env:Code>
                  <env:Reason>
                    <env:Text><xsl:value-of select="$faultstring"/></env:Text>
                  </env:Reason>
                  <xsl:if test="$soap-node-id != ''">
                    <env:Node>
                      <env:Text><xsl:value-of select="$soap-node-id"/></env:Text>
                    </env:Node>
                  </xsl:if>
                  <xsl:if test="$actor != ''">
                    <env:Role>
                      <env:Text><xsl:value-of select="$actor"/></env:Text>
                    </env:Role>
                  </xsl:if>
                </env:Fault>
              </env:Body>
            </env:Envelope>
          </xsl:otherwise>
        </xsl:choose>
      </dp:send-error>
      <!-- Set the correct protocol content-type and http status code for SOAP fault. 
           SOAP 1.1 spec doesn't define anything for the response code for a soap fault,
           it seems not hurt to set the SOAP-HTTP binding headers; 
           SOAP 1.2 spec introduces the new content type application/soap+xml
           while SOAP  1.1 used text/xml. -->
      <xsl:choose>
        <xsl:when test="$soapnsuri = 'http://schemas.xmlsoap.org/soap/envelope/'">
          <dp:set-response-header name="'Content-Type'" value="'text/xml'"/>
        </xsl:when>
        <xsl:otherwise>
          <dp:set-response-header name="'Content-Type'" value="'application/soap+xml'"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="$faultcode = 'env:Sender'">
          <dp:set-variable name="'var://service/error-protocol-response'" value="'400'"/>
          <dp:set-variable name="'var://service/error-protocol-reason-phrase'" value="'Bad Request'"/>
        </xsl:when>
        <xsl:otherwise>
          <dp:set-variable name="'var://service/error-protocol-response'" value="'500'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:template>

    <!-- strip dsig:Signature -->
    <xsl:template match="node()|@*" mode="strip-signature">
      <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="strip-signature"/>
      </xsl:copy>
    </xsl:template>

    <xsl:template match="dsig:Signature" mode="strip-signature"/>
    <!-- end of strip dsig:Signature -->

  <!-- Match the wssec:Security actor/role with the configured actor/role.
       return true if the S11 actor or S12 role matches with the configured one.

       The actor/role id matching will now be different between message sender
       and message receiver.
       
       As a message sender, it doesn't process/consume the message, hence we
       only need to literally test if there is already a Security header with 
       the configured actor/role, then put the new info into it, otherwise we 
       create a new Security header. Since it doesn't consume the message, we 
       need not to semantically test the "next"/"none" actor roles. Please note:
       even for this case, the omitting actor is identical as the utilmateReceiver.

       As a message receiver, it does consume the message, hence we
       need to semantically compare the actor/role values: such as 
       "next"/"none"/omitting/empty.
       -->
  <func:function name="dpfunc:match-actor-role">
    <xsl:param name="security" select="/.."/>
    <xsl:param name="id" select="'DP:ULTIMATE_RECEIVER_ACTOR'"/>
    <!-- indicate which way to match the soap actor/role. -->
    <xsl:param name="sender-or-receiver" select="'receiver'"/>

    <!-- yes, if actor and/or role exist, either one matches will work.
         if no actor/role, it works when configured actor/role is ultimateReceiver.
      -->
    <xsl:choose>
      <!-- the security header has no actor/role -->
      <xsl:when test="not($security/@S11:actor) and not($security/@S12:role) and
                      $id = 'DP:ULTIMATE_RECEIVER_ACTOR'
                     ">
          <!-- for most cases -->
          <func:result select="true()"/>
      </xsl:when>

      <xsl:otherwise>
        <!-- the absent should have been processed for the security header. -->
        <xsl:variable name="s11-actor">
          <xsl:if test="$security/@S11:actor">
            <xsl:value-of select="dpfunc:get-actor-role-value($security/@S11:actor, '0')"/>
          </xsl:if>
        </xsl:variable>

        <xsl:variable name="s12-role">
          <xsl:if test="$security/@S12:role">
            <xsl:value-of select="dpfunc:get-actor-role-value($security/@S12:role, '0')"/>
          </xsl:if>
        </xsl:variable>

        <xsl:choose>
          <xsl:when test="$sender-or-receiver = 'sender'">
            <func:result select="$id=$s11-actor or $id=$s12-role"/>
          </xsl:when>
          <!-- The following is applicable for message receivers only.  -->
          <xsl:when test="$s11-actor = 'DP:NEXT_ACTOR' or
                          $s12-role = 'DP:NEXT_ACTOR'">
              <func:result select="true()"/>
          </xsl:when>
          <xsl:when test="$s11-actor = 'http://www.w3.org/2003/05/soap-envelope/role/none' or
                          $s12-role  = 'http://www.w3.org/2003/05/soap-envelope/role/none'
                          ">
              <func:result select="false()"/>
          </xsl:when>
          <xsl:otherwise>
              <func:result select="$id=$s11-actor or $id=$s12-role"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>

  <!-- test if there is more than one Security header with the following scenarios:
         - WS-I BSP R3206: no more than one Security header with the actor attribute omitted
         - WS-I BSP R3210: no more than one Security header with the same actor attribute.
         - The omitted soap actor/role is logically same as "ultimateReceiver".
       Then a fault message should be returned.
  -->

  <func:function name="dpfunc:ambiguous-wssec-actor">
    <xsl:param name="headers" select="/.."/>
    <xsl:param name="id" select="'VALUE-IS-HIDDEN'"/>
  
    <!-- we could easily call the xsl:key() here, but the compiler reports compilation error unless
         the <xsl:key/> has been used, but this function may not be called at all, we
         do not call the <xsl:key/> when it's not needed. -->
    <xsl:variable name="matched-security-count" select="count($headers)"/>

    <xsl:choose>
      <xsl:when test="$matched-security-count &gt; 1">
        <xsl:message dp:priority="warn" dp:id="{$DPLOG_CRYPTO_WSSEC_HEADER_MATCHED_ACTOR}">
          <dp:with-param value="{$matched-security-count}"/>
          <dp:with-param value="{$id}"/>
        </xsl:message>

          <func:result select="true()"/>
      </xsl:when>
      <xsl:otherwise>
          <func:result select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>

  <func:function name="dpfunc:has-wssec-security">
    <func:result select="count(/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='Security']) &gt; 0"/>
  </func:function>

</xsl:stylesheet>
