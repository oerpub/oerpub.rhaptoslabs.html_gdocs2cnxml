<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
		xmlns="http://cnx.rice.edu/cnxml"
		xmlns:h="http://www.w3.org/1999/xhtml"
                xmlns:m="http://www.w3.org/1998/Math/MathML"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  
		exclude-result-prefixes="h">

  <xsl:output omit-xml-declaration="no" indent="yes" method="xml"
	      doctype-public="-//CNX//DTD CNXML 0.5 plus MathML//EN"
	      doctype-system="http://cnx.rice.edu/technology/cnxml/schema/dtd/0.5/cnxml_mathml.dtd"/>

  <xsl:template match="/">

    <document xmlns="http://cnx.rice.edu/cnxml"
	      xmlns:m="http://www.w3.org/1998/Math/MathML" 
              id="{generate-id()}">
      <name><xsl:value-of select="//h:title" /></name>
      <metadata xmlns:md="http://cnx.rice.edu/mdml/0.4">
	<md:version></md:version>
	<md:created>
	</md:created>
	<md:revised></md:revised>
	<md:authorlist>
	  <md:author id= "">
	    <md:firstname></md:firstname>
	    <md:surname></md:surname>
	    <md:email></md:email>
	  </md:author>
	</md:authorlist>
	<md:maintainerlist>
	  <md:maintainer id= "">
	    <md:firstname></md:firstname>
	    <md:surname></md:surname>
	    <md:email></md:email>
	  </md:maintainer>
	</md:maintainerlist>
	<md:abstract>
	</md:abstract>
      </metadata>
      
      <xsl:apply-templates select="//h:body" />
    </document>
  </xsl:template>

  <xsl:template match="h:body">
    <content>

      <xsl:apply-templates />
      <!--<para id="{generate-id()}">
	<xsl:for-each select="*[not(self::h:p) and not(preceding::h:p)]">
	  <xsl:apply-templates />
	</xsl:for-each>
    </para>-->

    </content>
  </xsl:template>

  <!-- SECTION -->
  <xsl:template match="h:section">
    <section id="{generate-id()}">
      <xsl:apply-templates />
    </section>
  </xsl:template>

  <!-- NAME -->
  <xsl:template match="h:name">
    <name><xsl:value-of select="(*|text())"/></name>
  </xsl:template>

  <!--<xsl:template match="text:h[@text:level='1' and following-sibling::text:p]">
       <section id="{generate-id()}">
    <name><xsl:value-of select="(*|text())"/></name>
       <xsl:call-template select="section-para">
       <xsl:with-param name="level">
       <xsl:value-of select="@text:level"/>
       </xsl:with-param>
       </xsl:call-template>
       </section>
       </xsl:template>

       <xsl:template name="section-para">
       <para id="{generate-id()}">
       <xsl:apply-templates />
       </para>
       <xsl:if test="not(follow-sibling::text:h)">
       <xsl:call-template name="section-para"/>
       </xsl:if>
       </xsl:template>
  -->

  <!-- Para -->
  <xsl:template match="h:p">
    <xsl:choose>
      <xsl:when test="parent::h:li">
	<xsl:apply-templates/>
      </xsl:when>
      <!--<xsl:when test="@text:style-name='Table'"/>
	   <xsl:when test="normalize-space(.)=''"/>
	   <xsl:when test="text:span[@text:style-name = 'XrefLabel']"/>-->
      <xsl:when test="parent::h:td">
	<xsl:apply-templates />
      </xsl:when>
      <xsl:otherwise>
	<para id="{generate-id()}">
	  <xsl:apply-templates />
	</para>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Any random stuff before the first heading, put it in a paragraph
       <xsl:template match="h:body/*[not(self::h:p) and not(preceding::h:p)]">
       <para id="{generate-id()}">
       <xsl:value-of select="local-name()" />
       <xsl:apply-templates />
       </para>
       </xsl:template>-->

  <!-- Do something with line-breaks -->
  <!--<xsl:template match="text:line-break">
       <xsl:if test="parent::text:p">
       <xsl:if test="following-sibling::text:line-break">
       <xsl:variable name='temp-id'>
       <xsl:value-of select="generate-id()"/>
       </xsl:variable>
       <xsl:text disable-output-escaping="yes">&lt;/para&gt;</xsl:text>
       <xsl:text disable-output-escaping="yes">&lt;para id='</xsl:text>
       <xsl:value-of select="$temp-id"/>
       <xsl:text disable-output-escaping="yes">'&gt;</xsl:text>
       </xsl:if>
       </xsl:if>
       </xsl:template>-->

  
  <!-- List and list items -->
  <xsl:template match="h:ol">
    <list type="enumerated">
      <xsl:apply-templates/>
    </list>
  </xsl:template>

  <xsl:template match="h:ul">
    <list type="bulleted" id="{generate-id()}">
      <xsl:apply-templates/>
    </list>
  </xsl:template>
  
  <xsl:template match="h:li">
    <item>
      <xsl:apply-templates/>
    </item>
  </xsl:template>


  <!-- Link -->
  <xsl:template match="h:a[text()]">
    <link src="{@href}">
      <xsl:apply-templates/>
    </link>
  </xsl:template>

  <!-- Figure -->
  <xsl:template match="h:img">
    <figure id="{generate-id()}">
      <media type="image/jpg" src="{@src}"/>
    </figure>    
  </xsl:template>
  
  
  <!-- Emphasis, Quote, Code 
       <xsl:template match="text:span">
       <xsl:variable name="Style">
       <xsl:value-of select="@text:style-name"/>
       </xsl:variable>
       <xsl:choose>
       <xsl:when test="$Style='Emphasis'">
       <emphasis>
       <xsl:apply-templates/>
       </emphasis>
       </xsl:when>
       <xsl:when test="$Style='q'">
       <quote>
       <xsl:apply-templates />
       </quote>
       </xsl:when>
       <xsl:when test="$Style='Code'">
       <code>
       <xsl:apply-templates/>
       </code>
       </xsl:when>
       <xsl:otherwise>
       <xsl:apply-templates />
       </xsl:otherwise>
       </xsl:choose>
       </xsl:template>-->

  <!-- MathML -->
  <xsl:template match="m:math">
    <xsl:copy-of select="."/>
  </xsl:template>


  <!-- Squash Everything Else -->
  <!--<xsl:template select="h:*"/>-->

</xsl:stylesheet>

