import 'package:flutter/material.dart';
import '../../core/glass_kit.dart';
import '../../core/tokens.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final theme = Theme.of(context);
    final c = IosColors.of(context);
    final faqs = zh ? _zh : _en;

    return GlassScaffold(
      appBar: AppBar(title: Text(zh ? '使用說明' : 'Help')),
      body: ListView(
        padding: const EdgeInsets.only(top: Gap.sm, bottom: 40),
        children: [
          for (final f in faqs) ...[
            SectionHeader(f.$1),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: Gap.lg),
              padding: const EdgeInsets.all(Gap.lg),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(Radii.card),
              ),
              child: Text(
                f.$2,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: c.labelSecondary, height: 1.45),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static const _zh = [
    ('資料存在哪裡?', '所有習慣與打卡紀錄只存在這支手機的本機資料庫,沒有雲端同步。解除安裝 App 會刪除資料,請定期到「設定」匯出備份。'),
    ('怎麼補打卡?', '點進習慣詳情頁,在日曆選擇過去的日期,再按「補打卡」。未來的日期不能選。'),
    ('怎麼刪除習慣?', '在「今天」頁面把卡片往右滑即可刪除,頂部會出現「復原」按鈕。想保留紀錄但不再顯示,請改用封存。'),
    ('每日目標是什麼?', '習慣可以設定每天要完成 1 到 20 次。達到目標次數才算當天完成。'),
    ('連續天數怎麼算?', '只計算排程日。休息日沒有打卡不會中斷連續天數。'),
    ('怎麼換手機?', '在舊手機「設定」匯出備份檔,傳到新手機後,在新手機「設定」選擇匯入。'),
  ];

  static const _en = [
    ('Where is my data?', 'Habits and check-ins are stored only in this phone\'s local database. There is no cloud sync, and uninstalling the app deletes the data. Export a backup from Settings regularly.'),
    ('How do I make up a missed day?', 'Open a habit, pick a past date on the calendar, then tap Make up. Future dates cannot be selected.'),
    ('How do I delete a habit?', 'Swipe the card to the right on the Today page. An Undo button appears at the top. To keep the history but hide the habit, archive it instead.'),
    ('What is the daily target?', 'A habit can require 1 to 20 completions per day. The day counts as done once the target is reached.'),
    ('How is the streak counted?', 'Only scheduled days count. Missing a rest day does not break your streak.'),
    ('How do I move to a new phone?', 'Export a backup from Settings on the old phone, copy the file over, then import it from Settings on the new phone.'),
  ];
}
