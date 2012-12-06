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
  Change namespacing of math
-->

<!-- Default: copy everything -->
<xsl:template match="@*|node()">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="@*|node()" mode="math">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="*" mode="math">
  <xsl:element name="m:{local-name()}" namespace="http://www.w3.org/1998/Math/MathML">
     <xsl:apply-templates select="@*"/>
     <xsl:apply-templates select="node()" mode="math"/>
   </xsl:element>
</xsl:template>

<xsl:template match="cnx:math">
  <xsl:element name="m:{local-name()}" namespace="http://www.w3.org/1998/Math/MathML">
     <xsl:apply-templates select="@*|node()" mode="math"/>
   </xsl:element>
</xsl:template>

</xsl:stylesheet>
