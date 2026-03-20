import '../models/venue.dart';
import '../models/swipe_session.dart';
import 'dart:math';

class VenueRepository {
  static const List<Venue> _all = [
    // ── РЕСТОРАНЫ ──────────────────────────────────────────────────────────
    Venue(
      id: 'v01',
      name: 'Ресторан «Пряности & Радости»',
      description:
          'Уютный ресторан с авторской кухней в самом центре Краснодара. Живая музыка по выходным, большое меню завтраков.',
      photoUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
      type: VenueType.restaurant,
      distance: DistanceTag.near,
      group: GroupTag.couple,
      price: PriceTag.mid,
      features: [VenueFeature.romantic, VenueFeature.quiet],
      address: 'ул. Красная, 15, Краснодар',
    ),
    Venue(
      id: 'v02',
      name: 'Ресторан «Чито-Ра»',
      description:
          'Грузинская кухня: хачапури, хинкали, шашлыки. Большие порции, шумная атмосфера, идеально для компании.',
      photoUrl: 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
      type: VenueType.restaurant,
      distance: DistanceTag.near,
      group: GroupTag.friends,
      price: PriceTag.mid,
      features: [VenueFeature.lively, VenueFeature.vegetarian],
      address: 'ул. Мира, 48, Краснодар',
    ),
    Venue(
      id: 'v03',
      name: 'Стейк-хаус «Texas»',
      description:
          'Лучшие стейки города. Американский бар, виски, тёмное пиво. Для тех, кто любит мясо и хочет отдохнуть в мужской компании.',
      photoUrl: 'https://images.unsplash.com/photo-1558030006-450675393462?w=800',
      type: VenueType.restaurant,
      distance: DistanceTag.near,
      group: GroupTag.friends,
      price: PriceTag.premium,
      features: [VenueFeature.alcohol, VenueFeature.lively],
      address: 'ул. Северная, 325, Краснодар',
    ),
    Venue(
      id: 'v04',
      name: 'Семейный ресторан «Сытый папа»',
      description:
          'Домашняя кухня, детское меню, игровой уголок. Отличный вариант для обеда всей семьёй.',
      photoUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800',
      type: VenueType.restaurant,
      distance: DistanceTag.medium,
      group: GroupTag.family,
      price: PriceTag.budget,
      features: [VenueFeature.kids, VenueFeature.quiet],
      address: 'ул. Тополиная, 12, Краснодар',
    ),
    Venue(
      id: 'v05',
      name: 'Ресторан «Скат»',
      description:
          'Морепродукты и рыба прямо с краснодарских рыбных рынков. Свежайшие устрицы, тигровые креветки.',
      photoUrl: 'https://images.unsplash.com/photo-1424847651672-bf20a4b0982b?w=800',
      type: VenueType.restaurant,
      distance: DistanceTag.near,
      group: GroupTag.couple,
      price: PriceTag.premium,
      features: [VenueFeature.romantic, VenueFeature.quiet],
      address: 'ул. Красная, 180, Краснодар',
    ),
    Venue(
      id: 'v06',
      name: 'Шашлычная «Мангал»',
      description:
          'Доступные цены, огромные порции шашлыка, пловом угощают бесплатно. Типичное кубанское застолье.',
      photoUrl: 'https://images.unsplash.com/photo-1529042410759-befb1204b468?w=800',
      type: VenueType.restaurant,
      distance: DistanceTag.medium,
      group: GroupTag.largeGroup,
      price: PriceTag.budget,
      features: [VenueFeature.outdoor, VenueFeature.lively, VenueFeature.kids],
      address: 'ул. Ставропольская, 88, Краснодар',
    ),

    // ── КАФЕ ───────────────────────────────────────────────────────────────
    Venue(
      id: 'v07',
      name: 'Кофейня «Паровоз»',
      description:
          'Специальный кофе, авторские десерты, уютный интерьер в стиле лофт. Хорошее место для работы или тихой встречи.',
      photoUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800',
      type: VenueType.cafe,
      distance: DistanceTag.near,
      group: GroupTag.solo,
      price: PriceTag.mid,
      features: [VenueFeature.quiet, VenueFeature.vegetarian],
      address: 'ул. Красная, 105, Краснодар',
    ),
    Venue(
      id: 'v08',
      name: 'Кафе «Тесто»',
      description:
          'Пекарня и кафе: свежая выпечка каждые 2 часа, домашние завтраки, хорошая кухня.',
      photoUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800',
      type: VenueType.cafe,
      distance: DistanceTag.near,
      group: GroupTag.solo,
      price: PriceTag.budget,
      features: [VenueFeature.quiet, VenueFeature.vegetarian],
      address: 'ул. Горького, 78, Краснодар',
    ),
    Venue(
      id: 'v09',
      name: 'Детское кафе «Карусель»',
      description:
          'Аниматоры, игровая комната, детское меню и торты на заказ. Идеальное место для детского дня рождения.',
      photoUrl: 'https://images.unsplash.com/photo-1588516903720-8ceb67f9ef84?w=800',
      type: VenueType.cafe,
      distance: DistanceTag.medium,
      group: GroupTag.family,
      price: PriceTag.mid,
      features: [VenueFeature.kids],
      address: 'ул. Янковского, 150, Краснодар',
    ),

    // ── ПАРКИ ──────────────────────────────────────────────────────────────
    Venue(
      id: 'v10',
      name: 'Парк имени Горького',
      description:
          'Главный городской парк с колесом обозрения, аттракционами и фонтанами. Любимое место краснодарцев.',
      photoUrl: 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800',
      type: VenueType.park,
      distance: DistanceTag.near,
      group: GroupTag.family,
      price: PriceTag.budget,
      features: [VenueFeature.kids, VenueFeature.outdoor, VenueFeature.lively],
      address: 'ул. Красная, 206, Краснодар',
    ),
    Venue(
      id: 'v11',
      name: 'Чистяковская роща',
      description:
          'Тихий лесной парк в городе. Пруды с лебедями, спортивные площадки, велодорожки. Хорошо для утренних пробежек.',
      photoUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?w=800',
      type: VenueType.park,
      distance: DistanceTag.near,
      group: GroupTag.solo,
      price: PriceTag.budget,
      features: [VenueFeature.outdoor, VenueFeature.sport, VenueFeature.nature, VenueFeature.quiet],
      address: 'ул. Айвазовского, 2/6, Краснодар',
    ),
    Venue(
      id: 'v12',
      name: 'Парк «Солнечный остров»',
      description:
          'Огромный парк с зоопарком, батутами и верёвочными городками. Целый день активного отдыха для семьи.',
      photoUrl: 'https://images.unsplash.com/photo-1551009175-8a68da93d5f9?w=800',
      type: VenueType.park,
      distance: DistanceTag.medium,
      group: GroupTag.family,
      price: PriceTag.budget,
      features: [VenueFeature.kids, VenueFeature.outdoor, VenueFeature.sport, VenueFeature.lively],
      address: 'Прикубанский округ, Краснодар',
    ),
    Venue(
      id: 'v13',
      name: 'Краснодарский зоопарк',
      description:
          'Более 3000 животных 300 видов. Один из лучших зоопарков Юга России. Отличное место для детей.',
      photoUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.medium,
      group: GroupTag.family,
      price: PriceTag.budget,
      features: [VenueFeature.kids, VenueFeature.outdoor, VenueFeature.nature],
      address: 'ул. Zipcode, Краснодар',
    ),

    // ── МУЗЕИ ──────────────────────────────────────────────────────────────
    Venue(
      id: 'v14',
      name: 'Краснодарский художественный музей',
      description:
          'Более 13 000 произведений искусства от XVIII века до современности. Один из крупнейших музеев Юга России.',
      photoUrl: 'https://images.unsplash.com/photo-1518998053901-5348d3961a04?w=800',
      type: VenueType.museum,
      distance: DistanceTag.near,
      group: GroupTag.solo,
      price: PriceTag.budget,
      features: [VenueFeature.cultural, VenueFeature.quiet],
      address: 'ул. Красная, 13, Краснодар',
    ),
    Venue(
      id: 'v15',
      name: 'Краснодарский краевой историко-археологический музей',
      description:
          'Богатейшая коллекция по истории Кубани: от скифов до казачества. Интерактивные экспозиции для детей.',
      photoUrl: 'https://images.unsplash.com/photo-1555635572-1e5e2b74b19e?w=800',
      type: VenueType.museum,
      distance: DistanceTag.near,
      group: GroupTag.family,
      price: PriceTag.budget,
      features: [VenueFeature.cultural, VenueFeature.historical, VenueFeature.kids],
      address: 'ул. Гимназическая, 67, Краснодар',
    ),
    Venue(
      id: 'v16',
      name: 'Музей фелицына',
      description:
          'Природоведческий и исторический музей. Огромная коллекция флоры и фауны Краснодарского края.',
      photoUrl: 'https://images.unsplash.com/photo-1559329007-40df8a9345d8?w=800',
      type: VenueType.museum,
      distance: DistanceTag.near,
      group: GroupTag.solo,
      price: PriceTag.budget,
      features: [VenueFeature.cultural, VenueFeature.nature, VenueFeature.quiet],
      address: 'ул. Гимназическая, 67, Краснодар',
    ),

    // ── ХРАМЫ ──────────────────────────────────────────────────────────────
    Venue(
      id: 'v17',
      name: 'Свято-Екатерининский собор',
      description:
          'Главный православный собор Краснодара. Красивая архитектура конца XIX века, живописные росписи внутри.',
      photoUrl: 'https://images.unsplash.com/photo-1504884790557-80b5c62b6c28?w=800',
      type: VenueType.temple,
      distance: DistanceTag.near,
      group: GroupTag.solo,
      price: PriceTag.budget,
      features: [VenueFeature.christian, VenueFeature.historical, VenueFeature.quiet],
      address: 'ул. Коммунаров, 52, Краснодар',
    ),
    Venue(
      id: 'v18',
      name: 'Храм Рождества Христова',
      description:
          'Новый храм в современном православном стиле. Известен иконостасом из белого мрамора.',
      photoUrl: 'https://images.unsplash.com/photo-1519320109577-27a8e5ea5fc9?w=800',
      type: VenueType.temple,
      distance: DistanceTag.medium,
      group: GroupTag.family,
      price: PriceTag.budget,
      features: [VenueFeature.christian, VenueFeature.quiet],
      address: 'ул. Котлярова, 44, Краснодар',
    ),
    Venue(
      id: 'v19',
      name: 'Свято-Троицкий собор',
      description:
          'Один из старейших соборов Краснодара, основан в 1818 году. Место паломничества православных верующих.',
      photoUrl: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=800',
      type: VenueType.temple,
      distance: DistanceTag.near,
      group: GroupTag.solo,
      price: PriceTag.budget,
      features: [VenueFeature.christian, VenueFeature.historical, VenueFeature.quiet],
      address: 'ул. Советская, 53, Краснодар',
    ),
    Venue(
      id: 'v20',
      name: 'Свято-Георгиевский монастырь',
      description:
          'Действующий монастырь за городом. Тишина, природа, иконы, монашеский хор по выходным.',
      photoUrl: 'https://images.unsplash.com/photo-1533929736458-ca588d08c8be?w=800',
      type: VenueType.temple,
      distance: DistanceTag.far,
      group: GroupTag.solo,
      price: PriceTag.budget,
      features: [VenueFeature.christian, VenueFeature.quiet, VenueFeature.nature],
      address: 'Краснодарский край, пос. Новый',
    ),

    // ── БАРЫ / НОЧНАЯ ЖИЗНЬ ────────────────────────────────────────────────
    Venue(
      id: 'v21',
      name: 'Крафтовый бар «Kuban Brew»',
      description:
          'Более 20 сортов крафтового пива собственного производства. Живые концерты каждую пятницу.',
      photoUrl: 'https://images.unsplash.com/photo-1436076863939-06870fe779c2?w=800',
      type: VenueType.bar,
      distance: DistanceTag.near,
      group: GroupTag.friends,
      price: PriceTag.mid,
      features: [VenueFeature.alcohol, VenueFeature.lively],
      address: 'ул. Красноармейская, 66, Краснодар',
    ),
    Venue(
      id: 'v22',
      name: 'Крыша-бар «Panorama»',
      description:
          'Коктейли на крыше с панорамным видом на ночной Краснодар. Дресс-код, романтичная атмосфера.',
      photoUrl: 'https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=800',
      type: VenueType.bar,
      distance: DistanceTag.near,
      group: GroupTag.couple,
      price: PriceTag.premium,
      features: [VenueFeature.romantic, VenueFeature.alcohol, VenueFeature.lively],
      address: 'ул. Красная, 109, Краснодар',
    ),

    // ── СПА / ВЕЛНЕС ───────────────────────────────────────────────────────
    Venue(
      id: 'v23',
      name: 'Spa-центр «Эдем»',
      description:
          'Хаммам, сауна, бассейн, массажи. Пакеты для пар и индивидуальные программы релакса.',
      photoUrl: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800',
      type: VenueType.spa,
      distance: DistanceTag.near,
      group: GroupTag.couple,
      price: PriceTag.premium,
      features: [VenueFeature.romantic, VenueFeature.quiet],
      address: 'ул. Захарова, 28, Краснодар',
    ),
    Venue(
      id: 'v24',
      name: 'Семейный банный комплекс «Парная»',
      description:
          'Русская баня с вениками, купель, горячий чай. Отдельные кабинки для семей. Дети до 10 лет бесплатно.',
      photoUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
      type: VenueType.spa,
      distance: DistanceTag.medium,
      group: GroupTag.family,
      price: PriceTag.mid,
      features: [VenueFeature.kids, VenueFeature.quiet],
      address: 'ул. Калинина, 133, Краснодар',
    ),

    // ── СПОРТ ──────────────────────────────────────────────────────────────
    Venue(
      id: 'v25',
      name: 'Скалодром «Вертикаль»',
      description:
          'Крупнейший скалодром Краснодара. Трассы для всех уровней, инструкторы для начинающих.',
      photoUrl: 'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=800',
      type: VenueType.sport,
      distance: DistanceTag.medium,
      group: GroupTag.friends,
      price: PriceTag.mid,
      features: [VenueFeature.sport, VenueFeature.lively],
      address: 'ул. Тургенева, 138/1, Краснодар',
    ),
    Venue(
      id: 'v26',
      name: 'Каток «Айсберг»',
      description:
          'Крытый каток с прокатом коньков, работает круглый год. Дискотека на льду по субботам.',
      photoUrl: 'https://images.unsplash.com/photo-1544881248-c325e52c2462?w=800',
      type: VenueType.sport,
      distance: DistanceTag.near,
      group: GroupTag.family,
      price: PriceTag.budget,
      features: [VenueFeature.sport, VenueFeature.kids, VenueFeature.lively],
      address: 'ул. Ставропольская, 175, Краснодар',
    ),
    Venue(
      id: 'v27',
      name: 'Велопрокат на набережной Кубани',
      description:
          'Прокат велосипедов, самокатов и роликов вдоль реки Кубань. 14 км велодорожки.',
      photoUrl: 'https://images.unsplash.com/photo-1558618047-f4e60cde4228?w=800',
      type: VenueType.sport,
      distance: DistanceTag.near,
      group: GroupTag.couple,
      price: PriceTag.budget,
      features: [VenueFeature.sport, VenueFeature.outdoor, VenueFeature.romantic, VenueFeature.nature],
      address: 'Набережная реки Кубань, Краснодар',
    ),
    Venue(
      id: 'v28',
      name: 'Верёвочный парк «Тарзан»',
      description:
          'Верёвочный городок в лесу: 7 трасс разной сложности, зиплайн. Незабываемо для детей и взрослых.',
      photoUrl: 'https://images.unsplash.com/photo-1508739773434-c26b3d09e071?w=800',
      type: VenueType.sport,
      distance: DistanceTag.far,
      group: GroupTag.largeGroup,
      price: PriceTag.mid,
      features: [VenueFeature.sport, VenueFeature.outdoor, VenueFeature.kids, VenueFeature.nature],
      address: 'Динской район, Краснодарский край',
    ),

    // ── НАБЕРЕЖНЫЕ / ПРОГУЛКИ ──────────────────────────────────────────────
    Venue(
      id: 'v29',
      name: 'Набережная реки Кубань',
      description:
          'Прогулочная набережная с видом на реку. Вечерняя иллюминация, фотозоны, уличные музыканты.',
      photoUrl: 'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=800',
      type: VenueType.embankment,
      distance: DistanceTag.near,
      group: GroupTag.couple,
      price: PriceTag.budget,
      features: [VenueFeature.romantic, VenueFeature.outdoor, VenueFeature.lively],
      address: 'Набережная р. Кубань, Краснодар',
    ),
    Venue(
      id: 'v30',
      name: 'Пешеходная улица Красная',
      description:
          'Главная пешеходная улица Краснодара: бутики, кафе, уличные художники. Центр городской жизни.',
      photoUrl: 'https://images.unsplash.com/photo-1555817128-342e4a1e0c08?w=800',
      type: VenueType.embankment,
      distance: DistanceTag.near,
      group: GroupTag.friends,
      price: PriceTag.budget,
      features: [VenueFeature.outdoor, VenueFeature.lively, VenueFeature.cultural],
      address: 'ул. Красная, Краснодар',
    ),

    // ── АТТРАКЦИОНЫ / РАЗВЛЕЧЕНИЯ ──────────────────────────────────────────
    Venue(
      id: 'v31',
      name: 'Планетарий Краснодара',
      description:
          'Звёздное небо на огромном куполе, образовательные программы для детей и взрослых.',
      photoUrl: 'https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.near,
      group: GroupTag.family,
      price: PriceTag.budget,
      features: [VenueFeature.kids, VenueFeature.cultural, VenueFeature.quiet],
      address: 'ул. Жлобы, 59, Краснодар',
    ),
    Venue(
      id: 'v32',
      name: 'Квест-комната «Escape»',
      description:
          'Лучшие квест-комнаты города: детективы, ужасы, приключения. 60 минут острых ощущений.',
      photoUrl: 'https://images.unsplash.com/photo-1572375992501-4b0892d50c69?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.near,
      group: GroupTag.friends,
      price: PriceTag.mid,
      features: [VenueFeature.lively],
      address: 'ул. Рашпилевская, 67, Краснодар',
    ),
    Venue(
      id: 'v33',
      name: 'Боулинг-клуб «Strike»',
      description:
          '32 дорожки, бар, бильярд и аркадные автоматы. Идеально для большой компании в любую погоду.',
      photoUrl: 'https://images.unsplash.com/photo-1547941126-3d5322b218b0?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.medium,
      group: GroupTag.largeGroup,
      price: PriceTag.mid,
      features: [VenueFeature.lively, VenueFeature.alcohol, VenueFeature.kids],
      address: 'ТЦ «Красная площадь», Краснодар',
    ),
    Venue(
      id: 'v34',
      name: 'Кинотеатр «Монитор» IMAX',
      description:
          'Зал IMAX и 4DX, Dolby Atmos. Лучший кинозал Краснодара для блокбастеров.',
      photoUrl: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.near,
      group: GroupTag.couple,
      price: PriceTag.mid,
      features: [VenueFeature.romantic],
      address: 'ТЦ Галерея, ул. Красная, Краснодар',
    ),
    Venue(
      id: 'v35',
      name: 'Парк водных аттракционов «Аквапарк»',
      description:
          'Горки, волновой бассейн, детские зоны. Работает с мая по сентябрь.',
      photoUrl: 'https://images.unsplash.com/photo-1575429198097-0414ec08e8cd?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.medium,
      group: GroupTag.family,
      price: PriceTag.mid,
      features: [VenueFeature.kids, VenueFeature.outdoor, VenueFeature.lively, VenueFeature.sport],
      address: 'ул. Восточно-Кругликовская, Краснодар',
    ),

    // ── ТЕАТРЫ / КУЛЬТУРА ──────────────────────────────────────────────────
    Venue(
      id: 'v36',
      name: 'Краснодарский музыкальный театр',
      description:
          'Оперы, балеты, мюзиклы мирового уровня. Великолепное здание в центре города.',
      photoUrl: 'https://images.unsplash.com/photo-1514533450685-4493e01d1fdc?w=800',
      type: VenueType.theater,
      distance: DistanceTag.near,
      group: GroupTag.couple,
      price: PriceTag.mid,
      features: [VenueFeature.romantic, VenueFeature.cultural, VenueFeature.quiet],
      address: 'ул. Красная, 28, Краснодар',
    ),
    Venue(
      id: 'v37',
      name: 'Молодёжный театр «Эксперимент»',
      description:
          'Авангардные постановки, нестандартная сцена, умные пьесы для взрослых. Билеты надо брать заранее.',
      photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800',
      type: VenueType.theater,
      distance: DistanceTag.near,
      group: GroupTag.friends,
      price: PriceTag.budget,
      features: [VenueFeature.cultural, VenueFeature.quiet],
      address: 'ул. Гимназическая, 102, Краснодар',
    ),
    Venue(
      id: 'v38',
      name: 'Краснодарский цирк',
      description:
          'Классические цирковые программы, гастроли топовых трупп России. Дети в восторге.',
      photoUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=800',
      type: VenueType.theater,
      distance: DistanceTag.near,
      group: GroupTag.family,
      price: PriceTag.mid,
      features: [VenueFeature.kids, VenueFeature.cultural, VenueFeature.lively],
      address: 'ул. Буденного, 153, Краснодар',
    ),

    // ── ТОРГОВЫЕ ЦЕНТРЫ ────────────────────────────────────────────────────
    Venue(
      id: 'v39',
      name: 'ТРЦ «Галерея Краснодар»',
      description:
          'Крупнейший ТРЦ региона: 400 магазинов, 50 ресторанов, каток, кино. Целый день развлечений.',
      photoUrl: 'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=800',
      type: VenueType.mall,
      distance: DistanceTag.near,
      group: GroupTag.largeGroup,
      price: PriceTag.mid,
      features: [VenueFeature.kids, VenueFeature.lively],
      address: 'ул. Красная, 176, Краснодар',
    ),
    Venue(
      id: 'v40',
      name: 'ТЦ «Красная площадь»',
      description:
          'Торговый центр с фудкортом, IKEA и крупными магазинами. Большая парковка.',
      photoUrl: 'https://images.unsplash.com/photo-1601574968106-b312ac309953?w=800',
      type: VenueType.mall,
      distance: DistanceTag.medium,
      group: GroupTag.family,
      price: PriceTag.mid,
      features: [VenueFeature.kids, VenueFeature.lively],
      address: 'ул. Дзержинского, 100, Краснодар',
    ),

    // ── ПРИРОДА / ЗА ГОРОДОМ ───────────────────────────────────────────────
    Venue(
      id: 'v41',
      name: 'Горячеключевские скалы',
      description:
          'Живописные скалы и пещеры в 60 км от Краснодара. Маршруты для пеших прогулок, купание в реке.',
      photoUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800',
      type: VenueType.park,
      distance: DistanceTag.far,
      group: GroupTag.friends,
      price: PriceTag.budget,
      features: [VenueFeature.nature, VenueFeature.outdoor, VenueFeature.sport, VenueFeature.historical],
      address: 'г. Горячий Ключ, Краснодарский край',
    ),
    Venue(
      id: 'v42',
      name: 'Дольмены под Геленджиком',
      description:
          'Таинственные каменные гробницы возрастом 5000 лет. Необычное место для тех, кто любит историю.',
      photoUrl: 'https://images.unsplash.com/photo-1520962880247-cfaf541c8724?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.far,
      group: GroupTag.solo,
      price: PriceTag.budget,
      features: [VenueFeature.historical, VenueFeature.nature, VenueFeature.outdoor],
      address: 'Краснодарский край, окрестности Геленджика',
    ),
    Venue(
      id: 'v43',
      name: 'Краснодарское водохранилище',
      description:
          'Рыбалка, пикники, байдарки на большом водохранилище. Просторные берега, свежий воздух.',
      photoUrl: 'https://images.unsplash.com/photo-1500375592092-40eb2168fd21?w=800',
      type: VenueType.park,
      distance: DistanceTag.medium,
      group: GroupTag.largeGroup,
      price: PriceTag.budget,
      features: [VenueFeature.nature, VenueFeature.outdoor, VenueFeature.sport, VenueFeature.kids],
      address: 'пос. Краснодарское, Краснодарский край',
    ),
    Venue(
      id: 'v44',
      name: 'Агроферма «Кубанская сотня»',
      description:
          'Экскурсия на рабочую ферму: лошади, коровы, козы. Дегустация домашних продуктов. Дети в восторге.',
      photoUrl: 'https://images.unsplash.com/photo-1500595046743-cd271d694d30?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.far,
      group: GroupTag.family,
      price: PriceTag.mid,
      features: [VenueFeature.kids, VenueFeature.nature, VenueFeature.outdoor],
      address: 'Краснодарский район, хутор Копанской',
    ),

    // ── ЕЩЁ РЕСТОРАНЫ/КАФЕ ────────────────────────────────────────────────
    Venue(
      id: 'v45',
      name: 'Веганское кафе «Зелёный»',
      description:
          'Полностью растительное меню, смузи-бары, безглютеновая выпечка. Популярно среди ЗОЖ-аудитории.',
      photoUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800',
      type: VenueType.cafe,
      distance: DistanceTag.near,
      group: GroupTag.solo,
      price: PriceTag.mid,
      features: [VenueFeature.vegetarian, VenueFeature.quiet],
      address: 'ул. Красноармейская, 52, Краснодар',
    ),
    Venue(
      id: 'v46',
      name: 'Кулинарная студия «Мастер-класс»',
      description:
          'Мастер-классы по кубанской кухне: лепка вареников, выпечка, дегустация вин. Для компаний и пар.',
      photoUrl: 'https://images.unsplash.com/photo-1507048331197-7d4ac70811cf?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.near,
      group: GroupTag.couple,
      price: PriceTag.mid,
      features: [VenueFeature.romantic, VenueFeature.cultural, VenueFeature.lively],
      address: 'ул. Октябрьская, 36, Краснодар',
    ),
    Venue(
      id: 'v47',
      name: 'Ночной клуб «Arena»',
      description:
          'Главный клуб Краснодара: топовые диджеи, огромная танцплощадка, VIP-зоны.',
      photoUrl: 'https://images.unsplash.com/photo-1566417713940-fe7c737a9ef2?w=800',
      type: VenueType.bar,
      distance: DistanceTag.near,
      group: GroupTag.friends,
      price: PriceTag.premium,
      features: [VenueFeature.alcohol, VenueFeature.lively],
      address: 'ул. Буденного, 148, Краснодар',
    ),
    Venue(
      id: 'v48',
      name: 'Рынок «Сенной» с дегустацией',
      description:
          'Легендарный кубанский рынок: местные сыры, вина, мёд, специи. Гастрономический туризм.',
      photoUrl: 'https://images.unsplash.com/photo-1519996529931-28324d5a630e?w=800',
      type: VenueType.attraction,
      distance: DistanceTag.near,
      group: GroupTag.solo,
      price: PriceTag.budget,
      features: [VenueFeature.cultural, VenueFeature.lively, VenueFeature.outdoor],
      address: 'ул. Сенная, 1, Краснодар',
    ),
    Venue(
      id: 'v49',
      name: 'Конная прогулка «Кубань»',
      description:
          'Прогулки верхом по степи и лесополосе. Инструкторы, пони для детей. Рассвет или закат.',
      photoUrl: 'https://images.unsplash.com/photo-1472396961693-142e6e269027?w=800',
      type: VenueType.sport,
      distance: DistanceTag.far,
      group: GroupTag.family,
      price: PriceTag.mid,
      features: [VenueFeature.kids, VenueFeature.nature, VenueFeature.outdoor, VenueFeature.romantic],
      address: 'Динской район, Краснодарский край',
    ),
    Venue(
      id: 'v50',
      name: 'Смотровая площадка на ул. Красной',
      description:
          'Бесплатная смотровая площадка с видом на весь центр Краснодара. Лучший закат в городе.',
      photoUrl: 'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=800',
      type: VenueType.embankment,
      distance: DistanceTag.near,
      group: GroupTag.couple,
      price: PriceTag.budget,
      features: [VenueFeature.romantic, VenueFeature.outdoor, VenueFeature.quiet],
      address: 'ул. Красная, Краснодар',
    ),
  ];

  List<Venue> getAll() => List.unmodifiable(_all);

  Venue? getById(String id) {
    try {
      return _all.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Build session queue of [count] cards for the given [mode].
  /// Cards are selected to maximally cover different dimensions
  /// (distance, group, price, type, features) so the algorithm
  /// has enough signal after the session.
  List<Venue> buildSessionQueue(SessionMode mode, {int count = 12}) {
    final rng = Random();

    // 1. Filter by mode constraints
    var pool = _all.toList();

    final requiredFeatures = mode.requiredFeatures;
    if (requiredFeatures != null && mode != SessionMode.normal) {
      pool = pool
          .where((v) => v.features.any((f) => requiredFeatures.contains(f)))
          .toList();
    }

    final reqPrice = mode.requiredPrice;
    if (reqPrice != null) {
      pool = pool.where((v) => v.price == reqPrice).toList();
    }

    final reqType = mode.requiredType;
    if (reqType != null) {
      // for foodie – restaurants and cafes
      pool = pool
          .where((v) =>
              v.type == VenueType.restaurant || v.type == VenueType.cafe)
          .toList();
    }

    if (pool.length <= count) {
      pool.shuffle(rng);
      return pool;
    }

    // 2. Stratified sampling: ensure coverage of distance/group/price
    final selected = <Venue>[];
    final buckets = <List<Venue>>[];

    for (final dist in DistanceTag.values) {
      for (final grp in GroupTag.values) {
        final bucket = pool
            .where((v) => v.distance == dist && v.group == grp)
            .toList()
          ..shuffle(rng);
        if (bucket.isNotEmpty) buckets.add(bucket);
      }
    }

    buckets.shuffle(rng);
    final usedIds = <String>{};

    for (final bucket in buckets) {
      for (final v in bucket) {
        if (!usedIds.contains(v.id)) {
          selected.add(v);
          usedIds.add(v.id);
          if (selected.length >= count) break;
        }
      }
      if (selected.length >= count) break;
    }

    // 3. Fill up with random if needed
    if (selected.length < count) {
      final remaining = pool.where((v) => !usedIds.contains(v.id)).toList()
        ..shuffle(rng);
      for (final v in remaining) {
        selected.add(v);
        if (selected.length >= count) break;
      }
    }

    selected.shuffle(rng);
    return selected.take(count).toList();
  }
}
