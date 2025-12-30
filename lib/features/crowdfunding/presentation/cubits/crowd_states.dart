import 'package:nri_trial1_clean/features/crowdfunding/domain/entities/crowd_post.dart';

abstract class CrowdState {}

class CrowdInitial extends CrowdState {}
class CrowdLoading extends CrowdState {}
class CrowdUploading extends CrowdState {}
class CrowdLoaded extends CrowdState { final List<CrowdPost> crowds; CrowdLoaded(this.crowds); }
class CrowdError extends CrowdState { final String message; CrowdError(this.message); }