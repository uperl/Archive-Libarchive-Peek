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
and thus all of the many formats supported by `libarchive`.

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

## iterate

```perl
$peek->iterate(sub ($filename, $content) {
  ...
});
```

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
