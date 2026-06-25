enum SocialTarget { meditation, teacher, training, comment }

extension SocialTargetX on SocialTarget {
  String get dbValue => name;
}
