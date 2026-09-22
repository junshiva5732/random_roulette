import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// 앱 문자열 (en / ko / ja / zh). 기본은 시스템 언어를 따르고(미지원 언어는 영어),
/// 홈 화면의 언어 설정으로 바꿀 수 있다 ([LocaleController]).
///
/// 새 언어를 추가하려면 [supported] 와 [nativeName] 에 로케일을 넣고 [_t] 에 인자를 추가한다.
class S {
  final Locale locale;
  const S(this.locale);

  static S of(BuildContext context) => Localizations.of<S>(context, S)!;
  static const LocalizationsDelegate<S> delegate = _SDelegate();
  static const supported = [Locale('en'), Locale('ko'), Locale('ja'), Locale('zh')];

  /// 시스템 언어를 지원 로케일로 맞춘다 (미지원이면 영어).
  static Locale resolve(Locale? l) =>
      supported.firstWhere((s) => s.languageCode == l?.languageCode, orElse: () => supported.first);

  /// 언어 선택 목록에 각 언어의 자기 이름으로 표시.
  static String nativeName(Locale l) => switch (l.languageCode) {
        'ko' => '한국어',
        'ja' => '日本語',
        'zh' => '简体中文',
        _ => 'English',
      };

  String _t(String en, String ko, String ja, String zh) => switch (locale.languageCode) {
        'ko' => ko,
        'ja' => ja,
        'zh' => zh,
        _ => en,
      };

  String get appTitle => _t('Random Roulette', '랜덤 룰렛', 'ランダムルーレット', '随机转盘');
  String get subtitle => _t('Spin to decide', '돌려서 정하자', '回して決めよう', '转一转，做决定');

  // 홈
  String get newRoulette => _t('New roulette', '새 룰렛', '新しいルーレット', '新转盘');
  String itemCount(int n) => _t('$n items', '항목 $n개', '$n項目', '$n 项');
  String get edit => _t('Edit', '편집', '編集', '编辑');
  String get duplicate => _t('Duplicate', '복제', '複製', '复制');
  String get delete => _t('Delete', '삭제', '削除', '删除');
  String get deleteTitle => _t('Delete roulette?', '룰렛을 삭제할까요?', 'ルーレットを削除しますか？', '删除转盘？');
  String deleteBody(String title) => _t(
        '"$title" will be removed. This cannot be undone.',
        '"$title" 이(가) 삭제됩니다. 되돌릴 수 없어요.',
        '「$title」が削除されます。元に戻せません。',
        '“$title”将被删除，无法撤销。',
      );
  String get emptyHome => _t(
        'No roulettes yet.\nTap + to make one.',
        '아직 룰렛이 없어요.\n+ 를 눌러 만들어 보세요.',
        'ルーレットがまだありません。\n＋をタップして作りましょう。',
        '还没有转盘。\n点击 + 创建一个。',
      );
  String get copySuffix => _t(' (copy)', ' (복사본)', '（コピー）', '（副本）');
  String get language => _t('Language', '언어', '言語', '语言');
  String get systemLanguage => _t('System default', '시스템 기본', 'システムの設定', '跟随系统');
  String get howToUse => _t('How to use', '사용 방법', '使い方', '使用方法');
  String get cancel => _t('Cancel', '취소', 'キャンセル', '取消');
  String get ok => _t('OK', '확인', 'OK', '确定');
  String get save => _t('Save', '저장', '保存', '保存');
  String get close => _t('Close', '닫기', '閉じる', '关闭');
  String get watchAd => _t('Watch ad', '광고 보기', '広告を見る', '观看广告');
  String get helpBody => _t(
        'Pick a roulette from the list and tap SPIN (or the wheel).\n\n'
            'Make your own roulette with +: give it a title and add 2 to 20 items. '
            'Long-press a roulette to edit, duplicate or delete it.\n\n'
            'On the wheel screen, turn on "Remove winner" to take the picked item out until you reset — '
            'handy for deciding an order or picking several people.\n\n'
            'Change the wheel colors from the palette icon. Some themes are unlocked by watching a short ad.',
        '목록에서 룰렛을 고르고 SPIN 버튼(또는 룰렛)을 누르세요.\n\n'
            '+ 로 나만의 룰렛을 만들 수 있어요. 제목을 정하고 항목을 2~20개 넣으면 끝. '
            '룰렛을 길게 누르면 편집·복제·삭제할 수 있어요.\n\n'
            '룰렛 화면의 "당첨 항목 제외"를 켜면 뽑힌 항목이 초기화 전까지 빠집니다. '
            '순서를 정하거나 여러 명을 뽑을 때 편해요.\n\n'
            '팔레트 아이콘으로 룰렛 색상을 바꿀 수 있어요. 일부 테마는 짧은 광고를 보면 열립니다.',
        'リストからルーレットを選んで SPIN（またはルーレット）をタップ。\n\n'
            '＋で自分のルーレットを作れます。タイトルを決めて項目を2〜20個入れるだけ。'
            'ルーレットを長押しすると編集・複製・削除できます。\n\n'
            'ルーレット画面の「当たりを除外」をオンにすると、選ばれた項目はリセットするまで外れます。'
            '順番決めや複数人を選ぶときに便利です。\n\n'
            'パレットアイコンでルーレットの色を変更できます。一部のテーマは短い広告を見ると開きます。',
        '从列表中选择转盘，点击 SPIN（或转盘）。\n\n'
            '点击 + 创建自己的转盘：填写标题，添加 2 到 20 个选项即可。'
            '长按转盘可编辑、复制或删除。\n\n'
            '在转盘页面打开“移除中奖项”，被选中的选项会在重置前退出——'
            '决定顺序或挑选多人时很方便。\n\n'
            '通过调色板图标更换转盘配色。部分主题观看一段短广告即可解锁。',
      );

  // 편집
  String get editRoulette => _t('Edit roulette', '룰렛 편집', 'ルーレットを編集', '编辑转盘');
  String get title => _t('Title', '제목', 'タイトル', '标题');
  String get titleHint => _t('e.g. What to eat?', '예: 오늘 점심 뭐 먹지?', '例: 今日のランチは？', '例如：今天吃什么？');
  String get items => _t('Items', '항목', '項目', '选项');
  String get addItem => _t('Add item', '항목 추가', '項目を追加', '添加选项');
  String itemHint(int n) => _t('Item $n', '항목 $n', '項目 $n', '选项 $n');
  String get needTitle => _t('Enter a title.', '제목을 입력하세요.', 'タイトルを入力してください。', '请输入标题。');
  String needItems(int min) => _t(
        'Add at least $min items.',
        '항목을 $min개 이상 입력하세요.',
        '項目を$min個以上入力してください。',
        '请至少添加 $min 个选项。',
      );
  String maxItems(int max) => _t('Up to $max items.', '최대 $max개까지 가능해요.', '最大$max個までです。', '最多 $max 个选项。');
  String get discardTitle => _t('Discard changes?', '변경 내용을 버릴까요?', '変更を破棄しますか？', '放弃更改？');
  String get discard => _t('Discard', '버리기', '破棄', '放弃');
  String get shuffle => _t('Shuffle', '섞기', 'シャッフル', '打乱');

  // 룰렛
  String get spin => 'SPIN';
  String get spinning => _t('Spinning…', '돌아가는 중…', '回転中…', '旋转中…');
  String get result => _t('Result', '결과', '結果', '结果');
  String get spinAgain => _t('Spin again', '다시 돌리기', 'もう一回', '再转一次');
  String get removeWinner => _t('Remove winner', '당첨 항목 제외', '当たりを除外', '移除中奖项');
  String get reset => _t('Reset', '초기화', 'リセット', '重置');
  String remaining(int n, int total) => _t('$n of $total left', '$total개 중 $n개 남음', '残り $n / $total', '剩余 $n / $total');
  String get allPicked => _t(
        'All items have been picked. Reset to spin again.',
        '모든 항목이 뽑혔어요. 초기화하면 다시 돌릴 수 있어요.',
        'すべての項目が選ばれました。リセットするともう一度回せます。',
        '所有选项都已选中。重置后可再次旋转。',
      );
  String get history => _t('History', '기록', '履歴', '记录');
  String get clearHistory => _t('Clear', '지우기', '消去', '清除');
  String get theme => _t('Wheel theme', '룰렛 테마', 'ルーレットのテーマ', '转盘主题');
  String themeName(String id) => switch (id) {
        'classic' => _t('Classic', '클래식', 'クラシック', '经典'),
        'pastel' => _t('Pastel', '파스텔', 'パステル', '马卡龙'),
        'neon' => _t('Neon', '네온', 'ネオン', '霓虹'),
        'sunset' => _t('Sunset', '선셋', 'サンセット', '日落'),
        'forest' => _t('Forest', '포레스트', 'フォレスト', '森林'),
        'ocean' => _t('Ocean', '오션', 'オーシャン', '海洋'),
        _ => id,
      };
  String get unlockTitle => _t('Unlock theme', '테마 잠금 해제', 'テーマをアンロック', '解锁主题');
  String unlockBody(String name) => _t(
        'Watch a short ad to unlock "$name" forever.',
        '짧은 광고를 보면 "$name" 테마가 영구히 열립니다.',
        '短い広告を見ると「$name」テーマが永久にアンロックされます。',
        '观看一段短广告即可永久解锁“$name”主题。',
      );
  String get unlocked => _t('Theme unlocked!', '테마가 열렸어요!', 'テーマをアンロックしました！', '主题已解锁！');
  String get adNotReady => _t(
        'The ad is not ready yet. Please try again in a moment.',
        '광고를 아직 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
        '広告をまだ読み込めていません。しばらくしてからもう一度お試しください。',
        '广告尚未加载完成，请稍后再试。',
      );

  // 기본 제공 룰렛 (첫 실행 시 생성)
  List<(String, List<String>)> get presets => [
        (
          _t('What to eat?', '오늘 뭐 먹지?', '今日は何食べる？', '今天吃什么？'),
          _t(
            'Pizza,Burger,Sushi,Ramen,Salad,Tacos,Pasta,Fried chicken',
            '김치찌개,돈까스,치킨,피자,초밥,짜장면,파스타,햄버거',
            'ラーメン,カレー,寿司,パスタ,牛丼,ピザ,焼肉,うどん',
            '火锅,炒饭,拉面,寿司,披萨,烤肉,饺子,汉堡',
          ).split(','),
        ),
        (
          _t('Yes or No', '예 / 아니오', 'はい / いいえ', '是 / 否'),
          _t('Yes,No,Yes,No', '예,아니오,예,아니오', 'はい,いいえ,はい,いいえ', '是,否,是,否').split(','),
        ),
        (
          _t('Who pays?', '누가 쏠까?', '誰がおごる？', '谁请客？'),
          _t('Me,You,Split it,Rock-paper-scissors', '나,너,반반,가위바위보', '私,あなた,割り勘,じゃんけん', '我,你,AA,猜拳').split(','),
        ),
        (
          _t('Penalty', '벌칙', '罰ゲーム', '惩罚'),
          _t(
            'Sing a song,Do 10 push-ups,Dance,Tell a joke,Safe!,Truth or dare',
            '노래 한 곡,팔굽혀펴기 10개,춤추기,개인기,통과!,진실게임',
            '歌を歌う,腕立て10回,ダンス,一発芸,セーフ！,質問に答える',
            '唱首歌,10个俯卧撑,跳舞,讲笑话,安全！,真心话',
          ).split(','),
        ),
        (
          _t('Numbers 1–10', '숫자 1~10', '数字 1〜10', '数字 1–10'),
          List.generate(10, (i) => '${i + 1}'),
        ),
      ];
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) => S.supported.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<S> load(Locale locale) => SynchronousFuture(S(locale));

  @override
  bool shouldReload(_SDelegate old) => false;
}

/// 사용자가 고른 언어. null 이면 시스템 언어를 따른다. 값이 바뀌면 [MaterialApp] 이 다시 빌드된다.
class LocaleController extends ValueNotifier<Locale?> {
  LocaleController(super.value);

  static LocaleController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LocaleScope>()!.controller;

  /// 저장된 언어 코드 → 로케일. 지원하지 않는 코드는 무시(null).
  static Locale? fromCode(String? code) =>
      code == null ? null : S.supported.cast<Locale?>().firstWhere((l) => l!.languageCode == code, orElse: () => null);
}

/// [LocaleController] 를 위젯 트리에 내려보낸다.
class LocaleScope extends StatelessWidget {
  final LocaleController controller;
  final Widget child;
  const LocaleScope({super.key, required this.controller, required this.child});

  @override
  Widget build(BuildContext context) => _LocaleScope(controller: controller, child: child);
}

class _LocaleScope extends InheritedWidget {
  final LocaleController controller;
  const _LocaleScope({required this.controller, required super.child});

  @override
  bool updateShouldNotify(_LocaleScope old) => old.controller != controller;
}
