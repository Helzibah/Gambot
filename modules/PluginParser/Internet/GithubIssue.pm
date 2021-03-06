package PluginParser::Internet::GithubIssue;
use strict;
use warnings;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(match);

sub match {
  my ($self,$core) = @_;
  if($core->{'receiver_nick'} ne $core->{'botname'}) { return ''; }
  if($core->{'event'} ne 'on_public_message' and $core->{'event'} ne 'on_private_message') { return ''; }


  if($core->{'message'} =~ /^issue (.+)$/) {
    return issue($core,$core->{'receiver_chan'},$core->{'target'},$1);
  }

  return '';
}

sub issue {
  use FindBin;
  use lib "$FindBin::Bin/../../modules/";
  require POSIX;
  require LWP::UserAgent;
  require JSON::JSON;
  my ($core,$chan,$target,$description) = @_;

  my $botname = $core->{'botname'};
  my $sender = $core->{'sender_nick'};
  my $incoming_message = $core->{'incoming_message'};
  my $key = $core->value_get('config','github_key');
  my $url = "https://api.github.com/repos/Grickit/gambot/issues?access_token=${key}";
  my $title = substr($description,0,30);

  my %struct;

  $struct{'title'} = "[From IRC] ${title}";
  $struct{'body'} = "[Generated by ${botname} at request of ${sender}]\n\n[${incoming_message}]\n\n${description}";

  my $json = JSON::encode_json(\%struct);
  $core->log_error($json);

  my $requester = LWP::UserAgent->new;
  my $request = HTTP::Request->new(POST => $url);
  $request->content_type('application/x-www-form-urlencoded');
  $request->content($json);

  my $result = $requester->request($request);
  $core->log_error($result->as_string);
}
