<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://cnx.rice.edu/cnxml"
  xmlns:cnx="http://cnx.rice.edu/cnxml"
  xmlns:md="http://cnx.rice.edu/mdml"
  xmlns:bib="http://bibtexml.sf.net/"
  xmlns:m="http://www.w3.org/1998/Math/MathML"
  xmlns:q="http://cnx.rice.edu/qml/1.0"
  xmlns:cnxtra="http://cnxtra"
  version="1.0"
  exclude-result-prefixes="cnx cnxtra">

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<xsl:strip-space elements="*"/>
<!--
<xsl:preserve-space elements="cnx:code"/>
-->

<xsl:param name="id.prefix">gd-</xsl:param>

<!--
      These are all elements defined in the RNG schema that require @id.
-->

<!-- Default: copy everything -->
<xsl:template match="@*|node()" mode="pass8">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()" mode="pass8"/>
  </xsl:copy>
</xsl:template>

<!-- Insert a @id for elements that require it (RED text import didn't add them) -->
<xsl:template match="
    cnx:document|
    cnx:div|
    cnx:para|
    cnx:list|
    cnx:term|
    cnx:meaning|
    cnx:definition|
    cnx:figure|
    cnx:subfigure|
    cnx:media|
    cnx:note|
    cnx:footnote|
    cnx:example|
    cnx:exercise|
    cnx:problem|
    cnx:solution|
    cnx:equation|
    cnx:table|
    cnx:quote|
    cnx:preformat|
    cnx:code|
    cnx:rule|
    cnx:statement|
    cnx:proof|
    cnx:equation|
    cnx:commentary|
    cnx:section"
    mode="pass8">
  <xsl:copy>
    <xsl:if test="not(@id)">
      <xsl:attribute name="id">
        <!-- ID text prefix -->
        <xsl:value-of select="$id.prefix"/>
        <xsl:value-of select="generate-id()"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:apply-templates select="@*|node()" mode="pass8"/>
  </xsl:copy>
</xsl:template>

<!-- Remove the cnx: prefix (EIP doesn't like it) -->
<!--
<xsl:template match="cnx:*">
  <xsl:element name="{local-name()}" namespace="http://cnx.rice.edu/cnxml">
    <xsl:apply-templates select="@*|node()"/>
  </xsl:element>
</xsl:template>
-->


</xsl:stylesheet>