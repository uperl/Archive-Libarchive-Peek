use Test2::V0 -no_srand => 1;
use Archive::Libarchive::Peek;

is(
  dies { Archive::Libarchive::Peek->new },
  match qr/^Required option: filename at t\/archive_libarchiv/,
  'undef filename',
);

is(
  dies { Archive::Libarchive::Peek->new( filename => 'bogus.tar' ) },
  match qr/^Missing or unreadable: bogus.tar at t\/archive_li/,
  'bad filename',
);

is(
  dies { Archive::Libarchive::Peek->new( filename => 'corpus/archive.tar', foo => 1, bar => 2 ) },
  match qr/^Illegal options: bar foo/,
  'bad filename',
);

is(
  Archive::Libarchive::Peek->new( filename => 'corpus/archive.tar' ),
  object {
    call [ isa => 'Archive::Libarchive::Peek' ] => T();
    call filename => 'corpus/archive.tar';
    call_list files => [
      'archive/',
      'archive/bar.txt',
      'archive/foo.txt',
    ];
  },
  'files'
);

done_testing;


