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
<xsl:preserve-space elements="xh:p xh:span xh:li cnhtml:list xh:td xh:a"/>

<!--
This XSLT transforms
normalizes headers.
Important if headers always start at level 2 or the first header is not in level 1.
-->

<!-- Default: copy everything -->
<xsl:template match="@*|node()">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
</xsl:template>

<!-- do not copy @level, it will be calculated/normalized -->
<xsl:template match="cnhtml:h/@level"/>

<xsl:variable name="min_level">
  <xsl:value-of select="//cnhtml:h[not(preceding-sibling::cnhtml:h/@level &lt; @level) and not(following-sibling::cnhtml:h/@level &lt; @level)][1]/@level"/>
</xsl:variable>

<xsl:variable name="delta_level_one">
  <xsl:value-of select="$min_level - 1"/>
</xsl:variable>

<xsl:template match="cnhtml:h">
  <xsl:variable name="temp_level">
    <xsl:value-of select="@level - $delta_level_one"/>
  </xsl:variable>
  
  <!-- TODO: Quickfix, first header is always level 1. Needs more logic! -->
  <xsl:variable name="new_level">
      <xsl:choose>
        <xsl:when test="generate-id(.) = generate-id(//cnhtml:h[1])">
          <xsl:value-of select="'1'"/>
        </xsl:when>
        <xsl:otherwise>         
            <xsl:value-of select="$temp_level"/>
        </xsl:otherwise>
      </xsl:choose>
  </xsl:variable>
  
  <xsl:copy>
  	<xsl:attribute name="level">
  	  <xsl:value-of select="$new_level"/>
  	</xsl:attribute>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
</xsl:template>

</xsl:stylesheet>
