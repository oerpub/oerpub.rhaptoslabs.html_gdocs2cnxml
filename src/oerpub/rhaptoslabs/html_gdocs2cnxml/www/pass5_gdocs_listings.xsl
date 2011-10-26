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

<xsl:template match="node()|@*" mode="pass5">
  <xsl:copy>
    <xsl:apply-templates select="node()[1]|@*" mode="pass5"/>
  </xsl:copy>
  <xsl:apply-templates select="following-sibling::node()[1]" mode="pass5"/>
</xsl:template>

<!-- remove style attribute -->
<xsl:template match="cnhtml:list/@style" mode="pass5"/>

<!-- remove level attribute -->
<xsl:template match="cnhtml:list/@level" mode="pass5"/>

<xsl:template match="cnhtml:list[preceding-sibling::node()[1][not(self::cnhtml:list)] or not(preceding-sibling::node()[1])]" mode="pass5">
  <ol>
    <xsl:apply-templates mode="listgroup_pass5"
      select="key('kListGroup', generate-id(preceding-sibling::node()[1]))
               [not(@level) or @level = 1]"/>
  </ol>
  <xsl:apply-templates select="following-sibling::node()[not(self::cnhtml:list)][1]" mode="pass5"/>
</xsl:template>

<xsl:template match="cnhtml:list" mode="listgroup_pass5">
  <li>
    <xsl:apply-templates select="@*" mode="pass5"/>
    <xsl:copy-of select="*"/> <!-- use copy-of because apply-templates gives wron result -->
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
        <xsl:apply-templates select="$vNextLevel" mode="listgroup_pass5"/>
      </ol>
    </xsl:if>
  </li>
</xsl:template>

</xsl:stylesheet>
