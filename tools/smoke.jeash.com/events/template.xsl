<?xml version="1.0"?>
<xsl:stylesheet 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xi="http://www.w3.org/2001/XInclude"
version="1.0">
<xsl:output method="html" indent="yes" doctype-public="" />

<xsl:param name="jsfile" />
<xsl:strip-space elements="*" />

<xsl:template match="/">
<html>
	<head>
		<title><xsl:value-of select="/root/title" /></title>
	</head>
	<body>
		<div id="haxe:jeash"></div>
		<div id="haxe:trace" style="position:absolute; bottom:0px; right:0px; height:80%; overflow:scroll"></div>
		<script><xsl:attribute name="src"><xsl:value-of select="$jsfile" /></xsl:attribute></script>
	</body>
</html>
</xsl:template>
</xsl:stylesheet>

