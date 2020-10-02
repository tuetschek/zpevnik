#!/usr/bin/perl

# Convert plain text chords (above text) into the chordpro format.

use strict;
use warnings;

#
# constants
#


# chord regexp
my $chord_pattern = "([A-H](?:b|#)?\\*?(?:[0-9]+|maj[0-9]*|mi[0-9]*|m[0-9]*|sus[0-9]*|[0-9]*add[0-9]*|\/[A-H](?:b|#)?|[0-9]*-)?)";
my $songpart_pattern = "^\\s*(repeat |[0-9]x\\s*)?([0-9]\\.?|([0-9]\\.\\s*)?verse|ending|outro|end|solo|chorus|bridge|coda|intro|riff|ref\\.?|r\\.?|refrain)( and fade)?(\\s+=\\s+[0-9]\\.?)?\\s*[0-9]?\\.?:?\\s*\$";

#
# main
#

sub process_file {

	my $file = shift();

	# do we have a chords line saved?
	my $chordline = "";
	# line counter
	my $linectr = 0;

	while(<$file>){

		# chop newline
		my $line = $_;
		$line =~ s/\r?\n$//;

		# check for chord line
		if ($chordline eq ""){

			my $test = $line;
			$test =~ s/[,\|.\s]+//g;
			if ($test eq ""){ # empty line

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
				print("{t:$line}\n");
			}
			elsif ($linectr == 1){
				print("{st:$line}\n");
			}
			# check for chorus, verse etc.
			elsif ($line =~ m/$songpart_pattern/i){
				print("{c:$line}\n");
			}
			else {
				print("$line\n");
			}
		}
		# we've got a chord line saved -> apply it to the current line
		else {

			my $add_len = 0;
			my @chords = ($chordline =~ m/$chord_pattern/g);
			my $chord_ctr = 0;

			# chords are followed by an empty line -> just print them out
			if ($line =~ m/^[,\s]*$/){
				print("[".join("][",@chords)."]\n\n");
			}
			# normal, full line for the chords -> insert chords into it
			else {

				while($chordline =~ m/$chord_pattern/g){

					my $ins_pos = pos($chordline) - length($chords[$chord_ctr]) + $add_len;

					if ($ins_pos > length($line)){
						$line .= "[$chords[$chord_ctr]]";
					}
					else {
						$line = substr($line, 0, $ins_pos)."[".$chords[$chord_ctr]."]"
								.substr($line, $ins_pos);
					}

					$add_len += length($chords[$chord_ctr]) + 2;
					$chord_ctr++;
				}
				print("$line\n");
			}

			$chordline = "";
		}

		$linectr++;
	}
}


if (!@ARGV){
	process_file(\*STDIN);
}
else {
	while(@ARGV){

		if (!open(INPUT, $ARGV[0])){
			print(STDERR "Could not open $ARGV[0].\n");
			shift(@ARGV);
			next;
		}
		process_file(\*INPUT);
		shift(@ARGV);
	}
}
