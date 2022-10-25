<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2010. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->
<xsl:stylesheet version="1.0"
     xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
     xmlns:dpcr="http://www.datapower.com/ConformanceAnalysis"
     xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
    xmlns:dpfunc="http://www.datapower.com/extensions/functions"
>

<!-- This is an example stylesheet that demonstrates how to repair
     a BSP conformance error, using the information in a conformance 
     report.  This stylesheet will repair instances of failures of
     R3221 - incorrect order of CREATE and EXPIRES within a TIMESTAMP.

     The conformance report (without an embedded message) is the input
     to a fixup stylesheet.  The message itself is retrieved via
     a call to dpfunc:get-annotated-message(), and a new message 
     is installed via template "set-message".

     This particular non-conformance is processed as follows:
     First the input is read and a key generated allowing 
     specific instances of the non-conformance report to be
     retrieved given an element reference.  Then (assuming that
     there is at least one instance of an R3221 violation,
     the message  is retrieved and copied, using the key
     previously generated to recognize violations of R3221,
     and fix them on-the-fly.  The resultant fixed copy of
     the message then replaces the original.

     The conformance report is then edited to remove instances
     of R3221 violation reports. A more complex fixup stylesheet
     might only be able to correct some problems, but we assume
     that all R3221 errors have been fixed.

-->


<xsl:include href="store:///dp/conformance-utilities.xsl" />

<xsl:key name="R3221"
         match="dpcr:Report[@specification='BSP1.0' and @requirement='R3221']" 
         use="self::dpcr:Report/dpcr:Location[@type='Element']/@node-id"/>


<xsl:template mode="copy-and-filter" match="@*|node()">

  <xsl:if test="count(self::dpcr:Report[@specification='BSP1.0' and @requirement='R3221'])=0" >
    <xsl:copy>
      <xsl:copy-of select="@*|namespace::*"/>
      <xsl:apply-templates mode="copy-and-filter"/>
    </xsl:copy>
  </xsl:if>
  
</xsl:template>

<xsl:template name="fixup-message">
  <xsl:param name="message" select= "/.."/>


<!-- The elements we're interested in are wsu:Timestamp elements,
     whose wsu:Created and wsu:Expires child elements are included
     in reports, i.e. where those reports can be retrieved from
     key "R3221" by the dpcr:reference value of the child 
     wsu:Created or wsu:Expires elements -->

  <xsl:variable name="referenceKeys" 
                select="$message/self::wsu:Timestamp/wsu:Created/@dpcr:reference
                      | $message/self::wsu:Timestamp/wsu:Expires/@dpcr:reference"/>


  <xsl:variable name="Reports" select="key('R3221', $referenceKeys)"/>


<!-- Save the current context.  We will need to switch back to this later so that key() works properly -->
  <xsl:variable name="here" select="."/>

  <xsl:choose>

    <xsl:when test="self::text()">
      <xsl:copy/>
    </xsl:when>

    <xsl:when test="count($Reports)>0">

<!-- The current node is a node identified in the conformance report
     messages contained in the Reports variable.  This means that it
     is a wsu:Timestamp element, whose wsu:Created and wsu:Expires
     child elements have been reversed.  Fix this on-the-fly -->

<!-- The gyrations here are to ensure that the context node points
     into the conformance report when invoking fixup-message, so that
     the lookup via the key() function looks at the correct document.
     Since a wsu:Timestamp is not supposed to contain any children
     other then wsu:Created and wsu:Expires, this complexity is not
     really needed here; however it is included for illustrative 
     purposes  -->

      <xsl:for-each select="$message">
        <xsl:copy>
          <xsl:copy-of select="@*|namespace::*"/>
          <xsl:copy-of select="wsu:Created"/>
          <xsl:copy-of select="wsu:Expires"/>

          <xsl:for-each select="*[(name()!='wsu:Created') and (name()!='wsu:Expires')]">
            <xsl:variable name="elem" select="."/>
            <xsl:for-each select="$here">
              <xsl:call-template name="fixup-message">
                <xsl:with-param name="message" select="$elem"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:copy>
      </xsl:for-each>
    </xsl:when>
    <xsl:otherwise>

      <xsl:for-each select="$message">
        <xsl:copy>
          <xsl:copy-of select="@*|namespace::*"/>
          <xsl:for-each select="*|text()">
            <xsl:variable name="elem" select="."/>
            <xsl:for-each select="$here">
              <xsl:call-template name="fixup-message">
                <xsl:with-param name="message" select="$elem"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:copy>
      </xsl:for-each>
    </xsl:otherwise>
  </xsl:choose>


</xsl:template>

<xsl:template match="/">
<!-- Here before we've read any of the report.
     Process the report into a variable, so we can 
     see if we have work to do -->

  <xsl:variable name="conformanceReport">
    <xsl:copy-of select="."/>
  </xsl:variable>


<!-- Now the complete conformance report is in conformanceReport.
     Are there any instances of R3221 (otherwise we don't need
     to do anything) -->
  <xsl:choose>
    <xsl:when test="count($conformanceReport//dpcr:Report[@specification='BSP1.0' and @requirement='R3221']) > 0">
<!-- There is at least one instance of an R3221 failure.
     Retrieve the annotated message -->
      <xsl:variable name="annotatedMessage" select="dpfunc:get-annotated-message()"/>


<!-- Run through the message, copying it and fixing it up on the fly -->
      <xsl:variable name="fixedAnnotatedMessage">
        <xsl:call-template name="fixup-message">
          <xsl:with-param name="message" select="$annotatedMessage"/>
        </xsl:call-template>
      </xsl:variable>

<!-- Replace the original message with the fixed one -->
      <xsl:call-template name="set-message">
        <xsl:with-param name="message" select="$fixedAnnotatedMessage"/>
      </xsl:call-template>

<!-- Finally, edit the conformance report to remove the errors that
     have been repaired.  -->

      <xsl:for-each select="$conformanceReport">
        <xsl:apply-templates mode="copy-and-filter"/>
      </xsl:for-each>


    </xsl:when>
    <xsl:otherwise>
<!-- No work to do; deliver the unmodified conformance report and exit -->
      <xsl:copy-of select="$conformanceReport"/>
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>



</xsl:stylesheet>
