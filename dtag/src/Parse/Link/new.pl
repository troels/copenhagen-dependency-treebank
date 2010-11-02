=item Link->new() = $link

Create new Link object.

=cut

sub new {
	# Create new object and find its class
	my $proto = shift;
	my $class = ref($proto) || $proto;

	# Create self
	my $self = []; 

	# Specify class for new object
	bless ($self, $class);

	# Return
	return $self;
}

