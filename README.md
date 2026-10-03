# Aula.

Chat en grupo pensado para clases. Canales, horario compartido, anclas (`/deberes mates`) y avatar Funko.

**Repo:** https://github.com/mauro1gifo/aula-app

## Archivos en el repo

| Archivo | Descripción |
|---------|-------------|
| `index.html` | Página de entrada (sustituye por la app completa de 62 KB) |
| `vercel.json` | Config para desplegar en Vercel |
| `package.json` | Metadatos del proyecto |
| `cloud/schema.sql` | Esquema PostgreSQL / Supabase (auth, grupos, mensajes, RLS) |
| `cloud/config.example.js` | Plantilla de claves Supabase |
| `cloud/README.md` | Guía versión cloud |

## App completa (localStorage)

El cliente completo (~62 KB, un solo `index.html`) está en el entorno de desarrollo. Para subirlo al repo:

1. En GitHub → **Add file** → **Upload files**
2. Sube el `index.html` completo (sustituye el actual)
3. Commit en `main`

O en local:

```bash
git clone https://github.com/mauro1gifo/aula-app.git
cd aula-app
# copia aquí el index.html completo de la app
git add index.html
git commit -m "Add full Aula app"
git push
```

## Abrir en local

Abre `index.html` (el completo) en el navegador, preferiblemente en vista móvil.

## Desplegar en Vercel

```bash
npx vercel --prod
```

O conecta este repo en [vercel.com/new](https://vercel.com/new).

## Versión cloud (multi-dispositivo)

Ver [`cloud/`](cloud/): ejecuta `schema.sql` en Supabase y configura Auth + Realtime.

## Qué incluye la app

- Bienvenida, registro con diseñador de Funko, login
- Dock de cristal: Chats · Buscar · Crear · Ajustes
- Grupos con canales (general, mates, lengua, historia, inglés)
- Burbujas estilo iMessage, stickers, fotos
- Anclas indexables
- Mini horario L–V
- DMs y bloqueo de contactos
- Persistencia local (localStorage) por dispositivo
