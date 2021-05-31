package Archive::Libarchive::Peek;

use strict;
use warnings;
use Archive::Libarchive qw( ARCHIVE_OK ARCHIVE_WARN ARCHIVE_EOF );
use Carp ();
use 5.020;
use experimental qw( signatures );

# ABSTRACT: Peek into archives without extracting them
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis.pl

=head1 DESCRIPTION

This module lets you peek into archives without extracting them.  It is based on L<Archive::Peek>, but it uses L<Archive::Libarchive>,
and thus all of the many formats supported by C<libarchive>.

=head1 CONSTRUCTOR

=head2 new

 my $peek = Archive::Libarchive::Peek->new(%options);

This creates a new instance of the Peek object.

=over 4

=item filename

 my $peek = Archive::Libarchive::Peek->new( filename => $filename );

This option is required, and is the filename of the archive.

=item passphrase

 my $peek = Archive::Libarchive::Peek->new( passphrase => $passphrase );
 my $peek = Archive::Libarchive::Peek->new( passphrase => sub {
   ...
   return $passphrase;
 });

This option is the passphrase for encrypted zip entries, or a
callback which will return the passphrase.

=back

=cut

sub new ($class, %options)
{
  Carp::croak("Required option: filename")
    unless defined $options{filename};

  Carp::croak("Missing or unreadable: $options{filename}")
    unless -r $options{filename};

  my $self = bless {
    filename   => delete $options{filename},
    passphrase => delete $options{passphrase},
  }, $class;

  Carp::croak("Illegal options: @{[ sort keys %options ]}")
    if %options;

  return $self;
}

=head1 PROPERTIES

=head2 filename

This is the archive filename for the Peek object.

=cut

sub filename ($self)
{
  return $self->{filename};
}

=head1 METHODS

=head2 files

 my @files = $peek->files;

This method returns the filenames of the entries in the archive.

=cut

sub _archive ($self)
{
  my $r = Archive::Libarchive::ArchiveRead->new;
  my $e = Archive::Libarchive::Entry->new;

  $r->support_filter_all;
  $r->support_format_all;

  my $ret = $r->open_filename($self->filename, 10240);
  if($ret == ARCHIVE_WARN)
  {
    Carp::carp($r->error_string);
  }
  elsif($ret < ARCHIVE_WARN)
  {
    Carp::croak($r->error_string);
  }

  return ($r,$e);
}

sub files ($self)
{
  my($r, $e) = $self->_archive;

  my @files;

  while(1)
  {
    my $ret = $r->next_header($e);
    last if $ret == ARCHIVE_EOF;
    if($ret == ARCHIVE_WARN)
    {
      Carp::carp($r->error_string);
    }
    elsif($ret < ARCHIVE_WARN)
    {
      Carp::croak($r->error_string);
    }
    push @files, $e->pathname;
    $r->read_data_skip;
  }

  $r->close;

  return @files;
}

=head2 file

 my $content = $peek->file($filename);

=cut

sub file
{
}

=head2 iterate

 $peek->iterate(sub ($filename, $content, $type) {
   ...
 });

This method iterates over the entries in the archive and calls the callback for each
entry.  The arguments are:

=over 4

=item filename

The filename of the entry

=item content

The content of the entry, or C<''> for non-regular or zero-sized files

=item type

The type of entry.  For regular files this will be C<reg> and for directories
this will be C<dir>.  See L<Archive::Libarchive::Entry/filetype> for the full list.
(Unlike L<Archive::Libarchive::Entry>, this method will NOT create dualvars, just
strings).

=back

=cut

sub iterate ($self, $callback)
{
  my($r, $e) = $self->_archive;

  while(1)
  {
    my $ret = $r->next_header($e);
    last if $ret == ARCHIVE_EOF;
    if($ret == ARCHIVE_WARN)
    {
      Carp::carp($r->error_string);
    }
    elsif($ret < ARCHIVE_WARN)
    {
      Carp::croak($r->error_string);
    }

    my $content = '';
    if($e->size > 0)
    {
      my $buffer;

      my $ret = $r->read_data(\$buffer);
      last if $ret == 0;
      if($ret == ARCHIVE_WARN)
      {
        Carp::carp($r->error_string);
      }
      elsif($ret < ARCHIVE_WARN)
      {
        Carp::croak($r->error_string);
      }
      $content .= $buffer;
    }

    $callback->($e->pathname, $content, $e->filetype.'');
  }
}

1;

=head1 SEE ALSO

=over 4

=item L<Archive::Peek>

The original!

=item L<Archive::Peek::External>

Another implementation that uses external commands to peek into archives

=item L<Archive::Peek::Libarchive>

Another implementation that also relies on C<libarchive>, but doesn't support
the file type in iterate mode, encrypted zip entries, or multi-file RAR archives.

=item L<Archive::Libarchive>

A lower-level interface to C<libarchive> which can be used to read/extract and create
archives of various formats.

=back

=cut
