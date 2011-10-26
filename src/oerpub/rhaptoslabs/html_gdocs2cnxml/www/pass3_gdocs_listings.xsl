<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xh="http://www.w3.org/1999/xhtml"
  xmlns:cnhtml="http://cnxhtml"
  exclude-result-prefixes="xh">

<xsl:output
  method="xml"
  encoding="UTF-8"
  indent="yes"/>

<xsl:strip-space elements="*"/>

<!--
This XSLT removes all <ol> tags because Google Docs uses margins

Input example:
<ol>
  <li/>
  <li/>
</ol>

Output:
  <cnhtml:list/>
  <cnhtml:list/>
 -->

<!-- Default: copy everything -->
<xsl:template match="@*|node()" mode="pass3">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()" mode="pass3"/>
  </xsl:copy>
</xsl:template>

<!-- Remove <ol> tags. Later all <li> will be rearranged by their margin -->
<xsl:template match="xh:ol" mode="pass3">
  <xsl:message>INFO: Removing ol</xsl:message>
  <xsl:apply-templates mode="pass3"/>                <!-- just copy all children -->
</xsl:template>

<!-- Rename <li> to <lists>. Add margin attribute for leveling lists in pass 3 -->
<xsl:template match="xh:li" mode="pass3">
  <xsl:variable name="margin"
    select="normalize-space(substring-before(substring-after(@style,'margin-left:'),'pt'))"/>
  <xsl:variable name="list-style-type"
    select="normalize-space(substring-before(substring-after(parent::xh:ol/@style,'list-style-type:'),';'))"/>
  <cnhtml:list>
    <xsl:attribute name="margin">
      <xsl:value-of select="$margin"/>
    </xsl:attribute>
    <xsl:attribute name="list-style-type">
      <xsl:value-of select="$list-style-type"/>
    </xsl:attribute>
    <!-- remove rest of the list attributes like e.g. style, because they are not needed anymore -->
    <!-- <xsl:apply-templates select="@*" mode="pass3"/> -->
    <xsl:apply-templates mode="pass3"/>
  </cnhtml:list>
</xsl:template>


</xsl:stylesheet>
