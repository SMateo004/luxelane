# booking/

Fotos de capacidad por clase. Si una foto no existe, la app dibuja un esquema
vectorial de esa clase (maletero o mapa de asientos), así que nunca se ve una
imagen de otro vehículo.

- `luggage/<clase>_<0|1|2>.png` — maletero con la opción 0 (de mano), 1 (facturadas), 2 (extra grande)
- `seating/<clase>_<0|1|2>.png` — cabina trasera con la opción 0 (capacidad máxima), 1 (un pasajero menos), 2 (con asiento infantil)

`<clase>`: `business`, `business_suv`, `van`, `first_class`. Tamaño: 754 × 694 px, PNG.
