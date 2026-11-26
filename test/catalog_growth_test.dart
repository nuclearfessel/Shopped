import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopped/data/database.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('new generic items and brands are searchable', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    final eggplant = await db.searchCatalog('eggplant');
    expect(eggplant.map((item) => item.name), contains('Eggplant'));

    final weet = await db.searchCatalog('weet');
    expect(weet.map((item) => item.name), contains('Weetabix'));
    expect(
      weet.firstWhere((item) => item.name == 'Weetabix').parentName,
      'Cereal',
    );
  });

  test('expanded multi-word grocery names are searchable', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    const names = [
      'Chicken breast',
      'Salmon fillet',
      'Bell pepper',
      'Sweet potato',
      'Sourdough bread',
      'Mac and cheese',
      'Tomato sauce',
      'Plastic wrap',
      'Greek yoghurt',
    ];
    for (final name in names) {
      final hits = await db.searchCatalog(name);
      expect(hits.map((item) => item.name), contains(name), reason: name);
    }
  });

  test(
    'regular, East Asian, Southeast Asian, and South Asian produce search',
    () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);

      final bananas = await db.searchCatalog('regular bananas');
      expect(bananas.map((item) => item.name), contains('Regular bananas'));
      expect(
        bananas.firstWhere((item) => item.name == 'Regular bananas').parentName,
        'Bananas',
      );

      final nonOrganic = await db.searchCatalog('non-organic spinach');
      expect(
        nonOrganic.map((item) => item.name),
        contains('Non-organic spinach'),
      );

      final shiso = await db.searchCatalog('shiso');
      expect(shiso.map((item) => item.name), contains('Shiso'));
      expect(
        shiso.firstWhere((item) => item.name == 'Shiso').parentName,
        'East Asian herbs',
      );

      final thaiBasil = await db.searchCatalog('thai basil');
      expect(thaiBasil.map((item) => item.name), contains('Thai basil'));
      expect(
        thaiBasil.firstWhere((item) => item.name == 'Thai basil').parentName,
        'Southeast Asian herbs',
      );

      final curry = await db.searchCatalog('curry leaves');
      expect(curry.map((item) => item.name), contains('Curry leaves'));
      expect(
        curry.firstWhere((item) => item.name == 'Curry leaves').parentName,
        'South Asian herbs',
      );

      final bitter = await db.searchCatalog('bitter melon');
      expect(bitter.map((item) => item.name), contains('Bitter melon'));

      final drumstick = await db.searchCatalog('drumstick');
      expect(drumstick.map((item) => item.name), contains('Drumsticks'));

      final kkaennip = await db.searchCatalog('kkaennip');
      expect(kkaennip.map((item) => item.name), contains('Kkaennip'));

      final daunSalam = await db.searchCatalog('daun salam');
      expect(daunSalam.map((item) => item.name), contains('Daun salam'));

      final gongura = await db.searchCatalog('gongura');
      expect(gongura.map((item) => item.name), contains('Gongura'));

      final alphonso = await db.searchCatalog('alphonso');
      expect(alphonso.map((item) => item.name), contains('Alphonso mango'));

      final mangosteen = await db.searchCatalog('mangosteen');
      expect(mangosteen.map((item) => item.name), contains('Mangosteen SEA'));

      final yuzu = await db.searchCatalog('yuzu fruit');
      expect(yuzu.map((item) => item.name), contains('Yuzu fruit'));
    },
  );

  test('Ghirardelli, Tillamook, and ice cream brands are searchable', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    final ghirardelli = await db.searchCatalog('ghirardelli');
    expect(
      ghirardelli.map((item) => item.name),
      containsAll([
        'Ghirardelli chips',
        'Ghirardelli squares',
        'Ghirardelli brownie mix',
        'Ghirardelli hot chocolate',
      ]),
    );

    final tillamook = await db.searchCatalog('tillamook');
    expect(
      tillamook.map((item) => item.name),
      containsAll([
        'Tillamook cheddar',
        "Tillamook Maker's Reserve",
        'Tillamook ice cream',
        'Tillamook marionberry pie',
        'Tillamook extra creamy salted butter',
        'Tillamook extra creamy unsalted butter',
      ]),
    );

    final organic = await db.searchCatalog('organic valley');
    expect(
      organic.map((item) => item.name),
      containsAll([
        'Organic Valley whole milk',
        'Organic Valley sharp cheddar',
        'Organic Valley salted butter',
        'Organic Valley sour cream',
        'Organic Valley ghee',
        'Organic Valley string cheese',
      ]),
    );

    final haagen = await db.searchCatalog('haagen');
    expect(
      haagen.map((item) => item.name),
      containsAll([
        'Haagen-Dazs vanilla',
        'Haagen-Dazs butter pecan',
        'Haagen-Dazs matcha',
      ]),
    );

    final ben = await db.searchCatalog('jerry');
    expect(
      ben.map((item) => item.name),
      containsAll([
        "Ben & Jerry's Cherry Garcia",
        "Ben & Jerry's Chunky Monkey",
        "Ben & Jerry's The Tonight Dough",
      ]),
    );
  });

  test('generic grocery names are searchable without a brand', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    final chocolateMilk = await db.searchCatalog('chocolate milk');
    expect(chocolateMilk.map((item) => item.name), contains('Chocolate milk'));
    expect(
      chocolateMilk
          .firstWhere((item) => item.name == 'Chocolate milk')
          .parentName,
      'Milk',
    );

    final iceCream = await db.searchCatalog('rocky road ice cream');
    expect(iceCream.map((item) => item.name), contains('Rocky road ice cream'));
    expect(
      iceCream
          .firstWhere((item) => item.name == 'Rocky road ice cream')
          .parentName,
      'Ice cream',
    );

    final bagels = await db.searchCatalog('everything bagels');
    expect(bagels.map((item) => item.name), contains('Everything bagels'));

    final applesauce = await db.searchCatalog('applesauce');
    expect(applesauce.map((item) => item.name), contains('Applesauce'));
  });

  test('everyday generic groceries cover the departments', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    final rows = await db.select(db.catalogItems).get();
    expect(rows.length, greaterThan(6500));

    const names = [
      'Gruyere',
      'Queso fresco',
      'Gochujang',
      'Panko breadcrumbs',
      'Mahi mahi',
      'Andouille sausage',
      'Fresh rhubarb',
      'Phyllo dough',
      'Chili crisp',
      'Dry black beans',
      'Canned chicken',
      'Turkey drumsticks',
    ];
    for (final name in names) {
      final hits = await db.searchCatalog(name);
      expect(hits.map((item) => item.name), contains(name), reason: name);
    }
  });

  test('Coca-Cola, PepsiCo, and Gatorade drinks are searchable', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    final coke = await db.searchCatalog('coke zero sugar');
    expect(
      coke.map((item) => item.name),
      containsAll(['Coke Zero Sugar', 'Coke Zero Sugar mini cans']),
    );
    expect(
      coke.firstWhere((item) => item.name == 'Coke Zero Sugar').parentName,
      'Soft drinks',
    );

    final cocaCola = await db.searchCatalog('coca-cola zero');
    expect(
      cocaCola.map((item) => item.name),
      contains('Coca-Cola Zero Sugar'),
    );

    final pepsi = await db.searchCatalog('diet pepsi');
    expect(
      pepsi.map((item) => item.name),
      containsAll(['Diet Pepsi', 'Diet Pepsi mini cans']),
    );

    final sprite = await db.searchCatalog('sprite zero');
    expect(
      sprite.map((item) => item.name),
      containsAll(['Sprite Zero', 'Sprite Zero Sugar', 'Sprite Zero Sugar mini cans']),
    );

    final dew = await db.searchCatalog('mountain dew zero');
    expect(
      dew.map((item) => item.name),
      containsAll([
        'Mountain Dew Zero Sugar',
        'Mountain Dew Zero Sugar mini cans',
      ]),
    );

    final tropicana = await db.searchCatalog('tropicana');
    expect(
      tropicana.map((item) => item.name),
      containsAll([
        'Tropicana',
        'Tropicana orange juice',
        'Tropicana mini bottles',
        'Tropicana Zero Sugar',
      ]),
    );
    expect(
      tropicana
          .firstWhere((item) => item.name == 'Tropicana orange juice')
          .parentName,
      'Juice',
    );

    final minuteMaid = await db.searchCatalog('minute maid');
    expect(
      minuteMaid.map((item) => item.name),
      containsAll([
        'Minute Maid',
        'Minute Maid orange juice',
        'Minute Maid Zero Sugar',
        'Minute Maid mini bottles',
      ]),
    );

    final gatorade = await db.searchCatalog('gatorade');
    expect(
      gatorade.map((item) => item.name),
      containsAll([
        'Gatorade',
        'Gatorade Zero',
        'Gatorade mini bottles',
        'Gatorade Zero mini bottles',
        'Gatorade Lemon Lime',
      ]),
    );
    expect(
      gatorade.firstWhere((item) => item.name == 'Gatorade Zero').parentName,
      'Energy & sports',
    );

    final powerade = await db.searchCatalog('powerade zero');
    expect(
      powerade.map((item) => item.name),
      containsAll(['Powerade Zero', 'Powerade Zero Sugar']),
    );

    final mini = await db.searchCatalog('coca-cola mini cans');
    expect(
      mini.map((item) => item.name),
      containsAll([
        'Coca-Cola mini cans',
        'Coca-Cola mini cans 6-pack',
        'Coca-Cola mini cans 12-pack',
        'Coca-Cola mini cans 24-pack',
        'Coca-Cola mini cans 12 pk',
      ]),
    );

    final pepsiMini = await db.searchCatalog('pepsi mini cans 12');
    expect(
      pepsiMini.map((item) => item.name),
      containsAll([
        'Pepsi mini cans 12-pack',
        'Pepsi mini cans 12 pk',
      ]),
    );

    final dietCokePack = await db.searchCatalog('diet coke mini 24-pack');
    expect(
      dietCokePack.map((item) => item.name),
      containsAll([
        'Diet Coke mini cans 24-pack',
        'Diet Coke mini 24-pack',
      ]),
    );

    final zeroPack = await db.searchCatalog('coke zero sugar mini cans 6');
    expect(
      zeroPack.map((item) => item.name),
      containsAll([
        'Coke Zero Sugar mini cans 6-pack',
        'Coke Zero Sugar mini cans 6 pk',
      ]),
    );
  });

  test('Darigold dairy products are searchable', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    final darigold = await db.searchCatalog('darigold');
    expect(
      darigold.map((item) => item.name),
      containsAll([
        'Darigold whole milk',
        'Darigold 2% milk',
        'Darigold 1% milk',
        'Darigold fat-free milk',
        'Darigold lactose-free whole milk',
        'Darigold organic whole milk',
        'Darigold ultra-filtered chocolate milk',
        'Darigold Nutrition+ milk',
        'Darigold chocolate milk',
        'Darigold old fashioned chocolate milk',
        'Darigold strawberry milk',
        'Darigold FIT chocolate milk',
        'Darigold chocolate protein shake',
        'Darigold vanilla protein shake',
        'Darigold classic eggnog',
        'Darigold old fashioned eggnog',
        'Darigold salted butter',
        'Darigold unsalted butter',
        'Darigold half and half',
        'Darigold fat-free half and half',
        'Darigold heavy whipping cream',
        'Darigold whipping cream',
        'Darigold Dari Whip',
        'Darigold sour cream',
        'Darigold Mexican style sour cream',
        'Darigold cottage cheese',
        'Darigold large curd cottage cheese',
        'Darigold low fat cottage cheese',
        'Darigold French vanilla creamer',
        'Darigold sweet cream creamer',
        'Darigold caramel creamer',
        'Darigold hazelnut creamer',
      ]),
    );
    expect(
      darigold
          .firstWhere((item) => item.name == 'Darigold whole milk')
          .parentName,
      'Milk',
    );
    expect(
      darigold
          .firstWhere((item) => item.name == 'Darigold French vanilla creamer')
          .parentName,
      'Creamer',
    );
  });

  test('a parent query does not list every brand', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    final cereal = await db.searchCatalog('cereal');
    final unmatched = cereal.where(
      (item) =>
          item.parentName == 'Cereal' &&
          !item.name.toLowerCase().contains('cereal'),
    );
    expect(unmatched.length, lessThanOrEqualTo(8));
    expect(cereal.map((item) => item.name), isNot(contains('Weetabix')));
    expect(
      (await db.searchCatalog('weetabix')).map((item) => item.name),
      contains('Weetabix'),
    );
  });

  test('upgrading adds missing built-ins without duplicating names', () async {
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'shopped-catalog-${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    addTearDown(() async {
      if (await file.exists()) await file.delete();
    });

    final first = AppDatabase(NativeDatabase(file));
    await first.customSelect('select 1').get();
    await (first.delete(
      first.catalogItems,
    )..where((t) => t.name.equals('Weetabix'))).go();
    await first
        .into(first.catalogItems)
        .insert(
          CatalogItemsCompanion.insert(
            name: 'Kombucha',
            category: 'Beverages',
            isCustom: const Value(true),
          ),
        );
    final milkBefore = await (first.select(
      first.catalogItems,
    )..where((t) => t.name.equals('Milk'))).get();
    expect(milkBefore, hasLength(1));
    await first.customStatement('PRAGMA user_version = 10');
    await first.close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);
    await upgraded.customSelect('select 1').get();

    final rows =
        await (upgraded.select(upgraded.catalogItems)..where(
              (t) =>
                  t.name.equals('Milk') |
                  t.name.equals('Weetabix') |
                  t.name.equals('Kombucha'),
            ))
            .get();
    expect(rows.where((row) => row.name == 'Milk'), hasLength(1));
    expect(rows.where((row) => row.name == 'Weetabix'), hasLength(1));
    expect(rows.singleWhere((row) => row.name == 'Kombucha').isCustom, isTrue);
  });
}
