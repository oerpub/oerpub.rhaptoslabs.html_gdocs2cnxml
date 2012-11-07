<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  extension-element-prefixes="exsl"
  exclude-result-prefixes="exsl">

<xsl:import href="pass1_xhtml_headers.xsl"/>
<xsl:import href="pass2_xhtml_gdocs_headers.xsl"/>
<xsl:import href="pass3_xhtml_divs.xsl"/>
<xsl:import href="pass4_xhtml_text.xsl"/>
<xsl:import href="pass6_xhtml2cnxml.xsl"/>

<xsl:output
  method="xml"
  encoding="UTF-8"
  indent="yes"/>

<xsl:strip-space elements="*"/>

<xsl:template match="/">
  <!-- general HTML/GDocs XSLTs -->
  <xsl:variable name="temp1">
    <xsl:apply-templates select="." mode="pass1"/>
  </xsl:variable>
<!--
  Do not do pass2 now. It brakes paragraph creation!
  <xsl:variable name="temp2">
    <xsl:apply-templates select="exsl:node-set($temp1)" mode="pass2"/>
  </xsl:variable>
-->
  <!-- merge DIVs -->
  <xsl:variable name="temp3">
    <xsl:apply-templates select="exsl:node-set($temp1)" mode="pass3"/>
  </xsl:variable>

  <!-- generate paragraphs -->
  <xsl:variable name="temp4">
    <xsl:apply-templates select="exsl:node-set($temp3)" mode="pass4"/>
  </xsl:variable>

  <!-- do now pass2 -->
  <xsl:variable name="temp5">
    <xsl:apply-templates select="exsl:node-set($temp4)" mode="pass2"/>
  </xsl:variable>

  <!-- XHTML 2 CNXML -->
  <xsl:apply-templates select="exsl:node-set($temp5)" mode="pass6"/>
</xsl:template>

</xsl:stylesheet>