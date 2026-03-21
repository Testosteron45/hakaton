# Контекст проекта: «Тревелье — Куда пойти в Краснодаре»

Flutter-приложение для подбора мест в Краснодаре через свайп-сессии. Работает на Web (Flutter Web + Firebase).

---

## Стек

- **Flutter** (Dart) — Web
- **Firebase Auth** — регистрация/вход по email
- **Cloud Firestore** — хранение заведений, профилей пользователей, аналитики
- **Riverpod** — управление состоянием
- **GoRouter** — навигация
- **AppinioSwiper** — свайп-карточки

---

## Поток приложения

```
Запуск
  └─ LoadingScreen (/loading)
       ├─ Firestore загружает заведения в кэш (VenueSeedService)
       └─ Переход на /modes

/modes — SessionModeScreen
  ├─ Кнопка "Обычная сессия" → /session?mode=normal
  └─ Тематические режимы (романтика, бюджет, семья...) → /session?mode=X

/session — SwipeSessionScreen
  ├─ buildSessionQueue() берёт 12 заведений стратифицированной выборкой
  ├─ Пользователь свайпает карточки (лайк/дизлайк)
  ├─ После каждого свайпа пишется аналитика в venues/{id}/stats (batch)
  └─ После 12 свайпов → /result + пишутся интересы пользователя в user_profiles/{uid}

/result — RecommendationScreen
  └─ Алгоритм анализирует свайпы + накопленный профиль и показывает топ-3 места

/profile — ProfileScreen
  ├─ Статистика пользователя, портрет вкуса
  ├─ Секция "Моё заведение" — список своих заведений со статистикой
  └─ Кнопка "Добавить заведение" → /add-venue

/add-venue — AddVenueScreen
  └─ Форма создания заведения → сохраняется в venues/ + привязывается к профилю

/my-venue — MyVenueScreen
  └─ Статистика конкретного заведения (показы, лайки, дизлайки, разбивка по режимам)
```

---

## Заведения

Хранятся в **Firestore**, коллекция `venues`. 21 реальное место в Краснодаре + пользовательские заведения.

При первом запуске `VenueSeedService` заливает базовые 21 заведение если коллекция пустая.

Каждое заведение (`Venue`) содержит:
- `id`, `name`, `description`, `address`
- `photoUrl` — fallback URL (Unsplash/Yandex), используется только если нет локального ассета
- `mapUrl` — ссылка на Яндекс.Карты
- `lat`, `lon` — координаты
- `rating` — оценка с Яндекс.Карт (4.2–4.8)
- `type` — тип (ресторан, парк, музей, храм, театр, кафе, набережная, достопримечательность)
- `distance` — near/medium/far от центра
- `group` — solo/couple/friends/family/largeGroup
- `price` — budget/mid/premium
- `features` — теги (romantic, kids, outdoor, quiet, lively, cultural, historical, nature...)
- `category` — строка для фильтрации по режиму сессии
- `tags` — список строк для алгоритма рекомендаций
- `createdBy` — uid владельца (только для пользовательских заведений)
- `stats` — `{likes, dislikes, impressions}` — свайп-аналитика
- `modeStats` — `{modeName: {likes, dislikes}}` — аналитика по режимам сессий

### Список базовых заведений

Парки: Парк «Краснодар», Японский сад, Чистяковская роща, Городской сад, Солнечный остров
Достопримечательности: Улица Красная, Александровская триумфальная арка, Памятник Екатерине II, Мост поцелуев, Шуховская башня, Немецкая деревня
Храмы: Свято-Екатерининский собор
Музеи: Музей Коваленко, Музей Фелицына, Исторический парк «Россия — Моя история»
Театры: Театр им. Горького
Рестораны: Йоргос, Клёво, Катенька-Катюша, Фишт, Станъ

---

## Режимы сессий

| Режим | Описание | Фильтр |
|---|---|---|
| normal | Обычная | без фильтров |
| bigFamily | Семейный | kids, outdoor, nature |
| christian | Духовный | christian |
| romantic | Романтика | romantic |
| budget | Бюджетно | price=budget |
| active | Активный | outdoor, sport, nature |
| foodie | Гастрономия | категории: ресторан, кафе |

---

## Алгоритм рекомендаций

`RecommendationService.recommend(session, {UserProfile? profile})` — анализирует 12 свайпов:

1. Разделяет лайки и дизлайки
2. Выводит предпочтения: `preferredDistance`, `preferredGroup`, `preferredPrice`, `preferredTypes`, `preferredFeatures`, `preferredTags`
3. Скорит все заведения не из текущей сессии:
   - +4/2/1 за совпадение типа (1й/2й/3й предпочтительный)
   - -3 за совпадение с дизлайкнутым типом
   - +2 за совпадение дистанции, группы
   - +1 за совпадение цены, фичей
   - до +3 за совпадение тегов
   - до +1.5/1.0/0.5 буст от накопленного профиля (история сессий)
4. Возвращает топ-3 заведения с объяснением

---

## Накопление интересов пользователя

После каждой сессии `SwipeSessionNotifier` пишет два потока данных:

**Поток 1 — интересы пользователя** (`user_profiles/{uid}`):
- `likedTypes: {restaurant: 4, park: 2}` — только лайки
- `likedFeatures`, `preferredPrice`, `preferredDistance`, `preferredGroup`
- `totalSessions` — счётчик сессий
- Используется в следующих сессиях для буста рекомендаций

**Поток 2 — аналитика заведений** (`venues/{venueId}`):
- `stats: {likes, dislikes, impressions}` — лайки + дизлайки
- `modeStats: {romantic: {likes, dislikes}, ...}` — разбивка по режимам
- Доступна владельцу заведения в `/my-venue`

---

## Профиль пользователя (`user_profiles/{uid}`)

```
uid, name
preferredTypes: List<String>       — из онбординга
defaultGroup: String               — из онбординга
assistantCustomization: Map        — внешний вид казачьего ассистента
likedTypes: Map<String, int>       — накопленные интересы
likedFeatures: Map<String, int>
preferredPrice: Map<String, int>
preferredDistance: Map<String, int>
preferredGroup: Map<String, int>
totalSessions: int
ownedVenueIds: List<String>        — ID заведений пользователя
```

---

## Добавление своего заведения

Любой авторизованный пользователь может:
1. Через `/add-venue` заполнить форму (название, описание, адрес, тип, цена, дистанция, группа, фичи)
2. Заведение записывается в `venues/` с полем `createdBy: uid`
3. ID добавляется в `user_profiles/{uid}/ownedVenueIds`
4. Заведение сразу попадает в пул свайп-сессий для всех пользователей
5. Владелец видит статистику на экране `/my-venue`

---

## Ключевые файлы

```
lib/
├── main.dart
├── core/
│   ├── router/app_router.dart         — GoRouter, все маршруты
│   ├── constants/app_colors.dart      — цвета
│   ├── constants/venue_assets.dart    — маппинг venueId → assets/places/
│   └── theme/app_theme.dart
├── data/
│   ├── models/
│   │   ├── venue.dart                 — модель + все enum (VenueType, GroupTag, PriceTag...)
│   │   ├── swipe_session.dart         — модель сессии
│   │   └── user_profile.dart          — профиль с интересами и ownedVenueIds
│   ├── repositories/
│   │   ├── venue_repository.dart      — кэш, buildSessionQueue(), addVenue(),
│   │   │                                updateVenueStats(), loadVenueStats(), deleteVenue()
│   │   └── user_profile_repository.dart — load/save, updateInterests(),
│   │                                      addOwnedVenue(), removeOwnedVenue()
│   └── services/
│       ├── venue_seed_service.dart    — первичная загрузка в Firestore
│       └── recommendation_service.dart
├── features/
│   ├── auth/screens/auth_screen.dart
│   ├── session_mode/
│   ├── swipe_session/
│   │   └── providers/swipe_session_provider.dart — пишет аналитику после сессии
│   ├── recommendation/
│   ├── map/
│   ├── profile/screens/profile_screen.dart
│   └── my_venue/screens/
│       ├── add_venue_screen.dart      — форма создания заведения
│       └── my_venue_screen.dart       — статистика заведения
└── shared/providers/providers.dart    — все Riverpod провайдеры
```

---

## Провайдеры (Riverpod)

- `venuesInitProvider` — FutureProvider: seed + load из Firestore
- `venueRepositoryProvider` — кэш заведений
- `swipeSessionProvider` — текущая сессия + запись аналитики по завершении
- `recommendationProvider` — топ-3 после сессии (использует профиль)
- `userProfileProvider` — FutureProvider<UserProfile?>
- `ownedVenueStatsProvider` — FutureProvider<List<VenueStats>> — статистика всех заведений юзера
- `authStateProvider` — стрим авторизации
- `themeModeProvider` — светлая/тёмная тема

---

## Маршруты

| Путь | Экран |
|---|---|
| /loading | LoadingScreen — инициализация |
| /auth | AuthScreen — вход/регистрация |
| /onboarding | OnboardingScreen — настройка предпочтений |
| /modes | SessionModeScreen — выбор режима |
| /session | SwipeSessionScreen — свайп 12 карточек |
| /result | RecommendationScreen — топ-3 рекомендации |
| /profile | ProfileScreen — профиль + статистика |
| /map | KrasnodarMapScreen — карта заведений |
| /add-venue | AddVenueScreen — форма добавления заведения |
| /my-venue | MyVenueScreen — статистика заведения владельца |

---

## Изображения заведений

Фотографии хранятся в `assets/places/` (42 файла, формат `NN_name.jpg`).
Маппинг venue ID → путь: `lib/core/constants/venue_assets.dart`.

Логика отображения:
1. Если venueId есть в `kVenueAssets` → `Image.asset()` (быстро, offline)
2. Иначе → `Image.network(photoUrl)` (fallback на URL из Firestore)

---

## Что не сделано / можно улучшить

- Онбординг отключён (предпочтения не собираются при регистрации)
- Рейтинги с Яндекс.Карт захардкожены
- Нет истории предыдущих сессий в UI
- Фото для пользовательских заведений только по URL (нет загрузки файла)
