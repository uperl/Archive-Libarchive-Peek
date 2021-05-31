# Archive::Libarchive::Peek ![linux](https://github.com/uperl/Archive-Libarchive-Peek/workflows/linux/badge.svg)

Peek into archives without extracting them

# SYNOPSIS

```perl
use Archive::Libarchive::Peek;
my $peek = Archive::Libarchive::Peek->new( filename => 'archive.tar' );
my @files = $peek->files();
my $contents = $peek->file('README.txt')
```

# DESCRIPTION

This module lets you peek into archives without extracting them.  It is based on [Archive::Peek](https://metacpan.org/pod/Archive::Peek), but it uses [Archive::Libarchive](https://metacpan.org/pod/Archive::Libarchive),
and thus all of the many formats supported by `libarchive`.  It also supports some unique features of the various classes that use
the "Peek" style interface:

- Many Many formats

    compressed tar, Zip, RAR, ISO 9660 images, etc.

- Zips with encrypted entries

    You can specify the passphrase or a passphrase callback with the constructor

- Multi-file RAR archives

    If filename is an array reference it will be assumed to be a list of filenames
    representing a single multi-file archive.

# CONSTRUCTOR

## new

```perl
my $peek = Archive::Libarchive::Peek->new(%options);
```

This creates a new instance of the Peek object.

- filename

    ```perl
    my $peek = Archive::Libarchive::Peek->new( filename => $filename );
    ```

    This option is required, and is the filename of the archive.

- passphrase

    ```perl
    my $peek = Archive::Libarchive::Peek->new( passphrase => $passphrase );
    my $peek = Archive::Libarchive::Peek->new( passphrase => sub {
      ...
      return $passphrase;
    });
    ```

    This option is the passphrase for encrypted zip entries, or a
    callback which will return the passphrase.

# PROPERTIES

## filename

This is the archive filename for the Peek object.

# METHODS

## files

```perl
my @files = $peek->files;
```

This method returns the filenames of the entries in the archive.

## file

```perl
my $content = $peek->file($filename);
```

This method files the filename in the archive and returns its content.

## iterate

```perl
$peek->iterate(sub ($filename, $content, $e) {
  ...
});
```

This method iterates over the entries in the archive and calls the callback for each
entry.  The arguments are:

- filename

    The filename of the entry

- content

    The content of the entry, or `''` for non-regular or zero-sized files

- entry

    This is a [Archive::Libarchive::Entry](https://metacpan.org/pod/Archive::Libarchive::Entry) instance which has metadata about the
    file, like the permissions, timestamps and file type.

# SEE ALSO

- [Archive::Peek](https://metacpan.org/pod/Archive::Peek)

    The original!

- [Archive::Peek::External](https://metacpan.org/pod/Archive::Peek::External)

    Another implementation that uses external commands to peek into archives

- [Archive::Peek::Libarchive](https://metacpan.org/pod/Archive::Peek::Libarchive)

    Another implementation that also relies on `libarchive`, but doesn't support
    the file type in iterate mode, encrypted zip entries, or multi-file RAR archives.

- [Archive::Libarchive](https://metacpan.org/pod/Archive::Libarchive)

    A lower-level interface to `libarchive` which can be used to read/extract and create
    archives of various formats.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
