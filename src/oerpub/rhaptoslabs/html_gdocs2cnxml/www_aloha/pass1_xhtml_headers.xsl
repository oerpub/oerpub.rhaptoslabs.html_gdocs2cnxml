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
Transforms headers of XHTML.

It transforms all tags
<h1>,<h2>,<h3>,<h4>,<h5>,<h6> to <cnhtml:h level="x">

Input example:
<h1>Title</h1>

Output:
<cnhtml:h level="1" titlecontent="Title">Title</cnhtml:h>
-->

<!-- Default: copy everything -->
<xsl:template match="@*|node()" mode="pass1">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()" mode="pass1"/>
  </xsl:copy>
</xsl:template>

<!-- Change header to <h level="x"> -->
<xsl:template match="xh:h1|xh:h2|xh:h3|xh:h4|xh:h5|xh:h6" mode="pass1">
  <cnhtml:h>
    <xsl:message>INFO: Renaming HTML header to leveled header</xsl:message>
    <xsl:attribute name="level" >                          <!-- insert level attribute -->
      <xsl:choose>
        <xsl:when test="self::xh:h1">1</xsl:when>
        <xsl:when test="self::xh:h2">2</xsl:when>
        <xsl:when test="self::xh:h3">3</xsl:when>
        <xsl:when test="self::xh:h4">4</xsl:when>
        <xsl:when test="self::xh:h5">5</xsl:when>
        <xsl:when test="self::xh:h6">6</xsl:when>
      </xsl:choose>
    </xsl:attribute>

    <!-- In @title the content of the header is saved -->
    <xsl:variable name="titlecontent">
      <xsl:value-of select="normalize-space(.)"/>
    </xsl:variable>
    <xsl:if test="string-length($titlecontent) &gt; 0">
	    <xsl:attribute name="title">
	      <xsl:value-of select="$titlecontent"/>
	    </xsl:attribute>
    </xsl:if>

    <xsl:apply-templates select="@*" mode="pass1"/>        <!-- copy all remaining attributes -->

    <!-- Do NOT copy children in XHTML mode! -->
    <!-- TODO: Copy empty a names for internal bookmarks -->
    <!-- <xsl:apply-templates mode="pass1"/> -->
  </cnhtml:h>
</xsl:template>

<!-- remove all children of headers which are text() or have text() inside -->
<xsl:template match="node()[ancestor::xh:h1|ancestor::xh:h2|ancestor::xh:h3|ancestor::xh:h4|ancestor::xh:h5|ancestor::xh:h6]" mode="pass1">
  <xsl:if test="not(./text() or self::text())">
	  <xsl:copy>
	    <xsl:apply-templates select="@*|node()" mode="pass1"/>
	  </xsl:copy>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>
