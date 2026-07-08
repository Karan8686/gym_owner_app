import re

with open("lib/features/members/data/members_repository.dart", "r") as f:
    content = f.read()

# Add import
if "package:uuid/uuid.dart" not in content:
    content = content.replace(
        "import 'package:gym_owner_app/core/config/supabase_config.dart';",
        "import 'package:gym_owner_app/core/config/supabase_config.dart';\nimport 'package:uuid/uuid.dart';"
    )

# createMember -> memberships insert
content = re.sub(
    r"final membershipResponse = await supabase.from\('memberships'\).insert\(\{",
    "final membershipId = const Uuid().v4();\n    final membershipResponse = await supabase.from('memberships').insert({\n      'id': membershipId,",
    content,
    count=1
)
# change final membershipId = membershipResponse['id'] as String; to just use membershipId
content = re.sub(
    r"final membershipId = membershipResponse\['id'\] as String;",
    "// membershipId already defined",
    content,
    count=1
)

# createMember -> payments insert
content = re.sub(
    r"await supabase.from\('payments'\).insert\(\{",
    "await supabase.from('payments').insert({\n      'id': const Uuid().v4(),",
    content,
    count=1
)

# renewMembership -> memberships insert
content = re.sub(
    r"final membershipResponse = await supabase.from\('memberships'\).insert\(\{",
    "final membershipId = const Uuid().v4();\n    final membershipResponse = await supabase.from('memberships').insert({\n      'id': membershipId,",
    content,
    count=1
)
# change final membershipId = membershipResponse['id'] as String; to just use membershipId
content = re.sub(
    r"final membershipId = membershipResponse\['id'\] as String;",
    "// membershipId already defined",
    content,
    count=1
)

# renewMembership -> payments insert
content = re.sub(
    r"await supabase.from\('payments'\).insert\(\{",
    "await supabase.from('payments').insert({\n      'id': const Uuid().v4(),",
    content,
    count=1
)

with open("lib/features/members/data/members_repository.dart", "w") as f:
    f.write(content)
