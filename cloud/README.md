# Aula. — versión cloud (Supabase + Vercel)

## 1. Supabase (base de datos + auth + realtime)

1. Crea un proyecto en [supabase.com](https://supabase.com) (gratis).
2. **SQL Editor** → pega y ejecuta `schema.sql`.
3. **Authentication → Providers**: Email activado.
4. **Storage**: crea bucket `chat-images` (público o con políticas).
5. **Database → Replication**: activa realtime para `group_messages`, `dm_messages`, `schedule_items`.
6. **Project Settings → API**: copia URL y `anon` key a `config.js`.

## 2. Frontend

La app actual (`index.html`) usa localStorage.
La versión cloud reutiliza la misma UI y sustituye la capa de datos por el cliente de Supabase (`@supabase/supabase-js` por CDN).

Cuando tengas el proyecto Supabase:

1. Copia `config.example.js` → `config.js` con tus claves.
2. Despliega en Vercel el HTML + `config.js` (sin commitear secretos de service role; solo `anon`).

## 3. Vercel (servidor estático)

```bash
npx vercel --prod
```

URL típica: `https://aula-app.vercel.app`

## 4. Flujo multi-dispositivo

- Registro/login con Supabase Auth (email + contraseña).
- Perfil + Funko en `profiles`.
- Grupos, canales, mensajes y horario en Postgres con RLS.
- Mensajes en vivo con Realtime subscriptions.
- Fotos en Storage.
