<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xh="http://www.w3.org/1999/xhtml"
  xmlns:cnhtml="http://cnxhtml"
  extension-element-prefixes="exsl"
  exclude-result-prefixes="exsl xh">

<xsl:output
  method="xml"
  encoding="UTF-8"
  indent="no"/>

<xsl:strip-space elements="*"/>
<xsl:preserve-space elements="xh:p xh:span xh:li cnhtml:list xh:td xh:a xh:h1 xh:h2 xh:h3 xh:h4 xh:h5 xh:h6"/>

<!--
This XSLT transforms headers and lists of (Google Docs) XHTML.

It transforms all tags: <h1>,<h2>,<h3>,<h4>,<h5>,<h6> to <cnhtml:h level="x">
e.g. <h1></h1> to <cnhtml:h level="1"></cnhtml:h>
-->

<!-- Default: copy everything -->
<xsl:template match="@*|node()">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
</xsl:template>

<!-- ======= -->

<!-- Clean the title, remove comments out of title -->
<xsl:template match="@*|node()" mode="cleantitle">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()" mode="cleantitle"/>
  </xsl:copy>
</xsl:template>

<!-- ignore comments in title -->
<xsl:template match="xh:a[starts-with(@href, '#cmnt')]" mode="cleantitle"/>

<!-- ======= -->

<!-- Change header to <h level="x"> -->
<xsl:template match="xh:h1|xh:h2|xh:h3|xh:h4|xh:h5|xh:h6"> 
  <!-- get title content without comments -->
  <xsl:variable name="title_nodeset">
  	<xsl:apply-templates mode="cleantitle"/>
  </xsl:variable>
  <xsl:variable name="title_content">
    <xsl:value-of select="normalize-space(exsl:node-set($title_nodeset))"/>
  </xsl:variable>
  
  <xsl:choose>
      <!-- convert empty headers to empty paragraphs -->
      <xsl:when test="string-length($title_content) &lt;= 0">
          <p>
            <xsl:apply-templates/>
          </p>
      </xsl:when>
      <!-- convert headings inside lists to paragraphs -->
      <xsl:when test="ancestor::xh:li">
          <p>
              <xsl:apply-templates/>
          </p>
      </xsl:when>
      <xsl:otherwise>
        <cnhtml:h>
            <xsl:message>INFO: Renaming HTML header to leveled header</xsl:message>
            <xsl:attribute name="level" >                          <!-- insert level attribute -->
              <xsl:choose>
                <!-- make sure that the very first heading has level 1! Otherwise transformation will loose content -->
                <!-- <xsl:when test="generate-id((//xh:h1[1]|//xh:h2[1]|//xh:h3[1]|//xh:h4[1]|//xh:h5[1]|//xh:h6[1])[1]) = generate-id(.)">1</xsl:when> -->
                <xsl:when test="self::xh:h1">1</xsl:when>
                <xsl:when test="self::xh:h2">2</xsl:when>
                <xsl:when test="self::xh:h3">3</xsl:when>
                <xsl:when test="self::xh:h4">4</xsl:when>
                <xsl:when test="self::xh:h5">5</xsl:when>
                <xsl:when test="self::xh:h6">6</xsl:when>
              </xsl:choose>
            </xsl:attribute>

            <!-- <xsl:if test="string-length($title_content) &gt; 0"> -->
                <xsl:attribute name="title">
                  <xsl:value-of select="$title_content"/>
                </xsl:attribute>
            <!-- </xsl:if> -->

            <xsl:apply-templates select="@*"/>        <!-- copy all remaining attributes -->

            <!-- copy all children which do not have any content -->
            <xsl:apply-templates/>
        </cnhtml:h>
      </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- remove all children of headers which are text() or have text() inside -->
<!-- TODO: Rework this title thing, it's not the optimum -->
<xsl:template match="node()[ancestor::xh:h1|ancestor::xh:h2|ancestor::xh:h3|ancestor::xh:h4|ancestor::xh:h5|ancestor::xh:h6][not(ancestor::xh:li)]">
  <xsl:if test="not(./text() or self::text())">
	  <xsl:copy>
	    <xsl:apply-templates select="@*|node()"/>
	  </xsl:copy>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>
