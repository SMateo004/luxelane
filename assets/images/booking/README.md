# booking/

Fotos de la sección "Capacidad" de la reserva. Se muestran enteras, con
esquinas redondeadas, y el texto de cada opción va debajo de la foto. Si una
foto no existe, la app dibuja un esquema de esa clase.

- `luggage/<clase>_<0|1|2>.png`: maletero con la opción 0 (de mano), 1 (facturadas), 2 (extra grandes)
- `seating/<clase>_<0|1|2>.png`: cabina con la opción 0 (capacidad máxima), 1 (un pasajero menos), 2 (con asiento infantil)

`<clase>`: `business_class`, `business_suv`, `van`, `first_class`.
Mejor si las tres fotos de una misma clase tienen la misma proporción.
