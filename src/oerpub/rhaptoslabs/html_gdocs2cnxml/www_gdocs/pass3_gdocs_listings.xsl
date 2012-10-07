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
  indent="no"/>

<xsl:strip-space elements="*"/>
<xsl:preserve-space elements="xh:p xh:span xh:li cnhtml:list xh:td xh:a"/>

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
<xsl:template match="@*|node()">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
</xsl:template>

<!-- Remove <ol> tags. Later all <li> will be rearranged by their margin -->
<xsl:template match="xh:ol">
  <xsl:message>INFO: Removing ol</xsl:message>
  <xsl:apply-templates/>                <!-- just copy all children -->
</xsl:template>

<!-- Add an empty listentry for empty unordered lists -->
<xsl:template match="xh:ol[not(child::xh:li)]">
  <xsl:variable name="margin"
    select="normalize-space(substring-before(substring-after(@style,'margin:'),'pt'))"/>
  <xsl:variable name="list-style-type"
    select="normalize-space(substring-before(substring-after(@style,'list-style-type:'),';'))"/>
  <cnhtml:list>
    <xsl:attribute name="margin">
      <xsl:value-of select="$margin"/>
    </xsl:attribute>
    <xsl:attribute name="list-style-type">
      <xsl:value-of select="$list-style-type"/>
    </xsl:attribute>
    <xsl:if test="@start">
      <xsl:attribute name="start-value">
        <xsl:value-of select="@start"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:apply-templates/> <!-- normally nothing will be applied here -->
  </cnhtml:list>
</xsl:template>

<!-- Rename <li> to <lists>. Add margin attribute for leveling lists in pass 3 -->
<xsl:template match="xh:li">
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
    <xsl:if test="parent::xh:ol/@start">
      <xsl:attribute name="start-value">
        <xsl:value-of select="parent::xh:ol/@start"/>
      </xsl:attribute>
    </xsl:if>
    <!-- remove rest of the list attributes like e.g. style, because they are not needed anymore -->
    <!-- <xsl:apply-templates select="@*"/> -->
    <xsl:apply-templates/>
  </cnhtml:list>
</xsl:template>


</xsl:stylesheet>
