use strict;
use CXGN::Page;
use CXGN::Page::Toolbar::SGN;
my $page=CXGN::Page->new("Tools","Andrew");
$page->header();


print qq{ 
<body id="body">
<table width="800px" cellpadding="10px">
	<table width="100%">
		<tr><td>
		<a href="/CytoScape/cy1.jnlp">Start Cytoscape</a>
		</td></tr>
	</table>
	<table width="100%">
		<tr><td>
		<div id="footer">
		<b>Funding for Cytoscape is provided by a federal grant from the U.S.
		<a href="http://www.nigms.nih.gov">National Institute of General Medical Sciences (NIGMS)</a> of the
		<a href="http://www.nih.gov">National Institutes of Health (NIH)</a> under award number GM070743-01 and
		the U.S. <a href="http://www.nsf.gov">National Science Foundation (NSF) </a>.
		Corporate funding is provided through a contract from
		<a href="http://www.unilever.com">Unilever PLC</a>.
		</b>
		<p>
		<center>
		<a href="http://cytoscape.org">Cytoscape home</a>
		|
		<a href="http://www.systemsbiology.org">ISB</a>
		|
		<a href="http://www.ucsd.edu">UCSD</a>
		|
		<a href="http://cbio.mskcc.org">MSKCC</a>
		|
		<a href="http://www.pasteur.fr">Pasteur</a>
		|
		<a href="http://www.agilent.com/">Agilent</a>
		| &copy; 2001-2006 Cytoscape
		</center>
		</div>

		</td></tr>
	</table>

	</td></tr>
</table>
</body>};

$page->footer();
