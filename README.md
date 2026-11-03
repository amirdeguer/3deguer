# 3Deguer OS Web · v0.1

Panel React + TypeScript + Tailwind CSS + Supabase inspirado en la interfaz aprobada `$3d.1`.

## Inicio rápido

1. Instalar Node.js 20+.
2. Abrir esta carpeta en VS Code y ejecutar `npm install`.
3. Ejecutar `npm run dev` y abrir la URL indicada.
4. El selector **Demo** funciona sin configurar Supabase, con datos ficticios en memoria (se reinician al recargar).

## Activar el modo Normal

1. Crear un proyecto en https://supabase.com y ejecutar `supabase/schema.sql` en el SQL Editor.
2. En Supabase Authentication, crear una cuenta de usuario (o habilitar el registro y verificar el correo).
3. Copiar `.env.example` a `.env` y completar `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY` (clave pública/anon o publishable; **nunca** service_role).
4. Reiniciar `npm run dev`, elegir **Normal** e iniciar sesión.
5. Crear tus propios filamentos y productos iniciales en Supabase. El modo Normal comienza vacío y no importa automáticamente los datos ficticios.

## Publicación

Subir el proyecto a un repositorio privado GitHub y conectarlo a Vercel. Build: `npm run build`, output: `dist`. Configurar las dos variables `VITE_...` en Vercel. En Supabase Auth configurar los dominios autorizados si se habilitan flujos por correo.

## Alcance de esta primera versión

- Seis pantallas: Inicio, Pedidos, Stock, Productos, Costos, Estadísticas.
- Demo aislada en memoria; Normal con autenticación y tablas por usuario.
- Pedidos con hasta 4 colores y consumo único transaccional mediante RPC PostgreSQL.
- Reposición de stock, productos, edición de precios, estados de pedidos y cálculos.
- No se implementaron todavía edición/borrado de pedidos, ajustes por desperdicio, auditoría avanzada, importación de inventario, multiusuario con roles, pruebas automatizadas ni PWA offline.
- Los valores de stock y catálogo Demo son **datos ilustrativos**, no un inventario histórico verificado.
- Para producción conviene reforzar validación SQL del JSON de colores y calcular el precio desde productos dentro de la RPC en lugar de confiar en el importe enviado por el cliente.

## Seguridad

Las tablas tienen RLS por usuario. Las credenciales privadas de Supabase nunca deben ir en el navegador. Antes de usar datos comerciales reales, probar permisos, copias de seguridad y validaciones del servidor.
