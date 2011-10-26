<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  extension-element-prefixes="exsl"
  exclude-result-prefixes="exsl">

<xsl:import href="pass1_gdocs_headers.xsl"/>
<xsl:import href="pass2_xhtml_gdocs_headers.xsl"/>
<xsl:import href="pass3_gdocs_listings.xsl"/>
<xsl:import href="pass4_gdocs_listings.xsl"/>
<xsl:import href="pass5_gdocs_listings.xsl"/>
<xsl:import href="pass5_part2_gdocs_red2cnxml.xsl"/>
<xsl:import href="pass6_gdocs2cnxml.xsl"/>

<!--
<xsl:output
  method="xml"
  encoding="UTF-8"
  doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
  doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
  indent="yes"/>
-->

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
  <xsl:variable name="temp2">
    <xsl:apply-templates select="exsl:node-set($temp1)" mode="pass2"/>
  </xsl:variable>
  <!-- Convert flat listings in GDocs to structured listings -->
  <xsl:variable name="temp3">
    <xsl:apply-templates select="exsl:node-set($temp2)" mode="pass3"/>
  </xsl:variable>
  <xsl:variable name="temp4">
    <xsl:apply-templates select="exsl:node-set($temp3)" mode="pass4"/>
  </xsl:variable>
  <xsl:variable name="temp5">
    <xsl:apply-templates select="exsl:node-set($temp4)" mode="pass5"/>
  </xsl:variable>
  <!-- GDocs, convert red text to enclosed CNXML -->
  <xsl:variable name="temp6">
    <xsl:apply-templates select="exsl:node-set($temp5)" mode="red2cnxml"/>  
  </xsl:variable>
  <!-- GDocs 2 CNXML -->
  <xsl:apply-templates select="exsl:node-set($temp6)" mode="pass6"/>
</xsl:template>


</xsl:stylesheet>