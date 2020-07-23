package gaia;
##
## $Id: gaia.pm.in 3226 2016-01-15 21:41:54Z heas $
## Loosely base on dell.pm
#
use 5.010;
use strict 'vars';
use warnings;
no warnings 'uninitialized';
require(Exporter);
our @ISA = qw(Exporter);

use rancid 3.5.1;

our $proc;
our $found_version;

@ISA = qw(Exporter rancid main);
#XXX @Exporter::EXPORT = qw($VERSION @commandtable %commands @commands);

# load-time initialization
sub import {
    $timeo = 300;               # dllogin timeout in seconds (some of these
                                # devices are remarkably slow to read config)

    0;
}

# post-open(collection file) initialization
sub init {
    $proc = "";
    $found_version = 0;

    # add content lines and separators
    ProcessHistory("","","","#RANCID-CONTENT-TYPE: Gaia\n\n");

    0;
}

# main loop of input of device output
sub inloop {
    my($INPUT, $OUTPUT) = @_;
    my($cmd, $rval);

TOP: while(<$INPUT>) {
        tr/\015//d;
        # XXX this match is not correct for DELL
print STDERR $_;
        if (/>\s?exit$/) {
            $clean_run = 1;
      print STDERR ("$host : end of run found") if ($debug);
            last;
        }
        if (/^Error:/) {
            print STDOUT ("$host login error: $_");
            print STDERR ("$host login error: $_") if ($debug);
            $clean_run = 0;
            last;
        }
        while (/^.+(>|\$)\s*($cmds_regexp)\s*$/) {
            $cmd = $2;
            # - gaia clish prompts end with '>'.
            if ($_ =~ m/^.+>/) {
                $prompt = '.+>.*';
            }
            print STDERR ("HIT COMMAND:$_") if ($debug);
            if (! defined($commands{$cmd})) {
                print STDERR "$host: found unexpected command - \"$cmd\"\n";
                $clean_run = 0;
                last TOP;
            }
            if (! defined(&{$commands{$cmd}})) {
                printf(STDERR "$host: undefined function - \"%s\"\n",
                       $commands{$cmd});
                $clean_run = 0;
                last TOP;
            }
            $rval = &{$commands{$cmd}}($INPUT, $OUTPUT, $cmd);
            delete($commands{$cmd});

      if ($rval == 1) { $clean_run =1;}

            if ($rval == -1) {
                $clean_run = 0;
                last TOP;
            }
        }
    }
}

# This routine parses "show configuration"
sub GetConf {
  my($INPUT, $OUTPUT, $cmd) = @_;
  print STDERR "    In GetConf: $_" if ($debug);

  ProcessHistory("","","","\n");
  ProcessHistory("","","","\n");

  while (<$INPUT>) {
        tr/\015//d;
          next if /^\s*$/;
          last if (/$prompt/);

    if (/^(.+password-hash) \S+/ && $filter_pwds >= 1) {
      $_ = "$1 <removed>\n";
    }

    if (/^(.+Exported by rancid on) \S+/ && $filter_pwds >= 1) {
      $_ = "$1 <date removed>\n";
    }

        ProcessHistory("","","","$_");
  }

  $found_end = 1;
  print STDERR "    Out GetConf: $_" if ($debug);

  return(1);
}


# This routine parses "fw ctl affinity"
sub GetAffinity {
  my($INPUT, $OUTPUT, $cmd) = @_;
  print STDERR "    In GetAffinity: $_" if ($debug);

  ProcessHistory("","","","\n");
  ProcessHistory("","","","\n");

  while (<$INPUT>) {
        tr/\015//d;
          next if /^\s*$/;
          last if (/$prompt/);

        ProcessHistory("","","","$_");
  }

  $found_end = 1;
  print STDERR "    Out GetAffinity: $_" if ($debug);

  return(1);
}



# This routine parses "show installer packages"
sub GetPackages {
  my($INPUT, $OUTPUT, $cmd) = @_;
  print STDERR "    In GetPackages: $_" if ($debug);

  ProcessHistory("","","","Installer packages status\n");
  while (<$INPUT>) {
        tr/\015//d;
          next if /^\s*$/;
          last if (/$prompt/);

          ProcessHistory("","","","$_");
  }

  $found_end = 1;
  print STDERR "    Out GetPackages: $_" if ($debug);

  return(1);
}

# This routine parses anything standard
sub DefaultParsing {
  my($INPUT, $OUTPUT, $cmd) = @_;
  print STDERR "    In DefaultParsing: $_" if ($debug);

  ProcessHistory("","","","\n");
  while (<$INPUT>) {
        tr/\015//d;
          next if /^\s*$/;
          last if (/$prompt/);

          ProcessHistory("","","","$_");
  }

  $found_end = 1;
  print STDERR "    Out DefaultParsing: $_" if ($debug);

  return(1);
}



1;

