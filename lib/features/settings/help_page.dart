import 'package:flutter/material.dart';
import '../../core/glass_kit.dart';
import '../../core/strings.dart';
import '../../core/settings_strings.dart';
import '../../core/tokens.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = IosColors.of(context);

    return GlassScaffold(
      appBar: AppBar(title: Text(s.helpPageTitle)),
      body: ListView(
        padding: const EdgeInsets.only(top: Gap.sm, bottom: 40),
        children: [
          for (final (q, a) in s.faqs) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.md),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(Radii.card),
              ),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                // 去掉 ExpansionTile 預設的上下分隔線
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: Gap.lg),
                  childrenPadding:
                      const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  title: Text(
                    q,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  children: [
                    Text(
                      a,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: c.labelSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
