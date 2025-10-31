MyTravaly – Flutter Screening Task

Overview

MyTravaly 3–screen Flutter app showcasing Google Sign‑In (frontend‑only), Hotel Home with search, and API‑backed Search Results with pagination. Implemented with Riverpod (state) and Dio (HTTP).

Tech stack

- Flutter (Material 3 theme)
- Riverpod (flutter_riverpod)
- Dio

Screens

1) Splash
- Registers device to obtain visitortoken; loads app settings; routes to Sign‑In.

2) Google Sign‑In (frontend‑only)
- “Continue with Google” and “Continue as Guest” → navigates to Home (no backend call required).

3) Home
- Hero search bar; sample “Featured” tiles; quick access actions.
- Submitting a query navigates to Results.

4) Search Results
- Compact header title “Results”.
- Search field to refine query; list with infinite scroll; pull‑to‑refresh.
- Empty state and loading states included.

API integration

- Base: https://api.mytravaly.com/public/v1/
- Auth headers: authtoken + visitortoken
- Flow (implemented in `lib/src/features/hotels/data/hotel_repository.dart`):
  1. Device Register (action: deviceRegister) on Splash → sets visitortoken.
  2. Search Auto complete (action: searchAutoComplete) → derives searchType/searchQuery.
  3. Get Search Result (action: getSearchResultListOfHotels) → real hotel listings.
- Currency List (action: getCurrencyList) and App Settings (POST appSetting/) are integrated via providers for future use.

Configuration

- Auth token is centralized in `lib/src/core/api_client.dart`.
- Visitortoken is acquired at runtime and injected in the same client automatically.

Project structure (selected)

- lib/
  - main.dart
  - src/
    - app_router.dart
    - theme/app_theme.dart
    - core/api_client.dart
    - features/
      - splash/splash_page.dart
      - auth/presentation/sign_in_page.dart
      - hotels/
        - data/{hotel_model.dart, hotel_repository.dart}
        - providers/hotel_providers.dart
        - presentation/{home_page.dart, search_results_page.dart}
        - widgets/hotel_tile.dart
      - session/visitor_token_repository.dart
      - settings/app_settings_repository.dart
      - currency/currency_repository.dart
    - widgets/{brand_logo.dart, google_button.dart}

Run locally

1) Flutter SDK installed (3.19+ recommended)
2) Install deps
   - flutter pub get
3) Run
   - flutter run

Notes on pagination

- Get Search Result currently infers hasMore by page size since paging parameters aren’t documented publicly here. If server paging fields (e.g., rid/page/offset) are provided, the repository can be updated quickly to use true server‑driven pagination.

What reviewers can test

- Splash → Sign‑In → Home → Search → Results
- Refine search; scroll to load more; pull‑to‑refresh; observe empty state.

Contact

- Candidate: Keval Panwala
- Submission: Public GitHub link + this README

# mytravel

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
