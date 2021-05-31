use Test2::V0 -no_srand => 1;
use Archive::Libarchive::Peek;
use experimental qw( signatures );

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

subtest 'iterate' => sub {

  my $peek = Archive::Libarchive::Peek->new( filename => 'corpus/archive.tar' );

  my @expect = (
    [ 'archive/', '', 'dir' ],
    [ 'archive/bar.txt', "there\n", 'reg' ],
    [ 'archive/foo.txt', "hello\n", 'reg' ],
  );

  $peek->iterate(sub ($filename, $content, $type) {
    my $expect = shift @expect;
    is [$filename, $content, $type], $expect, $expect->[0];
  });

  is \@expect, [], 'consumed all expected';

};

is(
  Archive::Libarchive::Peek->new( filename => 'corpus/archive.tar' ),
  object {
    call [ file => 'archive/' ] => '';
    call [ file => 'archive/bar.txt' ] => "there\n";
    call [ file => 'archive/foo.txt' ] => "hello\n";
  },
  'file',
);

is(
  Archive::Libarchive::Peek->new( filename => 'corpus/archive.zip', passphrase => 'password' ),
  object {
    call [ file => 'archive/' ] => '';
    call [ file => 'archive/bar.txt' ] => "there\n";
    call [ file => 'archive/foo.txt' ] => "hello\n";
  },
  'zip passphrase',
);

is(
  Archive::Libarchive::Peek->new( filename => 'corpus/archive.zip', passphrase => sub { return 'password' } ),
  object {
    call [ file => 'archive/' ] => '';
    call [ file => 'archive/bar.txt' ] => "there\n";
    call [ file => 'archive/foo.txt' ] => "hello\n";
  },
  'zip passphrase',
);

is(
  Archive::Libarchive::Peek->new( filename => [
    'corpus/test_read_splitted_rar_aa',
    'corpus/test_read_splitted_rar_ab',
    'corpus/test_read_splitted_rar_ac',
    'corpus/test_read_splitted_rar_ad',
  ]),
  object {
    call_list files => [
      'test.txt',
      'testlink',
      'testdir/test.txt',
      'testdir',
      'testemptydir',
    ];
  },
  'file',
);

done_testing;
