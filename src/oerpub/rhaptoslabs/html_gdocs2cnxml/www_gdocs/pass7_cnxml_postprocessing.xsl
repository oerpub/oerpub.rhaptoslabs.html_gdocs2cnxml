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

<xsl:output method="xml" encoding="UTF-8" indent="no"/>

<xsl:strip-space elements="*"/>
<xsl:preserve-space elements="cnx:emphasis"/>

<!--
Post processing of CNXML
- Convert empty paragraphs to paragraphs with newlines
- Convert cnxtra:image to images
- Convert cnxtra:tex from Blahtex to embedded MathML

Deprecated:
- Add @IDs to elements (needs rework!)
-->

<!-- Default: copy everything -->
<xsl:template match="@*|node()">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
</xsl:template>

<!-- remove all nesting paras -->
<xsl:template match="cnx:para[ancestor::cnx:para]">
  <xsl:apply-templates/>
</xsl:template>

<!-- remove all empty tables -->
<xsl:template match="cnx:table[not(child::*)]"/>

<!-- convert empty paragraphs to paragraphs with newline -->
<xsl:template match="cnx:para[not(child::*|text())]">
  <para>
    <xsl:apply-templates select="@*"/>
    <newline/>
  </para>
</xsl:template>

<!-- add an empty div to empty sections -->
<xsl:template match="cnx:section[not(child::cnx:*[not(self::cnx:title|self::cnx:section)])]">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
    <div/>
  </xsl:copy>
</xsl:template>

<!-- convert images to CNXML -->
<xsl:template match="cnxtra:image">
  <xsl:choose>
    <xsl:when test="text()">
      <media>
        <xsl:attribute name="alt">
          <xsl:value-of select="@alt"/>
        </xsl:attribute>
        <image>
          <xsl:attribute name="mime-type">
            <xsl:value-of select="@mime-type"/>
          </xsl:attribute>
          <xsl:attribute name="src">
            <xsl:value-of select="."/>
          </xsl:attribute>
          <xsl:if test="@height &gt; 0">
            <xsl:attribute name="height">
              <xsl:value-of select="@height"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:if test="@width &gt; 0">
            <xsl:attribute name="width">
              <xsl:value-of select="@width"/>
            </xsl:attribute>
          </xsl:if>
        </image>
      </media>
    </xsl:when>
    <xsl:otherwise>
      <media>
        <xsl:attribute name="alt">
          <xsl:value-of select="@alt"/>
        </xsl:attribute>
        <image>
          <xsl:attribute name="mime-type">
            <xsl:value-of select="@mime-type"/>
          </xsl:attribute>
          <xsl:attribute name="src">
            <xsl:value-of select="@src"/>
          </xsl:attribute>
          <xsl:if test="@height &gt; 0">
            <xsl:attribute name="height">
              <xsl:value-of select="@height"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:if test="@width &gt; 0">
            <xsl:attribute name="width">
              <xsl:value-of select="@width"/>
            </xsl:attribute>
          </xsl:if>
        </image>
      </media>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- remove empty tex nodes (this should not happen) -->
<xsl:template match="cnxtra:tex[not(node())]|cnxtra:gmath[not(node())]"/>

<!-- convert blahtex MathMl output to CNXML standards-->
<xsl:template match="cnxtra:tex[node()]|cnxtra:gmath[node()]">
  <xsl:choose>
    <xsl:when test="cnx:blahtex/cnx:mathml/cnx:markup">
      <m:math> <!-- namespace="http://www.w3.org/1998/Math/MathML"> --> <!-- Rhaptos does not want namespaces -->
        <m:semantics>
          <!-- enclose math in mrow when we have more than one child element -->
          <xsl:choose>
            <xsl:when test="count(cnx:blahtex/cnx:mathml/cnx:markup/*) &gt; 1">
	            <m:mrow>
                <xsl:apply-templates select="cnx:blahtex/cnx:mathml/cnx:markup/*" mode="mathml_ns"/>
              </m:mrow>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="cnx:blahtex/cnx:mathml/cnx:markup/*" mode="mathml_ns"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:apply-templates select="cnx:blahtex/cnx:annotation" mode="mathml_ns"/>
	      </m:semantics>
      </m:math>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text> [MathML Transformation-Error:</xsl:text>
        <xsl:value-of select="cnx:blahtex"/>
      <xsl:text>] </xsl:text>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- copy blahtex' MathML and change namespace to the right value -->
<xsl:template match="*" mode="mathml_ns">
  <xsl:element name="m:{local-name()}"> <!-- namespace="http://www.w3.org/1998/Math/MathML"> -->
    <xsl:apply-templates select="@*|node()" mode="mathml_ns"/>
  </xsl:element>
</xsl:template>

<!-- copy blahtex' MathML attributes and text also -->
<xsl:template match="@*|node()[not(self::*)]" mode="mathml_ns">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()" mode="mathml_ns"/>
  </xsl:copy>
</xsl:template>

<!-- OLD, should be removed in near future: -->
<!-- ID number generation -->
<!--
<xsl:template name="IDAttributeNO" mode="pass7NO">
  <xsl:text>gd-</xsl:text>
  <xsl:number count="
    cnx:document[not(@id)]
	|cnx:section[not(@id)]
	|cnx:para[not(@id)]
	|cnx:list[not(@id)]
	|cnx:table[not(@id)]
	|cnx:footnote[not(@id)]" level="any" format="000001"/>
</xsl:template>
-->

<!-- OLD, should be removed in near future: -->
<!-- Add id attribute to following elements -->
<!--
<xsl:template match="cnx:document|cnx:section|cnx:para|cnx:list|cnx:table|cnx:footnote" mode="pass7NO">
  <xsl:copy>
	<xsl:if test="not(@id)">
		<xsl:attribute name="id">
		  <xsl:call-template name="IDAttribute"/>
		</xsl:attribute>
	</xsl:if>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
</xsl:template>
-->

</xsl:stylesheet>
