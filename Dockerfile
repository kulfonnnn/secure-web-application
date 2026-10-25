
# lekki obraz pythona
FROM python:3.13-slim

#zmienne srodowiskowe
#bez tworzenia plikow .pyc, wysylanie logow na biezaco, bez buforowania
ENV PYTHONDONTWRITEBYTECODE=1 \ 
    PYTHONUNBUFFERED=1

# katalog roboczy apki wewnatrz kontenera
WORKDIR /app

# polecenia podczas uruchamiania
#grupa systemowa app, uzytkownik app stworzony i przypisany do tej grupy
RUN addgroup --system app \
&& adduser --system --ingroup app app 

# dodanie pliku z potrzebnymi bibliotekami
COPY requirements.txt /app/requirements.txt

# uruchomienie pythona, aktulizacja, instalacja potrzebnych bibliotek
RUN python -m pip install --no-cache-dir --upgrade pip \
    && python -m pip install --no-cache-dir -r /app/requirements.txt

# kopiujemy wszystkie pliki, ktore nie sa w dockerignore, do kontenera
# wlascicielem plikow bedzie stworzony user app
COPY --chown=app:app . /app/

# nastepne instrukcje z poziomu usera (ograniczenie uprawnien)
USER app

# informacja o porcie 8000
EXPOSE 8000

# domyslne polecenie przy starcie kontenera
# konieczne pliki, uruchomienie, wszystkie interfejsy port 8000
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
