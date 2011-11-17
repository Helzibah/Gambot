use strict;
use warnings;
use Benchmark;
use FindBin;
use lib $FindBin::Bin;

use feed_reader;

my $time_start = Benchmark->new();
$| = 1;
binmode STDOUT, ":utf8";

my $db_connection = &connect_to_database();

my $link_regex = qr/\n<id>(.+)<\/id>\n/;
my $author_regex = qr/\n<name>(.+)<\/name>\n/;
my $title_regex = qr/^<title><\/title>\n/;
my $date_regex = qr/\n<published>(.+)<\/published>\n/;
my $data_site = 'Frogatto';

my @feed_array;

push(@feed_array, '1'); #General Discussion
push(@feed_array, '3'); #Frogatto Mods
push(@feed_array, '2'); #Technical Support

push(@feed_array, '4'); #General/Planning/Art
push(@feed_array, '8'); #Bugs and Feature Requests
push(@feed_array, '10'); #Tools, Tutorials, Modding Questions
push(@feed_array, '7'); #Audio
push(@feed_array, '6'); #Translations

push(@feed_array, '5'); #Off-Topic

print "log>FEEDREAD>$data_site feeds beginning\n";

foreach my $current_feed (@feed_array) {
  my @subscribers_array = get_subscribers($db_connection, $data_site, $current_feed);
  my $current_feed_url = "http://www.frogatto.com/forum/index.php?action=.xml&board=$current_feed".".0&type=atom";
  my @entries_array = &url_to_entries($current_feed_url,'<entry>','</entry>');

  foreach my $i (1..scalar(@entries_array)) {
    my $current_entry = $entries_array[-$i];

    my ($data_link, $data_author, $data_title, $data_date_full) = entry_to_data($current_entry,$link_regex,$author_regex,$title_regex,$date_regex);
    #2011-06-07T05:09:07Z
    $data_date_full =~ m/^([0-9]+)-([0-9]+)-([0-9]+)T([0-9]+):([0-9]+):([0-9]+)Z$/i;
    my $data_date = "$2-$3-$1";
    my $data_time = "$4:$5";

    unless(&check_existence($db_connection, $current_feed, $data_link)) {
      &commit_entry($db_connection, $data_site, $current_feed, $data_link, $data_title, $data_author, $data_date, $data_time);
      #print "send_server_message>PRIVMSG ##Gambot-forum :\x02Frogatto Forums\x02 | \x02$data_title\x02 by \x0303$data_author\x0F [ \x0314$data_date $data_time\x0F ] [ $data_link ]\n";
      foreach my $current_subscriber (@subscribers_array) {
	print "send_server_message>PRIVMSG $current_subscriber :\x02Frogatto Forums\x02 | \x02$data_title\x02 by \x0303$data_author\x0F [ \x0314$data_date $data_time\x0F ] [ $data_link ]\n";
      }
    }
  }
}

$db_connection->disconnect();
my $time_end = Benchmark->new();
my $time_difference = timestr(timediff($time_end,$time_start));
print "log>FEEDREAD>$data_site finished. $time_difference\n";