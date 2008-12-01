package Acme::Tpyo;

# See the notes after __END__ for [1] these

use 5.008003;
use strict;
use warnings;
use utf8;
use Data::Dumper;
use POSIX;

our $VERSION = '0.1';


# Preloaded methods go here.

# If you list them in the order unmodified, shift, altgr, then
# a character that can be in more than one place on the keyboard
# will be taken from the most likely one - it is less likely that
# you're using altgr than shift if a char is on shift
my %keysets = (
US_QWERTY => 
	{ 
	 	unmodified => 
		[
			q[`1234567890-=\\], #`
			q[qwertyuiop[]],
			q[asdfghjkl;'], #'#these comments are to fix syntax highlighting in cream
			q[zxcvbnm,./],
		],
		shift =>
		[
			q[~!@#$%^&*()_+|],
			q[QWERTYUIOP{}],
			q[ASDFGHJKL:"],#"
			q[ZXCVBNM<>?],
		],
		altgr =>
		[
			#halp
		],
		_offsets =>
		[
			0, 1.5, 1.75, 1.25
		],
		_allow_table_jump => [
			[ qw( unmodified shift ) ],
			[ qw( shift unmodified ) ],
		],
	},
GB_QWERTY =>
	{ 
	 	unmodified => 
		[
			q[`1234567890-=], #`
			q[qwertyuiop[]],
			q[asdfghjkl;'#], #'
			q[\zxcvbnm,./],
		],
		shift =>
		[
			q[¬!"£$%^&*()_+], #"
			q[QWERTYUIOP{}],
			q[ASDFGHJKL:@~],
			q[|ZXCVBNM<>?],
		],
		altgr =>
		[
			q[|¹²³€½¾{[]}\\],
			q[@łe¶ŧ←↓→øþ],
			q[æßðđŋħjĸł],
			q[|«»¢“”nµ ·]
		],
		altgrshift =>
		[
			q[|¡⅛£¼⅜⅝⅞™±°¿],
			q[ WE®Ŧ¥↑ıØÞ],
			q[Æ§ÐªŊĦJ&Ł],
			q[¦<>©‘’Nº×÷],
		],
		_modifier_priority => [
			qw/ unmodified shift altgr altgrshift /
		],
		_offsets =>
		[
			0, 1.5, 1.75, 1.25
		],
		_allow_table_jump => [
				[ qw( unmodified shift ) ],
				[ qw( shift unmodified ) ],
				[ qw( altgr unmodified ) ],
				[ qw( altgrshift shift ) ],
				[ qw( altgrshift altgr ) ],
		],
	},
);

my $DEAFULT_KEYSTE = "US_QWERTY";
my $DEFAUTL_TPYIST = {
	modifier_discipline => 0.9995,
	spacebar_discipline => 0.9995,
	finger_fatness      => 0.25,
	miscoordination     => 0.05,
	disorder            => 0.007,
	weakness            => 0.0001,
	complete_failure    => 0,
	caffeine            => 0.003,
	drunkenness         => 0,
};

# Returns INDICES in rows, not coordinates on keyboard!
sub get_coords {
	my $char = shift;
	my $kesyet = shift; # hashref!
	
	# TODO: Allow spaces in the keyset.
	# Allow a space, but don't give a location.
  return ('unmodified', -1, -1) if $char eq ' ';
	
	my ($modifier, $ky, $kx) = ("", -1, -1);

	if (length($char) != 1)
	{
		die "bah i fucked up: $char";
	}
	
	my @modifiers = defined $kesyet->{_modifier_priority} ? @{$kesyet->{_modifier_priority}} : grep(!/^_/, keys %$kesyet);
	# Check each accelerator mapping and stop if we find it.
	# NOTE we return in this loop! This is naughty but easy.
	for my $acc (@modifiers)
	{ 
		my $kyy = 0;
		for my $kb_row (@{$kesyet->{$acc}})
		{
			if ($kb_row =~ /\Q$char/ )
			{
				$modifier = $acc;
				$ky = $kyy;
				$kx = index($kb_row,$char);
				#DEBUG
				# print "  $char is at $acc, $ky, $kb_row, $kx\n";
				return ($modifier, $kx, $ky);
			}
			$kyy++;
		}
	}

	# Didn't find the letter.
	return;
}

sub get_candidates {
	# $key_x is the index of x, not the absolute position.
	# Consider the offsets incidental.
	my ($kesyet, $modifier, $key_x, $key_y) = @_;

	# special case yanno?
	return (" " => 1) if ($key_x == -1 or $key_y == -1);

	my %candidates;
	my $num_rows = 0;

	for ( (-1, 1) ) {
		# This algorithm only made sense to me after I'd drawn it on
		# a whiteboard and glared at it for half an hour trying to work
		# it out. It hurt a bit and you're not allowed to make fun of me.
	
		# $x and $y are the relative offsets between these two rows.
		my $y = $key_y + $_;
		next if $y < 0; # prevent wrapping with a -1 index
		next if $y > $#{$kesyet->{_offsets}}; # prevent going down too far.

		my $candidate_row = $kesyet->{$modifier}[$y];

		my $x = $kesyet->{_offsets}[$key_y] - $kesyet->{_offsets}[$y];

		my $leftmost_x = floor ($x) + $key_x; #The index of the leftmost overlapping key

		my $left_overlap  = abs ($x - floor abs $x); # by how much it overlaps
		my $right_overlap = 1 - abs $left_overlap; # all keys are 1 wide

		my $left_char  = get_char($kesyet, $modifier, $leftmost_x, $y);
		my $right_char = get_char($kesyet, $modifier, $leftmost_x + 1, $y);

		# DEBUG:
		# print "Offsets: $x; Key x: $key_x; left: $leftmost_x; left overlap: $left_overlap; right overlap: $right_overlap\n";

		@candidates{$left_char, $right_char} = ($left_overlap, $right_overlap);
		++$num_rows;
	}

	# the two keys on this row are as likely as each other;
	# or the one key is the only candidate.
	if ($key_x == 0) {
		$candidates{ get_char($kesyet, $modifier, $key_x + 1, $key_y) } = 1;
	}
	elsif ($key_x == length ($kesyet->{$modifier}[$key_y]) - 1) {
		$candidates{ get_char($kesyet, $modifier, $key_x - 1, $key_y) } = 1;
	}
	else {
		@candidates{
			get_char($kesyet, $modifier, $key_x-1, $key_y),
			get_char($kesyet, $modifier, $key_x+1, $key_y) } = (0.5, 0.5);
		;
	}
	++$num_rows;

	# normalise them. 
	# Each row's $_->[1]s add up to 1, so the total is scalar @candidates.
	$candidates{$_} /= $num_rows foreach keys %candidates;

	return %candidates;
}

sub get_char {
	my ($kesyet, $modifier, $kx, $ky) = @_;
	
	return " " if ($kx == -1 || $ky == -1);
	my $r = substr $kesyet->{$modifier}[$ky], $kx, 1;
	# DEBUG
	# print "$modifier [$kx $ky] = $r\n";

	return $r;
}

# TODO: make this maths better.
# Increase all the failure rates for the typist by the drunkenness level.
sub drunkify {
	my $tpyist = shift;

	for (qw(miscoordination weakness finger_fatness caffeine disorder complete_failure)) {
		$tpyist->{$_} *= (1 + $tpyist->{drunkenness});
	}
	# success rates go *down*
	for (qw(modifier_discipline spacebar_discipline)) {
		$tpyist->{$_} *= (1 - $tpyist->{drunkenness});
	}
}

sub get_completely_random_letter {
	my $kesyet = shift;
  my $modifier = shift;

	my $all_letters = join "", @{$kesyet->{$modifier}};

	return substr $all_letters, rand length $all_letters, 1;
}

sub misspell {
	my $self = shift;
	my ($stirng, $kesyet, $tpyist);

	$stirng = shift;
	$kesyet = $self->{keyset};
	$tpyist = $self->{tpyist};


	drunkify($tpyist);

	my $misspellign;
	my $last_modifier = "unmodified";
	my $switch_with;

	LETTER:
	# If we loop along the string with an index, we can do look-aheads.
	for my $i (0 .. length ($stirng) - 1)
	{
		my $c = substr $stirng, $i, 1;
		# DEBUG:
		# print "$c ";

		# Fail to even type the letter.
		# DEBUG:
		# print "No press\n" and next LETTER if rand (1) < $tpyist->{weakness};

		my ($modifier, $key_x, $key_y) = get_coords($c, $kesyet) or next LETTER;
		
		# [1]
		if ($modifier ne $last_modifier) {
			# Look for [ $modifier, $last_modifier ] in @{$kesyet->{_allow_table_jump}} 
			if ( grep { $_->[0] eq $modifier and $_->[1] eq $last_modifier } 
										@{$kesyet->{_allow_table_jump}} ) 
			{
				# DEBUG
				# print "Modifier fail\n" and $modifier = $last_modifier if rand (1) > $tpyist->{modifier_discipline};
			}
		}

		my %candidates = get_candidates($kesyet, $modifier, $key_x, $key_y);

		my @candidates = map { ($_) x int (100 * $candidates{$_} ) } keys %candidates;
		my $fail_char = (rand 1 < $tpyist->{miscoordination} ) ? 
		                    $candidates[ rand @candidates ] 
											: get_char($kesyet, $modifier, $key_x, $key_y);

		if (rand (1) < $tpyist->{complete_failure}) {
			#DEBUG
			# print "complete failure\n";
			$fail_char = get_completely_random_letter($kesyet, $modifier);
		}

		# DEBUG
		# print "    $c -> $fail_char\n";

		# [2]
		if (($c eq ' ' or substr($stirng, $i+1, 1) eq ' ')
				and rand (1) > $tpyist->{spacebar_discipline}) {
			$switch_with = $fail_char;
			# DEBUG
			# print "Space discipline failure\n";
			next LETTER;
		}

		# Press two keys - type the correct char as well as the failed char.
		# print "Fat fingers\n" and $misspellign .= $c if (rand (1) < $tpyist->{finger_fatness} and $fail_char ne $c);
		$misspellign .= $fail_char;

		$misspellign .= $fail_char if rand (1) < $tpyist->{caffeine};

		# print "Appending '$switch_with'\n" if $switch_with;
		$misspellign .= $switch_with if $switch_with;
		$switch_with = undef;

		# [3]
		$last_modifier = $modifier;
	}
	return $misspellign;
}

sub new {
	my $class = shift;
	my $kesyet = shift || $DEAFULT_KEYSTE;
	my $tpyist = shift || $DEFAUTL_TPYIST;

	$tpyist = { %$DEFAUTL_TPYIST, %$tpyist };

	my $self = { tpyist => $tpyist };

	if (ref $kesyet and ref $kesyet eq 'HASH') {
		$self->{keyset} = $kesyet;
	}
	else {
		$self->{keyset} = $keysets{$kesyet} || die "Unknown keyset";
	}

	bless $self, $class;
}

1;

__END__

# Notes:
#
# [1]
# Have we changed modifier? If so, what are the chances we failed
# to actually do it? And does the layout allow that we fail in this
# manner - i.e. can we go from $modifier to $last_modifier?
# 
# [2] 
# Call next if we're on a space and we're losing spacebar discipline,
# because we don't want to actually concatenate the character until
# the end of the next loop.
#
# [3]
# It might seem that setting the last modifier to the current modifier
# is a bug, because earlier we set the modifier to the last modifier in
# certain circumstances. However, this is coherent: if the typist has 0
# for their modifier discipline, the typist will never successfully let
# go of any modifier the key set says he can hold on to.

=head1 NAME

Acme::Tpyo - Perl extension for misspelling words!

=head1 SYNOPSIS

	use Acme::Tpyo;
	my $tpyist = Acme::Tpyo->new();
	print $tpyist->misspell("one of these days alice, bang zoom, straight to the moon");
	...
	my $keysetup = {
	  MY_BOARD => {
			# Key tables
			unmodified => 
			[
				"`1234567890-=\\",
				"qwertyuiop[]",
				"asdfghjkl;'",
				"zxcvbnm,./",
			],
			shift =>
			[
				"~!@#$%^&*()_+|",
				"QWERTYUIOP{}",
				"ASDFGHJKL:\"",
				"ZXCVBNM<>?",
			],
			# Relative positions of the first key of each row.
			_offsets =>
			[
				0, 0.5, 1, 2
			],
			# Which key tables can we jump between? [ from, to ]
			_allow_table_jump =>
			[
				[ qw( unmodified shift ) ],
				[ qw( shift unmodified ) ],
			],
		},
	};

=head1 DESCRIPTION

Tired of having to misspell your words by accident? 

Want to do it more often and worse than normal?

Acme::Tpyo is for you!

With Acme::Tpyo you can use your normally perfectly typed strings
and make them look like a 2nd grader! Great to give your project that
professional edge your boss is always asking for!

=head2 METHODS

=head3 misspell

	$tpyist->misspell($string);

Use it to misspell stuff.

B<$string>

The string to misspell.

=head3 new

B<$keyset>

Optional defaults to US_QWERTY otherwise.

Pass a) a hashref (see below) or b) a string naming one of the default
keyboard layouts

B<$typist>

Optional.

Pass a hashref describing the typist. Defaults will be used if not 
provided.

=over

=item modifier_discipline

Between 0 and 1, how B<un>likely the typist is to use the wrong key table.

=item spacebar_discipline

Between 0 and 1, how B<un>likely the typist is to put the space at the end
of a word in the wrong place.

=item finger_fatness

Between 0 and 1, how likely the typist is to press more than one key
at once.

=item disorder

Between 0 and 1, how likely the typist is to get the letters in the
wrong order.

=item miscoordination

Between 0 and 1, how likely the typist is to get the letters wrong in
the first place.

=item weakness

Between 0 and 1, how likely the typist is to succeed in pressing the key.

=item complete_failure

Between 0 and 1, how likely the typist is to have a complete brain fart
and press completely the wrong key, rather than just miss.

=item caffeine

Between 0 and 1, how likely the typist is to repeat a letter due to 
the jitters.

=item drunkenness

Between 0 and 1, makes the typist worse at everything in one go.

=back

B<Returns>

Tpyo object

=head2 KEYBOARD LAYOUTS

Creating a new keyboard layout is easy.

=head3 Things to note

If you don't read the rest, note these.

=over

=item * You can call your keyboard layout anything you want

=item * You can call your modifier tables anything you want, except
something starting with an underscore.

=item * You must have a table called "unmodified" for it to work

=item * You can't lose modifier discipline if your _allow_table_jump
array is empty - map your modifier table names to each other here.

=item * _allow_table_jump must always be a two-dimensional array ref

=item * If modifier+key produces nothing, put a space, so that the other
keys line up in the table.

=back

=head3 Key tables

First, describe what the key setup looks like without any modifiers.
To do this, start a new hashref in $keysetup with whatever name you
wish:

	my $keysetup = {
		# ...
		NEW_LAYOUT => {
		}
	}

Then, add a key called "unmodified". In fact, you can name your key 
tables whatever you wish, but Tpyo expects there to be one called
"unmodified".

Hash keys starting with an underscore are ignored, because these are
meta-keys used by the engine as settings for the key tables.

This key points to an array ref. The array ref contains as many strings
as you have rows on your keyboard.

Fill in your strings by pressing the first key on the row and then
dragging it jazz-pianist style to the end of the row. Repeat for each
row.

	my $keysetup = {
		# ...
		NEW_LAYOUT => {
			unmodified => [
				q[`1234567890-=],
				q[qwertyuiop[]],
				# ... etc
			]
		}
	}

Next, repeat this process for each accelerator or modifier key that
you care about. For instance, shift:

	my $keysetup = {
		# ...
		NEW_LAYOUT => {
			unmodified => [
				# ...
			],
			shift => [
				q[ ¬!"£$%^*()_+ ],
				# ...
			]
		}
	}

This constructs a table for each modifier key. 

=head3 Offsets

You may also wish to specify the offsets of each row, relative to the
leftmost row, which is at 0. This doesn't have to be precise; it just
helps for the engine to know which keys are next to which other keys.

	my $keysetup = {
		# ...
		NEW_LAYOUT => {
			unmodified => [
				# ...
			],
			shift => [
				# ...
			],
			_offsets => [
				0, 1.5, 1.75, 1.25
			]
		}
	}

=head3 Table jumping

Table jumping is what happens when you accidentally press a modifier
key while typing. This usually happens when you don't let go of it
fast enough, or press it too early.

As part of the keyboard settings you can specify which modifiers you're
likely, as a typist, to press at the wrong time.

	my $keysetup = {
		# ...
		NEW_LAYOUT => {
			# ...
			_allow_table_jump => [
				[ qw( unmodified shift ) ],
				[ qw( shift unmodified ) ],
				[ qw( altgr unmodified ) ],
				[ qw( altgrshift shift ) ],
				[ qw( altgrshift altgr ) ],
			]
		}
	}

The above means that a character found in the 'unmodified' table may
be replaced by the equivalent character from the 'shift' key table;
a character on the 'shift' key table may be replaced by a character
in the 'unmodified' key table; and a character in the 'altgr' keytable
may be replaced by a character from the 'unmodified' key table. But,
a character from the 'unmodified' and 'shift' key tables may not be
replaced by a character from the 'altgr' key table, because one is
not likely to accidentally press altgr - but one is likely to 
accidentally fail to press it.

=head1 TODO

=over

=item 1 Check docs are proper, always needs doing

=item 2 Allow space in keyset

=item 3 Fix maths in drunkify function

=item 4 (Suggested by f00li5h) Allow for permanent modifiers in the keyset,
to be pressed by accident, such as caps next to A.

=back

=head1 AUTHOR

Ryan Voots, simcop@cpan.org
Alastair Douglas, alastair.douglas+cpan@gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004,2008 by Ryan Voots, portions by Alastair Douglas

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
