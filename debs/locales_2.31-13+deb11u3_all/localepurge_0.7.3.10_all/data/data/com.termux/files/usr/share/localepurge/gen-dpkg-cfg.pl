#!//data/data/com.termux/files/usr/bin/perl

use strict;
use warnings;

use constant CONFIG_FILE => '//data/data/com.termux/files/usr/etc/locale.nopurge';
use constant DPKG_CONFIG_FILE => '//data/data/com.termux/files/usr/etc/dpkg/dpkg.cfg.d/50localepurge';

my @PURGABLE_DIRS = (
    '/data/data/com.termux/files/usr/share/locale/*',
    '/data/data/com.termux/files/usr/share/gnome/help/*/*',
    '/data/data/com.termux/files/usr/share/doc/kde/HTML/*/*',
    '/data/data/com.termux/files/usr/share/omf/*/*-*.emf',
    '/data/data/com.termux/files/usr/share/tcltk/t*/msgs/*.msg',
    '/data/data/com.termux/files/usr/share/cups/templates/*', '/data/data/com.termux/files/usr/share/cups/locale/*', '/data/data/com.termux/files/usr/share/cups/doc-root/*',
    '/data/data/com.termux/files/usr/share/calendar/*',
    '/data/data/com.termux/files/usr/share/aptitude/*.*',
    '/data/data/com.termux/files/usr/share/help/*',
    '/data/data/com.termux/files/usr/share/vim/vim*/lang/*',
);
my @KEEP_DIRS = (
    '/data/data/com.termux/files/usr/share/locale/locale.alias',
    '/data/data/com.termux/files/usr/share/locale/@LOCALE@/*',
    '/data/data/com.termux/files/usr/share/gnome/help/*/C/*',
    '/data/data/com.termux/files/usr/share/gnome/help/*/@LOCALE@/*',
    '/data/data/com.termux/files/usr/share/doc/kde/HTML/C/*',
    '/data/data/com.termux/files/usr/share/doc/kde/HTML/@LOCALE@/*',
    '/data/data/com.termux/files/usr/share/omf/*/*-@LOCALE@.emf',
    '/data/data/com.termux/files/usr/share/omf/*/*-C.emf',
    '/data/data/com.termux/files/usr/share/locale/languages',      # from blender-data
    '/data/data/com.termux/files/usr/share/locale/all_languages',  # from kdelibs5-data
    '/data/data/com.termux/files/usr/share/locale/currency/*',     # from kde-runtime-data
    '/data/data/com.termux/files/usr/share/locale/l10n/*',         # from kde-runtime-data
    '/data/data/com.termux/files/usr/share/tcltk/t*/msgs/@LOCALE@.msg',
    '/data/data/com.termux/files/usr/share/cups/templates/*.tmpl', 
    '/data/data/com.termux/files/usr/share/cups/templates/@LOCALE@/*', 
    '/data/data/com.termux/files/usr/share/cups/locale/@LOCALE@/*', 
    '/data/data/com.termux/files/usr/share/cups/doc-root/*.*', 
    '/data/data/com.termux/files/usr/share/cups/doc-root/help', 
    '/data/data/com.termux/files/usr/share/cups/doc-root/images',
    '/data/data/com.termux/files/usr/cups/doc-root/@LOCALE@/*',
    '/data/data/com.termux/files/usr/share/calendar/*.*',
    '/data/data/com.termux/files/usr/share/calendar/@LOCALE@/*',
    '/data/data/com.termux/files/usr/share/aptitude/aptitude-defaults.@LOCALE@', '/data/data/com.termux/files/usr/share/aptitude/README.@LOCALE@', '/data/data/com.termux/files/usr/share/aptitude/help-@LOCALE@.txt', '/data/data/com.termux/files/usr/share/aptitude/mine-help-@LOCALE@.txt', '/data/data/com.termux/files/usr/share/aptitude/help.txt', '/data/data/com.termux/files/usr/share/aptitude/mine-help.txt', 
    '/data/data/com.termux/files/usr/share/help/@LOCALE@/*', '/data/data/com.termux/files/usr/share/help/C/*',
    '/data/data/com.termux/files/usr/share/vim/vim*/lang/@LOCALE@/*', '/data/data/com.termux/files/usr/share/vim/vim*/lang/*.*'
);

exit 0 unless -f CONFIG_FILE;

my %options = ();
my @dpkg_opts = ();
my $dpkgcnf = DPKG_CONFIG_FILE;

if (defined $ARGV[0] and $ARGV[0] eq '--remove') {
    if ( -f $dpkgcnf ) {
        print "Removing auto-generated file: $dpkgcnf\n";
        unlink $dpkgcnf or die "unlink $dpkgcnf: $!";
    }
    exit 0;
}

read_conf (CONFIG_FILE, \%options);

if ($options{'MANDELETE'}) {
    push @PURGABLE_DIRS, '/data/data/com.termux/files/usr/share/man/*';
    push @KEEP_DIRS, '/data/data/com.termux/files/usr/share/man/@LOCALE@/*';
    push @KEEP_DIRS, '/data/data/com.termux/files/usr/share/man/man[0-9]/*';
}

if ($options{'USE_DPKG'}) {
    my @KEEPERS = @{ $options{'KEEP_LOCALES'} };
    open my $fd, '>', $dpkgcnf or die "open $dpkgcnf: $!";
    print $fd <<EOF ;
# DO NOT MODIFY/REMOVE THIS FILE - IT IS AUTO-GENERATED
#
# To remove/disable this, run dpkg-reconfigure localepurge
# and say no to/disable the "Use dpkg --path-exclude" option.
#
# To change what patterns are affected use:
# * dpkg-reconfigure localepurge
#   (to alter which locales are kept and whether manpages should
#    be purged)
# * Add a dpkg config file in /etc/dpkg/dpkg.cfg.d that is read
#   after this file with the necessary --path-include and
#   --path-exclude options.
#
# Report faulty patterns against the localepurge package.
#

EOF

    print $fd "# Paths to purge\n";
    foreach my $pd (@PURGABLE_DIRS) {
        emit_pattern ($fd, 'path-exclude', $pd, \@KEEPERS);
    }

    print $fd "# Paths to keep\n";
    foreach my $pd (@KEEP_DIRS) {
        emit_pattern ($fd, 'path-include', $pd, \@KEEPERS);
    }
    close $fd or die "close $dpkgcnf: $!";
} elsif ( -f $dpkgcnf ) {
    unlink $dpkgcnf or die "unlink $dpkgcnf: $!";
}

exit 0;

sub emit_pattern {
    my ($fd, $option, $pat, $keepers) = @_;
    if ($pat =~ m/\@LOCALE\@/) {
        foreach my $keep (@$keepers) {
            my $d = $pat;
            $d =~ s/\@LOCALE\@/$keep/;
            print $fd "$option=$d\n";
        }
    } else {
        print $fd "$option=$pat\n";
    }
}

sub read_conf {
    my ($filename, $opts) = @_;
    my @keep_locales = ();
    open my $fd, '<', $filename or die "open $filename: $!";
    $opts->{'KEEP_LOCALES'} = \@keep_locales;
    while ( my $line = <$fd> ) {
        chomp $line;
        next if $line =~ m/^\s*#/;
        next unless $line =~ m/^\S++$/o;
        if ($line =~ m/^[a-z]/) {
            push @keep_locales, $line;
        } else {
            $opts->{$line} = 1;
        }
    }
    close $fd;
}
