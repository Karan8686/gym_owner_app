import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/theme.dart';
import '../../domain/membership.dart';
import '../../data/members_repository.dart';

class MemberCard extends StatefulWidget {
  final MemberWithMembership item;
  final bool isExpiredTab;

  const MemberCard({
    super.key,
    required this.item,
    this.isExpiredTab = false,
  });

  @override
  State<MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<MemberCard> {
  bool _isExpanded = false;

  void _sendWhatsAppMessage() async {
    final member = widget.item.member;
    final membership = widget.item.latestMembership;
    
    var phone = member.phoneNo.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.length == 10) phone = '91$phone';

    final dueDateStr = membership != null 
        ? DateFormat('d-M-yyyy').format(membership.dueDate) 
        : 'N/A';

    final message = '''Hi ${member.name},
This is a reminder that your Gym Membership Fee is due on $dueDateStr.
Please make your payment online or at the front desk to avoid any interruption in your membership.

In case you have already paid the fee, please inform the front desk.
If you are not coming to the gym, please reply to this message.

Thank You,
FitTrack''';

    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$phone?text=$encodedMessage');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error launching WhatsApp: $e");
    }
  }

  Widget _buildInfoItem(String label, String value, Color valueColor, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.inkSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final item = widget.item;
    final member = item.member;
    final membership = item.latestMembership;
    final days = item.daysRemaining;
    
    final isExpired = membership?.status == MembershipStatus.expired;
    final daysColor = (days != null && days <= 7)
        ? AppColors.signal
        : AppColors.inkPrimary;

    final planName = membership?.planType.toUpperCase() ?? 'N/A';
    final priceCharged = membership != null ? '₹${membership.priceCharged.toStringAsFixed(0)}' : 'N/A';

    int? daysInactive;
    if (isExpired && membership != null) {
      daysInactive = DateTime.now().difference(membership.dueDate).inDays;
    }
        
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: ClipOval(
                      child: (member.photoUrl != null && member.photoUrl!.isNotEmpty)
                          ? Image.network(
                              member.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) => _buildFallbackAvatar(),
                            )
                          : _buildFallbackAvatar(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Plan: $planName',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (isExpired && daysInactive != null)
                          Text(
                            'Inactive: $daysInactive days',
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.signal,
                            ),
                          )
                        else if (days != null)
                          Text(
                            '$days days remaining',
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: daysColor,
                            ),
                          )
                        else
                          Text(
                            'No active plan',
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.inkSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isExpired && widget.isExpiredTab)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          color: AppColors.inkSecondary,
                          tooltip: 'Renew Membership',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            context.push('/members/${member.id}/renew');
                          },
                        ),
                        const SizedBox(width: 12),
                        if (member.phoneNo.isNotEmpty)
                          IconButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.whatsapp,
                              size: 20,
                            ),
                            color: const Color(0xFF25D366),
                            tooltip: 'Send WhatsApp',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _sendWhatsAppMessage,
                          ),
                      ],
                    )
                  else if (days != null && !isExpired)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          days.toString(),
                          style: AppText.display.copyWith(
                            color: daysColor,
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          'DAYS',
                          style: AppText.label.copyWith(
                            color: AppColors.inkSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (_isExpanded && membership != null) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Membership Fee',
                          priceCharged,
                          AppColors.inkPrimary,
                          textTheme,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          isExpired ? 'Days Inactive' : 'Days Remaining',
                          isExpired ? (daysInactive?.toString() ?? 'N/A') : (days?.toString() ?? 'N/A'),
                          isExpired ? AppColors.signal : AppColors.inkPrimary,
                          textTheme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          isExpired ? 'Expired On' : 'Due Date',
                          DateFormat('d MMM yyyy').format(membership.dueDate),
                          isExpired ? AppColors.signal : AppColors.inkPrimary,
                          textTheme,
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => context.push('/members/${member.id}'),
                            icon: const Icon(Icons.person_outline, size: 16, color: AppColors.inkPrimary),
                            label: Text(
                              'Full Profile',
                              style: textTheme.bodySmall?.copyWith(color: AppColors.inkPrimary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    final member = widget.item.member;
    return Container(
      color: AppColors.inkPrimary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
          style: AppText.headline.copyWith(
            color: AppColors.inkPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
