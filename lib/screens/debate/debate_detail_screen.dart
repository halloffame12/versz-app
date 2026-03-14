import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/url_utils.dart';
import '../../models/debate.dart';
import '../../models/comment.dart';
import '../../providers/comment_provider.dart';
import '../../providers/vote_provider.dart';
import '../../providers/saved_debates_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/views_provider.dart';
import '../../widgets/common/verz_button.dart';
import '../../widgets/common/verz_text_field.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';

class DebateDetailScreen extends ConsumerStatefulWidget {
  final Debate debate;
  const DebateDetailScreen({super.key, required this.debate});

  @override
  ConsumerState<DebateDetailScreen> createState() => _DebateDetailScreenState();
}

class _DebateDetailScreenState extends ConsumerState<DebateDetailScreen> with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  int _commentTabIndex = 0;
  late int _displayUpvotes;
  late int _displayDownvotes;
  int? _lastVote;
  late AnimationController _voteAnimationController;
  late Animation<double> _voteButtonScale;
  bool _isCommentPosting = false;
  String? _commentPostError;

  @override
  void initState() {
    super.initState();
    _displayUpvotes = widget.debate.upvotes;
    _displayDownvotes = widget.debate.downvotes;
    
    // Setup vote button animation
    _voteAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _voteButtonScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _voteAnimationController, curve: Curves.easeInOut),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commentProvider(widget.debate.id).notifier).fetchComments();
      ref.read(viewsProvider).trackDebateView(widget.debate.id);
      // Vote provider is initialized automatically in constructor
    });

    ref.listenManual<VoteState>(voteProvider('debate:${widget.debate.id}'), (prev, next) {
      final oldVote = _lastVote;
      final newVote = next.userVote;
      if (oldVote == newVote) return;

      setState(() {
        if (oldVote == 1) _displayUpvotes = (_displayUpvotes - 1).clamp(0, 1 << 30);
        if (oldVote == -1) _displayDownvotes = (_displayDownvotes - 1).clamp(0, 1 << 30);
        if (newVote == 1) _displayUpvotes = (_displayUpvotes + 1).clamp(0, 1 << 30);
        if (newVote == -1) _displayDownvotes = (_displayDownvotes + 1).clamp(0, 1 << 30);
        _lastVote = newVote;
      });
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _voteAnimationController.dispose();
    super.dispose();
  }

  void _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    setState(() {
      _isCommentPosting = true;
      _commentPostError = null;
    });
    
    try {
      final side = _commentTabIndex == 0 ? 'agree' : 'disagree';
      await ref.read(commentProvider(widget.debate.id).notifier).postComment(
        _commentController.text.trim(),
        side: side,
      );
      if (!mounted) return;
      
      setState(() {
        _isCommentPosting = false;
        _commentPostError = null;
      });
      
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCommentPosting = false;
        _commentPostError = 'Failed to post comment: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentState = ref.watch(commentProvider(widget.debate.id));
    final voteState = ref.watch(voteProvider('debate:${widget.debate.id}'));
    final sideTagged = commentState.comments.where((c) => c.side == 'agree' || c.side == 'disagree').toList();
    final hasSideTagged = sideTagged.isNotEmpty;
    final agreeComments = hasSideTagged
      ? commentState.comments.where((c) => c.side == 'agree').toList()
      : commentState.comments;
    final disagreeComments = hasSideTagged
      ? commentState.comments.where((c) => c.side == 'disagree').toList()
      : commentState.comments;
    final activeComments = _commentTabIndex == 0 ? agreeComments : disagreeComments;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: widget.debate.mediaUrl != null ? 300 : 120,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.darkCardBg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.debate.mediaType == 'image' &&
                      isValidNetworkUrl(widget.debate.mediaUrl))
                    CachedNetworkImage(
                      imageUrl: widget.debate.mediaUrl!,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradientLinear,
                      ),
                    ),
                  // Dark gradient overlay for readability
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x26000000)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined,
                    color: AppColors.textPrimary),
                onPressed: () {},
              ),
              Consumer(
                builder: (context, ref, child) {
                  final isSaved = ref.watch(
                    savedDebatesProvider.select((state) =>
                        state.savedDebates.any((d) => d.id == widget.debate.id)),
                  );
                  return IconButton(
                    icon: Icon(
                      isSaved
                          ? Icons.bookmark
                          : Icons.bookmark_border_rounded,
                      color: isSaved
                          ? AppColors.accentOrange
                          : AppColors.textPrimary,
                    ),
                    onPressed: () {
                      if (isSaved) {
                        ref
                            .read(savedDebatesProvider.notifier)
                            .unsaveDebate(widget.debate.id);
                      } else {
                        ref
                            .read(savedDebatesProvider.notifier)
                            .saveDebate(widget.debate.id);
                      }
                    },
                  );
                },
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textPrimary),
                itemBuilder: (context) => [
                  PopupMenuItem(
                      child: const Text('Report'),
                      onTap: () => _showReportDialog(context)),
                ],
              ),
            ],
          ),
        ],
        body: Container(
          decoration: const BoxDecoration(
            color: AppColors.darkBackground,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCreatorHeader(),
                      const SizedBox(height: 24),
                      Text(widget.debate.title,
                          style: AppTextStyles.h1.copyWith(
                            fontSize: 28,
                            color: AppColors.textPrimary,
                          )),
                      if (widget.debate.description != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          widget.debate.description!,
                          style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textSecondary, height: 1.6),
                        ),
                      ],
                      const SizedBox(height: 32),
                      _buildAdvancedVoteSection(voteState),
                      if (widget.debate.aiSummary != null &&
                          widget.debate.aiSummary!.trim().isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildAiVerdictCard(),
                      ],
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Text('COMMENTS', style: AppTextStyles.labelMedium.copyWith(letterSpacing: 1.2)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${widget.debate.commentCount}', style: AppTextStyles.labelSmall),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildCommentTabs(agreeComments.length, disagreeComments.length),
                      const SizedBox(height: 24),
                      if (commentState.isLoading)
                        const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      else if (commentState.error != null)
                        _buildCommentsError(commentState.error!)
                      else if (activeComments.isEmpty)
                        _buildNoComments()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activeComments.length,
                          separatorBuilder: (_, __) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Divider(color: AppColors.surfaceLight.withValues(alpha: 0.5), height: 1),
                          ),
                          itemBuilder: (context, index) => _buildCommentItem(activeComments[index]),
                        ),
                      const SizedBox(height: 100), // Space for input
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: _buildGlassCommentInput(),
    );
  }

  Widget _buildCreatorHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.45), width: 2),
            boxShadow: [BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 0)],
          ),
          child: const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.darkCardBg,
            child: Icon(Icons.person, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ${widget.debate.creatorId.substring(0, 8)}',
                style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            Text(timeago.format(widget.debate.createdAt).toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary)),
          ],
        ),
        const Spacer(),
        if (widget.debate.status == 'active') _buildLiveIndicator(),
      ],
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: AppColors.errorRed, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text('LIVE',
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.errorRed, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildAdvancedVoteSection(VoteState voteState) {
    final userVote = voteState.userVote;
    final total = _displayUpvotes + _displayDownvotes;
    final agreePercent = total == 0 ? 0.5 : _displayUpvotes / total;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ScaleTransition(
                scale: _voteButtonScale,
                child: VerzButton(
                  text: 'AGREE',
                  isOutlined: userVote != 1,
                  backgroundColor: AppColors.accentTeal,
                  onPressed: voteState.isLoading
                      ? null
                      : () {
                          _voteAnimationController.forward().then((_) {
                            _voteAnimationController.reverse();
                          });
                          ref
                              .read(voteProvider('debate:${widget.debate.id}')
                                  .notifier)
                              .castVote(1);
                        },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ScaleTransition(
                scale: _voteButtonScale,
                child: VerzButton(
                  text: 'DISAGREE',
                  isOutlined: userVote != -1,
                  backgroundColor: AppColors.errorRed,
                  onPressed: voteState.isLoading
                      ? null
                      : () {
                          _voteAnimationController.forward().then((_) {
                            _voteAnimationController.reverse();
                          });
                          ref
                              .read(voteProvider('debate:${widget.debate.id}')
                                  .notifier)
                              .castVote(-1);
                        },
                ),
              ),
            ),
          ],
        ),
        if (voteState.error != null) ...[
          const SizedBox(height: 10),
          Text(
            voteState.error!,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.errorRed),
          ),
        ],
        const SizedBox(height: 32),
        // Professional vote visualization
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(agreePercent * 100).toInt()}% AGREE',
                    style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.accentTeal,
                        fontWeight: FontWeight.w600)),
                Text('${((1 - agreePercent) * 100).toInt()}% DISAGREE',
                    style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: agreePercent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accentTeal,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.accentTeal
                                  .withValues(alpha: 0.25),
                              blurRadius: 10,
                              spreadRadius: 1),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }



  Widget _buildCommentItem(Comment comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surfaceLight,
              child: Icon(Icons.person, size: 16, color: AppColors.textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('User ${comment.userId.substring(0, 8)}', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold)),
                      if (comment.side != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: comment.side == 'agree'
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: comment.side == 'agree' ? AppColors.success : AppColors.error,
                            ),
                          ),
                          child: Text(
                            comment.side!.toUpperCase(),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: comment.side == 'agree' ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(timeago.format(comment.createdAt), style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(comment.content, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('👍 ${comment.upvotes}', style: AppTextStyles.labelSmall),
            const SizedBox(width: 16),
            Text('👎 ${comment.downvotes}', style: AppTextStyles.labelSmall),
            const SizedBox(width: 16),
            if (comment.replyCount > 0)
              Text('💬 ${comment.replyCount}', style: AppTextStyles.labelSmall),
          ],
        ),
      ],
    );
  }

  Widget _buildNoComments() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.surfaceLight),
          const SizedBox(height: 16),
          Text('No arguments for this side yet. Be the first!', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildCommentsError(String error) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 40),
          const SizedBox(height: 10),
          Text(
            'Could not load comments',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => ref.read(commentProvider(widget.debate.id).notifier).fetchComments(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTabs(int agreeCount, int disagreeCount) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _commentTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _commentTabIndex == 0 ? AppColors.success.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('AGREE ($agreeCount)', style: AppTextStyles.labelSmall.copyWith(color: AppColors.success)),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _commentTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _commentTabIndex == 1 ? AppColors.error.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('DISAGREE ($disagreeCount)', style: AppTextStyles.labelSmall.copyWith(color: AppColors.error)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiVerdictCard() {
    final side = widget.debate.winningSide ?? 'tie';
    final sideColor = switch (side) {
      'agree' => AppColors.accentTeal,
      'disagree' => AppColors.errorRed,
      _ => AppColors.primaryYellow,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryYellow.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [BoxShadow(color: AppColors.primaryYellow.withValues(alpha: 0.08), blurRadius: 16, spreadRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primaryYellow, size: 18),
              const SizedBox(width: 8),
              Text('AI VERDICT', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryYellow, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sideColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sideColor),
                ),
                child: Text(
                  side.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(color: sideColor, fontSize: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(widget.debate.aiSummary!, style: AppTextStyles.bodyMedium.copyWith(height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildGlassCommentInput() {
    final isTextEmpty = _commentController.text.trim().isEmpty;
    
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: AppColors.darkCardBg,
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_commentPostError != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.errorRed, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _commentPostError!,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.errorRed),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _commentPostError = null),
                    child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: VerzTextField(
                  label: '',
                  hintText: _isCommentPosting
                      ? 'Posting...'
                      : (_commentTabIndex == 0 ? 'Argue for AGREE...' : 'Argue for DISAGREE...'),
                  controller: _commentController,
                  maxLines: 1,
                  enabled: !_isCommentPosting,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: isTextEmpty || _isCommentPosting
                      ? AppColors.primaryYellow.withValues(alpha: 0.5)
                      : AppColors.primaryYellow,
                  shape: BoxShape.circle,
                  boxShadow: isTextEmpty || _isCommentPosting
                      ? []
                      : [BoxShadow(color: AppColors.primaryYellow.withValues(alpha: 0.35), blurRadius: 14, spreadRadius: 0)],
                ),
                child: IconButton(
                  onPressed: (isTextEmpty || _isCommentPosting) ? null : _postComment,
                  icon: _isCommentPosting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlack.withValues(alpha: 0.7)),
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: AppColors.primaryBlack, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Report Debate', style: AppTextStyles.h3),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select a reason:'),
              const SizedBox(height: 12),
              ...['Spam', 'Harassment', 'Misinformation', 'Offensive Content', 'Other'].map((reason) => 
                ListTile(
                  title: Text(reason),
                  onTap: () {
                    reasonController.text = reason;
                    Navigator.pop(context);
                    _submitReport(reason);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _submitReport(String reason) {
    final reportTypeMap = {
      'Spam': ReportType.spam,
      'Harassment': ReportType.harassment,
      'Misinformation': ReportType.misinformation,
      'Offensive Content': ReportType.offensiveContent,
      'Other': ReportType.otherViolation,
    };
    ref.read(reportProvider.notifier).reportContent(
      targetId: widget.debate.id,
      targetType: 'debate',
      reportType: reportTypeMap[reason] ?? ReportType.otherViolation,
      description: 'User reported this debate as $reason',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for reporting. Our team will review this.')),
    );
  }

}
