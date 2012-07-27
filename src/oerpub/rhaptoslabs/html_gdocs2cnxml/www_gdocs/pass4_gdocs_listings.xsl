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
This XSLT adds the level attribute to <lists> and removes margin attribute
Pass1 transformation is precondition for this pass.
Before and after this transformation the Google Docs HTML is no valid HTML anymore!

Input example:
  <cnhtml:list margin="10">1</cnhtml:list>
  <cnhtml:list margin="15">2</cnhtml:list>
  <somethingelse/>
  <cnhtml:list margin="33">3</cnhtml:list>
  <cnhtml:list margin="72">4</cnhtml:list>
  <cnhtml:list margin="15">5</cnhtml:list>

Output:
  <cnhtml:list level="1">1</cnhtml:list>
  <cnhtml:list level="2">2</cnhtml:list>
  <somethingelse/>
  <cnhtml:list level="1">3</cnhtml:list>
  <cnhtml:list level="2">4</cnhtml:list>
  <cnhtml:list level="1">5</cnhtml:list>

-->

<!-- copy all other nodes -->
<xsl:template match="node()|@*">
  <xsl:copy>
    <xsl:apply-templates select="node()|@*"/>
  </xsl:copy>
</xsl:template>

<!-- find every cnhtml:list element which has a preceding non-cnhtml:list element -->
<xsl:template match="cnhtml:list[not(preceding-sibling::*[1][self::cnhtml:list])]">
  <!-- now walk recursive through all lists -->
  <xsl:apply-templates select="self::cnhtml:list" mode="recurse_pass4">
    <xsl:with-param name="level1_margin" select="@margin"/>
    <xsl:with-param name="level" select="1"/>
  </xsl:apply-templates>
</xsl:template>

<!-- remove other cnhtml:list elements, because they are recursive processed -->
<xsl:template match="cnhtml:list"/>

<!-- remove @margin from cnhtml:list -->
<xsl:template match="cnhtml:list/@margin"/>

<!-- go recursive through all following lists -->
<xsl:template match="cnhtml:list" mode="recurse_pass4">
    <xsl:param name="level1_margin" select="0"/>
    <xsl:param name="level" select="1"/>

    <xsl:variable name="nextStep" select="self::cnhtml:list/following-sibling::*[1][self::cnhtml:list]"/>

    <!-- create current cnhtml:list element with its level -->
    <xsl:apply-templates select="self::cnhtml:list" mode="create_pass4">
      <xsl:with-param name="level" select="$level"/>
    </xsl:apply-templates>

    <xsl:if test="$nextStep">
      <xsl:choose>
        <!-- new start margin/point for level 1 -->
        <xsl:when test="($nextStep/@margin &lt;= $level1_margin) or ($nextStep/@margin &lt; @margin and $level = 2)">
          <xsl:apply-templates select="$nextStep" mode="recurse_pass4">
            <xsl:with-param name="level1_margin" select="$nextStep/@margin"/>
            <xsl:with-param name="level" select="1"/>
          </xsl:apply-templates>
        </xsl:when>
        <!-- -1 -->
        <xsl:when test="$nextStep/@margin &lt; @margin and $level &gt; 1">
          <xsl:apply-templates select="$nextStep" mode="recurse_pass4">
            <xsl:with-param name="level1_margin" select="$level1_margin"/>
            <xsl:with-param name="level" select="$level - 1"/>
          </xsl:apply-templates>
        </xsl:when>
        <!-- +1 -->
        <xsl:when test="$nextStep/@margin &gt; @margin">
          <xsl:apply-templates select="$nextStep" mode="recurse_pass4">
            <xsl:with-param name="level1_margin" select="$level1_margin"/>
            <xsl:with-param name="level" select="$level + 1"/>
          </xsl:apply-templates>
        </xsl:when>
        <!-- +-0 -->
        <xsl:otherwise>
          <xsl:apply-templates select="$nextStep" mode="recurse_pass4">
            <xsl:with-param name="level1_margin" select="$level1_margin"/>
            <xsl:with-param name="level" select="$level"/>
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
</xsl:template>

<!-- create cnhtml:list element with level attribute -->
<xsl:template match="cnhtml:list" mode="create_pass4">
  <xsl:param name="level"/>
    <cnhtml:list>
      <xsl:attribute name="level">
        <xsl:value-of select="$level"/>
      </xsl:attribute>
      <xsl:apply-templates select="@*"/>
        <xsl:apply-templates/>
    </cnhtml:list>
</xsl:template>

</xsl:stylesheet>
