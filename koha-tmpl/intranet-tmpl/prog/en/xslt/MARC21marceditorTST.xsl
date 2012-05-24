<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html"/>

    <xsl:template match="/">
        <html>
            <xsl:apply-templates/>
        </html>
    </xsl:template>

    <xsl:template match="marc:record">
        <table>
            <tr>
                <th NOWRAP="TRUE" ALIGN="RIGHT" VALIGN="TOP">
                000
                </th>
                <td>
                    <input type="text">
                    <xsl:attribute name="id">
                        <xsl:value-of select="000"/>
                    </xsl:attribute>
                        <xsl:attribute name="value">
                            <xsl:value-of select="marc:leader"/>
                        </xsl:attribute>
                    </input>
                </td>
            </tr>
            <xsl:apply-templates select="marc:datafield|marc:controlfield"/>
        </table>
    </xsl:template>

    <xsl:template match="marc:controlfield">
        <tr>
            <th NOWRAP="TRUE" ALIGN="RIGHT" VALIGN="TOP">
                <xsl:value-of select="@tag"/>
            </th>
            <td>
                <input type="text">
                    <xsl:attribute name="id">
                        <xsl:value-of select="@tag"/>
                    </xsl:attribute>
                    <xsl:attribute name="value">
                        <xsl:value-of select="."/>
                    </xsl:attribute>
                </input>

            </td>
        </tr>
    </xsl:template>

    <xsl:template match="marc:datafield">
        <tr>
            <th NOWRAP="TRUE" ALIGN="RIGHT" VALIGN="TOP">
                <xsl:value-of select="@tag"/>
            </th>
            <td>
                <xsl:value-of select="@ind1"/>
                <xsl:value-of select="@ind2"/>
                <xsl:apply-templates select="marc:subfield"/>
            </td>
        </tr>
    </xsl:template>

    <xsl:template match="marc:subfield">
        <strong>|<xsl:value-of select="@code"/></strong> <xsl:value-of select="."/>
    </xsl:template>
</xsl:stylesheet>
