package bigip;
##
## $Id: bigip.pm.in 3350 2016-04-04 01:58:23Z heas $
##
## rancid 3.5.1
##
#  RANCID - Really Awesome New Cisco confIg Differ
#
#  bigip.pm - F5 BIG-IP >= v15 rancid procedures

use 5.010;
use strict 'vars';
use warnings;
no warnings 'uninitialized';
require(Exporter);
our @ISA = qw(Exporter);

use rancid 3.5.1;

@ISA = qw(Exporter rancid main);
#XXX @Exporter::EXPORT = qw($VERSION @commandtable %commands @commands);

# load-time initialization
sub import {
    # force a terminal type so as not to confuse the POS
    $ENV{'TERM'} = "vt100";

    0;
}

# post-open(collection file) initialization
sub init {
    # add content lines and separators
    ProcessHistory("","","","!RANCID-CONTENT-TYPE: $devtype\n!\n");
    ProcessHistory("COMMENTS","keysort","A1","#\n");
    ProcessHistory("COMMENTS","keysort","B0","#\n");
    ProcessHistory("COMMENTS","keysort","C0","#\n");

    0;
}

# main loop of input of device output
sub inloop {
    my($INPUT, $OUTPUT) = @_;
    my($cmd, $rval);

TOP: while(<$INPUT>) {
        tr/\015//d;
        if (/^Error:/) {
            print STDOUT ("$host clogin error: $_");
            print STDERR ("$host clogin error: $_") if ($debug);
            $clean_run=0;
            last;
        }
        while (/#\s*($cmds_regexp)\s*$/) {
            $cmd = $1;
            if (!defined($prompt)) {
                $prompt = ($_ =~ /^([^#]+#)/)[0];
                $prompt =~ s/([][}{)(\\])/\\$1/g;
                print STDERR ("PROMPT MATCH: $prompt\n") if ($debug);
            }
            print STDERR ("HIT COMMAND:$_") if ($debug);
            if (! defined($commands{$cmd})) {
                print STDERR "$host: found unexpected command - \"$cmd\"\n";
                $clean_run = 0;
                last TOP;
            }
            $rval = &{$commands{$cmd}}($INPUT, $OUTPUT, $cmd);
            delete($commands{$cmd});
            if ($rval == -1) {
                $clean_run = 0;
                last TOP;
            }
        }
        if (/\#\s?quit$/) {
            $clean_run=1;
            last;
        }
    }
}

# This routine parses "tmsh show /sys version"
sub ShowVersion {
    my($INPUT, $OUTPUT, $cmd) = @_;
    print STDERR "    In ShowVersion: $_" if ($debug);

    while (<$INPUT>) {
        tr/\015//d;
        last if (/^$prompt/);
        next if (/^(\s*|\s*$cmd\s*)$/);
        return(-1) if (/command authorization failed/i);

        /^kernel:/i && ($_ = <$INPUT>) &&
            ProcessHistory("COMMENTS","keysort","A3","#Image: Kernel: $_") &&
            next;
        if (/^package:/i) {
            my($line);

            while ($_ = <$INPUT>) {
                tr/\015//d;
                last if (/:/);
                last if (/^$prompt/);
                chomp;
                $line .= " $_";
            }
            ProcessHistory("COMMENTS","keysort","A2",
                           "#Image: Package:$line\n");
        }

        if (/:/) {
            ProcessHistory("COMMENTS","keysort","C1","$_");
        } else {
            ProcessHistory("COMMENTS","keysort","C1","\t$_");
        }
    }
    return(0);
}

# This routine parses "tmsh show /sys hardware"
sub ShowHardware {
    my($INPUT, $OUTPUT, $cmd) = @_;
    print STDERR "    In ShowHardware: $_" if ($debug);

    while (<$INPUT>) {
        tr/\015//d;
        last if (/^$prompt/);
        next if (/^(\s*|\s*$cmd\s*)$/);
        return(1) if /^\s*\^\s*$/;
        return(1) if /(Invalid input detected|Type help or )/;
        return(-1) if (/command authorization failed/i);

        s/\d+rpm//ig;
        s/^\|//;
        s/^\ \ ([0-9]+)(\ +).*up.*[0-9]/  $1$2up REMOVED/i;
        s/^\ \ ([0-9]+)(\ +).*Air\ Inlet/  $1$2REMOVED Air Inlet/i;
        s/^\ \ ([0-9]+)(\ +).*HSBe/  $1$2REMOVED HSBe/i;
        s/^\ \ ([0-9]+)(\ +).*TMP421 on die/  $1$2REMOVED TMP421 on die/i;
        s/^\ \ ([0-9]+)(\ +)[0-9]+\ +[0-9]+/  $1$2REMOVED     REMOVED/;
        /Type: / && ProcessHistory("COMMENTS","keysort","A0",
                                   "#Chassis type: $'");

        ProcessHistory("COMMENTS","keysort","B1","$_") && next;
    }
    return(0);
}

# This routine parses "tmsh show /sys license"
sub ShowLicense {
    my($INPUT, $OUTPUT, $cmd) = @_;
    my($line) = (0);
    print STDERR "    In ShowLicense: $_" if ($debug);

    while (<$INPUT>) {
        tr/\015//d;
        # v9 software license does not have CR at EOF
        s/^#-+($prompt.*)/$1/;
        last if (/^$prompt/);
        next if (/^(\s*|\s*$cmd\s*)$/);
        return(1) if /^\s*\^\s*$/;
        return(1) if /(Invalid input detected|Type help or )/;
        return(-1) if (/command authorization failed/i);

        if (!$line++) {
            ProcessHistory("LICENSE","","","#\n#show /sys licence:\n");
        }
        ProcessHistory("LICENSE","","","$_") && next;
    }
    return(0);
}

# This routine parses "tmsh show /net route static"
sub ShowRouteStatic {
    my($INPUT, $OUTPUT, $cmd) = @_;
    print STDERR "    In ShowRouteStatic: $_" if ($debug);

    while (<$INPUT>) {
        tr/\015//d;
        last if (/^$prompt/);
        next if (/^(\s*|\s*$cmd\s*)$/);
        return(1) if /^\s*\^\s*$/;
        return(1) if /(Invalid input detected|Type help or )/;
        return(-1) if (/command authorization failed/i);

  $found_end++;

        ProcessHistory("ROUTE","","","$_") && next;
    }
    return(0);
}

# This routine parses "show running-config Cm"
sub ShowRunCm {
    my($INPUT, $OUTPUT, $cmd) = @_;
    my($line) = (0);
    print STDERR "    In ShowRunCm: $_" if ($debug);

    while (<$INPUT>) {
        tr/\015//d;
        last if (/^$prompt/);
        next if (/^(\s*|\s*$cmd\s*)$/);
        return(1) if /^\s*\^\s*$/;
        return(1) if /(Invalid input detected|Type help or )/;
        return(-1) if (/command authorization failed/i);

        if (!$line++) {
            ProcessHistory("RUNCm","","","#\n#/show running-config Cm:\n");
        }
        ProcessHistory("RUNCm","","","$_") && next;
    }
    return(0);
}


# This routine parses "show running-config Net"
sub ShowRunNet {
    my($INPUT, $OUTPUT, $cmd) = @_;
    my($line) = (0);
    print STDERR "    In ShowRunNet: $_" if ($debug);

    while (<$INPUT>) {
        tr/\015//d;
        last if (/^$prompt/);
        next if (/^(\s*|\s*$cmd\s*)$/);
        return(1) if /^\s*\^\s*$/;
        return(1) if /(Invalid input detected|Type help or )/;
        return(-1) if (/command authorization failed/i);

        if (!$line++) {
            ProcessHistory("RUNNet","","","#\n#show running-config Net:\n");
        }
        ProcessHistory("RUNNet","","","$_") && next;
    }
    return(0);
}


# This routine parses "show running-config Ltm"
sub ShowRunLtm {
    my($INPUT, $OUTPUT, $cmd) = @_;
    my($line) = (0);
    print STDERR "    In ShowRunLtm: $_" if ($debug);

    while (<$INPUT>) {
        tr/\015//d;
        last if (/^$prompt/);
        next if (/^(\s*|\s*$cmd\s*)$/);
        return(1) if /^\s*\^\s*$/;
        return(1) if /(Invalid input detected|Type help or )/;
        return(-1) if (/command authorization failed/i);

        if (!$line++) {
            ProcessHistory("RUNLtm","","","#\n#show running-config Ltm:\n");
        }
        ProcessHistory("RUNLtm","","","$_") && next;
    }
    return(0);
}

# This routine parses "lsof -n -i :179"
sub ShowZebOSsockets {
    my($INPUT, $OUTPUT, $cmd) = @_;
    my($line) = (0);
    print STDERR "    In ShowZebOSsockets: $_" if ($debug);

    while (<$INPUT>) {
        tr/\015//d;
        last if (/^$prompt/);
        next if (/^(\s*|\s*$cmd\s*)$/);
        return(1) if /^\s*\^\s*$/;
        return(1) if /(Invalid input detected|Type help or )/;
        return(-1) if (/command authorization failed/i);

        if (!$line++) {
            ProcessHistory("ZEBOSSOCKETS","","","#\n#lsof -n -i :179:\n");
        }
        ProcessHistory("ZEBOSSOCKETS","","","# $_") && next;
    }
    return(0);
}

# This routine processes a "tmsh -q list"
sub WriteTerm {
    my($INPUT, $OUTPUT, $cmd) = @_;
    my($lines) = 0;
    print STDERR "    In WriteTerm: $_" if ($debug);

    while (<$INPUT>) {
        tr/\015//d;
        next if (/^\s*$/);

        # Ignore monitor down state, save the config as up.
        s/state down$/state up/i;

        # end of config - hopefully.  f5 does not have a reliable end-of-config
        # tag.
        if (/^$prompt/) {
            $found_end++;
            last;
        }
        return(-1) if (/command authorization failed/i);

        $lines++;

        if (/(bind-pw|encrypted-password|user-password-encrypted|passphrase) / && $filter_pwds >= 1) {
            ProcessHistory("ENABLE","","","# $1 <removed>\n");
            next;
        }

        # catch anything that wasnt matched above.
        ProcessHistory("","","","$_");
    }

    return(0);
}

1;
