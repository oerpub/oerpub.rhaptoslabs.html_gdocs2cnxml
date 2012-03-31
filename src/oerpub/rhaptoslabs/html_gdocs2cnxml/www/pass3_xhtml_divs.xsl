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
Merges DIVs and removes not needed header content

Example input:
<body><div>Hello<div> this <div> is </div>some </div>text</div></body>

Output
<body>Hello this is some text</body>
-->

<!-- Default: copy everything -->
<xsl:template match="@*|node()">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
</xsl:template>

<!-- remove all divs (but preserve content of divs -->
<xsl:template match="xh:div">
  <xsl:apply-templates/>
</xsl:template>


<!-- remove all nesting divs -->
<!--
<xsl:template match="xh:div[ancestor::xh:div]">
  <xsl:apply-templates/>
</xsl:template>
-->

<!-- remove everything from header except title and metadata -->
<xsl:template match="xh:head/xh:*[not(self::xh:title or self::xh:meta)]"/>

<!-- remove comments -->
<xsl:template match="comment()"/>

<!-- remove scripts -->
<xsl:template match="xh:script"/>

<!-- remove iframes -->
<xsl:template match="xh:iframe"/>

</xsl:stylesheet>
