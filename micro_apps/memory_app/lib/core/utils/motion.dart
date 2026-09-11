import 'package:flutter/material.dart';

/// Returns [duration] unchanged, or [Duration.zero] if the user has
/// enabled "reduce motion" at the OS level. Flutter's own implicit
/// animations already respect this in a few places, but hand-rolled
/// `AnimationController`s and `TweenAnimationBuilder`s don't unless
/// explicitly told to — every custom animation in this app that isn't a
/// small crossfade should be wrapped with this.
Duration motionDuration(BuildContext context, Duration duration) {
  final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  return disableAnimations ? Duration.zero : duration;
}

bool isReducedMotion(BuildContext context) {
  return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}
