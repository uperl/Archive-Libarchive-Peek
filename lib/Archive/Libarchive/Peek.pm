package Archive::Libarchive::Peek;

use strict;
use warnings;
use Archive::Libarchive 0.03 qw( ARCHIVE_OK ARCHIVE_WARN ARCHIVE_EOF );
use Ref::Util qw( is_plain_coderef is_plain_arrayref );
use Carp ();
use 5.020;
use experimental qw( signatures );

# ABSTRACT: Peek into archives without extracting them
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis.pl

=head1 DESCRIPTION

This module lets you peek into archives without extracting them.  It is based on L<Archive::Peek>, but it uses L<Archive::Libarchive>,
and thus all of the many formats supported by C<libarchive>.  It also supports some unique features of the various classes that use
the "Peek" style interface:

=over 4

=item Many Many formats

compressed tar, Zip, RAR, ISO 9660 images, etc.

=item Zips with encrypted entries

You can specify the passphrase or a passphrase callback with the constructor

=item Multi-file RAR archives

If filename is an array reference it will be assumed to be a list of filenames
representing a single multi-file archive.

=back

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

  foreach my $filename (@{ is_plain_arrayref($options{filename}) ? $options{filename} : [$options{filename}] })
  {
    Carp::croak("Missing or unreadable: $filename")
      unless -r $filename;
  }

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

  if($self->{passphrase})
  {
    if(is_plain_coderef $self->{passphrase})
    {
      $r->set_passphrase_callback($self->{passphrase});
    }
    else
    {
      $r->add_passphrase($self->{passphrase});
    }
  }

  my $ret = is_plain_arrayref($self->filename) ? $r->open_filenames($self->filename, 10240) : $r->open_filename($self->filename, 10240);

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

sub _entry ($self, $r, $e)
{
  my $ret = $r->next_header($e);
  return 0 if $ret == ARCHIVE_EOF;
  if($ret == ARCHIVE_WARN)
  {
    Carp::carp($r->error_string);
  }
  elsif($ret < ARCHIVE_WARN)
  {
    Carp::croak($r->error_string);
  }
  return 1;
}

sub files ($self)
{
  my($r, $e) = $self->_archive;

  my @files;

  while(1)
  {
    last unless $self->_entry($r,$e);
    push @files, $e->pathname;
    $r->read_data_skip;
  }

  $r->close;

  return @files;
}

=head2 file

 my $content = $peek->file($filename);

This method files the filename in the archive and returns its content.

=cut

sub _entry_data ($self, $r, $e, $content)
{
  $$content = '';

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
    $$content .= $buffer;
  }
}

sub file ($self, $filename)
{
  my($r, $e) = $self->_archive;

  while(1)
  {
    last unless $self->_entry($r,$e);
    if($e->pathname eq $filename)
    {
      my $content;
      $self->_entry_data($r, $e, \$content);
      return $content;
    }
    else
    {
      $r->read_data_skip;
    }
  }

  $r->close;

  return undef;
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
    last unless $self->_entry($r,$e);
    my $content;
    $self->_entry_data($r, $e, \$content);
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
