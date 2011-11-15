<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://cnx.rice.edu/cnxml"
  xmlns:c="http://cnx.rice.edu/cnxml"
  exclude-result-prefixes="c"
  version="1.0">

<xsl:param name="id.prefix">import-auto-</xsl:param>

<xsl:output indent="yes" method="xml" />


<!--
      These are all elements defined in the RNG schema that require @id.
-->

<xsl:strip-space elements="*"/>
<xsl:preserve-space elements="c:code"/>


<!-- Insert a @id for elements that require it (RED text import didn't add them) -->
<xsl:template match="
    c:para|
    c:list|
    c:term|
    c:meaning|
    c:definition|
    c:figure|
    c:subfigure|
    c:media|
    c:note|
    c:footnote|
    c:example|
    c:exercise|
    c:problem|
    c:solution|
    c:equation|
    c:table|
    c:quote|
    c:preformat|
    c:code|
    c:rule|
    c:statement|
    c:proof|
    c:equation|
    c:commentary|
    c:section">
  <xsl:element name="{local-name()}" namespace="http://cnx.rice.edu/cnxml">
    <xsl:if test="not(@id)">
      <xsl:attribute name="id">
        <xsl:value-of select="$id.prefix"/>
        <xsl:value-of select="generate-id()"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:element>
</xsl:template>

<!-- Remove the c: prefix (EIP doesn't like it) -->
<xsl:template match="c:*">
  <xsl:element name="{local-name()}" namespace="http://cnx.rice.edu/cnxml">
    <xsl:apply-templates select="@*|node()"/>
  </xsl:element>
</xsl:template>

<!-- Identity transform. Nothing interesting... -->
<xsl:template match="@*|node()">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
</xsl:template>

</xsl:stylesheet>