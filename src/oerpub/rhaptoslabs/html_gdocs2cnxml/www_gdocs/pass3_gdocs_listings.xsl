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
<xsl:template match="xh:ol|xh:ul">
  <!-- add a div seperator if an ol follows immediately after an ul or an ul follows an ol. Very important for later processing-->
  <xsl:if test="preceding-sibling::*[1][self::xh:ol|self::xh:ul]">
    <xh:div/>
  </xsl:if>
  <xsl:message>INFO: Removing ol</xsl:message>
  <xsl:apply-templates/>                <!-- just copy all children -->
</xsl:template>

<!-- Add an empty listentry for empty unordered lists -->
<xsl:template match="xh:ol[not(child::xh:li)]|xh:ul[not(child::xh:li)]">
  <xsl:variable name="margin"
    select="normalize-space(substring-before(substring-after(@style,'margin:'),'pt'))"/>
  <xsl:variable name="list-style-type"
    select="normalize-space(substring-before(substring-after(@style,'list-style-type:'),';'))"/>
  <cnhtml:list>
    <xsl:if test="self::xh:ul">
      <xsl:attribute name="unordered">
        <xsl:text>true</xsl:text>
      </xsl:attribute>
    </xsl:if>
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
  <xsl:variable name="ol-ul-parent"
    select="parent::*[self::xh:ol or self::xh:ul][1]"/>
  <xsl:variable name="margin"
    select="normalize-space(substring-before(substring-after(@style,'margin-left:'),'pt'))"/>
  <xsl:variable name="try-get-list-style-type"
    select="normalize-space(substring-before(substring-after($ol-ul-parent/@style,'list-style-type:'),';'))"/>
  <xsl:variable name="list-style-type">
    <xsl:choose>
      <xsl:when test="$try-get-list-style-type">
        <xsl:value-of select="$try-get-list-style-type"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of
          select="normalize-space(substring-after($ol-ul-parent/@style,'list-style-type:'))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <cnhtml:list>
    <xsl:if test="parent::xh:ul">
      <xsl:attribute name="unordered">
        <xsl:text>true</xsl:text>
      </xsl:attribute>
    </xsl:if>      
    <xsl:attribute name="margin">
      <xsl:value-of select="$margin"/>
    </xsl:attribute>
    <xsl:attribute name="list-style-type">
      <xsl:value-of select="$list-style-type"/>
    </xsl:attribute>
    <xsl:if test="$ol-ul-parent/@start">
      <xsl:attribute name="start-value">
        <xsl:value-of select="$ol-ul-parent/@start"/>
      </xsl:attribute>
    </xsl:if>
    <!-- remove rest of the list attributes like e.g. style, because they are not needed anymore -->
    <!-- <xsl:apply-templates select="@*"/> -->
    <xsl:apply-templates/>
  </cnhtml:list>
</xsl:template>


</xsl:stylesheet>
