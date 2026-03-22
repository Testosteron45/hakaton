import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/venue.dart';

/// One-time seeder: uploads all venues from RTDB export to Firestore.
/// Call [seedIfEmpty] on app start — it's a no-op if venues already exist.
/// Call [seedMissingVenues] to add new venue groups without resetting the DB.
class VenueSeedService {
  VenueSeedService(this._firestore);

  final FirebaseFirestore _firestore;
  final _log = Logger();

  Future<void> seedIfEmpty() async {
    final snap = await _firestore.collection('venues').limit(1).get();

    if (snap.docs.isNotEmpty) return;

    _log.i('Seeding venues to Firestore...');

    final now = Timestamp.now();
    final batch = _firestore.batch();
    for (final v in _seedVenues) {
      final ref = _firestore.collection('venues').doc(v.id);
      batch.set(ref, {...v.toFirestore(), 'createdAt': now});
    }
    await batch.commit();
    _log.i('Seeded ${_seedVenues.length} venues.');
  }

  /// Adds venues from [candidates] that are not yet in Firestore.
  /// Safe to call on every start — only writes missing docs.
  Future<void> seedMissingVenues(List<Venue> candidates) async {
    final batch = _firestore.batch();
    var count = 0;
    final now = Timestamp.now();
    for (final v in candidates) {
      final doc = await _firestore.collection('venues').doc(v.id).get();
      if (!doc.exists) {
        batch.set(
          _firestore.collection('venues').doc(v.id),
          {...v.toFirestore(), 'createdAt': now},
        );
        count++;
      }
    }
    if (count > 0) {
      await batch.commit();
      _log.i('Seeded $count missing venues.');
    }
  }

  /// Re-stamps [createdAt] for all known seed venues with staggered dates
  /// based on their position in [_seedVenues] (index 0 = oldest).
  /// Call once to fix venues that were backfilled with identical timestamps.
  Future<void> restampSeedCreatedAt() async {
    final base = DateTime(2025, 1, 1);
    final batch = _firestore.batch();
    for (var i = 0; i < _seedVenues.length; i++) {
      final ref = _firestore.collection('venues').doc(_seedVenues[i].id);
      batch.update(ref, {
        'createdAt': Timestamp.fromDate(base.add(Duration(hours: i))),
      });
    }
    await batch.commit();
    _log.i('Restamped createdAt for ${_seedVenues.length} seed venues.');
  }

  /// Backfills [createdAt] for any venue doc that's missing the field.
  /// Known seed venues get staggered timestamps based on their seed order
  /// (later index = newer) so the feed has a meaningful stable order.
  /// Unknown docs get a single shared old timestamp.
  /// Safe to run repeatedly — skips docs that already have the timestamp.
  Future<void> backfillCreatedAt() async {
    final snap = await _firestore.collection('venues').get();
    final missing = snap.docs
        .where((d) => d.data()['createdAt'] == null)
        .toList();

    if (missing.isEmpty) return;

    // Base date far in the past so real user-added venues stay on top.
    final base = DateTime(2025, 1, 1);
    final idToIndex = {
      for (var i = 0; i < _seedVenues.length; i++) _seedVenues[i].id: i,
    };

    final batch = _firestore.batch();
    for (final doc in missing) {
      final idx = idToIndex[doc.id];
      final date = idx != null
          ? base.add(Duration(hours: idx))
          : base;
      batch.update(doc.reference, {'createdAt': Timestamp.fromDate(date)});
    }
    await batch.commit();
    _log.i('Backfilled createdAt for ${missing.length} venues.');
  }

  // ── Data ─────────────────────────────────────────────────────────────────────

  static final List<Venue> _seedVenues = [
    // ── Парки / Сады ──────────────────────────────────────────────────────────
  // ── Парки / Сады ──────────────────────────────────────────────────────────
    Venue(
      id: 'park_krasnodar',
      name: 'Парк «Краснодар»',
      description: 'Один из самых известных современных парков России, известный своими ландшафтными зонами, арт-объектами, прогулочными маршрутами и красивой вечерней подсветкой.',
      photoUrl: 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800',
      type: VenueType.park,
      distance: DistanceTag.near,
      group: GroupTag.family,
      price: PriceTag.budget,
      features: [VenueFeature.nature, VenueFeature.outdoor, VenueFeature.kids],
      address: 'ул. им. 40-летия Победы, 36, Краснодар',
      category: 'парк',
      tags: ['парк', 'прогулка', 'современная архитектура', 'семейный отдых', 'фотолокация', 'вечерние прогулки', 'достопримечательность'],
      lat: 45.0420453, lon: 39.0322848,
      mapUrl: 'https://yandex.ru/maps/?ll=39.0322848%2C45.0420453&z=17&whatshere%5Bpoint%5D=39.0322848%2C45.0420453&whatshere%5Bzoom%5D=17',
      rating: 4.8,
    ),
    Venue(
      id: 'park_japanese_garden',
      name: 'Японский сад',
      description: 'Живописный японский сад на территории парка «Краснодар» с мостиками, водоемами, каменными композициями и спокойной атмосферой.',
      photoUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=800',
      type: VenueType.park,
      distance: DistanceTag.near,
      group: GroupTag.couple,
      price: PriceTag.budget,
      features: [VenueFeature.romantic, VenueFeature.quiet, VenueFeature.nature, VenueFeature.outdoor],
      address: 'ул. им. 40-летия Победы, 36, Краснодар',
      category: 'сад',
      tags: ['японский сад', 'тихое место', 'ландшафтный дизайн', 'фотографии', 'романтическое место', 'природа', 'эстетика'],
      lat: 45.0434208, lon: 39.0368097,
      mapUrl: 'https://yandex.ru/maps/?ll=39.0368097%2C45.0434208&z=17&whatshere%5Bpoint%5D=39.0368097%2C45.0434208&whatshere%5Bzoom%5D=17',
      rating: 4.8,
    ),
    Venue(
      id: 'park_chistyakovskaya',
      name: 'Чистяковская роща',
      description: 'Одна из старейших зеленых зон Краснодара, подходящая для прогулок, отдыха с детьми и спокойного времяпрепровождения.',
      photoUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?w=800',
      type: VenueType.park,
      distance: DistanceTag.near,
      group: GroupTag.family,
      price: PriceTag.budget,
      features: [VenueFeature.nature, VenueFeature.outdoor, VenueFeature.kids, VenueFeature.quiet],
      address: 'ул. Зиповская, 5, Краснодар',
      category: 'парк',
      tags: ['парк', 'природа', 'семейный отдых', 'дети', 'прогулка', 'тень', 'тихий отдых'],
      lat: 45.058219, lon: 38.9957857,
      mapUrl: 'https://yandex.ru/maps/?ll=38.9957857%2C45.058219&z=17&whatshere%5Bpoint%5D=38.9957857%2C45.058219&whatshere%5Bzoom%5D=17',
      rating: 4.5,
    ),
    Venue(
      id: 'park_gorodskoy_sad',
      name: 'Городской сад',
      description: 'Классический городской парк с аллеями, аттракционами и атмосферой старого Краснодара.',
      photoUrl: 'https://images.unsplash.com/photo-1513836279014-a89f7a76ae86?w=800',
      type: VenueType.park,
      distance: DistanceTag.near,
      group: GroupTag.family,
      price: PriceTag.budget,
      features: [VenueFeature.nature, VenueFeature.outdoor, VenueFeature.kids],
      address: 'ул. Красная, 4, Краснодар',
      category: 'парк',
      tags: ['парк', 'аттракционы', 'семейный отдых', 'центр', 'прогулка', 'исторический парк', 'зеленая зона'],
      lat: 45.0113836, lon: 38.970886,
      mapUrl: 'https://yandex.ru/maps/?ll=38.970886%2C45.0113836&z=17&whatshere%5Bpoint%5D=38.970886%2C45.0113836&whatshere%5Bzoom%5D=17',
      rating: 4.4,
    ),
    Venue(
      id: 'park_solnechny_ostrov',
      name: 'Солнечный остров',
      description: 'Большой парк для отдыха с прогулочными зонами, семейными развлечениями и красивыми видами у воды.',
      photoUrl: 'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=800',
      type: VenueType.park,
      distance: DistanceTag.medium,
      group: GroupTag.family,
      price: PriceTag.budget,
      features: [VenueFeature.nature, VenueFeature.outdoor, VenueFeature.sport, VenueFeature.kids],
      address: 'Солнечный остров, Краснодар',
      category: 'парк',
      tags: ['парк', 'семейный отдых', 'набережная', 'активный отдых', 'велосипеды', 'выходные', 'развлечения'],
      lat: 45.0066954, lon: 39.0555153,
      mapUrl: 'https://yandex.ru/maps/?ll=39.0555153%2C45.0066954&z=17&whatshere%5Bpoint%5D=39.0555153%2C45.0066954&whatshere%5Bzoom%5D=17',
      rating: 4.6,
    ),

    // ── Достопримечательности ─────────────────────────────────────────────────
    Venue(
      id: 'attr_krasnaya_street',
      name: 'Улица Красная',
      description: 'Главная центральная улица Краснодара, популярная для прогулок, посещения кафе и знакомства с архитектурой города.',
      photoUrl: 'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.near,
      group: GroupTag.friends,
      price: PriceTag.mid,
      features: [VenueFeature.historical, VenueFeature.lively, VenueFeature.cultural],
      address: 'ул. Красная, Краснодар',
      category: 'прогулки',
      tags: ['центр города', 'променад', 'архитектура', 'кафе', 'городская жизнь', 'туристический маршрут', 'исторический центр'],
      lat: 45.03132, lon: 38.9730406,
      mapUrl: 'https://yandex.ru/maps/?ll=38.9730406%2C45.03132&z=17&whatshere%5Bpoint%5D=38.9730406%2C45.03132&whatshere%5Bzoom%5D=17',
      rating: 4.5,
    ),
    Venue(
      id: 'attr_triumfalnaya_arka',
      name: 'Александровская триумфальная арка',
      description: 'Эффектная триумфальная арка в центре Краснодара, считающаяся одним из заметных архитектурных символов города.',
      photoUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.near,
      group: GroupTag.couple,
      price: PriceTag.budget,
      features: [VenueFeature.historical, VenueFeature.cultural],
      address: 'ул. Красная / ул. Бабушкина, Краснодар',
      category: 'достопримечательность',
      tags: ['архитектура', 'памятник', 'история', 'центр', 'фотолокация', 'символ города', 'достопримечательность'],
      lat: 45.0465119, lon: 38.9782784,
      mapUrl: 'https://yandex.ru/maps/?ll=38.9782784%2C45.0465119&z=17&whatshere%5Bpoint%5D=38.9782784%2C45.0465119&whatshere%5Bzoom%5D=17',
      rating: 4.6,
    ),
    Venue(
      id: 'attr_ekaterina_monument',
      name: 'Памятник Екатерине II',
      description: 'Знаковый памятник, связанный с историей основания Екатеринодара и формированием исторического образа Краснодара.',
      photoUrl: 'https://images.unsplash.com/photo-1564507592333-c60657eea523?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.near,
      group: GroupTag.solo,
      price: PriceTag.budget,
      features: [VenueFeature.historical, VenueFeature.cultural],
      address: 'ул. Красная, 1, Краснодар',
      category: 'достопримечательность',
      tags: ['памятник', 'история города', 'Екатеринодар', 'центр', 'сквер', 'культурное наследие', 'фотографии'],
      lat: 45.0153667, lon: 38.9685124,
      mapUrl: 'https://yandex.ru/maps/?ll=38.9685124%2C45.0153667&z=17&whatshere%5Bpoint%5D=38.9685124%2C45.0153667&whatshere%5Bzoom%5D=17',
      rating: 4.7,
    ),
    Venue(
      id: 'attr_most_potseluev',
      name: 'Мост поцелуев',
      description: 'Пешеходный мост через затон Кубани, популярный у туристов и пар благодаря красивым видам и романтичной атмосфере.',
      photoUrl: 'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=800',
      type: VenueType.embankment,
      distance: DistanceTag.near,
      group: GroupTag.couple,
      price: PriceTag.budget,
      features: [VenueFeature.romantic, VenueFeature.outdoor],
      address: 'Набережная Кубани, Краснодар',
      category: 'прогулки',
      tags: ['мост', 'романтическое место', 'видовая точка', 'набережная', 'вечерние прогулки', 'фотолокация', 'Кубань'],
      lat: 45.0253104, lon: 38.9577712,
      mapUrl: 'https://yandex.ru/maps/?ll=38.9577712%2C45.0253104&z=17&whatshere%5Bpoint%5D=38.9577712%2C45.0253104&whatshere%5Bzoom%5D=17',
      rating: 4.4,
    ),
    Venue(
      id: 'attr_shukhov_tower',
      name: 'Шуховская башня',
      description: 'Редкий инженерный объект, связанный с именем Владимира Шухова, интересный для любителей промышленной архитектуры.',
      photoUrl: 'https://images.unsplash.com/photo-1486325212027-8081e485255e?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.near,
      group: GroupTag.solo,
      price: PriceTag.budget,
      features: [VenueFeature.historical, VenueFeature.cultural],
      address: 'ул. Коммунаров, 209, Краснодар',
      category: 'достопримечательность',
      tags: ['инженерная архитектура', 'Шухов', 'конструктивизм', 'история', 'урбанистика', 'необычное место', 'архитектура'],
      lat: 45.0385265, lon: 38.9718207,
      mapUrl: 'https://yandex.ru/maps/?ll=38.9718207%2C45.0385265&z=17&whatshere%5Bpoint%5D=38.9718207%2C45.0385265&whatshere%5Bzoom%5D=17',
      rating: 4.3,
    ),
    Venue(
      id: 'attr_nemetskaya_derevnya',
      name: 'Немецкая деревня',
      description: 'Необычный район с европейской архитектурой, озером и атмосферой, подходящей для прогулок и фотосессий.',
      photoUrl: 'https://images.unsplash.com/photo-1467269204594-9661b134dd2b?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.far,
      group: GroupTag.couple,
      price: PriceTag.budget,
      features: [VenueFeature.romantic, VenueFeature.outdoor, VenueFeature.quiet],
      address: 'Немецкая деревня, Краснодар',
      category: 'достопримечательность',
      tags: ['европейская архитектура', 'фотолокация', 'прогулка', 'тихий отдых', 'озеро', 'необычное место', 'атмосферный район'],
      lat: 45.1198071, lon: 38.9271584,
      mapUrl: 'https://yandex.ru/maps/?ll=38.9271584%2C45.1198071&z=17&whatshere%5Bpoint%5D=38.9271584%2C45.1198071&whatshere%5Bzoom%5D=17',
      rating: 4.2,
    ),

    // ── Храмы ────────────────────────────────────────────────────────────────
    Venue(
      id: 'temple_ekaterininskiy',
      name: 'Свято-Екатерининский кафедральный собор',
      description: 'Один из главных православных храмов Краснодара, известный своей архитектурой и духовным значением.',
      photoUrl: 'https://images.unsplash.com/photo-1503614472-8c93d56e92ce?w=800',
      type: VenueType.temple,
      distance: DistanceTag.near,
      group: GroupTag.solo,
      price: PriceTag.budget,
      features: [VenueFeature.christian, VenueFeature.historical, VenueFeature.quiet],
      address: 'ул. Коммунаров, 52, Краснодар',
      category: 'собор',
      tags: ['собор', 'православие', 'архитектура', 'религиозный туризм', 'история', 'духовное место', 'центр'],
      lat: 45.0205531, lon: 38.9747075,
      mapUrl: 'https://yandex.ru/maps/?ll=38.9747075%2C45.0205531&z=17&whatshere%5Bpoint%5D=38.9747075%2C45.0205531&whatshere%5Bzoom%5D=17',
      rating: 4.8,
    ),

    // ── Музеи ─────────────────────────────────────────────────────────────────
    Venue(
      id: 'museum_kovalenko',
      name: 'Художественный музей им. Ф. А. Коваленко',
      description: 'Один из старейших художественных музеев юга России с коллекциями живописи, графики и декоративного искусства.',
      photoUrl: 'https://images.unsplash.com/photo-1566127444979-b3d2b654e3d7?w=800',
      type: VenueType.museum,
      distance: DistanceTag.near,
      group: GroupTag.solo,
      price: PriceTag.budget,
      features: [VenueFeature.cultural, VenueFeature.quiet],
      address: 'ул. Красная, 13, Краснодар',
      category: 'музей',
      tags: ['музей', 'искусство', 'живопись', 'культура', 'выставки', 'исторический центр', 'спокойный отдых'],
      lat: 45.0183164, lon: 38.967954,
      mapUrl: 'https://yandex.ru/maps/?ll=38.967954%2C45.0183164&z=17&whatshere%5Bpoint%5D=38.967954%2C45.0183164&whatshere%5Bzoom%5D=17',
      rating: 4.5,
    ),
    Venue(
      id: 'museum_felitsyna',
      name: 'Историко-археологический музей-заповедник им. Е. Д. Фелицына',
      description: 'Крупный музей, где можно познакомиться с историей Кубани, археологией, этнографией и культурой региона.',
      photoUrl: 'https://images.unsplash.com/photo-1534430480872-3498386e7856?w=800',
      type: VenueType.museum,
      distance: DistanceTag.near,
      group: GroupTag.family,
      price: PriceTag.budget,
      features: [VenueFeature.cultural, VenueFeature.historical],
      address: 'ул. Гимназическая, 67, Краснодар',
      category: 'музей',
      tags: ['музей', 'история Кубани', 'археология', 'краеведение', 'экспозиции', 'культура', 'познавательный туризм'],
      lat: 45.0255342, lon: 38.9721651,
      mapUrl: 'https://yandex.ru/maps/?ll=38.9721651%2C45.0255342&z=17&whatshere%5Bpoint%5D=38.9721651%2C45.0255342&whatshere%5Bzoom%5D=17',
      rating: 4.6,
    ),
    Venue(
      id: 'museum_rossiya_moya_istoriya',
      name: 'Исторический парк «Россия — Моя история»',
      description: 'Современный мультимедийный исторический комплекс с интерактивными экспозициями для детей и взрослых.',
      photoUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
      type: VenueType.museum,
      distance: DistanceTag.far,
      group: GroupTag.family,
      price: PriceTag.mid,
      features: [VenueFeature.cultural, VenueFeature.historical, VenueFeature.kids],
      address: 'ул. Конгрессная, 1, Краснодар',
      category: 'музей',
      tags: ['интерактивный музей', 'история', 'мультимедиа', 'семейный отдых', 'образование', 'выставки', 'современный формат'],
      lat: 45.1045421, lon: 38.9765424,
      mapUrl: 'https://yandex.ru/maps/?ll=38.9765424%2C45.1045421&z=17&whatshere%5Bpoint%5D=38.9765424%2C45.1045421&whatshere%5Bzoom%5D=17',
      rating: 4.7,
    ),

    // ── Театры ───────────────────────────────────────────────────────────────
    Venue(
      id: 'theater_gorky',
      name: 'Краснодарский академический театр драмы им. Горького',
      description: 'Главный драматический театр Краснодара, расположенный в центре города и известный своими постановками.',
      photoUrl: 'https://images.unsplash.com/photo-1503095396549-807759245b35?w=800',
      type: VenueType.theater,
      distance: DistanceTag.near,
      group: GroupTag.couple,
      price: PriceTag.mid,
      features: [VenueFeature.cultural],
      address: 'ул. Красная, 55, Краснодар',
      category: 'театр',
      tags: ['театр', 'культура', 'спектакли', 'вечерний отдых', 'центр', 'сцена', 'городская достопримечательность'],
      lat: 45.0351356, lon: 38.9772972,
      mapUrl: 'https://yandex.ru/maps/?ll=38.9772972%2C45.0351356&z=17&whatshere%5Bpoint%5D=38.9772972%2C45.0351356&whatshere%5Bzoom%5D=17',
      rating: 4.6,
    ),

    // ── Рестораны ────────────────────────────────────────────────────────────
    Venue(
      id: 'rest_yorgos',
      name: 'Ресторан «Йоргос»',
      description: 'Известный греческий ресторан в центре Краснодара с яркой атмосферой и национальной кухней.',
      photoUrl: 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
      type: VenueType.restaurant,
      distance: DistanceTag.near,
      group: GroupTag.friends,
      price: PriceTag.premium,
      features: [VenueFeature.lively],
      address: 'ул. Красная, 73, Краснодар',
      category: 'ресторан',
      tags: ['ресторан', 'греческая кухня', 'центр', 'ужин', 'атмосфера', 'гастрономия', 'аутентичность'],
      lat: 45.0279661, lon: 38.9727964,
      mapUrl: 'https://yandex.ru/maps/?ll=38.9727964%2C45.0279661&z=17&whatshere%5Bpoint%5D=38.9727964%2C45.0279661&whatshere%5Bzoom%5D=17',
      rating: 4.3,
    ),
    Venue(
      id: 'rest_klyovo',
      name: 'Ресторан «Клёво»',
      description: 'Популярный ресторан морепродуктов на улице Красной, подходящий для стильного обеда или ужина.',
      photoUrl: 'https://images.unsplash.com/photo-1424847651672-bf20a4b0982b?w=800',
      type: VenueType.restaurant,
      distance: DistanceTag.near,
      group: GroupTag.couple,
      price: PriceTag.premium,
      features: [VenueFeature.romantic, VenueFeature.quiet],
      address: 'ул. Красная, 50, Краснодар',
      category: 'ресторан',
      tags: ['ресторан', 'морепродукты', 'рыбный ресторан', 'центр', 'гастрономия', 'вечернее место', 'стиль'],
      lat: 45.0259415, lon: 38.9713491,
      mapUrl: 'https://yandex.ru/maps/?ll=38.9713491%2C45.0259415&z=17&whatshere%5Bpoint%5D=38.9713491%2C45.0259415&whatshere%5Bzoom%5D=17',
      rating: 4.4,
    ),
    Venue(
      id: 'rest_katenka',
      name: 'Ресторан «Катенька-Катюша»',
      description: 'Ресторан современной русской кухни в историческом центре, где можно попробовать блюда с локальным характером.',
      photoUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
      type: VenueType.restaurant,
      distance: DistanceTag.near,
      group: GroupTag.couple,
      price: PriceTag.mid,
      features: [VenueFeature.historical, VenueFeature.quiet],
      address: 'ул. Красная, 45, Краснодар',
      category: 'ресторан',
      tags: ['ресторан', 'русская кухня', 'локальная еда', 'исторический центр', 'атмосфера', 'гастрономия', 'ужин'],
      lat: 45.0181055, lon: 38.9684874,
      mapUrl: 'https://yandex.ru/maps/?ll=38.9684874%2C45.0181055&z=17&whatshere%5Bpoint%5D=38.9684874%2C45.0181055&whatshere%5Bzoom%5D=17',
      rating: 4.2,
    ),
    Venue(
      id: 'rest_fisht',
      name: 'Ресторан «Фишт»',
      description: 'Уютное место с кавказской и домашней кухней, подходящее для сытного обеда и знакомства с местной едой.',
      photoUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800',
      type: VenueType.cafe,
      distance: DistanceTag.near,
      group: GroupTag.friends,
      price: PriceTag.mid,
      features: [VenueFeature.lively],
      address: 'ул. Ставропольская, 2, Краснодар',
      category: 'кафе',
      tags: ['кафе', 'ресторан', 'кавказская кухня', 'местная еда', 'обед', 'уютное место', 'гастрономический отдых'],
      lat: 45.0374376, lon: 38.9605513,
      mapUrl: 'https://yandex.ru/maps/?ll=38.9605513%2C45.0374376&z=17&whatshere%5Bpoint%5D=38.9605513%2C45.0374376&whatshere%5Bzoom%5D=17',
      rating: 4.3,
    ),
    Venue(
      id: 'rest_stan',
      name: 'Ресторан «Станъ»',
      description: 'Колоритный ресторан казачьей кухни рядом с набережной, где можно познакомиться с традициями кубанской гастрономии.',
      photoUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
      type: VenueType.restaurant,
      distance: DistanceTag.near,
      group: GroupTag.friends,
      price: PriceTag.mid,
      features: [VenueFeature.historical, VenueFeature.lively],
      address: 'Набережная Кубани, Краснодар',
      category: 'ресторан',
      tags: ['ресторан', 'казачья кухня', 'кубанская кухня', 'набережная', 'историческая атмосфера', 'туристическое место', 'местная культура'],
      lat: 45.0199886, lon: 38.9575604,
      mapUrl: 'https://yandex.ru/maps/?ll=38.9575604%2C45.0199886&z=17&whatshere%5Bpoint%5D=38.9575604%2C45.0199886&whatshere%5Bzoom%5D=17',
      rating: 4.4,
    ),

    // ── Винодельни ────────────────────────────────────────────────────────────
    Venue(
      id: 'winery_abrau',
      name: 'Абрау-Дюрсо',
      description: 'Один из самых известных центров винного туризма на юге России. Для гостей доступны экскурсии по Русскому винному дому, подземным тоннелям и дегустации игристых и тихих вин.',
      photoUrl: 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.far,
      group: GroupTag.couple,
      price: PriceTag.mid,
      features: [VenueFeature.alcohol, VenueFeature.outdoor, VenueFeature.cultural],
      address: 'пос. Абрау-Дюрсо, Новороссийск, Краснодарский край',
      category: 'винодельня',
      tags: ['винодельня', 'экскурсия', 'дегустация', 'игристые вина', 'энотуризм', 'Новороссийск', 'Краснодарский край', 'винный туризм', 'озеро Абрау'],
      lat: 44.70064, lon: 37.601575,
      mapUrl: 'https://yandex.ru/maps/?ll=37.601575%2C44.70064&z=17&whatshere%5Bpoint%5D=37.601575%2C44.70064&whatshere%5Bzoom%5D=17',
      rating: 4.7,
    ),
    Venue(
      id: 'winery_gay_kodzor',
      name: 'Винодельня «Гай-Кодзор»',
      description: 'Частная винодельня рядом с Анапой, куда можно попасть по предварительной записи. Гостям предлагают экскурсии по производству, залу ароматов и дегустации нескольких вин.',
      photoUrl: 'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.far,
      group: GroupTag.friends,
      price: PriceTag.mid,
      features: [VenueFeature.alcohol, VenueFeature.outdoor, VenueFeature.nature],
      address: 'Анапский район, Краснодарский край',
      category: 'винодельня',
      tags: ['винодельня', 'экскурсия по записи', 'дегустация', 'Анапа', 'терруар', 'частная винодельня', 'энотуризм', 'винный туризм', 'дегустация по записи'],
      lat: 44.8411833, lon: 37.43805,
      mapUrl: 'https://yandex.ru/maps/?ll=37.43805%2C44.8411833&z=17&whatshere%5Bpoint%5D=37.43805%2C44.8411833&whatshere%5Bzoom%5D=17',
      rating: 4.6,
    ),
    Venue(
      id: 'winery_chateau_de_talu',
      name: 'Chateau de Talu',
      description: 'Современная винодельня в Геленджике с туристическим комплексом. Здесь проводят экскурсии по винодельне и виноградникам, дегустации и прогулки по живописной территории шато.',
      photoUrl: 'https://images.unsplash.com/photo-1559494007-9f5847c49d94?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.far,
      group: GroupTag.couple,
      price: PriceTag.premium,
      features: [VenueFeature.alcohol, VenueFeature.outdoor, VenueFeature.romantic],
      address: 'Геленджикский район, Краснодарский край',
      category: 'винодельня',
      tags: ['винодельня', 'экскурсия', 'дегустация', 'Геленджик', 'виноградники', 'видовая площадка', 'эногастрономия', 'винный туризм', 'шато'],
      lat: 44.542243, lon: 38.085729,
      mapUrl: 'https://yandex.ru/maps/?ll=38.085729%2C44.542243&z=17&whatshere%5Bpoint%5D=38.085729%2C44.542243&whatshere%5Bzoom%5D=17',
      rating: 4.8,
    ),
    Venue(
      id: 'winery_fanagoria',
      name: 'Винодельня «Фанагория»',
      description: 'Крупная кубанская винодельня в поселке Сенной. Для посетителей доступны винные туры с экскурсиями по современному и античному производству, подвалам и дегустациями.',
      photoUrl: 'https://images.unsplash.com/photo-1474722883778-792e7990302f?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.far,
      group: GroupTag.friends,
      price: PriceTag.mid,
      features: [VenueFeature.alcohol, VenueFeature.cultural, VenueFeature.historical],
      address: 'пос. Сенной, Темрюкский район, Краснодарский край',
      category: 'винодельня',
      tags: ['винодельня', 'экскурсия', 'дегустация', 'Сенной', 'Тамань', 'винный тур', 'кубанские вина', 'винный туризм', 'Темрюкский район'],
      lat: 45.28363, lon: 36.990865,
      mapUrl: 'https://yandex.ru/maps/?ll=36.990865%2C45.28363&z=17&whatshere%5Bpoint%5D=36.990865%2C45.28363&whatshere%5Bzoom%5D=17',
      rating: 4.5,
    ),
    Venue(
      id: 'winery_sober_bash',
      name: 'Винодельня «Собер Баш»',
      description: 'Винодельня недалеко от Краснодара, куда приезжают на экскурсии и дегустации. Гостям предлагают прогулку по виноградникам, знакомство с производством и несколько дегустационных сетов.',
      photoUrl: 'https://images.unsplash.com/photo-1543418219-44e30b057fea?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.far,
      group: GroupTag.friends,
      price: PriceTag.mid,
      features: [VenueFeature.alcohol, VenueFeature.outdoor, VenueFeature.nature],
      address: 'Северский район, Краснодарский край',
      category: 'винодельня',
      tags: ['винодельня', 'экскурсия', 'дегустация', 'рядом с Краснодаром', 'виноградники', 'Северский район', 'энотуризм', 'винный туризм', 'выезд из Краснодара'],
      lat: 44.75167833933321, lon: 38.7430500984192,
      mapUrl: 'https://yandex.ru/maps/?ll=38.7430500984192%2C44.75167833933321&z=17&whatshere%5Bpoint%5D=38.7430500984192%2C44.75167833933321&whatshere%5Bzoom%5D=17',
      rating: 4.6,
    ),
    Venue(
      id: 'winery_shato_andre',
      name: 'Семейная винодельня «Шато Андре»',
      description: 'Агротуристический комплекс с винодельней, виноградниками и дегустациями в Крымском районе. Посещение доступно по предварительному бронированию, на территории есть ресторан и прогулочные зоны.',
      photoUrl: 'https://images.unsplash.com/photo-1528823872057-9c018a7a7553?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.far,
      group: GroupTag.family,
      price: PriceTag.mid,
      features: [VenueFeature.alcohol, VenueFeature.outdoor, VenueFeature.nature, VenueFeature.kids],
      address: 'Крымский район, Краснодарский край',
      category: 'винодельня',
      tags: ['винодельня', 'экскурсия', 'дегустация', 'Крымский район', 'агротуризм', 'виноградники', 'семейный отдых', 'винный туризм', 'эстетичная локация'],
      lat: 45.026244, lon: 37.622103,
      mapUrl: 'https://yandex.ru/maps/?ll=37.622103%2C45.026244&z=17&whatshere%5Bpoint%5D=37.622103%2C45.026244&whatshere%5Bzoom%5D=17',
      rating: 4.7,
    ),
  ];

  static List<Venue> get wineries => _seedVenues
      .where((v) => v.category == 'винодельня')
      .toList();
}
