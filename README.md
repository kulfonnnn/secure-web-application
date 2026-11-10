# Bezpieczeństwo serwerów i aplikacji webowych — projekt

## Opis projektu

Projekt realizowany w ramach przedmiotu „Bezpieczeństwo Serwerów i Aplikacji Webowych”. Aplikacja internetowa oparta na Django i PostgreSQL, uruchamiana w kontenerach Docker.

Pierwsza wersja aplikacji obejmuje rejestrację użytkowników, logowanie, wylogowanie oraz dostęp do strony przeznaczonej dla zalogowanych użytkowników. Dalsza funkcjonalność aplikacji zostanie rozwinięta w kolejnych etapach projektu.

## Technologie

- **Python / Django** — aplikacja webowa i obsługa użytkowników.
- **PostgreSQL** — baza danych.
- **Docker / Docker Compose** — uruchamianie aplikacji i bazy danych.
- **GitHub** — repozytorium kodu i współpraca zespołu.

## Wymagania

Do uruchomienia projektu potrzebne są:
- Docker Engine,
- Docker Compose.

Nie jest konieczna osobna instalacja Pythona, Django ani PostgreSQL na komputerze.

## Uruchomienie lokalne

### 1. Pobranie projektu

```bash
git clone <ADRES_REPOZYTORIUM>
cd Bezpieczenstwo-serwerow-i-aplikacji-Web---projekt
```

### 2. Konfiguracja zmiennych środowiskowych

Utwórz lokalny plik `.env` na podstawie przykładowej konfiguracji:

```bash
cp .env.example .env
```

Edytuj plik `.env` i ustaw własny, losowy klucz `DJANGO_SECRET_KEY` oraz silne hasło do PostgreSQL (`POSTGRES_PASSWORD`). Pozostałe zmienne skonfiguruj zgodnie z `.env.example`.

**Plik `.env` zawiera poufne dane i nie może być przesyłany do repozytorium.**

### 3. Uruchomienie aplikacji

W katalogu projektu wykonaj:

```bash
docker compose up --build
```

Docker zbuduje obraz aplikacji, uruchomi kontener Django i bazę PostgreSQL. Po uruchomieniu bazy wykonywane są migracje Django.

Aplikacja będzie dostępna pod adresem:

http://127.0.0.1:8000

### 4. Zatrzymanie aplikacji

Aby zatrzymać aplikację uruchomioną w bieżącym terminalu, naciśnij `Ctrl+C`. Następnie wykonaj:

```bash
docker compose down
```

Dane PostgreSQL są przechowywane w wolumenie Dockera, dzięki czemu zwykłe zatrzymanie kontenerów nie usuwa bazy danych.

## Przydatne polecenia

Sprawdzenie stanu kontenerów:

```bash
docker compose ps
```

Wyświetlenie logów aplikacji:

```bash
docker compose logs -f web
```

Ponowne zbudowanie obrazu i uruchomienie aplikacji:

```bash
docker compose up --build
```

Ręczne wykonanie migracji bazy danych:

```bash
docker compose exec web python manage.py migrate
```

## Uwagi

Projekt jest rozwijany. Obecna konfiguracja Dockera służy do lokalnego środowiska deweloperskiego. Docelowo aplikacja zostanie rozbudowana o wymagane funkcjonalności oraz wdrożona w środowisku chmurowym AWS.
<img width="1595" height="891" alt="awsinfrastructure drawio" src="https://github.com/user-attachments/assets/3a305e2e-f4e7-4a32-814d-d371f21d869e" />

