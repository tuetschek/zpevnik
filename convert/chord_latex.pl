#!/usr/bin/perl

# Convert plain text chords into my own LaTeX format.

use strict;
use warnings;

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

#
# constants
#


# chord regexp
my $chord_pattern = qr/([A-H](?:b|#)?\*?(?:[0-9]+|maj[0-9]*|mi?[0-9]*(?:b|add[0-9])?|sus[0-9]*|[0-9]*add[0-9]*|[0-9]*-)?(?:\/[A-H](?:b|#)?)?)/;
my $songpart_pattern = "^(?:\\s*(repeat|[0-9][x.:]?|[0-9](?:st|rd|nd)|main|verse|ending|outro|end|solo(?: on)?|(?:pre-?)?chorus|bridge|coda|intro|riff|ref[.:]?|r[.:]?|refrain|and|fade|=|:))+\\s*\$";

#
# main
#

sub process_file {

    my $file = shift();

    # do we have a chords line saved?
    my $chordline = "";
    # line counter
    my $linectr = 0;
    # inside of a verse indicator
    my $in_verse = 0;
    # remember song title to print out with author
    my $title = '';

    while(<$file>){

        # chop newline
        my $line = $_;
        $line =~ s/\r?\n$//;

        # check for chord line
        if ($chordline eq ""){

            my $test = $line;
            $test =~ s/[,\|.\/\s]+//g;
            if ($test eq ""){ # empty line
                if ($in_verse){
                    print "\\end{guitar}\n";
                    $in_verse = 0;
                }
                print ("\n");
                ++$linectr;
                next;
            }

            $test =~ s/$chord_pattern//g;
            if ($test eq ""){

                $chordline = $line;
                ++$linectr;
                next;
            }

            # not a chord line and we do not have one -> print everything
            # save first two lines for title & sub-title
            if ($linectr == 0){
                $title = $line;
            }
            elsif ($linectr == 1){
                print("\\begin{song}{$title}{$line}\n");
            }
            # check for chorus, verse etc.
            elsif ($line =~ m/$songpart_pattern/i){
                if ($in_verse){
                    print "\\end{guitar}\n";
                    $in_verse = 0;
                }
                print("\\songpart{$line}\n");
            }
            else {
                if ($line !~ /^\s*$/){
                    if (!$in_verse){
                        print "\\begin{guitar}\n";
                        $in_verse = 1;
                    }
                }
                else {
                    if ($in_verse){
                        print "\\end{guitar}\n";
                        $in_verse = 0;
                    }
                }
                print("$line\\\\\n");
            }
        }
        # we've got a chord line saved -> apply it to the current line
        else {

            my $add_len = 0;
            my @chords = ($chordline =~ m/$chord_pattern/g);
            my $chord_ctr = 0;

            if (!$in_verse){
                print "\\begin{guitar}\n";
                $in_verse = 1;
            }

            # chords are followed by an empty line -> just print them out
            if ($line =~ m/^[,\s]*$/){
                print("^ [" . join("] [",@chords) . "]\\\\\n\n");
            }
            # normal, full line for the chords -> insert chords into it
            else {

                my $closing = '';

                while($chordline =~ m/$chord_pattern/g){

                    my $ins_pos = pos($chordline) - length($chords[$chord_ctr]) + $add_len;

                    $add_len += length($closing) + length($chords[$chord_ctr]) + length("[]");

                    if ($ins_pos > length($line)){
                        $line .= $closing."[".$chords[$chord_ctr]."]";
                    }
                    else {
                        $line = substr($line, 0, $ins_pos).$closing."[".$chords[$chord_ctr]."]"
                                .substr($line, $ins_pos);
                    }
                    $closing = '';

                    $chord_ctr++;
                }
                #$line =~ s/ /~/g;
                print("^ $line\\\\\n");
            }

            $chordline = "";
        }

        $linectr++;
    }
    if ($in_verse){
        print "\\end{guitar}\n";
        $in_verse = 0;
    }
    print "\\end{song}\n";
}


if (!@ARGV){
    process_file(\*STDIN);
}
else {
    while(@ARGV){

        if (!open(INPUT, "<:utf8", $ARGV[0])){
            print(STDERR "Could not open $ARGV[0].\n");
            shift(@ARGV);
            next;
        }
        process_file(\*INPUT);
        shift(@ARGV);
    }
}
