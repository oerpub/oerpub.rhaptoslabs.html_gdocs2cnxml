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

<!--
Encloses nodes and text inside paragraphs if they are not enclosed by paragraphs.
This step is needed to get valid CNXML at the end.

This XSLT encloses all valid XHTML children of <p> inside <p>....</p> if they are not already enclosed by <p>.
It should work for all valid XHTML which do not have nested <div>.

If you want a simpler example of this XSLT which does not take care of all XHTML tags look at pass4_xhtml_text_old_simple.xsl.

Input example:
<body>
  <p>Hello</p>I'm <a href="http://www.google.com">a link.</a>
</body>

Output:
<body>
  <p>hello</p><p>I'm <a href="http://www.google.com">a link</a></p>
</body>

-->

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

<xsl:template match="node()
  [
		self::text()
		or self::xh:a
		or self::xh:abbr
		or self::xh:acronym
		or self::xh:applet
		or self::xh:b
		or self::xh:basefont
		or self::xh:bdo
		or self::xh:big
		or self::xh:br
		or self::xh:button
		or self::xh:cite
		or self::xh:code
		or self::xh:del
		or self::xh:dfn
		or self::xh:em
		or self::xh:font
		or self::xh:i
		or self::xh:img
		or self::xh:ins
		or self::xh:input
		or self::xh:iframe
		or self::xh:kbd
		or self::xh:label
		or self::xh:map
		or self::xh:object
		or self::xh:q
		or self::xh:samp
		or self::xh:script
		or self::xh:select
		or self::xh:small
		or self::xh:span
		or self::xh:strong
		or self::xh:sub
		or self::xh:sup
		or self::xh:textarea
		or self::xh:tt
		or self::xh:var
  ]
  [not(preceding-sibling::node())
   or preceding-sibling::node()[1]
    [
      not(
		  self::text()
			or self::xh:a
			or self::xh:abbr
			or self::xh:acronym
			or self::xh:applet
			or self::xh:b
			or self::xh:basefont
			or self::xh:bdo
			or self::xh:big
			or self::xh:br
			or self::xh:button
			or self::xh:cite
			or self::xh:code
			or self::xh:del
			or self::xh:dfn
			or self::xh:em
			or self::xh:font
			or self::xh:i
			or self::xh:img
			or self::xh:ins
			or self::xh:input
			or self::xh:iframe
			or self::xh:kbd
			or self::xh:label
			or self::xh:map
			or self::xh:object
			or self::xh:q
			or self::xh:samp
			or self::xh:script
			or self::xh:select
			or self::xh:small
			or self::xh:span
			or self::xh:strong
			or self::xh:sub
			or self::xh:sup
			or self::xh:textarea
			or self::xh:tt
			or self::xh:var
			)
    ]
  ]" mode="walker_pass4">
  <p>
    <xsl:apply-templates select="." mode="pass4"/>
    <!-- is following node not p ? -->
    <xsl:if test="following-sibling::node()[1]
      [
				self::text()
				or self::xh:a
				or self::xh:abbr
				or self::xh:acronym
				or self::xh:applet
				or self::xh:b
				or self::xh:basefont
				or self::xh:bdo
				or self::xh:big
				or self::xh:br
				or self::xh:button
				or self::xh:cite
				or self::xh:code
				or self::xh:del
				or self::xh:dfn
				or self::xh:em
				or self::xh:font
				or self::xh:i
				or self::xh:img
				or self::xh:ins
				or self::xh:input
				or self::xh:iframe
				or self::xh:kbd
				or self::xh:label
				or self::xh:map
				or self::xh:object
				or self::xh:q
				or self::xh:samp
				or self::xh:script
				or self::xh:select
				or self::xh:small
				or self::xh:span
				or self::xh:strong
				or self::xh:sub
				or self::xh:sup
				or self::xh:textarea
				or self::xh:tt
				or self::xh:var
      ]">
      <xsl:apply-templates select="following-sibling::node()[1]" mode="walker_pass4">
        <xsl:with-param name="inside_paragraph" select="'yes'"/>
      </xsl:apply-templates>
    </xsl:if>
  </p>
  <xsl:apply-templates select="
			following-sibling::node()
			  [
					not(
					self::text()
					or self::xh:a
					or self::xh:abbr
					or self::xh:acronym
					or self::xh:applet
					or self::xh:b
					or self::xh:basefont
					or self::xh:bdo
					or self::xh:big
					or self::xh:br
					or self::xh:button
					or self::xh:cite
					or self::xh:code
					or self::xh:del
					or self::xh:dfn
					or self::xh:em
					or self::xh:font
					or self::xh:i
					or self::xh:img
					or self::xh:ins
					or self::xh:input
					or self::xh:iframe
					or self::xh:kbd
					or self::xh:label
					or self::xh:map
					or self::xh:object
					or self::xh:q
					or self::xh:samp
					or self::xh:script
					or self::xh:select
					or self::xh:small
					or self::xh:span
					or self::xh:strong
					or self::xh:sub
					or self::xh:sup
					or self::xh:textarea
					or self::xh:tt
					or self::xh:var
					)
        ]
        [1]" mode="walker_pass4"/>
</xsl:template>

<xsl:template match="node()" mode="walker_pass4">
  <xsl:param name="inside_paragraph" select="'no'"/>

  <xsl:apply-templates select="." mode="pass4"/>

  <xsl:if test="
    not($inside_paragraph='yes'
    and following-sibling::node()
	    [1]
	    [
				not(
				self::text()
				or self::xh:a
				or self::xh:abbr
				or self::xh:acronym
				or self::xh:applet
				or self::xh:b
				or self::xh:basefont
				or self::xh:bdo
				or self::xh:big
				or self::xh:br
				or self::xh:button
				or self::xh:cite
				or self::xh:code
				or self::xh:del
				or self::xh:dfn
				or self::xh:em
				or self::xh:font
				or self::xh:i
				or self::xh:img
				or self::xh:ins
				or self::xh:input
				or self::xh:iframe
				or self::xh:kbd
				or self::xh:label
				or self::xh:map
				or self::xh:object
				or self::xh:q
				or self::xh:samp
				or self::xh:script
				or self::xh:select
				or self::xh:small
				or self::xh:span
				or self::xh:strong
				or self::xh:sub
				or self::xh:sup
				or self::xh:textarea
				or self::xh:tt
				or self::xh:var
			  )
      ]
    )">
    <xsl:apply-templates select="following-sibling::node()[1]" mode="walker_pass4">
      <xsl:with-param name="inside_paragraph" select="$inside_paragraph"/>
    </xsl:apply-templates>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>
