<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xh="http://www.w3.org/1999/xhtml"
  xmlns:cnhtml="http://cnxhtml"
  exclude-result-prefixes="xh cnhtml">

<xsl:output
  method="xml"
  encoding="UTF-8"
  indent="yes"/>

<xsl:strip-space elements="*"/>

<!-- This XSLT encloses text inside paragraphs -->

<!-- Default: copy everything -->
<xsl:template match="@*|node()" mode="pass4">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()" mode="pass4"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="xh:body" mode="pass4">
  <xsl:copy>
    <xsl:apply-templates select="@*" mode="pass4"/>
    <xsl:apply-templates select="node()[1]" mode="walker_pass4"/>
  </xsl:copy>
</xsl:template>

<!-- notes which are not p and (do not have any preceding node or preceding p node -->
<xsl:template match="node()
[not(self::xh:p)]
[not(preceding-sibling::node())
 or preceding-sibling::node()[1]
 [self::xh:p
  or self::cnhtml:h]
]" mode="walker_pass4">
  <p>
    <xsl:apply-templates select="." mode="pass4"/>
    <!-- is following node not p ? -->
    <xsl:if test="following-sibling::node()[1]
      [not(self::xh:p or self::cnhtml:h)]">
      <xsl:apply-templates select="following-sibling::node()[1]" mode="walker_pass4">
        <xsl:with-param name="inside_paragraph" select="'yes'"/>
      </xsl:apply-templates>
    </xsl:if>
  </p>
  <xsl:apply-templates select="
    (following-sibling::xh:p[1]
    |following-sibling::cnhtml:h[1])[1]"
    mode="walker_pass4"/>
</xsl:template>

<xsl:template match="node()" mode="walker_pass4">
  <xsl:param name="inside_paragraph" select="'no'"/>

  <xsl:apply-templates select="." mode="pass4"/>

  <xsl:if test="not($inside_paragraph='yes' and following-sibling::node()[1]
    [self::xh:p
    or self::cnhtml:h])">
    <xsl:apply-templates select="following-sibling::node()[1]" mode="walker_pass4">
      <xsl:with-param name="inside_paragraph" select="$inside_paragraph"/>
    </xsl:apply-templates>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>
