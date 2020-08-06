<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:wb-name-util="workbench.sql.NameUtil"
                xmlns:wb-string-util="workbench.util.StringUtil"
                xmlns:wb-sql-util="workbench.util.SqlUtil">
<!--
  Convert a SQL Workbench/J schema report (http://www.sql-workbench.net)
  into a SQL script for MySQL (http://www.oracle.com)

  Author: Thomas Kellerer
-->

<xsl:output
  encoding="iso-8859-15"
  method="text"
  indent="no"
  standalone="yes"
  omit-xml-declaration="yes"
/>

<xsl:strip-space elements="*"/>
<xsl:variable name="quote"><xsl:text>"</xsl:text></xsl:variable>
<xsl:variable name="newline"><xsl:text>&#10;</xsl:text></xsl:variable>

<xsl:template match="/">
  <xsl:apply-templates select="/schema-report/table-def"/>
  <xsl:apply-templates select="/schema-report/view-def"/>
  <xsl:call-template name="process-fk"/>
</xsl:template>

<xsl:template match="table-def">

  <xsl:variable name="tablename" select="table-name"/>
  <xsl:text>DROP TABLE IF EXISTS </xsl:text>
  <xsl:value-of select="table-name"/>
  <xsl:text>;</xsl:text>
  <xsl:value-of select="$newline"/>

  <xsl:text>CREATE TABLE </xsl:text><xsl:value-of select="table-name"/>
  <xsl:value-of select="$newline"/>
  <xsl:text>(</xsl:text>
  <xsl:value-of select="$newline"/>

  <xsl:for-each select="column-def">
    <xsl:sort select="dbms-position"/>
    <xsl:variable name="colname">
      <xsl:choose>
        <xsl:when test="contains(column-name,' ')">
          <xsl:value-of select="concat($quote,column-name,$quote)"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="column-name"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="nullable">
      <xsl:if test="nullable = 'false'"> NOT NULL</xsl:if>
    </xsl:variable>

    <xsl:variable name="defaultvalue">
      <xsl:if test="string-length(default-value) &gt; 0">
        <xsl:text> DEFAULT </xsl:text><xsl:value-of select="default-value"/>
      </xsl:if>
    </xsl:variable>

    <xsl:variable name="datatype">
      <xsl:choose>
        <xsl:when test="java-sql-type-name = 'TIMESTAMP'">
          <xsl:value-of select="'DATETIME'"/>
        </xsl:when>
        <!-- this is for an Oracle migration -->
        <xsl:when test="dbms-data-type = 'DATE'">
          <xsl:value-of select="'DATETIME'"/>
        </xsl:when>
        <xsl:when test="dbms-data-type = 'CLOB'">
          <xsl:value-of select="'LONGTEXT'"/>
        </xsl:when>
        <xsl:when test="dbms-data-type = 'BLOB'">
          <xsl:value-of select="'LONGBLOB'"/>
        </xsl:when>
        <xsl:when test="java-sql-type-name = 'DECIMAL'">
          <xsl:choose>
            <xsl:when test="dbms-data-digits &gt; 0">
              <xsl:text>DECIMAL(</xsl:text><xsl:value-of select="dbms-data-size"/><xsl:text>,</xsl:text><xsl:value-of select="dbms-data-digits"/><xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:when test="dbms-data-size &gt; 9">
              <xsl:text>BIGINT</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>INTEGER</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="java-sql-type-name = 'VARCHAR'">
          <xsl:value-of select="'VARCHAR('"/><xsl:value-of select="dbms-data-size"/><xsl:value-of select="')'"/>
        </xsl:when>
        <xsl:when test="java-sql-type-name = 'BIGINT'">
          <xsl:value-of select="'BIGINT'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="dbms-data-type"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:text>  </xsl:text>
    <xsl:copy-of select="$colname"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$datatype"/>
    <xsl:value-of select="$defaultvalue"/>
    <xsl:value-of select="$nullable"/>
    <xsl:if test="position() &lt; last()">
      <xsl:text>,</xsl:text><xsl:value-of select="$newline"/>
    </xsl:if>
  </xsl:for-each>
  <xsl:value-of select="$newline"/>
  <xsl:text>);</xsl:text>
  <xsl:value-of select="$newline"/>
  <xsl:value-of select="$newline"/>
  
  <xsl:variable name="pkcount">
    <xsl:value-of select="count(column-def[primary-key='true'])"/>
  </xsl:variable>

  <xsl:if test="$pkcount &gt; 0">
    <xsl:text>ALTER TABLE </xsl:text><xsl:value-of select="$tablename"/>
    <xsl:value-of select="$newline"/>
	<xsl:variable name="constraintname">
    <xsl:if test="string-length(primary-key-name) &gt; 0">
      <xsl:value-of select="primary-key-name"/>
    </xsl:if>
    <xsl:if test="string-length(primary-key-name) = 0">
      <xsl:value-of select="concat('pk_', $tablename)"/>
    </xsl:if>
	</xsl:variable>
    <!-- MySQL will ignore the constraint name -->
    <xsl:text>ADD CONSTRAINT </xsl:text><xsl:value-of select="$constraintname"/><xsl:text> PRIMARY KEY (</xsl:text>
    <xsl:for-each select="column-def[primary-key='true']">
      <xsl:value-of select="column-name"/>
      <xsl:if test="position() &lt; last()">
        <xsl:text>, </xsl:text>
      </xsl:if>
    </xsl:for-each>
    <xsl:text>);</xsl:text>
    <xsl:value-of select="$newline"/>
  </xsl:if>

  <xsl:for-each select="index-def">
    <xsl:call-template name="create-index">
      <xsl:with-param name="tablename" select="$tablename"/>
    </xsl:call-template>
  </xsl:for-each>

  <xsl:value-of select="$newline"/>
  <xsl:value-of select="$newline"/>

</xsl:template>

<xsl:template name="create-index">
  <xsl:param name="tablename"/>
  <xsl:variable name="pk" select="primary-key"/>
  <xsl:if test="$pk = 'false'">
    <xsl:variable name="unique">
      <xsl:if test="unique='true'">UNIQUE </xsl:if>
    </xsl:variable>
    <xsl:value-of select="$newline"/>
    <xsl:text>CREATE </xsl:text><xsl:value-of select="$unique"/>
    <xsl:text>INDEX </xsl:text><xsl:value-of select="name"/>
    <xsl:text> ON </xsl:text><xsl:value-of select="$tablename"/>
    <xsl:text> (</xsl:text>
    <xsl:for-each select="column-list/column">
        <xsl:value-of select="@name"/>
        <xsl:if test="position() &lt; last()">
          <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:for-each>
    <xsl:text>);</xsl:text>
  </xsl:if>
</xsl:template>

<xsl:template name="process-fk">
  <xsl:for-each select="/schema-report/table-def">
    <xsl:variable name="table" select="table-name"/>
    <xsl:if test="count(foreign-keys) &gt; 0">
      <xsl:for-each select="foreign-keys/foreign-key">
        <xsl:variable name="targetTable" select="references/table-name"/>
        <xsl:value-of select="$newline"/>
        <xsl:text>ALTER TABLE </xsl:text><xsl:value-of select="$table"/>
        <xsl:value-of select="$newline"/>
        <xsl:text> ADD CONSTRAINT </xsl:text><xsl:value-of select="constraint-name"/>
        <xsl:value-of select="$newline"/>
        <xsl:text> FOREIGN KEY (</xsl:text>
        <xsl:for-each select="source-columns/column">
          <xsl:value-of select="."/>
          <xsl:if test="position() &lt; last()">
            <xsl:text>,</xsl:text>
          </xsl:if>
        </xsl:for-each>
        <xsl:text>)</xsl:text>
        <xsl:value-of select="$newline"/>
        <xsl:text> REFERENCES </xsl:text><xsl:value-of select="$targetTable"/><xsl:text> (</xsl:text>
        <xsl:for-each select="referenced-columns/column">
          <xsl:value-of select="."/>
          <xsl:if test="position() &lt; last()">
            <xsl:text>,</xsl:text>
          </xsl:if>
        </xsl:for-each>
        <xsl:text>)</xsl:text>
        <xsl:call-template name="add-fk-action">
          <xsl:with-param name="event-name" select="'ON DELETE'"/>
          <xsl:with-param name="action" select="delete-rule"/>
        </xsl:call-template>
        
        <xsl:text>;</xsl:text>
        <xsl:value-of select="$newline"/>
      </xsl:for-each>
      <xsl:value-of select="$newline"/>
    </xsl:if>
  </xsl:for-each>
</xsl:template>

<xsl:template name="add-fk-action">
  <xsl:param name="event-name"/>
  <xsl:param name="action"/>
  <xsl:if test="$action = 'DELETE' or $action = 'SET NULL'">
    <xsl:value-of select="$newline"/>
    <xsl:text>  </xsl:text>
    <xsl:value-of select="$event-name"/><xsl:text> </xsl:text><xsl:value-of select="$action"/>
  </xsl:if>
</xsl:template>

<xsl:template match="view-def">
  <xsl:variable name="quote"><xsl:text>"</xsl:text></xsl:variable>

  <xsl:value-of select="$newline"/>
  <xsl:text>CREATE OR REPLACE VIEW </xsl:text><xsl:value-of select="view-name"/>
  <xsl:value-of select="$newline"/>
  <xsl:text>(</xsl:text>
  <xsl:value-of select="$newline"/>

  <xsl:for-each select="column-def">
    <xsl:sort select="dbms-position"/>
    <xsl:variable name="orgname" select="column-name"/>
    <xsl:variable name="uppername">
    <xsl:value-of select="translate(column-name,
                                  'abcdefghijklmnopqrstuvwxyz`',
                                  'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
    </xsl:variable>
    <xsl:variable name="colname">
      <xsl:choose>
      <xsl:when test="contains(column-name,' ')">
        <xsl:value-of select="concat($quote,column-name,$quote)"/>
      </xsl:when>
      <xsl:otherwise>
          <xsl:value-of select="$uppername"/>
      </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:text>  </xsl:text><xsl:copy-of select="$colname"/>
    <xsl:if test="position() &lt; last()">
      <xsl:text>,</xsl:text>
    </xsl:if>
    <xsl:value-of select="$newline"/>
  </xsl:for-each>
  <xsl:text>)</xsl:text>
  <xsl:value-of select="$newline"/>
  <xsl:text>AS </xsl:text>
  <xsl:value-of select="$newline"/>
  <xsl:value-of select="view-source"/>
</xsl:template>

</xsl:stylesheet>

