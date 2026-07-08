import re

with open("lib/features/members/presentation/member_detail_screen.dart", "r") as f:
    content = f.read()

content = re.sub(
    r'"Couldn\'t load member details\.",',
    'error.toString(),',
    content
)

with open("lib/features/members/presentation/member_detail_screen.dart", "w") as f:
    f.write(content)
