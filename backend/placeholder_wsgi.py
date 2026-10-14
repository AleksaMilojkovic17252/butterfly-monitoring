"""Placeholder WSGI app so the django container can start and pass its health check.

T003 replaces this with the Django project (config.wsgi) and deletes this file.
"""


def application(environ, start_response):
    body = b'{"status": "placeholder"}\n'
    start_response("200 OK", [("Content-Type", "application/json"), ("Content-Length", str(len(body)))])
    return [body]
