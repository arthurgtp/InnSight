-- ============================================================
-- Actualizar coordenadas reales de hoteles en InnSight
-- Ejecutar en: Supabase Dashboard → SQL Editor
-- ============================================================

UPDATE hotels SET
  latitude  = 21.1619,
  longitude = -86.8515
WHERE hotel_id = 'a1111111-1111-1111-1111-111111111111';
-- Hotel Paradise — Cancún, Quintana Roo

UPDATE hotels SET
  latitude  = 16.7370,
  longitude = -92.6376
WHERE hotel_id = 'a2222222-2222-2222-2222-222222222222';
-- Hotel Montaña Azul — San Cristóbal de las Casas, Chiapas

UPDATE hotels SET
  latitude  = 19.4326,
  longitude = -99.1332
WHERE hotel_id = 'a3333333-3333-3333-3333-333333333333';
-- Hotel Centro Histórico — Ciudad de México, CDMX

UPDATE hotels SET
  latitude  = 20.6296,
  longitude = -87.0739
WHERE hotel_id = 'a4444444-4444-4444-4444-444444444444';
-- Resort Playa del Carmen — Playa del Carmen, Quintana Roo

UPDATE hotels SET
  latitude  = 17.0732,
  longitude = -96.7266
WHERE hotel_id = 'a5555555-5555-5555-5555-555555555555';
-- Hotel Oaxaca Colonial — Oaxaca de Juárez, Oaxaca

-- Verificar resultado:
SELECT hotel_id, name, latitude, longitude FROM hotels ORDER BY name;
