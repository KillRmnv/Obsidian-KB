// JSON
new HttpEntity<>(jsonBody, headers);

// Multipart
new HttpEntity<>(multipartBody, headers);

// Только заголовки
new HttpEntity<>(headers);

// Без тела (Void)
new HttpEntity<Void>(headers);
