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
<xsl:preserve-space elements="cnx:emphasis"/>

<!--
Post processing of CNXML
After this step the CNXML should be a valid CNXML.
- Add internal linking
- remove <cnxtra:bookmark> placeholders

This XSLT searches for links to <bookmarks> and replaces this internal links
with the nearest preceding/following or nearest ancestor/descendant @id.
<cnxtra:bookmark> are not valid CNXML and only placeholders which are removed during this transformation.
This is also the reason why they have their own namespace.

Input example (CNXML with an invalid bookmark placeholder):
   <link bookmark="#h.xyz">look at Heading1</link>
   <para id="gd-000001">hello1</para>
   <section id="gd-000002">
      <title>Heading1</title>
      <cnxtra:bookmark name="h.xyz"/>
      <para id="gd-000003">hello2</para>
   </section>

Output (CNXML with a correct id linking, bookmark removed):
   <link target-id="gd-000002">look at Heading1</link>
   <para id="gd-000001">hello1</para>
   <section id="gd-000002">
      <title>Heading1</title>
      <para id="gd-000003">hello2</para>
   </section>

-->

<!-- Default: copy everything -->
<xsl:template match="@*|node()">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
</xsl:template>

<!-- remove bookmark attribute -->
<xsl:template match="cnx:link/@bookmark"/>

<!-- generate internal links -->
<xsl:template match="cnx:link[@bookmark]">

  <!-- if we have a link with only '#' in @bookmark, then do not create any <link> -->
  <xsl:choose>
		<xsl:when test="string-length(@bookmark) &gt; 1">

		  <xsl:variable name="bookmark">
	      <xsl:value-of select="substring(@bookmark, 2)"/>
	    </xsl:variable>

			<!-- if we have a header bookmark 'h.xyz' use a id from preceding element -->
			<!-- if we have an id bookmark 'id.xyz' use the following element -->

			<xsl:variable name="precedingID">
		    <!-- this was a bit complicated: Get the nearest ancestor or preceding node from bookmark  -->
		    <!-- http://stackoverflow.com/questions/6554067/xpath-1-0-closest-preceding-and-or-ancestor-node-with-an-attribute-in-a-xml-tree -->
		    <xsl:value-of select="(//cnxtra:bookmark[@name = $bookmark]/ancestor::cnx:*[@id][1]/@id|//cnxtra:bookmark[@name = $bookmark]/preceding::cnx:*[@id][1]/@id)[last()]"/>
			</xsl:variable>
			<xsl:variable name="followingID">
			  <!-- Get the nearest descendant or following node from bookmark  -->
		    <xsl:value-of select="(//cnxtra:bookmark[@name = $bookmark]/descendant::cnx:*[@id][1]/@id|//cnxtra:bookmark[@name = $bookmark]/following::cnx:*[@id][1]/@id)[1]"/>
			</xsl:variable>

		  <xsl:choose>
		    <xsl:when test="$precedingID or $followingID">
			    <link>
		        <xsl:attribute name="target-id">
		          <xsl:choose>
		            <xsl:when test="starts-with($bookmark, 'id')">
		              <!-- first try with followingID, when not available use precedingID -->
		              <xsl:choose>
		                <xsl:when test="$followingID">
		                  <xsl:value-of select="$followingID"/>
		                </xsl:when>
		                <xsl:otherwise>
		                  <xsl:value-of select="$precedingID"/>
		                </xsl:otherwise>
		              </xsl:choose>
	              </xsl:when>
		            <xsl:otherwise>
	                <!-- first try with precedingID, when not available use followingID -->
		              <xsl:choose>
		                <xsl:when test="$precedingID">
		                  <xsl:value-of select="$precedingID"/>
		                </xsl:when>
		                <xsl:otherwise>
		                  <xsl:value-of select="$followingID"/>
		                </xsl:otherwise>
		              </xsl:choose>
		            </xsl:otherwise>
		          </xsl:choose>
		        </xsl:attribute>
		        <xsl:apply-templates select="@*"/>
		        <xsl:apply-templates/>
			    </link>
		    </xsl:when>
		    <!-- if no IDs were found, remove the link -->
		    <xsl:otherwise>
		      <xsl:apply-templates/>
		    </xsl:otherwise>
		  </xsl:choose>
		</xsl:when>
		<xsl:otherwise>
		  <!-- just apply templates to child notes if bookmark is less than 1 character -->
		  <xsl:apply-templates/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- remove bookmark element placeholders -->
<xsl:template match="cnxtra:bookmark"/>

<!-- remove underline placeholder -->
<!--
<xsl:template match="cnx:underline"/>
-->

</xsl:stylesheet>
