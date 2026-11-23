from django.http import HttpResponse


class HealthCheckMiddleware:
    """Odpowiada na /health/ przed weryfikacją nagłówka Host (ALLOWED_HOSTS).

    ALB wysyła zapytania kontrolne z adresem IP instancji w nagłówku Host,
    którego nie ma na liście ALLOWED_HOSTS. Bez tego Django zwracałoby błąd 400.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if request.path == "/health/":
            return HttpResponse("ok", content_type="text/plain")
        return self.get_response(request)