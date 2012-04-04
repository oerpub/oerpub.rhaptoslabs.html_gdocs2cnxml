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
Post processing of CNXML
- Convert empty paragraphs to paragraphs with newlines
- Convert cnxtra:image to images
- Convert cnxtra:tex from Blahtex to embedded MathML

Deprecated:
- Add @IDs to elements (needs rework!)
-->

<!-- Default: copy everything -->
<xsl:template match="@*|node()" mode="pass7">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()" mode="pass7"/>
  </xsl:copy>
</xsl:template>

<!-- remove all nesting paras -->
<xsl:template match="cnx:para[ancestor::cnx:para]" mode="pass7">
  <xsl:apply-templates mode="pass7"/>
</xsl:template>

<!-- convert empty paragraphs to paragraphs with newline -->
<xsl:template match="cnx:para[not(child::*|text())]" mode="pass7">
  <para>
    <xsl:apply-templates select="@*" mode="pass7"/>
    <newline/>
  </para>
</xsl:template>

<!-- add an empty div to empty sections -->
<xsl:template match="cnx:section[not(child::cnx:*[not(self::cnx:title|self::cnx:section)])]" mode="pass7">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()" mode="pass7"/>
    <div/>
  </xsl:copy>
</xsl:template>

<!-- convert images to CNXML -->
<xsl:template match="cnxtra:image" mode="pass7">
  <!-- just ignore images which cannot be uploaded -->
  <!--
  <xsl:choose>
  -->
    <xsl:if test="text()">
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
    </xsl:if>
  <!--
    <xsl:otherwise>
      <xsl:text>[Image (Upload Error)]</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
  -->
</xsl:template>

<!-- remove empty tex nodes (this should not happen) -->
<xsl:template match="cnxtra:tex[not(node())]" mode="pass7"/>

<!-- convert blahtex MathMl output to CNXML standards-->
<xsl:template match="cnxtra:tex[node()]" mode="pass7">
  <xsl:choose>
    <xsl:when test="cnx:blahtex/cnx:mathml/cnx:markup">
      <m:math> <!-- namespace="http://www.w3.org/1998/Math/MathML"> --> <!-- Rhaptos does not want namespaces -->
        <m:semantics>
	        <xsl:apply-templates select="cnx:blahtex/cnx:mathml/cnx:markup/*" mode="mathml_pass7"/>
	        <m:annotation encoding="Google Chart Tools">
	          <xsl:value-of select="@src"/>
	        </m:annotation>
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
<xsl:template match="*" mode="mathml_pass7">
  <xsl:element name="m:{local-name()}"> <!-- namespace="http://www.w3.org/1998/Math/MathML"> -->
    <xsl:apply-templates select="@*|node()" mode="mathml_pass7"/>
  </xsl:element>
</xsl:template>

<!-- copy blahtex' MathML attributes and text also -->
<xsl:template match="@*|node()[not(self::*)]" mode="mathml_pass7">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()" mode="mathml_pass7"/>
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
		  <xsl:call-template name="IDAttribute" mode="pass7"/>
		</xsl:attribute>
	</xsl:if>
    <xsl:apply-templates select="@*|node()" mode="pass7"/>
  </xsl:copy>
</xsl:template>
-->

</xsl:stylesheet>
