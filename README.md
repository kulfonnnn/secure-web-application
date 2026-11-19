# Secure Web Application

**Aplikacja webowa rozwijana z naciskiem na bezpieczeństwo, konteneryzację i docelowe wdrożenie w chmurze AWS.**

Projekt zespołowy realizowany w ramach przedmiotu *Bezpieczeństwo Serwerów i Aplikacji Webowych*. Obejmuje tworzenie aplikacji Django, zabezpieczanie mechanizmów uwierzytelniania oraz projektowanie bezpiecznej infrastruktury chmurowej.

## Technologie

- **Python / Django** – logika aplikacji i obsługa użytkowników.
- **PostgreSQL** – relacyjna baza danych.
- **Docker / Docker Compose** – konteneryzacja i lokalne środowisko uruchomieniowe.
- **AWS** – docelowe środowisko wdrożeniowe.
- **Git / GitHub** – kontrola wersji i współpraca zespołu.

## Aktualny stan projektu

Aplikacja działa lokalnie w środowisku Docker Compose i obejmuje:

- Rejestrację, logowanie i wylogowanie użytkowników.
- Dostęp do widoków przeznaczonych wyłącznie dla zalogowanych użytkowników.
- Resetowanie hasła z wykorzystaniem jednorazowego tokenu.
- Przechowywanie haseł z użyciem algorytmu **Argon2**.
- Walidację danych po stronie serwera oraz ochronę CSRF.
- Bezpieczną obsługę sesji i plików cookie.

Kod aplikacji i konfiguracja środowiska znajdują się we wspólnym repozytorium GitHub.

## Planowane prace

### Infrastruktura AWS
- Wdrożenie aplikacji na instancjach EC2 z wykorzystaniem Docker.
- Wykorzystanie RDS PostgreSQL, ElastiCache Valkey i S3.
- Rozdzielenie zasobów publicznych i prywatnych w VPC.
- Obsługa ruchu przez CloudFront, AWS WAF i Application Load Balancer.

### Zabezpieczenia
- Ograniczenie uprawnień z wykorzystaniem IAM i Security Groups.
- Przechowywanie sekretów w AWS Secrets Manager.
- Monitoring i alarmowanie z wykorzystaniem CloudWatch, EventBridge i SNS.
- Kopie zapasowe oraz dodatkowe mechanizmy ochrony infrastruktury.

### Automatyzacja i testy
- Przygotowanie procesu CI/CD z wykorzystaniem GitHub Actions.
- Automatyzacja budowania i wdrażania aplikacji.
- Testy bezpieczeństwa aplikacji i infrastruktury, w tym analiza podatności oraz weryfikacja konfiguracji.

## Architektura AWS

*Planowana architektura infrastruktury:*

<img width="1595" height="891" alt="awsinfrastructure drawio" src="https://github.com/user-attachments/assets/546bd029-ce5d-4d9d-8951-fbb87ad6296f" />


## Uruchomienie lokalne

### Wymagania
- Docker Engine
- Docker Compose

Nie jest wymagana osobna instalacja Pythona, Django ani PostgreSQL.

### 1. Pobranie repozytorium

```bash
git clone <ADRES_REPOZYTORIUM>
cd secure-web-application
```

### 2. Konfiguracja

Utwórz plik `.env` na podstawie przykładowej konfiguracji:

```bash
cp .env.example .env
```

Ustaw własny klucz `DJANGO_SECRET_KEY` oraz silne hasło `POSTGRES_PASSWORD`.

**Nie udostępniaj pliku `.env` ani zawartych w nim sekretów.**

### 3. Uruchomienie

```bash
docker compose up --build
```

Aplikacja będzie dostępna pod adresem:

http://127.0.0.1:8000

### 4. Zatrzymanie

```bash
docker compose down
```

Dane PostgreSQL są przechowywane w wolumenie Dockera i pozostają dostępne po zatrzymaniu kontenerów.

---

*Projekt jest rozwijany etapami. Opis infrastruktury AWS, automatyzacji wdrożeń i dodatkowych testów bezpieczeństwa przedstawia planowane rozszerzenia, a nie funkcjonalności już wdrożone.*
