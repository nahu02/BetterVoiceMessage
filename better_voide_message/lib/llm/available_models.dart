enum AvailableModels {
  llama3_1SonarSmall128kOnline,
  llama3_1SonarLarge128kOnline,
  llama3_1SonarHuge128kOnline;

  @override
  String toString() {
    switch (this) {
      case AvailableModels.llama3_1SonarSmall128kOnline:
        return 'llama-3.1-sonar-small-128k-online';
      case AvailableModels.llama3_1SonarLarge128kOnline:
        return 'llama-3.1-sonar-large-128k-online';
      case AvailableModels.llama3_1SonarHuge128kOnline:
        return 'llama-3.1-sonar-huge-128k-online';
    }
  }
}
