package Gherkin::TokenMatcher;

use Moose;
use Gherkin::Dialect;

our $LANGUAGE_RE = qr/^\s*#\s*language\s*:\s*([a-zA-Z\-_]+)\s*$/o;

has 'dialect' => (
    is      => 'ro',
    isa     => 'Gherkin::Dialect',
    default => sub {
        Gherkin::Dialect->new( { dialect => 'en' } );
    },
    handles => { dialect_name => 'dialect', }
);

has '_default_dialect_name' => ( is => 'rw', isa => 'Str' );

has '_indent_to_remove' => ( is => 'rw', isa => 'Int', default => 0 );
has '_active_doc_string_separator' => ( is => 'rw', isa => 'Str|Undef' );

sub BUILD {
    my $self = shift;
    $self->_default_dialect_name( $self->dialect_name );
    $self->reset();
}

sub reset {
    my $self = shift;
    $self->dialect_name( $self->_default_dialect_name )
        unless $self->dialect_name eq $self->_default_dialect_name;
    $self->_indent_to_remove(0);
    $self->_active_doc_string_separator(undef);
}

for my $keyword (qw/Feature Scenario ScenarioOutline Background Examples/) {
    __PACKAGE__->meta->add_method(
        'match_' . $keyword . 'Line' => sub {
            my ( $self, $token ) = @_;
            return $self->_match_title_line(
                $token,
                $keyword . 'Line',
                $self->dialect->$keyword,
            );
        }
    );
}

sub match_Language {
    my ( $self, $token ) = @_;
    if ( $token->line->get_line_text =~ $LANGUAGE_RE ) {
        my $dialect_name = $1;
        $self->_set_token_matched( $token,
            Language => { text => $dialect_name } );
        $self->dialect_name( $dialect_name, $token->location );
        return 1;
    }
    else {
        return;
    }
}

sub match_TagLine {
    my ( $self, $token ) = @_;
    return unless $token->line->startswith('@');
    $self->_set_token_matched( $token,
        TagLine => { items => $token->line->tags } );
    return 1;
}

sub _match_title_line {
    my ( $self, $token, $token_type, $keywords ) = @_;

    for my $keyword (@$keywords) {
        if ( $token->line->startswith_title_keyword($keyword) ) {
            my $title
                = $token->line->get_rest_trimmed( length( $keyword . ': ' ) );
            $self->_set_token_matched( $token, $token_type,
                { text => $title, keyword => $keyword } );
            return 1;
        }
    }

    return;
}

sub _set_token_matched {
    my ( $self, $token, $matched_type, $options ) = @_;
    $options->{'items'} ||= [];
    $token->matched_type($matched_type);

    if ( defined $options->{'text'} ) {
        chomp( $options->{'text'} );
        $token->matched_text( $options->{'text'} );
    }

    $token->matched_keyword( $options->{'keyword'} )
        if defined $options->{'keyword'};

    if ( defined $options->{'indent'} ) {
        $token->matched_indent( $options->{'indent'} );
    }
    else {
        $token->matched_indent( $token->line ? $token->line->indent : 0 );
    }

    $token->matched_items( $options->{'items'} )
        if defined $options->{'items'};

    $token->location->{'column'} = $token->matched_indent + 1;
    $token->matched_gherkin_dialect( $self->dialect_name );
}

sub match_EOF {
    my ( $self, $token ) = @_;
    return unless $token->is_eof;
    $self->_set_token_matched( $token, 'EOF' );
    return 1;
}

sub match_Empty {
    my ( $self, $token ) = @_;
    return unless $token->line->is_empty;
    $self->_set_token_matched( $token, Empty => { indent => 0 } );
    return 1;
}

sub match_Comment {
    my ( $self, $token ) = @_;
    return unless $token->line->startswith('#');

    my $comment_text = $token->line->line_text;
    $comment_text =~ s/\r\n$//; # Why?

    $self->_set_token_matched( $token,
        Comment => { text => $comment_text, indent => 0 } );
    return 1;
}

sub match_Other {
    my ( $self, $token ) = @_;

    # take the entire line, except removing DocString indents
    my $text = $token->line->get_line_text( $self->_indent_to_remove );
    $self->_set_token_matched( $token,
        Other => { indent => 0, text => $self->_unescaped_docstring( $text ) } );
    return 1;
}

sub _unescaped_docstring {
    my ( $self, $text ) = @_;
    if ( $self->_active_doc_string_separator ) {
        $text =~ s!\\"\\"\\"!"""!;
        return $text;
    }
    else {
        return $text;
    }
}

sub match_StepLine {
    my ( $self, $token ) = @_;
    my @keywords
        = map { @{ $self->dialect->$_ } } qw/Given When Then And But/;

    for my $keyword (@keywords) {
        if ( $token->line->startswith($keyword) ) {
            my $title = $token->line->get_rest_trimmed( length($keyword) );
            $self->_set_token_matched( $token,
                StepLine => { text => $title, keyword => $keyword } );
            return 1;
        }
    }
    return;
}

sub match_DocStringSeparator {
    my ( $self, $token ) = @_;
    if ( !$self->_active_doc_string_separator ) {
        return $self->_match_DocStringSeparator( $token, '"""', 1 )
            || $self->_match_DocStringSeparator( $token, '```', 1 );
    }
    else {
        return $self->_match_DocStringSeparator( $token,
            $self->_active_doc_string_separator, 0 );
    }
}

sub _match_DocStringSeparator {
    my ( $self, $token, $separator, $is_open ) = @_;
    return unless $token->line->startswith($separator);

    my $content_type;
    if ($is_open) {
        $content_type = $token->line->get_rest_trimmed( length($separator) );
        $self->_active_doc_string_separator($separator);
        $self->_indent_to_remove( $token->line->indent );
    }
    else {
        $self->_active_doc_string_separator(undef);
        $self->_indent_to_remove(0);
    }

    $self->_set_token_matched( $token,
        DocStringSeparator => { text => $content_type } );
}

sub match_TableRow {
    my ( $self, $token ) = @_;
    return unless $token->line->startswith('|');

    $self->_set_token_matched( $token,
        TableRow => { items => $token->line->table_cells } );
}

1;