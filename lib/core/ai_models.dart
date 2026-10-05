import 'constants.dart';

/// What a model costs the user, in the only terms that matter when choosing
/// one (ADR-073).
enum ModelTier {
  /// The provider's strongest text model of the three measured. The default
  /// everywhere except Mistral, where it is not reachable without paying.
  best,

  /// Cheaper, and measurably weaker on grammar that is marked away from the
  /// noun — see ADR-072 for what that costs in practice.
  economy,

  /// Usable with the provider's free credit.
  free,
}

/// One selectable model.
///
/// The id is what goes on the wire, as an alias rather than a dated snapshot
/// (ADR-067): a pinned snapshot is eventually retired, and it is retired in
/// the field, on phones nobody has updated.
class AiModel {
  final String id;
  final String label;
  final ModelTier tier;

  const AiModel(this.id, this.label, this.tier);
}

/// The models a user may pick, per provider, strongest first.
///
/// Measured rather than assumed (ADR-072): every entry was run against the
/// number-agreement fixture, and the two that are absent — `mistral-large-latest`
/// and `gpt-4o-mini` — are absent because they failed it, not for lack of
/// space. Mistral Large is the counter-intuitive one: it scored 30% against
/// Medium's 89%, which matches Mistral's own documentation, where Medium is
/// the frontier-class model and Large an open-weight one.
const kModelsByProvider = <String, List<AiModel>>{
  kProviderClaude: [
    AiModel('claude-sonnet-5-5', 'Claude Sonnet 5.5', ModelTier.best),
    AiModel('claude-haiku-4-5', 'Claude Haiku 4.5', ModelTier.economy),
  ],
  kProviderOpenAI: [
    AiModel('gpt-5.6-luna', 'GPT-5.6 Luna', ModelTier.best),
  ],
  kProviderMistral: [
    AiModel('mistral-medium-latest', 'Mistral Medium', ModelTier.best),
    AiModel('mistral-small-latest', 'Mistral Small', ModelTier.free),
  ],
};

/// The model a provider uses until the user says otherwise.
///
/// Claude and OpenAI default to their strongest, because a default that
/// silently drops a plural is the defect ADR-072 was opened for. Mistral
/// cannot: its strongest needs a paid plan, and the README sends newcomers to
/// the free tier, so a paid default would meet them with an error on their
/// first translation.
String defaultModelFor(String provider) => switch (provider) {
      kProviderClaude => 'claude-sonnet-5-5',
      kProviderOpenAI => 'gpt-5.6-luna',
      _ => 'mistral-small-latest',
    };

/// The models for [provider], or an empty list for an unknown one.
List<AiModel> modelsFor(String provider) =>
    kModelsByProvider[provider] ?? const [];

/// Keeps a stored value usable when this catalogue moves on: a model that was
/// removed, or a preference written by a newer version, falls back to the
/// provider's default rather than being sent to an API that will reject it.
String resolveModel(String provider, String stored) {
  if (modelsFor(provider).any((m) => m.id == stored)) return stored;
  return defaultModelFor(provider);
}
