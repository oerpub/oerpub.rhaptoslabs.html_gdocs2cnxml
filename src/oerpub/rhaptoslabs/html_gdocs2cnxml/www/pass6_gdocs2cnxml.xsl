<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://cnx.rice.edu/cnxml"
  xmlns:md="http://cnx.rice.edu/mdml"
  xmlns:bib="http://bibtexml.sf.net/"
  xmlns:m="http://www.w3.org/1998/Math/MathML"
  xmlns:q="http://cnx.rice.edu/qml/1.0"
  xmlns:xh="http://www.w3.org/1999/xhtml"
  xmlns:cnhtml="http://cnxhtml"
  xmlns:cnxtra="http://cnxtra"
  xmlns:exsl="http://exslt.org/common"
  version="1.0"
  extension-element-prefixes="exsl"
  exclude-result-prefixes="exsl xh cnhtml cnxtra">

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<xsl:strip-space elements="*"/>

<!--
This XSLT transforms Google Docs HTML tags to CNXML.
Most of the HTML tags are converted to CNXML.
But after this transformation ID attributes are still missing and internal links point
to a <cnxtra:bookmark> placeholder which is not a valid CNML tag!
Pass1,2...4 transformation is a precondition for this pass.
-->

<xsl:template match="/" mode="pass6">
  <document>
    <xsl:attribute name="cnxml-version">0.7</xsl:attribute>
    <xsl:attribute name="module-id">new</xsl:attribute>
     <xsl:apply-templates select="xh:html" mode="pass6"/>
  </document>
</xsl:template>

<!-- HTML -->
<xsl:template match="xh:html" mode="pass6">
  <xsl:apply-templates select="xh:head" mode="pass6"/>
  <content>
    <xsl:apply-templates select="xh:body" mode="pass6"/>
  </content>
</xsl:template>

<!-- Get the title out of the header -->
<xsl:template match="xh:head" mode="pass6">
  <!-- if document title is missing, Rhaptos creates error in metadata! -->
  <title>
    <xsl:variable name="document_title">
      <xsl:value-of select="normalize-space(xh:title)"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string-length($document_title) &gt; 0">
        <xsl:value-of select="$document_title"/>
      </xsl:when>
      <xsl:otherwise> <!-- create "untitled" as title text -->
        <xsl:text>Untitled</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </title>
</xsl:template>

<!-- HTML body -->
<xsl:template match="xh:body" mode="pass6">
  <xsl:apply-templates mode="pass6"/>
</xsl:template>

<!-- embedded CNXML (red text) -->
<xsl:template match="cnhtml:cnxml" mode="pass6">
  <xsl:value-of select="." disable-output-escaping="yes"/>
</xsl:template>

<!-- paragraphs -->
<xsl:template match="xh:p" mode="pass6">
  <para>
    <xsl:apply-templates mode="pass6"/>
  </para>
</xsl:template>

<!-- span -->
<xsl:template match="xh:span" mode="pass6">
  <xsl:choose>
    <!-- Do we have a header? Then do not apply any emphasis to the <title> -->
     <xsl:when test="parent::cnhtml:h">
      <xsl:apply-templates mode="pass6"/>
    </xsl:when>
    <!-- First super- and supformat text -->
    <xsl:when test="contains(@style, 'vertical-align:super')">
      <sup>
        <xsl:apply-templates mode="pass6"/>
      </sup>
    </xsl:when>
    <xsl:when test="contains(@style, 'vertical-align:sub')">
      <sub>
        <xsl:apply-templates mode="pass6"/>
      </sub>
    </xsl:when>
    <xsl:when test="contains(@style, 'font-style:italic')">
      <emphasis effect='italics'>
        <xsl:apply-templates mode="pass6"/>
      </emphasis>
    </xsl:when>
    <xsl:when test="contains(@style, 'font-weight:bold')">
      <emphasis effect='bold'>
        <xsl:apply-templates mode="pass6"/>
      </emphasis>
    </xsl:when>
    <xsl:when test="contains(@style, 'text-decoration:underline')">
      <!-- when we have no text, e.g. just links, do not generate emphasis -->
      <xsl:choose>
        <xsl:when test="text()">
          <emphasis effect='underline'>
            <xsl:apply-templates mode="pass6"/>
          </emphasis>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates mode="pass6"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates mode="pass6"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- copy text from specific text-nodes -->
<xsl:template match="xh:span/text()|xh:li/text()|xh:td/text()|xh:a/text()" mode="pass6">
  <xsl:value-of select="."/>
</xsl:template>

<!-- headers -->
<xsl:template match="cnhtml:h" mode="pass6">
  <xsl:choose>
    <!-- do not create a section if we are inside tables -->
    <xsl:when test="ancestor::xh:td">
      <xsl:value-of select="@title"/>
      <xsl:apply-templates mode="pass6"/>
    </xsl:when>
    <xsl:otherwise>
		  <!-- Check if header is empty, if yes, create no section -->
		  <xsl:if test="@title">
			  <section>
			    <title>
			      <xsl:value-of select="@title"/>
			    </title>
			    <xsl:apply-templates mode="pass6"/>
			  </section>
		  </xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- listings -->
<xsl:template match="xh:ol" mode="pass6">
  <xsl:if test="xh:li">
    <xsl:apply-templates select="xh:li[1]" mode="walker_pass6">
      <xsl:with-param name="preceding_style" select="'unknown'"/>
    </xsl:apply-templates>
  </xsl:if>
</xsl:template>

<!-- ignore li, instead walk through li's (look at template ol above) -->
<xsl:template match="xh:li" mode="pass6"/>

<!-- walk through listings -->
<xsl:template match="xh:li" mode="walker_pass6">
  <xsl:param name="preceding_style" select="'unknown'"/>
  <xsl:variable name="my_style" select="@list-style-type"/>
  <xsl:variable name="next_same_style" select="following-sibling::*[1][self::xh:li][@list-style-type = $my_style]"/>

  <!-- TODO: Is this wrong? Check if next_diff_style only looks for the next different style in current <ol> block -->
  <xsl:variable name="next_diff_style" select="following-sibling::xh:li[@list-style-type != $my_style][1]"/>

  <xsl:choose>
    <xsl:when test="$preceding_style = @list-style-type">
      <item>
        <xsl:apply-templates mode="pass6"/>
      </item>
      <xsl:apply-templates select="$next_same_style" mode="walker_pass6">
        <xsl:with-param name="preceding_style" select="$my_style"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:when test="$preceding_style = 'unknown'">
      <list>
        <xsl:choose>
          <xsl:when test="$my_style = 'disc'">
            <xsl:attribute name="list-type">bulleted</xsl:attribute>
          </xsl:when>
          <xsl:when test="$my_style = 'circle'">
            <xsl:attribute name="list-type">bulleted</xsl:attribute>
            <xsl:attribute name="bullet-style">open-circle</xsl:attribute>
          </xsl:when>
          <xsl:when test="$my_style = 'decimal'">
            <xsl:attribute name="list-type">enumerated</xsl:attribute>
          </xsl:when>
          <xsl:when test="$my_style = 'upper-latin'">
            <xsl:attribute name="list-type">enumerated</xsl:attribute>
            <xsl:attribute name="number-style">upper-alpha</xsl:attribute>
          </xsl:when>
          <xsl:when test="$my_style = 'lower-latin'">
            <xsl:attribute name="list-type">enumerated</xsl:attribute>
            <xsl:attribute name="number-style">lower-alpha</xsl:attribute>
          </xsl:when>
          <xsl:when test="$my_style = 'lower-roman'">
            <xsl:attribute name="list-type">enumerated</xsl:attribute>
            <xsl:attribute name="number-style">lower-roman</xsl:attribute>
          </xsl:when>
          <xsl:when test="$my_style = 'upper-roman'">
            <xsl:attribute name="list-type">enumerated</xsl:attribute>
            <xsl:attribute name="number-style">upper-roman</xsl:attribute>
          </xsl:when>
          <xsl:otherwise> <!-- Fail safe mode -->
            <xsl:attribute name="list-type">bulleted</xsl:attribute>
          </xsl:otherwise>
        </xsl:choose>
        <item>
          <xsl:apply-templates mode="pass6"/>
        </item>
        <xsl:apply-templates select="$next_same_style" mode="walker_pass6">
          <xsl:with-param name="preceding_style" select="$my_style"/>
        </xsl:apply-templates>
      </list>
      <xsl:apply-templates select="$next_diff_style" mode="walker_pass6">
        <xsl:with-param name="preceding_style" select="'unknown'"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>
      <xsl:message>This should not happen!</xsl:message>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- table -->
<xsl:template match="xh:table" mode="pass6">
  <table>
    <xsl:attribute name="summary" select=""/>
    <xsl:apply-templates select="xh:tbody" mode="pass6"/>
  </table>
</xsl:template>

<!-- table body -->
<xsl:template match="xh:tbody" mode="pass6">
  <tgroup>
    <xsl:attribute name="cols">
      <!-- get number of column from the first row -->
      <xsl:value-of select="count(xh:tr[1]/xh:td)"/>
    </xsl:attribute>
    <tbody>
      <xsl:for-each select="xh:tr">
        <row>
          <xsl:for-each select="xh:td">
            <entry>
              <!-- Ignore paragraphs and headings, only process span -->
              <xsl:apply-templates select="*[not(self::xh:table)]" mode="pass6"/>
              <!-- TODO: Support nested tables? -->
              <xsl:if test="xh:table">
                <xsl:text>ERROR! Nested tables are not supported!</xsl:text>
                <xsl:message>Warning: Nested tables are not supported! The nested table will be ignored!</xsl:message>
              </xsl:if>
            </entry>
          </xsl:for-each>
        </row>
      </xsl:for-each>
    </tbody>
  </tgroup>
</xsl:template>

<!-- links -->
<xsl:template match="xh:a" mode="pass6">
  <xsl:if test="@href">
    <xsl:choose>
      <!-- internal link -->
      <xsl:when test="substring(@href, 1, 1) = '#'">
        <link>
	        <xsl:attribute name="bookmark">
	          <xsl:value-of select="@href"/>
	        </xsl:attribute>
	        <xsl:apply-templates mode="pass6"/>
	      </link>
      </xsl:when>
      <!-- external link -->
      <xsl:otherwise>
		    <link>
		      <xsl:attribute name="url">
		        <xsl:value-of select="@href"/> <!-- link url -->
 		      </xsl:attribute>
		      <!-- open external links default in new window if they are no emails-->
		      <xsl:if test="not(starts-with(@href, 'mailto'))">
		        <xsl:attribute name="window">new</xsl:attribute>
		      </xsl:if>
		      <xsl:apply-templates mode="pass6"/>
		    </link>
	    </xsl:otherwise>
    </xsl:choose>
  </xsl:if>
  <!-- create a "bookmark" for internal links -->
  <xsl:if test="@name">
  	<cnxtra:bookmark>
  		<xsl:attribute name="name">
  			<xsl:value-of select="@name"/>
  		</xsl:attribute>
  		<xsl:apply-templates mode="pass6"/>
  	</cnxtra:bookmark>
	</xsl:if>
</xsl:template>

<!-- images -->
<xsl:template match="xh:img" mode="pass6">
  <cnxtra:image>
    <xsl:copy-of select="@src|@height|@width|@alt"/>
  </cnxtra:image>
</xsl:template>

<!-- links to footnotes -->
<xsl:template match="xh:sup/xh:a" mode="pass6">
  <xsl:variable name="reference">
    <xsl:value-of select="substring(@href, 2)"/>
  </xsl:variable>
  <!-- Do not create a footnote if reference is a gdocs comment -->
  <xsl:if test="not(starts-with($reference, 'cmnt'))">
	  <footnote>
	    <xsl:apply-templates select="//xh:div[xh:p/xh:a[@name = $reference]]/xh:p/xh:span" mode="pass6"/>
	  </footnote>
	</xsl:if>
</xsl:template>

<!-- Look for TeX Formulars from Google Chart Tools -->
<xsl:template match="xh:img[
  (contains(@src, 'cht=tx')
  and contains(@src, 'chart')
  and (contains(@src, '.google.com') or contains(@src, '.googleapis.com')))
  and (contains(@src, '?chl=') or contains(@src, '&amp;chl='))]" mode="pass6">

  <cnxtra:tex>
    <xsl:attribute name="src">
      <xsl:value-of select="@src"/>
    </xsl:attribute>

    <!-- parse the tex string out -->
    <xsl:variable name="parsedTex1">
      <xsl:value-of select="substring-after(@src, 'chl=')"/>
    </xsl:variable>

    <xsl:variable name="parsedTex2">
      <xsl:choose>
      <xsl:when test="not(contains($parsedTex1, '&amp;'))">
          <xsl:value-of select="$parsedTex1"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="substring-before($parsedTex1, '&amp;')"/>
      </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- Keep in mind: tex is still URL encoded! -->
    <xsl:attribute name="tex">
      <xsl:value-of select="$parsedTex2"/>
    </xsl:attribute>
  </cnxtra:tex>
</xsl:template>


<!-- underline -->
<!--
<xsl:template match="hr" mode="pass6">
  <underline/>
</xsl:template>
-->

<!-- ignore div -->
<xsl:template match="xh:div" mode="pass6"/>

</xsl:stylesheet>
