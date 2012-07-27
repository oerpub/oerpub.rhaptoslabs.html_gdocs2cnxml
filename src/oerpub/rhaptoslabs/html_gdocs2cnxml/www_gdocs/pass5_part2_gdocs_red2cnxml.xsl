<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xh="http://www.w3.org/1999/xhtml"
  xmlns:cnhtml="http://cnxhtml"
  exclude-result-prefixes="xh cnhtml">

<!--
  <xsl:import href="urldecode.xsl"/>
-->
  
<xsl:output
  method="xml"
  encoding="UTF-8"
  indent="no"
  cdata-section-elements="cnhtml:cnxml"/>

<xsl:strip-space elements="*"/>
<xsl:preserve-space elements="xh:p xh:span xh:li cnhtml:list xh:td xh:a"/>

<!--
This XSLT encloses red text into <cnhtml:cnxml>some red text</cnhtml:cnxml>

Important node which will be converted to directly to CNXML (restrictive):
xh:span[@style='color:#ff0000']

Important node which will be converted to directly to CNXML (less restrictive):
xh:span[contains(@style, 'color:#ff0000')]

not important node (less restrictive):
*[parent::xh:p][not(contains(@style, 'color:#ff0000'))]

2012-05-07:
Change to violet text for Siyavula Docs
-->

<!-- Red text color constant -->
<!-- TODO: (Marvin) For some reason the constant does not work??? -->
<xsl:variable name="REDTEXTCOLOR" as="xs:string">color:#9900ff</xsl:variable>

<xsl:template match="node()|@*">
  <xsl:copy>
    <xsl:apply-templates select="node()|@*"/>
  </xsl:copy>
</xsl:template>

<!-- Look in span-children of this node if there is some red text -->
 <xsl:template match="xh:p[child::node() and not(ancestor::xh:div or ancestor::xh:table or ancestor::xh:li)]">
	<xsl:apply-templates select="node()[1]" mode="red2cnxml_walker"/>
    <!-- add linebreaks if red text used. Necessary for code blocks http://cnx.org/eip-help/code -->
    <xsl:if test="xh:span[contains(@style, 'color:#9900ff')]">
        <cnhtml:cnxml><xsl:text>&#xA;</xsl:text></cnhtml:cnxml>
    </xsl:if>
</xsl:template>

<xsl:template match="xh:span[contains(@style, 'color:#9900ff')]" mode="red2cnxml_walker">
	<cnhtml:cnxml><xsl:value-of select="."/></cnhtml:cnxml>
	<xsl:apply-templates select="following-sibling::node()[1]" mode="red2cnxml_walker"/>
</xsl:template>

<xsl:template match="node()" mode="red2cnxml_walker">
	<xsl:choose>
		<xsl:when test="not(preceding-sibling::node()) or preceding-sibling::node()[1][self::xh:span[contains(@style, 'color:#9900ff')]]">
			<xsl:element name="{name(..)}">
				<xsl:apply-templates select="../@*"/>
				<xsl:apply-templates select="."/>
				<xsl:apply-templates select="following-sibling::node()[1][not(self::xh:span[contains(@style, 'color:#9900ff')])]" mode="red2cnxml_walker"/>
			</xsl:element>
			<xsl:apply-templates select="following-sibling::xh:span[contains(@style, 'color:#9900ff')][1]" mode="red2cnxml_walker"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="."/>
			<xsl:apply-templates select="following-sibling::node()[1][not(self::xh:span[contains(@style, 'color:#9900ff')])]" mode="red2cnxml_walker"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>


</xsl:stylesheet>
