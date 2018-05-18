use HTML::WikiConverter;

opendir(DIR,'.');
while(readdir DIR){
next if /\.pl/;
trans($_);
}
closedir(DIR);

sub trans {

my $name=shift;
my $out=$name.".md";
open my $OUT,'>',$out;

my $html;
{
  local $/;
  open my $IN, '<', $name or die "can't open $file: $!";
  $html = <$IN>;
 }

my $wc = new HTML::WikiConverter( dialect => 'Markdown' );
my $content=$wc->html2wiki( $html );

print $OUT $content;
close $OUT;

}
