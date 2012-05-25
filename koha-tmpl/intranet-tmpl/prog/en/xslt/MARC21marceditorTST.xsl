<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html"/>

    <xsl:template match="/">
        <html>
            <script type="text/javascript">
            //<![CDATA[
            $(function() {
                $("#addbibliotabs ul").tabs();
            });
            //]]>
            </script>

            <xsl:apply-templates/>
        </html>
    </xsl:template>

    <xsl:template match="marc:record">
    <div id="addbibliotabs" class="toptabs numbered">
        <ul>
            <li><a href="#0">0</a></li>
            <li><a href="#1">1</a></li>
            <li><a href="#2">2</a></li>
            <li><a href="#3">3</a></li>
            <li><a href="#4">4</a></li>
            <li><a href="#5">5</a></li>
            <li><a href="#6">6</a></li>
            <li><a href="#7">7</a></li>
            <li><a href="#8">8</a></li>
            <li><a href="#9">9</a></li>
        </ul>
        <div id="0">
            <table>
                <tr>
                    <th>
                        000
                    </th>
                    <td>
                        <input type="text">
                            <xsl:attribute name="id">
                                <xsl:value-of select='format-number(000, "000")'/>
                            </xsl:attribute>
                            <xsl:attribute name="value">
                                <xsl:value-of select="marc:leader"/>
                            </xsl:attribute>
                        </input>
                    </td>
                </tr>
                <xsl:apply-templates select="marc:controlfield"/>
                <xsl:apply-templates select="marc:datafield[@tag &lt; 99]"/>
            </table>
        </div>
        <div id="1">
            <table>
                <xsl:apply-templates select="marc:datafield[@tag &gt; 99 and @tag &lt; 199]"/>
            </table>
        </div>
        <div id="2">
            <table>
                <xsl:apply-templates select="marc:datafield[@tag &gt; 199 and @tag &lt; 299]"/>
            </table>
        </div>
        <div id="3">
            <table>
                <xsl:apply-templates select="marc:datafield[@tag &gt; 299 and @tag &lt; 399]"/>
            </table>
        </div>
        <div id="4">
            <table>
                <xsl:apply-templates select="marc:datafield[@tag &gt; 399 and @tag &lt; 499]"/>
            </table>
        </div>
        <div id="5">
            <table>
                <xsl:apply-templates select="marc:datafield[@tag &gt; 499 and @tag &lt; 599]"/>
            </table>
        </div>
        <div id="6">
            <table>
                <xsl:apply-templates select="marc:datafield[@tag &gt; 599 and @tag &lt; 699]"/>
            </table>
        </div>
        <div id="7">
            <table>
                <xsl:apply-templates select="marc:datafield[@tag &gt; 699 and @tag &lt; 799]"/>
            </table>
        </div>
        <div id="8">
            <table>
                <xsl:apply-templates select="marc:datafield[@tag &gt; 799 and @tag &lt; 899]"/>
            </table>
        </div>
        <div id="9">
            <table>
                <xsl:apply-templates select="marc:datafield[@tag &gt; 699 and @tag &lt; 999]"/>
            </table>
        </div>
    </div>
    </xsl:template>

    <xsl:template match="marc:controlfield">
        <tr>
            <th>
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
            <th>
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
