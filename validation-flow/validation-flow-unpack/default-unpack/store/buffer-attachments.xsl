<?xml version="1.0" encoding="utf-8"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
    This transform will buffer in all attachments by reading the
    variable attachment-manifest.  If a rule does not read the attachment
    manifest and no action in the rule references attachments, some parts
    may not be buffered.  They can be streamed directly to output.  If a policy
    attempts to reference a context from a rule that has completed, such as a
    response rule referencing a request rule context, this action may need to be in
    the request rule to ensure attachments exist in the context.
-->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpconfig="http://www.datapower.com/param/config"
    extension-element-prefixes="dp"
    exclude-result-prefixes="dp dpconfig"
>

  <xsl:output method="xml"/>

  <xsl:template match="/">

    <xsl:variable name="attachments" select="dp:variable('var://local/attachment-manifest')"/>

    <xsl:copy-of select="."/>
  </xsl:template>

</xsl:stylesheet>
