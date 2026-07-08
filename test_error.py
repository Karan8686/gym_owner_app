import re

with open("lib/features/members/presentation/member_detail_controller.dart", "r") as f:
    content = f.read()

content = re.sub(
    r"Future<MemberDetailData> _fetchAll\(String memberId\) async \{",
    """Future<MemberDetailData> _fetchAll(String memberId) async {
    try {""",
    content
)

content = re.sub(
    r"      payments: results\[2\] as List<PaymentSummary>,\n    \);\n  \}",
    """      payments: results[2] as List<PaymentSummary>,
    );
    } catch (e, stack) {
      print('ERROR IN FETCH ALL: $e\\n$stack');
      rethrow;
    }
  }""",
    content
)

with open("lib/features/members/presentation/member_detail_controller.dart", "w") as f:
    f.write(content)
