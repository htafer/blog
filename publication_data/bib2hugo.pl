use warnings;
use BibTeX::Parser;
use IO::File;
use Data::Dumper;  
use Getopt::Std;
use File::Map qw(map_file);
use File::Path;



my %opts; 
sub init{ 
 getopts('h:d:b:t:',\%opts) || usage();
 usage() if($opts{h} || !defined($opts{d}) || !defined($opts{b}) || !defined($opts{t}));
}
  
sub usage{
  print STDOUT << "EOF";  
 
This program takes as input a bibtex-file (-b), parses it 
and return for each bibtex bibtexentry an md-formated file compatible 
with the academic theme. Each bibtexentry is saved in a separate directory. 
 
usage: $0 [-hdb]
 
-h: this message
-d: directory where the md-formated entries are saved  
-b: bibtex file to parse 
-t: hugo-academic publication template
 
example:  

perl ./bib2hugo.pl -t bib2hugo.tmp -d ../content/publication/ -b ./works.bib 

EOF

exit;  
}

sub main{
    init();
    my $fh = IO::File->new($opts{b});  
    my $parser = BibTeX::Parser->new($fh);
    # ... and iterate over entries
    # ... TODO check if keys are present twice
    while (my $bibtexentry = $parser->next ) {
	# Check for completeness
	if ($bibtexentry->parse_ok && defined($bibtexentry->{doi}) && defined($bibtexentry->{abstract}) && defined($bibtexentry->{year})) {
	    # Start generating publication entries
	    my $entry = print_bibtex_md($bibtexentry);
	    my $dir = $opts{d}."/".$bibtexentry->{_key};
	    
	    mkpath $dir;
	    open(FH,">$dir/index.md");
	    print FH $entry;
	    close(FH);
		
	} else {
	    print Dumper $bibtexentry;
	    warn "Error parsing file: " . $bibtexentry->error;
	    
	}
    }  
}

sub print_bibtex_md{
    #This function takes as input a parsed bibtexentry
    #A academic-hugo publication template file in markdown format
    #It returns a stringified template with the corresponding field replaced in the template
    #get bibtexentry
    my $bibtexentry = shift;
    #open template file
    open(TEMPLATE, "$opts{t}");
    my @template = <TEMPLATE>;
    close(TEMPLATE);
    my $template = join("",@template);
    # Parse title
    my $title = $bibtexentry->{title};
    $title =~s/\\.//g;
    $title =~s/[\{\}]//g;
    $template=~s/\{\{TITLE\}\}/"$title"/;
    # Parse author
    my $authors="";
    foreach my $entry ($bibtexentry->author){
	$authors.= "\"";
	$authors.= $entry->first;
	$authors.=" ";
	$authors.= $entry->last;
	$authors =~s/\\.//g;	 
	$authors =~s/(\{|\})//g;
	$authors.= "\"";
	$authors.=", ";
    }
    $authors=~s/, $/]/;
    $authors="[".$authors;
    $template=~s/\{\{AUTHORS\}\}/$authors/;
    # Parse year
    my $year = $bibtexentry->{year};
    $year.="-12-31";
    $template=~s/\{\{DATE\}\}/"$year"/;
    # Parse abstract
    my $abstract = $bibtexentry->{abstract};
    $abstract =~s/\\.//g;	 
    $abstract =~s/(\{|\})//g;
    $abstract =~s/"//g;
    $template=~s/\{\{ABSTRACT\}\}/"$abstract"/;
    # Parse doi
    my $doi = $bibtexentry->{doi};
    $template=~s/\{\{DOI\}\}/"$doi"/g;
    return $template;
   
    # Read in template replace the corresponding fields.

    
    
    #map_file(my $string, $opts{t});
    
    
    #$authors=~s/, $/]/;
    #print $authors;
    
    # Now generate file
    
}



main();




#print $bibtexentry->{_key},"\n";
#my $type = $bibtexentry->type;
#my $title= $bibtexentry->field("title");  
# 
#my @authors = $bibtexentry->author; 
# or: 
#my @editors = $bibtexentry->editor; 
 
#foreach my $author (@authors) {  

#  print $author->first . " "  
#  . $author->last . ", "
#} 
