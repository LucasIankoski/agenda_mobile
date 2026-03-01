# Agenda Online (Flutter)

Frontend mobile em Flutter para consumir o backend Spring Boot (Agenda Escolar Online).

## Endpoints consumidos
- `POST /auth/register`
- `POST /auth/login`
- `GET /api/v1/classrooms`
- `GET /api/v1/classrooms/{id}`
- `POST /api/v1/classrooms`
- `PUT /api/v1/classrooms/{id}`
- `DELETE /api/v1/classrooms/{id}`
- `GET /api/v1/students`
- `GET /api/v1/students/{id}`
- `POST /api/v1/students`
- `DELETE /api/v1/students/{id}`
- `POST /api/v1/diaries`
- `GET /api/v1/diaries/{id}`
- `GET /api/v1/diaries/student/{studentId}?page=0&size=10`

(Admin)
- `GET /api/v1/users`
- `GET /api/v1/users/{id}`
- `PATCH /api/v1/users/{id}/desativar`

## Rodando
> **Android Emulator**: use `http://10.0.2.2:8080` para acessar o host.

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

## Observações
- JWT armazenado com `flutter_secure_storage`.
- Interceptor do `Dio` injeta `Authorization: Bearer <token>` automaticamente.
- Rotas protegidas com `go_router`.
- Estado com `Riverpod`.
