enum AvailableProviders {
  perplexity;

  @override
  String toString() {
    switch (this) {
      case AvailableProviders.perplexity:
        return 'Perplexity';
    }
  }
}
