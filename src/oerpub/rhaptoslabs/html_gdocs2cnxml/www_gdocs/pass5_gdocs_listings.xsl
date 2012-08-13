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
This XSLT transforms lists of Google Docs HTML to nested lists.
Pass1 transformation is precondition for this pass.
Before and after this transformation the Google Docs HTML is no valid HTML anymore!

Input example:
  <cnhtml:list level="1">
    Heading1
  </cnhtml:list>
  <cnhtml:list level="2">
    Heading2
  </cnhtml:list>

Output:
  <ol>
    <li>Heading1
    <ol>
      <li>Heading2</li>
    </ol>
    </li>
  </ol>

-->

<xsl:key name="kListGroup" match="cnhtml:list"
  use="generate-id(preceding-sibling::node()[not(self::cnhtml:list)][1])" />

<xsl:template match="node()|@*">
  <xsl:copy>
    <xsl:apply-templates select="node()[1]|@*"/>
  </xsl:copy>
  <xsl:apply-templates select="following-sibling::node()[1]"/>
</xsl:template>

<!-- remove style attribute -->
<xsl:template match="cnhtml:list/@style"/>

<!-- remove start-value attribute from cnhtml:list -->
<xsl:template match="cnhtml:list/@start-value"/>

<!-- remove level attribute -->
<xsl:template match="cnhtml:list/@level"/>

<xsl:template match="cnhtml:list[preceding-sibling::node()[1][not(self::cnhtml:list)] or not(preceding-sibling::node()[1])]">
  <xsl:variable name="ancestor_header_id"> 
    <xsl:value-of select="generate-id(ancestor::cnhtml:h[1])"/>
  </xsl:variable>
  <!-- TODO: tables needs also more testings -->
  <ol>
    <!-- add start variable. Note: key (...) looks the same as on apply-templates below. -->
    <xsl:variable name="start">
      <xsl:value-of select="key('kListGroup', generate-id(preceding-sibling::node()[1]))
               [not(@level) or @level = 1]
               [generate-id(ancestor::cnhtml:h[1]) = $ancestor_header_id][self::cnhtml:list][1]/@start-value"/>
    </xsl:variable>
    <xsl:if test="$start != ''">
      <xsl:attribute name="start">
        <xsl:value-of select="$start"/>
      </xsl:attribute>
    </xsl:if>
    <!-- process list items -->
    <xsl:apply-templates mode="listgroup_pass5"
      select="key('kListGroup', generate-id(preceding-sibling::node()[1]))
               [not(@level) or @level = 1]
               [generate-id(ancestor::cnhtml:h[1]) = $ancestor_header_id]"/>
  </ol>
  <xsl:apply-templates select="following-sibling::node()[not(self::cnhtml:list)][1]"/>
</xsl:template>

<xsl:template match="cnhtml:list" mode="listgroup_pass5">
  <li>
    <xsl:apply-templates select="@*"/>
    <xsl:copy-of select="node()"/> <!-- use copy-of because apply-templates gives wrong result -->
    <!-- <xsl:value-of select="." /> -->

    <xsl:variable name="vNext"
      select="following-sibling::cnhtml:list[not(@level > current()/@level)][1]
          |following-sibling::node()[not(self::cnhtml:list)][1]"/>

    <xsl:variable name="vNextLevel"
      select="following-sibling::cnhtml:list
            [@level = current()/@level +1]
             [generate-id(following-sibling::cnhtml:list
                 [not(@level > current()/@level)][1]
                |
                following-sibling::node()[not(self::cnhtml:list)][1]
                   )
             =
              generate-id($vNext)
             ]
            " />
    <xsl:if test="$vNextLevel">
      <ol>
        <!-- add start value -->
        <xsl:if test="$vNextLevel[1]/@startvalue">
          <xsl:attribute name="start">
            <xsl:value-of select="$vNextLevel[1]/@startvalue"/>
          </xsl:attribute>
        </xsl:if>
        <!-- process list items -->
        <xsl:apply-templates select="$vNextLevel" mode="listgroup_pass5"/>
      </ol>
    </xsl:if>
  </li>
</xsl:template>

</xsl:stylesheet>
